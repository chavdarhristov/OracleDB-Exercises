--3 Exercises Dynamic Physical Data Storage, part one: the life
--and times of the data block

--SETUP

drop table mother purge;
drop sequence sqmother;

/
create table mother 
(
 ID  number(10,0)
     not null
     constraint coPKMother
     primary key
     
 ,name char(100)
    not null
    
 ,gender char(01)
    not null
    constraint coCHMotherGender
    check(gender in('F'))

 ,dateOfBirth date
    not null
    
 ,meaninglessData varchar2(2000)
 ) pctfree 0
;
----------------------
--inserting data into the tables

create sequence sqMother
  start with 1
  increment by 1
  noMaxValue
  cache 100
  ;
  

/
declare
 
  noOfMothers  constant int := 5000;
  
begin

execute immediate 'truncate table mother';
  for m in 1..noOfMothers loop
  
     insert into mother (id,name,gender,dateOfBirth,meaninglessData)
     values (    sqMother.nextval
              , 'Mother ' || to_char(sqMother.currval)
              , 'F'
              , sysdate
              , 'Meaningless data please'
              );   
  end loop;
  commit;
end;
/
-------------------------------------
select count(*) from mother;
---------------------------------------
/*
1. Find the following information about the mother table, by looking at the right places in the
static data dictionary (you may have to look in the static data dictionary to find where in
the static data dictionary the information is exposed) :
1.1. In which tablespace was your table created?
1.2. What are the sizes of the initial and subsequent extents?
1.3. What is the percentage of freespace per data block?
(hint: if you go searching for this in the data dictionary, be aware that the parameter
is not called freespace, but, as will become clear later, PCTFREE. And, irritatingly, in
the static data dictionary it is spelled differently again. Your safest bet may be to
search for any column in the static data dictionary where the name contains the
string FREE somewhere.
If you search in the manual instead, all this may be irrelevant…)
1.4. What file(s) will data from the table be stored in?
1.5. What is the size of a data block for the table?
*/

--1.1
describe SYS.DBA_TABLES;

select substr(table_name,1,20),substr(tablespace_name,1,20) from user_tables 
where table_name = 'MOTHER'
;

--1.2

select substr(table_name,1,20),initial_extent,next_extent from user_tables 
where table_name = 'MOTHER'
;

--TABLE_NAME                                         INITIAL_EXTENT                             NEXT_EXTENT
--MOTHER                                                 65536                                 1048576


--1.3

select substr(table_name,1,20) as table_name,AVG_SPACE_FREELIST_BLOCKS,pct_free from user_tables 
where table_name = 'MOTHER'
;
--10%

--1.4

describe dba_data_files;

select a.table_name,a.tablespace_name,b.file_id,b.file_name
from user_tables a join dba_data_files b
on a.tablespace_name = b.tablespace_name 
where a.table_name = 'MOTHER'
;
--FILE_ID   FILE_NAME
--   7      D:\APP\ICHAKP\VIRTUAL\ORADATA\ORCL\USERS01.DBF   

select * from dba_data_files;

--1.5
select a.table_name,b.*
from user_tables a join dba_data_files b
on a.tablespace_name = b.tablespace_name 
where a.table_name = 'MOTHER'
;

--block size

select a.table_name,(b.bytes/b.blocks) as "Block size",b.bytes,b.blocks
from user_tables a join dba_data_files b
on a.tablespace_name = b.tablespace_name 
where a.table_name = 'MOTHER'
;




----------------------
/*2. How many blocks of data does the Mother table use?
  2.1. Find the answer using the static data dictionary (note that this requires updating
  table statistics using the DBMS_STATS package. Syntax for this was given in the
  exercise set for last week)*/


exec DBMS_STATS.GATHER_TABLE_STATS('AAD','MOTHER');
select substr(table_name,1,20) as table_name,initial_extent/(1024*8) as "initial blocks",next_extent/(1024*8) as "next blocks" from user_tables 
where table_name = 'MOTHER'
;
--TABLE_NAME                                    initial blocks                             next blocks
--MOTHER                                                     8                                     128



----------------------------
/*3. We can (and you will!) find the same information in another way.
Each row in the database has its own internal unique identifier, called a ROWID. Part of the
ROWID is the number of the data block that the row is stored in (see excerpt from the
Concept Manual assigned as reading for this session for details). You can select the ROWID
of any row, simply by issuing a SELECT ROWID from…. for the row.
We can decode the ROWID, using the DBMS_ROWID supplied PL/SQL package. It has a
function called DBMS_ROWID.ROWID_BLOCK_NUMBER() that takes a ROWID as input and
returns the block number of the row.



3.1. Use the DBMS_ROWID package to find the number of data blocks used for the
mother table.
3.2. Use the DBMS_ROWID package to find the average number of rows per block for the
mother table.
3.3. If the number of blocks that you got in 3.1 is different from what you got in question
     2.1 – spend a minute on wondering why that may be?
*/
--3.1.
describe dbms_rowid;

--displaying all the rowids (including those on the same blocks)
select id,dbms_rowid.rowid_block_number(rowid) as "Block number",rowid
from mother
;

--counting the number of distinct blocks
select count(distinct(dbms_rowid.rowid_block_number(rowid))) as "Number of blocks"
from mother
;
/*
                       Number of blocks
---------------------------------------
                                    100
*/                                    
--3.2 Displaying the number of rows per block and the block
select count(rowid) as "Number of rows per block",dbms_rowid.rowid_block_number(rowid) as "Block number" from mother 
group by dbms_rowid.rowid_block_number(rowid)
;
--AVG of the number of row per block
select avg(count(rowid)) as "Average rows per block"  from mother
group by dbms_rowid.rowid_block_number(rowid)
;
--
--               Average rows per block
---------------------------------------
--                                   50

--3.3 Done



--4. Write a select statement that will require reading all mothers3

select * from mother ;

explain plan for select * from mother;
select plan_table_output from table(dbms_xplan.display('plan_table',null,'basic'));
/*
Plan_Table_Output                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
----------------------------------------------------------------------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
| Id  | Operation         | Name   | Rows  | Bytes | Cost (%CPU)| Time     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
----------------------------------------------------------------------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
|   0 | SELECT STATEMENT  |        |  5000 |   678K|    30   (0)| 00:00:01 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
|   1 |  TABLE ACCESS FULL| MOTHER |  5000 |   678K|    30   (0)| 00:00:01 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
----------------------------------------------------------------------------
*/
select a.STATISTIC#,b.NAME,a.VALUE
from v$sesstat a
join v$statname b
on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid')
and name = 'consistent gets'
;

-- 139 consistent gets                                                       25203
-- 139 consistent gets                                                       25310

--------------------------------------------------------------------------------

/*
5. Write a select statement that will only retrieve five specific mothers, based on values of
their primary keys. The primary keys should be distributed across the range of PK values
for your table (e.g. if you have keys ranging from 1 to 5000, select #1, 1250, 2500, 3750
and 5000).
  5.1. Verify, by looking at the execution plan that your statement uses the primary key
  index rather than reading the entire table
  5.2. Use the relevant dynamic performance view(s) to find how many I/Os the execution
  of the statement requires. Remember to repeat this a few times until the result
  stabilizes on/around some value
*/

select * from mother
where id in (1,1250,2500,3750,5000);

explain plan for
select * from mother
where id in (1,1250,2500,3750,5000);
select plan_table_output from table(dbms_xplan.display('plan_table',null,'basic'));
/*
| Id  | Operation                    | Name       |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
---------------------------------------------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
|   0 | SELECT STATEMENT             |            |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
|   1 |  INLIST ITERATOR             |            |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
|   2 |   TABLE ACCESS BY INDEX ROWID| MOTHER     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
|   3 |    INDEX UNIQUE SCAN         | COPKMOTHER |
*/
select a.STATISTIC#,b.NAME,a.VALUE
from v$sesstat a
join v$statname b
on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid')
and name = 'consistent gets'
;
--Before       139 consistent gets                                                       51656
--After1       139 consistent gets                                                       51668
--After2       139 consistent gets                                                       51680
--After3       139 consistent gets                                                       51692
--Conclusion: I/O cost stabilised at 12 consistent gets


-----------------------------------------------------------

--6.Drop the mother table. Recreate it, this time specifying PCTFREE 0. Insert 5000 mothers.


drop table mother purge;
drop sequence sqmother;
select count(*) from mother;


/*
7. Let us investigate the amount of space required with this version of the table
  7.1. Using the data dictionary, find the number of blocks used by the table
  7.2. Do the same, this time using the DBMS_ROWID package
  7.3. Using DBMS_ROWID, find the average number of rows per block
*/

--7.1
exec DBMS_STATS.GATHER_TABLE_STATS('AAD','MOTHER');
select substr(table_name,1,20) as table_name,initial_extent/(1024*8) as "initial blocks",next_extent/(1024*8) as "next blocks" from user_tables 
where table_name = 'MOTHER'
;
/*  The same as question 2
TABLE_NAME                                    initial blocks                             next blocks
-------------------- --------------------------------------- ---------------------------------------
MOTHER                                                     8                                     128
*/
--7.2   The number of blocks used is smaller than before (100) because all the space from the blocks is being used
--counting the number of distinct blocks
select count(distinct(dbms_rowid.rowid_block_number(rowid))) as "Number of blocks"
from mother
;
/*
                       Number of blocks
---------------------------------------
                                     90
*/
--7.3   More rows can fit into a block as the storage space in a block has increased (Before result 50)

-- Displaying the number of rows per block and the block
select count(rowid) as "Number of rows per block",dbms_rowid.rowid_block_number(rowid) as "Block number" from mother 
group by dbms_rowid.rowid_block_number(rowid)
;
--AVG of the number of row per block
select avg(count(rowid)) as "Average rows per block"  from mother
group by dbms_rowid.rowid_block_number(rowid)
;
/*
                 Average rows per block
---------------------------------------
                                56
*/



----------------------------------------------------
--9. Repeat exercise 4
--   9.1. Compare the I/O cost of reading all rows between the two versions of the table
select * from mother ;

explain plan for select * from mother;
select plan_table_output from table(dbms_xplan.display('plan_table',null,'all'));

/* The same as before
| Id  | Operation         | Name   | Rows  | Bytes | Cost (%CPU)| Time     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
----------------------------------------------------------------------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
|   0 | SELECT STATEMENT  |        |  5000 |   678K|    27   (0)| 00:00:01 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
|   1 |  TABLE ACCESS FULL| MOTHER |  5000 |   678K|    27   (0)| 00:00:01 |
*/

--9.1
select a.STATISTIC#,b.NAME,a.VALUE
from v$sesstat a
join v$statname b
on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid')
and name = 'consistent gets'
;
--       139 consistent gets                                                       67798 * 109
--       139 consistent gets                                                       67907 count 18
--       139 consistent gets                                                       67925 count 18
--       139 consistent gets                                                       67943 count 18
--       139 consistent gets                                                       67961 count 9
--       139 consistent gets                                                       68070 count 9
--       139 consistent gets                                                       68179 * 109
--       139 consistent gets                                                       68288 * 109
--       139 consistent gets                                                       68397 * 109
--       139 consistent gets                                                       68506 * 109
--Count(*) give around 18 I/O
--select* gives around 109







--10. Repeat exercise 5
--  10.1. Compare the I/O cost of reading specific rows between the two versions of the table
--  10.2. Discuss any differences found (if any). What have caused them?


select * from mother
where id in (1,1250,2500,3750,5000);

explain plan for
select * from mother
where id in (1,1250,2500,3750,5000);
select plan_table_output from table(dbms_xplan.display('plan_table',null,'all'));

select a.STATISTIC#,b.NAME,a.VALUE
from v$sesstat a
join v$statname b
on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid')
and name = 'consistent gets'
;

/*
       139 consistent gets                                                       68506 
       139 consistent gets                                                       68520 12
       139 consistent gets                                                       68532 12
       
       139 consistent gets                                                       68627  explain plan     
       139 consistent gets                                                       68639  12  
    
--Conclusion: I/O cost stabilised at 12 consistent gets the same result as before

|   0 | SELECT STATEMENT             |            |     5 |   695 |     3   (0)| 00:00:01 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
|   1 |  INLIST ITERATOR             |            |       |       |            |          |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
|   2 |   TABLE ACCESS BY INDEX ROWID| MOTHER     |     5 |   695 |     3   (0)| 00:00:01 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
|*  3 |    INDEX UNIQUE SCAN         | COPKMOTHER |     5 |       |     2   (0)| 00:00:01 |      
*/
