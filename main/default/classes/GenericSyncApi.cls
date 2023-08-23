/**
 * @description       : Will be used to send back 'Synchronous' response received from API call
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 09-14-2021
 * @last modified by  : Maeran Shaikh
**/
public with sharing class GenericSyncApi {

    /**
    * @description Generic method to be used to send back Response for a single record API call
    * @author Maeran Shaikh | 09-14-2021 
    * @param settingName 
    * @param APIName 
    * @param functionName 
    * @param methodName 
    * @param obj 
    * @return Response 
    **/
    public static API_Log__c getResponseFromApi(String settingName,String apiName, SObject obj , String functionName){

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        API_Log__c objApiLog = new API_Log__c();

        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration(settingName);
        if(apiSetting == null) {
            return null;
        }


        // Logic will only run for Quote Sync Schronous Operation
        if(apiName == 'Sync Quote Status'){
            req = getHttpRequestForQuoteSync(apiSetting, (Quote)obj);
            Http h = new Http();
            res = h.send(req);
            objApiLog = ApiUtil.createLogAPICall(req,res,apiName,functionName, apiSetting.HeaderParams__c, 'Outbound');
            return objApiLog;
        }
        else{
            // Add else if logic for specific operation
            return null;
        }
    }


    /**
    * @description : Specific to Quote Sync Operation
    * @author Maeran Shaikh | 09-14-2021 
    * @param apiSetting 
    * @param updatedQuote 
    * @return HttpRequest 
    **/
    public static HttpRequest getHttpRequestForQuoteSync(API_Configuration__mdt apiSetting, Quote updatedQuote) {
        HttpRequest req = Invsk_Callout.getHttpRequest(apiSetting);
        String quoteSyncJson = ApiUtil.getRatingJson(updatedQuote.Id);
        req.setBody(quoteSyncJson);        
        return req;
    }
}