# Java并发机制的底层实现原理

## volitale实现原理

- Lock前缀指令会引起处理器缓存回写到内存
- 一个处理器的缓存回写到内存会导致其他处理器的缓存无效

## synchronized实现原理

### 实现的基础

Java中的每一个对象都可以作为锁

- 普通同步方法： 当前实例对象
- 静态同步方法： 当前类的Clas对象
- 同步代码块： synchronized括号里配置的对象

### monitorenter和monitorexit指令

### 对象头

源码定义在markOop.hpp文件

## 原子操作的实现原理

### 处理器的原子操作实现

- 总线锁
- 缓存锁定

### Java中的原子操作实现

