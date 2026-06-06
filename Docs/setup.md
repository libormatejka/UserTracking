# Setup a workflow

## Přidání nové tabulky

1. Vytvoř SQL soubor v příslušné vrstvě: `SQL/{vrstva}/{název}.sql`
2. Přidej nebo aktualizuj JSON schéma: `DataSchema/{vrstva}.json`
3. Zdokumentuj pole v: `DataModel/{vrstva}.md`

## Přidání nového pole do existující tabulky

1. Přidej pole do `DataSchema/{vrstva}.json`
2. Aktualizuj SQL transformaci v `SQL/{vrstva}/`
3. Přidej popis pole do `DataModel/{vrstva}.md`

## BigQuery schema JSON formát

```json
[
  {
    "name": "NAZEV_POLE",
    "mode": "NULLABLE",
    "type": "STRING",
    "description": "Popis pole",
    "fields": []
  }
]
```
