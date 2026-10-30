-- Findings queries for the Olist dbt project (Snowflake).
-- Run against the marts and staging schemas built by `dbt build`.
-- Replace ANALYTICS.DBT_AVASILOPOULOS_* with your own database and schema if they differ.

-- Finding 1: review score by delivery delay
select delay_bucket,
       count(*) as orders,
       round(avg(review_score), 2) as avg_review_score
from ANALYTICS.DBT_AVASILOPOULOS_MARTS.FCT_ORDERS
where is_delivered
group by delay_bucket
order by min(delay_days);

-- Finding 2a: overall late rate
select count(*) as delivered_orders,
       round(100 * avg(iff(is_late, 1, 0)), 1) as late_pct
from ANALYTICS.DBT_AVASILOPOULOS_MARTS.FCT_ORDERS
where is_delivered;

-- Finding 2b: states with the highest late rate (300+ delivered orders)
select customer_state,
       count(*) as delivered_orders,
       round(100 * avg(iff(is_late, 1, 0)), 1) as late_pct
from ANALYTICS.DBT_AVASILOPOULOS_MARTS.FCT_ORDERS
where is_delivered
group by customer_state
having count(*) >= 300
order by late_pct desc
limit 5;

-- Finding 3: revenue from late-delivered orders
select round(sum(case when is_late then items_revenue end), 0) as late_revenue,
       round(100 * sum(case when is_late then items_revenue end) / sum(items_revenue), 1) as pct_of_delivered_revenue
from ANALYTICS.DBT_AVASILOPOULOS_MARTS.FCT_ORDERS
where is_delivered;

-- Data quality 1: orders with more than one review
select count(*) as orders_with_multiple_reviews
from (select order_id
      from ANALYTICS.DBT_AVASILOPOULOS_STAGING.STG_OLIST__ORDER_REVIEWS
      group by order_id
      having count(*) > 1);

-- Data quality 2: revenue inflated by a naive join of items to payments
select (select sum(price)
        from ANALYTICS.DBT_AVASILOPOULOS_STAGING.STG_OLIST__ORDER_ITEMS) as correct_revenue,
       (select sum(i.price)
        from ANALYTICS.DBT_AVASILOPOULOS_STAGING.STG_OLIST__ORDER_ITEMS i
        join ANALYTICS.DBT_AVASILOPOULOS_STAGING.STG_OLIST__ORDER_PAYMENTS p
          on i.order_id = p.order_id) as naive_join_revenue;

-- Data quality 3: orders marked delivered without a delivery date
select count(*) as delivered_without_date
from ANALYTICS.DBT_AVASILOPOULOS_MARTS.FCT_ORDERS
where order_status = 'delivered'
  and delivered_at is null;
