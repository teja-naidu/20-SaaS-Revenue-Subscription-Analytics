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


-- ============================================================
-- PROJECT 20: SaaS Revenue & Subscription Analytics
-- DAY 2: Revenue & Subscription Performance
-- Queries 31–45
-- Reporting snapshot: 2024-12-31
-- ============================================================

-- NOTE:
-- Subscription rows may overlap for the same account.
-- Snapshot MRR below is the sum of qualifying subscription
-- records, not necessarily deduplicated account-level MRR.
-- Historical sums are not recognized accounting revenue.


-- ============================================================
-- QUERY 31: Total Recorded Subscription Revenue
-- ============================================================

SELECT
    COUNT(*) AS total_subscription_records,
    COUNT(DISTINCT account_id) AS total_accounts,
    SUM(mrr_amount) AS total_recorded_mrr,
    ROUND(AVG(mrr_amount), 2) AS avg_subscription_mrr,
    SUM(arr_amount) AS total_recorded_arr,
    ROUND(AVG(arr_amount), 2) AS avg_subscription_arr
FROM subscriptions;


-- ============================================================
-- QUERY 32: Active Subscription Snapshot (2024-12-31)
-- ============================================================

WITH snapshot AS (
    SELECT *
    FROM subscriptions
    WHERE start_date <= DATE '2024-12-31'
      AND (
          end_date IS NULL
          OR end_date > DATE '2024-12-31'
      )
      AND COALESCE(churn_flag, FALSE) = FALSE
      AND COALESCE(is_trial, FALSE) = FALSE
)
SELECT
    COUNT(*) AS active_paid_subscription_records,
    COUNT(DISTINCT account_id) AS active_paid_accounts,
    SUM(mrr_amount) AS snapshot_mrr,
    SUM(arr_amount) AS snapshot_arr,
    ROUND(AVG(mrr_amount), 2) AS avg_active_subscription_mrr,
    ROUND(
        SUM(mrr_amount) * 1.0 /
        NULLIF(COUNT(DISTINCT account_id), 0),
        2
    ) AS mrr_per_active_account
FROM snapshot;


-- ============================================================
-- QUERY 33: Monthly Subscription Starts and Recorded MRR
-- ============================================================

SELECT
    DATE_TRUNC('month', start_date)::DATE AS start_month,
    COUNT(*) AS new_subscription_records,
    COUNT(DISTINCT account_id) AS accounts_starting_subscriptions,
    SUM(mrr_amount) AS recorded_mrr_from_starts,
    ROUND(AVG(mrr_amount), 2) AS avg_new_subscription_mrr
FROM subscriptions
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- QUERY 34: Monthly Active Paid MRR Trend
-- ============================================================

WITH months AS (
    SELECT
        month_end::DATE AS snapshot_date
    FROM generate_series(
        DATE '2023-01-31',
        DATE '2024-12-31',
        INTERVAL '1 month'
    ) AS t(month_end)
),
active_records AS (
    SELECT
        m.snapshot_date,
        s.subscription_id,
        s.account_id,
        s.mrr_amount
    FROM months m
    JOIN subscriptions s
      ON s.start_date <= m.snapshot_date
     AND (
         s.end_date IS NULL
         OR s.end_date > m.snapshot_date
     )
    WHERE COALESCE(s.churn_flag, FALSE) = FALSE
      AND COALESCE(s.is_trial, FALSE) = FALSE
)
SELECT
    snapshot_date,
    COUNT(*) AS active_paid_subscription_records,
    COUNT(DISTINCT account_id) AS active_paid_accounts,
    SUM(mrr_amount) AS active_record_mrr,
    ROUND(
        SUM(mrr_amount) -
        LAG(SUM(mrr_amount)) OVER (
            ORDER BY snapshot_date
        ),
        2
    ) AS mom_mrr_change
FROM active_records
GROUP BY snapshot_date
ORDER BY snapshot_date;


-- ============================================================
-- QUERY 35: Revenue by Subscription Plan Tier
-- ============================================================

SELECT
    plan_tier,
    COUNT(*) AS subscription_records,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    SUM(mrr_amount) AS recorded_mrr,
    SUM(arr_amount) AS recorded_arr,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr,
    ROUND(
        100.0 * SUM(mrr_amount) /
        NULLIF(
            (SELECT SUM(mrr_amount) FROM subscriptions),
            0
        ),
        2
    ) AS pct_recorded_mrr
FROM subscriptions
GROUP BY plan_tier
ORDER BY recorded_mrr DESC;


-- ============================================================
-- QUERY 36: Active Paid Revenue by Plan Tier
-- ============================================================

SELECT
    plan_tier,
    COUNT(*) AS active_subscription_records,
    COUNT(DISTINCT account_id) AS active_accounts,
    SUM(mrr_amount) AS active_record_mrr,
    SUM(arr_amount) AS active_record_arr,
    ROUND(AVG(mrr_amount), 2) AS avg_active_mrr
FROM subscriptions
WHERE start_date <= DATE '2024-12-31'
  AND (
      end_date IS NULL
      OR end_date > DATE '2024-12-31'
  )
  AND COALESCE(churn_flag, FALSE) = FALSE
  AND COALESCE(is_trial, FALSE) = FALSE
GROUP BY plan_tier
ORDER BY active_record_mrr DESC;


-- ============================================================
-- QUERY 37: Revenue by Billing Frequency
-- ============================================================

SELECT
    billing_frequency,
    COUNT(*) AS subscription_records,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    SUM(mrr_amount) AS recorded_mrr,
    SUM(arr_amount) AS recorded_arr,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_subscription_records
FROM subscriptions
GROUP BY billing_frequency
ORDER BY recorded_mrr DESC;


-- ============================================================
-- QUERY 38: Trial vs Paid Subscription Performance
-- ============================================================

SELECT
    CASE
        WHEN is_trial = TRUE THEN 'Trial'
        WHEN is_trial = FALSE THEN 'Paid'
        ELSE 'Unknown'
    END AS subscription_type,
    COUNT(*) AS subscription_records,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    SUM(mrr_amount) AS recorded_mrr,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr,
    SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
        AS churn_flag_records
FROM subscriptions
GROUP BY 1
ORDER BY subscription_records DESC;


-- ============================================================
-- QUERY 39: Upgrade and Downgrade Distribution
-- ============================================================

SELECT
    CASE
        WHEN upgrade_flag = TRUE
         AND downgrade_flag = TRUE
            THEN 'Both Upgrade and Downgrade'
        WHEN upgrade_flag = TRUE
            THEN 'Upgrade'
        WHEN downgrade_flag = TRUE
            THEN 'Downgrade'
        ELSE 'No Change'
    END AS change_category,
    COUNT(*) AS subscription_records,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    SUM(mrr_amount) AS recorded_mrr,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr
FROM subscriptions
GROUP BY 1
ORDER BY subscription_records DESC;


-- ============================================================
-- QUERY 40: Revenue by Auto-Renewal Status
-- ============================================================

SELECT
    auto_renew_flag,
    COUNT(*) AS subscription_records,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    SUM(mrr_amount) AS recorded_mrr,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr,
    SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
        AS churn_flag_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage
FROM subscriptions
GROUP BY auto_renew_flag
ORDER BY recorded_mrr DESC;


-- ============================================================
-- QUERY 41: Revenue by Customer Industry
-- ============================================================

SELECT
    a.industry,
    COUNT(s.subscription_id) AS subscription_records,
    COUNT(DISTINCT a.account_id) AS distinct_accounts,
    SUM(s.mrr_amount) AS recorded_mrr,
    ROUND(AVG(s.mrr_amount), 2) AS avg_mrr,
    SUM(s.arr_amount) AS recorded_arr
FROM subscriptions s
JOIN accounts a
  ON s.account_id = a.account_id
GROUP BY a.industry
ORDER BY recorded_mrr DESC;


-- ============================================================
-- QUERY 42: Revenue by Customer Country
-- ============================================================

SELECT
    a.country,
    COUNT(s.subscription_id) AS subscription_records,
    COUNT(DISTINCT a.account_id) AS distinct_accounts,
    SUM(s.mrr_amount) AS recorded_mrr,
    ROUND(AVG(s.mrr_amount), 2) AS avg_mrr
FROM subscriptions s
JOIN accounts a
  ON s.account_id = a.account_id
GROUP BY a.country
ORDER BY recorded_mrr DESC;


-- ============================================================
-- QUERY 43: Top 20 Accounts by Recorded Subscription MRR
-- ============================================================

SELECT
    a.account_id,
    a.account_name,
    a.industry,
    a.country,
    COUNT(s.subscription_id) AS subscription_records,
    SUM(s.mrr_amount) AS recorded_mrr,
    SUM(s.arr_amount) AS recorded_arr,
    ROUND(AVG(s.mrr_amount), 2) AS avg_subscription_mrr
FROM accounts a
JOIN subscriptions s
  ON a.account_id = s.account_id
GROUP BY
    a.account_id,
    a.account_name,
    a.industry,
    a.country
ORDER BY recorded_mrr DESC
LIMIT 20;


-- ============================================================
-- QUERY 44: Revenue Concentration Among Top Accounts
-- ============================================================

WITH account_revenue AS (
    SELECT
        account_id,
        SUM(mrr_amount) AS recorded_mrr
    FROM subscriptions
    GROUP BY account_id
),
ranked_accounts AS (
    SELECT
        account_id,
        recorded_mrr,
        ROW_NUMBER() OVER (
            ORDER BY recorded_mrr DESC, account_id
        ) AS revenue_rank
    FROM account_revenue
)
SELECT
    COUNT(*) AS total_accounts,
    SUM(recorded_mrr) AS total_recorded_mrr,
    SUM(
        CASE WHEN revenue_rank <= 10
             THEN recorded_mrr ELSE 0 END
    ) AS top_10_recorded_mrr,
    ROUND(
        100.0 *
        SUM(
            CASE WHEN revenue_rank <= 10
                 THEN recorded_mrr ELSE 0 END
        ) / NULLIF(SUM(recorded_mrr), 0),
        2
    ) AS top_10_revenue_share_pct,
    ROUND(
        100.0 *
        SUM(
            CASE WHEN revenue_rank <= 50
                 THEN recorded_mrr ELSE 0 END
        ) / NULLIF(SUM(recorded_mrr), 0),
        2
    ) AS top_50_revenue_share_pct
FROM ranked_accounts;


-- ============================================================
-- QUERY 45: Subscription Overlap and Revenue Quality Check
-- ============================================================

WITH active_snapshot AS (
    SELECT
        account_id,
        subscription_id,
        plan_tier,
        mrr_amount
    FROM subscriptions
    WHERE start_date <= DATE '2024-12-31'
      AND (
          end_date IS NULL
          OR end_date > DATE '2024-12-31'
      )
      AND COALESCE(churn_flag, FALSE) = FALSE
      AND COALESCE(is_trial, FALSE) = FALSE
),
account_summary AS (
    SELECT
        account_id,
        COUNT(*) AS active_subscription_records,
        COUNT(DISTINCT plan_tier) AS active_plan_tiers,
        SUM(mrr_amount) AS combined_active_mrr
    FROM active_snapshot
    GROUP BY account_id
)
SELECT
    COUNT(*) AS active_accounts,
    SUM(
        CASE WHEN active_subscription_records > 1
             THEN 1 ELSE 0 END
    ) AS accounts_with_multiple_active_records,
    MAX(active_subscription_records)
        AS max_active_records_per_account,
    SUM(
        CASE WHEN active_plan_tiers > 1
             THEN 1 ELSE 0 END
    ) AS accounts_with_multiple_active_tiers,
    SUM(
        CASE WHEN active_subscription_records > 1
             THEN combined_active_mrr ELSE 0 END
    ) AS mrr_from_multi_record_accounts,
    ROUND(
        100.0 *
        SUM(
            CASE WHEN active_subscription_records > 1
                 THEN combined_active_mrr ELSE 0 END
        ) / NULLIF(SUM(combined_active_mrr), 0),
        2
    ) AS multi_record_mrr_share_pct
FROM account_summary;


-- ============================================================
-- PROJECT 20: SaaS Revenue & Subscription Analytics
-- DAY 3: Customer Churn & Retention Analytics
-- Queries 46–60
-- ============================================================

-- Reporting date: 2024-12-31
-- Churn flags represent subscription-record characteristics.
-- Churn events represent separately recorded churn activity.
-- Do not assume that these populations are identical.


-- ============================================================
-- QUERY 46: Overall Subscription Churn Overview
-- ============================================================

SELECT
    COUNT(*) AS total_subscription_records,
    COUNT(DISTINCT account_id) AS total_accounts,
    SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    SUM(CASE WHEN NOT churn_flag THEN 1 ELSE 0 END)
        AS non_churn_flagged_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage,
    SUM(CASE WHEN churn_flag THEN mrr_amount ELSE 0 END)
        AS mrr_associated_with_churn_flags
FROM subscriptions;

-- ============================================================
-- QUERY 47: Churn Event Summary
-- ============================================================

SELECT
    COUNT(*) AS total_churn_events,
    COUNT(DISTINCT churn_event_id) AS unique_churn_events,
    COUNT(DISTINCT account_id) AS accounts_with_churn_events,
    MIN(churn_date) AS earliest_churn_date,
    MAX(churn_date) AS latest_churn_date
FROM churn_events;

-- ============================================================
-- QUERY 48: Monthly Churn Event Trend
-- ============================================================

SELECT
    DATE_TRUNC('month', churn_date)::DATE AS churn_month,
    COUNT(*) AS churn_events,
    COUNT(DISTINCT account_id) AS affected_accounts
FROM churn_events
GROUP BY 1
ORDER BY 1;

-- ============================================================
-- QUERY 49: Churn Reasons Distribution
-- ============================================================

SELECT
    reason_code,
    COUNT(*) AS churn_events,
    COUNT(DISTINCT account_id) AS affected_accounts,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_churn_events
FROM churn_events
GROUP BY reason_code
ORDER BY churn_events DESC;

-- ============================================================
-- QUERY 50: Churn by Subscription Plan Tier
-- ============================================================

SELECT
    plan_tier,
    COUNT(*) AS subscription_records,
    SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage,
    SUM(CASE WHEN churn_flag THEN mrr_amount ELSE 0 END)
        AS churn_flagged_mrr
FROM subscriptions
GROUP BY plan_tier
ORDER BY churn_flag_percentage DESC;


-- ============================================================
-- QUERY 51: Churn by Billing Frequency
-- ============================================================

SELECT
    billing_frequency,
    COUNT(*) AS subscription_records,
    SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage,
    SUM(CASE WHEN churn_flag THEN mrr_amount ELSE 0 END)
        AS churn_flagged_mrr
FROM subscriptions
GROUP BY billing_frequency
ORDER BY churn_flag_percentage DESC;


-- ============================================================
-- QUERY 52: Churn by Trial vs Paid Subscription
-- ============================================================

SELECT
    CASE
        WHEN is_trial = TRUE THEN 'Trial'
        WHEN is_trial = FALSE THEN 'Paid'
        ELSE 'Unknown'
    END AS subscription_type,
    COUNT(*) AS subscription_records,
    SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage,
    SUM(CASE WHEN churn_flag THEN mrr_amount ELSE 0 END)
        AS churn_flagged_mrr
FROM subscriptions
GROUP BY 1
ORDER BY churn_flag_percentage DESC;


-- ============================================================
-- QUERY 53: Churn by Customer Industry
-- ============================================================

SELECT
    a.industry,
    COUNT(*) AS subscription_records,
    COUNT(DISTINCT s.account_id) AS accounts,
    SUM(CASE WHEN s.churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN s.churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage,
    SUM(CASE WHEN s.churn_flag THEN s.mrr_amount ELSE 0 END)
        AS churn_flagged_mrr
FROM subscriptions s
JOIN accounts a
    ON s.account_id = a.account_id
GROUP BY a.industry
ORDER BY churn_flag_percentage DESC;


-- ============================================================
-- QUERY 54: Churn by Customer Country
-- ============================================================

SELECT
    a.country,
    COUNT(*) AS subscription_records,
    SUM(CASE WHEN s.churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN s.churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage,
    SUM(CASE WHEN s.churn_flag THEN s.mrr_amount ELSE 0 END)
        AS churn_flagged_mrr
FROM subscriptions s
JOIN accounts a
    ON s.account_id = a.account_id
GROUP BY a.country
ORDER BY churn_flag_percentage DESC;


-- ============================================================
-- QUERY 55: Churn by Auto-Renewal Status
-- ============================================================

SELECT
    auto_renew_flag,
    COUNT(*) AS subscription_records,
    SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage,
    SUM(CASE WHEN churn_flag THEN mrr_amount ELSE 0 END)
        AS churn_flagged_mrr
FROM subscriptions
GROUP BY auto_renew_flag
ORDER BY churn_flag_percentage DESC;


-- ============================================================
-- QUERY 56: Subscription Tenure Distribution
-- ============================================================

WITH subscription_tenure AS (
    SELECT
        subscription_id,
        account_id,
        DATE_DIFF(
            'day',
            start_date,
            COALESCE(end_date, DATE '2024-12-31')
        ) AS tenure_days
    FROM subscriptions
    WHERE start_date <= DATE '2024-12-31'
)
SELECT
    CASE
        WHEN tenure_days < 0 THEN 'Invalid Negative Tenure'
        WHEN tenure_days < 30 THEN 'Less Than 1 Month'
        WHEN tenure_days < 90 THEN '1–3 Months'
        WHEN tenure_days < 180 THEN '3–6 Months'
        WHEN tenure_days < 365 THEN '6–12 Months'
        ELSE '12+ Months'
    END AS tenure_category,
    COUNT(*) AS subscription_records,
    COUNT(DISTINCT account_id) AS accounts,
    ROUND(AVG(tenure_days), 2) AS avg_tenure_days
FROM subscription_tenure
GROUP BY 1
ORDER BY MIN(tenure_days);


-- ============================================================
-- QUERY 57: Churn Flag Percentage by Subscription Tenure
-- ============================================================

WITH subscription_tenure AS (
    SELECT
        subscription_id,
        churn_flag,
        DATE_DIFF(
            'day',
            start_date,
            COALESCE(end_date, DATE '2024-12-31')
        ) AS tenure_days
    FROM subscriptions
    WHERE start_date <= DATE '2024-12-31'
)
SELECT
    CASE
        WHEN tenure_days < 0 THEN 'Invalid Negative Tenure'
        WHEN tenure_days < 30 THEN 'Less Than 1 Month'
        WHEN tenure_days < 90 THEN '1–3 Months'
        WHEN tenure_days < 180 THEN '3–6 Months'
        WHEN tenure_days < 365 THEN '6–12 Months'
        ELSE '12+ Months'
    END AS tenure_category,
    COUNT(*) AS subscription_records,
    SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    ROUND(
        100.0 *
        SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END) /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_flag_percentage
FROM subscription_tenure
GROUP BY 1
ORDER BY MIN(tenure_days);


-- ============================================================
-- QUERY 58: Account-Level Churn Exposure
-- ============================================================

WITH account_churn AS (
    SELECT
        account_id,
        COUNT(*) AS total_subscription_records,
        SUM(CASE WHEN churn_flag THEN 1 ELSE 0 END)
            AS churn_flagged_records,
        SUM(CASE WHEN NOT churn_flag THEN 1 ELSE 0 END)
            AS non_churn_flagged_records
    FROM subscriptions
    GROUP BY account_id
)
SELECT
    COUNT(*) AS total_accounts,
    SUM(
        CASE WHEN churn_flagged_records > 0
             THEN 1 ELSE 0 END
    ) AS accounts_with_any_churn_flag,
    SUM(
        CASE WHEN churn_flagged_records > 0
              AND non_churn_flagged_records > 0
             THEN 1 ELSE 0 END
    ) AS accounts_with_mixed_churn_flags,
    SUM(
        CASE WHEN churn_flagged_records > 0
              AND non_churn_flagged_records = 0
             THEN 1 ELSE 0 END
    ) AS accounts_with_all_records_churn_flagged,
    SUM(
        CASE WHEN churn_flagged_records = 0
             THEN 1 ELSE 0 END
    ) AS accounts_without_churn_flags
FROM account_churn;



-- ============================================================
-- QUERY 59: Account-Level Churn Flag vs Churn Event Reconciliation
-- ============================================================

WITH subscription_flags AS (
    SELECT
        account_id,
        COUNT(*) AS total_subscription_records,
        SUM(
            CASE WHEN churn_flag THEN 1 ELSE 0 END
        ) AS churn_flagged_records
    FROM subscriptions
    GROUP BY account_id
),
event_summary AS (
    SELECT
        account_id,
        COUNT(*) AS churn_event_count
    FROM churn_events
    GROUP BY account_id
)
SELECT
    CASE
        WHEN s.churn_flagged_records > 0
         AND e.account_id IS NOT NULL
            THEN 'Has Churn Flag and Event'
        WHEN s.churn_flagged_records > 0
         AND e.account_id IS NULL
            THEN 'Has Churn Flag Only'
        WHEN s.churn_flagged_records = 0
         AND e.account_id IS NOT NULL
            THEN 'Has Churn Event Only'
        ELSE 'Neither Flag nor Event'
    END AS reconciliation_category,
    COUNT(*) AS accounts,
    SUM(s.total_subscription_records)
        AS subscription_records,
    SUM(s.churn_flagged_records)
        AS churn_flagged_records,
    SUM(COALESCE(e.churn_event_count, 0))
        AS churn_events
FROM subscription_flags s
LEFT JOIN event_summary e
    ON s.account_id = e.account_id
GROUP BY 1
ORDER BY accounts DESC;

-- ============================================================
-- QUERY 60: Top 20 Accounts by Churn-Flagged MRR Exposure
-- ============================================================

SELECT
    a.account_id,
    a.account_name,
    a.industry,
    a.country,
    COUNT(s.subscription_id) AS total_subscription_records,
    SUM(CASE WHEN s.churn_flag THEN 1 ELSE 0 END)
        AS churn_flagged_records,
    SUM(
        CASE WHEN s.churn_flag
             THEN s.mrr_amount ELSE 0 END
    ) AS churn_flagged_mrr,
    SUM(
        CASE WHEN NOT s.churn_flag
             THEN s.mrr_amount ELSE 0 END
    ) AS non_churn_flagged_mrr
FROM accounts a
JOIN subscriptions s
    ON a.account_id = s.account_id
GROUP BY
    a.account_id,
    a.account_name,
    a.industry,
    a.country
HAVING SUM(
    CASE WHEN s.churn_flag THEN 1 ELSE 0 END
) > 0
ORDER BY churn_flagged_mrr DESC
LIMIT 20;

