create function public.get_context()
    returns jsonb
    language sql
    volatile
    set search_path = ''
as $$

select jsonb_build_object(
    'databases', coalesce(
        jsonb_agg(
            jsonb_build_object(
                'name', db,
                'schemas', coalesce(
                    (
                        select jsonb_agg(
                            jsonb_build_object(
                                'name', n.nspname,
                                'tables', coalesce(
                                    (
                                        select jsonb_agg(
                                            jsonb_build_object(
                                                'name', c.relname,
                                                'comment', pg_catalog.obj_description(c.oid, 'pg_class'),
                                                'columns', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', pa.attname,
                                                                'comment', pg_catalog.col_description(c.oid, pa.attnum),
                                                                'type', pg_catalog.format_type(pa.atttypid, pa.atttypmod),
                                                                'is_nullable', not pa.attnotnull,
                                                                'has_default', pd.adbin is not null,
                                                                'default', pg_get_expr(pd.adbin, pd.adrelid)
                                                            ) order by pa.attnum
                                                        )
                                                        from pg_attribute pa
                                                        left join pg_attrdef pd on (pa.attrelid = pd.adrelid and pa.attnum = pd.adnum)
                                                        where pa.attrelid = c.oid
                                                          and pa.attnum > 0
                                                          and not pa.attisdropped
                                                    ),
                                                    '[]'::jsonb
                                                ),
                                                'indexes', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', idx.relname,
                                                                'definition', pg_get_indexdef(i.indexrelid),
                                                                'comment', pg_catalog.obj_description(idx.oid, 'pg_class')
                                                            ) order by idx.relname
                                                        )
                                                        from pg_index i
                                                        join pg_class idx on idx.oid = i.indexrelid
                                                        where i.indrelid = c.oid
                                                    ),
                                                    '[]'::jsonb
                                                ),
                                                'foreign_keys', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', con.conname,
                                                                'definition', pg_get_constraintdef(con.oid),
                                                                'comment', pg_catalog.obj_description(con.oid, 'pg_constraint')
                                                            ) order by con.conname
                                                        )
                                                        from pg_constraint con
                                                        where con.conrelid = c.oid
                                                          and con.contype = 'f' -- only foreign keys
                                                    ),
                                                    '[]'::jsonb
                                                ),
                                                'constraints', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', con.conname,
                                                                'type', con.contype,
                                                                'definition', pg_get_constraintdef(con.oid),
                                                                'comment', pg_catalog.obj_description(con.oid, 'pg_constraint')
                                                            ) order by con.conname
                                                        )
                                                        from pg_constraint con
                                                        where con.conrelid = c.oid
                                                          and con.contype <> 'f' -- everything except foreign keys
                                                    ),
                                                    '[]'::jsonb
                                                ),
                                                'policies', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', pol.policyname,
                                                                'roles', pol.roles,
                                                                'cmd', pol.cmd,
                                                                'permissive', pol.permissive,
                                                                'qual', pol.qual,
                                                                'with_check', pol.with_check
                                                            ) order by pol.policyname
                                                        )
                                                        from pg_policies pol
                                                        where pol.schemaname = n.nspname
                                                          and pol.tablename = c.relname
                                                    ),
                                                    '[]'::jsonb
                                                ),
                                                'triggers', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', t.tgname,
                                                                'definition', pg_get_triggerdef(t.oid),
                                                                'comment', pg_catalog.obj_description(t.oid, 'pg_trigger')
                                                            ) order by t.tgname
                                                        )
                                                        from pg_trigger t
                                                        where t.tgrelid = c.oid
                                                          and not t.tgisinternal
                                                    ),
                                                    '[]'::jsonb
                                                )
                                            )
                                        )
                                        from pg_class c
                                        where c.relnamespace = n.oid
                                          and c.relkind = 'r' -- table
                                    ),
                                    '[]'::jsonb
                                ),
                                'views', coalesce(
                                    (
                                        select jsonb_agg(
                                            jsonb_build_object(
                                                'name', c.relname,
                                                'comment', pg_catalog.obj_description(c.oid, 'pg_class'),
                                                'security_definer', (
                                                    lower(coalesce(c.reloptions::text,'{}'))::text[]
                                                    && array['security_invoker=1', 'security_invoker=true', 'security_invoker=yes','security_invoker=on']
                                                ),
                                                'columns', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', pa.attname,
                                                                'comment', pg_catalog.col_description(c.oid, pa.attnum),
                                                                'type', pg_catalog.format_type(pa.atttypid, pa.atttypmod),
                                                                'is_nullable', not pa.attnotnull,
                                                                'has_default', pd.adbin is not null,
                                                                'default', pg_get_expr(pd.adbin, pd.adrelid)
                                                            ) order by pa.attnum
                                                        )
                                                        from pg_attribute pa
                                                        left join pg_attrdef pd on (pa.attrelid = pd.adrelid and pa.attnum = pd.adnum)
                                                        where pa.attrelid = c.oid
                                                          and pa.attnum > 0
                                                          and not pa.attisdropped
                                                    ),
                                                    '[]'::jsonb
                                                ),
                                                'dependencies', coalesce(
                                                    (
                                                        select
                                                            jsonb_agg(
                                                                jsonb_build_object(
                                                                    'schema', schema_name,
                                                                    'name', object_name,
                                                                    'entity_type', object_type
                                                                )
                                                                order by schema_name, object_name
                                                            ) as dependencies
                                                        from (
                                                            select distinct
                                                                n2.nspname as schema_name,
                                                                rc.relname as object_name,
                                                                case rc.relkind
                                                                    when 'r' then 'table'
                                                                    when 'v' then 'view'
                                                                    when 'm' then 'materialized view'
                                                                    else rc.relkind::text
                                                                end as object_type
                                                            from pg_depend d
                                                            join pg_rewrite r
                                                                on d.objid = r.oid
                                                            join pg_class c2
                                                                on r.ev_class = c2.oid
                                                            join pg_namespace n
                                                                on c2.relnamespace = n.oid
                                                            join pg_class rc
                                                                on d.refobjid = rc.oid
                                                            join pg_namespace n2
                                                                on rc.relnamespace = n2.oid
                                                            where c2.oid = c.oid
                                                              and d.deptype = 'n'
                                                              and rc.relkind in ('r','v','m') -- tables, views, matviews
                                                              and rc.oid != c.oid -- Exclude the view itself from the results
                                                        ) sub
                                                    ),
                                                    '[]'::jsonb
                                                )
                                            )
                                        )
                                        from pg_class c
                                        where c.relnamespace = n.oid
                                          and c.relkind = 'v' -- view
                                    ),
                                    '[]'::jsonb
                                ),
                                'aggregates', coalesce(
                                    (
                                        select jsonb_agg(
                                            jsonb_build_object(
                                                'name', p.proname,
                                                'comment', pg_catalog.obj_description(p.oid, 'pg_proc')
                                            )
                                        )
                                        from pg_proc p
                                        where p.pronamespace = n.oid
                                          and p.prokind = 'a' -- aggregate
                                    ),
                                    '[]'::jsonb
                                ),
                                'foreign_tables', coalesce(
                                    (
                                        select jsonb_agg(
                                            jsonb_build_object(
                                                'name', c.relname,
                                                'comment', pg_catalog.obj_description(c.oid, 'pg_class'),
                                                'columns', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', pa.attname,
                                                                'comment', pg_catalog.col_description(c.oid, pa.attnum),
                                                                'type', pg_catalog.format_type(pa.atttypid, pa.atttypmod),
                                                                'is_nullable', not pa.attnotnull,
                                                                'has_default', pd.adbin is not null,
                                                                'default', pg_get_expr(pd.adbin, pd.adrelid)
                                                            ) order by pa.attnum
                                                        )
                                                        from pg_attribute pa
                                                        left join pg_attrdef pd on (pa.attrelid = pd.adrelid and pa.attnum = pd.adnum)
                                                        where pa.attrelid = c.oid
                                                          and pa.attnum > 0
                                                          and not pa.attisdropped
                                                    ),
                                                    '[]'::jsonb
                                                )
                                            )
                                        )
                                        from pg_class c
                                        where c.relnamespace = n.oid
                                          and c.relkind = 'f' -- foreign table
                                    ),
                                    '[]'::jsonb
                                ),
                                'materialized_views', coalesce(
                                    (
                                        select jsonb_agg(
                                            jsonb_build_object(
                                                'name', c.relname,
                                                'comment', pg_catalog.obj_description(c.oid, 'pg_class'),
                                                'columns', coalesce(
                                                    (
                                                        select jsonb_agg(
                                                            jsonb_build_object(
                                                                'name', pa.attname,
                                                                'comment', pg_catalog.col_description(c.oid, pa.attnum),
                                                                'type', pg_catalog.format_type(pa.atttypid, pa.atttypmod),
                                                                'is_nullable', not pa.attnotnull,
                                                                'has_default', pd.adbin is not null,
                                                                'default', pg_get_expr(pd.adbin, pd.adrelid)
                                                            ) order by pa.attnum
                                                        )
                                                        from pg_attribute pa
                                                        left join pg_attrdef pd on (pa.attrelid = pd.adrelid and pa.attnum = pd.adnum)
                                                        where pa.attrelid = c.oid
                                                          and pa.attnum > 0
                                                          and not pa.attisdropped
                                                    ),
                                                    '[]'::jsonb
                                                )
                                            )
                                        )
                                        from pg_class c
                                        where c.relnamespace = n.oid
                                          and c.relkind = 'm' -- materialized view
                                    ),
                                    '[]'::jsonb
                                ),
                                'procedures', coalesce(
                                    (
                                        select jsonb_agg(
                                            jsonb_build_object(
                                                'name', p.proname,
                                                'argument_types', (
                                                    select array_agg(t.typname)
                                                    from unnest(p.proargtypes) arg
                                                    join pg_type t on t.oid = arg
                                                ),
                                                'comment', pg_catalog.obj_description(p.oid, 'pg_proc')
                                            )
                                        )
                                        from pg_proc p
                                        where p.pronamespace = n.oid
                                          and p.prokind = 'p' -- procedure
                                    ),
                                    '[]'::jsonb
                                ),
                                'trigger_functions', coalesce(
                                    (
                                        select jsonb_agg(
                                            jsonb_build_object(
                                                'name', p.proname,
                                                'comment', pg_catalog.obj_description(p.oid, 'pg_proc')
                                            )
                                        )
                                        from pg_proc p
                                        where p.pronamespace = n.oid
                                          and p.prorettype = 'pg_catalog.trigger'::regtype
                                    ),
                                    '[]'::jsonb
                                ),
                                'types', coalesce(
                                    (
                                        select jsonb_agg(
                                            jsonb_build_object(
                                                'name', t.typname,
                                                'comment', pg_catalog.obj_description(t.oid, 'pg_type'),
                                                'type_kind', case t.typtype
                                                    when 'b' then 'base'
                                                    when 'c' then 'composite'
                                                    when 'd' then 'domain'
                                                    when 'e' then 'enum'
                                                    when 'r' then 'range'
                                                    when 'm' then 'multirange'
                                                    when 'p' then 'pseudo'
                                                    else 'unknown'
                                                end,
                                                'enum_variants', case
                                                    when t.typtype = 'e' then (
                                                        select jsonb_agg(e.enumlabel)
                                                        from pg_enum e
                                                        where e.enumtypid = t.oid
                                                    )
                                                    else '[]'::jsonb
                                                end,
                                                'domain_base_type', case
                                                    when t.typtype = 'd' then pg_catalog.format_type(t.typbasetype, t.typtypmod)
                                                    else null
                                                end,
                                                'domain_constraints', case
                                                    when t.typtype = 'd' then coalesce(
                                                        (
                                                            select jsonb_agg(
                                                                jsonb_build_object(
                                                                    'name', con.conname,
                                                                    'definition', pg_catalog.pg_get_constraintdef(con.oid)
                                                                )
                                                            )
                                                            from pg_constraint con
                                                            where con.contypid = t.oid
                                                        ),
                                                        '[]'::jsonb
                                                    )
                                                    else '[]'::jsonb
                                                end
                                            )
                                        )
                                        from pg_type t
                                        where t.typnamespace = n.oid
                                          and t.typtype not in ('p','b') -- exclude built-in/pseudo types
                                          and t.typrelid = 0 -- exclude table row types,
                                    ),
                                    '[]'::jsonb
                                )
                            ) order by n.nspname
                        )
                        from pg_namespace n
                        where n.nspname not like 'pg_%'
                          and n.nspname <> 'information_schema'
                    ),
                    '[]'::jsonb
                ),
                'extensions', coalesce(
                    (
                        select jsonb_agg(
                            jsonb_build_object(
                                'name', x.name,
                                'available_version', x.default_version,
                                'installed_version', e.extversion,
                                'installed', e.extname is not null,
                                'schema', sn.nspname
                            ) order by x.name
                        )
                        from pg_available_extensions x
                        left join pg_extension e on x.name = e.extname
                        left join pg_namespace sn on e.extnamespace = sn.oid
                    ),
                    '[]'::jsonb
                )
            )
        ),
        '[]'::jsonb
    ))
from (select current_database() as db) as sub;

$$;
