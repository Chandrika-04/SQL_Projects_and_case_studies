create database if not exists test;
use test;

-- LOCATION TABLE
CREATE TABLE Location (
    Location_ID INT PRIMARY KEY,
    City VARCHAR(50)
);
-- DEPARTMENT TABLE
CREATE TABLE Department (
    Department_Id INT PRIMARY KEY,
    Name VARCHAR(50),
    Location_Id INT,
    FOREIGN KEY (Location_Id) REFERENCES Location(Location_ID)
);
-- JOB TABLE
CREATE TABLE Job (
    Job_ID INT PRIMARY KEY,
    Designation VARCHAR(50)
);
-- Insert into Location
INSERT INTO Location (Location_ID, City) VALUES
(122, 'New York'),
(123, 'Dallas'),
(124, 'Chicago'),
(167, 'Boston');
-- Insert into Department
INSERT INTO Department (Department_Id, Name, Location_Id) VALUES
(10, 'Accounting', 122),
(20, 'Sales', 124),
(30, 'Research', 123),
(40, 'Operations', 167);
-- Insert into Job
INSERT INTO Job (Job_ID, Designation) VALUES
(667, 'Clerk'),
(668, 'Staff'),
(669, 'Analyst'),
(670, 'Sales Person'),
(671, 'Manager'),
(672, 'President');
CREATE TABLE Employee (
    Emp_Id INT PRIMARY KEY,
    Last_Name VARCHAR(50),
    First_Name VARCHAR(50),
    Mid CHAR(1),
    Job_Id INT,
    Hire_Date DATE,
    Salary INT,
    Comm INT,
    Dept_Id INT,
    FOREIGN KEY (Job_Id) REFERENCES Job(Job_ID),
    FOREIGN KEY (Dept_Id) REFERENCES Department(Department_Id)
);
INSERT INTO Employee 
(Emp_Id, Last_Name, First_Name, Mid, Job_Id, Hire_Date, Salary, Comm, Dept_Id)
VALUES
(7369, 'Smith', 'John', 'Q', 667, '1984-12-17', 800, NULL, 20),

(7499, 'Allen', 'Kevin', 'J', 670, '1985-02-20', 1600, 300, 30),

(755, 'Doyle', 'Jean', 'K', 671, '1985-04-04', 2850, NULL, 30),

(756, 'Dennis', 'Lynn', 'S', 671, '1985-05-15', 2750, NULL, 30),

(757, 'Baker', 'Leslie', 'D', 671, '1985-06-10', 2200, NULL, 40),

(7521, 'Wark', 'Cynthia', 'D', 670, '1985-02-22', 1250, 50, 30);

-- 1.List all the locations.

select * from location;

-- 2.List all job details. 

select * from job;

-- 3.List all the department details. 

select * from department;

-- 4.List all the employee details. 

select * from employee;
-- 5.List out the First Name, Last Name, Salary, Comm for all Employees. 

select first_name,last_name,salary,comm from employee;

-- 6. List out the Employee ID, Last Name, Department ID for all employees and alias Employee ID as 
-- ID of the Employee", Last Name as "Name of the Employee", Department ID as "Dep_id". 

select emp_id,last_name as Name_of_the_employee ,dept_id as Dep_id from employee;

-- 7. List out the annual salary of the employees with their names only. 

select First_Name,Salary from employee;

-- 8. List the details about "Smith".
select * from employee
where last_name='smith';

--  9.List out the employees who are working in department 20.
 
select name from department
where department_id=20;

--  10.List out the employees who are earning salary between 2000 and 3000. 

select * from employee
where salary between 2000 and 3000;

-- 11.List out the employees who are working in department 10 or 20. 

select * from employee
where dept_id=10 or dept_id=20;

-- 12. Find out the employees who are not working in department 10 or 30. 

select * from employee
where dept_id NOT IN(10,30);

 -- 13.List out the employees whose name starts with 'L'.
 
 select * from employee
 where first_name like 'L%';
 
 -- 14.List out the employees whose name starts with 'L' and ends with 'E'.
 
 select * from employee
 where first_name like 'L%'and first_name like '%E';
 
 -- 15.List out the employees whose name length is 4 and start with 'J'.
 
 select * from employee 
 where length(first_name)=4 and first_name like 'J%';
 
 -- 16.List out the employees who are working in department 30 and draw the salaries more than 2500.
 
 select * from employee 
 where dept_id=30 and salary>2500;
 
 -- 17. List out the employees who are not receiving commission. 
 
 select * from employee
 where comm is NULL;
 
 
 --  18.List out the Employee ID and Last Name in ascending order based on the Employee ID
 
 select emp_id,last_name
 from employee
 order by emp_id asc,last_name asc;
 
 -- 19. List out the Employee ID and Name in descending order based on salary. 
 
 select emp_id,first_name
 from employee
 order by salary desc;
 
 --  20. List out the employee details according to their Last Name in ascending order.
 
 select * from employee
 order by last_name asc;
 
 -- 21.List out the employee details according to their Last Name in ascending order and then  ID in descending order.
 
select * from employee 
order by last_name asc, dept_id desc;

-- 22. List out the department wise maximum salary, minimum salary and average salary of the  employees. 

select max(salary) as highest_salary , min(salary) as lowest_salary , avg(salary) as average_salary
from employee
group by dept_id;

 -- 23.List out the job wise maximum salary, minimum salary and average salary of the employees.
 
 select max(salary),min(salary) ,avg(salary)
 from employee 
 group by job_id;
 
-- 24. List out the number of employees who joined each month in ascending order. 

select count(emp_id) 
from employee
group by hire_date
order by hire_date;

-- 25. List out the number of employees for each month and year in ascending order based on the year and month. 

select count(emp_id) as no_of_employees ,year(hire_date),month(hire_date)
from employee
group by month(hire_date),year(hire_date)
order by month(hire_date) asc, year(hire_date) asc;

-- 26. List out the Department ID having at least four employees. 

select count(*) ,dept_id from employee
group by dept_id
having count(*)>= 4;

-- 27. How many employees joined in February month. 

select count(*) ,month(hire_date ) as m
from employee
group by m
having m =2;

-- 28. How many employees joined in May or June month. 

select count(*) ,month(hire_date ) as month
from employee
group by m
having m =5 or m=6;

-- 29. How many employees joined in 1985? 

select count(*) ,year(hire_date ) as year
from employee
group by y
having y= 1985;

-- 30. How many employees joined each month in 1985? 

SELECT MONTH(hire_date) AS month, COUNT(*) AS total_employees
FROM employee
WHERE YEAR(hire_date) = 1985
GROUP BY MONTH(hire_date)
ORDER BY month;

-- 31. How many employees were joined in April 1985? 

SELECT COUNT(*) AS total_employees
FROM employee
WHERE YEAR(hire_date) = 1985
  AND MONTH(hire_date) = 4;
  
-- 32. Which is the Department ID having greater than or equal to 3 employees joining in April 1985? 

SELECT dept_id, COUNT(*) AS total_employees
FROM employee
WHERE YEAR(hire_date) = 1985
  AND MONTH(hire_date) = 4
GROUP BY dept_id
HAVING COUNT(*) >= 3;

-- 33.List out employees with their department names. 

select e.emp_id,e.first_name,d.name
from employee e
LEFT JOIN department d
ON e.dept_id=d.department_id;

-- 34. Display employees with their designations. 

select e.emp_id,e.first_name,j.job_id,j.designation
from employee e
left JOIN job j
ON e.job_id=j.job_id;

-- 35. Display the employees with their department names and city.
 
select e.emp_id,e.first_name,d.name,d.location_id
from employee e
LEFT JOIN department d
ON e.dept_id=d.department_id;

-- 36. How many employees are working in different departments? Display with department names.

select e.emp_id,e.first_name,d.name
from employee e
LEFT JOIN department d
ON e.dept_id=d.department_id;

-- 37. How many employees are working in the sales department? 

select COUNT(e.emp_id),d.name
from employee e
LEFT JOIN department d
ON e.dept_id=d.department_id 
where d.name='sales';

-- 38. Which is the department having greater than or equal to 3 employees and display the department  names in ascending order. 

select COUNT(e.emp_id),d.name
from employee e
LEFT JOIN department d
ON e.dept_id=d.department_id 
group by d.name
having count(emp_id)>=3
order by count(emp_id) asc;

-- 39. How many employees are working in 'Dallas'? 

SELECT COUNT(e.emp_id) AS total_employees
FROM employee e
JOIN department d ON e.dept_id = d.department_id
JOIN location l ON d.location_id = l.location_id
WHERE l.city = 'Dallas';

-- 40. Display all employees in sales or operation departments.

select DISTINCT e.emp_id,d.name
from employee e
LEFT JOIN department d
ON e.dept_id=d.department_id 
WHERE TRIM(LOWER(d.name)) IN ('sales', 'operations');

-- 41. Display the employee details with salary grades. Use conditional statement to create a grade column. 

select emp_id,salary, case when salary>2000 then 'A'
							when salary>1500 then 'B'
                            when salary>1000 then 'C'
                            else 'D' end as grade
from employee;

-- 42. List out the number of employees grade wise. Use conditional statement to create a grade column.

select  case when salary>2000 then 'A'
							when salary>1500 then 'B'
                            when salary>1000 then 'C'
                            else 'D' end as grade,count(*) as num_of_employees
from employee
group by case when salary>2000 then 'A'
							when salary>1500 then 'B'
                            when salary>1000 then 'C'
                            else 'D' end 
order by grade;

-- 43. Display the employee salary grades and the number of employees between 2000 to 5000 range of salary. 

SELECT 
    CASE
        WHEN salary BETWEEN 2000 AND 3000 THEN 'Grade C'
        WHEN salary BETWEEN 3001 AND 4000 THEN 'Grade B'
        WHEN salary BETWEEN 4001 AND 5000 THEN 'Grade A'
    END AS salary_grade,
    COUNT(*) AS number_of_employees
FROM employee
WHERE salary BETWEEN 2000 AND 5000
GROUP BY 
    CASE
        WHEN salary BETWEEN 2000 AND 3000 THEN 'Grade C'
        WHEN salary BETWEEN 3001 AND 4000 THEN 'Grade B'
        WHEN salary BETWEEN 4001 AND 5000 THEN 'Grade A'
    END
ORDER BY salary_grade;

--  44.Display the employees list who got the maximum salary.

select emp_id,salary
from employee 
where salary=(select max(salary) from employee);

-- 45 Display the employees who are working in the sales department.

select emp_id,first_name
from employee
where dept_id IN (select dept_id from department where name='sales');

-- 46.Display the employees who are working as 'Clerk'

select emp_id,first_name
from employee
where job_id IN (select job_id from job where designation='clerk');

-- 47. Display the list of employees who are living in 'Boston'. 

SELECT emp_id, first_name
FROM employee
WHERE dept_id IN (
    SELECT department_id
    FROM department
    WHERE location_id = (
        SELECT location_id
        FROM location
        WHERE city = 'Boston'
    )
);

-- 48. Find out the number of employees working in the sales department. 

SELECT COUNT(emp_id)
FROM employee
WHERE dept_id IN (
    SELECT department_id
    FROM department
    WHERE name = 'Sales'
);

-- 49.Update the salaries of employees who are working as clerks on the basis of 10%. 

update employee
set salary=salary*1.10
where job_id = (select job_id FROM job WHERE designation = 'Clerk');

-- 50. Display the second highest salary drawing employee details. 

SELECT *
FROM employee
WHERE salary = (SELECT MAX(salary) FROM employee WHERE salary < (SELECT MAX(salary) FROM employee));

-- 51. List out the employees who earn more than every employee in department 30. 

SELECT * FROM employee
WHERE salary > ALL ( SELECT salary FROM employee WHERE dept_id = 30);

-- 52. Find out which department has no employees. 

select dept_id from department d
where not exists (select 1 from employee e where d.dept_id=e.dept_id);

-- 53. Find out the employees who earn greater than the average salary for their department.

SELECT * FROM employee e
WHERE salary > (SELECT AVG(salary) FROM employee WHERE dept_id = e.dept_id
);