-- +goose Up
-- +goose StatementBegin

CREATE INDEX IF NOT EXISTS outbound_event_queue_id_index ON dumbo.outbound_event_queue (id);
-- +goose StatementEnd
-- +goose Down