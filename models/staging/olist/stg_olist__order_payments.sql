select
    order_id || '-' || cast(payment_sequential as varchar)  as payment_key,
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    cast(payment_value as decimal(12, 2))                   as payment_value
from {{ source('olist', 'olist_order_payments_dataset') }}
