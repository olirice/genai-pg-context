begin;

---------------------------------------------
-- drop and recreate the schema for a clean test run
---------------------------------------------
drop schema if exists minimal_test cascade;
create schema minimal_test;
set search_path to minimal_test;

---------------------------------------------
-- 1) extension (skip uuid-ossp; keep file_fdw)
---------------------------------------------
create extension if not exists file_fdw;
comment on extension file_fdw is 'file-based foreign data wrapper';

---------------------------------------------
-- 2) user-defined types
---------------------------------------------
-- enum type
create type my_enum as enum ('option_a', 'option_b');
comment on type my_enum is 'enum type example';

-- composite type
create type my_composite as (
    col1 int,
    col2 text
);
comment on type my_composite is 'composite type example';

-- domain
create domain my_domain as int
    check (value > 0);
comment on domain my_domain is 'domain example';

---------------------------------------------
-- 3) sequence
---------------------------------------------
create sequence my_sequence
    start 1
    increment 1
    minvalue 1
    cache 1;
comment on sequence my_sequence is 'sequence example';

---------------------------------------------
-- 4) tables
---------------------------------------------
create table parent_table (
    id serial primary key,               -- automatically creates index + constraint
    val text not null unique,
    my_col my_enum default 'option_a' not null,
    check (length(val) > 0)
);
comment on table parent_table is 'parent table example';
comment on column parent_table.id is 'id primary key';
comment on column parent_table.val is 'value column';
comment on column parent_table.my_col is 'enum column';

-- enable row-level security + sample policy
alter table parent_table enable row level security;

create policy parent_table_policy
on parent_table
for select
to public
using (true);
comment on policy parent_table_policy on parent_table is 'row-level security policy';

create table child_table (
    id int not null default nextval('my_sequence'),
    parent_id int references parent_table (id),
    val text,
    some_data my_domain,
    constraint child_pk primary key (id),
    constraint child_val_not_empty check (length(val) > 0)
);
comment on table child_table is 'child table example';
comment on column child_table.id is 'id using sequence';
comment on column child_table.parent_id is 'foreign key to parent_table';
comment on column child_table.val is 'value column';
comment on column child_table.some_data is 'this is a column comment.';
comment on constraint child_pk on child_table is 'child table primary key';
comment on constraint child_val_not_empty on child_table is 'child table check constraint';

-- add an index
create index child_val_idx on child_table (val);
comment on index child_val_idx is 'index on child_table.val';

---------------------------------------------
-- 5) views
---------------------------------------------
create view parent_table_view as
select id, val, my_col
from parent_table
where length(val) > 1;
comment on view parent_table_view is 'simple view of parent_table';

---------------------------------------------
-- 6) materialized views
---------------------------------------------
create materialized view parent_table_matview as
select id, val
from parent_table
where length(val) > 1;
comment on materialized view parent_table_matview is 'materialized view of parent_table';

---------------------------------------------
-- 7) aggregates
---------------------------------------------
create function my_agg_step(state integer, next_value integer)
returns integer
language sql
as $$
    select state + next_value;
$$;
comment on function my_agg_step(integer, integer) is 'aggregate step function';

create function my_agg_final(state integer)
returns integer
language sql
as $$
    select state;
$$;
comment on function my_agg_final(integer) is 'aggregate final function';

create aggregate my_agg(integer) (
    sfunc = my_agg_step,
    stype = integer,
    finalfunc = my_agg_final,
    initcond = 0
);
comment on aggregate my_agg(integer) is 'custom integer aggregator';

---------------------------------------------
-- 8) procedures
---------------------------------------------
create procedure my_procedure(arg_val text)
language plpgsql
as $$
begin
    raise notice 'argument passed: %', arg_val;
end;
$$;
comment on procedure my_procedure(text) is 'example procedure';

---------------------------------------------
-- 9) trigger function & trigger
---------------------------------------------
create function my_trigger_function()
returns trigger
language plpgsql
as $$
begin
    -- simple example: just return the row
    return new;
end;
$$;
comment on function my_trigger_function() is 'trigger function example';

create trigger my_row_trigger
before insert on child_table
for each row
execute procedure my_trigger_function();
comment on trigger my_row_trigger on child_table is 'trigger example';

---------------------------------------------
-- 10) foreign table (file_fdw)
---------------------------------------------
create server test_file_server
foreign data wrapper file_fdw;
comment on server test_file_server is 'file fdw server example';

create foreign table my_foreign_table (
    col1 int,
    col2 text
)
server test_file_server
options (filename '/tmp/my_data.csv', format 'csv');
comment on foreign table my_foreign_table is 'foreign table example';

---------------------------------------------
-- 11) event trigger
---------------------------------------------
create function my_event_trigger_function()
returns event_trigger
language plpgsql
as $$
begin
    -- do nothing for now
end;
$$;
comment on function my_event_trigger_function() is 'event trigger function example';

create event trigger my_event_trigger
on ddl_command_start
execute procedure my_event_trigger_function();
comment on event trigger my_event_trigger is 'event trigger example';

---------------------------------------------
-- 12) publications
---------------------------------------------
create publication my_publication
for table parent_table;
comment on publication my_publication is 'example publication';

select jsonb_pretty(public.get_context());

rollback;
