public class SyncServiceHandler_CEL {
    
     // ************For Celerity ********** //
    public static void SyncServiceCall_Cel(List<Quote> listQuote){
         API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Quote_Sync');

        if(apiSetting == null) return;
        
        try{   
            for(Quote quote : listQuote){
                system.debug('QQQ-->'+quote);
                if(quote.Opportunity.LastSource__c != GlobalVariables.PROD_NAME_FOR_SHOPX &&  quote.Product_Name__c != GlobalVariables.PROD_NAME_FOR_PI){
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
        } 
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }    
    }
     
}