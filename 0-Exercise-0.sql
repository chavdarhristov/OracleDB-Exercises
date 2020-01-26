describe dba_tables;

CREATE TABLE mother
(
FirstName VARCHAR(20) ,
LastName VARCHAR(20) ,
gender CHAR   NOT NULL,
age int,
CHECK (gender in ('M','F')),
PRIMARY KEY(firstname,lastname)
);

CREATE TABLE child
(
FirstName VARCHAR(20) ,
LastName VARCHAR(20) ,
age int,
CHECK(age>0),
PRIMARY KEY(firstname,lastname),
FOREIGN KEY(firstname,lastname) REFERENCES mother(firstname,lastname)
)
;

-------------------------------

--Exercise 1 Setting up tables
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

--  execute immediate 'truncate table child';
--  execute immediate 'truncate table mother';
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

select count(*) from mother;
select * from mother;

----------------------------
--Exercise 2 Investigating database objects
----2. Find the names of all tables that you have created, i.e. tables in your own schema (multiple
---solutions exist)?

select table_name from dba_tables
     where OWNER = 'AAD';
     
select distinct owner
     from dba_tables
     order by 1;

select 'drop table' || table_name || 'purge;'
   from dba_tables
   where owner='AAD'
;

select * from child;
select * from mother;

describe dba_tables;

select * from dba_tables
where table_name='CHILD';



----------------


    
    SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') FROM DUAL;








