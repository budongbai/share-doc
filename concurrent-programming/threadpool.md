# ThreadPool 线程池

好处：

1. 降低资源能耗。通过重复利用已创建的线程降低线程创建和销毁造成的消耗
2. 提高响应速度。当任务到达时，任务可以不需要等到线程创建就能立即执行。
3. 提高线程的可管理性。线程是稀缺资源，如果无限制地创建，不仅会消耗系统资源，还会降低系统地稳定性，使用线程池可以进行统一分配、调优和监控。

## 线程池的实现原理

* corePoolSize
* runnableTaskQueue
* maximumPoolSize
* RejectedExecutionHandler

## 源码解析

### ctl含义

ctl是一个原子整型数，其低29位表示线程的数量，高3位表示运行状态

```java
    private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
    // 线程数量的位数
    private static final int COUNT_BITS = Integer.SIZE - 3;
    // 线程数量的最大值 2^29 - 1
    private static final int CAPACITY   = (1 << COUNT_BITS) - 1;

    // runState is stored in the high-order bits
    private static final int RUNNING    = -1 << COUNT_BITS;
    private static final int SHUTDOWN   =  0 << COUNT_BITS;
    private static final int STOP       =  1 << COUNT_BITS;
    private static final int TIDYING    =  2 << COUNT_BITS;
    private static final int TERMINATED =  3 << COUNT_BITS;

    // Packing and unpacking ctl
    // 运行状态，线程数量最大值取反后，再和c与操作
    private static int runStateOf(int c)     { return c & ~CAPACITY; }
    // 线程数量
    private static int workerCountOf(int c)  { return c & CAPACITY; }
    private static int ctlOf(int rs, int wc) { return rs | wc; }

    /*
     * Bit field accessors that don't require unpacking ctl.
     * These depend on the bit layout and on workerCount being never negative.
     */

    private static boolean runStateLessThan(int c, int s) {
        return c < s;
    }

    private static boolean runStateAtLeast(int c, int s) {
        return c >= s;
    }

    private static boolean isRunning(int c) {
        return c < SHUTDOWN;
    }
```

```java
    /**
     * Executes the given task sometime in the future.  The task
     * may execute in a new thread or in an existing pooled thread.
     *
     * If the task cannot be submitted for execution, either because this
     * executor has been shutdown or because its capacity has been reached,
     * the task is handled by the current {@code RejectedExecutionHandler}.
     *
     * @param command the task to execute
     * @throws RejectedExecutionException at discretion of
     *         {@code RejectedExecutionHandler}, if the task
     *         cannot be accepted for execution
     * @throws NullPointerException if {@code command} is null
     */
    public void execute(Runnable command) {
        if (command == null)
            throw new NullPointerException();
        /*
         * Proceed in 3 steps:
         *
         * 1. If fewer than corePoolSize threads are running, try to
         * start a new thread with the given command as its first
         * task.  The call to addWorker atomically checks runState and
         * workerCount, and so prevents false alarms that would add
         * threads when it shouldn't, by returning false.
         *
         * 2. If a task can be successfully queued, then we still need
         * to double-check whether we should have added a thread
         * (because existing ones died since last checking) or that
         * the pool shut down since entry into this method. So we
         * recheck state and if necessary roll back the enqueuing if
         * stopped, or start a new thread if there are none.
         *
         * 3. If we cannot queue task, then we try to add a new
         * thread.  If it fails, we know we are shut down or saturated
         * and so reject the task.
         */
        int c = ctl.get();
        // 当前运行线程数小于核心池数量
        if (workerCountOf(c) < corePoolSize) {
            // 创建一个新的线程，返回，addWorker(runable, core)是否核心池
            if (addWorker(command, true))
                return;
            // 创建失败，采用获取当前状态
            c = ctl.get();
        }
        // 线程池在运行中，且可以加入到阻塞队列里
        if (isRunning(c) && workQueue.offer(command)) {
            int recheck = ctl.get();
            // 如果当前线程池不在运行中，且移除任务成功，则执行拒绝策略
            if (! isRunning(recheck) && remove(command))
                reject(command);
            // 如果当前运行线程数为0，则创建一个新的线程
            else if (workerCountOf(recheck) == 0)
                addWorker(null, false);
        }
        // 如果加入到线程池中也失败了，就执行拒绝策略
        else if (!addWorker(command, false))
            reject(command);
    }
```

```java
    private boolean addWorker(Runnable firstTask, boolean core) {
        retry:
        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // Check if queue empty only if necessary.
            /*如果线程处于非运行状态，并且 rs 不等于 SHUTDOWN （因为第一个条件说明了当前状态处于SHUTDOWN、STOP等状态，所有这里不等于SHUTDOWN只能是STOP以上状态）且 firstTask 不等于空且
            workQueue 为空，直接返回 false（表示不可添加 work 状态）
            1. 线程池已经 shutdown 后，还要添加新的任务，拒绝
            2. （第二个判断）SHUTDOWN 状态不接受新任务，但仍然会执行已经加入任务队列的任
            务，所以当进入 SHUTDOWN 状态，而传进来的任务为空，并且任务队列不为空的时候，是允许添加
            新线程的,如果把这个条件取反，就表示不允许添加 worker*/
            if (rs >= SHUTDOWN &&
                ! (rs == SHUTDOWN &&
                   firstTask == null &&
                   ! workQueue.isEmpty()))
                return false;

            // 死循环开始啦
            for (;;) {
                int wc = workerCountOf(c);
                // 当前线程数大于等于线程最大容量，
                // 或者如果当前是添加到核心线程池，判断是否大于等于核心线程池大小
                // 如果是添加到线程池，判断是否大于等于maximumPoolSize
                // 已经满了的情况，返回false
                if (wc >= CAPACITY ||
                    wc >= (core ? corePoolSize : maximumPoolSize))
                    return false;
                // CAS更新当前线程数，跳出retry块，执行下面的创建线程过程
                if (compareAndIncrementWorkerCount(c))
                    break retry;
                c = ctl.get();  // Re-read ctl
                // 如果线程池当前运行状态和初始时不一样了，重试
                if (runStateOf(c) != rs)
                    continue retry;
                // else CAS failed due to workerCount change; retry inner loop
            }
        }

        // 开始正式创建工作线程
        boolean workerStarted = false;
        boolean workerAdded = false;
        Worker w = null;
        try {
            w = new Worker(firstTask);
            final Thread t = w.thread;
            if (t != null) {
                final ReentrantLock mainLock = this.mainLock;
                mainLock.lock();
                try {
                    // Recheck while holding lock.
                    // Back out on ThreadFactory failure or if
                    // shut down before lock acquired.
                    int rs = runStateOf(ctl.get());

                    // 当 线程池当前状态为运行状态 或者 线程池当前状态为关闭状态且firstTask为空
                    // 才加入到工作线程池中
                    if (rs < SHUTDOWN ||
                        (rs == SHUTDOWN && firstTask == null)) {
                        if (t.isAlive()) // precheck that t is startable
                            throw new IllegalThreadStateException();
                        workers.add(w);
                        int s = workers.size();
                        // 线程池的一些统计信息
                        if (s > largestPoolSize)
                            largestPoolSize = s;
                        workerAdded = true;
                    }
                } finally {
                    mainLock.unlock();
                }
                // 添加成功，启动线程
                if (workerAdded) {
                    t.start();
                    workerStarted = true;
                }
            }
        } finally {
            if (! workerStarted)
                addWorkerFailed(w);
        }
        return workerStarted;
    }
```

```java
    final void runWorker(Worker w) {
        Thread wt = Thread.currentThread();
        Runnable task = w.firstTask;
        w.firstTask = null;
        w.unlock(); // allow interrupts
        boolean completedAbruptly = true;
        try {
            while (task != null || (task = getTask()) != null) {
                w.lock();
                // If pool is stopping, ensure thread is interrupted;
                // if not, ensure thread is not interrupted.  This
                // requires a recheck in second case to deal with
                // shutdownNow race while clearing interrupt
                // 如果线程池正在关闭，确保线程被中断
                // 如果没有，确保线程没有中断。
                if ((runStateAtLeast(ctl.get(), STOP) ||
                     (Thread.interrupted() &&
                      runStateAtLeast(ctl.get(), STOP))) &&
                    !wt.isInterrupted())
                    wt.interrupt();
                try {
                    // 可以自定义扩展，默认空实现
                    beforeExecute(wt, task);
                    Throwable thrown = null;
                    try {
                        // 这里才是真正的执行了任务
                        task.run();
                    } catch (RuntimeException x) {
                        thrown = x; throw x;
                    } catch (Error x) {
                        thrown = x; throw x;
                    } catch (Throwable x) {
                        thrown = x; throw new Error(x);
                    } finally {
                        // 可以自定义扩展，默认空实现
                        afterExecute(task, thrown);
                    }
                } finally {
                    //置空任务(这样下次循环开始时,task 依然为 null,需要再通过 getTask()取) + 记录该 Worker 完成任务数量 + 解锁
                    task = null;
                    // 线程池统计信息
                    w.completedTasks++;
                    w.unlock();
                }
            }
            completedAbruptly = false;
        } finally {
            //1.将入参 worker 从数组 workers 里删除掉；
            //2.根据布尔值 allowCoreThreadTimeOut 来决定是否补充新的 Worker 进数组workers
            processWorkerExit(w, completedAbruptly);
        }
    }
```

```java
    /**
     * Performs blocking or timed wait for a task, depending on
     * current configuration settings, or returns null if this worker
     * must exit because of any of:
     * 1. There are more than maximumPoolSize workers (due to
     *    a call to setMaximumPoolSize).
     * 2. The pool is stopped.
     * 3. The pool is shutdown and the queue is empty.
     * 4. This worker timed out waiting for a task, and timed-out
     *    workers are subject to termination (that is,
     *    {@code allowCoreThreadTimeOut || workerCount > corePoolSize})
     *    both before and after the timed wait, and if the queue is
     *    non-empty, this worker is not the last thread in the pool.
     *
     * @return task, or null if the worker must exit, in which case
     *         workerCount is decremented
     */
    private Runnable getTask() {
        boolean timedOut = false; // Did the last poll() time out?

        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // Check if queue empty only if necessary.
            /* 对线程池状态的判断，两种情况会 workerCount-1，并且返回 null
            1. 线程池状态为 shutdown，且 workQueue 为空（反映了 shutdown 状态的线程池还是要执行 workQueue 中剩余的任务的）
            2. 线程池状态为 stop（shutdownNow()会导致变成 STOP）（此时不用考虑 workQueue的情况）*/
            if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
                decrementWorkerCount();
                return null;
            }

            int wc = workerCountOf(c);

            // timed 变量用于判断是否需要进行超时控制。
            // allowCoreThreadTimeOut 默认是 false，也就是核心线程不允许进行超时；
            // wc > corePoolSize，表示当前线程池中的线程数量大于核心线程数量；
            // 对于超过核心线程数量的这些线程，需要进行超时控制
            // Are workers subject to culling?
            // workers会被淘汰嘛？
            boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

            /*1. 线程数量超过 maximumPoolSize 可能是线程池在运行时被调用了 setMaximumPoolSize()
            被改变了大小，否则已经 addWorker()成功不会超过 maximumPoolSize
            2. timed && timedOut 如果为 true，表示当前操作需要进行超时控制，并且上次从阻塞队列中
            获取任务发生了超时.其实就是体现了空闲线程的存活时间*/
            if ((wc > maximumPoolSize || (timed && timedOut))
                && (wc > 1 || workQueue.isEmpty())) {
                if (compareAndDecrementWorkerCount(c))
                    return null;
                continue;
            }

            try {
                /*根据 timed 来判断，如果为 true，则通过阻塞队列 poll 方法进行超时控制，如果在
                keepaliveTime 时间内没有获取到任务，则返回 null.
                否则通过 take 方法阻塞式获取队列中的任务*/
                Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
                if (r != null)
                    return r;
                timedOut = true;
            } catch (InterruptedException retry) {
                timedOut = false;
            }
        }
    }
```

### shutdown

```java
    /**
     * Initiates an orderly shutdown in which previously submitted
     * tasks are executed, but no new tasks will be accepted.
     * Invocation has no additional effect if already shut down.
     *
     * <p>This method does not wait for previously submitted tasks to
     * complete execution.  Use {@link #awaitTermination awaitTermination}
     * to do that.
     *
     * @throws SecurityException {@inheritDoc}
     */
    // 启动一个有序的关闭，在此关闭中执行先前提交的任务，但不接受新的任务，如果已经关闭，再调用也没有额外的效果。
    // 此方法不等待以前提交的任务完成执行
    public void shutdown() {
        final ReentrantLock mainLock = this.mainLock;
        mainLock.lock();
        try {
            checkShutdownAccess();
            // 设置运行状态为SHUTDOWN
            advanceRunState(SHUTDOWN);
            // 中断没有正在执行任务的worker
            interruptIdleWorkers();
            onShutdown(); // hook for ScheduledThreadPoolExecutor
        } finally {
            mainLock.unlock();
        }
        tryTerminate();
    }


    /**
     * Attempts to stop all actively executing tasks, halts the
     * processing of waiting tasks, and returns a list of the tasks
     * that were awaiting execution. These tasks are drained (removed)
     * from the task queue upon return from this method.
     *
     * <p>This method does not wait for actively executing tasks to
     * terminate.  Use {@link #awaitTermination awaitTermination} to
     * do that.
     *
     * <p>There are no guarantees beyond best-effort attempts to stop
     * processing actively executing tasks.  This implementation
     * cancels tasks via {@link Thread#interrupt}, so any task that
     * fails to respond to interrupts may never terminate.
     *
     * @throws SecurityException {@inheritDoc}
     */
    // 尝试停止所有正在积极执行的任务，听着等待任务的处理，并返回一个正在等待执行的任务列表，从此方法返回时，这些任务将被任务队列中删除。
    // 此方法不等的主动执行的任务终止，
    // 除了尽最大努力停止积极执行任务的处理外，不做任何保证
    public List<Runnable> shutdownNow() {
        List<Runnable> tasks;
        final ReentrantLock mainLock = this.mainLock;
        mainLock.lock();
        try {
            checkShutdownAccess();
            advanceRunState(STOP);
            interruptWorkers();
            tasks = drainQueue();
        } finally {
            mainLock.unlock();
        }
        tryTerminate();
        return tasks;
    }
```

## 参考文献

* Java并发编程的艺术，第9章

