-- Different examples of how you can build a COUNT using processing time
-- Progressively better examples
-- These are intended to be run in a SQL client to see each, rather than a collective script

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


-- Simple, floor the timestamp approach
-- Round down TS to second, count page views, in that second
SELECT
  FLOOR(ts TO SECOND) AS window_start,
  count(url) as cnt
FROM pageviews
GROUP BY FLOOR(ts TO SECOND);


-- Better attempt --
-- add processing time
ALTER TABLE pageviews ADD `proc_time` AS PROCTIME();
-- Table returned with windows, grouped view
SELECT
  window_start, count(url) AS cnt
FROM TABLE(
  TUMBLE(TABLE pageviews, 
  DESCRIPTOR(proc_time), 
  INTERVAL '1' SECOND)) -- Note the config for data gen is 100/s
GROUP BY window_start;

-- compare this with the above to see the affect of interval time
SELECT
  window_start, count(url) AS cnt
FROM TABLE(
  TUMBLE(TABLE pageviews, 
  DESCRIPTOR(proc_time), 
  INTERVAL '5' SECOND)) -- 5
GROUP BY window_start;

-- Table returned with windows, not grouped
-- Note wide terminal to see the windows
SELECT * 
FROM TABLE(TUMBLE(
  TABLE pageviews, 
  DESCRIPTOR(proc_time), 
  INTERVAL '1' SECOND)
);

-- Use HOP when you want to track trends over a moving time period, 
--- like "number of page views in the last 10 seconds, updated every 5 seconds"
 SELECT window_start, count(url) as cnt_url
  FROM TABLE(
    HOP(TABLE pageviews, 
    DESCRIPTOR(proc_time), 
    INTERVAL '5' SECONDS, 
    INTERVAL '10' SECONDS))
 GROUP BY window_start;

-- Use CUMULATE when you want to see both quick early results and longer-term accumulation,
-- like "show me page view counts at 5, 10, and 15 second marks, and stop counting at 15

 SELECT window_start, count(url) as cnt_url
  FROM TABLE(
    CUMULATE(TABLE pageviews,
     DESCRIPTOR(proc_time), 
     INTERVAL '5' SECONDS, -- step size. Note default refresh window in sql client terminal is 1s
     INTERVAL '15' SECONDS)) -- window size
 GROUP BY window_start;
