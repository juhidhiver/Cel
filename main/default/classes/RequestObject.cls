public class RequestObject {
    public String endpoint {get;set;}
    public String method {get;set;}
    public Map<String, String> headers {get;set;}
    public String body {get;set;}
    public Integer timeout {get;set;}

    public RequestObject() {
        this.endpoint = '';
        this.method = '';
        this.headers = new Map<String, String>();
        this.body = '';
        this.timeout = 0;
    }

    public HttpRequest getHttpRequest() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(this.endpoint);
        req.setMethod(this.method);
        req.setTimeout(this.timeout);
        req.setBody(this.body);

        for (String key : headers.keySet()) {
            req.setHeader(key, headers.get(key));
        }

        return req;
    }
}