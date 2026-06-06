# Přehled datového modelu

## Tok dat

```
GA4 raw export (events_* tabulky)
        ↓
      L0  — raw events view, žádná transformace, pouze sjednocení schématu
        ↓
      L1  — vyčistěné eventy, parsování parametrů, obohacení
        ↓
      L2  — aggregované tabulky (sessions, users, page_stats, ...)
```

## Vrstvy

### L0 — Raw Events
- Zdroj: GA4 BigQuery export (`events_YYYYMMDD`)
- Granularita: 1 řádek = 1 event
- Schéma: [`DataSchema/L0.json`](../DataSchema/L0.json)
- Dokumentace polí: [`DataModel/L0.md`](L0.md)

### L1 — Cleaned Events
- Zdroj: L0
- Granularita: 1 řádek = 1 event
- Schéma: [`DataSchema/L1.json`](../DataSchema/L1.json)
- Dokumentace polí: [`DataModel/L1.md`](L1.md)

### L2 — Aggregated Marts
- Zdroj: L1
- Granularita: závisí na konkrétní tabulce
- Schéma: [`DataSchema/L2.json`](../DataSchema/L2.json)
- Dokumentace: [`DataModel/L2.md`](L2.md)
