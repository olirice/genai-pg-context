begin;

    select jsonb_pretty(public.get_context());

rollback;
