create database ss13;
use ss13;
CREATE TABLE company_funds (
    fund_id INT PRIMARY KEY AUTO_INCREMENT,
    balance DECIMAL(15,2) NOT NULL -- Số dư quỹ công ty
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50) NOT NULL,   -- Tên nhân viên
    salary DECIMAL(10,2) NOT NULL    -- Lương nhân viên
);

CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,                      -- ID nhân viên (FK)
    salary DECIMAL(10,2) NOT NULL,   -- Lương được nhận
    pay_date DATE NOT NULL,          -- Ngày nhận lương
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);


INSERT INTO company_funds (balance) VALUES (50000.00);

INSERT INTO employees (emp_name, salary) VALUES
('Nguyễn Văn An', 5000.00),
('Trần Thị Bốn', 4000.00),
('Lê Văn Cường', 3500.00),
('Hoàng Thị Dung', 4500.00),
('Phạm Văn Em', 3800.00);

-- 2
create table transaction_log(
	log_id int primary key auto_increment,
    log_message text not null,
    log_time timestamp default current_timestamp
);

-- 3
alter table transaction_log
add column last_pay_date date default( curdate());

-- 4
set autocommit = 0;
DELIMITER &&
create procedure transferMoney (
	in employeeId int,
    in fundId int
)
begin 
declare com_balance decimal;
    declare emp_salary decimal;
	start transaction;
    if (select count(emp_id) from employees where emp_id = employeeId) = 0 
		or (select count(fund_id) from company_funds where fund_id = fundId) = 0
		then
		insert into transaction_log(log_message)
		values('Id nguoi dung, hoac Id cong ty khong ton tai');
        rollback;
    else
		select balance into com_balance from company_funds where fund_id = fundId ;
        select salary into emp_salary from employees where emp_id = employeeId;
		if (com_balance) < (emp_salary) 
			then
			insert into transaction_log(log_message)
			values('so du tai khoan cong ty khong du');
			rollback;
        else 
        update company_funds
        set balance = balance - emp_salary;
        
        insert into payroll(emp_id, salary, pay_date)
        values 
        (employeeId, emp_salary, curdate());
        
        insert into transaction_log(log_message)
        values ('chuyển tiền thành công');
        commit;
        end if;
    end if;
end &&

DELIMITER &&;


-- 5
call transferMoney(1,1);
select * from company_funds;
select * from employees;

select * from payroll;