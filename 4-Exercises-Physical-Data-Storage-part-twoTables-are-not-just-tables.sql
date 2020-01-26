--1 Create the tables with the organization specified for this set of exercises, and populate with
--  data. Use the supplied script

--Done

--2. Check data storage (using DBMS_ROWID)
--   2.1.A How many blocks does the mother table use? 
select count(distinct(dbms_rowid.rowid_block_number(rowid))) as "Number of blocks" from mother;
--Number of blocks 109
--2.1 B
select leaf_blocks from dba_indexes where table_name = 'MOTHER' and table_owner = 'AAD';
--LEAF_BLOCKS  100

--2.1 C  Blocks = 5000
select dbms_rowid.rowid_block_number(rowid) as "Number of blocks" from mother;
select count(distinct(dbms_rowid.rowid_block_number(rowid))) as "Number of blocks" from mother; 

--2.2 D 109
select count(distinct(dbms_rowid.rowid_block_number(rowid))) as "Number of blocks" from mother;


--2.2 A Ditto for the child table                                   
select count(distinct(dbms_rowid.rowid_block_number(rowid))) as "Number of Blocks" from child;    
--Number of Blocks 568
--2.2B Number of Blocks 567
--2.2C Blocks = 5000
--2.2D Blocks 569


--2.3.A Find the total number of blocks used to store the two tables.
select SUM(cnt) from 
(
(select count(distinct(dbms_rowid.rowid_block_number(rowid))) as cnt from mother)
union
(select count(distinct(dbms_rowid.rowid_block_number(rowid))) from child)
)t
;
--C and M Blocks 677

--2.3 B 667

select SUM(cnt) from 
(
(select leaf_blocks as cnt from dba_indexes where table_name = 'MOTHER' and table_owner='AAD') 
union
(select count(distinct(dbms_rowid.rowid_block_number(rowid))) from child)
)t
;

--2.3 C 5000
--2.3 D 678
        
        
                                    
--2.4. Choose one specific mother (say, motherID = 2500) 
--2.4.1.A In which block in the mother table is her data stored? 
select dbms_rowid.rowid_block_number(rowid) from mother
where id=2500 ;
--Block 205

describe dba_indexes;
select * from dba_indexes where table_name = 'MOTHER' and table_owner = 'AAD';
--2.4.1 B Leaf-blocks not specified
--2.4.1 C 2700
--2.4.1 D 349

--2.4.2.A In which blocks in the child table are her children stored? 
select id,dbms_rowid.rowid_block_number(rowid)  from child
where motherid=2500
;
/*A 
DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID)
---------------------------------------
                                    337
                                    586
                                    746
                                    869
                                    992
 B
 ---------- ---------------------------------------
                                 347
                                 588
                                 758
                                 877
                                 1128
C
ID    DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID)
---------- ---------------------------------------
      2500                                    2700
      7500                                    2700
     12500                                    2700
     17500                                    2700
     22500                                    2700
D
                                  8143
                                   8442
                                  6991
                                 5967
                                  6262
 */
                                    


--3. Retrieving mother data by table scan 
--3.1.A Write an SQL statement that retrieves the number of blond mothers 
select count(*) from mother
where HAIRCOLOR='blond';
--A 100
--B 100
--C 100
--D 100


--3.2. Find AND SAVE the execution plan. How does Oracle resolve the query?
set autotrace on;
select count(*) from mother
where HAIRCOLOR='blond' 
;
set autotrace off;
--3.3. Find the IO cost (in consistent gets) for executing that statement.

select a.STATISTIC#,b.NAME,a.VALUE from v$sesstat a join v$statname b on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid') and name = 'consistent gets'
;
/*A 114
  B 117
  C 5040
  D 114
*/


--4. Retrieving child data by table scan 
--4.1. Write an SQL statement that retrieves the count of children born in the year 2012 
describe child;
set autotrace off;
set autotrace on;

select count(*) from child
where yearborn=2012;
--4.2. Find AND SAVE the execution plan. How does Oracle resolve the query? 
--4.3. Find the IO cost (in consistent gets) for executing that statement. 
select a.STATISTIC#,b.NAME,a.VALUE from v$sesstat a join v$statname b on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid') and name = 'consistent gets'
;
--A 617 consistent gets
--B 617 consistent gets
--C 5040 consistent gets
--D 277 consistent gets


--5. Retrieving rows from both tables based on join (indexed) 
/*5.1. Write an SQL statement (join) that retrieves the name of a mother and the years of birth for all of her children. Reuse the mother that you decided on above in exercise 1.4 */
set autotrace on;
set autotrace off;
select m.id as "Mother ID", c.firstname , c.yearborn
from mother m join child c 
on m.id=c.motherid where m.id = 2500;
--5.2. Find AND SAVE the execution plan. How does Oracle resolve the query? 
--5.3. Find the IO cost (in consistent gets) for executing that statement. 
select a.STATISTIC#,b.NAME,a.VALUE from v$sesstat a join v$statname b on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid') and name = 'consistent gets'
;
/*
A Consistent gets = 617
B Consistent gets = 7
C Consistent gets = 3
D Consistent gets = 7*/


--6. Retrieving mothers based on primary key values 
--6.1. Write an SQL statement that retrieves 10 mothers with specific primary key values,
--    with intervals of at least 100 (say: id = 1000,1100,1200 etc) 
set autotrace off;
set autotrace on;
select * from mother where id in (100,200,300,400,500,2500,3500,4000,4100,5000);
--6.2. Find AND SAVE the execution plan. How does Oracle resolve the query? 
--6.3. Find the IO cost (in consistent gets) for executing that statement
select a.STATISTIC#,b.NAME,a.VALUE from v$sesstat a join v$statname b on a.STATISTIC# = b.STATISTIC#
where sid =sys_context('userenv','sid') and name = 'consistent gets'
;
/*
A Consistent gets 23
B Consistent gets 12
C Consistent gets 23
D Consistent gets 23
*/


-----------------------------------
--PARTITIONED BY LIST (YEAR BORN)

--8. With the partitioned version of the child table: find a random child, born in 2012. Update
--this child to have been born in: 
select * from child where id = 21000; -- id = 21000

UPDATE child
SET yearBorn = 2013
WHERE id = 21000;

UPDATE child
SET yearBorn = 1966
WHERE id = 21000;












-------------------
---RANDOM code
select iot_name,cluster_name  from dba_tables where table_name='MOTHER';
describe dba_tables;


describe dba_tables
select tablespace_name from dba_tables where table_name ='CHILD' and owner = 'AAD';
