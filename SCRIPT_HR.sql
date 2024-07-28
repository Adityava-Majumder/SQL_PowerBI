use adityava_db ;

select * from hr_yt;

-- start cleaning

alter table hr_yt
change column ï»¿id emp_id varchar(20) null ;	-- change employee id column name

desc hr_yt;

-- format birthdate and hiredate column from mixed typed to yyyy-mm-dd format and also change datatype  of column

select birthdate from hr_yt;

 set sql_safe_updates = 0;
update hr_yt
set birthdate = case
	when birthdate like '%/%' then date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    when birthdate like '%-%' then date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    else null
end;

select birthdate from hr_yt;
alter table hr_yt
modify column birthdate date;

update hr_yt
set hire_date = case
	when hire_date like '%/%' then date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    when hire_date like '%-%' then date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    else null
end;
 
select hire_date from hr_yt;
alter table hr_yt
modify column hire_date date;

-- format termination date column and replace null and empty values with default date of 000-00-00

select termdate from hr_yt;

update hr_yt
set termdate = if(termdate is not null and termdate != '', 		-- IF STATEMENT IS VERY IMPORTANT
				date(str_to_date(termdate,'%Y-%m-%d %H:%i:%s UTC')),'0000-00-00')
where true;

select termdate from hr_yt;

set sql_mode = 'ALLOW_INVALID_DATES';		-- THIS MODE NEEDS TO BE ALLOWED TO USE THE ONVALID EMPTY DATE FORMAT
alter table hr_yt
modify column termdate date;

select termdate from hr_yt;

-- ADDING AGE COLUMN --

alter table hr_yt
add column age int ;

update hr_yt
set age = timestampdiff(year,birthdate,curdate());
select birthdate,age from hr_yt;

-- some are negative age, remove them 
select 
	min(age) as youngest,
	max(age) as oldest
from hr_yt;
-- for removing records with negative age or less than 18 we use
-- delete from hr_yt where age < 18

select count(*)
from hr_yt
where age < 18;

select count(*) from hr_yt where termdate>curdate();	-- records with termination date in future

select count(*) from hr_yt where termdate= 0000-00-00;	-- records with no termination date

-- QUESTIONS

-- 1. What is the gender breakdown of employees in the company?

select gender,count(*) as count from hr_yt
where age >= 18 and(termdate>curdate() or  termdate = 0000-00-00)
group by gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?

select race,count(*) as count from hr_yt 
where age >= 18 and(termdate>curdate() or  termdate = 0000-00-00)
group by race order by count desc;

-- 3. What is the age distribution of employees in the company?

select min(age) as youngest, max(age) as oldest
from hr_yt where age >= 18 and(termdate>curdate() or  termdate = 0000-00-00);

select floor(age/10)*10 as age_group, count(*) as count
from hr_yt where age >= 18 group by floor(age/10)*10;

select case
when age >= 18 and age <= 24 then '18-24'
when age >= 25 and age <= 34 then '25-34'
when age >= 35 and age <= 44 then '35-44'
when age >= 45 and age <= 54 then '45-54'
when age >= 55 and age <= 64 then '55-64'
else '65+'
end as age_group,
count(*) as count
from hr_yt where age >= 18 and (termdate > curdate() or termdate = 0000-00-00)
group by age_group order by age_group;

-- genderwise age group 

select case
when age >= 18 and age <= 24 then '18-24'
when age >= 25 and age <= 34 then '25-34'
when age >= 35 and age <= 44 then '35-44'
when age >= 45 and age <= 54 then '45-54'
when age >= 55 and age <= 64 then '55-64'
else '65+'
end as age_group, gender,
count(*) as count
from hr_yt where age >= 18 and (termdate > curdate() or termdate = 0000-00-00)
group by age_group,gender order by age_group,gender;

-- 4. How many employees work at headquarters versus remote locations?

select location,count(*) as count from hr_yt 
where age >= 18 and (termdate > curdate() or  termdate = 0000-00-00)
group by location;

-- 5. What is the average length of employment for employees who have been terminated?

select round(avg(datediff(termdate,hire_date))/365) as avg_emp_length_yrs
from hr_yt where age >= 18 and termdate <= curdate() and termdate != 0000-00-00;

-- 6. How does the gender distribution vary across departments and job titles?

select department,jobtitle,gender, count(*) as count
from hr_yt
where age >= 18 and (termdate > curdate() or  termdate = 0000-00-00)
group by department,jobtitle,gender 
order by department;

-- gender vary as per department only

select department,gender, count(*) as count
from hr_yt
where age >= 18 and (termdate > curdate() or  termdate = 0000-00-00)
group by department,gender 
order by department;

-- 7. What is the distribution of job titles across the company?

select jobtitle, count(*) as count
from hr_yt
where age >= 18 and (termdate > curdate() or  termdate = 0000-00-00)
group by jobtitle 
order by jobtitle desc;

-- 8. Which department has the highest turnover rate? turnover rate at which employees leave a company

select department,count(*) as total_count,
	sum(case when termdate <= curdate() and termdate != 0000-00-00 then 1 else 0 end) as terminated_count,
    sum(case when termdate = 0000-00-00 then 1 else 0 end) as active_count,
    (sum(case when termdate <= curdate() and termdate != 0000-00-00 then 1 else 0 end)/count(*)) as termination_rate

from hr_yt
group by department
order by termination_rate desc;

-- 9. What is the distribution of employees across locations by city and state?

select location_state, count(*) as count
from hr_yt where age >= 18 and (termdate > curdate() or  termdate = 0000-00-00)
group by location_state
order by count desc;

-- 10. How has the company's employee count changed over time based on hire and term dates?

select 
	years, 
    hires,
    terminations, 
    hires - terminations as net_change, 
    round(((hires - terminations)/hires)*100,0) as net_percent_change
from (
	select 
		year(hire_date) as years,
        count(*) as hires,
        sum(case when termdate <= curdate() and termdate != 0000-00-00 then 1 else 0 end) as terminations
	from hr_yt where age >= 18 group by year(hire_date) 
    ) as sub_query
order by years;
    
    
-- 11. What is the tenure distribution for each department?\

select department, round(avg(datediff(termdate,hire_date)/365),0) as avg_tenure
from hr_yt
where age >= 18 and (termdate <= curdate() and termdate != 0000-00-00)
group by department;