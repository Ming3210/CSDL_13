use ss13;

create table enrollments_history(
	history_id int primary key auto_increment,
    student_id int not null,
    course_id int not null,
    action varchar(50),
    timestamp datetime default current_timestamp ,
    constraint foreign key (student_id )references students (student_id)
)


-- 2
DELIMITER &&

create procedure enroll_student_with_history(
    in p_student_name varchar(50), 
    in p_course_name varchar(100)
)
begin
    declare v_student_id int;
    declare v_course_id int;
    declare v_available_seats int;
    declare v_enrollment_exists int;

   

    start transaction;

    select student_id into v_student_id
    from students
    where student_name = p_student_name;

    select course_id, available_seats into v_course_id, v_available_seats
    from courses
    where course_name = p_course_name;

    select count(*) into v_enrollment_exists
    from enrollments
    where student_id = v_student_id and course_id = v_course_id;

    if v_enrollment_exists > 0 then
        insert into enrollments_history (student_id, course_id, action) 
        values (v_student_id, v_course_id, 'already enrolled');
        rollback;
        signal sqlstate '45000' set message_text = 'student already enrolled in the course';
    end if;

    if v_available_seats <= 0 then
        insert into enrollments_history (student_id, course_id, action) 
        values (v_student_id, v_course_id, 'registration failed - no seats available');
        rollback;
        signal sqlstate '45000' set message_text = 'no available seats in the course';
    end if;

    insert into enrollments (student_id, course_id)
    values (v_student_id, v_course_id);

    update courses
    set available_seats = available_seats - 1
    where course_id = v_course_id;

    insert into enrollments_history (student_id, course_id, action)
    values (v_student_id, v_course_id, 'successful enrollment');

    commit;
end &&

DELIMITER ;


-- 3
call enroll_student_with_history('Nguyễn Văn Ba', 'Lập trình C');

-- 4
select * from enrollments;
select * from courses;
select * from enrollments_history;

drop procedure enroll_student_with_history;
