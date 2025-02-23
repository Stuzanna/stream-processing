--- create brands table
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

CREATE TABLE enriched_items (
  id BIGINT,
  price DECIMAL(10, 2),
  name STRING,
  description STRING,
  brand_name STRING,
  state_tax DECIMAL(3, 2),
  country_tax DECIMAL(3, 2),
  proc_time AS PROCTIME()
) WITH (
    'connector' = 'kafka',
    'topic' = 'enriched_items',
    'properties.bootstrap.servers' = 'kafka1:9092',
    'format' = 'avro-confluent',
    'avro-confluent.url' = 'http://schema-registry:8081',
    'key.format' = 'avro-confluent',
    'key.fields' = 'id',
    'key.avro-confluent.url' = 'http://schema-registry:8081',
    'value.format' = 'avro-confluent',
    'value.fields-include' = 'EXCEPT_KEY',
    'properties.group.id' = 'flink_table_enriched_streams', -- CG name needed for Kafka
    'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
);

-- View that updates
SET 'sql-client.execution.result-mode' = 'TABLEAU';
-- INSERT INTO enriched_items -- Alternatively run as a job instead of creating a view
CREATE VIEW continuous_enriched AS
SELECT 
    unenriched_items.id,
    unenriched_items.price,
    unenriched_items.name,
    unenriched_items.description,
    brands.name AS brand_name,
    tax_status.state_tax,
    tax_status.country_tax
FROM unenriched_items
    JOIN brands 
        ON unenriched_items.brand_id = brands.id
        AND unenriched_items.proc_time BETWEEN brands.proc_time - INTERVAL '1' MINUTE 
        AND brands.proc_time + INTERVAL '1' MINUTE
    JOIN tax_status 
        ON unenriched_items.tax_status_id = tax_status.id
        AND unenriched_items.proc_time BETWEEN tax_status.proc_time - INTERVAL '1' MINUTE 
        AND tax_status.proc_time + INTERVAL '1' MINUTE
;

SELECT * FROM continuous_enriched;
--  SELECT * FROM enriched_items;
