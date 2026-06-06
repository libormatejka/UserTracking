# UserTracking — BigQuery Data Model

Dokumentace datového modelu a SQL transformací pro web tracking data (GA4 + GTM → BigQuery).

## Architektura vrstev

```
GA4 / GTM
    ↓
[L0] Raw events          — surová data, bez úprav
    ↓  SQL/L1/
[L1] Cleaned events      — vyčištěná, obohacená data na úrovni eventů
    ↓  SQL/L2/
[L2] Aggregated marts    — agregace na úrovni sessionů, uživatelů, stránek
```

## Struktura repozitáře

| Složka | Obsah |
|---|---|
| `DataSchema/` | JSON schémata tabulek ve formátu BigQuery |
| `SQL/L0/` | SQL pro zdrojovou vrstvu (view nad raw GA4 exportem) |
| `SQL/L1/` | SQL transformace L0 → L1 |
| `SQL/L2/` | SQL transformace L1 → L2 (marts) |
| `DataModel/` | Markdown dokumentace — popis tabulek, business logika polí |
| `Docs/` | Konvence, setup, workflow |

## Konvence

- Schémata: `DataSchema/{vrstva}.json` ve formátu [BigQuery JSON schema](https://cloud.google.com/bigquery/docs/schemas#creating_a_json_schema_file)
- SQL soubory: `SQL/{vrstva}/{název_tabulky}.sql`
- Dokumentace tabulky: `DataModel/{vrstva}.md`
