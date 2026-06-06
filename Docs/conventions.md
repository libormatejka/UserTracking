# Konvence

## Pojmenování

- **Sloupce:** `SNAKE_UPPER_CASE`
- **SQL soubory:** `{název_tabulky}.sql` — název odpovídá finální tabulce v BigQuery
- **Schema soubory:** `{vrstva}.json` (L0, L1, L2)

## Vrstvy

| Vrstva | Účel | Granularita |
|---|---|---|
| L0 | Raw data, žádná transformace | event |
| L1 | Čistá data, parsování, obohacení | event |
| L2 | Aggregace pro reporting | závisí na tabulce |

## Typy polí (BigQuery)

- `STRING` — textové hodnoty
- `INTEGER` — celá čísla (UNIX timestamps v **milisekundách**, počty)
- `FLOAT` — desetinná čísla (časy, skóre)
- `DATE` — datum `YYYY-MM-DD`
- `DATETIME` — datum a čas bez timezone
- `BOOLEAN` — true/false

## Zdrojové tabulky

| Vrstva | BigQuery tabulka |
|---|---|
| L0 | `collectorboycz.UserTracking.RAW_DATA_PROD` |

### Povinná podmínka při selectu z L0

Každý dotaz na L0 **musí** obsahovat filtr na `EVENT_DATE_UTC`. Tabulka je partitionovaná podle tohoto sloupce — bez filtru BigQuery prochází celou historii, což je pomalé a nákladné.

SQL parametry (`@date_from`) nefungují v nativním BigQuery — používáme výrazy přímo v SQL.

Výchozí rozsah je **posledních 30 dní**. Každý dotaz na L0 musí vždy obsahovat všechny tyto podmínky:

```sql
WHERE EVENT_DATE_UTC BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
  AND TRAFFIC_TYPE != "internal"
  AND NOT REGEXP_CONTAINS(LOWER(USER_AGENT), r'(lighthouse|bitsightbot|facebookexternalhit|bingbot|headlesschrome|hanaleibot|ptst/)')
```

- `TRAFFIC_TYPE != "internal"` — vyloučení interních návštěv (zaměstnanci, vývoj)
- `REGEXP_CONTAINS` — vyloučení botů a crawlerů, které zkreslují metriky

## SQL styl

- Klíčová slova BigQuery SQL velkými písmeny (`SELECT`, `FROM`, `WHERE`)
- Aliasy tabulek zkratkou vrstvy (`l0`, `l1`, `l2`)
- Každý SQL soubor začíná komentářem s popisem účelu a zdrojové tabulky
