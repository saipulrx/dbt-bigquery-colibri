-- Silver layer: Staging
-- DEV  : membaca dari seed raw_location
-- PROD : ganti ref('raw_location') → source('raw', 'raw_location')

with source as (
    select * from {{ ref('raw_location') }}
    -- PROD: select * from {{ source('raw', 'raw_location') }}
),

renamed as (
    select
        location_id_integer         as location_id,
        shop_name,
        shop_address,
        shop_city,
        shop_province,
        shop_country,
        current_timestamp()         as _loaded_at
    from source
    where location_id_integer is not null
)

select * from renamed
