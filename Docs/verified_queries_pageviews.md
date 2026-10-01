# Ověřené dotazy — L1_PAGEVIEWS_DATA

Sada ověřených dotazů (verified queries) pro BigQuery data agenta nad tabulkou
`collectorboycz.UserTracking.L1_PAGEVIEWS_DATA` *(uprav název, pokud se cílová
tabulka jmenuje jinak)*.

Postup nahrání: BigQuery Studio → agent → **Verified Queries** → **Add query** →
vlož text otázky, SQL, a u parametrizovaných dotazů klikni na **Spravovat parametry
v URL** a zaregistruj každý `@parametr` (typ + výchozí hodnota), teprve pak **Spustit**
→ **Add**.

---

## 1. Nejnavštěvovanější stránky

**Otázka:** Jakých @limit stránek mělo nejvíc zobrazení za posledních @days dní?

**Parametry:**
- `@limit` — INT64, výchozí hodnota `10`
- `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  PAGE_LOCATION_CLEAN,
  PAGE_TITLE,
  SUM(PAGE_VIEWS) AS TOTAL_PAGE_VIEWS
FROM
  `collectorboycz.UserTracking.L1_PAGEVIEWS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  PAGE_LOCATION_CLEAN, PAGE_TITLE
ORDER BY
  TOTAL_PAGE_VIEWS DESC
LIMIT @limit
```

---

## 2. Průměrná doba na konkrétní stránce

**Otázka:** Jaká je průměrná doba strávená na stránce @page_url za posledních @days dní?

**Parametry:**
- `@page_url` — STRING, popis: "Přesná očištěná URL stránky (PAGE_LOCATION_CLEAN)"
- `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  PAGE_LOCATION_CLEAN,
  SUM(PAGE_VIEWS) AS TOTAL_PAGE_VIEWS,
  ROUND(AVG(TIME_ON_PAGE_SECONDS), 1) AS AVG_TIME_ON_PAGE_SECONDS
FROM
  `collectorboycz.UserTracking.L1_PAGEVIEWS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
  AND PAGE_LOCATION_CLEAN = @page_url
GROUP BY
  PAGE_LOCATION_CLEAN
```

---

## 3. Stránky s nejdelší průměrnou dobou strávenou na stránce

**Otázka:** Na kterých @limit stránkách tráví uživatelé nejvíc času za posledních @days dní (alespoň @min_views zobrazení)?

**Parametry:**
- `@limit` — INT64, výchozí hodnota `10`
- `@days` — INT64, výchozí hodnota `30`
- `@min_views` — INT64, výchozí hodnota `50`, popis: "Minimální počet zobrazení stránky, aby se vyloučily málo navštěvované stránky se zkreslujícím průměrem"

```sql
SELECT
  PAGE_LOCATION_CLEAN,
  PAGE_TITLE,
  SUM(PAGE_VIEWS) AS TOTAL_PAGE_VIEWS,
  ROUND(AVG(TIME_ON_PAGE_SECONDS), 1) AS AVG_TIME_ON_PAGE_SECONDS
FROM
  `collectorboycz.UserTracking.L1_PAGEVIEWS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  PAGE_LOCATION_CLEAN, PAGE_TITLE
HAVING
  TOTAL_PAGE_VIEWS >= @min_views
ORDER BY
  AVG_TIME_ON_PAGE_SECONDS DESC
LIMIT @limit
```

---

## 4. Zobrazení podle skupiny obsahu (content group)

**Otázka:** Kolik zobrazení měla jednotlivá skupina obsahu (content group) za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  CONTENT_GROUP,
  SUM(PAGE_VIEWS) AS TOTAL_PAGE_VIEWS,
  ROUND(AVG(TIME_ON_PAGE_SECONDS), 1) AS AVG_TIME_ON_PAGE_SECONDS
FROM
  `collectorboycz.UserTracking.L1_PAGEVIEWS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  CONTENT_GROUP
ORDER BY
  TOTAL_PAGE_VIEWS DESC
```

---

## 5. Zobrazení podle typu zařízení

**Otázka:** Jak se liší počet zobrazení stránek podle typu zařízení za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  DEVICE_CATEGORY,
  SUM(PAGE_VIEWS) AS TOTAL_PAGE_VIEWS,
  ROUND(AVG(TIME_ON_PAGE_SECONDS), 1) AS AVG_TIME_ON_PAGE_SECONDS
FROM
  `collectorboycz.UserTracking.L1_PAGEVIEWS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  DEVICE_CATEGORY
ORDER BY
  TOTAL_PAGE_VIEWS DESC
```

---

## 6. Podíl souhlasu se sledováním na úrovni pageviews

**Otázka:** Jaký podíl zobrazení stránek má udělený souhlas s analytics storage za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  CONSENT,
  SUM(PAGE_VIEWS) AS TOTAL_PAGE_VIEWS,
  ROUND(SAFE_DIVIDE(SUM(PAGE_VIEWS), SUM(SUM(PAGE_VIEWS)) OVER ()) * 100, 1) AS SHARE_PCT
FROM
  `collectorboycz.UserTracking.L1_PAGEVIEWS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  CONSENT
```

---

## 7. Zobrazení podle prohlížeče

**Otázka:** Kolik zobrazení stránek přišlo z jednotlivých prohlížečů za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  BROWSER,
  SUM(PAGE_VIEWS) AS TOTAL_PAGE_VIEWS
FROM
  `collectorboycz.UserTracking.L1_PAGEVIEWS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  BROWSER
ORDER BY
  TOTAL_PAGE_VIEWS DESC
```

---

## 8. Denní trend zobrazení stránek

**Otázka:** Jak se vyvíjel denní počet zobrazení stránek za posledních @days dní?

**Parametr:** `@days` — INT64, výchozí hodnota `30`

```sql
SELECT
  EVENT_DATE,
  SUM(PAGE_VIEWS) AS TOTAL_PAGE_VIEWS
FROM
  `collectorboycz.UserTracking.L1_PAGEVIEWS_DATA`
WHERE
  EVENT_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL @days DAY)
GROUP BY
  EVENT_DATE
ORDER BY
  EVENT_DATE
```
