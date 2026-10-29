select
    customer_id,                -- one per ORDER, not per person
    customer_unique_id,         -- the real customer
    customer_zip_code_prefix    as zip_code_prefix,
    customer_city,
    customer_state
from {{ source('olist', 'olist_customers_dataset') }}
