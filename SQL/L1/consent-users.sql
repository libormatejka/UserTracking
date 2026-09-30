SELECT
  DATE(event_date_utc) AS EVENT_DATE,
  DEVICE_CATEGORY,
  PAGE_LOCATION_CLEAN, 
  USER_PSEUDO_ID,
  MAX(CASE
      WHEN consent_analytics_storage IS TRUE THEN TRUE
      ELSE FALSE
  END
    ) AS CONSENT_TYPE
FROM
  `collectorboycz.UserTracking.RAW_DATA_PROD`
WHERE
  --DATE(event_date_utc) = CURRENT_DATE() - 1
  EVENT_DATE_UTC BETWEEN "2024-04-01" AND CURRENT_DATE()
  AND TRAFFIC_TYPE != "internal"
  AND NOT REGEXP_CONTAINS(
    LOWER(USER_AGENT),
    (SELECT STRING_AGG(PATTERN, '|') FROM `collectorboycz.UserTracking.BOT_USER_AGENTS` WHERE IS_ACTIVE)
  )
GROUP BY
  user_pseudo_id,
  event_date,
  device_category,
  PAGE_LOCATION_CLEAN
ORDER BY
  event_date ASC,
  device_category,
  user_pseudo_id