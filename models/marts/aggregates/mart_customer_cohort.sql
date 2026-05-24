-- Gold layer: Mart Aggregasi
-- Tujuan: analisis retensi customer per cohort bulan pertama pembelian.
--         Dikonsumsi dashboard Customer Retention & Cohort.
-- Grain: 1 baris = 1 cohort_month x months_since_first_purchase

with fct as (
    select * from {{ ref('fct_sales') }}
),

dim_time as (
    select * from {{ ref('dim_time') }}
),

dim_customer as (
    select * from {{ ref('dim_customer') }}
),

-- ambil bulan pertama beli setiap customer (cohort assignment)
customer_cohort as (
    select
        customer_sk,
        format_date('%Y-%m', first_purchase_date)   as cohort_month
    from dim_customer
    where first_purchase_date is not null
),

-- join transaksi dengan cohort
sales_with_cohort as (
    select
        f.customer_sk,
        cc.cohort_month,
        t.year_month                                as activity_month,

        -- berapa bulan setelah cohort customer ini bertransaksi?
        date_diff(
            date(t.full_date),
            date(parse_date('%Y-%m', cc.cohort_month)),
            month
        )                                           as months_since_first_purchase

    from fct f
    left join dim_time       t  on f.time_sk     = t.time_sk
    left join customer_cohort cc on f.customer_sk = cc.customer_sk
),

-- cohort size per bulan
cohort_size as (
    select
        cohort_month,
        count(distinct customer_sk) as cohort_total_customers
    from customer_cohort
    group by 1
),

-- hitung retensi
cohort_retention as (
    select
        sc.cohort_month,
        sc.months_since_first_purchase,
        count(distinct sc.customer_sk)          as retained_customers,
        cs.cohort_total_customers

    from sales_with_cohort sc
    left join cohort_size cs on sc.cohort_month = cs.cohort_month
    group by 1, 2, cs.cohort_total_customers
),

final as (
    select
        cohort_month,
        months_since_first_purchase,
        cohort_total_customers,
        retained_customers,
        safe_divide(
            retained_customers,
            cohort_total_customers
        )                                       as retention_rate
    from cohort_retention
)

select * from final
order by cohort_month, months_since_first_purchase
