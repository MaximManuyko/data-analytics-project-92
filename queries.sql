--Напишите запрос, который считает общее количество покупателей. Назовите колонку customers_count

select count(1) as customers_count
from customers;
---------------------

--Первый отчет о десятке лучших продавцов. Таблица состоит из трех колонок - данных о продавце, суммарной выручке с проданных товаров и количестве проведенных сделок, и отсортирована по убыванию выручки:

--name — имя и фамилия продавца
--operations - количество проведенных сделок
--income — суммарная выручка продавца за все время

--Вариант 1
SELECT  CONCAT_WS(' ', employees.first_name, employees.last_name) AS name,
        COUNT(*) AS operations, 
        SUM(sales.quantity * products.price) AS income
FROM sales
LEFT JOIN employees ON employees.employee_id = sales.sales_person_id
LEFT JOIN products ON products.product_id = sales.product_id 
GROUP BY CONCAT_WS(' ', employees.first_name, employees.last_name)
order by income desc
limit 10;

--Вариант 2
SELECT  employees.first_name|| ' ' ||employees.last_name AS name,
        COUNT(*) AS operations, 
        SUM(sales.quantity * products.price) AS income
FROM sales
LEFT JOIN employees ON employees.employee_id = sales.sales_person_id
LEFT JOIN products ON products.product_id = sales.product_id 
GROUP BY employees.first_name|| ' ' ||employees.last_name
order by income desc
limit 10;
---------------------


--Второй отчет содержит информацию о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам. Таблица отсортирована по выручке по возрастанию.
--name — имя и фамилия продавца
--average_income — средняя выручка продавца за сделку с округлением до целого

WITH subquery AS (
    SELECT first_name || ' ' || last_name AS name,
            ROUND(AVG(quantity * price), 0) AS average_income
    FROM sales
    LEFT JOIN employees ON employees.employee_id = sales.sales_person_id 
    LEFT JOIN products ON products.product_id = sales.product_id 
    GROUP BY first_name || ' ' || last_name
)
SELECT name, average_income
FROM subquery
WHERE average_income < (SELECT AVG(average_income) FROM subquery)
ORDER BY average_income;
---------------------

--Третий отчет содержит информацию о выручке по дням недели. Каждая запись содержит имя и фамилию продавца, день недели и суммарную выручку. Отсортируйте данные по порядковому номеру дня недели и name
--name — имя и фамилия продавца
--weekday — название дня недели на английском языке
--income — суммарная выручка продавца в определенный день недели, округленная до целого числа


SELECT 
    name,
    weekday,
    sum as income
FROM (
    SELECT 
    e.first_name || ' ' || e.last_name AS name,
    CASE 
        WHEN extract(isodow from s.sale_date) = 1 THEN 'Monday'
        WHEN extract(isodow from s.sale_date) = 2 THEN 'Tuesday'
        WHEN extract(isodow from s.sale_date) = 3 THEN 'Wednesday'
        WHEN extract(isodow from s.sale_date) = 4 THEN 'Thursday'
        WHEN extract(isodow from s.sale_date) = 5 THEN 'Friday'
        WHEN extract(isodow from s.sale_date) = 6 THEN 'Saturday'
        WHEN extract(isodow from s.sale_date) = 7 THEN 'Sunday'
    END AS weekday,
    round(sum(s.quantity * p.price)) AS sum,
    extract(isodow from s.sale_date) AS number
    FROM 
    sales s 
    JOIN employees e ON s.sales_person_id = e.employee_id 
    JOIN products p ON s.product_id = p.product_id
    GROUP BY 
    e.first_name, e.last_name, weekday, number
    ORDER BY 4, 1
) as t
---------------------

--Первый отчет - количество покупателей в разных возрастных группах: 10-15, 16-25, 26-40 и 40+. Итоговая таблица должна быть отсортирована по возрастным группам и содержать следующие поля:
--age_category - возрастная группа
--count - количество человек в группе


SELECT 
    age_categories.age_category,
    COALESCE(COUNT(customers.age), 0) AS count
FROM 
    (SELECT '16-25' AS age_category
        UNION SELECT '26-40'
        UNION SELECT '40+') AS age_categories
LEFT JOIN 
    customers ON 
    CASE 
        WHEN customers.age BETWEEN 16 AND 25 THEN '16-25' 
        WHEN customers.age BETWEEN 26 AND 40 THEN '26-40' 
        ELSE '40+' 
    END = age_categories.age_category
GROUP BY 
    age_categories.age_category 
ORDER BY 
    age_categories.age_category ASC;
---------------------

--Во втором отчете предоставьте данные по количеству уникальных покупателей и выручке, которую они принесли. Сгруппируйте данные по дате, которая представлена в числовом виде ГОД-МЕСЯЦ. Итоговая таблица должна быть отсортирована по дате по возрастанию и содержать следующие поля:
--date - дата в указанном формате
--total_customers - количество покупателей
--income - принесенная выручка



SELECT 
    TO_CHAR(DATE_TRUNC('month', s.sale_date), 'YYYY-MM') AS date,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    SUM(s.quantity * p.price) AS income
FROM 
    sales s
LEFT JOIN 
    products p ON s.product_id = p.product_id 
GROUP BY 
    DATE_TRUNC('month', s.sale_date)
ORDER BY 
    date ASC;
---------------------

--Третий отчет следует составить о покупателях, первая покупка которых была в ходе проведения акций (акционные товары отпускали со стоимостью равной 0). Итоговая таблица должна быть отсортирована по id покупателя и дате покупки. Таблица состоит из следующих полей:
--customer - имя и фамилия покупателя
--sale_date - дата покупки
--seller - имя и фамилия продавца

SELECT 
    sub.customer,
    sub.sale_date,
    sub.seller
FROM 
    (
        SELECT 
            CONCAT(c.first_name, ' ', c.last_name) AS customer,
            s.sale_date,
            CONCAT(e.first_name, ' ', e.last_name) AS seller,
            ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY s.sale_date) AS rn
        FROM 
            sales s
            INNER JOIN customers c ON s.customer_id = c.customer_id
            INNER JOIN employees e ON s.sales_person_id = e.employee_id
            INNER JOIN products p ON s.product_id = p.product_id
        WHERE 
            p.price = 0
    ) sub
WHERE 
    sub.rn = 1
ORDER BY 
    sub.customer, sub.sale_date;


--Второй вариант
SELECT DISTINCT ON (c.customer_id)
    c.first_name || ' ' || c.last_name AS customer,
    s.sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM
    sales s
LEFT JOIN
    customers c ON c.customer_id = s.customer_id
LEFT JOIN
    employees e ON e.employee_id = s.sales_person_id
LEFT JOIN
    products p ON p.product_id = s.product_id
WHERE
    p.price = 0
ORDER BY
    c.customer_id, s.sale_date;
    ---------------------