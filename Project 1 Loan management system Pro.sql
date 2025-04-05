create database Loan_Management_System;
use Loan_Management_System;

select * from customer_income;

select * from loan_status;

alter table loan_status modify LoanAmount int;
desc loan_status;

select * from customer_info;

select * from country_state;

select * from region_info;

set autocommit = off;
-- set autocommit = on;

start transaction ;

select * from customer_income;


create table Applicant_income_Grade select c.*,
case 
when
ApplicantIncome >15000 then "Grade A"
when
ApplicantIncome >9000 then "Grade B"
when
ApplicantIncome >5000 then "middle class customer"
else "Low Class"
end as ApplicantIncGrade
from  customer_income c;

select * from Applicant_income_Grade;

-- Applicant monthly interest % criteria

create table Applicant_monthly_interest select *,
case
when ApplicantIncome <5000 then
case
when Property_Area = "rural" then 3
when Property_Area = "semirural" then 3.5
when Property_Area = "urban" then 5
when Property_Area = "semiurban" then 2.5
end 
else 7
end as interest_percentage 
from customer_income;

drop table Applicant_monthly_interest;
select * from Applicant_monthly_interest;

-- loan status table
select * from loan_status;
select count(*) from loan_status;


-- loan status Primary Table1
create table loan_status_table1 
(loan_id varchar(50), customer_id varchar(50), loan_amount varchar(50), loan_amount_term int, cibil_score int,
primary key (loan_id));

-- loan status Secondary Table1
create table loan_remark (
loan_id varchar(50),loan_amount varchar(50),Cibil_Score int,Cibil_Score_status varchar (50),
primary key (loan_id));

-- sheet 2 
-- Create row level trigger for loan amt 

delimiter //
create trigger Cibil_score before insert on
loan_status_table1 for each row
begin
if new.Loan_amount is null then set new.Loan_amount = "Loan still processing";
end if ;
insert into loan_remark (loan_id,loan_amount,cibil_score,cibil_score_status)
values (new.loan_id,new.loan_amount,new.cibil_score,
case
when new.cibil_score > 900 then "High cibil score"
when new.cibil_score > 750 then "no penalty"
when new.cibil_score > 0 then "Penalty customers"
when new.cibil_score <= 0 then "Loan cannot apply"
end );
end //
delimiter ;
drop trigger Cibil_score;

insert into loan_status_table1 select * from Loan_status;

select  * from loan_status_table1;
desc loan_status_table1;
select * from loan_remark;
desc loan_remark;
-- Then delete the reject and loan still processing customers
delete from loan_remark where loan_amount = "Loan still processing" or 
Cibil_Score_status = "Loan cannot apply";
select * from loan_remark;

-- Update loan as integers
alter table loan_remark modify loan_amount int;

/*Create all the above fields as a table 
Table name - loan cibil score status details*/
alter table loan_remark rename loan_cibil_score_status_details;

select * from loan_cibil_score_status_details;

-- sheet 1 (New field creation based on interest) above

-- Calculate monthly interest amt and annual interest amt based on loan amt


create table Amount_based_on_interest as 
select  a.*, l.loan_amount, l.cibil_score, l.cibil_score_status 
from Applicant_monthly_interest a 
inner join loan_cibil_score_status_details l 
on a.loan_id = l.loan_id;

select  * from Amount_based_on_interest;

create table customer_interest_analysis as 
select Loan_ID, loan_amount, interest_percentage, 
       ROUND((interest_percentage / 100) * loan_amount, 0) AS monthly_interest, 
       ROUND(((interest_percentage / 100) * loan_amount) * 12, 0) AS annual_interest 
from Amount_based_on_interest;

select * from customer_interest_analysis;
select l.*,interest_percentage,monthly_interest,annual_interest from loan_cibil_score_status_details l join customer_interest_analysis a
 on l.loan_id = a.loan_id;
 
create table Bsd_interest select l.*,interest_percentage,monthly_interest,annual_interest from loan_cibil_score_status_details l 
join customer_interest_analysis a 
on l.loan_id = a.loan_id;

drop table Bsd_interest;
select * from Bsd_interest;

select * from customer_interest_analysis;

-- sheet 3
-- customer info 
select * from customer_info;
update customer_info  
set gender =
case
when `customer id` = 'IP43006' then 'female'
when `customer id`  = 'IP43016' then 'female'
when `customer id`  = 'IP43018' then 'male'
when `customer id`  = 'IP43038' then 'male'
when `customer id`  = 'IP43508' then 'female'
when `customer id`  = 'IP43577' then 'female'
when `customer id`  = 'IP43589' then 'female'
when `customer id`  = 'IP43593' then 'female'
else gender
end ,
age = case
when `customer id`  ='IP43007' then 45
when `customer id`  ='IP43009'	then 32
else age
end;


-- sheet 4 & 5 
-- country state and region
-- Join all the 5 tables without repeating the fields - output 1 

create table output1 select c.*, A.ApplicantIncome, A.CoapplicantIncome, A.property_area, A.Loan_status, 
A.interest_percentage, A.loan_amount, A.cibil_score, A.cibil_score_status, s.postal_code, s.segment, s.state, 
i.monthly_interest, i.annual_interest, r.region 
from customer_info c 
inner join Amount_based_on_interest  A on c.Loan_Id = A.Loan_ID  
inner join country_state s on c.Loan_Id = s.Loan_Id 
inner join customer_interest_analysis i on c.Loan_Id = i.Loan_ID 
inner join region_info r on c.Region_id = r.Region_id;

select * from customer_info;
select * from Amount_based_on_interest;
select * from customer_interest_analysis;
select * from region_info;
select * from country_state;
desc country_state;
ALTER TABLE country_state
CHANGE COLUMN `Load Id` Loan_Id text;

-- find the mismatch details using joins - output 2

select o.*,r.* from output1 as o right join region_info r on 
 o.region =  r.region where o.region is null;

select * from region_info;
select * from customer_info;
ALTER TABLE customer_info
CHANGE COLUMN `Customer ID` customer_id text;
select * from country_state;
-- Filtering information using inner join


delimiter // 
create procedure final_output3()
begin
SELECT c.*, A.applicantIncome, A.coapplicantincome, A.property_area, A.loan_status, 
A.interest_percentage, A.loan_amount, A.cibil_score, A.cibil_score_status, s.postal_code, s.segment, s.state, 
i.monthly_interest, i.annual_interest, r.region 
FROM customer_info c 
INNER JOIN Amount_based_on_interest A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id;

SELECT c.*, A.applicantIncome, A.coapplicantIncome, A.property_area, A.loan_status, 
A.interest_percentage, A.loan_amount, A.cibil_score, A.cibil_score_status, 
s.postal_code, s.segment, s.state, i.monthly_interest, i.annual_interest, 
r.region 
FROM customer_info c 
INNER JOIN Amount_based_on_interest A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id
order by a.cibil_score desc limit 1;
end //
delimiter // 



delimiter // 
create procedure final_output4()
begin
SELECT c.*, A.applicantIncome, A.coapplicantincome, A.property_area, A.loan_status, 
A.interest_percentage, A.loan_amount, A.cibil_score, A.cibil_score_status, s.postal_code, s.segment, s.state, 
i.monthly_interest, i.annual_interest, r.region 
FROM customer_info c 
INNER JOIN Amount_based_on_interest A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id;

SELECT c.*, A.applicantIncome, A.coapplicantIncome, A.property_area, A.loan_status, 
A.interest_percentage, A.loan_amount, A.cibil_score, A.cibil_score_status, 
s.postal_code, s.segment, s.state, i.monthly_interest, i.annual_interest, r.region 
FROM customer_info c 
INNER JOIN Amount_based_on_interest A ON c.loan_id = A.loan_id  
INNER JOIN country_state s ON c.loan_id = s.loan_id  
INNER JOIN customer_interest_analysis i ON c.loan_id = i.loan_id 
INNER JOIN region_info r ON c.region_id = r.region_id
where s.segment in ('Home Office','corporate');
end //
delimiter // 


drop procedure final_output;
select * from region_info;

SHOW COLUMNS FROM country_state;

DROP PROCEDURE IF EXISTS final_output;

SHOW PROCEDURE STATUS WHERE Db = 'loan_management_system';

delimiter ;
call final_output3;

call final_output4;

