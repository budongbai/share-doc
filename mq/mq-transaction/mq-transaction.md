# RocketMQ 事务消息

## 分布式事务的实现

- 2PC（Two-phase Commit，二阶段提交）
- TCC（Try-Confirm-Cancel）
- 事务消息
  - 适用场景： 需要异步更新数据，并且对数据实时性要求不太高的场景
  - Kafka及RocketMQ提供了事务相关功能

## 消息队列是如何实现分布式事务的？

- 半消息
    在事务提交之前，对于消费者来说，这个消息不可见
  - 开启事务
  - 发送半消息
  - 执行本地事务
  - 提交或回滚
  - 投递消息

## RocketMQ中的分布式事务实现

![事务消息](./transaction.png)

利用事务反查机制解决了事务消息提交失败的问题。

1. MQ 发送方向 MQ Server 发送半消息
2. MQ Server 接收到半消息，则向 MQ 发送方返回发送成功
3. 执行本地事务
4. MQ 发送方向 MQ Server 提交或回滚半消息
5. MQ Server 未收到第4步中的确认时，回查事务状态
6. MQ 发送方检查本地事务的状态
7. 根据事务的状态提交或回滚
8. MQ Server 收到提交确认，则向 MQ 订阅方投递消息；否则删消息不进行投递

## RocketMQ 事务消息源码解读

### 如何找到相关源码

从阅读文档示例开始，事务示例相关文档详见 <https://rocketmq.apache.org/docs/transaction-example/>

### 使用限制

1. 事务消息不支持定时和批量
2. 为了避免对单个消息反查过多次，从而导致半队列消息累积，设置了默认次数15次。可通过 transactionCheckMax 参数进行调整。如果已经检查超过了这个参数配置的次数，则丢弃并打印错误日志。
3. 反查时间可以通过 transactionTimeout 参数配置
4. 事务消息可能被检查或消费多次
5. 提交的消息向用户目标主题投递时可能失败
6. 事务消息的生产者 ID 不能与其他类型消息的生产者 ID 共享。 与其他类型的消息不同，事务性消息允许向后查询。 MQ Server 通过生产者 ID 查询客户端。

### TranscationListener

这个接口主要包含两个接口，一个执行本地事务，一个检查本地事务状态

```java
// 执行本地事务
LocalTransactionState executeLocalTransaction(final Message msg, final Object arg);
// 检查本地事务状态
LocalTransactionState checkLocalTransaction(final MessageExt msg);
```

### 发送事务消息

TransactionMQProducer#sendMessageInTransaction(final Message msg, final Object arg)

- DefaultMQProducerImpl#sendMessageInTransaction
  - 获取业务实现的TranscationListener，用于后续发送半消息成功之后执行本地事务
  - 半消息有一个特殊参数PROPERTY_TRANSACTION_PREPARED为true，用于标识半消息类型
  - 发送半消息
  - 如果发送成功，则执行本地事务；否则本地事务状态更新为回滚
  - 结束事务 endTranscation
    - 根据本地事务状态确定请求头参数为提交、回滚或未知，单向发送
  - 组装事务结果返回

### 处理事务消息

SendMessageProcessor#sendMessage

- TransactionalMessageServiceImpl#prepareMessage
  - TranscationMessageBridge#putHalfMessage
    - parseHalfMessageInner: 将真实的主题及队列ID放到参数里，将主题设置为半消息主题

### 处理提交或回滚

EndTranscationProcessor#processRequest

### 检查

TranscationMessageServiceImpl#check

- 看半消息主题有没有队列
  - 没有，直接返回了
- 遍历队列
  - 拉一批消息
  - needDiscard: 判断当前检查次数是否已经超过最大检查次数，超过则丢弃该消息
  - needSkip: 半消息超过文件留存时间，跳过
  - 如果需要反查，则调用putBackHalfQueue再次写入Half topic，并异步进行反查

ClientRemotingProcessor#processRequest 会去调用发消息时实现的接口，反查本地事务状态