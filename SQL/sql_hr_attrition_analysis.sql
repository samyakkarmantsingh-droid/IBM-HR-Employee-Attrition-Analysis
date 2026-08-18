-- IBM HR Analytics - SQL Analysis
-- ==================================================

USE hr_attrition;


-- ==================================================
-- 1. Job Role × Overtime Attrition
-- Business Question:
-- Which job roles have particularly high attrition
-- among employees who work overtime?
-- ==================================================

SELECT
    JobRole,
    OverTime,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Employees_Left,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS Attrition_Rate
FROM employees
GROUP BY JobRole, OverTime
HAVING COUNT(*) >= 20
ORDER BY Attrition_Rate DESC;


-- ==================================================
-- 2. Overtime Attrition Gap by Job Role
-- Business Question:
-- How much does overtime change attrition within
-- each job role?
-- ==================================================

SELECT
    JobRole,
    MAX(CASE WHEN OverTime = 'Yes' THEN Attrition_Rate END) AS Overtime_Rate,
    MAX(CASE WHEN OverTime = 'No' THEN Attrition_Rate END) AS No_Overtime_Rate,
    ROUND(
        MAX(CASE WHEN OverTime = 'Yes' THEN Attrition_Rate END)
        -
        MAX(CASE WHEN OverTime = 'No' THEN Attrition_Rate END),
        2
    ) AS Attrition_Gap
FROM (
    SELECT
        JobRole,
        OverTime,
        ROUND(
            100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        ) AS Attrition_Rate
    FROM employees
    GROUP BY JobRole, OverTime
    HAVING COUNT(*) >= 20
) AS role_rates
GROUP BY JobRole
HAVING Overtime_Rate IS NOT NULL
   AND No_Overtime_Rate IS NOT NULL
ORDER BY Attrition_Gap DESC;

-- ==================================================
-- 3. Risk Segmentation
-- Business Question:
-- Which combination of overtime, income and tenure
-- is associated with higher observed attrition?

-- Note:
-- Risk thresholds are hypothesis-driven analytical rules,
-- not statistically validated predictive thresholds.
-- ==================================================

SELECT
    CASE
        WHEN OverTime = 'Yes' AND MonthlyIncome < 3000 AND YearsAtCompany <= 3
            THEN 'High Risk'
        WHEN OverTime = 'Yes' AND MonthlyIncome < 5000
            THEN 'Moderate Risk'
        ELSE 'Lower Risk'
    END AS Risk_Segment,

    COUNT(*) AS Total_Employees,

    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Employees_Left,

    ROUND(
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS Attrition_Rate

FROM employees

GROUP BY Risk_Segment

ORDER BY Attrition_Rate DESC;


-- ==================================================
-- 4. Risk Segment Profile
-- Business Question:
-- What characteristics distinguish employees
-- in each risk segment?
-- ==================================================

SELECT
    Risk_Segment,
    AVG(Age) AS Avg_Age,
    ROUND(AVG(MonthlyIncome), 0) AS Avg_Monthly_Income,
    ROUND(AVG(YearsAtCompany), 1) AS Avg_Years_At_Company,
    ROUND(AVG(JobSatisfaction), 2) AS Avg_Job_Satisfaction,
    ROUND(AVG(TotalWorkingYears), 1) AS Avg_Total_Working_Years,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Employees_Left,
    COUNT(*) AS Total_Employees
FROM (
    SELECT
        *,
        CASE
            WHEN OverTime = 'Yes'
                 AND MonthlyIncome < 3000
                 AND YearsAtCompany <= 3
                THEN 'High Risk'
            WHEN OverTime = 'Yes'
                 AND MonthlyIncome < 5000
                THEN 'Moderate Risk'
            ELSE 'Lower Risk'
        END AS Risk_Segment
    FROM employees
) AS segmented
GROUP BY Risk_Segment
ORDER BY
    CASE Risk_Segment
        WHEN 'High Risk' THEN 1
        WHEN 'Moderate Risk' THEN 2
        ELSE 3
    END;


-- ==================================================
-- 5. Retention Prioritization
-- Business Question:
-- Which risk segment should HR prioritize based
-- on both attrition rate and number of employees lost?
-- ==================================================

SELECT
    Risk_Segment,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Employees_Left,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS Attrition_Rate,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / (
            SELECT COUNT(*)
            FROM employees
            WHERE Attrition = 'Yes'
        ),
        2
    ) AS Share_of_All_Attrition
FROM (
    SELECT
        *,
        CASE
            WHEN OverTime = 'Yes'
                 AND MonthlyIncome < 3000
                 AND YearsAtCompany <= 3
                THEN 'High Risk'
            WHEN OverTime = 'Yes'
                 AND MonthlyIncome < 5000
                THEN 'Moderate Risk'
            ELSE 'Lower Risk'
        END AS Risk_Segment
    FROM employees
) AS segmented
GROUP BY Risk_Segment
ORDER BY Employees_Left DESC; 


-- ==================================================
-- 6. Department Attrition Analysis
-- Business Question:
-- Which departments have the highest attrition,
-- and how do income and job satisfaction compare?
-- ==================================================

SELECT
    Department,
    COUNT(*) AS Total_Employees,

    SUM(
        CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END
    ) AS Employees_Left,

    ROUND(
        100.0 *
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS Attrition_Rate,

    ROUND(AVG(MonthlyIncome), 0) AS Avg_Monthly_Income,

    ROUND(AVG(JobSatisfaction), 2) AS Avg_Job_Satisfaction

FROM employees

GROUP BY Department

ORDER BY Attrition_Rate DESC;



-- ==================================================
-- 7. Tenure-Based Attrition Analysis
-- Business Question:
-- How does employee tenure relate to attrition?
-- ==================================================

SELECT
    CASE
        WHEN YearsAtCompany <= 2 THEN '0-2 Years'
        WHEN YearsAtCompany <= 5 THEN '3-5 Years'
        WHEN YearsAtCompany <= 10 THEN '6-10 Years'
        ELSE '10+ Years'
    END AS Tenure_Group,

    COUNT(*) AS Total_Employees,

    SUM(
        CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END
    ) AS Employees_Left,

    ROUND(
        100.0 *
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS Attrition_Rate

FROM employees

GROUP BY Tenure_Group

ORDER BY Attrition_Rate DESC;


-- ==================================================
-- 8. Job Role Attrition Ranking
-- Business Question:
-- Which job roles have the highest attrition rates?
-- ==================================================

WITH role_attrition AS (

    SELECT
        JobRole,
        COUNT(*) AS Total_Employees,

        SUM(
            CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END
        ) AS Employees_Left,

        ROUND(
            100.0 *
            SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        ) AS Attrition_Rate

    FROM employees

    GROUP BY JobRole
)

SELECT
    JobRole,
    Total_Employees,
    Employees_Left,
    Attrition_Rate,

    RANK() OVER (
        ORDER BY Attrition_Rate DESC
    ) AS Attrition_Rank

FROM role_attrition

ORDER BY Attrition_Rank;
