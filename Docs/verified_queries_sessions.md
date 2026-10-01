# Ověřené dotazy — L1_SESSIONS_DATA

Sada ověřených dotazů (verified queries) pro BigQuery data agenta nad tabulkou
`collectorboycz.UserTracking.L1_SESSIONS_DATA`.

Postup nahrání: BigQuery Studio → agent → **Verified Queries** → **Add query** →
vlož text otázky do pole otázky a SQL do pole dotazu → **Run** (ověř výsledek) → **Add**.

`@parametr` v otázce/SQL je šablona, kterou agent sám doplňuje podle dotazu uživatele —
nejde o nativní BigQuery query parameter. U každého parametrizovaného dotazu je uveden
typ a popis pro nastavení v **Manage query parameters**.

---

## 1. Počet sessions a engagement rate za posledních N dní

**Otázka:** Kolik bylo sessions a jaký byl engagement rate za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`, popis: "Počet dní zpětně od dneška"

```sql
SELECT
  COUNT(*) AS SESSIONS,
  COUNTIF(ENGAGED_SESSION) AS ENGAGED_SESSIONS,
  ROUND(SAFE_DIVIDE(COUNTIF(ENGAGED_SESSION), COUNT(*)) * 100, 1) AS ENGAGEMENT_RATE_PCT
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
```

---

## 2. Sessions podle kanálu (channel grouping)

**Otázka:** Kolik sessions přišlo z jednotlivých kanálů za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  DEFAULT_CHANNEL_GROUPING,
  COUNT(*) AS SESSIONS,
  COUNTIF(ENGAGED_SESSION) AS ENGAGED_SESSIONS,
  ROUND(AVG(SESSION_DURATION_SECONDS), 1) AS AVG_SESSION_DURATION_SECONDS
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  DEFAULT_CHANNEL_GROUPING
ORDER BY
  SESSIONS DESC
```

---

## 3. Bounce rate podle typu zařízení

**Otázka:** Jaký je bounce rate podle typu zařízení za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  DEVICE_CATEGORY,
  COUNT(*) AS SESSIONS,
  COUNTIF(IS_BOUNCE) AS BOUNCES,
  ROUND(SAFE_DIVIDE(COUNTIF(IS_BOUNCE), COUNT(*)) * 100, 1) AS BOUNCE_RATE_PCT
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  DEVICE_CATEGORY
ORDER BY
  SESSIONS DESC
```

---

## 4. Top vstupní stránky podle počtu sessions

**Otázka:** Jakých @limit vstupních stránek mělo nejvíc sessions za posledních @days dní?

**Parametry:**
- `@limit` — INT64, výchozí hodnota `10`, popis: "Počet vrácených řádků"
- `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  LANDING_PAGE,
  COUNT(*) AS SESSIONS,
  ROUND(SAFE_DIVIDE(COUNTIF(IS_BOUNCE), COUNT(*)) * 100, 1) AS BOUNCE_RATE_PCT
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  LANDING_PAGE
ORDER BY
  SESSIONS DESC
LIMIT @limit
```

---

## 5. Noví vs. vracející se návštěvníci

**Otázka:** Jaký je poměr nových a vracejících se návštěvníků za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  NEW_VS_RETURNING,
  COUNT(*) AS SESSIONS,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) * 100, 1) AS SHARE_PCT
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  NEW_VS_RETURNING
```

---

## 6. Výkon konkrétní kampaně

**Otázka:** Jak si vedla kampaň @campaign_name za posledních @days dní?

**Parametry:**
- `@campaign_name` — STRING, popis: "Přesný název kampaně (SESSION_CAMPAIGN_NAME)"
- `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  SESSION_CAMPAIGN_NAME,
  SESSION_SOURCE,
  SESSION_MEDIUM,
  COUNT(*) AS SESSIONS,
  COUNTIF(ENGAGED_SESSION) AS ENGAGED_SESSIONS,
  ROUND(AVG(PAGEVIEWS_PER_SESSION), 1) AS AVG_PAGEVIEWS_PER_SESSION
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
  AND SESSION_CAMPAIGN_NAME = @campaign_name
GROUP BY
  SESSION_CAMPAIGN_NAME, SESSION_SOURCE, SESSION_MEDIUM
```

---

## 7. Průměrná délka session a pageviews podle zdroje

**Otázka:** Jaká je průměrná délka session a počet pageviews podle zdroje návštěvnosti za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  SESSION_SOURCE,
  COUNT(*) AS SESSIONS,
  ROUND(AVG(SESSION_DURATION_SECONDS), 1) AS AVG_SESSION_DURATION_SECONDS,
  ROUND(AVG(PAGEVIEWS_PER_SESSION), 1) AS AVG_PAGEVIEWS_PER_SESSION
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  SESSION_SOURCE
ORDER BY
  SESSIONS DESC
```

---

## 8. Podíl sessions se souhlasem se sledováním

**Otázka:** Jaký podíl sessions má udělený souhlas s analytics storage za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  CONSENT,
  COUNT(*) AS SESSIONS,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) * 100, 1) AS SHARE_PCT
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  CONSENT
```

---

## 9. Denní trend počtu sessions

**Otázka:** Jak se vyvíjel denní počet sessions za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  EVENT_DATE,
  COUNT(*) AS SESSIONS,
  COUNTIF(ENGAGED_SESSION) AS ENGAGED_SESSIONS
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  EVENT_DATE
ORDER BY
  EVENT_DATE
```

---

## 10. Nejčastější exit stránky

**Otázka:** Jakých @limit stránek bylo nejčastěji poslední navštívenou stránkou (exit page) za posledních @days dní?

**Parametry:**
- `@limit` — INT64, výchozí hodnota `10`
- `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  EXIT_PAGE,
  COUNT(*) AS SESSIONS
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
  AND EXIT_PAGE IS NOT NULL
GROUP BY
  EXIT_PAGE
ORDER BY
  SESSIONS DESC
LIMIT @limit
```

---

## 11. Top kombinace source / medium podle počtu sessions

**Otázka:** Jakých @limit kombinací zdroje a média (source/medium) přineslo nejvíc sessions za posledních @days dní?

**Parametry:**
- `@limit` — INT64, výchozí hodnota `10`
- `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  SESSION_SOURCE,
  SESSION_MEDIUM,
  COUNT(*) AS SESSIONS,
  COUNTIF(ENGAGED_SESSION) AS ENGAGED_SESSIONS,
  ROUND(SAFE_DIVIDE(COUNTIF(IS_BOUNCE), COUNT(*)) * 100, 1) AS BOUNCE_RATE_PCT
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  SESSION_SOURCE, SESSION_MEDIUM
ORDER BY
  SESSIONS DESC
LIMIT @limit
```

---

## 12. Sessions podle konkrétního zdroje (source)

**Otázka:** Kolik sessions přišlo ze zdroje @source za posledních @days dní a jak si vedly?

**Parametry:**
- `@source` — STRING, popis: "Přesný název zdroje (SESSION_SOURCE), např. google, facebook"
- `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  SESSION_SOURCE,
  SESSION_MEDIUM,
  COUNT(*) AS SESSIONS,
  COUNTIF(ENGAGED_SESSION) AS ENGAGED_SESSIONS,
  ROUND(AVG(SESSION_DURATION_SECONDS), 1) AS AVG_SESSION_DURATION_SECONDS,
  ROUND(AVG(PAGEVIEWS_PER_SESSION), 1) AS AVG_PAGEVIEWS_PER_SESSION
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
  AND SESSION_SOURCE = @source
GROUP BY
  SESSION_SOURCE, SESSION_MEDIUM
ORDER BY
  SESSIONS DESC
```

---

## 13. Sessions podle konkrétního média (medium)

**Otázka:** Kolik sessions přišlo z média @medium za posledních @days dní?

**Parametry:**
- `@medium` — STRING, popis: "Přesný název média (SESSION_MEDIUM), např. cpc, organic, referral, email"
- `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  SESSION_SOURCE,
  COUNT(*) AS SESSIONS,
  COUNTIF(ENGAGED_SESSION) AS ENGAGED_SESSIONS,
  ROUND(SAFE_DIVIDE(COUNTIF(IS_BOUNCE), COUNT(*)) * 100, 1) AS BOUNCE_RATE_PCT
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
  AND SESSION_MEDIUM = @medium
GROUP BY
  SESSION_SOURCE
ORDER BY
  SESSIONS DESC
```

---

## 14. Placená vs. neplacená návštěvnost (podle media)

**Otázka:** Jaký je poměr placené a neplacené návštěvnosti podle média za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  CASE
    WHEN SESSION_MEDIUM LIKE "%cpc%" OR SESSION_MEDIUM LIKE "%cpm%" THEN "Paid"
    ELSE "Unpaid"
  END AS PAID_VS_UNPAID,
  SESSION_MEDIUM,
  COUNT(*) AS SESSIONS
FROM
  `collectorboycz.UserTracking.L1_SESSIONS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  PAID_VS_UNPAID, SESSION_MEDIUM
ORDER BY
  SESSIONS DESC
```
