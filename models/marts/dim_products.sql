select
    p.product_id,
    p.product_category_name                                          as category_name_pt,
    coalesce(t.product_category_name_english, p.product_category_name, 'unknown') as category_name_en,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
from {{ ref('stg_olist__products') }} p
left join {{ ref('stg_olist__category_translation') }} t
    on p.product_category_name = t.product_category_name
