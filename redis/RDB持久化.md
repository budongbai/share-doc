# RDB持久化

数据库状态 -rdbSave-> RDB文件
RDB文件 -rdbLoad-> 数据库状态

## RDB文件的创建与载入

### 创建

用于生成RDB文件的命令，实现rdb.c/rdbSave

- SAVE
  - 会阻塞Redis服务器进程，直到RDB文件创建完毕为止，在服务器进程阻塞期间，服务器不能处理任何命令请求。
  - 服务器状态：阻塞，直到RDB文件创建完毕
- BGSAVE
  - 派生出一个子进程，由子进程负责创建RDB文件，服务器进程继续处理命令请求
  - BGSAVE执行期间
    - 客户端发送的SAVE命令会被服务器拒绝
    - 客户端发送的BGSAVE命令也会被服务器拒绝
    - BGREWRITEAOF和BGSAVE不能同时执行
      - 如果BGSAVE在执行，BGREWRITEAOF会被延迟到BGSAVE执行完毕后执行
      - 如果BGREWRITEAOF在执行，BGSAVE会被服务器拒绝。两个子进程同时执行大量磁盘写入操作性能不好。

### 载入 rdb.c/rdbLoad

- 在服务器启动时自动执行的，所以Redis并没有专门用于载入RDB文件的命令，只有Redis服务在启动时检测到RDB文件的存在，就会自动载入RDB文件。
- 服务器状态： 阻塞，直到载入工作完成

### AOF持久化

AOF文件更新频率比RDB文件的更新频率高

- 如果服务器开启了AOF持久化功能，优先使用AOF文件来还原数据库状态
- AOF持久化功能关闭，才使用RDB

## 自动间隔性保存

save选项： 设置多个保存条件，只要其中任意一个条件被满足，服务器就会执行BGSAVE命令。

### 设置保存条件

默认条件： save 900 1 save 300 10 save 60 10000

## RDB文件结构

| REDIS | db_version | databases | EOF | check_sum |
|----|----|----|----|----|
| 5字节 | 4字节 | 零个或多个数据库 | 1字节，结束符 | 8字节，校验和 |

### databases

| SELECTDB | db_number | key_value_pairs |
|----|----|----|
|1字节|数据库号码，1字节2字节或5字节|所有键值对数据|

### key_value_pairs

|TYPE|key|value|
|----|----|----|
|1字节，根据TYPE的值决定如何读入key和value|||

|EXPIRETIME_MS|ms|TYPE|key|value|
|----|----|----|----|----|
|1字节，告知读入程序接下来要读入的是一个毫秒为单位的过期时间|8字节，UNIX时间戳|||

### value的编码

## 分析RDB文件

6.0.9版本的rdb文件格式

0000000   R   E   D   I   S   0   0   0   9 372  \t   r   e   d   i   s
0000020   -   v   e   r 005   6   .   0   .   9 372  \n   r   e   d   i
0000040   s   -   b   i   t   s 300   @ 372 005   c   t   i   m   e 302
0000060 231 304 363   _ 372  \b   u   s   e   d   -   m   e   m 302    
0000100   4  \r  \0 372  \f   a   o   f   -   p   r   e   a   m   b   l
0000120   e 300  \0 376  \0 373 001  \0  \0 003   m   s   g 005   h   e
0000140   l   l   o 377 202   L  \t 357   V 037   %  \0
0000154

- REDIS 魔数，标识rdb文件
- 0009 RDB版本号，version = 9