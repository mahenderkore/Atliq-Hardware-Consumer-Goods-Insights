use gdb023;
show tables;
select * from dim_customer;
select * from  dim_product;
select * from  fact_gross_price;
select * from  fact_manufacturing_cost;
select * from  fact_pre_invoice_deductions;
select * from  fact_sales_monthly;


/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

select 
distinct(market) as Markets
from dim_customer 
where customer='Atliq Exclusive' and region ='APAC';



/*2. What is the percentage of unique product increase in 2021 vs. 2020?*/

with unique_product as(
select 
count(distinct case when fiscal_year = 2020 then product_code end) as unique_products_2020,
count(distinct case when fiscal_year = 2021 then product_code end) as unique_products_2021,
((count(distinct case when fiscal_year = 2021 then product_code end) -
 count(distinct case when fiscal_year = 2020 then product_code end)) / count(distinct 
 case when fiscal_year = 2020 then product_code end))* 100 as percentage_cg
from fact_sales_monthly)
select 
unique_products_2020,unique_products_2021,
round(percentage_cg,2) as percentage_chg
from unique_product;

 

/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts.*/ 

select segment, count( distinct product) as product_count
from dim_product 
group by segment
order by product_count desc;



/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020?*/

with seg as
(
select B.segment ,
count(distinct case when A.fiscal_year = '2020' then B.product end) as 'product_count_2020',
count(distinct case when A.fiscal_year = '2021' then B.product end) as 'product_count_2021',
((count(distinct case when A.fiscal_year = '2021' then B.product end))-
(count(distinct case when A.fiscal_year = '2020' then B.product end))) as 'difference'
from fact_sales_monthly as A
inner join dim_product as B
on A.product_code = B.product_code
group by segment)
select * , round((difference/product_count_2020)*100,2) as percentage_increase
from seg
group by segment
order by percentage_increase desc;


/*5. Get the products that have the highest and lowest manufacturing costs*/


with prod as
(select 
A.product,B.manufacturing_cost 
from dim_product as A
inner join fact_manufacturing_cost as B
on A.product_code = B.product_code)
select * from prod
where manufacturing_cost = (select max(manufacturing_cost) from prod)
or manufacturing_cost= (select min(manufacturing_cost) from prod)
order by manufacturing_cost desc; 




/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market.*/


select 
A.customer,B.customer_code,
round(avg(B.pre_invoice_discount_pct)*100,2) as average_discount_percentage
from dim_customer as A
inner join fact_pre_invoice_deductions as B
on A.customer_code = B.customer_code
where B.fiscal_year = '2021' and A.market='India'
group by A.customer_code , A.customer 
order by average_discount_percentage desc limit 5;


/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.*/


select
extract(year from B.date) as year,extract(month from B.date) as Month,
sum(B.sold_quantity*C.gross_price) as 'Gross sales amount' 
from dim_customer as A
inner join fact_sales_monthly as B
on A.customer_code = B.customer_code
inner join fact_gross_price as C
on B.product_code = C.product_code
where A.customer  ='Atliq Exclusive'
group by month,year
order by year,month desc;


/*8. In which quarter of 2020, got the maximum total_sold_quantity?*/

select 
concat('Q',extract(quarter from date)) as Quarter,
sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where extract(year from date)='2020'
group by Quarter
order by total_sold_quantity desc;




    
/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution?*/

with chnl as
(select 
A.channel,
sum(B.sold_quantity*C.gross_price) as gross_sales_mln
from dim_customer as A
inner join fact_sales_monthly as B
on A.customer_code =B.customer_code
inner join fact_gross_price as C
on B.product_code = C.product_code
where B.fiscal_year='2021'
group by A.channel)
select channel, gross_sales_mln, 
round(gross_sales_mln*100/(select sum(gross_sales_mln)from chnl),2) as percentage_contribution
from chnl
group by channel, gross_sales_mln 
order by gross_sales_mln desc;


/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021?*/


with sld as 
(select A.division,A.product_code,A.product,
sum(B.sold_quantity) as total_sold_quantity
from dim_product as A
inner join fact_sales_monthly as B
on A.product_code = B.product_code
where B.fiscal_year = '2021'
group by division,product_code,product),
rnk as(
select *,rank() over(partition by division order by
total_sold_quantity desc) as rank_order
from sld)
select * from 
rnk
where rank_order<=3;
 
 
 