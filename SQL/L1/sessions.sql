WITH 

-- 1. Zjistí, které session mají alespoň 1 event s consent = true
consent_sessions AS (
  SELECT DISTINCT
    CONCAT(USER_PSEUDO_ID, "-", GA_SESSION_ID) AS UNIQUE_SESSION_ID
  FROM
    `collectorboycz.UserTracking.RAW_DATA_PROD`
  WHERE
    CONSENT_ANALYTICS_STORAGE = TRUE
    AND EVENT_DATE_UTC > "2022-07-01"
),

-- 1b. Délka session: rozdíl mezi prvním a posledním eventem v rámci té samé session
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

-- 1c. Počet pageviews v rámci session (pro GA4 definici engaged session)
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

-- 1d. Exit page: PAGE_LOCATION_CLEAN posledního page_view eventu v rámci session
session_exit_page AS (
  SELECT
    UNIQUE_SESSION_ID,
    PAGE_LOCATION_CLEAN AS EXIT_PAGE
  FROM (
    SELECT
      CONCAT(USER_PSEUDO_ID, "-", GA_SESSION_ID) AS UNIQUE_SESSION_ID,
      PAGE_LOCATION_CLEAN,
      ROW_NUMBER() OVER (
        PARTITION BY CONCAT(USER_PSEUDO_ID, "-", GA_SESSION_ID)
        ORDER BY EVENT_TIMESTAMP_UTC DESC
      ) AS rn
    FROM
      `collectorboycz.UserTracking.RAW_DATA_PROD`
    WHERE
      EVENT_NAME = "page_view"
      AND EVENT_DATE_UTC > "2022-07-01"
      AND PAGE_LOCATION_CLEAN IS NOT NULL
      AND TRAFFIC_TYPE != "internal"
      AND NOT REGEXP_CONTAINS(LOWER(USER_AGENT), r'(googlebot|google-read-aloud|lighthouse|bingbot|yandexbot|duckduckbot|applebot|bitsightbot|facebookexternalhit|headlesschrome|hanaleibot|ptst/|ahrefsbot|semrushbot|mj12bot|dotbot|petalbot|seznambot|babbar|gptbot|claudebot|ccbot|bytespider|amazonbot|anthropic-ai|cohere-ai|python-requests|scrapy|curl|wget|go-http-client|okhttp|axios|java/|libwww-perl)')
  )
  WHERE
    rn = 1
)

-- 2. Hlavní query – session_start eventy + přiřazení consent příznaku
SELECT
  main.UNIQUE_EVENT_ID,
  DATE(TIMESTAMP_MILLIS(main.EVENT_TIMESTAMP_UTC), "Europe/Prague") AS EVENT_DATE,
  main.USER_PSEUDO_ID,
  CONCAT(main.USER_PSEUDO_ID, "-", main.GA_SESSION_ID) AS UNIQUE_SESSION_ID,

  CASE
    WHEN main.GCLID is not null
      OR main.SESSION_MEDIUM LIKE "%cpc%"
      OR main.SESSION_MEDIUM LIKE "%cpm%"
      THEN "Paid"
    WHEN main.SESSION_MEDIUM LIKE "%organic%"
      OR main.SESSION_SOURCE LIKE "%search%"
      OR main.SESSION_SOURCE LIKE "%yandex%"
      OR main.SESSION_SOURCE LIKE "%ya.ru%"
      OR main.SESSION_SOURCE LIKE "%qwant.com%"
      THEN "Organic"
    WHEN main.SESSION_SOURCE LIKE "%chatgpt%"
      OR main.SESSION_SOURCE LIKE "%gemini%"
      OR main.SESSION_SOURCE LIKE "%copilot%"
      OR main.SESSION_SOURCE LIKE "%perplexity%"
      OR main.SESSION_SOURCE LIKE "%lens.google.com%"
      THEN "AI & LLMs"
    WHEN main.SESSION_SOURCE LIKE "%facebook%"
      OR main.SESSION_SOURCE LIKE "%instagram%"
      OR main.SESSION_SOURCE LIKE "%youtube%"
      OR main.FBCLID IS NOT NULL
      THEN "Social"
    WHEN main.SESSION_MEDIUM = "email"
      THEN "E-mail"
    WHEN main.SESSION_MEDIUM = "referral"
      THEN "Referral"
    WHEN main.SESSION_SOURCE = "(direct)" AND main.SESSION_MEDIUM = "(none)"
      THEN "Direct"
    ELSE "OTHER"
  END AS DEFAULT_CHANNEL_GROUPING,

  main.SESSION_CAMPAIGN_ID, 
  main.SESSION_CAMPAIGN_NAME, 
  main.SESSION_SOURCE, 
  main.SESSION_MEDIUM, 
  main.SESSION_CAMPAIGN_CONTENT, 
  main.SESSION_CREATIVE_FORMAT, 
  main.SESSION_MARKETING_TACTIC, 
  main.SESSION_SOURCE_PLATFORM, 
  main.CB_CAMPAIGN, 
  main.CB_MEDIUM, 
  main.CB_SOURCE,
  main.PAGE_TITLE,
  main.PAGE_LOCATION_CLEAN AS LANDING_PAGE,
  main.PAGE_CATEGORY,
  main.DEVICE_CATEGORY,
  main.CONTENT_GROUP,
  main.BROWSER,
  main.BROWSER_VERSION, 
  main.OS_PLATFORM,

  -- Nový sloupec: 'consent' pokud session má alespoň 1 event s consent = true
  CASE
    WHEN cs.UNIQUE_SESSION_ID IS NOT NULL THEN "GRANTED"
    ELSE "DENIED"
  END AS CONSENT,

  -- Délka session v sekundách: rozdíl mezi prvním a posledním eventem session
  ROUND((sd.last_event_timestamp - sd.first_event_timestamp) / 1000, 1) AS SESSION_DURATION_SECONDS,

  -- Engaged session (GA4 definice): trvá 10+ sekund NEBO má 2+ pageviews
  CASE
    WHEN ROUND((sd.last_event_timestamp - sd.first_event_timestamp) / 1000, 1) >= 10 THEN TRUE
    WHEN sp.pageview_count >= 2 THEN TRUE
    ELSE FALSE
  END AS ENGAGED_SESSION,

  -- Bounce: opak engaged session
  CASE
    WHEN ROUND((sd.last_event_timestamp - sd.first_event_timestamp) / 1000, 1) >= 10 THEN FALSE
    WHEN sp.pageview_count >= 2 THEN FALSE
    ELSE TRUE
  END AS IS_BOUNCE,

  -- Počet pageviews v rámci session
  COALESCE(sp.pageview_count, 0) AS PAGEVIEWS_PER_SESSION,

  -- Nová vs. vracející se session podle pořadového čísla session daného uživatele
  CASE
    WHEN main.GA_SESSION_NUMBER = 1 THEN "New"
    ELSE "Returning"
  END AS NEW_VS_RETURNING,

  -- Poslední navštívená stránka v rámci session
  sep.EXIT_PAGE

FROM
  `collectorboycz.UserTracking.RAW_DATA_PROD` AS main
LEFT JOIN
  consent_sessions AS cs
  ON CONCAT(main.USER_PSEUDO_ID, "-", main.GA_SESSION_ID) = cs.UNIQUE_SESSION_ID
LEFT JOIN
  session_duration AS sd
  ON CONCAT(main.USER_PSEUDO_ID, "-", main.GA_SESSION_ID) = sd.UNIQUE_SESSION_ID
LEFT JOIN
  session_pageviews AS sp
  ON CONCAT(main.USER_PSEUDO_ID, "-", main.GA_SESSION_ID) = sp.UNIQUE_SESSION_ID
LEFT JOIN
  session_exit_page AS sep
  ON CONCAT(main.USER_PSEUDO_ID, "-", main.GA_SESSION_ID) = sep.UNIQUE_SESSION_ID

WHERE
  main.EVENT_NAME = "session_start"
  AND main.EVENT_DATE_UTC > "2022-07-01"
  AND main.TRAFFIC_TYPE != "internal"
  AND main.SESSION_SOURCE != "collectorboy.cz"
  --AND NOT REGEXP_CONTAINS(LOWER(main.USER_AGENT), r'(Google-Read-Aloud|Lighthouse|lighthouse|bitsightbot|facebookexternalhit|bingbot|headlesschrome|hanaleibot|ptst/)')
  AND NOT REGEXP_CONTAINS(LOWER(main.USER_AGENT), r'(googlebot|google-read-aloud|lighthouse|bingbot|yandexbot|duckduckbot|applebot|bitsightbot|facebookexternalhit|headlesschrome|hanaleibot|ptst/|ahrefsbot|semrushbot|mj12bot|dotbot|petalbot|seznambot|babbar|gptbot|claudebot|ccbot|bytespider|amazonbot|anthropic-ai|cohere-ai|python-requests|scrapy|curl|wget|go-http-client|okhttp|axios|java/|libwww-perl)')