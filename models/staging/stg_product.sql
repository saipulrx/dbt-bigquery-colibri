-- Silver layer: Staging
-- DEV  : membaca dari seed raw_product
-- PROD : ganti ref('raw_product') → source('raw', 'raw_product')

with source as (
    select * from {{ ref('raw_product') }}
    -- PROD: select * from {{ source('raw', 'raw_product') }}
),

renamed as (
    select
        product_id_integer          as product_id,
        product_name,
        product_category,
        product_subcategory,
        merk                        as brand,
        cast(unit_price as numeric) as unit_price,
        cast(qty as integer)        as stock_qty,
        current_timestamp()         as _loaded_at
    from source
    where product_id_integer is not null
)

select * from renamed
