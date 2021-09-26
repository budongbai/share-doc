# 集群

## 节点

CLUSTER MEET ip port

### 启动节点

cluster-enable配置选项值

### 集群数据结构

clusterNode结构保存了一个节点的当前状态，比如节点创建时间、节点名字、节点当前的配置纪元、节点的IP地址和端口号

### CLUSTER MEET命令的实现

## 槽指派

CLUSTER ADDSLOTS 将一个或多个槽指派给节点负责

### 记录节点的槽指派信息

slots属性是一个二进制位数组，长度位2048个字节，共包含16384个二进制位。

### 传播节点的槽指派信息

### 记录集群所有槽的指派信息

clusterNode \*slots\[16384\];

clusterState.slots数组记录了集群中所有槽的指派信息，而clusterNode.slots数组只记录了clusterNode结构所代表的节点的槽指派信息。

