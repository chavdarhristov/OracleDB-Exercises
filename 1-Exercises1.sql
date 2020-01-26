/
drop table child purge;

drop table mother purge;

drop sequence sqmother;

drop sequence sqchild;
/
create table mother
(
 ID  number(10,0)
     not null
     constraint coPKMother
     primary key
     
 ,name varchar2(100)
    not null
    
 ,gender char(01)
    not null
    constraint coCHMotherGender
    check(gender in('F'))

 ,dateOfBirth date
    not null
    
 ,meaninglessData char(1000)
 )
;
create table child
(
   ID    number(10,0)
         not null
         constraint coPKChild
           primary key
           
 , motherID number(10,0)
            not null
            constraint coFKChildMother
              references mother
              
 , name     varchar(100) 
            not null
            
 , gender   char(01)
            not null
            constraint coCHChildGender
              check  (gender in ('M','F'))
              
 , dateOfBirth date
               not null
               
 , meaninglessData char(1000)
                   not null
)
;

--------------------
--inserting data into the tables

create sequence sqMother
  start with 1
  increment by 1
  noMaxValue
  cache 100
  ;

create sequence sqChild
  start with 1
  increment by 1
  noMaxValue
  cache 100
;
/
declare
 
  noOfMothers  constant int := 1000;
  noChildrenPerMother constant int := 5;
  
begin

execute immediate 'truncate table child';
execute immediate 'truncate table mother';
  for m in 1..noOfMothers loop
  
     insert into mother (id,name,gender,dateOfBirth,meaninglessData)
     values (    sqMother.nextval
              , 'Mother ' || to_char(sqMother.currval)
              , 'F'
              , sysdate
              , 'x'
              );
  
     for c in 1..noChildrenPerMother loop
       insert into child (id, motherID, name, gender, dateOfBirth, meaninglessData)
        values (
                   sqChild.nextval
                ,  sqMother.currval
                ,  'Child number ' || to_char(c) || ' of mother ' || to_char(sqMother.currval)
                ,  'F'
                ,  sysdate
                , 'x'
               );
     end loop;
    
  end loop;
  commit;
end;
/

------------------------------------------
--DML-------------
------------------------------------------


select count(*) from mother;
select count(*) from child;
---------------------
--Investigating database objects

--2
--All tables with aad as owner
select table_name from dba_tables
  where owner = 'BBC';

--3. Which tablespace are the tables stored in?

select owner,table_name,tablespace_name
  from dba_tables where owner = 'BBC';
  
  
--4. Which constraints are declared on your CHILD table? What type are they? (you may need
--to check the REFERENCE manual to figure that out)


