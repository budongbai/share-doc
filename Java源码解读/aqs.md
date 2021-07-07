# AQS

![./aqs.webp](./aqs.webp)

## CLH

![./clh.webp](./clh.webp)

## CLH变体

![./aqs-clh.webp](./aqs-clh.webp)

Provides a framework for implementing blocking locks and related synchronizers (semaphores, events, etc) that rely on first-in-first-out (FIFO) wait queues. This class is designed to be a useful basis for most kinds of synchronizers that rely on a single atomic int value to represent state. Subclasses must define the protected methods that change this state, and which define what that state means in terms of this object being acquired or released. Given these, the other methods in this class carry out all queuing and blocking mechanics. Subclasses can maintain other state fields, but only the atomically updated int value manipulated using methods getState, setState and compareAndSetState is tracked with respect to synchronization.

提供一个框架，用于实现依赖先进先出 (FIFO) 等待队列的阻塞锁和相关同步器（信号量、事件等）。 此类旨在成为大多数依赖单个原子 int 值来表示状态的同步器的有用基础。 子类必须定义更改此状态的受保护方法，并定义该状态在获取或释放此对象方面的含义。 鉴于这些，此类中的其他方法执行所有排队和阻塞机制。 子类可以维护其他状态字段，但只有使用 getState、setState 和 compareAndSetState 方法操作的原子更新的 int 值才会被同步跟踪。

Subclasses should be defined as non-public internal helper classes that are used to implement the synchronization properties of their enclosing class. Class AbstractQueuedSynchronizer does not implement any synchronization interface. Instead it defines methods such as acquireInterruptibly that can be invoked as appropriate by concrete locks and related synchronizers to implement their public methods.

子类应定义为非公共内部帮助类，用于实现其封闭类的同步属性。 AbstractQueuedSynchronizer 类不实现任何同步接口。相反，它定义了诸如acquireInterruptively 之类的方法，这些方法可以由具体锁和相关同步器适当调用以实现它们的公共方法。

This class supports either or both a default exclusive mode and a shared mode. When acquired in exclusive mode, attempted acquires by other threads cannot succeed. Shared mode acquires by multiple threads may (but need not) succeed. This class does not "understand" these differences except in the mechanical sense that when a shared mode acquire succeeds, the next waiting thread (if one exists) must also determine whether it can acquire as well. Threads waiting in the different modes share the same FIFO queue. Usually, implementation subclasses support only one of these modes, but both can come into play for example in a ReadWriteLock. Subclasses that support only exclusive or only shared modes need not define the methods supporting the unused mode.

此类支持默认独占模式和共享模式中的一种或两种。当以独占模式获取时，其他线程尝试获取不会成功。多个线程获取的共享模式可能（但不一定）成功。这个类不“理解”这些差异，除了机械意义上的区别，当共享模式获取成功时，下一个等待线程（如果存在）也必须确定它是否也可以获取。在不同模式下等待的线程共享同一个 FIFO 队列。通常，实现子类只支持这些模式中的一种，但两种模式都可以发挥作用，例如在 ReadWriteLock 中。仅支持独占或仅共享模式的子类不需要定义支持未使用模式的方法。

This class defines a nested AbstractQueuedSynchronizer.ConditionObject class that can be used as a Condition implementation by subclasses supporting exclusive mode for which method isHeldExclusively reports whether synchronization is exclusively held with respect to the current thread, method release invoked with the current getState value fully releases this object, and acquire, given this saved state value, eventually restores this object to its previous acquired state. No AbstractQueuedSynchronizer method otherwise creates such a condition, so if this constraint cannot be met, do not use it. The behavior of AbstractQueuedSynchronizer.

该类定义了一个嵌套的 AbstractQueuedSynchronizer.ConditionObject 类，该类可以被支持独占模式的子类用作 Condition 实现，其中方法 isHeldExclusively 报告是否针对当前线程独占同步，使用当前 getState 值调用的方法 release 完全释放此对象，并获得，给定这个保存的状态值，最终将此对象恢复到其先前获得的状态。没有 AbstractQueuedSynchronizer 方法否则会创建这样的条件，因此如果无法满足此约束，请不要使用它。 AbstractQueuedSynchronizer 的行为。

ConditionObject depends of course on the semantics of its synchronizer implementation.

ConditionObject 当然取决于其同步器实现的语义。

This class provides inspection, instrumentation, and monitoring methods for the internal queue, as well as similar methods for condition objects. These can be exported as desired into classes using an AbstractQueuedSynchronizer for their synchronization mechanics.

此类为内部队列提供检查、检测和监视方法，以及为条件对象提供类似方法。这些可以根据需要使用 AbstractQueuedSynchronizer 的同步机制导出到类中。

Serialization of this class stores only the underlying atomic integer maintaining state, so deserialized objects have empty thread queues. Typical subclasses requiring serializability will define a readObject method that restores this to a known initial state upon deserialization.

此类的序列化仅存储底层原子整数维护状态，因此反序列化的对象具有空线程队列。需要可序列化的典型子类将定义一个 readObject 方法，该方法在反序列化时将其恢复到已知的初始状态。

Usage
To use this class as the basis of a synchronizer, redefine the following methods, as applicable, by inspecting and/or modifying the synchronization state using getState, setState and/or compareAndSetState:
tryAcquire
tryRelease
tryAcquireShared
tryReleaseShared
isHeldExclusively
Each of these methods by default throws UnsupportedOperationException. **Implementations of these methods must be internally thread-safe, and should in general be short and not block. Defining these methods is the only supported means of using this class. All other methods are declared final because they cannot be independently varied.**

You may also find the inherited methods from AbstractOwnableSynchronizer useful to keep track of the thread owning an exclusive synchronizer. You are encouraged to use them -- this enables monitoring and diagnostic tools to assist users in determining which threads hold locks.

您可能还会发现从 AbstractOwnableSynchronizer 继承的方法对于跟踪拥有独占同步器的线程很有用。 鼓励您使用它们——这使监视和诊断工具能够帮助用户确定哪些线程持有锁。

Even though this class is based on an internal FIFO queue, it does not automatically enforce FIFO acquisition policies. The core of exclusive synchronization takes the form:
   Acquire:
       while (!tryAcquire(arg)) {
          enqueue thread if it is not already queued;
          possibly block current thread;
       }
  
   Release:
       if (tryRelease(arg))
          unblock the first queued thread;
(Shared mode is similar but may involve cascading signals.)
Because checks in acquire are invoked before enqueuing, a newly acquiring thread may barge ahead of others that are blocked and queued. However, you can, if desired, define tryAcquire and/or tryAcquireShared to disable barging by internally invoking one or more of the inspection methods, thereby providing a fair FIFO acquisition order. In particular, most fair synchronizers can define tryAcquire to return false if hasQueuedPredecessors (a method specifically designed to be used by fair synchronizers) returns true. Other variations are possible.

因为在入队之前调用获取中的检查，所以新的获取线程可能会抢在其他被阻塞和排队的线程之前。但是，如果需要，您可以定义 tryAcquire 和/或 tryAcquireShared 以通过内部调用一种或多种检查方法来禁用插入，从而提供公平的 FIFO 获取顺序。特别是，大多数公平同步器可以定义 tryAcquire 以在 hasQueuedPredecessors（一种专门设计为公平同步器使用的方法）返回 true 时返回 false。其他变化也是可能的。

Throughput and scalability are generally highest for the default barging (also known as greedy, renouncement, and convoy-avoidance) strategy. While this is not guaranteed to be fair or starvation-free, earlier queued threads are allowed to recontend before later queued threads, and each recontention has an unbiased chance to succeed against incoming threads. Also, while acquires do not "spin" in the usual sense, they may perform multiple invocations of tryAcquire interspersed with other computations before blocking. This gives most of the benefits of spins when exclusive synchronization is only briefly held, without most of the liabilities when it isn't. If so desired, you can augment this by preceding calls to acquire methods with "fast-path" checks, possibly prechecking hasContended and/or hasQueuedThreads to only do so if the synchronizer is likely not to be contended.

默认插入（也称为贪婪、放弃和避免护送）策略的吞吐量和可扩展性通常最高。虽然这不能保证公平或无饥饿，但允许较早的排队线程在较晚的排队线程之前重新竞争，并且每次重新竞争都有机会成功对抗传入的线程。此外，虽然获取不会在通常意义上“旋转”，但它们可能会在阻塞之前执行多次调用 tryAcquire 并穿插其他计算。当仅短暂保持独占同步时，这提供了自旋的大部分好处，而在不保持时则没有大部分责任。如果需要，您可以通过使用“快速路径”检查预先调用获取方法来增强这一点，可能会预先检查 hasContended 和/或 hasQueuedThreads 以仅在同步器可能不竞争时才这样做。

This class provides an efficient and scalable basis for synchronization in part by specializing its range of use to synchronizers that can rely on int state, acquire, and release parameters, and an internal FIFO wait queue. When this does not suffice, you can build synchronizers from a lower level using atomic classes, your own custom java.util.Queue classes, and LockSupport blocking support.

此类通过将其使用范围专门用于可以依赖 int 状态、获取和释放参数以及内部 FIFO 等待队列的同步器，为同步提供了高效且可扩展的基础。如果这还不够，您可以使用原子类、您自己的自定义 java.util.Queue 类和 LockSupport 阻塞支持从较低级别构建同步器。

Usage Examples
Here is a non-reentrant mutual exclusion lock class that uses the value zero to represent the unlocked state, and one to represent the locked state. While a non-reentrant lock does not strictly require recording of the current owner thread, this class does so anyway to make usage easier to monitor. It also supports conditions and exposes one of the instrumentation methods:

```java
 class Mutex implements Lock, java.io.Serializable {

   // Our internal helper class
   private static class Sync extends AbstractQueuedSynchronizer {
     // Reports whether in locked state
     protected boolean isHeldExclusively() {
       return getState() == 1;
     }

     // Acquires the lock if state is zero
     public boolean tryAcquire(int acquires) {
       assert acquires == 1; // Otherwise unused
       if (compareAndSetState(0, 1)) {
         setExclusiveOwnerThread(Thread.currentThread());
         return true;
       }
       return false;
     }

     // Releases the lock by setting state to zero
     protected boolean tryRelease(int releases) {
       assert releases == 1; // Otherwise unused
       if (getState() == 0) throw new IllegalMonitorStateException();
       setExclusiveOwnerThread(null);
       setState(0);
       return true;
     }

     // Provides a Condition
     Condition newCondition() { return new ConditionObject(); }

     // Deserializes properly
     private void readObject(ObjectInputStream s)
         throws IOException, ClassNotFoundException {
       s.defaultReadObject();
       setState(0); // reset to unlocked state
     }
   }

   // The sync object does all the hard work. We just forward to it.
   private final Sync sync = new Sync();

   public void lock()                { sync.acquire(1); }
   public boolean tryLock()          { return sync.tryAcquire(1); }
   public void unlock()              { sync.release(1); }
   public Condition newCondition()   { return sync.newCondition(); }
   public boolean isLocked()         { return sync.isHeldExclusively(); }
   public boolean hasQueuedThreads() { return sync.hasQueuedThreads(); }
   public void lockInterruptibly() throws InterruptedException {
     sync.acquireInterruptibly(1);
   }
   public boolean tryLock(long timeout, TimeUnit unit)
       throws InterruptedException {
     return sync.tryAcquireNanos(1, unit.toNanos(timeout));
   }
 }
```

Here is a latch class that is like a CountDownLatch except that it only requires a single signal to fire. Because a latch is non-exclusive, it uses the shared acquire and release methods.

```java
 class BooleanLatch {

   private static class Sync extends AbstractQueuedSynchronizer {
     boolean isSignalled() { return getState() != 0; }

     protected int tryAcquireShared(int ignore) {
       return isSignalled() ? 1 : -1;
     }

     protected boolean tryReleaseShared(int ignore) {
       setState(1);
       return true;
     }
   }

   private final Sync sync = new Sync();
   public boolean isSignalled() { return sync.isSignalled(); }
   public void signal()         { sync.releaseShared(1); }
   public void await() throws InterruptedException {
     sync.acquireSharedInterruptibly(1);
   }
 }
```

## 源码解析

### acquire

```java
    // 以独占模式获取，忽略中断。通过至少调用一次tryAcquire来来实现。否则线程会排队，可能反复阻塞以及解除阻塞，调用tryAcquire直到成功。
    public final void acquire(int arg) {
        // 尝试获取同步状态，成功的话直接返回了
        if (!tryAcquire(arg) &&
            // 为当前线程生成一个独占模式的结点，放到队列尾部
            acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
            // 补了一次中断，因为在parkAndInterrupt中判断是否中断用了Thread.interrupted方法，这个方法在判断是否中断的时候，将中断标记清除了
            // 为啥没有用Thread.isInterrupted方法
            selfInterrupt();
    }
```

```java
    final boolean acquireQueued(final Node node, int arg) {
        boolean failed = true;
        try {
            boolean interrupted = false;
            // 死循环，检查当前节点的前驱节点是不是头结点，是的话再尝试获取同步状态
            for (;;) {
                final Node p = node.predecessor();
                if (p == head && tryAcquire(arg)) {
                    setHead(node);
                    p.next = null; // help GC
                    failed = false;
                    return interrupted;
                }
                // 检查并更新当前节点的前驱节点的同步状态。如果线程应该阻塞返回true。
                if (shouldParkAfterFailedAcquire(p, node) &&
                    // 中断
                    parkAndCheckInterrupt())
                    interrupted = true;
            }
        } finally {
            // 如果还是没有成功，取消请求
            if (failed)
                cancelAcquire(node);
        }
    }
```

```java
// 检查并更新当前节点的前驱节点的同步状态。如果线程应该阻塞返回true。
// 这个方法是整个获取循环中主要的信号控制
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
        int ws = pred.waitStatus;
        if (ws == Node.SIGNAL)
            /*
             * This node has already set status asking a release
             * to signal it, so it can safely park.
             */
             // 如果前驱节点的状态已经是-1，当前节点应该中断
            return true;
        // 前驱节点的状态>0， 根据AQS中waitStatus的定义，我们知道只有取消状态为1，其他状态都小于或等于0
        if (ws > 0) {
            /*
             * Predecessor was cancelled. Skip over predecessors and
             * indicate retry.
             */
            do {
                // 从当前节点向前找第一个不是取消的前驱节点
                // 在向前寻找的过程中，还将当前节点的前驱节点进行了重置，最终指向的前驱节点即找到的第一个不是取消状态的前驱节点
                node.prev = pred = pred.prev;
            } while (pred.waitStatus > 0);
            // 前驱节点的后继节点设为当前节点
            pred.next = node;
        } else {
            /*
             * waitStatus must be 0 or PROPAGATE.  Indicate that we
             * need a signal, but don't park yet.  Caller will need to
             * retry to make sure it cannot acquire before parking.
             */
            // 再给一次机会试一下能不能获取到同步状态
            compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
        }
        return false;
    }
```

```java
    // 取消正在进行的获取尝试
    private void cancelAcquire(Node node) {
        // Ignore if node doesn't exist
        if (node == null)
            return;

        // 清除线程信息
        node.thread = null;

        // Skip cancelled predecessors
        // 从后往前遍历，找到第一个不是取消状态的前驱节点
        Node pred = node.prev;
        while (pred.waitStatus > 0)
            node.prev = pred = pred.prev;

        // predNext is the apparent node to unsplice. CASes below will
        // fail if not, in which case, we lost race vs another cancel
        // or signal, so no further action is necessary.
        Node predNext = pred.next;

        // Can use unconditional write instead of CAS here.
        // After this atomic step, other Nodes can skip past us.
        // Before, we are free of interference from other threads.
        // 当前节点设置为取消状态
        node.waitStatus = Node.CANCELLED;

        // If we are the tail, remove ourselves.
        // 如果当前节点是尾巴，将尾结点CAS设置为刚才遍历拿到的前驱节点
        if (node == tail && compareAndSetTail(node, pred)) {
            // 再CAS设置前驱节点的后继节点
            compareAndSetNext(pred, predNext, null);
        } else {
            // If successor needs signal, try to set pred's next-link
            // so it will get one. Otherwise wake it up to propagate.
            // 当前节点不是尾巴或者CAS设置尾结点的时候失败了，说明在进行CAS操作时尾结点不是当前节点了
            int ws;
            // 如果前驱节点不是头节点
            if (pred != head &&
                // 前驱节点的状态是-1
                ((ws = pred.waitStatus) == Node.SIGNAL ||
                  // 前驱节点状态小于等于0,且CAS操作设置前驱节点的状态为-1
                 (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
                pred.thread != null) {
                // 当前节点后继节点不为空，且其后继节点状态不是取消，CAS将前驱节点的后继节点设置为当前节点的后继节点
                Node next = node.next;
                // 这里只看了当前节点的后继节点而没有继续向后遍历后继节点
                // 原因可能是因为后继节点的链接本身就可能是断掉的
                // 而且在判断节点是否需要中断的时候(shouldParkAfterFailedAcquire)也从后向前依次遍历清理掉了取消状态的节点
                if (next != null && next.waitStatus <= 0)
                    compareAndSetNext(pred, predNext, next);
            } else {
                // 唤醒当前节点的后继节点
                unparkSuccessor(node);
            }

            node.next = node; // help GC
        }
    }
```

### release

```java
    public final boolean release(int arg) {
        // 尝试释放同步状态
        if (tryRelease(arg)) {
            Node h = head;
            // 头节点不为空或者不是正在初始化
            if (h != null && h.waitStatus != 0)
                // 唤醒后继节点
                unparkSuccessor(h);
            return true;
        }
        return false;
    }
```

h == null Head还没初始化。初始情况下，head == null，第一个节点入队，Head会被初始化一个虚拟节点。所以说，这里如果还没来得及入队，就会出现head == null 的情况。

h != null && waitStatus == 0 表明后继节点对应的线程仍在运行中，不需要唤醒。

h != null && waitStatus < 0 表明后继节点可能被阻塞了，需要唤醒。

```java
// 如果当前节点有后继节点的话，唤醒后继节点
private void unparkSuccessor(Node node) {
        /*
         * If status is negative (i.e., possibly needing signal) try
         * to clear in anticipation of signalling.  It is OK if this
         * fails or if status is changed by waiting thread.
         */
        int ws = node.waitStatus;
        if (ws < 0)
            compareAndSetWaitStatus(node, ws, 0);

        /*
         * Thread to unpark is held in successor, which is normally
         * just the next node.  But if cancelled or apparently null,
         * traverse backwards from tail to find the actual
         * non-cancelled successor.
         */
        Node s = node.next;
        // 如果当前节点的后继节点为空，或者其状态为取消，则从尾节点向前遍历，找到一个状态不是取消状态的后继节点，将它唤醒
        if (s == null || s.waitStatus > 0) {
            s = null;
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)
                    s = t;
        }
        if (s != null)
            LockSupport.unpark(s.thread);
    }
```

## 参考资料

- [从ReentrantLock的实现看AQS的原理及应用](https://tech.meituan.com/2019/12/05/aqs-theory-and-apply.html)
- [1.5 w字、16 张图，轻松入门 RLock+AQS 并发编程原理](https://www.jianshu.com/p/b7ec536c9ed7)