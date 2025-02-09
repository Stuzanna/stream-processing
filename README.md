# stream-processing
A collection of examples and learning on stream processing. Useful for getting setup locally in no time, introduction to fundamental concepts and reading my provided examples.

# Flink
Exploration of Apache Flink, different sections will include guides on how-to as well as references to stream processing concepts including:
1. Get started stack with Flink
1. Templated or simple guide on using Flink with Kafka
1. Examples where I reworked exercises using kSQLdb to be done in Flink, from Confluent's course [Introduction to Designing Events and Event Streams](https://developer.confluent.io/courses/event-design/intro/)


## Accessing the SQL Client
For running Flink SQL commands there is a sql-client service in the docker-compose.

```bash
docker compose exec -it sql-client bash -c "bin/sql-client.sh" # one in stack
docker compose exec -it sql-client bash # for terminal

docker compose run sql-client # standalone
```

## Kafka Tables
This is the relational table behaviour side of the Kafka topic, the stream table duality concept. Creating a table that models the data within the Kafka topic.

Topics should be created before the tables. This is closer to real-world behaviour where the creation of topics is usually governed and splits the infrastructure management concern from processing logic.

Running the SQL in the SQL client, **create a Kafka table** with:
```sql
--DDL for Flink table, a Kafka table
CREATE TABLE items(
  id BIGINT,
  price DECIMAL(10, 2),
  name STRING,
  description STRING,
  brand_id BIGINT,
  tax_status_id BIGINT,
  proc_time AS PROCTIME()
) WITH (
  'topic' = 'items',
  'key.fields' = 'id',
  'properties.group.id' = 'flink_table_items', -- CG name needed for Kafka
  'connector' = 'kafka',
  'properties.bootstrap.servers' = 'kafka1:9092',
  'format' = 'avro-confluent',
  'avro-confluent.url' = 'http://schema-registry:8081',
  'key.format' = 'avro-confluent',
  'key.avro-confluent.url' = 'http://schema-registry:8081',
  'value.format' = 'avro-confluent',
  'value.fields-include' = 'EXCEPT_KEY', -- set on key.fields property above, exclude the key in the value
  'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
--   'scan.startup.mode' = 'earliest-offset'
--   'properties.security.protocol' = 'PLAINTEXT',
--   'properties.sasl.mechanism' = 'PLAINTEXT', 
--   'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="" password="";',
--   'value.format' = 'json', -- alternative for just JSON
--   'sink.partitioner' = 'fixed' -- Fixed will send to same partition, for demo purposes only
);
```
There are more properties described in documentation, [the Flink docs](https://nightlies.apache.org/flink/flink-docs-master/docs/connectors/table/formats/avro-confluent/) were particularly useful for schema registry properties. Table properties can also be updated later on, see the [Flink docs](https://nightlies.apache.org/flink/flink-table-store-docs-release-0.3/docs/how-to/altering-tables/) for altering tables and example below.

`ALTER TABLE items SET ('properties.group.id'='flink_table_items');`

Some useful commands for interrogating tables in Flink were: `SHOW tables;` , `DESCRIBE items;` and `SHOW CREATE TABLE items;` for more info. Note lowercase works.

When building your processing queries you have to explicitly say which timestamps may be processing time, this can be added with:
```sql
ALTER TABLE items ADD proc_time AS PROCTIME();
```
