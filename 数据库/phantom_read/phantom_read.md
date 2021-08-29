# 幻读

```sql
    CREATE TABLE `t` (
      `id` int(11) NOT NULL,
      `c` int(11) DEFAULT NULL,
      `d` int(11) DEFAULT NULL,
      PRIMARY KEY (`id`),
      KEY `c` (`c`)
    ) ENGINE=InnoDB;

    insert into t values(0,0,0),(5,5,5),(10,10,10),(15,15,15),(20,20,20),(25,25,25);
```

## 1. 什么是幻读？

假设只在 id=5 这一行加行锁

![图1](./p1.png '假设只在 id=5 这一行加行锁')  

Q3 读到 id=1 这一行的现象，被称为“幻读”。  
也就是说，幻读指的是一个事务在前后两次查询同一个范围的时候，后一次查询看到了前一次查询没有看到的行。

## 2. 幻读有啥问题？

### 语义被破坏

![图2](./p2.png)

### 数据一致性问题

![图3](./p3.png)  

经过 T1 时刻，id=5 这一行变成 (5,5,100)，当然这个结果最终是在 T6 时刻正式提交的 ;  

经过 T2 时刻，id=0 这一行变成 (0,5,5);  

经过 T4 时刻，表里面多了一行 (1,5,5);其他行跟这个执行序列无关，保持不变。  

---

T2 时刻，session B 事务提交，写入了两条语句；  

T4 时刻，session C 事务提交，写入了两条语句；  

T6 时刻，session A 事务提交，写入了 update t set d=100 where d=5 这条语句。

```sql
    update t set d=5 where id=0; /*(0,0,5)*/
    update t set c=5 where id=0; /*(0,5,5)*/

    insert into t values(1,1,5); /*(1,1,5)*/
    update t set c=5 where id=1; /*(1,5,5)*/

    update t set d=100 where d=5;/*所有d=5的行，d改成100*/
```

这个数据不一致是怎么引入的？  

**因为我们最开始假设了“select * from t where d=5 for update 这条语句只给 d=5 这一行，也就是 id=5 的这一行加锁”**

## 3. 咋解决呢？

我们能想到的方式：把扫描过程中碰到的行，也都加上写锁。  

![图4](./p4.png)

所以，行锁是解决不了问题的，因为新插入的记录是记录之间的“间隙”。所以为了解决幻读问题，InnoDB引入了新的锁，也就是间隙锁（Gap Lock)。

## 4. InnoDB中的间隙锁 （ Repeatable Read ）

1. 行锁(Record Lock):单个记录上的锁
2. 间隙锁(Gap Lock):间隙锁，锁定一个范围，但不包括记录本身。
3. Next-Key Lock: 行锁+ 间隙锁，锁定一个范围，并锁定记录本身。

```sql
    create table t(a int,key idx_a(a))engine =innodb;
    insert into t values(1),(3),(5),(8),(11);
    session a:
    start transaction;
    select * from t where a = 8 for update;
```

(-∞,1)，1,(1,3)，3, (3,5)，5, (5,8)，8,(8,11)，11, (11,+∞）

```sql
    create table t(id int,name varchar(10),key idx_id(id),primary key(name))engine =innodb;
    insert into t values(1,'a'),(3,'c'),(5,'e'),(8,'g'),(11,'j');  
    session a:
    start transaction;
    delete from t where id=8;
```

(5e, 8g),8g,(8g,11j)

```sql
    create table t(a int primary key)engine =innodb;
    insert into t values(1),(3),(5),(8),(11);

    session a:
    start transaction;
    select * from t where a = 8 for update;
```

因为InnoDB对于行的查询都是采用了Next-Key Lock的算法，锁定的不是单个值，而是一个范围，按照这个方法是会和第一次测试结果一样。但是，当查询的索引含有唯一属性的时候，Next-Key Lock 会进行优化，将其降级为Record Lock，即仅锁住索引本身，不是范围。  

## 5. 间隙锁又会有啥问题？

场景：任意锁住一行，如果这一行不存在的话就插入，如果存在这一行就更新它的数据。
![图5](./p5.png)

间隙锁的引入，可能会导致同样的语句锁住更大的范围，也就影响了并发度。

## 6. 参考文档

1. <https://www.cnblogs.com/zhoujinyi/p/3435982.html>
2. <https://time.geekbang.org/column/article/75173>
