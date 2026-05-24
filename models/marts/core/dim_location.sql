-- Gold layer: Dimension
-- Tujuan: tabel dimensi lokasi toko enriched dengan region mapping
--         dari lookup_region_mapping.

with location as (
    select * from {{ ref('stg_location') }}
),

region as (
    select * from {{ ref('lookup_region_mapping') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['location_id']) }} as location_sk,

        -- natural key
        l.location_id,

        -- attributes
        l.shop_name,
        l.shop_address,
        l.shop_city,
        l.shop_province,
        l.shop_country,

        -- enrichment dari lookup_region_mapping
        r.region,
        r.island,
        r.is_tier1_city,

        -- audit
        current_timestamp()     as dbt_updated_at

    from location l
    left join region r on lower(trim(l.shop_city)) = lower(trim(r.city))
)

select * from final
