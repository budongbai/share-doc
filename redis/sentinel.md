# Sentinel

Sentinel是Redis高可用解决方案：由一个或多个Sentinel实例组成的Sentinel系统可以监视任意多个主服务器，以及这些主服务器属下的所有从服务器，并在被监视的主服务器进入下线状态时，自动将下线主服务器属下的从服务器升级为新的主服务器的，然后由新的主服务器代替已下线的主服务器继续处理命令请求。

## 启动并初始化Sentinel

redis-sentinel /path/to/you/sentinel.conf 或 redis-server /path/to/you/sentinel.conf --sentinel

启动Sentinel的过程：

1. 初始化服务器
2. 将普通Redis服务器使用的代码替换成Sentinel专用代码
3. 初始化Sentinel状态
4. 根据给定的配置文件，初始化Sentinel的监视主服务器列表
5. 创建连向主服务器的网络连接
   * 命令连接：用于向主服务器发送，并接受命令回复
   * 订阅连接：用于订阅主服务器的_sentinel_:hello频道

## 获取主服务器信息

INFO命令 10s一次，分析INFO命令的回复获取主服务器的当前信息。 INFO命令回复包含主服务器本身的信息，run\_id域记录的服务器运行ID和role域记录的服务器角色。还有主服务器属下所有从服务器的信息，包括IP+port

## 获取从服务器信息

创建连接到从服务器的命令连接和订阅连接

10s一次INFO命令，根据回复更新从服务器实例结构

## 向主服务器和从服务器发送信息

2s一次通过命令连接向所有被监视的主服务器和从服务器发送命令

PUBLISH **sentinel**:hello "s\_ip,s\_port,s\_runid,s\_epoch,m\_name,m\_ip,m\_port,m\_epoch"

## 接受来自主服务器和从服务器的频道信息

SUBCRIBE **sentinel**:hello 订阅命令

1. 更新sentinels字典
2. 创建连向其他Sentinel的命令连接

## 检测主观下线状态

1s一次向所有与它创建了命令连接的实例发送PING命令，根据回复判断实例状态。

down-after-milliseconds指定了Sentinel判断实例进入主观下线所需的时间长度。

## 检查客观下线状态

当Sentinel将一个主服务器判断为主观下线后，为确认是否真的下线，回想其他Sentinel进行询问，看它们是否认为主服务器已经进入下线状态。当Sentinel接受到足够多的已下线判断后，判定为客观下线，并进行故障转移操作。

1. 发送SENTINEL is-master-down-by-addr命令
2. 接收SENTINEL is-master-down-by-addr命令
3. 接收SENTINEL is-master-down-by-addr命令的回复

## 选举领头Sentinel

## 故障转移

1. 选出新的主服务器
2. 修改从服务区的复制目标
3. 将旧的主服务器变为从服务器

