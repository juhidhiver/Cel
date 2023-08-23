/**************************************************************************************************
 * Class Name: BindService
 * Author: 
 * Date: 
 * Description: Base Class For Bind related service logic
 **************************************************************************************************/
public with sharing class BindService {

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse checkSurplusLinesLicense(String quoteId){
        return BindServiceHandler_Common.checkSurplusLinesLicense(quoteId);
    }

    /* Description: Returns the status of the sync call via jobId */
    public static void bindQuoteIncoming(String quoteId, String payPlan, Boolean isBoundPending){
        BindServiceHandler_Common.bindQuoteIncoming(quoteId, payPlan, isBoundPending);
    }

    //method is being used for MPL/Cyber to bind with Binding License info
    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse bindQuoteWithBLInfo(String quoteId, String payPlan, Boolean isBoundPending, String blInfo ){
        return BindServiceHandler_CEL.bindQuoteWithBLInfo(quoteId,  payPlan, isBoundPending, blInfo);
    } 

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse bindQuote(String quoteId, String payPlan, Boolean isBoundPending){
        return BindServiceHandler_Common.bindQuote(quoteId, payPlan, isBoundPending);
    }

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse bindQuoteQC(String quoteId, String payPlan, Boolean isBoundPending, String binder, String blInfo){
        return BindServiceHandler_Common.bindQuoteQC(quoteId, payPlan, isBoundPending, binder, blInfo);
    }

    /* Description: Bind quote logic for Aqueous */
    @AuraEnabled
    public static ResultResponse bindQuoteAqueous(String quoteId, String payPlan, Boolean isBoundPending, String binder){
        return BindServiceHandler_AQ.bindQuoteAqueous(quoteId, payPlan, isBoundPending, binder);
    }
    
    /* Description: Bind quote logic for celerity */
    @AuraEnabled
    public static ResultResponse bindQuoteCelerity(String quoteId, String payPlan, Boolean isBoundPending) {     
        return BindServiceHandler_CEL.bindQuoteCelerity(quoteId, payPlan, isBoundPending);
    }

     /* Description: Bind quote logic for celerity incoming */
     @AuraEnabled
     public static ResultResponse bindQuoteCelerityIncoming(String quoteId, String payPlan, Boolean isBoundPending) { 
         return BindServiceHandler_CEL.bindQuoteCelerity(quoteId, payPlan, isBoundPending, true);
     }

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static BindServiceHandler_Common.InitObject getInitData(String quoteId) {
        return BindServiceHandler_Common.getInitData(quoteId);
    }

    /* Description: Returns the status of the sync call via jobId */
    public static String bindQuoteFromEndorsement(String quoteId, Date contractCancelDate, String contractCancellationReason) {
        return BindServiceHandler_Common.bindQuoteFromEndorsement(quoteId, contractCancelDate, contractCancellationReason);
    }

    /* Description: Returns the status of the sync call via jobId */
    public static String bindQuoteForEndorsement(String quoteId, Date contractCancelDate, String contractCancellationReason) {
        return BindServiceHandler_Common.bindQuoteForEndorsement(quoteId, contractCancelDate, contractCancellationReason);
    }

    @AuraEnabled
    public static string getPreBindDetails(String quoteId) {
        return BindServiceHandler_Common.getPreBindDetails(quoteId);
    }

    /* Looks like internal method. Not needed in bind service*/
    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, String quoteAzureId, String nameApi) {
        return BindServiceHandler_Common.getHttpRequest(apiSetting, quoteAzureId, nameApi);
    }

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static BindServiceHandler_CEL.mReAppointWR fetchMReAppointmentDetails(String quoteId, String oppId, String insuredState) {
        return BindServiceHandler_CEL.fetchMReAppointmentDetails(quoteId, oppId, insuredState);
    }

    @AuraEnabled
    public static Quote fetchQuoteDetail(String quoteId) {
        return BindServiceHandler_Common.quoteDetails(quoteId);
    }
}