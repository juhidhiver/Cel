public class SyncServiceHandler_AQ{
    
    //************  For AQUEOUS  ************ //
     public static void SyncServiceCall_AQ(List<Quote> listQuote){
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Quote_Sync');

        if(apiSetting == null) return;
        
        try{   
            for(Quote quote : listQuote){
                HttpRequest req = new HttpRequest();
                HttpResponse res = new HttpResponse();
                req = SyncServiceHandler_Common.getHttpRequest(apiSetting, quote);  
                Http h = new Http();
                res = h.send(req);
                system.debug('res-->'+res);
                if(!Test.isRunningTest()){
                 ApiUtil.logAPICall(req,res,'Sync Quote Status','SyncQuoteBatch', apiSetting.HeaderParams__c, 'Outbound');   
                }
            }
        } 
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }    
      }

}