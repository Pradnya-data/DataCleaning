-- Data Cleaning using SQL

create database datacleaning;

use datacleaning;

-- create table

CREATE TABLE employees (
    employee_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    hire_date DATE,
    salary DECIMAL(10, 2),
    department VARCHAR(50)
);



--  removing duplicates
SELECT employee_id, COUNT(*)
FROM employees
GROUP BY employee_id
HAVING COUNT(*) > 1;


-- 1. Remove duplicates (keep only one row per employee_id)
DELETE FROM employees
WHERE employee_id IN (
    SELECT employee_id
    FROM employees
    GROUP BY employee_id
    HAVING COUNT(*) > 1
);


-- 2. Handling Missing Values

-- a)	Identify Missing Values:
SELECT * 
FROM employees
WHERE email IS NULL OR salary IS NULL;

-- b) Update or Remove Records with Missing Data

-- Set default values for missing data
UPDATE employees
SET email = 'noemail@company.com'
WHERE email IS NULL;

-- Remove records with missing salary
DELETE FROM employees
WHERE salary IS NULL;

-- 3. Fixing Incorrect Formats

-- Convert email addresses to lowercase

UPDATE employees
SET email = LOWER(email);

-- 4. Normalizing Data  Normalization ensures that data is stored efficiently, without redundancies, and can be easily updated.

-- Create a new table for departments
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(50)
);

INSERT INTO departments (department_name)
SELECT DISTINCT department FROM employees;

-- Add a foreign key column to the employees table
ALTER TABLE employees ADD COLUMN department_id INT;

-- Update employees to reference the department_id
UPDATE employees e
JOIN departments d ON e.department = d.department_name
SET e.department_id = d.department_id;

-- Drop the old department column
ALTER TABLE employees DROP COLUMN department;

-- 5. Handling Outliers

-- Outliers can skew your data analysis. For instance, let’s say salaries over 1,000,000 are outliers and you want to cap them.

-- Identify salary outliers
SELECT * 
FROM employees
WHERE salary > 1000000;

-- Cap salaries to a maximum value
UPDATE employees
SET salary = 1000000
WHERE salary > 1000000;


-- 6. Standardizing Text Data 
-- Inconsistent text data (like names) can cause issues in analysis. You might want to standardize this by capitalizing the first letter of each name.

-- Capitalize the first letter of each name
UPDATE employees
SET first_name = CONCAT(UPPER(LEFT(first_name, 1)), LOWER(SUBSTRING(first_name, 2))),
    last_name = CONCAT(UPPER(LEFT(last_name, 1)), LOWER(SUBSTRING(last_name, 2)));


-- a)  Using CASE for Conditional Data Cleaning

UPDATE employees
SET department = CASE 
    WHEN department IN ('HR', 'Human Resources', 'hr') THEN 'Human Resources'
    WHEN department IN ('IT', 'Information Technology') THEN 'Information Technology'
    ELSE department
END;


-- b) Using Window Functions to Identify Patterns

WITH RankedEmployees AS (
    SELECT employee_id, first_name, last_name, 
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY hire_date) AS rn
    FROM employees
)
-- Delete all but the first occurrence of each duplicate
DELETE FROM employees
WHERE employee_id IN (
    SELECT employee_id
    FROM RankedEmployees
    WHERE rn > 1
);

-- c) Regular Expressions (REGEXP) for Text Cleanup
-- If you want to find records where emails do not match a valid pattern:

SELECT *
FROM employees
WHERE email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

-- 7. Pivoting Data for Normalization (GROUP BY + Aggregation)

-- Aggregating Salaries by Department

SELECT department, AVG(salary) AS avg_salary
FROM employees
GROUP BY department;

-- 8. Coalesce for Filling Missing Data   COALESCE() is used to fill in missing values with a default or fallback value, making it great for cleaning up NULLs in the data.

SELECT employee_id, COALESCE(salary, 0) AS salary
FROM employees;

-- OR
UPDATE employees
SET salary = COALESCE(salary, 0);

-- 9. Data Type Casting (CAST and CONVERT)

-- Converting Text to Date

SELECT CAST(hire_date AS DATE) AS formatted_date
FROM employees;

-- You can also update the column directly
UPDATE employees
SET hire_date = CAST(hire_date AS DATE)
WHERE hire_date IS NOT NULL;

-- 10. Using TRIM for Cleaning Extra Whitespace 
UPDATE employees
SET first_name = TRIM(first_name),
    last_name = TRIM(last_name);

-- 11. Removing Non-Numeric Characters (REGEXP_REPLACE)

UPDATE employees
SET phone_number = REGEXP_REPLACE(phone_number, '[^0-9]', '');
-- This will remove any character that is not a digit from the phone_number column.

-- 12. . Advanced Data Validation with Check Constraints

-- Adding a Check Constraint for Salary
ALTER TABLE employees
ADD CONSTRAINT chk_salary CHECK (salary >= 0 AND salary <= 1000000);


-- 13. Automating Data Cleanup Using Stored Procedures
DELIMITER &&
CREATE PROCEDURE CleanEmployeeData()
BEGIN
    -- Remove duplicates
    DELETE FROM employees
    WHERE employee_id IN (
        SELECT employee_id
        FROM (SELECT employee_id, COUNT(*)
              FROM employees
              GROUP BY employee_id
              HAVING COUNT(*) > 1) AS dup
    );
    
    -- Fix emails
    UPDATE employees
    SET email = LOWER(email)
    WHERE email IS NOT NULL;

    -- Fill missing salaries with 0
    UPDATE employees
    SET salary = COALESCE(salary, 0)
    WHERE salary IS NULL;
END &&
DELIMITER ;












