-- Examples using event time


-- Setup mock pageviews table
DROP TABLE IF EXISTS pageviews;

CREATE TABLE `pageviews` (
  `url` STRING,
  `user_id` STRING,
  `browser` STRING,
  `ts` TIMESTAMP(3),
  WATERMARK FOR `ts` AS ts - INTERVAL '5' SECOND
)
WITH (
  'connector' = 'faker',
  'rows-per-second' = '100',
  'fields.url.expression' = '/#{GreekPhilosopher.name}.html',
  'fields.user_id.expression' = '#{numerify ''user_##''}',
  'fields.browser.expression' = '#{Options.option ''chrome'', ''firefox'', ''safari'')}',
  'fields.ts.expression' =  '#{date.past ''5'',''1'',''SECONDS''}'
);

-- Count of pageviews. Note DESCRIPTOR is syntax for time field for windowing
SELECT
  window_start, count(url) AS cnt
FROM TABLE(
  TUMBLE(TABLE pageviews, DESCRIPTOR(ts), INTERVAL '1' SECOND))
GROUP BY window_start;

-- Pattern match for two browsers in 1 seconds for the user
SELECT *
FROM pageviews
    MATCH_RECOGNIZE (
      PARTITION BY user_id
      ORDER BY ts
      MEASURES
        A.browser AS browser1,
        B.browser AS browser2,
        A.ts AS ts1,
        B.ts AS ts2
      PATTERN (A B) WITHIN INTERVAL '1' SECOND
      DEFINE
        A AS true,
        B AS B.browser <> A.browser
    );
