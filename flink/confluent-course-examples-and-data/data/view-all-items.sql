CREATE TABLE all_items(
  id BIGINT,
  price DECIMAL(10, 2),
  name STRING,
  description STRING,
  brand_id BIGINT,
  tax_status_id BIGINT
) WITH (
  'connector' = 'kafka',
  'topic' = 'items',
  'properties.bootstrap.servers' = 'kafka1:9092',
  'format' = 'avro-confluent',
  'avro-confluent.url' = 'http://schema-registry:8081',
  'key.format' = 'avro-confluent',
  'key.fields' = 'id',
  'key.avro-confluent.url' = 'http://schema-registry:8081',
  'value.format' = 'avro-confluent',
  'value.fields-include' = 'EXCEPT_KEY',
  'properties.group.id' = 'flink_all-items_table', -- CG name
  'scan.startup.mode' = 'earliest-offset'

--   'properties.security.protocol' = 'PLAINTEXT',
--   'properties.sasl.mechanism' = 'PLAINTEXT', 
--   'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="" password="";',
--   'value.format' = 'json', -- alternative for just JSON
--   'sink.partitioner' = 'fixed' -- Send to same partition, for demo purpose only
);


-- If you want to create a view or continuous query similar to KSQL EMIT CHANGES
CREATE VIEW all_items_view AS
SELECT * FROM all_items;

-- View the view
SET 'sql-client.execution.result-mode' = 'TABLEAU'; -- as we're running in a script, non-interactive mode, need explicit result mode
-- SET sql-client.execution.result-mode = table; 

SELECT * FROM all_items_view;
