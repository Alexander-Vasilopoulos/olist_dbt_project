-- Grain: one row per real customer (customer_unique_id), not per order.
with customer_orders as (
    select
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.purchased_at,
        row_number() over (
            partition by c.customer_unique_id
            order by o.purchased_at desc, o.order_id
        ) as rn
    from {{ ref('stg_olist__customers') }} c
    left join {{ ref('stg_olist__orders') }} o on c.customer_id = o.customer_id
)

select
    customer_unique_id,
    max(case when rn = 1 then customer_city  end)   as customer_city,   -- location of latest order
    max(case when rn = 1 then customer_state end)   as customer_state,
    count(order_id)                                 as orders_count,
    min(purchased_at)                               as first_purchase_at,
    max(purchased_at)                               as last_purchase_at,
    count(order_id) > 1                             as is_repeat_customer
from customer_orders
group by customer_unique_id
