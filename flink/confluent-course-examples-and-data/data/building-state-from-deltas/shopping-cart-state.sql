SET 'sql-client.execution.statement-set-enabled' = 'true';
SET 'pipeline.name' = 'Shopping Cart State Pipeline';
SET 'sql-client.execution.result-mode' = 'TABLEAU'; -- Ignore if manual copy pasting, used as part of scripting
-- BEGIN STATEMENT SET;

CREATE TABLE item_added (
  cart_id BIGINT,
  item_id BIGINT,
  proc_time AS PROCTIME()
) WITH (
  'connector' = 'kafka',
  'topic' = 'item_added',
  'properties.bootstrap.servers' = 'kafka1:9092',
  'format' = 'avro-confluent',
  'avro-confluent.url' = 'http://schema-registry:8081',
  'key.format' = 'avro-confluent',
  'key.fields' = 'cart_id',
  'key.avro-confluent.url' = 'http://schema-registry:8081',
  'value.format' = 'avro-confluent',
  'value.fields-include' = 'EXCEPT_KEY',
  'properties.group.id' = 'flink_table_item_added', -- CG name needed for Kafka
  'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
);

CREATE TABLE item_removed (
  cart_id BIGINT,
  item_id BIGINT,
  proc_time AS PROCTIME()
) WITH (
    'topic' = 'item_removed',
    'properties.group.id' = 'flink_table_item_removed', -- CG name needed for Kafka
    'key.fields' = 'cart_id',
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka1:9092',
    'format' = 'avro-confluent',
    'avro-confluent.url' = 'http://schema-registry:8081',
    'key.format' = 'avro-confluent',
    'key.avro-confluent.url' = 'http://schema-registry:8081',
    'value.format' = 'avro-confluent',
    'value.fields-include' = 'EXCEPT_KEY',
    'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
);

CREATE TABLE merged_cart_actions_sink (
  cart_id BIGINT,
  item_id BIGINT,
  action STRING,
  proc_time AS PROCTIME()
) WITH (
    'topic' = 'merged_cart_actions',
    'properties.group.id' = 'flink_table_merged_cart_actions_sink', -- CG name needed for Kafka
    'key.fields' = 'cart_id',
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka1:9092',
    'format' = 'avro-confluent',
    'avro-confluent.url' = 'http://schema-registry:8081',
    'key.format' = 'avro-confluent',
    'key.avro-confluent.url' = 'http://schema-registry:8081',
    'value.format' = 'avro-confluent',
    'value.fields-include' = 'EXCEPT_KEY',
    'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
);

CREATE TEMPORARY VIEW shopping_cart_state AS (
  SELECT 
      cart_id,
      item_id,
      COALESCE(SUM(quantity), 0) as quantity
  FROM (
      SELECT cart_id, item_id, 1 as quantity
      FROM item_added
      
      UNION ALL
      
      SELECT cart_id, item_id, -1 as quantity
      FROM item_removed
  ) combined
  GROUP BY cart_id, item_id
  HAVING COALESCE(SUM(quantity), 0) > 0
);

SELECT * FROM shopping_cart_state;
-- END;