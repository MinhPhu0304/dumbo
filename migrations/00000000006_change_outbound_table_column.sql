-- +goose Up

ALTER TABLE dumbo.outbound_event_queue ALTER COLUMN statement TYPE text
    , ALTER COLUMN table_name TYPE text
    , ALTER COLUMN external_id TYPE text;

-- +goose Down
ALTER TABLE dumbo.outbound_event_queue ALTER COLUMN statement TYPE varchar(255)
    , ALTER COLUMN table_name TYPE varchar(255)
    , ALTER COLUMN external_id TYPE varchar(255);
