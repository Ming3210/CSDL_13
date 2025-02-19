use ss13;
-- 2

create table student_status (
	student_id int primary key auto_increment,
    status enum('ACTIVE','GRADUATED','SUPENED'),
    foreign key (student_id) references students(student_id)
);


-- 3
INSERT INTO student_status (student_id, status) VALUES

(1, 'ACTIVE'), -- Nguyễn Văn An có thể đăng ký

(2, 'GRADUATED'); -- Trần Thị Ba đã tốt nghiệp, không thể đăng ký

-- 4
CREATE TABLE enrollment_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    status VARCHAR(50),
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET AUTOCOMMIT = 0;
DELIMITER $$

CREATE PROCEDURE RegisterCourse(
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_status ENUM('ACTIVE', 'GRADUATED', 'SUSPENDED');
    DECLARE v_already_enrolled INT;
    DECLARE v_available_seats INT;
    DECLARE v_error_message VARCHAR(255);

    -- Bắt đầu transaction
    START TRANSACTION;

    -- Kiểm tra sinh viên có tồn tại không
    SELECT student_id INTO v_student_id FROM students WHERE student_name = p_student_name;
    IF v_student_id IS NULL THEN
        SET v_error_message = 'FAILED: Student does not exist';
        ROLLBACK;
        INSERT INTO enrollment_history (status, log_time) VALUES (v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Kiểm tra môn học có tồn tại không
    SELECT course_id, available_seats INTO v_course_id, v_available_seats FROM courses WHERE course_name = p_course_name;
    IF v_course_id IS NULL THEN
        SET v_error_message = 'FAILED: Course does not exist';
        ROLLBACK;
        INSERT INTO enrollment_history (student_id, status, log_time) 
        VALUES (v_student_id, v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Kiểm tra sinh viên đã đăng ký môn học này chưa
    SELECT COUNT(*) INTO v_already_enrolled 
    FROM enrollments 
    WHERE student_id = v_student_id AND course_id = v_course_id;

    IF v_already_enrolled > 0 THEN
        SET v_error_message = 'FAILED: Already enrolled';
        ROLLBACK;
        INSERT INTO enrollment_history (student_id, course_id, status, log_time) 
        VALUES (v_student_id, v_course_id, v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Kiểm tra trạng thái sinh viên
    SELECT status INTO v_status FROM student_status WHERE student_id = v_student_id;
    IF v_status IN ('GRADUATED', 'SUSPENDED') THEN
        SET v_error_message = 'FAILED: Student not eligible';
        ROLLBACK;
        INSERT INTO enrollment_history (student_id, course_id, status, log_time) 
        VALUES (v_student_id, v_course_id, v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Kiểm tra số chỗ trống của môn học
    IF v_available_seats <= 0 THEN
        SET v_error_message = 'FAILED: No available seats';
        ROLLBACK;
        INSERT INTO enrollment_history (student_id, course_id, status, log_time) 
        VALUES (v_student_id, v_course_id, v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Đăng ký sinh viên vào môn học
    INSERT INTO enrollments (student_id, course_id) VALUES (v_student_id, v_course_id);

    -- Giảm số lượng chỗ trống
    UPDATE courses SET available_seats = available_seats - 1 WHERE course_id = v_course_id;

    -- Ghi nhận lịch sử đăng ký thành công
    INSERT INTO enrollment_history (student_id, course_id, status, log_time) 
    VALUES (v_student_id, v_course_id, 'REGISTERED', NOW());

    -- Commit transaction
    COMMIT;
END $$

DELIMITER ;

-- 5
CALL RegisterCourse('Trần Thị Ba', 'Lập trình C');

-- 6
select * from enrollments;

select * from courses;

select * from enrollment_history;
