@isTest global class MockHttpResponsesGenerator implements HttpCalloutMock {
    // Implement this interface method
    public String body 			{get; set;}
    public Integer statusCode 	{get; set;}

    global HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        String endpoint = req.getEndPoint();
        String body = '';
        res = createResponse(this.statusCode, this.body);

        return res;
    }

    public static HttpResponse createResponse(Integer statusCode, String body) {
        
        HttpResponse result = new HttpResponse();

        result.setHeader('Content-Type', 'application/json');
        result.setStatusCode(statusCode);
        result.setBody(body);

        return result;
    }
}