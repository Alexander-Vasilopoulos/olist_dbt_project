-- Grain: one row per order. Some orders have several reviews; keep the most recent one.
with ranked as (
    select
        order_id,
        review_id,
        review_score,
        review_created_at,
        row_number() over (
            partition by order_id
            order by review_answered_at desc, review_created_at desc, review_id
        ) as rn
    from {{ ref('stg_olist__order_reviews') }}
)

select order_id, review_id, review_score, review_created_at
from ranked
where rn = 1
