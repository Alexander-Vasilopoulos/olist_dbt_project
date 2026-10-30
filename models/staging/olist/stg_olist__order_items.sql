select
    order_id || '-' || cast(order_item_id as varchar)  as order_item_key,
    order_id,
    order_item_id,
    product_id,
    seller_id,
    cast(shipping_limit_date as timestamp)             as shipping_limit_at,
    cast(price as decimal(12, 2))                      as price,
    cast(freight_value as decimal(12, 2))              as freight_value
from {{ source('olist', 'olist_order_items_dataset') }}
