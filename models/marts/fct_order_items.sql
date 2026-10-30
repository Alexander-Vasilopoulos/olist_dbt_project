-- Grain: one row per order line item. Use this for seller and product analysis.
select
    i.order_item_key,
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    o.customer_unique_id,
    o.order_status,
    o.purchase_date,
    i.price,
    i.freight_value,
    i.price + i.freight_value   as item_total,
    o.is_late,
    o.delay_days,
    o.review_score
from {{ ref('stg_olist__order_items') }} i
left join {{ ref('fct_orders') }} o on i.order_id = o.order_id
