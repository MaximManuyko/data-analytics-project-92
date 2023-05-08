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



--Второй отчет содержит информацию о продавцах, чья выручка меньше средней выручки по всем продавцам. Таблица отсортирована по выручке по возрастанию.

--name — имя и фамилия продавца
--average_income — средняя выручка продавца за все время с округлением до целого

SELECT CONCAT_WS(' ', employees.first_name, employees.last_name) AS name, ROUND(SUM(sales.quantity * products.price)) AS average_income
FROM sales
LEFT JOIN employees ON employees.employee_id = sales.sales_person_id
LEFT JOIN products ON products.product_id = sales.product_id 
GROUP BY employees.employee_id
HAVING SUM(sales.quantity * products.price) < 
       (SELECT AVG(total_income) FROM
           (SELECT SUM(sales.quantity * products.price) AS total_income
            FROM sales
            LEFT JOIN employees ON employees.employee_id = sales.sales_person_id
            LEFT JOIN products ON products.product_id = sales.product_id 
            GROUP BY sales.sales_person_id) AS subquery)
order by 2;


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