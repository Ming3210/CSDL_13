use ss13;
-- 2
create table banks (
	bank_id int auto_increment primary key,
    bank_name varchar(255) not null,
    status enum('ACTIVE','ERROR')
);

-- 3
INSERT INTO banks (bank_id, bank_name, status) VALUES 

(1,'VietinBank', 'ACTIVE'),   

(2,'Sacombank', 'ERROR'),    

(3, 'Agribank', 'ACTIVE');   


-- 4
alter table company_funds 
add column bank_id int,
add constraint fk_company_funds_bank foreign key (bank_id) references banks(bank_id);


-- 5
UPDATE company_funds SET bank_id = 1 WHERE balance = 50000.00;

INSERT INTO company_funds (balance, bank_id) VALUES (45000.00,2);


-- 6
DELIMITER &&

create trigger check_bank_status
before insert on payroll
for each row
begin
    declare bank_status enum('ACTIVE', 'ERROR');

    -- lấy trạng thái ngân hàng của công ty từ bảng company_funds và banks
    select b.status into bank_status
    from company_funds cf
    join banks b on cf.bank_id = b.bank_id
    order by cf.fund_id desc
    limit 1;

    -- nếu ngân hàng có trạng thái error, báo lỗi và ngăn chặn giao dịch
    if bank_status = 'ERROR' then
        signal sqlstate '45000'
        set message_text = 'Ngân hàng đang gặp sự cố, không thể trả lương!';
    end if;
end &&;



DELIMITER &&;

-- 7
set autocommit = 0;
DELIMITER $$

CREATE PROCEDURE TransferSalary(
    IN p_emp_id INT  -- ID của nhân viên nhận lương
)
BEGIN
    DECLARE v_salary DECIMAL(10,2);
    DECLARE v_balance DECIMAL(15,2);
    DECLARE v_fund_id INT;
    DECLARE v_bank_status ENUM('ACTIVE', 'ERROR');
    DECLARE v_error_message VARCHAR(255);

    -- Bắt đầu transaction
    START TRANSACTION;

    -- Kiểm tra nhân viên có tồn tại không và lấy lương của nhân viên
    SELECT salary INTO v_salary FROM employees WHERE emp_id = p_emp_id;
    IF v_salary IS NULL THEN
        SET v_error_message = 'Nhân viên không tồn tại. Rollback đã được thực hiện.';
        ROLLBACK;
        INSERT INTO transaction_log (log_message, log_time) 
        VALUES (v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhân viên không tồn tại';
    END IF;

    -- Lấy số dư quỹ công ty và fund_id
    SELECT fund_id, balance INTO v_fund_id, v_balance 
    FROM company_funds 
    ORDER BY fund_id DESC 
    LIMIT 1;

    -- Kiểm tra quỹ công ty có đủ tiền trả lương không
    IF v_balance < v_salary THEN
        SET v_error_message = 'Quỹ công ty không đủ tiền để trả lương. Rollback đã được thực hiện.';
        ROLLBACK;
        INSERT INTO transaction_log (log_message, log_time) 
        VALUES (v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quỹ công ty không đủ tiền để trả lương';
    END IF;

    -- Kiểm tra trạng thái ngân hàng
    SELECT b.status INTO v_bank_status
    FROM company_funds cf
    JOIN banks b ON cf.bank_id = b.bank_id
    WHERE cf.fund_id = v_fund_id;

    IF v_bank_status = 'ERROR' THEN
        SET v_error_message = 'Ngân hàng gặp sự cố. Rollback đã được thực hiện.';
        ROLLBACK;
        INSERT INTO transaction_log (log_message, log_time) 
        VALUES (v_error_message, NOW());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngân hàng gặp sự cố';
    END IF;

    -- Trừ số tiền lương khỏi quỹ công ty 
    UPDATE company_funds 
    SET balance = balance - v_salary 
    WHERE fund_id = v_fund_id;

    -- Chèn bản ghi vào bảng payroll
    INSERT INTO payroll (emp_id, salary, pay_date)
    VALUES (p_emp_id, v_salary, NOW());

 

    -- Ghi log giao dịch thành công
    INSERT INTO transaction_log (log_message, log_time) 
    VALUES (CONCAT('Chuyển lương thành công cho nhân viên ', p_emp_id), NOW());

    -- Xác nhận giao dịch
    COMMIT;
END $$

DELIMITER ;

drop procedure TransferSalary;
-- 8
call TransferSalary(111);

