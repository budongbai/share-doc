# Java内存模型

JMM 的主要目的是定义程序中各种变量的访问规则，即关注在虚拟机中把变量值存储到内存和从内存中取出变量值这样的底层细节。

主内存： 静态字段、实例字段、构成数组对象的元素 线程私有： 局部变量和方法参数 工作内存：抽象概念，保存被该线程使用的变量的主内存副本（可能只是存了一下引用）

## Q & A

Q: 线程之间如何通信？

A: 共享内存、消息传递

Q: 线程之间如何同步？

A: 共享内存：程序员必须显式地指定某个方法或某段代码需要在线程之间互斥执行。

消息传递： 由于消息地发送必须在接收之前，因此同步是隐式执行的。

### Java内存模型的抽象结构

Java线程之间的通信由Java内存模型控制，JMM决定一个线程对共享变量的写入何时对另一个线程可见。

本地内存【抽象概念】

### 重排序类型

* 编译器优化的重排序
* 指令级并行的重排序
* 内存系统的重排序

### 内存屏障类型

* LoadLoad
* StoreStore
* LoadStore
* StoreLoad

### happens-before 原则

仅要求前一个操作的执行结果对后一个操作可见

* 程序次序规则: 控制流顺序
* 管程锁定规则：unlock -&gt; lock
* volatile变量规则
* 线程启动规则
* 线程终止规则
* 线程中断规则
* 对象终结规则
* 传递性

## 重排序

### 数据依赖性

### as-if-serial语义

### 程序顺序规则

## 顺序一致性模型与JMM模型的差异

* 顺序一致性模型保证单线程内的操作按程序的顺序执行，而JMM不保证
* 顺序一致性模型保证所有线程只能看到一致的操作执行顺序，而JMM不保证
* JMM不保证对64位的long型和double型变量的写操作具有原子性，而顺序一致性模型保证对所有的内存读、写操作具有原子性

## volatile的内存语义

### 特性

* 可见性: 对一个volatile变量的读，总是能看到对这个volatile变量最后的写入
* 原子性：对任意单个volatile变量的读、写具有原子性，但是类似于volatile++这种复合操作不具有原子性
* 禁止指令重排序

### volatile 写-读建立的 happens-before 关系

### volatile 写-读的内存语义

写语义： 当写一个volatile变量时，JMM会把该线程对应的本地内存中的共享变量值刷新到主内存。

读语义： 当读一个volatile变量时，JMM会把该线程对应的本地内存置为无效。线程接下来从主内存中读取共享变量。

### volatile 内存语义的实现

规则：

1. 当第二个操作是volatile写时，不管第一个操作是什么，都不能重排序。
2. 当第一个操作是volatile读时，不管第二个操作是什么，都不能重排序。
3. 当第一个操作是volatile写，第二个操作是volatile读时，不能重排序。

实现：

1. 在每个volatile写操作的前面插入一个StoreStore屏障
2. 在每个volatile写操作的后面插入一个StoreLoad屏障
3. 在每个volatile读操作的后面插入一个LoadLoad屏障
4. 在每个volatile读操作的后面插入一个LoadStore屏障

volatile语义的增强：严格限制编译器和处理器对volatile变量与普通变量的重排序，确保volatile写-读和锁的释放-获取具有相同的内存语义

## 锁的内存语义

### 锁的释放-获取建立的happens-before关系

锁的释放语义： 当线程释放锁时，JMM会把该线程对应的本地内存中的共享变量刷新到主内存中。 锁的获取语义： 当线程获取锁时，JMM会把该线程对应的本地内存置为无效，从而使得被监视器保护的临界区代码必须从主内存中读取共享变量。

## final域的内存语义

### final域的重排序规则

1. 在构造函数内对一个final域的写入，与随后把这个被构造对象的引用复制给一个引用变量，这两个操作之间不能重排序。
2. 初次读一个包含final域的对象的引用，与随后初次读这个final域，这两个操作之间不能重排序。

实现：

写实现：

1. JMM禁止编译器把final域的写重排序到构造函数之外。
2. 编译器会在final域写入之后，构造函数return之前，插入一个StoreStore屏障。

读实现：

在读final域操作的前面插入一个LoadLoad屏障
