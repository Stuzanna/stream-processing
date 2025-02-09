CREATE VIEW all_items_10min_window_view AS
SELECT *
FROM TABLE(
    TUMBLE(
        TABLE items, 
        DESCRIPTOR(proc_time), 
        INTERVAL '10' MINUTES
    )
)
ORDER by window_time, id; -- Note adding DESC here seems to think its a field
