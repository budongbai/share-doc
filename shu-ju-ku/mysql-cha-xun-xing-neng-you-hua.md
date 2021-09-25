# 慢查询基础：优化数据访问

1. 是否向数据库请求了不需要的数据

    1.1 查询不需要的记录

    1.2 多表关联时返回全部列

    1.3 总是取出全部列

    1.4 重复查询相同的数据

2. MySQL是否在扫描额外的记录

    2.1 响应时间

    2.2 扫描的行数和返回的行数

    2.3 扫描的行数和访问类型（explain使用）

MySQL应用where条件（性能由好至坏）

1. 在索引中使用where条件过滤不符合条件的记录。（存储引擎）
2. 使用索引覆盖扫描（在Extra列中出现了Using index）来返回记录，直接从索引中过滤不需要的记录并返回命中的结果。（MySQL服务器层）？为什么这个是服务器层
3. 从数据表中返回数据，然后过滤不满足条件的记录（Extra using where）。（MySQL服务器层）

重构查询的方式

1. 一个复杂查询还是多个简单查询
2. 切分查询：将大查询切分成小查询。
3. 分解关联查询

    3.1 缓存效率更高

    3.2 执行单个查询锁竞争减少

    3.3 应用层做关联，更易对数据库拆分

    3.4 查询本身效率可能提升

    3.5 减少冗余记录的查询

查询优化处理：解析SQL、预处理、优化SQL执行计划 语法解析器和预处理 查询优化器

* MysSQL可处理的优化类型：
  * 重新定义表的关联顺序。关联时并不一定按查询语句中指定的顺序。
  * 将外连接转换为内连接
  * 使用等价变换规则
  * 优化COUNT\(\)、MIN\(\)、MAX\(\)
  * 预估并转化为常数表达式
  * 覆盖索引扫描
  * 子查询优化
  * 提前终止查询
  * 等值传播
  * 列表IN\(\)的比较

MySQL关联查询优化

MySQL 5.6 Block Nested Loop Join MySQL 8.0 hash join

-- 8.0已优化6.5.1关联子查询中提到的in查询会被转成相关子查询的情况 explain select \* from film where film\_id in \( select film\_id from film\_actor where actor\_id = 1 \); -- 8.0中两个查询执行计划是等价的

```sql
explain
select *
from film
         inner join film_actor using (film_id)
where actor_id = 1;
```

对于子查询，应该用测试来验证其执行情况和响应时间的假设

count优化：select count\(_\) from world.city where id&gt;5; =&gt; select \(select count\(_\) from world.city\) - count\(\*\) from world.city where id &lt;=5; 优化关联查询 1、确保on或者using子句中的列上有索引。在创建索引的时候就要考虑关联的顺序 2、确保任何的group by和order by中的表达式只涉及到一个表中的列，这样MySQl才有可能使用索引来优化这个过程 3、升级MySQL时也需要注意：关联语法、运算符优先级等其他可能会发生变化的地方。

group by原理：使用临时表或文件排序来做分组

6.7.5 优化limit分页，延迟关联 select film\_id, description from film order by title limit 50, 5; select film\_id, description from film inner join\( select film\_id from film order by title limit 50,5\) as lim using\(film\_id\);

让MySQL扫描尽可能少的页面，获取需要访问的记录后再根据关联列回原表查询需要的所有列。

队列表提示：

1. 尽量少做事，可以的话就不要做任何事情。除非不得已，否则不使用轮询，因为会曾负载，而且还会带来很多低产出的工作
2. 尽可能快地完成需要做的事情。使用update代替先select for update再update的写法。将处理完成和未处理的数据分开，保证数据集足够小。
3. 使用缓存redis、memcached管理队列

