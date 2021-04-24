CREATE TABLE dev_user(
   id serial PRIMARY KEY,
   name text,
   create_at timestamptz default now()
);