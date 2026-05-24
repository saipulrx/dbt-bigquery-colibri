-- Silver layer: Staging
-- DEV  : membaca dari seed calendar (kalender lengkap)
-- PROD : ganti ref('calendar') → source('raw', 'raw_time')
-- CATATAN: seed calendar lebih lengkap, bahkan di production
--          calendar tetap direkomendasikan untuk dim_time.

with source as (
    select * from {{ ref('calendar') }}
    -- PROD: select * from {{ source('raw', 'raw_time') }}
),

renamed as (
    select
        time_id,
        cast(full_date as date)     as full_date,
        day_of_month,
        month_number,
        year_number,
        day_name,
        month_name,
        is_weekend,
        quarter,
        year_month,
        current_timestamp()         as _loaded_at
    from source
    where time_id is not null
)

select * from renamed
