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

INSERT INTO item_added (cart_id, item_id)
VALUES 
    (1234, 200),
    (1234, 200),
    (1234, 200),
    (1234, 400);

INSERT INTO item_removed (cart_id, item_id)
VALUES 
    (1234, 200);


--Final view of the state

-- CREATE VIEW shopping_cart_state AS
-- SELECT 
--     cart_id,
--     item_id,
--     COALESCE(SUM(quantity), 0) as quantity
-- FROM (
--     SELECT cart_id, item_id, 1 as quantity
--     FROM item_added
    
--     UNION ALL
    
--     SELECT cart_id, item_id, -1 as quantity
--     FROM item_removed
-- ) combined
-- GROUP BY cart_id, item_id
-- HAVING COALESCE(SUM(quantity), 0) > 0;

-- SELECT * FROM shopping_cart_state;

-- Try send to Kafka but will hit issue with sending that grouped state
-- CREATE TABLE shopping_cart_state_sink(
--   cart_id BIGINT,
--   item_id BIGINT,
--   quantity INT,
--   proc_time AS PROCTIME()
-- ) WITH (
--   'topic' = 'shopping_cart_state',
--   'key.fields' = 'cart_id',
--   'properties.group.id' = 'flink_table_items', -- CG name needed for Kafka
--   'connector' = 'kafka',
--   'properties.bootstrap.servers' = 'kafka1:9092',
--   'format' = 'avro-confluent',
--   'avro-confluent.url' = 'http://schema-registry:8081',
--   'key.format' = 'avro-confluent',
--   'key.avro-confluent.url' = 'http://schema-registry:8081',
--   'value.format' = 'avro-confluent',
--   'value.fields-include' = 'EXCEPT_KEY',
--   'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
-- --   'scan.startup.mode' = 'earliest-offset'
-- --   'properties.security.protocol' = 'PLAINTEXT',
-- --   'properties.sasl.mechanism' = 'PLAINTEXT', 
-- --   'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="" password="";',
-- --   'value.format' = 'json', -- alternative for just JSON
-- --   'sink.partitioner' = 'fixed' -- Send to same partition, for demo purpose only
-- );