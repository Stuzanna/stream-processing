-- Create tables, insert data
CREATE TABLE brands (
  id BIGINT,
  name STRING,
  proc_time AS PROCTIME()
) WITH (
    'connector' = 'kafka',
    'topic' = 'brands',
    'properties.bootstrap.servers' = 'kafka1:9092',
    'format' = 'avro-confluent',
    'avro-confluent.url' = 'http://schema-registry:8081',
    'key.format' = 'avro-confluent',
    'key.fields' = 'id',
    'key.avro-confluent.url' = 'http://schema-registry:8081',
    'value.format' = 'avro-confluent',
    'value.fields-include' = 'EXCEPT_KEY',
    'properties.group.id' = 'flink_table_brands', -- CG name needed for Kafka
    'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
);

CREATE TABLE tax_status (
  id BIGINT,
  state_tax DECIMAL(3, 2),
  country_tax DECIMAL(3, 2),
  proc_time AS PROCTIME()
) WITH (
    'connector' = 'kafka',
    'topic' = 'tax_status',
    'properties.bootstrap.servers' = 'kafka1:9092',
    'format' = 'avro-confluent',
    'avro-confluent.url' = 'http://schema-registry:8081',
    'key.format' = 'avro-confluent',
    'key.fields' = 'id',
    'key.avro-confluent.url' = 'http://schema-registry:8081',
    'value.format' = 'avro-confluent',
    'value.fields-include' = 'EXCEPT_KEY',
    'properties.group.id' = 'flink_table_tax_status', -- CG name needed for Kafka
    'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
);

CREATE TABLE unenriched_items (
  id BIGINT,
  price DECIMAL(10, 2),
  name STRING,
  description STRING,
  brand_id BIGINT,
  tax_status_id BIGINT,
  proc_time AS PROCTIME()
) WITH (
    'connector' = 'kafka',
    'topic' = 'unenriched_items',
    'properties.bootstrap.servers' = 'kafka1:9092',
    'format' = 'avro-confluent',
    'avro-confluent.url' = 'http://schema-registry:8081',
    'key.format' = 'avro-confluent',
    'key.fields' = 'id',
    'key.avro-confluent.url' = 'http://schema-registry:8081',
    'value.format' = 'avro-confluent',
    'value.fields-include' = 'EXCEPT_KEY',
    'properties.group.id' = 'flink_table_unenriched_items', -- CG name needed for Kafka
    'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
);


-- Sample brand
INSERT INTO brands (id, name) VALUES (400, 'ACME');
-- Sample tax
INSERT INTO tax_status (id, state_tax, country_tax) VALUES (777, 0.05, 0.10);


-- Add sample items, uses brand and tax ID, not value
INSERT INTO unenriched_items (id, price, name, description, brand_id, tax_status_id)
VALUES (9000, 19.99, 'Ball', 'Rubber Ball', 400, 777);
INSERT INTO unenriched_items (id, price, name, description, brand_id, tax_status_id)
VALUES (9001, 39.99, 'Baseball Glove', 'Leather Baseball Glove', 400, 777);
INSERT INTO unenriched_items (id, price, name, description, brand_id, tax_status_id)
VALUES (9002, 2.99, 'Tennis Ball', 'Green Tennis Ball', 400, 777);
