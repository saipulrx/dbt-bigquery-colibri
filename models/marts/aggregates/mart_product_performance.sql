-- Gold layer: Mart Aggregasi
-- Tujuan: performa produk per bulan — top seller, revenue kontribusi.
--         Dikonsumsi dashboard Product Performance.
-- Grain: 1 baris = 1 produk per bulan

with fct as (
    select * from {{ ref('fct_sales') }}
),

dim_time as (
    select * from {{ ref('dim_time') }}
),

dim_product as (
    select * from {{ ref('dim_product') }}
),

aggregated as (
    select
        -- dimensi waktu
        t.year_number,
        t.month_number,
        t.month_name,
        t.quarter,
        t.year_month,

        -- dimensi produk
        p.product_id,
        p.product_name,
        p.product_category,
        p.product_subcategory,
        p.brand,
        p.price_tier,
        p.unit_price            as listed_unit_price,

        -- measures volume
        count(distinct f.sales_id)          as total_transactions,
        sum(f.item_sold_qty)                as total_qty_sold,
        count(distinct f.customer_sk)       as unique_buyers,

        -- measures revenue
        sum(f.gross_sales_amount)           as gross_revenue,
        sum(f.discount_amount)              as total_discount_given,
        sum(f.net_sales_amount)             as net_revenue,

        -- averages
        avg(f.avg_selling_price)            as avg_actual_selling_price,
        avg(f.discount_amount)              as avg_discount_per_transaction,

        -- discount rate
        safe_divide(
            sum(f.discount_amount),
            sum(f.gross_sales_amount)
        )                                   as discount_rate

    from fct f
    left join dim_time    t on f.time_sk    = t.time_sk
    left join dim_product p on f.product_sk = p.product_sk

    group by 1,2,3,4,5,6,7,8,9,10,11,12
)

select * from aggregated
