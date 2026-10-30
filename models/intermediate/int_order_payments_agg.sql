-- Grain: one row per order. An order can be paid with several payments
-- (e.g. voucher + credit card), so summing payments straight onto orders would double count.
with payments as (
    select
        *,
        row_number() over (
            partition by order_id
            order by payment_value desc, payment_sequential
        ) as value_rank
    from {{ ref('stg_olist__order_payments') }}
),

aggregated as (
    select
        order_id,
        count(*)                         as payments_count,
        sum(payment_value)               as payment_total,
        max(payment_installments)        as max_installments,
        max(case when value_rank = 1 then payment_type end) as primary_payment_type
    from payments
    group by order_id
)

select * from aggregated
