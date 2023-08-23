/**
 * @description       : Web Service Class for Calling Sync Callout
 * @author            : JUHI
 * @group             : 
 * @last modified on  : 27-07-2022
 * @last modified by  : JUHI
 * @Reffered          : SyncQuoteBatch
**/
public class SyncServiceHandler_Common {
  
    
    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, Quote updatedQuote) {
        HttpRequest req = Invsk_Callout.getHttpRequest(apiSetting);
        String quoteSyncJson = ApiUtil.getRatingJson(updatedQuote.Id);
        req.setBody(quoteSyncJson);        
        return req;
    }    
}