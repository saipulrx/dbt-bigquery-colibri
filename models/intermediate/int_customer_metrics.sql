-- Silver layer: Intermediate
-- Tujuan: hitung lifetime metrics per customer.
--         Base = stg_customer agar semua customer muncul,
--         termasuk yang belum pernah bertransaksi (Never Purchased).
--         Dipakai oleh dim_customer dan mart_customer_cohort.

with customer as (
    select * from {{ ref('stg_customer') }}
),

sales as (
    select * from {{ ref('stg_sales') }}
),

-- agregasi metrics hanya dari customer yang punya transaksi
sales_agg as (
    select
        customer_id,
        count(distinct sales_id)        as total_orders,
        sum(item_sold_qty)              as total_items_bought,
        sum(sales_amount)               as gross_revenue,
        sum(net_sales_amount)           as net_revenue,
        sum(discount_amount)            as total_discount_received,
        avg(net_sales_amount)           as avg_order_value,
        min(sales_date)                 as first_purchase_date,
        max(sales_date)                 as last_purchase_date
    from sales
    group by customer_id
),

customer_metrics as (
    select
        c.customer_id,

        -- volume (0 untuk customer tanpa transaksi)
        coalesce(sa.total_orders, 0)            as total_orders,
        coalesce(sa.total_items_bought, 0)      as total_items_bought,

        -- revenue (0 untuk customer tanpa transaksi)
        coalesce(sa.gross_revenue, 0)           as gross_revenue,
        coalesce(sa.net_revenue, 0)             as net_revenue,
        coalesce(sa.total_discount_received, 0) as total_discount_received,

        -- averages (NULL untuk customer tanpa transaksi — tidak ada AOV)
        sa.avg_order_value,

        -- tanggal aktivitas (NULL untuk customer tanpa transaksi)
        sa.first_purchase_date,
        sa.last_purchase_date,

        -- recency (NULL untuk customer tanpa transaksi)
        case
            when sa.last_purchase_date is null then null
            else date_diff(current_date(), sa.last_purchase_date, day)
        end                                     as days_since_last_purchase,

        -- segmentasi RFM Recency + flag Never Purchased
        case
            when sa.last_purchase_date is null                              then 'Never Purchased'
            when date_diff(current_date(), sa.last_purchase_date, day) <= 30  then 'Active'
            when date_diff(current_date(), sa.last_purchase_date, day) <= 90  then 'At Risk'
            when date_diff(current_date(), sa.last_purchase_date, day) <= 180 then 'Lapsed'
            else 'Churned'
        end                                     as recency_segment,

        -- flag eksplisit untuk filter cepat di downstream
        sa.customer_id is null                  as is_never_purchased

    from customer c
    left join sales_agg sa on c.customer_id = sa.customer_id
)

select * from customer_metrics
