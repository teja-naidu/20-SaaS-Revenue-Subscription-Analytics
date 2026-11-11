# SaaS Revenue & Subscription Analytics

SQL portfolio project analyzing RavenStack, a synthetic SaaS business dataset.

## Tools
DuckDB, SQL, Git, GitHub

## Data
Five tables: accounts, subscriptions, feature_usage, support_tickets, churn_events.

**Dataset credit:** River @ Rivalytics (RavenStack synthetic SaaS dataset). Educational/portfolio use; see the original dataset README for licensing information.

## Run
From the project root:

```powershell
duckdb saas_analytics.duckdb < sql/queries.sql
```

Or inside the DuckDB shell:

```sql
.read sql/queries.sql
```

The SQL creates five persistent tables and runs 30 numbered Day 1 loading, exploration, and validation queries. Note that Q16 includes four date-range SELECT statements.

## Analysis plan
- Day 1: Data profiling, integrity, quality
- Day 2: MRR, ARR, subscription performance
- Day 3: Churn, retention, plan changes
- Day 4: Cohorts, LTV, feature adoption
- Day 5: SaaS KPI synthesis, recommendations

## Important analytical caveat
Subscription rows are historical records. Summing their MRR values is **not** a current MRR calculation. Define an as-of date and a deduplication/active-subscription policy before producing revenue KPIs. Churn events can repeat for an account, so event counts are not unique churned-customer counts.
