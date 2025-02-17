create database ss13;
use ss13;
-- 1
create table accounts(
	account_id int primary key auto_increment,
    account_name varchar(50),
    balance decimal(10,2)
);

-- 2
INSERT INTO accounts (account_name, balance) VALUES 

('Nguyễn Văn An', 1000.00),

('Trần Thị Bảy', 500.00);

-- 3
set autocommit = 0;
DELIMITER &&
create procedure transferMoney (
	acc_sender int,
    acc_receiver int,
    money decimal(15,2)
)
begin
	start transaction;
    
    -- 1. Kiem tra tk gui va nhan
    if(select count(account_id) from accounts where account_id = acc_sender) = 0
		or (select count(account_id) from accounts where account_id = acc_receiver) = 0 then
        rollback;
	else
	-- 2. Tru tien tk gui
		update accounts
			set balance = balance - money
            where account_id = acc_sender;
            -- 3. Ktra so du tk
            if (select balance from accounts where account_id = acc_sender) < money then
                rollback;
			else
            -- 4. Cong tien tk
            update accounts 
            set balance = balance + money where account_id = acc_receiver;
            commit;
            end if;
	end if;

end &&

DELIMITER &&;

drop procedure transferMoney;

-- 4

call transferMoney(1,2,20);


