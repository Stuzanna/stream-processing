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
For running scripts see [Running SQL Scripts](#running-sql-scripts).

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

## Inserting Values
Insert values with SQL statements.
```sql
INSERT INTO items
VALUES (
    1,                                             
    CAST(19.99 AS DECIMAL(10, 2)),                
    'Baseball Trading Cards - Collector Edition',  
    'Premium Ol Slugger baseball trading cards!',  
    401,                                           
    778                                           
);
```
Appears on the topic.

Note if this fails on the Kafka side the message is lost, as the INSERT job completed, but Kafka failed, to have retries you need to insert from a streaming table rather than fire and forget one valid command. Examples of streaming tables which will retry:

```sql
-- One-time but with retries
INSERT INTO items
SELECT * FROM source_items -- populated table
WHERE id = 1;  -- Or any specific condition
```

You can also source items being from a filesystem table. Note this will include the header, I believe there are functions in the Java, Scala and Python libraries to ignore but not in the [connector config](https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/connectors/table/formats/csv/).
```sql
-- with the Kafka table already created (items in this example) 

-- create source filesystem table
CREATE TABLE items_from_file (
  id BIGINT,
  price DECIMAL(10, 2),
  name STRING,
  description STRING,
  brand_id BIGINT,
  tax_status_id BIGINT
) WITH (
  'connector' = 'filesystem',
  'path' = '/opt/flink/data/items_data.csv', -- local csv
  'format' = 'csv',
  'csv.ignore-parse-errors' = 'true',
  'csv.allow-comments' = 'true'
);

-- stream from source to the topic table
INSERT INTO items
SELECT *
  FROM items_from_file;
```
A note on failures. You can see the issue for failed jobs in the job manager log list by searching for `FAILED`, or specifically the job exception list as it throws an exception, it's a nice jump to the failure. Note this doesn't throw an **error** as it fails gracefully. Example I had was forgetting to make the topic beforehand.

## Running SQL scripts
You're likely to want to make things more repeatable, more scriptable or make a mistake/encounter an error and need to look back at commands. Running SQL scripts is useful here.  
**Note tables are kept in memory** unless persisted e.g. to Hive, then you need to start your SQL script with table creation if the container has been restarted.
[Flink doc examples](https://nightlies.apache.org/flink/flink-docs-release-1.13/docs/dev/table/sqlclient/#initialize-session-using-sql-files).

The below is how I found copying scripts into the container and running them to work nicely, change the environment variable `SQL_HOST`, to match your path as needed. I used `add-records.sql` to add any new records to a table.
```bash
docker compose exec sql-client bash -c "mkdir -p /opt/flink/opt/scripts/"
SQL_HOST=./confluent-course-examples-and-data/data/add-records.sql
SQL_CONTAINER=/opt/flink/opt/scripts/add-records.sql
docker cp $SQL_HOST sql-client:$SQL_CONTAINER
docker compose exec sql-client /opt/flink/bin/sql-client.sh -f $SQL_CONTAINER
```

## Working with the data
The `view-all-items.sql` script is for more than just adding data to the Kafka table (and hence underlying topic). It's a bit more useful:
* Create table for all_items
* Create a view from the table
* Set execution mode as this is non-interactive mode.
  * *As we're running in a script, non-interactive mode, you need to explicitly set the result mode. This isn't required when working in the SQL client (SQL terminal) directly as it sets it's own mode there*
* Views the view

Use the block above on [running SQL scripts](#running-sql-scripts) to run the script.
*Note this is blank if there's no data on the topic as there's nothing to view.*

## Data
`view-all-items.sql` - Creates a table for all_items, this is shopping cart items used in the exercises.
`add-records.sql` - Example to Add more records to a table.