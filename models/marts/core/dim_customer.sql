-- Gold layer: Dimension
-- Tujuan: tabel dimensi customer enriched dengan lifetime metrics
--         dan region mapping dari lookup_region_mapping.

with customer as (
    select * from {{ ref('stg_customer') }}
),

metrics as (
    select * from {{ ref('int_customer_metrics') }}
),

region as (
    select * from {{ ref('lookup_region_mapping') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_sk,

        -- natural key
        c.customer_id,

        -- attributes
        c.customer_name,
        c.email,
        c.address,
        c.city,
        c.country,
        c.gender,

        -- enrichment region dari seed
        r.province,
        r.region,
        r.island,
        r.is_tier1_city,

        -- lifetime metrics (dari intermediate)
        m.total_orders,
        m.total_items_bought,
        m.gross_revenue             as lifetime_gross_revenue,
        m.net_revenue               as lifetime_net_revenue,
        m.avg_order_value,
        m.first_purchase_date,
        m.last_purchase_date,
        m.days_since_last_purchase,
        m.recency_segment,

        -- segmentasi nilai customer
        case
            when m.total_orders = 0 or m.total_orders is null then 'Never Purchased'
            when m.net_revenue >= 10000000                    then 'High Value'
            when m.net_revenue >= 3000000                     then 'Mid Value'
            else 'Low Value'
        end                         as customer_value_segment,

        -- audit
        current_timestamp()         as dbt_updated_at

    from customer c
    left join metrics m on c.customer_id = m.customer_id
    left join region  r on lower(trim(c.city)) = lower(trim(r.city))
)

select * from final
