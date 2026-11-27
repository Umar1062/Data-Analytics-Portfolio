-- KPI denominator: Success + Failed; Pending excluded.
SELECT transaction_status, COUNT(*) AS transaction_count FROM payments GROUP BY transaction_status;

SELECT
 COUNT(CASE WHEN transaction_status='Success' THEN 1 END) AS successes,
 COUNT(CASE WHEN transaction_status='Failed' THEN 1 END) AS failures,
 COUNT(CASE WHEN transaction_status IN ('Success','Failed') THEN 1 END) AS eligible,
 100.0*COUNT(CASE WHEN transaction_status='Success' THEN 1 END)/NULLIF(COUNT(CASE WHEN transaction_status IN ('Success','Failed') THEN 1 END),0) AS success_rate_pct,
 100.0*COUNT(CASE WHEN transaction_status='Failed' THEN 1 END)/NULLIF(COUNT(CASE WHEN transaction_status IN ('Success','Failed') THEN 1 END),0) AS failure_rate_pct
FROM payments;

-- Success rate by method
SELECT payment_method, COUNT(*) AS records,
 COUNT(CASE WHEN transaction_status='Success' THEN 1 END) AS successes,
 COUNT(CASE WHEN transaction_status='Failed' THEN 1 END) AS failures,
 100.0*COUNT(CASE WHEN transaction_status='Success' THEN 1 END)/NULLIF(COUNT(CASE WHEN transaction_status IN ('Success','Failed') THEN 1 END),0) AS success_rate_pct
FROM payments GROUP BY payment_method ORDER BY success_rate_pct DESC;

-- Merchant metrics
SELECT merchant_id, COUNT(*) AS records,
 COUNT(CASE WHEN transaction_status='Success' THEN 1 END) AS successes,
 COUNT(CASE WHEN transaction_status='Failed' THEN 1 END) AS failures,
 SUM(CASE WHEN transaction_status='Success' THEN amount ELSE 0 END) AS success_value,
 SUM(CASE WHEN transaction_status='Failed' THEN amount ELSE 0 END) AS failed_value
FROM payments GROUP BY merchant_id ORDER BY failed_value DESC;

-- Failure reasons
SELECT failure_reason, COUNT(*) AS failed_transactions, SUM(amount) AS failed_value
FROM payments WHERE transaction_status='Failed' GROUP BY failure_reason ORDER BY failed_transactions DESC;

-- Daily trend
SELECT CAST(transaction_date AS DATE) AS day,
 COUNT(*) AS records,
 COUNT(CASE WHEN transaction_status='Success' THEN 1 END) AS successes,
 COUNT(CASE WHEN transaction_status='Failed' THEN 1 END) AS failures
FROM payments GROUP BY CAST(transaction_date AS DATE) ORDER BY day;

-- Failed value by channel
SELECT payment_channel, COUNT(*) AS failures, SUM(amount) AS failed_value
FROM payments WHERE transaction_status='Failed' GROUP BY payment_channel ORDER BY failed_value DESC;

-- Average successful amount by method
SELECT payment_method, AVG(CASE WHEN transaction_status='Success' THEN amount END) AS avg_success_amount
FROM payments GROUP BY payment_method;

-- Top 5 merchants (MySQL/Postgres style)
SELECT merchant_id, SUM(amount) AS successful_value FROM payments WHERE transaction_status='Success'
GROUP BY merchant_id ORDER BY successful_value DESC LIMIT 5;

-- Failure rate by merchant, minimum 20 final outcomes
SELECT merchant_id,
 COUNT(CASE WHEN transaction_status='Failed' THEN 1 END) AS failures,
 COUNT(CASE WHEN transaction_status IN ('Success','Failed') THEN 1 END) AS eligible,
 100.0*COUNT(CASE WHEN transaction_status='Failed' THEN 1 END)/NULLIF(COUNT(CASE WHEN transaction_status IN ('Success','Failed') THEN 1 END),0) AS failure_rate_pct
FROM payments GROUP BY merchant_id
HAVING COUNT(CASE WHEN transaction_status IN ('Success','Failed') THEN 1 END)>=20
ORDER BY failure_rate_pct DESC;

-- Rank merchants by successful transaction value
WITH mv AS (SELECT merchant_id, SUM(amount) AS value FROM payments WHERE transaction_status='Success' GROUP BY merchant_id)
SELECT merchant_id,value,RANK() OVER (ORDER BY value DESC) AS merchant_rank FROM mv;
