/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 10-13-2021
 * @last modified by  : Vinayesh
**/
public class FinalizeQuoteController  {
    
    //method_Common
    @AuraEnabled
    public static List<FinalizeServiceHandler_Common.ReferralReasonWrapper> getReferralReasons(String quoteId){
        return FinalizeService.getReferralReasons(quoteId);
    }
    
    //method_Common
    @AuraEnabled
    public static ResultResponse finalizeQuote(String quoteId) {
        return FinalizeService.finalizeQuote(quoteId);
    }
    
    //method_Common: References in LWC but all are commented
    @AuraEnabled(cacheable = true)
    public static Boolean getQuoteDetails(Id quoteId){              //Added by Sarthak on 19th June 2020
        return FinalizeService.getQuoteDetails(quoteId);
    }
    
    //method_Common
    @AuraEnabled
    public static string quoteDetails(string quoteId){
        return FinalizeService.quoteDetails(quoteId);
    }
    
    //method_Common
    @AuraEnabled
    public static Boolean checkPartFixedEndorsement(ID quoteId){
        return FinalizeService.checkPartFixedEndorsement(quoteId);
    }
    
    //method_AQ
    @AuraEnabled
    public static Boolean checkSelectedQuoteOption(ID quoteId){
        return FinalizeService.checkSelectedQuoteOption(quoteId);
    }
    
    //method_AQ
    @AuraEnabled
    public static AsyncApexJob validateSyncForQuoteBind(ID jobId){
        return FinalizeService.validateSyncForQuoteBind(jobId);
    }

    //method_AQ
    @AuraEnabled
    public static List<FinalizeServiceHandler_AQ.CommentsWrapper> getQuoteApprovalComments(String quoteId){
        return FinalizeService.getQuoteApprovalComments(quoteId);
    }

    //method_AQ
    @AuraEnabled
    public static String generateApprovalURL(String quoteId){
        return FinalizeService.generateApprovalURL(quoteId);
    }
    
    //method_Common
    @AuraEnabled
    public static List<PicklistOption> handleCloseReasons(string quoteId){
        return FinalizeService.handleCloseReasons(quoteId);
    }
    
    //method_AQ
    @AuraEnabled
    public static Boolean checkIsPrimaryBroker(string quoteId){
        return FinalizeService.checkIsPrimaryBroker(quoteId);
    }

    //method_AQ
    @AuraEnabled
    public static API_Log__c syncQuoteToMiddleware(String quoteId) {
        return FinalizeService.syncQuoteToMiddleware(quoteId);
    }
}