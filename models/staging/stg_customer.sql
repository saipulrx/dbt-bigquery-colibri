-- Silver layer: Staging
-- DEV  : membaca dari seed raw_customer
-- PROD : ganti ref('raw_customer') → source('raw', 'raw_customer')

with source as (
    select * from {{ ref('raw_customer') }}
    -- PROD: select * from {{ source('raw', 'raw_customer') }}
),

renamed as (
    select
        customer_id_integer         as customer_id,
        customer_name,
        lower(email)                as email,
        address,
        city,
        country,
        upper(trim(gender))         as gender,
        current_timestamp()         as _loaded_at
    from source
    where customer_id_integer is not null
)

select * from renamed
