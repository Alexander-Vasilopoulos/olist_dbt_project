# Olist dbt project

Transforms the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
into a tested star schema that feeds a Power BI report on delivery performance and customer satisfaction.

**Business question:** where do late deliveries hurt customer satisfaction and revenue?

## Lineage

![Lineage graph](images/lineage.png)

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

![Lineage graph](<images/successful build.png>)


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

- **Late deliveries hurt reviews.** Orders delivered early average 4.29 stars; orders
  8+ days late average 1.70, about 2.6 stars lower, and the score falls at each step
  (4.03 on time, 3.29 at 1-3 days late, 2.10 at 4-7 days late).
- **Most orders arrive on time, but the tail is costly.** 6.8% of delivered orders
  (6,535 of 96,476) arrive after the estimated date, and 2,863 of them (3.0%) are
  more than a week late.
- **Delays are concentrated in the Northeast.** Among states with 300+ delivered
  orders, the highest late rates are AL (21.4%), MA (17.4%), SE (15.2%), PI (13.9%)
  and CE (13.8%), roughly 2-3x the 6.8% overall rate.
- **Revenue exposure:** R$ 985,954 (7.5% of delivered revenue) came from orders that
  arrived late.

## Limitations / next steps

- Geolocation table is not modelled.
- No incremental models (the dataset is small and static).
- Add a date dimension and CI that runs `dbt build` on every push.
