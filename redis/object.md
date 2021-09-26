# 对象的类型和编码

## 类型 redisObject.type

* 对象的类型
  * REDIS\_STRING 字符串对象 string
  * REDIS\_LIST 列表对象 list
  * REDIS\_HASH 哈希对象 hash
  * REDIS\_SET 集合对象 set
  * REDIS\_ZSET 有序集合对象 zset
* type命令：数据库键对应的值对象的类型

## 编码和底层实现 redisObject.encoding ptr底层实现数据结构

* 对象的编码
  * OBJ\_ENCODING\_RAW SDS    raw
  * OBJ\_ENCODING\_INT long类型的整数  int
  * OBJ\_ENCODING\_HT 字典    hashtable
  * OBJ\_ENCODING\_ZIPMAP zipmap
  * OBJ\_ENCODING\_LINKEDLIST 双端链表    linkedlist
    * Redis 3.2 不再使用它，更换为OBJ\_ENCODING\_QUICKLIST
  * OBJ\_ENCODING\_ZIPLIST 压缩列表   ziplist
  * OBJ\_ENCODING\_INTSET 整数集合    intset
  * OBJ\_ENCODING\_SKIPLIST 跳跃表和字典  skiplist
  * OBJ\_ENCODING\_EMBSTR embstr编码的SDS  embstr
  * OBJ\_ENCODING\_QUICKLIST
    * 3.2版本后list底层实现
  * OBJ\_ENCODING\_STREAM
* 不同类型和编码的对象
  * REDIS\_STRING
    * 编码
      * OBJ\_ENCODING\_INT 整数值（浮点数值用下面两个编码）
      * OBJ\_ENCODING\_EMBSTR 小于等于32字节的字符串
        * embstr只读，无法修改
        * embstr优势：一次内存分配函数分配连续空间
      * OBJ\_ENCODING\_RAW 大于32字节的字符串
    * 命令
      * SET
      * GET
      * APPEND
      * INCRBYFLOAT
      * INCRBY
      * DECRBY
      * STRLEN int转成字符串，再计算长度；sdslen函数
      * SETRANGE int和embstr转成raw，再执行；将字符串特定索引上的值设置为给定的字符
      * GETRANGE int转成字符串再取；直接取指定索引上的字符
  * REDIS\_LIST
    * 编码
      * OBJ\_ENCODING\_ZIPLIST
        * 列表对象保存的所有字符串元素的长度都小于64字节 list-max-ziplist-value
        * 列表对象保存的元素数量小于512个 list-max-ziplist-entries
      * ~~OBJ\_ENCODING\_LINKEDLIST~~
      * OBJ\_ENCODING\_QUICKLIST
    * 命令
      * LPUSH ziplistPush； listAddNodeHead
      * RPUSH ziplistPush; listAddNodeTail
      * LPOP ziplistIndex（取表头） -&gt; ziplistDelete; listFirst（取表头） -&gt; listDelNode
      * RPOP ziplistIndex（取表尾） -&gt; ziplistDelete; listLast（取表尾） -&gt; listDelNode
      * LINDEX ziplistIndex; listIndex
      * LLEN ziplistLen; listLength
      * LINSERT 表头或表尾ziplistPush，其他ziplistInsert；listInsertNode
      * LREM ziplistDelete； listDelNode
      * LTRIM ziplistDeleteRange; listDelNode
      * LSET ziplistDelete -&gt; ziplistInsert; listIndex
  * REDIS\_HASH
    * 编码
      * OBJ\_ENCODING\_ZIPLIST
        * 哈希对象保存的所有键值对的键和值的字符串长度都小于64字节 hash-max-ziplist-value
        * 哈希对象保存的键值对数量小于512个 hash-max-ziplist-entries
      * OBJ\_ENCODING\_HT
    * 命令
      * HSET  ziplistPush，键入表尾，ziplistPush，值入表尾; dictAdd
      * HGET ziplistFind，找到键，ziplistNext找到旁边的值节点; dictFind找到键，dictGetVal返回值
      * HEXISTS ziplistFind 找到键，找到就时存在; dictFind找到就是存在
      * HDEL ziplistFind找到键，将键节点、旁边的值节点删除; dictDelete
      * HLEN ziplitLen/2; dictSize
      * HGETALL 遍历，ziplistGet; 遍历，dictGetKey/dictGetVal
  * REDIS\_SET
    * 编码
      * OBJ\_ENCODING\_INTSET
        * 集合对象保存的所有元素都是整数值
        * 集合对象保存的元素数量不超过512个 set-max-intset-entries
      * OBJ\_ENCODING\_HT
    * 命令
      * SADD intsetAdd; dictAdd 新元素为键，NULL为值
      * SCARD intsetLen; dictSize
      * SISMEMBER intsetFind; dictFind
      * SMEMBERS 遍历，intsetGet; 遍历，dictGetKey
      * SRANDMEMBER intsetRandom; dictGetRandomKey
      * SPOP intsetRandom -&gt; intsetRemove; dictGetRandomKey -&gt; dictDelete
      * SREM intsetRemove -&gt; dictDelete
  * REDIS\_ZSET
    * 编码
      * OBJ\_ENCODING\_ZIPLIST
        * 有序集合保存的元素数量小于128个 zset-max-ziplist-entries
        * 有序集合保存的所有元素成员的长度都小于64字节   zset-max-ziplist-value
      * OBJ\_ENCODING\_SKIPLIST
    * 命令
      * ZADD ziplistInsert; zslInsert -&gt; dictAdd
      * ZCARD ziplistLen/2 ; length
      * ZCOUNT 遍历，统计数量; 遍历，统计数量
      * ZRANGE 遍历 ; 遍历
      * ZREVRANGE 反向遍历; 反向遍历
      * ZRANK 遍历，找到给定成员后，途径节点数量即排名；同左
      * ZREVRANK 反向遍历
      * ZREM 遍历，删除所有包含给定成员的节点，及旁边的分值节点; 

        遍历，删除所有包含给定成员的跳跃表节点。并在字典中解除被删除元素的成员和分值的关联

      * ZSCORE 遍历，查找包含了给定成员的节点，取出旁边分值节点的值; 直接从字典中取出给定成员的分值
* object encoding命令： 数据库键对应的值对象的编码
* 类型检查与命令多态
  * 类型检查的实现

    客户端发送LLEN\命令 -&gt; 服务器检查键key的值对象是否列表对象；如是对键执行LLEN命令；否则返回类型错误

  * 多态命令的实现

    客户端发送LLEN\命令 -&gt; 服务器检查键key的值对象是否列表对象

    ```text
    -> 如是，对象的编码是ziplist还是linkedlist -> ziplistLen或listLength
    -> 否则返回类型错误
    ```
* 内存回收redisObject.refCount
  * 引用计数（OBJECT REFCOUNT可以查看引用计数）
  * incrRefCount: 将对象的引用计数值增一
  * decrRefCount: 将对象的引用计数值减一，当对象的引用计数值等于0时，释放对象
  * resetRefCount: 将对象的引用计数值设置为0，但并不释放对象，这个函数通常再需要重新设置对象的引用计数时使用
* 对象共享
  * 引用计数属性除了用于实现引用计数内存回收机制，还有对象共享的作用
  * 让多个键共享同一个值对象的过程
    * 将数据库键的值指针指向一个现有的值对象
    * 将被共享的值对象的引用计数增一
  * 只对包含整数值的字符串对象进行共享（即值为0-9999的字符串对象）
* 空转时间:redisObject.lru
* 对象会记录自己的最后一次被访问的时间，这个时间可以用于计算对象的空转时间

