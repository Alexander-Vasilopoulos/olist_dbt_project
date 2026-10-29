# Olist dbt project

Transforms the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
into a tested star schema that feeds a Power BI report on delivery performance and customer satisfaction.

**Business question:** where do late deliveries hurt customer satisfaction and revenue?

## Lineage

```
raw CSVs -> staging (clean/rename, 1:1 with sources)
         -> intermediate (collapse to one row per order)
         -> marts (fct_orders, fct_order_items, dim_customers, dim_sellers, dim_products)
         -> Power BI
```

## Data issues handled

| Issue in the raw data | How it is handled |
|---|---|
| An order can have several payments (voucher + card) | `int_order_payments_agg` sums them to one row per order, so revenue is not double counted |
| An order can have several reviews, and `review_id` is not unique | `int_order_reviews_latest` keeps the most recent review per order |
| `customer_id` is per order, not per person | Customers are modelled on `customer_unique_id` in `dim_customers` |
| Some categories have no English translation | `dim_products` falls back to the Portuguese name, then `unknown` |
| A few orders are `delivered` but have no delivery date | Reported by a warn-level test instead of failing the build |
| Column typos (`product_name_lenght`) | Unused columns dropped in staging |

## Tests

- Unique / not null on all primary keys, `relationships` between facts and dimensions, `accepted_values` on status, review score and delay bucket.
- Reconciliation: total revenue in `fct_orders` must equal total revenue in `fct_order_items`.
- Sanity: no negative amounts.

## Run it

**Option A: Snowflake**
1. Run `setup/snowflake_setup.sql` and load the CSVs into `OLIST.RAW`.
2. `pip install dbt-snowflake`, copy `profiles.yml.example` to `~/.dbt/profiles.yml` and set the environment variables.
3. `dbt build` then `dbt docs generate && dbt docs serve`.

**Option B: DuckDB (free, local)**
1. `pip install dbt-duckdb`, copy `profiles.yml.example` to `~/.dbt/profiles.yml` and use `--target duckdb`.
2. Put the 8 CSVs in `data/raw/` (git-ignored).
3. `dbt build --target duckdb`.

## Findings

_Add 3-4 findings from your marts here (for example: how review scores change by delay bucket)._

## Limitations / next steps

- Geolocation table is not modelled.
- No incremental models (the dataset is small and static).
- Add a date dimension and CI that runs `dbt build` on every push.
