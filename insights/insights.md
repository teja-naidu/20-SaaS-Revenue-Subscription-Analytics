# SaaS Revenue & Subscription Analytics — Insights

## Day 1 — Dataset exploration and quality

### Data inventory
- Accounts: 500 rows
- Subscriptions: 5,000 rows
- Feature usage: 25,000 rows
- Support tickets: 2,000 rows
- Churn events: 600 rows
- **Total: 33,100 rows**

### Data model
Accounts connect to subscriptions, support tickets, and churn events by `account_id`. Feature usage connects to subscriptions by `subscription_id`.

### Findings awaiting DuckDB validation
After executing `sql/queries.sql`, add actual outputs for Q10–Q30: primary-key uniqueness, orphan references, date coverage, revenue consistency, plan and billing mix, trial/churn flags, missing values, and invalid metrics. Do not label these checks as passed before reviewing query output.

### Analytical precautions
- The sum of historical subscription MRR rows is not current MRR.
- Account churn events can recur; event counts must not be confused with unique accounts.
- Null subscription `end_date` can mean open-ended, and null satisfaction scores may mean no response.
- Multiple subscriptions per account require explicit deduplication rules for account-level metrics.

### Business questions for subsequent days
How much revenue is active at a chosen reporting date? Which plans generate the most revenue? Which customers churn and why? Does feature adoption or support experience correlate with retention?

### Day 1 result updates
Paste DuckDB output here after execution to document confirmed numerical findings and business recommendations.
