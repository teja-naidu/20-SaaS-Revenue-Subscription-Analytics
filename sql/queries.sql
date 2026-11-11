-- PROJECT 20: SaaS Revenue & Subscription Analytics
-- DAY 1: Dataset exploration and data quality validation
-- Run from the project root using: duckdb saas_analytics.duckdb < sql/queries.sql

-- Q01-Q05: Load raw CSV files as persistent DuckDB tables
CREATE OR REPLACE TABLE accounts AS SELECT * FROM read_csv_auto('data/ravenstack_accounts.csv', HEADER=TRUE);
CREATE OR REPLACE TABLE subscriptions AS SELECT * FROM read_csv_auto('data/ravenstack_subscriptions.csv', HEADER=TRUE);
CREATE OR REPLACE TABLE feature_usage AS SELECT * FROM read_csv_auto('data/ravenstack_feature_usage.csv', HEADER=TRUE);
CREATE OR REPLACE TABLE support_tickets AS SELECT * FROM read_csv_auto('data/ravenstack_support_tickets.csv', HEADER=TRUE);
CREATE OR REPLACE TABLE churn_events AS SELECT * FROM read_csv_auto('data/ravenstack_churn_events.csv', HEADER=TRUE);

-- Q06: Row counts across tables
SELECT 'accounts' AS table_name, COUNT(*) AS total_rows FROM accounts
UNION ALL SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL SELECT 'feature_usage', COUNT(*) FROM feature_usage
UNION ALL SELECT 'support_tickets', COUNT(*) FROM support_tickets
UNION ALL SELECT 'churn_events', COUNT(*) FROM churn_events;

-- Q07: Inspect tables and inferred types
DESCRIBE accounts;
DESCRIBE subscriptions;
DESCRIBE feature_usage;
DESCRIBE support_tickets;
DESCRIBE churn_events;

-- Q08: Sample account records
SELECT * FROM accounts LIMIT 5;
-- Q09: Sample subscription records
SELECT * FROM subscriptions LIMIT 5;
-- Q10: Unique IDs versus row counts
SELECT 'accounts' AS table_name, COUNT(*) AS rows, COUNT(DISTINCT account_id) AS unique_ids FROM accounts
UNION ALL SELECT 'subscriptions', COUNT(*), COUNT(DISTINCT subscription_id) FROM subscriptions
UNION ALL SELECT 'feature_usage', COUNT(*), COUNT(DISTINCT usage_id) FROM feature_usage
UNION ALL SELECT 'support_tickets', COUNT(*), COUNT(DISTINCT ticket_id) FROM support_tickets
UNION ALL SELECT 'churn_events', COUNT(*), COUNT(DISTINCT churn_event_id) FROM churn_events;

-- Q11: Null primary keys
SELECT 'accounts' AS table_name, COUNT(*) AS null_ids FROM accounts WHERE account_id IS NULL
UNION ALL SELECT 'subscriptions', COUNT(*) FROM subscriptions WHERE subscription_id IS NULL
UNION ALL SELECT 'feature_usage', COUNT(*) FROM feature_usage WHERE usage_id IS NULL
UNION ALL SELECT 'support_tickets', COUNT(*) FROM support_tickets WHERE ticket_id IS NULL
UNION ALL SELECT 'churn_events', COUNT(*) FROM churn_events WHERE churn_event_id IS NULL;

-- Q12: Orphan subscriptions
SELECT COUNT(*) AS orphan_subscriptions FROM subscriptions s LEFT JOIN accounts a ON s.account_id=a.account_id WHERE a.account_id IS NULL;
-- Q13: Orphan feature usage
SELECT COUNT(*) AS orphan_usage_events FROM feature_usage u LEFT JOIN subscriptions s ON u.subscription_id=s.subscription_id WHERE s.subscription_id IS NULL;
-- Q14: Orphan support tickets
SELECT COUNT(*) AS orphan_tickets FROM support_tickets t LEFT JOIN accounts a ON t.account_id=a.account_id WHERE a.account_id IS NULL;
-- Q15: Orphan churn events
SELECT COUNT(*) AS orphan_churn_events FROM churn_events c LEFT JOIN accounts a ON c.account_id=a.account_id WHERE a.account_id IS NULL;

-- Q16: Date coverage
SELECT MIN(signup_date) AS first_signup, MAX(signup_date) AS last_signup FROM accounts;
SELECT MIN(start_date) AS first_start, MAX(start_date) AS last_start, MIN(end_date) AS earliest_end, MAX(end_date) AS latest_end FROM subscriptions;
SELECT MIN(usage_date) AS first_usage, MAX(usage_date) AS last_usage FROM feature_usage;
SELECT MIN(churn_date) AS first_churn, MAX(churn_date) AS last_churn FROM churn_events;

-- Q17: Invalid subscription periods
SELECT COUNT(*) AS invalid_periods FROM subscriptions WHERE end_date < start_date;
-- Q18: Invalid revenue and seat amounts
SELECT COUNT(*) AS invalid_revenue_or_seats FROM subscriptions WHERE mrr_amount < 0 OR arr_amount < 0 OR seats <= 0;
-- Q19: ARR vs 12 times MRR (check for expected model relationship)
SELECT COUNT(*) AS arr_mrr_mismatches FROM subscriptions WHERE ABS(arr_amount - 12*mrr_amount) > 0.01;
-- Q20: Revenue summary (historical subscription rows, NOT point-in-time active MRR)
SELECT COUNT(*) AS subscription_records, ROUND(SUM(mrr_amount),2) AS sum_recorded_mrr, ROUND(AVG(mrr_amount),2) AS avg_recorded_mrr, ROUND(SUM(arr_amount),2) AS sum_recorded_arr FROM subscriptions;

-- Q21: Plan distribution
SELECT plan_tier, COUNT(*) AS subscription_records, ROUND(AVG(mrr_amount),2) AS avg_mrr FROM subscriptions GROUP BY plan_tier ORDER BY subscription_records DESC;
-- Q22: Billing frequency distribution
SELECT billing_frequency, COUNT(*) AS subscription_records FROM subscriptions GROUP BY billing_frequency ORDER BY subscription_records DESC;
-- Q23: Trial, churn, upgrade, downgrade flags
SELECT COUNT(*) AS subscriptions, COUNT(*) FILTER (WHERE is_trial) AS trial_rows, COUNT(*) FILTER (WHERE churn_flag) AS churn_flag_rows, COUNT(*) FILTER (WHERE upgrade_flag) AS upgrade_rows, COUNT(*) FILTER (WHERE downgrade_flag) AS downgrade_rows FROM subscriptions;
-- Q24: Missing support satisfaction scores
SELECT COUNT(*) AS tickets, COUNT(*) FILTER (WHERE satisfaction_score IS NULL) AS missing_satisfaction, ROUND(100.0*COUNT(*) FILTER (WHERE satisfaction_score IS NULL)/NULLIF(COUNT(*),0),2) AS missing_pct FROM support_tickets;
-- Q25: Churn reason counts
SELECT reason_code, COUNT(*) AS churn_events FROM churn_events GROUP BY reason_code ORDER BY churn_events DESC;
-- Q26: Account-level subscription frequency
SELECT COUNT(*) AS accounts, MIN(subscription_count) AS min_subscriptions, MAX(subscription_count) AS max_subscriptions, ROUND(AVG(subscription_count),2) AS avg_subscriptions FROM (SELECT account_id, COUNT(*) AS subscription_count FROM subscriptions GROUP BY account_id);
-- Q27: Duplicate account/date subscription rows (review, not automatically erroneous)
SELECT account_id, start_date, COUNT(*) AS records FROM subscriptions GROUP BY account_id,start_date HAVING COUNT(*)>1 ORDER BY records DESC LIMIT 20;
-- Q28: Null counts for important subscription attributes
SELECT COUNT(*) FILTER (WHERE account_id IS NULL) AS missing_account_id, COUNT(*) FILTER (WHERE start_date IS NULL) AS missing_start_date, COUNT(*) FILTER (WHERE plan_tier IS NULL) AS missing_plan_tier, COUNT(*) FILTER (WHERE mrr_amount IS NULL) AS missing_mrr, COUNT(*) FILTER (WHERE end_date IS NULL) AS open_end_dates FROM subscriptions;
-- Q29: Usage quality
SELECT COUNT(*) AS usage_events, COUNT(*) FILTER (WHERE usage_count < 0 OR usage_duration_secs < 0 OR error_count < 0) AS negative_metrics, COUNT(*) FILTER (WHERE usage_date IS NULL) AS missing_usage_dates FROM feature_usage;
-- Q30: Support ticket quality
SELECT COUNT(*) AS tickets, COUNT(*) FILTER (WHERE closed_at < submitted_at) AS closed_before_opened, COUNT(*) FILTER (WHERE resolution_time_hours < 0 OR first_response_time_minutes < 0) AS negative_response_metrics FROM support_tickets;
