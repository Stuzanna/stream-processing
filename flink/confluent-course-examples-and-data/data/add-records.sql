-- table creation
CREATE TABLE items(
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
    'properties.group.id' = 'flink_table_items', -- CG name needed for Kafka
  'properties.auto.offset.reset' = 'earliest' -- needed for Kafka
--   'properties.security.protocol' = 'PLAINTEXT',
--   'properties.sasl.mechanism' = 'PLAINTEXT', 
--   'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="" password="";',
--   'value.format' = 'json', -- alternative for just JSON
--   'sink.partitioner' = 'fixed' -- Send to same partition, for demo purpose only
);


-- Value insertion
INSERT INTO items (id, price, name, description, brand_id, tax_status_id)
VALUES 
    (1, 19.99, 'Baseball Trading Cards - Collector Edition', 'Premium Ol Slugger baseball trading cards!', 401, 778),
    (2, 0.99, 'Football Trading Cards', 'Premium NFL 2022 football trading cards!', 402, 778),
    (3, 19.99, 'Hockey Trading Cards', 'Premium NHL hockey trading cards!', 403, 778),
    (4, 49.99, 'Basketball Trading Cards', 'Premium NBA basketball trading cards!', 404, 778),
    (5, 24.99, 'Baseball Trading Cards', 'MLB official baseball trading cards set.', 405, 778),
    (6, 34.99, 'Soccer Trading Cards', 'Exclusive FIFA World Cup trading cards.', 406, 778),
    (7, 9.99, 'Tennis Trading Cards', 'Official ATP/WTA trading cards.', 407, 778),
    (8, 14.99, 'Golf Trading Cards', 'PGA Tour trading cards set.', 408, 778),
    (9, 4.99, 'Pokemon Cards Booster Pack', 'Official Pokemon trading card booster pack.', 409, 779),
    (10, 19.99, 'Magic: The Gathering Cards', 'Core set of Magic: The Gathering cards.', 410, 779),
    (11, 29.99, 'Yu-Gi-Oh! Cards', 'Starter set of Yu-Gi-Oh! trading cards.', 411, 779),
    (12, 12.99, 'Dinosaur Trading Cards', 'Educational dinosaur trading cards set.', 412, 778),
    (13, 9.49, 'Marvel Trading Cards', 'Marvel superheroes collector cards.', 413, 778),
    (14, 15.99, 'DC Comics Trading Cards', 'DC Comics superhero trading card collection.', 414, 778),
    (15, 10.49, 'Star Wars Trading Cards', 'Collector’s edition Star Wars trading cards.', 415, 779),
    (16, 20.99, 'Harry Potter Trading Cards', 'Wizarding World-themed trading cards.', 416, 779),
    (17, 11.49, 'Anime Trading Cards', 'Collector’s anime trading cards.', 417, 778),
    (18, 22.99, 'Retro Gaming Cards', 'Classic gaming character trading cards.', 418, 778),
    (19, 8.99, 'Animal Trading Cards', 'Set of animal-themed trading cards.', 419, 778),
    (20, 17.49, 'Space Exploration Cards', 'Educational space-themed trading cards.', 420, 778),
    (21, 7.99, 'Nature Trading Cards', 'Environmental and nature-themed cards.', 421, 778),
    (22, 19.99, 'Mythology Trading Cards', 'Mythological characters trading cards set.', 422, 778),
    (23, 14.49, 'Historical Events Cards', 'Educational trading cards about history.', 423, 778),
    (24, 13.99, 'Art Masterpieces Cards', 'Famous art masterpieces trading cards.', 424, 778),
    (25, 18.99, 'Science Fiction Cards', 'Sci-fi universe trading cards collection.', 425, 779);
