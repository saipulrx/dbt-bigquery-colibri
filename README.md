# Sales DBT BigQuery — Workshop Project

Project dbt untuk warehouse analytics penjualan menggunakan **BigQuery** sebagai data warehouse. Mengimplementasikan **medallion architecture** (Bronze → Silver → Gold) dengan **Kimball star schema** di layer Gold.

## Arsitektur

```
┌─────────────────────────────────────────────────────────────┐
│ BRONZE: seeds/*.csv                                         │
│   raw_sales, raw_customer, raw_product, raw_location        │
│   calendar (kalender 2020-2027)                             │
│   lookup_product_category, lookup_region_mapping            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ SILVER — STAGING (view)                                     │
│   stg_sales, stg_customer, stg_product, stg_location,       │
│   stg_time                                                  │
│   → cleaning, casting, rename                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ SILVER — INTERMEDIATE (ephemeral)                           │
│   int_sales_enriched      → join all staging                │
│   int_customer_metrics    → lifetime metrics per customer   │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼─────────────────┐
        ▼                ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
│ GOLD - CORE  │  │ GOLD - CORE  │  │ GOLD - AGGREGATE │
│  dim_customer│  │  fct_sales   │  │ mart_revenue_    │
│  dim_product │  │              │  │   daily          │
│  dim_location│  │              │  │ mart_product_    │
│  dim_time    │  │              │  │   performance    │
└──────────────┘  └──────────────┘  │ mart_customer_   │
                                    │   cohort         │
                                    └──────────────────┘
```

## Prerequisites

- Python 3.9+
- Akses ke GCP project dengan BigQuery enabled
- Service account dengan permission BigQuery Data Editor + Job User

## Instalasi

### 1. Install dbt

**Opsi A — dbt-core (rekomendasi untuk peserta workshop):**

```bash
python -m venv venv
source venv/bin/activate
pip install "dbt-core>=1.10" "dbt-bigquery>=1.10"
```

**Opsi B — dbt Fusion** (preview, lebih cepat):

```bash
curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update
```

### 2. Setup Profile

Buat file `~/.dbt/profiles.yml`:

```yaml
sales_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: <YOUR_GCP_PROJECT_ID>
      dataset: <YOUR_DATASET_PREFIX>
      keyfile: <ABSOLUTE_PATH_TO_SERVICE_ACCOUNT_JSON>
      location: US
      threads: 4
```

### 3. Install Dependencies

```bash
dbt deps
```

### 4. Test Koneksi

```bash
dbt debug
```

## Jalankan Pipeline

```bash
dbt seed       # upload CSV (Bronze) ke BigQuery
dbt run        # build semua model (Silver + Gold)
dbt test       # validasi data quality (108 tests)
```

## Struktur Project

| Folder | Isi |
|---|---|
| `models/staging/` | 5 staging views (`stg_*`) — cleaning & rename |
| `models/intermediate/` | 2 intermediate ephemeral models (`int_*`) |
| `models/marts/core/` | 4 dim + 1 fact (`dim_*`, `fct_*`) |
| `models/marts/aggregates/` | 3 use-case-specific marts (`mart_*`) |
| `seeds/` | 7 CSV files sebagai Bronze layer |

## Konvensi Materialization

| Layer | Materialization | Alasan |
|---|---|---|
| Staging | `view` | Selalu fresh, hemat storage |
| Intermediate | `ephemeral` | Reusable CTE, tidak ada object fisik |
| Marts (dim & fact) | `table` | Performa query untuk BI |
| Marts (aggregates) | `table` | Pre-aggregated untuk dashboard |

## Konvensi Penamaan

| Prefix | Layer | Contoh |
|---|---|---|
| `raw_` | Bronze (seed) | `raw_sales`, `raw_customer` |
| `lookup_` | Bronze (reference) | `lookup_product_category`, `lookup_region_mapping` |
| `stg_` | Silver - Staging | `stg_sales` |
| `int_` | Silver - Intermediate | `int_sales_enriched` |
| `dim_` | Gold - Dimension | `dim_customer` |
| `fct_` | Gold - Fact | `fct_sales` |
| `mart_` | Gold - Aggregate | `mart_revenue_daily` |

## Test Coverage

108 tests mencakup:

- **not_null** & **unique** di semua natural key & surrogate key
- **accepted_values** untuk kolom kategorikal (segment, price_tier, quarter, gender)
- **relationships** (FK integrity) di `fct_sales` → semua dim
- Tests berjalan di **semua layer**: seed → staging → intermediate → marts

## Customer Segmentation

`dim_customer` menyediakan 2 dimensi segmentasi:

| Segment | Nilai |
|---|---|
| `recency_segment` | Active, At Risk, Lapsed, Churned, **Never Purchased** |
| `customer_value_segment` | High Value, Mid Value, Low Value, **Never Purchased** |

`Never Purchased` muncul karena `int_customer_metrics` base-nya `stg_customer` (LEFT JOIN ke sales aggregate), sehingga semua customer terdaftar walau belum pernah bertransaksi.

## Dokumentasi Interaktif

**Untuk dbt-core:**

```bash
dbt docs generate
dbt docs serve
```

**Untuk dbt Fusion (pakai [dbt-colibri](https://github.com/dbt-labs/dbt-colibri)):**

```bash
dbt compile --write-catalog
colibri generate
cd dist && python3 -m http.server 8081
# buka http://localhost:8081
```

## Production Migration

Project ini didesain untuk dev/demo dengan seed. Untuk pakai data real:

1. Upload data ke BigQuery di dataset `raw`:
   ```bash
   bq load --source_format=CSV your_project:raw.raw_sales ./seeds/raw_sales.csv
   ```
2. Set `vars.raw_database` di `dbt_project.yml` ke GCP Project ID Anda.
3. Edit `stg_*.sql` — ganti `ref('raw_*')` menjadi `source('raw', 'raw_*')`.
4. Aktifkan kembali tests di `models/staging/sources.yml`.

## License

MIT
