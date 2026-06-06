-- Čas strávený na stránce (v sekundách)
-- Logika: od timestampu page_view po poslední zaznamenaný event na stejné stránce v dané session
-- Zdroj: L0

WITH page_views AS (
  SELECT
    EVENT_DATE_UTC,
    USER_PSEUDO_ID,
    GA_SESSION_ID,
    PAGE_LOCATION_CLEAN,
    CONTENT_GROUP,
    EVENT_TIMESTAMP_UTC AS page_view_timestamp
  FROM `collectorboycz.UserTracking.RAW_DATA_PROD`
  WHERE EVENT_DATE_UTC BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
    AND EVENT_NAME = 'page_view'
    AND PAGE_LOCATION_CLEAN IS NOT NULL
    AND TRAFFIC_TYPE != "internal"
    AND NOT REGEXP_CONTAINS(LOWER(USER_AGENT), r'(lighthouse|bitsightbot|facebookexternalhit|bingbot|headlesschrome|hanaleibot|ptst/)')
),

last_event_per_page AS (
  SELECT
    USER_PSEUDO_ID,
    GA_SESSION_ID,
    PAGE_LOCATION_CLEAN,
    MAX(EVENT_TIMESTAMP_UTC) AS last_event_timestamp
  FROM `collectorboycz.UserTracking.RAW_DATA_PROD`
  WHERE EVENT_DATE_UTC BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
    AND PAGE_LOCATION_CLEAN IS NOT NULL
    AND TRAFFIC_TYPE != "internal"
    AND NOT REGEXP_CONTAINS(LOWER(USER_AGENT), r'(lighthouse|bitsightbot|facebookexternalhit|bingbot|headlesschrome|hanaleibot|ptst/)')
  GROUP BY
    USER_PSEUDO_ID,
    GA_SESSION_ID,
    PAGE_LOCATION_CLEAN
)

SELECT
  pv.EVENT_DATE_UTC,
  pv.USER_PSEUDO_ID,
  pv.GA_SESSION_ID,
  pv.PAGE_LOCATION_CLEAN,
  pv.CONTENT_GROUP,
  TIMESTAMP_MILLIS(pv.page_view_timestamp)       AS page_view_time,
  TIMESTAMP_MILLIS(le.last_event_timestamp)      AS last_event_time,
  ROUND(
    (le.last_event_timestamp - pv.page_view_timestamp) / 1000
  , 1)                                           AS time_on_page_seconds
FROM page_views pv
LEFT JOIN last_event_per_page le
  ON  pv.USER_PSEUDO_ID       = le.USER_PSEUDO_ID
  AND pv.GA_SESSION_ID        = le.GA_SESSION_ID
  AND pv.PAGE_LOCATION_CLEAN  = le.PAGE_LOCATION_CLEAN
