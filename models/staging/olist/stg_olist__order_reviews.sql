select
    review_id,                  -- NOT unique in the raw data (see intermediate model)
    order_id,
    review_score,
    cast(review_creation_date as timestamp)     as review_created_at,
    cast(review_answer_timestamp as timestamp)  as review_answered_at
from {{ source('olist', 'olist_order_reviews_dataset') }}
