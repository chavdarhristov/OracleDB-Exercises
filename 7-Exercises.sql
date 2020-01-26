describe v$latch;

select substr(name,1,30) as name
,(gets+immediat_gets) as total
, gets
, immediate_gets
from v$latch
order by (gets+immediate_gets) desc
;

-- ALTER SYSTEM FLUSH SHARED_POOL
--

select  a.sql_id,  a.prev_sql_id,b.sql_text,c.sql_text from V$SESSION a
left join v$sql b on a.sql_id = b.sql_id
join v$sql c on a.prev_sql_id = c.sql_id
where sid =sys_context('userenv','sid')
;

select substr(sql_text,1,100)as sql_text  from v$sql
where sql_text like '%child%' or sql_text like '%mother%'
;

--select id, yearBorn from child where motherID = :1  

select sum(gets+immediate_gets) as "totalLatch" from v$latch;

select name,(gets+immediate_gets) as latch from v$latch order by (latch) desc;

