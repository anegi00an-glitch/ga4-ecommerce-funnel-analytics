-- Independent GA4 funnel analysis
-- Public source: bigquery-public-data.ga4_obfuscated_sample_ecommerce

WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    device.category AS device_category,
    geo.country AS country,
    traffic_source.source AS source,
    traffic_source.medium AS medium
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),
user_funnel AS (
  SELECT
    user_pseudo_id,
    ANY_VALUE(country) AS country,
    ANY_VALUE(source) AS source,
    ANY_VALUE(medium) AS medium,
    COUNTIF(event_name = 'view_item') > 0 AS viewed_product,
    COUNTIF(event_name = 'add_to_cart') > 0 AS added_to_cart,
    COUNTIF(event_name = 'begin_checkout') > 0 AS began_checkout,
    COUNTIF(event_name = 'purchase') > 0 AS purchased
  FROM events
  GROUP BY user_pseudo_id
)
SELECT
  COUNT(*) AS users,
  COUNTIF(viewed_product) AS product_viewers,
  COUNTIF(added_to_cart) AS cart_users,
  COUNTIF(began_checkout) AS checkout_users,
  COUNTIF(purchased) AS purchasers,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(added_to_cart), COUNTIF(viewed_product)), 2) AS view_to_cart_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(began_checkout), COUNTIF(added_to_cart)), 2) AS cart_to_checkout_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(purchased), COUNTIF(began_checkout)), 2) AS checkout_to_purchase_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(purchased), COUNTIF(viewed_product)), 2) AS product_to_purchase_pct
FROM user_funnel;

-- Acquisition quality
SELECT
  source,
  medium,
  COUNT(*) AS users,
  COUNTIF(purchased) AS purchasers,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(purchased), COUNT(*)), 2) AS purchase_rate_pct
FROM user_funnel
GROUP BY source, medium
HAVING COUNT(*) >= 100
ORDER BY purchase_rate_pct DESC, users DESC;

-- Daily purchase rate
SELECT
  event_date,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)) AS purchasers,
  ROUND(100 * SAFE_DIVIDE(
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)),
    COUNT(DISTINCT user_pseudo_id)
  ), 2) AS purchase_rate_pct
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY event_date
ORDER BY event_date;
