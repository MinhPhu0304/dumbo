-- +goose Up
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION dumbo.enqueue_event() RETURNS trigger
LANGUAGE plpgsql
AS $_$
DECLARE
  external_id varchar;
  changes jsonb;
  col record;
  outbound_event record;
BEGIN
  SELECT dumbo.external_id_relations.external_id INTO external_id
  FROM dumbo.external_id_relations
  WHERE table_name = TG_TABLE_NAME;

  IF TG_OP = 'INSERT' THEN
    EXECUTE format('SELECT ($1).%s::text', external_id) USING NEW INTO external_id;
  ELSE
    EXECUTE format('SELECT ($1).%s::text', external_id) USING OLD INTO external_id;
  END IF;

  IF TG_OP = 'INSERT' THEN
    changes := row_to_json(NEW);
  ELSIF TG_OP = 'UPDATE' THEN
    changes := row_to_json(NEW);
    -- Remove object that didn't change
    FOR col IN SELECT * FROM jsonb_each(row_to_json(OLD)::jsonb) LOOP
      IF changes->col.key = col.value THEN
        changes = changes - col.key;
      END IF;
    END LOOP;
  ELSIF TG_OP = 'DELETE' THEN
    changes := '{}'::jsonb;
  END IF;

  -- Don't enqueue an event for updates that did not change anything
  IF TG_OP = 'UPDATE' AND changes = '{}'::jsonb THEN
    RETURN NULL;
  END IF;

  INSERT INTO dumbo.outbound_event_queue(external_id, table_name, statement, data)
  VALUES (external_id, TG_TABLE_NAME, TG_OP, changes)
  RETURNING * INTO outbound_event;

  PERFORM pg_notify('outbound_event_queue', TG_OP);

  RETURN NULL;
END
$_$;
CREATE OR REPLACE FUNCTION dumbo.create_snapshot_events(table_name_ref regclass) RETURNS void
LANGUAGE plpgsql
AS $_$
DECLARE
  query text;
  rec record;
  changes jsonb;
  external_id_ref varchar;
  external_id varchar;
BEGIN
  SELECT dumbo.external_id_relations.external_id INTO external_id_ref
  FROM dumbo.external_id_relations
  WHERE dumbo.external_id_relations.table_name = table_name_ref::varchar;

  query := 'SELECT * FROM ' || table_name_ref;

  FOR rec IN EXECUTE query LOOP
    changes := row_to_json(rec);
    external_id := changes->>external_id_ref;

    INSERT INTO dumbo.outbound_event_queue(external_id, table_name, statement, data)
    VALUES (external_id, table_name_ref, 'SNAPSHOT', changes);
  END LOOP;

  PERFORM pg_notify('outbound_event_queue', 'SNAPSHOT');
END
$_$;
-- +goose StatementEnd

-- +goose Down
