select count(*)
from t2;

explain
select *
from t1
where a >= 100
  and a <= 200;

-- MySQL 8.0 Extra: Using index condition; 无MRR；set optimizer_switch='mrr_cost_based=off'后，显示了Using MRR


explain
select *
from t1 straight_join t2 on (t1.a = t2.a);
-- 执行set optimizer_switch='mrr=on,mrr_cost_based=off,batched_key_access=on';
-- Using join buffer (Batched Key Access)

select @@optimizer_switch;

set optimizer_switch =
        'index_merge=on,index_merge_union=on,index_merge_sort_union=on,index_merge_intersection=on,engine_condition_pushdown=on,index_condition_pushdown=on,mrr=on,mrr_cost_based=on,block_nested_loop=on,batched_key_access=off,materialization=on,semijoin=on,loosescan=on,firstmatch=on,duplicateweedout=on,subquery_materialization_cost_based=on,use_index_extensions=on,condition_fanout_filter=on,derived_merge=on,use_invisible_indexes=off,skip_scan=on,hash_join=on,subquery_to_derived=off,prefer_ordering_index=on,hypergraph_optimizer=off,derived_condition_pushdown=on';



set optimizer_switch = 'mrr=on,mrr_cost_based=on,batched_key_access=off';

set optimizer_switch = 'hash_join=off';


explain
select *
from t1
         join t2 on (t1.b = t2.b)
where t2.b >= 1
  and t2.b <= 2000;
show databases;

use sakila;

explain
select *
from film
where exists(
              select * from film_actor where actor_id = 1 and film_actor.film_id = film.film_id
          );


explain
select *
from film
         inner join film_actor using (film_id)
where actor_id = 1;

select film_id, language_id
from film
where not exists(
        select * from film_actor where film.film_id = film_actor.film_id
    );

select film.film_id, film.language_id
from film
         left outer join film_actor using (film_id)
where film_actor.film_id is null;

explain
select distinct `sakila`.`film`.`film_id` AS `film_id`
from `sakila`.`film`
         join `sakila`.`film_actor`
where (`sakila`.`film_actor`.`film_id` = `sakila`.`film`.`film_id`)
;

explain
select `semi`.`film_id` AS `film_id`
from `sakila`.`film` `semi`
         join `sakila`.`film_actor`
where (`sakila`.`film_actor`.`film_id` = `semi`.`film_id`)
;


explain
    (select first_name, last_name from actor order by last_name)
    union all
    (select first_name, last_name from customer order by last_name)
    limit 20;

explain
    (select first_name, last_name from actor order by last_name limit 20)
    union all
    (select first_name, last_name from customer order by last_name limit 20)
    limit 20;


-- 关联更新

explain
update employees.employees
set hire_date = '2012-09-01'
where employees.emp_no in (
    select emp_no from employees.departments where departments.dept_no = 'd001'
);

-- 8.0已优化6.5.1关联子查询中提到的in查询会被转成相关子查询的情况
explain
select *
from film
where film_id in (
    select film_id
    from film_actor
    where actor_id = 1
);
-- 8.0中两个查询执行计划是等价的
explain
select *
from film
         inner join film_actor using (film_id)
where actor_id = 1;

explain
select *
from film
where exists(
              select * from film_actor where actor_id = 1 and film_actor.film_id = film.film_id
          );

-- Using index for group-by 类似于松散索引扫描
explain
select actor_id, max(film_id)
from film_actor
group by actor_id;

explain
select (select count(*) from film_actor) - count(*)
from film_actor
where actor_id <= 5;

explain
select actor.first_name, actor.last_name, count(*)
from film_actor
         inner join actor using (actor_id)
group by actor.first_name, actor.last_name;
-- 1	SIMPLE	actor		ALL	PRIMARY				200	100	Using temporary
-- 1	SIMPLE	film_actor		ref	PRIMARY	PRIMARY	2	sakila.actor.actor_id	27	100	Using index

-- 6.7.4 优化group by和distinct
explain
select actor.first_name, actor.last_name, count(*)
from film_actor
         inner join actor using (actor_id)
group by actor.actor_id;
-- 这个效率最高
-- 1	SIMPLE	actor		index	PRIMARY,idx_actor_last_name	PRIMARY	2		200	100
-- 1	SIMPLE	film_actor		ref	PRIMARY	PRIMARY	2	sakila.actor.actor_id	27	100	Using index

explain
select actor.first_name, actor.last_name, count(*)
from film_actor
         inner join actor using (actor_id)
group by film_actor.actor_id;
-- 1	SIMPLE	actor		ALL	PRIMARY				200	100	Using temporary
-- 1	SIMPLE	film_actor		ref	PRIMARY,idx_fk_film_id	PRIMARY	2	sakila.actor.actor_id	27	100	Using index
select film_id, description
from film
         inner join(select film_id from film order by title limit 500,50) as lim using (film_id);


select film_id, description
from film
order by title
limit 500,50;


explain
select actor_id, last_name
from actor
where last_name = 'HOPPER';
explain
select actor_id
from actor
order by actor_id;

start transaction;

select actor_id
from actor
where actor_id < 5
  AND actor_id <> 1 for
update;

commit ;

use demo;

use sakila;


select actor_id
from actor
where actor_id = 1 for
update;

update actor set actor_id =1 where actor_id=1;