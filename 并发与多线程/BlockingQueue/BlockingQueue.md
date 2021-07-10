# 阻塞队列

## 什么是阻塞队列

阻塞队列是一个支持两个附加操作的队列。这两个附加的操作支持阻塞的插入和移除方法。

1. 支持阻塞的插入方法：当队列满时，队列会阻塞插入元素的线程，直到队列未满。

2. 支持阻塞的移除方法： 当队列为空时，获取元素的线程会等待队列变为非空。

| 方法/处理方式 | 抛出异常 | 返回特殊值 | 一直阻塞 | 超时退出 |
|  ----  | ----  | ---- | ----  | ----  |
| 插入方法 | add(e) | offer(e) | put(e) | offer(e, time, unit) |
| 移除方法 | remove(e) | poll() | take() | poll(time, unit) |
| 检查方法 | element() | peek() | 不可用 | 不可用 |

## Java里的阻塞队列

- ArrayBlockingQueue:  有界阻塞队列
- LinkedBlockingQueue： 无界阻塞队列
- PriorityBlockingQueue： 无界阻塞队列
- DelayQueue： 使用优先级队列实现的无界阻塞队列
  - 应用场景：
    - 缓存系统的设计： 可以用DelayQueue保存缓存元素的有效期，使用一个线程循环查询DelayQueue，一旦能从DelayQueue中获取元素时，表示缓存有效期到了。
    - 定时任务调度： 使用DelayQueue保存当天将会执行的任务和执行时间，一旦从DelayQueue中获取到任务就开始执行，比如TimerQueue就是用DelayQueue实现的
- SynchronousQueue： 不存储元素的阻塞队列
- LinkedTransferQueue： 无界阻塞队列
- LinkedBlockingDeque： 双向阻塞队列
