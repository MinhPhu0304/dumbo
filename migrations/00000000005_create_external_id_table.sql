-- +goose Up

CREATE TABLE IF NOT EXISTS dumbo.external_id_relations (
  id            BIGSERIAL PRIMARY KEY,
  external_id   TEXT NOT NULL,
  table_name    TEXT NOT NULL
);

-- +goose Down