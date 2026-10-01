-- =============================================================================
-- DOKUMENTACE VÝSTUPNÍCH SLOUPCŮ
-- =============================================================================
-- UNIQUE_EVENT_ID - Unikátní ID page_view eventu
-- EVENT_DATE - Datum zobrazení stránky v časové zóně Europe/Prague, tvar YYYY-mm-dd
-- PAGE_TITLE - Titulek zobrazené stránky
-- PAGE_LOCATION_CLEAN - URL zobrazené stránky, očištěná o parametry
-- DEVICE_CATEGORY - Kategorie zařízení (desktop, mobile, tablet)
-- CONTENT_GROUP - Skupina obsahu dané stránky
-- PAGE_VIEWS - Počet page_view eventů agregovaných pro danou kombinaci uživatel/session/stránka
-- CONSENT - Granted, pokud má daná pageview (uživatel + session + stránka) alespoň 1 event se souhlasem s analytics storage, jinak Denied
-- TIME_ON_PAGE_SECONDS - Doba strávená na stránce v sekundách (rozdíl mezi prvním a posledním eventem v rámci dané pageview)
-- BROWSER - Název prohlížeče uživatele
-- BROWSER_VERSION - Verze prohlížeče uživatele
-- OS_PLATFORM - Operační systém/platforma uživatele
-- =============================================================================

-- Consent na úrovni pageview: pageview = USER_PSEUDO_ID + GA_SESSION_ID + PAGE_LOCATION_CLEAN
-- Pokud má tato pageview alespoň 1 event s CONSENT_ANALYTICS_STORAGE = TRUE, je Granted, jinak Denied
WITH consent_pageviews AS (
  SELECT DISTINCT
    USER_PSEUDO_ID,
    GA_SESSION_ID,
    PAGE_LOCATION_CLEAN
  FROM
    `collectorboycz.UserTracking.RAW_DATA_PROD`
  WHERE
    CONSENT_ANALYTICS_STORAGE = TRUE
    AND EVENT_DATE_UTC > "2022-07-01"
),

-- Doba na stránce: rozdíl mezi prvním a posledním eventem v rámci té samé pageview
page_time AS (
  SELECT
    USER_PSEUDO_ID,
    GA_SESSION_ID,
    PAGE_LOCATION_CLEAN,
    MIN(EVENT_TIMESTAMP_UTC) AS first_event_timestamp,
    MAX(EVENT_TIMESTAMP_UTC) AS last_event_timestamp
  FROM
    `collectorboycz.UserTracking.RAW_DATA_PROD`
  WHERE
    EVENT_DATE_UTC > "2022-07-01"
    AND PAGE_LOCATION_CLEAN IS NOT NULL
    AND TRAFFIC_TYPE != "internal"
    AND NOT REGEXP_CONTAINS(
      LOWER(USER_AGENT),
      (SELECT STRING_AGG(PATTERN, '|') FROM `collectorboycz.UserTracking.BOT_USER_AGENTS` WHERE IS_ACTIVE)
    )
  GROUP BY
    USER_PSEUDO_ID,
    GA_SESSION_ID,
    PAGE_LOCATION_CLEAN
)

SELECT
  main.UNIQUE_EVENT_ID,
  DATE(TIMESTAMP_MILLIS(main.EVENT_TIMESTAMP_UTC), "Europe/Prague") AS EVENT_DATE,
  main.PAGE_TITLE,
  main.PAGE_LOCATION_CLEAN,
  main.DEVICE_CATEGORY,
  main.CONTENT_GROUP,
  COUNT(main.EVENT_NAME) AS PAGE_VIEWS,
  CASE
    WHEN cp.PAGE_LOCATION_CLEAN IS NOT NULL THEN "Granted"
    ELSE "Denied"
  END AS CONSENT,
  ROUND((pt.last_event_timestamp - pt.first_event_timestamp) / 1000, 1) AS TIME_ON_PAGE_SECONDS,
  main.BROWSER,
  main.BROWSER_VERSION,
  main.OS_PLATFORM,
FROM
  `collectorboycz.UserTracking.RAW_DATA_PROD` AS main
LEFT JOIN
  consent_pageviews AS cp
  ON main.USER_PSEUDO_ID = cp.USER_PSEUDO_ID
  AND main.GA_SESSION_ID = cp.GA_SESSION_ID
  AND main.PAGE_LOCATION_CLEAN = cp.PAGE_LOCATION_CLEAN
LEFT JOIN
  page_time AS pt
  ON main.USER_PSEUDO_ID = pt.USER_PSEUDO_ID
  AND main.GA_SESSION_ID = pt.GA_SESSION_ID
  AND main.PAGE_LOCATION_CLEAN = pt.PAGE_LOCATION_CLEAN
WHERE
  main.EVENT_DATE_UTC > "2022-07-01"
  AND main.EVENT_NAME = "page_view"
  AND main.TRAFFIC_TYPE != "internal"
  AND NOT REGEXP_CONTAINS(
    LOWER(main.USER_AGENT),
    (SELECT STRING_AGG(PATTERN, '|') FROM `collectorboycz.UserTracking.BOT_USER_AGENTS` WHERE IS_ACTIVE)
  )
GROUP BY
  ALL