-- Grain: one row per order. Collapses line items so joins to orders can't fan out.
select
    order_id,
    count(*)                        as items_count,
    count(distinct seller_id)       as sellers_count,
    sum(price)                      as items_revenue,
    sum(freight_value)              as freight_value
from {{ ref('stg_olist__order_items') }}
group by order_id
