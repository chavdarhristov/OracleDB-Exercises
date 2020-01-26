

drop table child purge
;
drop table mother purge
;
drop sequence sqMother
;
drop sequence sqChild
;
create table mother
(
    id       number(10,0)
             not null
             constraint coPKMother
               primary key 
               using index
               
  , firstName varchar(50)
              not null
              
  , lastName  varchar(50)
              not null
              
  , gender    char(01)
              not null
              constraint coCHMotherGender
                check (gender = 'F')
                
  , dateBorn  date
              not null
              
 , hairColor   varchar2(20)
               not null
               
 , meaninglessData char(100)
                   not null
)
organization heap
;

create table child
 (
     id      number(10,0)
             not null
             constraint coPKChild
               primary key
               using index
               
  , firstName varchar(50)
              not null
              
  , lastName  varchar(50)
              not null
              
  , gender    char(01)
              not null
              constraint coCHChildGender
                check (gender in ('F','M'))
              
  , yearBorn  number(4,0)
              
  , motherId  number(10,0)
              not null
              constraint coFKChildMother
                references mother
              
  , meaninglessData char(100)
                    not null 
   ) 
   organization heap
;
create index ixChildMotherID
  on  child(motherID)
  ;

create sequence sqMother
  start with 1
  increment by 1
  noMaxValue
  cache 20
;

create sequence sqChild
  start with 1
  increment by 1
  noMaxValue
  cache 20
;
commit
;
/
declare

  noOfMothers           constant int := 5000;
  noOfChildrenPerMother constant int := 10;
  
begin

  for m in 1..noOfMothers loop
  
     insert
       into mother (id, firstname, lastname, gender, dateBorn, hairColor, meaninglessData)
       values      (  sqMother.nextval
                    , 'First name ' || to_char(sqMother.currval)
                    , 'Last Name ' || to_char(sqMother.currval)
                    , 'F' 
                    , to_date('1980-01-01 00:00:00','YYYY-MM-DD hh24:mi:ss')
                       + to_ymInterval(to_char(floor(dbms_random.value(1,30))) || '-' || to_char(floor(dbms_random.value(1,12))) )
                    ,  case mod(m,50)
                          when 0 then 'blond'
                          else        'brown'
                       end 
                    , 'x');
                
  end loop;
  
    for c in 1..noOfChildrenPerMother loop 
       for m in (select id from mother) loop
  
         insert 
         into child (id, firstname, lastname, gender, yearBorn, motherID, meaninglessdata)
         values     (sqChild.nextval, 'Child first ' || to_char(sqChild.currval) ,
                     'Child no ' || to_char(c) || 'of mother ' || to_char(m.id),
                     case mod(c,2)
                          when 0 then 'M'
                          else        'F'
                       end 
                     , extract(year from (add_months(sysdate, -12 * c))), m.id, 'y' );
    
    end loop;
  
  end loop;
  
  commit;

end;
/
-- -------------------------------------------------------
execute DBMS_STATS.GATHER_TABLE_STATS ('AAD','MOTHER');
--/
execute DBMS_STATS.GATHER_TABLE_STATS ('AAD','CHILD');
--/
-- 
-- Check that the distributions of values are
-- sort of reasonable
--
select yearBorn
     , count(*)
  from child
  group by yearBorn
  order by yearBorn
;
select gender
     , count(*)
  from child
  group by gender
  ;
  
  select count(*) from mother;
