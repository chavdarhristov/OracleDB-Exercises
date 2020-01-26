select sid,'(' || username ||')' as Username
  from v$session
  where username = 'BBC'
  ;
  
  select case column_id || column_name
  when  1  then 'select ' 
  else ',' || column_name
  end as line
    from dba_tab_cols
    where owner = 'BBC'
      and table_name = 'MOTHER'
      ;
      
select constraint_name 
  from dba_constraints
    where owner='BBC'
    and table_name = 'MOTHER'
    ;
    
select constraint_name , r_constraint_name
  from dba_constraints
  where owner = 'BBC'
  and table_name = 'CHILD'
  and constraint_type = 'R'
  ;
      
  describe dba_tab_cols;
  
  
  select sid,username
  from v$session
  where username ! = NULL
  ;
  
  
  -----------------------------------
  -------------------------------------
  --1. Dynamic performance views (well, not all) have names that start with V$. Use the static
--data dictionary to obtain a list of the dynamic performance views. 
select view_name,owner from DBA_VIEWS
  where view_name like 'V_$%'
  group by owner,view_name
  ;

describe dba_views;

--2. Using the V$SESSION view, find the processes running on your instance. Can you identify
--which process is yourself? And what might some of the others be?
describe v$session ;
select 'The processes  :'||sid,event,service_name,process,type from V$Session 
;

--3. Oracle is a known memory hog. Use the V$SGA view to calculate how much memory your
--instance is using for Shared Global Area. And, once you have that number, could you
--please return it in Gigabytes as well?
describe v$sga;
select * from V$sga;
select  (SUM(value))/(1024*1024*1024) || ' Gigabytes ' "Total memory GB" from v$sga;

--4. Besides the SGA, each session also uses memory. This is exposed on a session-by-bysession
--level in the view V$SESSTAT, so we will need to sum this for all sessions. Join
--V$SESSTAT with the view V$STATNAME in order to limited the search for the statistic named
--'session pga memory' V$SESSTAT keeps a running tally in a number of counter of the resources that your session
--consumes. Again and again in this course we will use this to investigate the costs of different
--solutions. So, the technique here will be come in handy again later.

describe v$sesstat;
describe V$STATNAME;

select count(*) from V$STATNAME;
select count(*) from v$sesstat;

select * from v$statname where display_name = 'session pga memory';

select sum(a.VALUE) from v$sesstat a
join v$statname b
on a.STATISTIC# = b.STATISTIC#
where b.DISPLAY_NAME = 'session pga memory'
;

--5. You need the mother and child tables with some data. I have uploaded a script to
--studynet that will create the tables and put some data in. Copy and run this script
--6. Write a piece of SQL that retrieves one mother (with some ID) and all of her children (so
--we are clearly in join-territory here)

describe mother;
describe child;

select m.id,substr(m.name,1,10) as"Mothers name",substr(c.name,1,25) as "Childs name",c.dateofbirth 
from mother m
join child c
on m.id=c.MOTHERID
where m.id=1
;

--7. Expand the code from question 4
--7.1. Change it so it shows ALL the different resource counters for your session. You can
--identify your own session by adding the line where sid =
--sys_context(‘userenv’,’sid’) to the SQL. 
--7.2. Take a peek at the results: how many different types of ressources can we track the
--consumption of

select a.STATISTIC#,b.NAME,a.VALUE
from v$sesstat a
join v$statname b
on a.STATISTIC# = b.STATISTIC#
where value != 0
order by a.value desc
;

select a.STATISTIC#,b.NAME,a.VALUE
from v$sesstat a
join v$statname b
on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid') and a.value != 0
order by a.STATISTIC# 
;

--8. One of the resource counters is named 'Consistent gets' This records the number of
--times your session has requested a block of data to be read.
--8.1. Change the SQL to retrieve only that value
--8.2. Make a note of the value that you find


select a.STATISTIC#,b.NAME,a.VALUE
from v$sesstat a
join v$statname b
on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid')
and name = 'consistent gets'
;


--9. Run the SQL that retrieves a mother and her children
select m.id,m.name as "Mothers name",c.name as "Childs name",c.dateofbirth 
from mother m
join child c
on m.id=c.MOTHERID
where m.id=-357
;



--10. Find the IO cost of retrieving the rows:
--10.1. Re-run the SQL that retrieves the value of 'Consistent gets'
--10.2. Calculate the difference between the value that you now got and the one from point
--      8.2. The difference is the number of blocks that Oracle had to read to return your
--      data

-- consistent gets : 48423 - 47474 = 949 mother found
-- consistent gets : 48494 - 48423 = 71 mother not found



--11. Repeat steps 8, 9 and 10 a couple of times and calculate the average of the IO cost for the
--executions1

--1 48423 - 47474 = 949 mother found
--999 49445 - 48563 = 882 mother found
--500 50394 - 49445 = 949 mother found
--500 51276 - 50394 = 882 mother found

-- -1 48494 - 48423 = 71 mother not found



--12. Above, we got the IO cost for retrieving a mother and her children. Let try to improve that.
--12.1. Create an index on the foreign key in the Child table (use the create index name on
--tablename (columname) syntax
--12.2. Make sure that the query optimizer knows about the index. Use the execute
--DBMS_STATS.GATHER_TABLE_STATS ('owner','tablename') syntax for both tables
--12.3. Clear out any old execution plans. Use the alter system flush shared_pool
--syntax
--12.4. Repeat steps 8 through 11
--12.5. Compare the IO cost without and with the index in place. Was the index a good idea?

describe child ;
create index childIndex on child (motherid)
;

execute SYS.DBMS_STATS.GATHER_TABLE_STATS('AAD' , 'CHILD');
execute dbms_stats.gather_table_stats('AAD','MOTHER');

alter system flush shared_pool;
--
-- 500 73572 - 73311 = 261;
-- 256 73581 - 73572 = 9;
-- 999 73590 - 73581 = 9;
---357 73594 - 73590 = 4;


--13.Stalking is fun! (if you only do it in Oracle, and stay within what is legal!). We can use the
--dynamic performance views to investigate what any user on the system is doing.
--The V$SESSION view exposes all active sessions. The view has two columns, SQL_ID and
--PREV_SQL_ID. These are both foreign keys to another view, V$SQL (so, it is a 1 .. 0..2
--relationship). This, amongst other things, holds the text of SQL statements that the
--database has been/is executing
--13.1. Write SQL that joins the two views for your own session (check question 7 for hints),
--showing which SQL statements that you are running/just ran.

describe v$sql;


select  a.sql_id,  a.prev_sql_id,b.sql_text,c.sql_text from V$SESSION a
left join v$sql b on a.sql_id = b.sql_id
join v$sql c on a.prev_sql_id = c.sql_id
where sid =sys_context('userenv','sid')
;


