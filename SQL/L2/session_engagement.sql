-- Engagement rate / bounce rate podle dne
-- Vychází ze stejné logiky jako L1 SQL/L1/sessions.sql (ENGAGED_SESSION)
-- Zdroj: L0 RAW_DATA_PROD

WITH

session_duration AS (
  SELECT
    CONCAT(USER_PSEUDO_ID, "-", GA_SESSION_ID) AS UNIQUE_SESSION_ID,
    MIN(EVENT_TIMESTAMP_UTC) AS first_event_timestamp,
    MAX(EVENT_TIMESTAMP_UTC) AS last_event_timestamp
  FROM
    `collectorboycz.UserTracking.RAW_DATA_PROD`
  WHERE
    EVENT_DATE_UTC > "2022-07-01"
    AND TRAFFIC_TYPE != "internal"
    AND NOT REGEXP_CONTAINS(LOWER(USER_AGENT), r'(googlebot|google-read-aloud|lighthouse|bingbot|yandexbot|duckduckbot|applebot|bitsightbot|facebookexternalhit|headlesschrome|hanaleibot|ptst/|ahrefsbot|semrushbot|mj12bot|dotbot|petalbot|seznambot|babbar|gptbot|claudebot|ccbot|bytespider|amazonbot|anthropic-ai|cohere-ai|python-requests|scrapy|curl|wget|go-http-client|okhttp|axios|java/|libwww-perl)')
  GROUP BY
    UNIQUE_SESSION_ID
),

session_pageviews AS (
  SELECT
    CONCAT(USER_PSEUDO_ID, "-", GA_SESSION_ID) AS UNIQUE_SESSION_ID,
    COUNT(*) AS pageview_count
  FROM
    `collectorboycz.UserTracking.RAW_DATA_PROD`
  WHERE
    EVENT_NAME = "page_view"
    AND EVENT_DATE_UTC > "2022-07-01"
    AND TRAFFIC_TYPE != "internal"
    AND NOT REGEXP_CONTAINS(LOWER(USER_AGENT), r'(googlebot|google-read-aloud|lighthouse|bingbot|yandexbot|duckduckbot|applebot|bitsightbot|facebookexternalhit|headlesschrome|hanaleibot|ptst/|ahrefsbot|semrushbot|mj12bot|dotbot|petalbot|seznambot|babbar|gptbot|claudebot|ccbot|bytespider|amazonbot|anthropic-ai|cohere-ai|python-requests|scrapy|curl|wget|go-http-client|okhttp|axios|java/|libwww-perl)')
  GROUP BY
    UNIQUE_SESSION_ID
),

sessions AS (
  SELECT
    DATE(TIMESTAMP_MILLIS(main.EVENT_TIMESTAMP_UTC), "Europe/Prague") AS EVENT_DATE,
    CONCAT(main.USER_PSEUDO_ID, "-", main.GA_SESSION_ID) AS UNIQUE_SESSION_ID,
    CASE
      WHEN ROUND((sd.last_event_timestamp - sd.first_event_timestamp) / 1000, 1) >= 10 THEN TRUE
      WHEN sp.pageview_count >= 2 THEN TRUE
      ELSE FALSE
    END AS ENGAGED_SESSION
  FROM
    `collectorboycz.UserTracking.RAW_DATA_PROD` AS main
  LEFT JOIN
    session_duration AS sd
    ON CONCAT(main.USER_PSEUDO_ID, "-", main.GA_SESSION_ID) = sd.UNIQUE_SESSION_ID
  LEFT JOIN
    session_pageviews AS sp
    ON CONCAT(main.USER_PSEUDO_ID, "-", main.GA_SESSION_ID) = sp.UNIQUE_SESSION_ID
  WHERE
    main.EVENT_NAME = "session_start"
    AND main.EVENT_DATE_UTC > "2022-07-01"
    AND main.TRAFFIC_TYPE != "internal"
    AND main.SESSION_SOURCE != "collectorboy.cz"
    AND NOT REGEXP_CONTAINS(LOWER(main.USER_AGENT), r'(googlebot|google-read-aloud|lighthouse|bingbot|yandexbot|duckduckbot|applebot|bitsightbot|facebookexternalhit|headlesschrome|hanaleibot|ptst/|ahrefsbot|semrushbot|mj12bot|dotbot|petalbot|seznambot|babbar|gptbot|claudebot|ccbot|bytespider|amazonbot|anthropic-ai|cohere-ai|python-requests|scrapy|curl|wget|go-http-client|okhttp|axios|java/|libwww-perl)')
)

SELECT
  EVENT_DATE,
  COUNT(*) AS SESSIONS,
  COUNTIF(ENGAGED_SESSION) AS ENGAGED_SESSIONS,
  ROUND(COUNTIF(ENGAGED_SESSION) / COUNT(*), 4) AS ENGAGEMENT_RATE,
  ROUND(1 - (COUNTIF(ENGAGED_SESSION) / COUNT(*)), 4) AS BOUNCE_RATE
FROM
  sessions
GROUP BY
  EVENT_DATE
ORDER BY
  EVENT_DATE
