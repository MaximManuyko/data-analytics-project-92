"customers_count"
19759


--Подготовьте в файл top_10_total_income.csv отчет с продавцами у которых наибольшая выручка
SELECT CONCAT_WS(' ', employees.first_name, employees.last_name) AS name, COUNT(*) AS operations, SUM(sales.quantity * products.price) AS income
FROM sales
LEFT JOIN employees ON employees.employee_id = sales.sales_person_id
LEFT JOIN products ON products.product_id = sales.product_id 
GROUP BY CONCAT_WS(' ', employees.first_name, employees.last_name)
order by income desc
limit 10;