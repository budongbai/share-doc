# Arthas 入门使用

1. 下载arthas-boot.jar
    curl -O https://arthas.aliyun.com/arthas-boot.jar

2. 启动arthas
    java -jar arthas-boot.jar，选择要debug的相应进程
3. 比较常用的命令
    trace命令跟踪指定类的指定方法，打印其每一次函数调用的耗时，可以快速定位耗时长的函数

    示例： trace -E com.liulijuan.ops.controller.api.videouser.VideoUserController|com.liulijuan.ops.service.videouser.VideoUserService search|searchPageResponse|dealPageResponse -n 1
    其中，-n 1 表示 跟踪到一次后就退出trace。


更多功能还是看[arthas官方文档](https://arthas.aliyun.com/doc/quick-start.html)吧