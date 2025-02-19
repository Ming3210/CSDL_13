-- 2
create table `account` (
	acc_id int primary key auto_increment,
    emp_id int,
    bank_id int,
    amount_added decimal(15,2),
    total_amount decimal(15,2),
    foreign key (emp_id) references employees(emp_id),
    foreign key (bank_id) references banks(bank_id)
);

-- 3
INSERT INTO account (emp_id, bank_id, amount_added, total_amount) VALUES

(1, 1, 0.00, 12500.00),  

(2, 1, 0.00, 8900.00),   

(3, 1, 0.00, 10200.00),  

(4, 1, 0.00, 15000.00),  

(5, 1, 0.00, 7600.00);


-- 4
DELIMITER $$

CREATE PROCEDURE TransferSalaryAll()
BEGIN
    DECLARE v_emp_id INT;
    DECLARE v_salary DECIMAL(10,2);
    DECLARE v_balance DECIMAL(15,2);
    DECLARE v_bank_status ENUM('ACTIVE', 'ERROR');
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_error_message VARCHAR(255);
    DECLARE v_total_salary DECIMAL(15,2);
    
    -- Con trỏ phải khai báo TRƯỚC handler
    DECLARE emp_cursor CURSOR FOR 
        SELECT emp_id, salary FROM employees;
        
    -- Handler phải khai báo SAU cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Bắt đầu transaction
    START TRANSACTION;

    -- Lấy số dư quỹ công ty
    SELECT balance INTO v_balance FROM company_funds ORDER BY fund_id DESC LIMIT 1;

    -- Kiểm tra trạng thái ngân hàng
    SELECT b.status INTO v_bank_status
    FROM company_funds cf
    JOIN banks b ON cf.bank_id = b.bank_id
    ORDER BY cf.fund_id DESC
    LIMIT 1;

    IF v_bank_status = 'ERROR' THEN
        SET v_error_message = 'Ngân hàng gặp sự cố. Rollback đã được thực hiện.';
        ROLLBACK;
        INSERT INTO transaction_log (log_message, log_time) VALUES (v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngân hàng gặp sự cố';
    END IF;

    -- Kiểm tra tổng lương có vượt quá số dư không
    SELECT SUM(salary) INTO v_total_salary FROM employees;
    
    IF v_total_salary > v_balance THEN
        SET v_error_message = 'Quỹ công ty không đủ để trả lương. Rollback đã được thực hiện.';
        ROLLBACK;
        INSERT INTO transaction_log (log_message, log_time) VALUES (v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quỹ công ty không đủ tiền để trả lương';
    END IF;

    -- Mở con trỏ
    OPEN emp_cursor;

    emp_cursor_loop: LOOP
        -- Lấy thông tin nhân viên
        FETCH emp_cursor INTO v_emp_id, v_salary;
        IF done THEN
            LEAVE emp_cursor_loop;
        END IF;

        -- Trừ số tiền lương khỏi quỹ công ty
        UPDATE company_funds 
        SET balance = balance - v_salary
        ORDER BY fund_id DESC
        LIMIT 1;

        -- Thêm bản ghi vào bảng payroll
        INSERT INTO payroll (emp_id, salary, pay_date) 
        VALUES (v_emp_id, v_salary, NOW());

    

        -- Cập nhật bảng account
        UPDATE account 
        SET amount_added = v_salary, 
            total_amount = total_amount + v_salary
        WHERE emp_id = v_emp_id;

        -- Cập nhật số dư quỹ công ty
        SET v_balance = v_balance - v_salary;

        -- Tăng biến đếm số nhân viên đã nhận lương
        SET v_count = v_count + 1;
    END LOOP;

    -- Đóng con trỏ
    CLOSE emp_cursor;

    -- Ghi log giao dịch thành công
    INSERT INTO transaction_log (log_message, log_time) 
    VALUES (CONCAT('Chuyển lương thành công cho ', v_count, ' nhân viên.'), NOW());

    -- Commit transaction
    COMMIT;
END $$

DELIMITER ;

drop procedure TransferSalaryAll;
-- 5
call TransferSalaryAll();

-- 6
select * from company_funds;
select * from payroll;
select * from account;
select * from transaction_log;

