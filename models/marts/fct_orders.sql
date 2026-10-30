-- Grain: one row per order.
with orders as (
    select * from {{ ref('stg_olist__orders') }}
),

customers as (
    select customer_id, customer_unique_id, customer_state
    from {{ ref('stg_olist__customers') }}
),

items as (
    select * from {{ ref('int_order_items_agg') }}
),

payments as (
    select * from {{ ref('int_order_payments_agg') }}
),

reviews as (
    select * from {{ ref('int_order_reviews_latest') }}
),

joined as (
    select
        o.order_id,
        c.customer_unique_id,
        c.customer_state,
        o.order_status,
        o.purchased_at,
        cast(o.purchased_at as date)        as purchase_date,
        o.delivered_at,
        o.estimated_delivery_at,
        coalesce(i.items_count, 0)          as items_count,
        coalesce(i.items_revenue, 0)        as items_revenue,
        coalesce(i.freight_value, 0)        as freight_value,
        coalesce(i.items_revenue, 0) + coalesce(i.freight_value, 0) as order_total,
        p.payment_total,
        p.primary_payment_type,
        p.max_installments,
        r.review_score,
        o.delivered_at is not null          as is_delivered,
        case when o.delivered_at is not null
            then {{ dbt.datediff('o.purchased_at', 'o.delivered_at', 'day') }}
        end                                 as delivery_days,
        -- compare calendar days so a delivery at 00:30 isn't counted as a day late by timestamp noise
        case when o.delivered_at is not null
            then {{ dbt.datediff('cast(o.estimated_delivery_at as date)', 'cast(o.delivered_at as date)', 'day') }}
        end                                 as delay_days
    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join items i     on o.order_id = i.order_id
    left join payments p  on o.order_id = p.order_id
    left join reviews r   on o.order_id = r.order_id
)

select
    *,
    case
        when delay_days is null then null
        else delay_days > 0
    end as is_late,
    case
        when delay_days is null then 'Not delivered'
        when delay_days < 0  then 'Early'
        when delay_days = 0  then 'On time'
        when delay_days <= 3 then '1-3 days late'
        when delay_days <= 7 then '4-7 days late'
        else '8+ days late'
    end as delay_bucket
from joined
