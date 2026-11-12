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


---

# Day 2 – SaaS Revenue & Subscription Performance Analytics

## Objective

Analyze SaaS subscription revenue, Monthly Recurring Revenue (MRR), Annual Recurring Revenue (ARR), subscription growth, pricing tiers, billing frequency, customer segments, revenue concentration, and subscription lifecycle characteristics.

**Dataset:** RavenStack SaaS Analytics  
**SQL Engine:** DuckDB  
**Queries:** 31–45  
**Reporting Snapshot:** December 31, 2024  
**Subscription Records:** 5,000  
**Customer Accounts:** 500

> **Important Revenue Definition:** Total recorded MRR represents the sum of MRR values across subscription records. It is not equivalent to revenue recognized over the observation period. Snapshot MRR represents the sum of qualifying active, paid subscription records at a reporting date. Because accounts can have overlapping subscriptions, these values require additional validation before being treated as production-ready financial KPIs.

---

## 1. Executive Summary

Day 2 analysis identified the following findings:

- Total recorded subscription MRR: **$11,338,747**
- Total recorded subscription ARR: **$136,064,964**
- Active paid subscription records at December 31, 2024: **3,814**
- Distinct active paid accounts: **500**
- December 31 snapshot MRR: **$10,159,608**
- Enterprise recorded MRR: **$8,473,221**
- Enterprise share of recorded MRR: **74.73%**
- Highest subscription-start month: **December 2024**
- Top industry by recorded MRR: **FinTech**
- Top country by recorded MRR: **United States**
- Top 10 accounts' share of recorded MRR: **8.51%**
- Accounts with multiple active subscription records: **496**

The analysis indicates strong representation of Enterprise-tier subscriptions, substantial subscription-start activity during late 2024, and a high degree of overlapping subscription records.

However, revenue metrics must be interpreted carefully because the dataset contains multiple subscriptions per account.

---

## 2. Detailed SQL Findings

### Query 31 – Total Recorded Subscription Revenue

**Results**

| Metric | Value |
|---|---:|
| Total subscription records | 5,000 |
| Distinct customer accounts | 500 |
| Total recorded MRR | $11,338,747 |
| Total recorded ARR | $136,064,964 |
| Average recorded ARR per subscription | $27,212.99 |

**Key Findings**

- The dataset contains 5,000 subscription records distributed across 500 accounts.
- Recorded MRR totals approximately $11.34 million.
- Recorded ARR totals approximately $136.06 million.
- ARR is consistent with annualizing recorded MRR by multiplying by 12.
- Each customer has an average of 10 subscription records across the dataset.

**Business Interpretation**

The dataset provides sufficient subscription history for studying revenue composition and subscription behavior.

However, summing all subscription records does not establish a valid point-in-time recurring revenue metric.

**Recommendation**

Use date-filtered active subscriptions for reporting-period MRR and ARR calculations.

---

### Query 32 – Active Paid Subscription Snapshot

**Reporting Date:** December 31, 2024

| Metric | Value |
|---|---:|
| Active paid subscription records | 3,814 |
| Distinct active paid accounts | 500 |
| Snapshot MRR | $10,159,608 |
| Average MRR per active subscription record | $2,663.77 |
| Summed MRR per distinct active account | $20,319.22 |

**Key Findings**

- 3,814 subscription records satisfy the active, non-trial, non-churned filtering conditions.
- All 500 customer accounts have at least one qualifying subscription.
- Summed snapshot MRR is approximately $10.16 million.
- The average active subscription record contributes approximately $2,664 in MRR.

**Business Interpretation**

The snapshot provides a more relevant recurring revenue measure than summing all historical subscription records.

Nevertheless, multiple qualifying subscriptions can belong to the same account.

**Recommendation**

Validate whether simultaneous subscriptions represent separate products, additional licenses, or overlapping historical records before publishing account-level MRR.

---

### Query 33 – Monthly Subscription Starts and Associated MRR

**Selected Results**

| Month | New Subscription Records | MRR Associated With Starts |
|---|---:|---:|
| January 2023 | 3 | $4,684 |
| December 2023 | 121 | $267,264 |
| March 2024 | 186 | $421,916 |
| June 2024 | 248 | $537,758 |
| September 2024 | 440 | $992,366 |
| October 2024 | 504 | $1,173,608 |
| November 2024 | 612 | $1,549,040 |
| December 2024 | 953 | $2,273,427 |

**Key Findings**

- Subscription-start volume increased substantially over the observation period.
- December 2024 recorded the highest number of subscription starts, with 953 records.
- December's associated recorded MRR was approximately $2.27 million.
- November 2024 recorded 612 subscription starts and approximately $1.55 million in associated MRR.
- The number of subscription starts increased by approximately 55.72% from November to December 2024.

**Business Interpretation**

Late 2024 shows substantial growth in subscription-start activity.

However, subscription starts are not necessarily unique new customer acquisitions because existing customers may create additional subscriptions.

**Recommendation**

Separate new-customer acquisition, additional subscriptions, and plan transitions in future growth reporting.

---

### Query 34 – Monthly Active Paid MRR Trend

**Selected Original Query Results**

| Snapshot Date | Active Subscription Records | Active Accounts | Summed Active MRR |
|---|---:|---:|---:|
| 2023-01-31 | 3 | 2 | $4,684 |
| 2023-06-28 | 97 | 61 | $204,818 |
| 2023-12-28 | 478 | 177 | $1,152,081 |
| 2024-03-28 | 834 | 246 | $2,085,634 |
| 2024-06-28 | 1,361 | 327 | $3,533,870 |
| 2024-09-28 | 2,215 | 410 | $5,667,273 |
| 2024-11-28 | 3,056 | 473 | $8,083,106 |
| 2024-12-28 | 3,720 | 498 | $9,898,684 |

**Key Findings**

- The original query indicates a strong upward trend in qualifying subscription records and summed active MRR.
- The December 28 snapshot reports approximately $9.90 million in summed active MRR.
- The December 31 snapshot from Query 32 reports approximately $10.16 million.
- These two results are not directly comparable because they use different reporting dates.

**Data Quality Limitation**

The original Query 34 used monthly intervals starting on January 31, 2023.

This generated February 28 followed by the 28th of subsequent months rather than consistent calendar month-end dates.

Consequently, the output must not be described as a validated month-end revenue series.

**Recommendation**

Correct the date-generation logic and rerun Query 34 before publishing month-over-month revenue growth percentages.

---

### Query 35 – Recorded Revenue by Subscription Plan Tier

| Plan Tier | Subscription Records | Recorded MRR | Recorded ARR | MRR Share |
|---|---:|---:|---:|---:|
| Enterprise | 1,723 | $8,473,221 | $101,678,652 | 74.73% |
| Pro | 1,675 | $2,105,089 | $25,261,068 | 18.57% |
| Basic | 1,602 | $760,437 | $9,125,244 | 6.71% |

*Percentages are independently rounded.*

**Key Findings**

- Enterprise subscriptions generate the largest recorded MRR contribution.
- Enterprise represents approximately 34.46% of subscription records but 74.73% of recorded MRR.
- Pro contributes 18.57% of recorded MRR.
- Basic contributes approximately 6.71%.
- Average Enterprise subscription MRR is $4,917.71, compared with $1,256.77 for Pro and $474.68 for Basic.

**Business Interpretation**

Enterprise-tier subscriptions contribute disproportionately to recorded subscription value.

**Recommendation**

Prioritize Enterprise retention and account expansion analysis while maintaining an acquisition and conversion strategy for Basic and Pro customers.

---

### Query 36 – Active Paid Revenue by Plan Tier

**December 31, 2024 Snapshot**

| Plan Tier | Active Records | Active Accounts | Active MRR | Active ARR |
|---|---:|---:|---:|---:|
| Enterprise | 1,304 | 461 | $7,546,876 | $90,562,512 |
| Pro | 1,282 | 446 | $1,924,818 | $23,097,816 |
| Basic | 1,228 | 448 | $687,914 | $8,254,968 |

**Key Findings**

- Enterprise contributes approximately $7.55 million in active-record MRR.
- Pro contributes approximately $1.92 million.
- Basic contributes approximately $688,000.
- Enterprise accounts for approximately 74.28% of summed active-record MRR.
- The number of active accounts across tiers cannot be added together to determine unique customers because an account can appear in multiple tiers.

**Business Interpretation**

The Enterprise segment remains the primary contributor to the active paid subscription snapshot.

**Recommendation**

Track active revenue by tier using a validated subscription ownership and account-level revenue model.

---

### Query 37 – Revenue by Billing Frequency

| Billing Frequency | Subscription Records | Share of Records | Average MRR |
|---|---:|---:|---:|
| Monthly | 2,539 | 50.78% | $2,261.26 |
| Annual | 2,461 | 49.22% | $2,274.44 |

**Key Findings**

- Monthly and annual billing are nearly evenly distributed.
- Monthly subscriptions represent a slight majority of records.
- Average MRR values are similar between the two billing frequencies.

**Business Interpretation**

The dataset supports comparisons of billing preferences and their relationship with retention.

However, MRR should be normalized consistently for annual billing.

**Recommendation**

Compare churn rates, renewal behavior, and customer lifetime value between annual and monthly subscriptions.

---

### Query 38 – Trial vs Paid Subscription Performance

| Subscription Type | Records | Recorded MRR | Churn-Flagged Records |
|---|---:|---:|---:|
| Paid | 4,222 | $11,338,747 | 408 |
| Trial | 778 | $0 | 78 |

**Key Findings**

- Paid subscriptions represent 84.44% of subscription records.
- Trial subscriptions represent 15.56%.
- Trial subscriptions contribute zero recorded MRR.
- The dataset contains 408 churn-flagged paid records and 78 churn-flagged trial records.

**Business Interpretation**

Trial subscriptions represent a potential conversion opportunity.

However, these results alone cannot establish a trial-to-paid conversion rate.

**Recommendation**

Use subscription histories to identify trial starts, successful conversions, time to conversion, and trial abandonment.

---

### Query 39 – Upgrade and Downgrade Distribution

| Change Category | Subscription Records | Recorded MRR |
|---|---:|---:|
| No Change | 4,276 | $9,656,818 |
| Upgrade | 506 | $1,222,563 |
| Downgrade | 195 | $418,932 |
| Both Upgrade and Downgrade | 23 | $40,434 |

**Key Findings**

- Most subscription records have neither an upgrade nor a downgrade flag.
- Upgrade-only records outnumber downgrade-only records.
- 23 records have both upgrade and downgrade flags.
- Upgrade-only records account for approximately 10.78% of total recorded MRR.

**Business Interpretation**

Upgrade activity suggests opportunities for expansion revenue.

However, the recorded MRR associated with upgraded subscriptions is not the incremental revenue gained from those upgrades.

**Recommendation**

Calculate expansion and contraction MRR from before-and-after subscription values, and investigate records with conflicting lifecycle flags.

---

### Query 40 – Revenue by Auto-Renewal Status

| Auto-Renewal | Subscription Records | Churn-Flagged Records | Churn-Flag Percentage |
|---|---:|---:|---:|
| Enabled | 4,005 | 390 | 9.74% |
| Disabled | 995 | 96 | 9.65% |

**Key Findings**

- Auto-renewal is enabled on 80.10% of subscription records.
- Churn-flag percentages are similar for enabled and disabled subscriptions.
- The observed difference is only 0.09 percentage points.

**Business Interpretation**

These results do not demonstrate that auto-renewal independently reduces churn.

**Recommendation**

Analyze renewal status alongside subscription tenure, plan tier, customer segment, and actual churn dates before drawing conclusions about retention effectiveness.

---

### Query 41 – Revenue by Customer Industry

| Industry | Accounts | Recorded MRR |
|---|---:|---:|
| FinTech | 112 | $2,669,496 |
| DevTools | 113 | $2,403,654 |
| Cybersecurity | 100 | $2,253,318 |
| EdTech | 79 | $2,043,167 |
| HealthTech | 96 | $1,969,112 |

**Key Findings**

- FinTech is the largest industry by recorded MRR.
- DevTools has the highest number of subscription records, at 1,158.
- EdTech has the highest average MRR per subscription record, at $2,602.76.
- All five industries contribute meaningful recorded subscription value.

**Business Interpretation**

Industry-level segmentation can help identify revenue opportunities and customer retention priorities.

**Recommendation**

Develop industry-specific retention, expansion, and customer-success strategies based on active revenue and churn behavior.

---

### Query 42 – Revenue by Customer Country

| Country | Subscription Records | Recorded MRR |
|---|---:|---:|
| US | 2,961 | $6,634,595 |
| UK | 590 | $1,220,471 |
| IN | 498 | $1,194,325 |
| AU | 312 | $839,980 |
| FR | 211 | $589,796 |
| CA | 217 | $477,562 |
| DE | 211 | $382,018 |

**Key Findings**

- The United States contributes approximately 58.51% of total recorded MRR.
- The United Kingdom and India are the next-largest markets by recorded MRR.
- France has the highest average MRR per subscription record at $2,795.24.
- Geographic revenue distribution is concentrated in the United States.

**Business Interpretation**

The US is the primary recorded revenue market, while international markets provide additional opportunities for growth.

**Recommendation**

Compare active MRR, churn, customer acquisition, and expansion performance by country before prioritizing geographic investments.

---

### Query 43 – Top 20 Accounts by Recorded Subscription MRR

**Top Five Accounts**

| Account | Industry | Country | Recorded MRR |
|---|---|---|---:|
| Company_403 | FinTech | US | $138,060 |
| Company_166 | DevTools | US | $133,298 |
| Company_358 | EdTech | FR | $130,152 |
| Company_368 | EdTech | AU | $94,710 |
| Company_337 | Cybersecurity | IN | $87,957 |

**Key Findings**

- Company_403 has the highest aggregate recorded subscription MRR.
- Company_166 and Company_358 are the next-largest accounts.
- Several EdTech accounts appear among the highest-value customers.
- The top accounts span multiple industries and countries.

**Business Interpretation**

High-value accounts are important candidates for customer-success prioritization.

However, the ranking is based on summed recorded subscription values, not verified current account-level MRR.

**Recommendation**

Build a validated current-revenue account ranking before assigning revenue-risk classifications or strategic account priorities.

---

### Query 44 – Revenue Concentration Among Top Accounts

| Metric | Value |
|---|---:|
| Total accounts | 500 |
| Total recorded MRR | $11,338,747 |
| Top 10 accounts' recorded MRR | $964,589 |
| Top 10 revenue share | 8.51% |
| Top 50 revenue share | 26.88% |

**Key Findings**

- The top 10 accounts represent 8.51% of total recorded MRR.
- The top 50 accounts represent 26.88%.
- Recorded subscription value is distributed across a relatively broad account base.

**Business Interpretation**

The results suggest that recorded MRR is not dominated by a small group of customers.

However, current revenue concentration may differ from historical recorded subscription concentration.

**Recommendation**

Recalculate concentration using verified current account-level MRR and monitor revenue exposure to the largest customers.

---

### Query 45 – Subscription Overlap and Revenue Quality

| Metric | Value |
|---|---:|
| Active paid accounts | 500 |
| Accounts with multiple active records | 496 |
| Maximum active records for one account | 16 |
| MRR from multi-record accounts | $10,153,020 |
| Share of summed snapshot MRR from multi-record accounts | 99.94% |

**Key Findings**

- 496 of 500 active paid accounts have multiple qualifying subscription records.
- Some accounts have as many as 16 simultaneous qualifying records.
- Multi-record accounts contribute approximately $10.15 million in summed snapshot MRR.
- Approximately 99.94% of snapshot MRR comes from accounts with multiple active subscription records.

**Critical Data Quality Finding**

The dataset contains substantial subscription overlap.

This does not automatically establish duplicate revenue because customers may legitimately hold multiple products, contracts, or licenses.

However, the current analysis does not determine whether overlapping records represent independent billable subscriptions or duplicated subscription history.

**Recommendation**

Investigate subscription overlap using subscription IDs, contract dates, plan changes, and product-level identifiers.

Do not deduplicate subscriptions solely by account ID because doing so could incorrectly remove legitimate revenue.

---

## 3. Business Recommendations

### Recommendation 1 – Protect Enterprise Revenue

Enterprise subscriptions contribute approximately three-quarters of recorded MRR.

Actions:
- Monitor Enterprise churn and downgrade behavior.
- Prioritize high-value customer retention.
- Identify expansion opportunities among established accounts.
- Evaluate customer-success coverage for high-value contracts.

### Recommendation 2 – Improve Revenue Reporting Accuracy

The dataset contains substantial overlapping subscription activity.

Actions:
- Define a validated active-subscription reporting model.
- Distinguish independent subscriptions from historical replacements.
- Establish consistent MRR and ARR calculation rules.
- Reconcile account-level subscription revenue before financial reporting.

### Recommendation 3 – Investigate Late-2024 Subscription Growth

December 2024 has the highest subscription-start volume.

Actions:
- Separate new customers from existing-customer subscription additions.
- Investigate whether plan transitions create additional records.
- Compare monthly acquisition and expansion activity.
- Validate growth trends using corrected month-end reporting dates.

### Recommendation 4 – Develop Segment-Specific Strategies

FinTech, DevTools, and Cybersecurity contribute substantial recorded MRR.

Actions:
- Compare active revenue and churn by industry.
- Identify industries with higher expansion potential.
- Develop targeted customer-success programs.
- Evaluate international growth opportunities using country-level metrics.

### Recommendation 5 – Strengthen Subscription Lifecycle Analytics

Upgrade, downgrade, trial, and churn flags provide useful lifecycle signals.

Actions:
- Measure actual expansion and contraction MRR.
- Track trial-to-paid conversion.
- Compare annual and monthly retention.
- Investigate conflicting upgrade/downgrade flags.
- Measure churn using event dates and eligible populations.

---

## 4. Data Quality Findings and Limitations

### 4.1 Historical Revenue vs Snapshot Revenue

Summing recorded MRR across all subscription rows does not produce a valid historical revenue total or current MRR figure.

Historical subscription records may represent different time periods.

### 4.2 Multiple Active Subscriptions

496 accounts contain multiple active paid subscription records at the reporting snapshot.

The business meaning of these overlapping records requires validation.

### 4.3 Month-End Date Generation

Query 34 generates the 28th of most months after February 2023 rather than true calendar month-end dates.

The original trend is retained as an exploratory result only.

### 4.4 Churn Flag Interpretation

A churn flag is not necessarily equivalent to a churn event within a specified reporting period.

Historical churn calculations require consistent event-date and population definitions.

### 4.5 Upgrade and Downgrade Revenue

MRR associated with upgrade or downgrade flags does not equal incremental expansion or contraction revenue.

Previous and subsequent subscription values are required.

### 4.6 Billing Frequency Normalization

Annual and monthly billing must be represented consistently in monthly recurring revenue calculations.

### 4.7 Account-Level Revenue Attribution

Summed MRR divided by distinct accounts does not necessarily represent standard SaaS ARPA when subscription overlap is unresolved.

### 4.8 Reporting Snapshot Assumptions

The active snapshot excludes trials and churn-flagged records and uses subscription start and end dates.

This approach assumes the flags are valid for the reporting date. If churn flags represent eventual churn rather than point-in-time churn, historical snapshots may be biased.

---

## 5. Key Performance Indicators

| KPI | Day 2 Result |
|---|---:|
| Subscription records | 5,000 |
| Distinct customer accounts | 500 |
| Total recorded MRR | $11,338,747 |
| Total recorded ARR | $136,064,964 |
| December 31 active paid records | 3,814 |
| December 31 summed active MRR | $10,159,608 |
| Enterprise recorded MRR share | 74.73% |
| Monthly billing share | 50.78% |
| Annual billing share | 49.22% |
| Trial subscription records | 778 |
| Upgrade-only records | 506 |
| Downgrade-only records | 195 |
| Auto-renewal enabled records | 4,005 |
| Top 10 account revenue share | 8.51% |
| Top 50 account revenue share | 26.88% |
| Accounts with multiple active records | 496 |

---

## 6. Final Day 2 Conclusion

Day 2 analyzed 5,000 subscription records across 500 customer accounts using 15 SQL queries.

The analysis identified Enterprise as the dominant recorded revenue tier, strong subscription-start activity in late 2024, substantial US market representation, and a relatively distributed recorded revenue base.

The most significant technical finding is the prevalence of multiple active subscription records per customer.

This requires additional validation before using aggregated subscription revenue as a production-ready financial KPI.

The monthly revenue trend also requires corrected calendar month-end snapshots.

Overall, Day 2 establishes a foundation for SaaS revenue segmentation, subscription performance reporting, and future churn and retention analysis.

**Day 2 Status:** 15 queries executed; exploratory insights documented; revenue validation limitations identified.
