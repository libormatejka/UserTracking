-- Seznam bot/crawler user agentů, které filtrujeme z reportů.
-- Přidání nového bota = INSERT do této tabulky, ne úprava jednotlivých SQL souborů.
CREATE TABLE IF NOT EXISTS `collectorboycz.UserTracking.BOT_USER_AGENTS` (
  BOT_NAME    STRING NOT NULL,   -- čitelný název, např. "Lighthouse"
  PATTERN     STRING NOT NULL,   -- regex fragment, lowercase, bez lomítek, např. "lighthouse"
  IS_ACTIVE   BOOL NOT NULL,     -- FALSE = dočasně vypnutý bez mazání
  NOTE        STRING,
  ADDED_DATE  DATE
);

INSERT INTO `collectorboycz.UserTracking.BOT_USER_AGENTS`
  (BOT_NAME, PATTERN, IS_ACTIVE, NOTE, ADDED_DATE)
VALUES
  ('Lighthouse',            'lighthouse',           TRUE, NULL, CURRENT_DATE()),
  ('BitSight',              'bitsightbot',          TRUE, NULL, CURRENT_DATE()),
  ('Facebook External Hit', 'facebookexternalhit',  TRUE, NULL, CURRENT_DATE()),
  ('Bingbot',               'bingbot',              TRUE, NULL, CURRENT_DATE()),
  ('Headless Chrome',       'headlesschrome',       TRUE, NULL, CURRENT_DATE()),
  ('Hanalei bot',           'hanaleibot',           TRUE, NULL, CURRENT_DATE()),
  ('Pingdom (PTST)',        'ptst/',                TRUE, NULL, CURRENT_DATE()),
  ('Meta External Agent',   'meta-externalagent',   TRUE, NULL, CURRENT_DATE()),
  ('Meta Web Indexer',      'meta-webindexer',      TRUE, NULL, CURRENT_DATE()),
  ('Googlebot',             'googlebot',            TRUE, NULL, CURRENT_DATE()),
  ('Google Read Aloud',     'google-read-aloud',    TRUE, NULL, CURRENT_DATE()),
  ('Yandexbot',             'yandexbot',            TRUE, NULL, CURRENT_DATE()),
  ('DuckDuckBot',           'duckduckbot',          TRUE, NULL, CURRENT_DATE()),
  ('Applebot',              'applebot',             TRUE, NULL, CURRENT_DATE()),
  ('AhrefsBot',             'ahrefsbot',            TRUE, NULL, CURRENT_DATE()),
  ('SemrushBot',            'semrushbot',           TRUE, NULL, CURRENT_DATE()),
  ('MJ12bot',               'mj12bot',              TRUE, NULL, CURRENT_DATE()),
  ('DotBot',                'dotbot',               TRUE, NULL, CURRENT_DATE()),
  ('PetalBot',              'petalbot',             TRUE, NULL, CURRENT_DATE()),
  ('SeznamBot',             'seznambot',            TRUE, NULL, CURRENT_DATE()),
  ('Babbar',                'babbar',               TRUE, NULL, CURRENT_DATE()),
  ('GPTBot',                'gptbot',               TRUE, NULL, CURRENT_DATE()),
  ('ClaudeBot',             'claudebot',            TRUE, NULL, CURRENT_DATE()),
  ('CCBot',                 'ccbot',                TRUE, NULL, CURRENT_DATE()),
  ('Bytespider',            'bytespider',           TRUE, NULL, CURRENT_DATE()),
  ('Amazonbot',             'amazonbot',            TRUE, NULL, CURRENT_DATE()),
  ('Anthropic AI',          'anthropic-ai',         TRUE, NULL, CURRENT_DATE()),
  ('Cohere AI',             'cohere-ai',            TRUE, NULL, CURRENT_DATE()),
  ('Python Requests',       'python-requests',      TRUE, NULL, CURRENT_DATE()),
  ('Scrapy',                'scrapy',               TRUE, NULL, CURRENT_DATE()),
  ('cURL',                  'curl',                 TRUE, NULL, CURRENT_DATE()),
  ('Wget',                  'wget',                 TRUE, NULL, CURRENT_DATE()),
  ('Go HTTP Client',        'go-http-client',       TRUE, NULL, CURRENT_DATE()),
  ('OkHttp',                'okhttp',               TRUE, NULL, CURRENT_DATE()),
  ('Axios',                 'axios',                TRUE, NULL, CURRENT_DATE()),
  ('Java HTTP Client',      'java/',                TRUE, NULL, CURRENT_DATE()),
  ('libwww-perl',           'libwww-perl',          TRUE, NULL, CURRENT_DATE()),
  ('Web Image Collection Research', 'web-image-collection-research', TRUE, NULL, CURRENT_DATE()),
  ('Viewer (unknown)',      'viewer/',              TRUE, NULL, CURRENT_DATE()),
  ('LikeWise (unknown)',    'likewise/',            TRUE, NULL, CURRENT_DATE());
