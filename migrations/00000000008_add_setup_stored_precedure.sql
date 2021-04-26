-- +goose Up
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION dumbo.setup(table_name_ref regclass, external_id_name text) RETURNS void
LANGUAGE plpgsql
AS $_$
DECLARE
  existing_id varchar;
  trigger_name varchar;
  lock_query varchar;
  trigger_query varchar;
BEGIN
  SELECT dumbo.external_id_relations.external_id INTO existing_id
  FROM dumbo.external_id_relations
  WHERE dumbo.external_id_relations.table_name = table_name_ref::varchar;

  IF existing_id != '' THEN
    RAISE WARNING 'table/external_id relation already exists for %/%. Skipping setup.', table_name_ref, external_id_name;

    RETURN;
  END IF;

  INSERT INTO dumbo.external_id_relations(external_id, table_name)
  VALUES (external_id_name, table_name_ref);

  trigger_name := table_name_ref || '_enqueue_event';
  lock_query := 'LOCK TABLE ' || table_name_ref || ' IN ACCESS EXCLUSIVE MODE';
  trigger_query := 'CREATE TRIGGER ' || trigger_name
    || ' AFTER INSERT OR DElETE OR UPDATE ON ' || table_name_ref
    || ' FOR EACH ROW EXECUTE PROCEDURE dumbo.enqueue_event()';

  -- We aqcuire an exlusive lock on the table to ensure that we do not miss anything during migration
  EXECUTE lock_query;

  PERFORM dumbo.create_snapshot_events(table_name_ref);

  EXECUTE trigger_query;
END
$_$;
-- +goose StatementEnd
-- -goose down