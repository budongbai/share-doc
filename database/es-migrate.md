# ES迁移遇到的问题

## High Level Client兼容问题

### 常见错误
1. 使用6.0.0版本client操作7.6.2版本集群时，_bulk操作报错
```log
13:45:57.874 [main] INFO com.llj.demo.es.EsDemo - error
org.elasticsearch.ElasticsearchStatusException: Elasticsearch exception [type=illegal_argument_exception, reason=Action/metadata line [1] contains an unknown parameter [_routing]]
	at org.elasticsearch.rest.BytesRestResponse.errorFromXContent(BytesRestResponse.java:177)
	at org.elasticsearch.client.RestHighLevelClient.parseEntity(RestHighLevelClient.java:558)
	at org.elasticsearch.client.RestHighLevelClient.parseResponseException(RestHighLevelClient.java:534)
	at org.elasticsearch.client.RestHighLevelClient.performRequest(RestHighLevelClient.java:441)
	at org.elasticsearch.client.RestHighLevelClient.performRequestAndParseEntity(RestHighLevelClient.java:414)
	at org.elasticsearch.client.RestHighLevelClient.bulk(RestHighLevelClient.java:229)
	at com.llj.demo.es.EsDemo.post(EsDemo.java:82)
	at com.llj.demo.es.EsDemo.main(EsDemo.java:61)
	Suppressed: org.elasticsearch.client.ResponseException: method [POST], host [http://*.*.*.*:9200], URI [/_bulk?timeout=1m], status line [HTTP/1.1 400 Bad Request]
{"error":{"root_cause":[{"type":"illegal_argument_exception","reason":"Action/metadata line [1] contains an unknown parameter [_routing]"}],"type":"illegal_argument_exception","reason":"Action/metadata line [1] contains an unknown parameter [_routing]"},"status":400}
		at org.elasticsearch.client.RestClient$1.completed(RestClient.java:355)
		at org.elasticsearch.client.RestClient$1.completed(RestClient.java:344)
		at org.apache.http.concurrent.BasicFuture.completed(BasicFuture.java:122)
		at org.apache.http.impl.nio.client.DefaultClientExchangeHandlerImpl.responseCompleted(DefaultClientExchangeHandlerImpl.java:181)
		at org.apache.http.nio.protocol.HttpAsyncRequestExecutor.processResponse(HttpAsyncRequestExecutor.java:448)
		at org.apache.http.nio.protocol.HttpAsyncRequestExecutor.inputReady(HttpAsyncRequestExecutor.java:338)
		at org.apache.http.impl.nio.client.InternalRequestExecutor.inputReady(InternalRequestExecutor.java:83)
		at org.apache.http.impl.nio.DefaultNHttpClientConnection.consumeInput(DefaultNHttpClientConnection.java:265)
		at org.apache.http.impl.nio.client.InternalIODispatch.onInputReady(InternalIODispatch.java:81)
		at org.apache.http.impl.nio.client.InternalIODispatch.onInputReady(InternalIODispatch.java:39)
		at org.apache.http.impl.nio.reactor.AbstractIODispatch.inputReady(AbstractIODispatch.java:114)
		at org.apache.http.impl.nio.reactor.BaseIOReactor.readable(BaseIOReactor.java:162)
		at org.apache.http.impl.nio.reactor.AbstractIOReactor.processEvent(AbstractIOReactor.java:337)
		at org.apache.http.impl.nio.reactor.AbstractIOReactor.processEvents(AbstractIOReactor.java:315)
		at org.apache.http.impl.nio.reactor.AbstractIOReactor.execute(AbstractIOReactor.java:276)
		at org.apache.http.impl.nio.reactor.BaseIOReactor.execute(BaseIOReactor.java:104)
		at org.apache.http.impl.nio.reactor.AbstractMultiworkerIOReactor$Worker.run(AbstractMultiworkerIOReactor.java:591)
		at java.lang.Thread.run(Thread.java:748)
```

2. 使用7.6.2版本client操作6.0.0版本集群，search查询报错
```log
11:59:36.855 [main] DEBUG org.elasticsearch.client.RestClient - request [POST http://*.*.*.*:9200/creation_video/_search?routing=1828360351&pre_filter_shard_size=128&typed_keys=true&max_concurrent_shard_requests=5&ignore_unavailable=false&expand_wildcards=open&allow_no_indices=true&ignore_throttled=true&search_type=query_then_fetch&batched_reduce_size=512&ccs_minimize_roundtrips=true] returned [HTTP/1.1 400 Bad Request]
11:59:37.683 [main] INFO com.llj.demo.es.EsDemo - error
org.elasticsearch.ElasticsearchStatusException: Elasticsearch exception [type=illegal_argument_exception, reason=request [/creation_video/_search] contains unrecognized parameters: [ccs_minimize_roundtrips], [ignore_throttled]]
    at org.elasticsearch.rest.BytesRestResponse.errorFromXContent(BytesRestResponse.java:177)
    at org.elasticsearch.client.RestHighLevelClient.parseEntity(RestHighLevelClient.java:1793)
    at org.elasticsearch.client.RestHighLevelClient.parseResponseException(RestHighLevelClient.java:1770)
    at org.elasticsearch.client.RestHighLevelClient.internalPerformRequest(RestHighLevelClient.java:1527)
    at org.elasticsearch.client.RestHighLevelClient.performRequest(RestHighLevelClient.java:1484)
    at org.elasticsearch.client.RestHighLevelClient.performRequestAndParseEntity(RestHighLevelClient.java:1454)
    at org.elasticsearch.client.RestHighLevelClient.search(RestHighLevelClient.java:970)
    at com.llj.demo.es.EsDemo.search(EsDemo.java:114)
    at com.llj.demo.es.EsDemo.main(EsDemo.java:60)
    Suppressed: org.elasticsearch.client.ResponseException: method [POST], host [http://*.*.*.*:9200], URI [/creation_video/_search?routing=1828360351&pre_filter_shard_size=128&typed_keys=true&max_concurrent_shard_requests=5&ignore_unavailable=false&expand_wildcards=open&allow_no_indices=true&ignore_throttled=true&search_type=query_then_fetch&batched_reduce_size=512&ccs_minimize_roundtrips=true], status line [HTTP/1.1 400 Bad Request]
{"error":{"root_cause":[{"type":"illegal_argument_exception","reason":"request [/creation_video/_search] contains unrecognized parameters: [ccs_minimize_roundtrips], [ignore_throttled]"}],"type":"illegal_argument_exception","reason":"request [/creation_video/_search] contains unrecognized parameters: [ccs_minimize_roundtrips], [ignore_throttled]"},"status":400}
        at org.elasticsearch.client.RestClient.convertResponse(RestClient.java:283)
        at org.elasticsearch.client.RestClient.performRequest(RestClient.java:261)
        at org.elasticsearch.client.RestClient.performRequest(RestClient.java:235)
        at org.elasticsearch.client.RestHighLevelClient.internalPerformRequest(RestHighLevelClient.java:1514)
        ... 5 common frames omitted
```

### es client差异

1. 低版本中SearchHits中totalHits属性为long，而高版本中则是对象TotalHits

```java
public final class SearchHits implements Streamable, ToXContentFragment, Iterable<SearchHit> {
    public long totalHits;
}
```

```java
public final class SearchHits implements Writeable, ToXContentFragment, Iterable<SearchHit> {
    private final TotalHits totalHits;
}
```
除此之外，total问题：查询只能返回10000条数据
  - 7.6.2版本中total返回结构调整为object，其中包含value和relation两个字段，当文档数量大于10000时，relation为gte,value为10000。为兼total问题，该版本提供了解决方案，详见<https://www.cxyzjd.com/article/Dongguabai/109458542>

2. RestHighLevelClient#search 参数不同：低版本，无RequestOptions，高版本多了一个RequestOptions
```java
    public SearchResponse search(SearchRequest searchRequest, Header... headers) throws IOException {
        return performRequestAndParseEntity(searchRequest, Request::search, SearchResponse::fromXContent, emptySet(), headers);
    }
```

```java
    public final SearchResponse search(SearchRequest searchRequest, RequestOptions options) throws IOException {
        return performRequestAndParseEntity(
                searchRequest,
                r -> RequestConverters.search(r, "_search"),
                options,
                SearchResponse::fromXContent,
                emptySet());
    }
```

## 解决

在需要双写迁移es的场景中，可能存在着多版本并存的问题，需要一个兼容的client，而目前官方es是没有提供的，只能自行封装。
方案: 通过rpc调用，将实际发生的写入和查询等操作转移到某个rpc服务提供者，rpc接口对外提供统一的格式。