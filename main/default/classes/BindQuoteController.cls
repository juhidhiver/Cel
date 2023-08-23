/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 01-04-2022
 * @last modified by  : Vinayesh
**/
public with sharing class BindQuoteController {

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse checkSurplusLinesLicense(String quoteId){
        return BindService.checkSurplusLinesLicense(quoteId);
    }

    /* Description: Returns the status of the sync call via jobId */
    public static void bindQuoteIncoming(String quoteId, String payPlan, Boolean isBoundPending){
        BindService.bindQuoteIncoming(quoteId, payPlan, isBoundPending);
    }

    //method is being used for MPL/Cyber to bind with Binding License info
    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse bindQuoteWithBLInfo(String quoteId, String payPlan, Boolean isBoundPending, String blInfo ){
        return BindService.bindQuoteWithBLInfo(quoteId,  payPlan, isBoundPending, blInfo);
    }

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse bindQuote(String quoteId, String payPlan, Boolean isBoundPending){
        return BindService.bindQuote(quoteId, payPlan, isBoundPending);
    }

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse bindQuoteQC(String quoteId, String payPlan, Boolean isBoundPending, String binder, String blInfo){
        ResultResponse result = new ResultResponse();
        try{
            result = BindService.bindQuoteQC(quoteId, payPlan, isBoundPending, binder, blInfo);
        } catch(Exception ex){
            ErrorLogsUtilityHelper.logError(ex, 'BindQuoteController.bindQuoteQC', CommonUtil.getExceptionMessage(ex), quoteId, 'AQ_Exceptions', '', String.valueOf(ex.getLineNumber()));
            result.errors.add(CommonUtil.getExceptionMessage(ex));
        }
        return result;
    }

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse bindQuoteAqueous(String quoteId, String payPlan, Boolean isBoundPending, String binder){
        return BindService.bindQuoteAqueous(quoteId, payPlan, isBoundPending, binder);
    }
    
    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static ResultResponse bindQuoteCelerity(String quoteId, String payPlan, Boolean isBoundPending) {     
        return BindService.bindQuoteCelerity(quoteId, payPlan, isBoundPending);
    }

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static BindServiceHandler_Common.InitObject getInitData(String quoteId) {
        return BindService.getInitData(quoteId);
    }

    /* Description: Returns the status of the sync call via jobId */
    public static String bindQuoteFromEndorsement(String quoteId, Date contractCancelDate, String contractCancellationReason) {
        return BindService.bindQuoteFromEndorsement(quoteId, contractCancelDate, contractCancellationReason);
    }

    /* Description: Returns the status of the sync call via jobId */
    public static String bindQuoteForEndorsement(String quoteId, Date contractCancelDate, String contractCancellationReason) {
        return BindService.bindQuoteForEndorsement(quoteId, contractCancelDate, contractCancellationReason);
    }

    @AuraEnabled
    public static string getPreBindDetails(String quoteId) {
        return BindService.getPreBindDetails(quoteId);
    }

    /* Looks like internal method. Not needed in bind service*/
    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, String quoteAzureId, String nameApi) {
        return BindService.getHttpRequest(apiSetting, quoteAzureId, nameApi);
    }

    /* Description: Returns the status of the sync call via jobId */
    @AuraEnabled
    public static BindServiceHandler_CEL.mReAppointWR fetchMReAppointmentDetails(String quoteId, String oppId, String insuredState) {
        return BindServiceHandler_CEL.fetchMReAppointmentDetails(quoteId, oppId, insuredState);
    }
}