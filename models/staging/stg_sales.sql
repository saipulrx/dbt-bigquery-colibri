-- Silver layer: Staging
-- DEV  : membaca dari seed raw_sales
-- PROD : ganti ref('raw_sales') → source('raw', 'raw_sales')

with source as (
    select * from {{ ref('raw_sales') }}
    -- PROD: select * from {{ source('raw', 'raw_sales') }}
),

renamed as (
    select
        sales_id_integer                        as sales_id,
        product_id,
        customer_id,
        time_id,
        location_id,
        cast(item_solds as integer)             as item_sold_qty,
        cast(discount as numeric)               as discount_amount,
        cast(sales_amount as numeric)           as sales_amount,
        cast(sales_date as datetime)            as sales_datetime,
        cast(sales_date as date)                as sales_date,
        cast(sales_amount as numeric)
            - cast(discount as numeric)         as net_sales_amount,
        current_timestamp()                     as _loaded_at
    from source
    where sales_id_integer is not null
        and sales_amount > 0
)

select * from renamed
