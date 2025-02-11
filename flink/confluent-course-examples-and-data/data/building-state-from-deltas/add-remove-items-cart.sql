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
