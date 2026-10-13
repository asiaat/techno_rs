SHOW server_version;
SHOW config_file;

SELECT name, setting, unit, context, source, pending_restart
FROM pg_settings
WHERE name IN (
'shared_buffers',
'work_mem',
'hash_mem_multiplier',
'maintenance_work_mem',
'effective_cache_size',
'max_connections'
)
ORDER BY name;

SELECT state, count(*)
FROM pg_stat_activity
GROUP BY state
ORDER BY count(*) DESC;

