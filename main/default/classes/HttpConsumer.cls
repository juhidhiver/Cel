public with sharing class HttpConsumer {
    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, String queryParam) {
        
        HttpRequest req = new HttpRequest();

        if(apiSetting != null){
            queryParam = queryParam == null ? '' : '?'+queryParam;
            String serviceUrl = apiSetting.Base_Url__c + apiSetting.Endpoint__c + queryParam;
            system.debug('==serviceUrl==' + serviceUrl);
            Map<String, String> headerParamMap = new Map<String, String>();
            for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
                List<String> headerKeyValue = headerParam.split(':');
                headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
            }
            req.setEndpoint(serviceUrl);
            req.setMethod(apiSetting.Method__c);
            req.setTimeout(Integer.valueOf(Label.ApiTimeOut));
            for (String headerParamKey : headerParamMap.keySet()) {
                req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
            }
        }
        return req;
    }
}