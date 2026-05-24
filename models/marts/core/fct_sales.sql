-- Gold layer: Fact
-- Tujuan: tabel fakta transaksi penjualan di grain 1 baris = 1 transaksi.
--         Join ke surrogate key dari semua dim table.

with enriched as (
    select * from {{ ref('int_sales_enriched') }}
),

dim_product as (
    select product_id, product_sk from {{ ref('dim_product') }}
),

dim_customer as (
    select customer_id, customer_sk from {{ ref('dim_customer') }}
),

dim_time as (
    select time_id, time_sk from {{ ref('dim_time') }}
),

dim_location as (
    select location_id, location_sk from {{ ref('dim_location') }}
),

final as (
    select
        -- surrogate key fakta
        {{ dbt_utils.generate_surrogate_key(['e.sales_id']) }} as sales_sk,

        -- natural key
        e.sales_id,

        -- foreign keys ke dimensi (surrogate key)
        dp.product_sk,
        dc.customer_sk,
        dt.time_sk,
        dl.location_sk,

        -- degenerate dimensions (tidak perlu dim table sendiri)
        e.sales_date,
        e.sales_datetime,

        -- measures additive
        e.item_sold_qty,
        e.discount_amount,
        e.sales_amount          as gross_sales_amount,
        e.net_sales_amount,

        -- measures semi-additive / derived
        e.avg_selling_price,
        e.unit_price            as listed_unit_price,

        -- flags bisnis
        e.is_repeat_purchase,
        e.customer_order_sequence,

        -- audit
        current_timestamp()     as dbt_updated_at

    from enriched e
    left join dim_product  dp on e.product_id  = dp.product_id
    left join dim_customer dc on e.customer_id = dc.customer_id
    left join dim_time     dt on e.time_id     = dt.time_id
    left join dim_location dl on e.location_id = dl.location_id
)

select * from final
