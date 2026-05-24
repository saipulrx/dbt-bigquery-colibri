-- Gold layer: Mart Aggregasi
-- Tujuan: revenue harian per lokasi dan kategori produk.
--         Dikonsumsi langsung oleh dashboard Revenue Overview.
-- Grain: 1 baris = 1 kombinasi (tanggal, lokasi, kategori produk)

with fct as (
    select * from {{ ref('fct_sales') }}
),

dim_time as (
    select * from {{ ref('dim_time') }}
),

dim_location as (
    select * from {{ ref('dim_location') }}
),

dim_product as (
    select * from {{ ref('dim_product') }}
),

aggregated as (
    select
        -- dimensi waktu
        t.full_date,
        t.year_number,
        t.month_number,
        t.month_name,
        t.quarter,
        t.year_month,
        t.is_weekend,

        -- dimensi lokasi
        l.shop_name,
        l.shop_city,
        l.shop_province,

        -- dimensi produk
        p.product_category,
        p.price_tier,

        -- measures
        count(distinct f.sales_id)          as total_transactions,
        sum(f.item_sold_qty)                as total_items_sold,
        sum(f.gross_sales_amount)           as gross_revenue,
        sum(f.discount_amount)              as total_discount,
        sum(f.net_sales_amount)             as net_revenue,
        avg(f.net_sales_amount)             as avg_transaction_value,
        count(distinct f.customer_sk)       as unique_customers,

        -- repeat purchase
        countif(f.is_repeat_purchase)       as repeat_purchase_count,
        countif(not f.is_repeat_purchase)   as new_purchase_count

    from fct f
    left join dim_time     t on f.time_sk     = t.time_sk
    left join dim_location l on f.location_sk = l.location_sk
    left join dim_product  p on f.product_sk  = p.product_sk

    group by 1,2,3,4,5,6,7,8,9,10,11,12
)

select * from aggregated
