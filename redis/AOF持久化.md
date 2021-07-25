# AOF持久化

AOF持久化是通过保存Redis服务器所执行的写命令来记录数据库状态的。

## AOF持久化的实现

### 命令追加 append

当AOF持久化功能处于打开状态时，服务器在执行完一个写命令后，会以协议格式将被执行的写命令追加到服务器状态的aof_buf缓冲区的末尾。

### 文件写入和同步

Redis的服务器进程就是一个事件循环，这个循环中的文件事件负责接收客户端的命令请求，以及向客户端发送命令回复，而时间事件则负责执行像servercron函数这样需要定时运行的函数。

flushAppendOnlyFile函数实现AOF文件写入，其行为由服务器配置的appendfsync选项的值来决定

[appendfsync选项](https://redislabs.com/ebook/part-2-core-concepts/chapter-4-keeping-data-safe-and-ensuring-performance/4-1-persistence-options/4-1-2-append-only-file-persistence/) 与MySQLinnodb_flush_log_at_trx_commit类似

- always
  - 将aof_buf中的所有内容写入并同步到AOF文件
- everysec 默认值
  - 将aof_buf中的所有内容写入AOF文件，如果上次同步AOF文件的时间距离现在超过一秒，则对AOF文件进行同步
- no
  - 将aof_buf中的所有内容写入AOF文件，但不进行同步，何时同步由操作系统决定

flushAppendOnlyFile 刷盘

- 问题： 为什么在aof_buf为空的时候还要检查是否需要fsync?

## AOF文件的载入与数据还原

1. 创建一个不带网络连接的伪客户端
2. 从AOF文件中分析并读取出一条写命令
3. 使用伪客户端执行被读出的写命令
4. 一直执行步骤2、3,直到AOF文件中的所有命令被处理完毕为止。

## AOF重写

- 问题： AOF文件体积膨胀
- 解决： AOF文件重写。创建一个新的AOF文件代替现有文件，它们保存的数据库状态相同，但新AOF文件没有冗余命令。

### AOF文件重写的实现

从数据库中读取键现在的值，然后用一条命令去记录键值对，代替之前记录这个键值对的多条命令。

### AOF后台重写

- 目的
  - 子进程进行AOF重写期间，服务器进程可以继续处理命令请求
  - 子进程带有服务器进程的数据副本，使用子进程而不是线程，可以避免使用锁的情况下保证数据的安全性
- 问题
  - 子进程在进行AOF重写期间，服务器进程还在处理命令请求，新的命令可能对现有数据库状态进行修改，导致服务器当前的数据库状态与重写后的AOF文件不一致
- 解决
  增加AOF重写缓冲区，在服务器创建子进程后开始使用。当子进程完成AOF重写后，向父进程发送一个信号，父进程接到信号后，调用信号处理函数，执行以下工作
  - 将AOF重写缓冲区的内容写入新AOF文件中
  - 对新的AOF文件改名，原子覆盖现有AOF文件，完成新旧AOF文件的替换