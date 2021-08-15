# ReentrantReadWriteLock

高16位表示共享资源数量，低16位表示独占资源数量，分别提供了两个静态方法sharedCount(int)、exclusiveCount(int)来获取结果

```java
        // 释放独占资源
        protected final boolean tryRelease(int releases) {
            if (!isHeldExclusively())
                throw new IllegalMonitorStateException();
            // 释放指定数量的资源后，独占资源是否为0
            int nextc = getState() - releases;
            boolean free = exclusiveCount(nextc) == 0;
            // 为0时，重置当前独占线程为null
            if (free)
                setExclusiveOwnerThread(null);
            // 设置同步状态
            setState(nextc);
            return free;
        }

        protected final boolean tryAcquire(int acquires) {
            /*
             * Walkthrough:
             * 1. If read count nonzero or write count nonzero
             *    and owner is a different thread, fail.
             * 2. If count would saturate, fail. (This can only
             *    happen if count is already nonzero.)
             * 3. Otherwise, this thread is eligible for lock if
             *    it is either a reentrant acquire or
             *    queue policy allows it. If so, update state
             *    and set owner.
             */
            Thread current = Thread.currentThread();
            int c = getState();
            int w = exclusiveCount(c);
            if (c != 0) {
                // (Note: if c != 0 and w == 0 then shared count != 0)
                // 存在读锁，写锁与之互斥；或者不存在读锁，但当前线程不是持有独占锁的线程
                if (w == 0 || current != getExclusiveOwnerThread())
                    return false;
                // 边界校验，超过锁的最大数量
                if (w + exclusiveCount(acquires) > MAX_COUNT)
                    throw new Error("Maximum lock count exceeded");
                // Reentrant acquire
                // 写锁个数不为0时，只有持有锁的线程才能到这里来，不必CAS
                setState(c + acquires);
                return true;
            }
            // 写锁为0，检查当前是否需要阻塞写，如果不需要阻塞，进行CAS设置同步状态，成功的话，将持有线程设置为当前线程
            if (writerShouldBlock() ||
                !compareAndSetState(c, c + acquires))
                return false;
            setExclusiveOwnerThread(current);
            return true;
        }

        protected final boolean tryReleaseShared(int unused) {
            Thread current = Thread.currentThread();
            if (firstReader == current) {
                // assert firstReaderHoldCount > 0;
                if (firstReaderHoldCount == 1)
                    firstReader = null;
                else
                    firstReaderHoldCount--;
            } else {
                HoldCounter rh = cachedHoldCounter;
                if (rh == null || rh.tid != getThreadId(current))
                    rh = readHolds.get();
                int count = rh.count;
                if (count <= 1) {
                    readHolds.remove();
                    if (count <= 0)
                        throw unmatchedUnlockException();
                }
                --rh.count;
            }
            for (;;) {
                int c = getState();
                int nextc = c - SHARED_UNIT;
                if (compareAndSetState(c, nextc))
                    // Releasing the read lock has no effect on readers,
                    // but it may allow waiting writers to proceed if
                    // both read and write locks are now free.
                    return nextc == 0;
            }
        }

        protected final int tryAcquireShared(int unused) {
            /*
             * Walkthrough:
             * 1. If write lock held by another thread, fail.
             * 2. Otherwise, this thread is eligible for
             *    lock wrt state, so ask if it should block
             *    because of queue policy. If not, try
             *    to grant by CASing state and updating count.
             *    Note that step does not check for reentrant
             *    acquires, which is postponed to full version
             *    to avoid having to check hold count in
             *    the more typical non-reentrant case.
             * 3. If step 2 fails either because thread
             *    apparently not eligible or CAS fails or count
             *    saturated, chain to version with full retry loop.
             */
            // 1. 如果写锁被别的线程持有，直接失败
            // 2. 否则，该线程有资格获得锁写入状态，因此询问它是否应该因为队列策略而阻塞。 如果没有，请尝试 CAS更新状态，并更新计数。
            //     请注意，这一步不检查可重入获取，它被推迟到fullTryAcquireShared以避免在更典型的非可重入情况下检查保持计数。
            //  3. 如果第 2 步由于线程显然不符合条件或 CAS 失败或计数饱和而失败，则链接到具有完整重试循环的版本。
            Thread current = Thread.currentThread();
            int c = getState();
            // 写锁状态不为0，且持有线程不是当前线程
            if (exclusiveCount(c) != 0 &&
                getExclusiveOwnerThread() != current)
                return -1;
            int r = sharedCount(c);
            // 检查应不应该阻塞读，不阻塞的情况下，检查当前读锁的数量是否超过了最大数量，没超过，还可以分配读锁。
            // 则CAS更新同步状态（这里没有加上请求的读锁数量）
            if (!readerShouldBlock() &&
                r < MAX_COUNT &&
                compareAndSetState(c, c + SHARED_UNIT)) {
                // 读锁数量为0，说明当前线程是第一个读锁的请求线程，记录一下
                if (r == 0) {
                    firstReader = current;
                    firstReaderHoldCount = 1;
                } else if (firstReader == current) {
                    // 如果当前线程和第一个读锁请求线程是同一个，记录一下第一个线程持有读锁的数量
                    firstReaderHoldCount++;
                } else {
                    // 不是第一个读锁请求线程，从threadLocal中找到当前线程的读锁持有数量缓存
                    HoldCounter rh = cachedHoldCounter;
                    if (rh == null || rh.tid != getThreadId(current))
                        cachedHoldCounter = rh = readHolds.get();
                    else if (rh.count == 0)
                        readHolds.set(rh);
                    rh.count++;
                }
                return 1;
            }
            return fullTryAcquireShared(current);
        }

        final int fullTryAcquireShared(Thread current) {
            /*
             * This code is in part redundant with that in
             * tryAcquireShared but is simpler overall by not
             * complicating tryAcquireShared with interactions between
             * retries and lazily reading hold counts.
             */
            // 代码与tryAcquireShared有部分冗余
            HoldCounter rh = null;
            for (;;) {
                int c = getState();
                // 当前写锁不为0，且持有线程不是当前线程，返回
                if (exclusiveCount(c) != 0) {
                    if (getExclusiveOwnerThread() != current)
                        return -1;
                    // else we hold the exclusive lock; blocking here
                    // would cause deadlock.
                } else if (readerShouldBlock()) {
                    // 写锁未被占有，且阻塞队列中有其他线程在等待，如果是当前线程，直接到下面的CAS
                    // Make sure we're not acquiring read lock reentrantly
                    if (firstReader == current) {
                        // assert firstReaderHoldCount > 0;
                    } else {
                        // 
                        if (rh == null) {
                            rh = cachedHoldCounter;
                            if (rh == null || rh.tid != getThreadId(current)) {
                                rh = readHolds.get();
                                if (rh.count == 0)
                                    readHolds.remove();
                            }
                        }
                        if (rh.count == 0)
                            return -1;
                    }
                }
                if (sharedCount(c) == MAX_COUNT)
                    throw new Error("Maximum lock count exceeded");
                if (compareAndSetState(c, c + SHARED_UNIT)) {
                    if (sharedCount(c) == 0) {
                        firstReader = current;
                        firstReaderHoldCount = 1;
                    } else if (firstReader == current) {
                        firstReaderHoldCount++;
                    } else {
                        if (rh == null)
                            rh = cachedHoldCounter;
                        if (rh == null || rh.tid != getThreadId(current))
                            rh = readHolds.get();
                        else if (rh.count == 0)
                            readHolds.set(rh);
                        rh.count++;
                        cachedHoldCounter = rh; // cache for release
                    }
                    return 1;
                }
            }
        }
```