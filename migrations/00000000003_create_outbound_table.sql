-- +goose Up
CREATE TABLE IF NOT EXISTS dumbo.outbound_event_queue (
  id            BIGSERIAL PRIMARY KEY,
  uuid          uuid NOT NULL DEFAULT uuid_generate_v4(),
  external_id   varchar(255),
  table_name    varchar(255) NOT NULL,
  statement     varchar(20) NOT NULL,
  data          jsonb NOT NULL,
  created_at    timestamp NOT NULL DEFAULT current_timestamp,
  processed     boolean DEFAULT false
);

-- +goose Down