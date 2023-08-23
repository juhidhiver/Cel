public class FinalizeService {

    /****************************************************** Common ***************************************************************/

    /* Description: Returns the Referral Reasons related to the quote */
    public static List<FinalizeServiceHandler_Common.ReferralReasonWrapper> getReferralReasons(String quoteId){
        return FinalizeServiceHandler_Common.getReferralReasons(quoteId);
    }

    /* Description: Performs all the required validations and finalizes the quote */
    public static ResultResponse finalizeQuote(String quoteId) {
        return FinalizeServiceHandler_Common.finalizeQuote(quoteId);
    }

    /* Description: Checks for any pending approval request related to quote */
    public static Boolean getQuoteDetails(Id quoteId){
        return FinalizeServiceHandler_Common.getQuoteDetails(quoteId);
    }

    /* Description: Checks the Sanction Status of all the related Accounts and returns the wrapper with all the details */
    public static string quoteDetails(string quoteId){
        return FinalizeServiceHandler_Common.quoteDetails(quoteId);
    }

    /* Description: Checks if the value for any Part Fixed Endorsement is blank */
    public static Boolean checkPartFixedEndorsement(ID quoteId){
        return FinalizeServiceHandler_Common.checkPartFixedEndorsement(quoteId);
    }

    /* Description: Returns some specific picklist values for Quote Closed Reason field depending on product - AQ/CEL */
    public static List<PicklistOption> handleCloseReasons(string quoteId){
        return FinalizeServiceHandler_Common.handleCloseReasons(quoteId);
    }

    /* Description: Finalizes the quote in middleware and generates the quote documents */
    public static FinalizeServiceHandler_Common.ResultResponseWrapper generateFinalizeDocument(string quoteAzureId,string quoteId){
        return FinalizeServiceHandler_Common.generateFinalizeDocument(quoteAzureId, quoteId);
    }

    /****************************************************** Aqueous ***************************************************************/

    /* Description: Returns the selected quote option for the quote */
    public static Boolean checkSelectedQuoteOption(ID quoteId){
        return FinalizeServiceHandler_AQ.checkSelectedQuoteOption(quoteId);
    }

    /* Description: Returns the status of the sync call via jobId */
    public static AsyncApexJob validateSyncForQuoteBind(ID jobId){
        return FinalizeServiceHandler_AQ.validateSyncForQuoteBind(jobId);
    }

    /* Description: Returns the comments for Approved/Rejected approvals for the quote */
    public static List<FinalizeServiceHandler_AQ.CommentsWrapper> getQuoteApprovalComments(String quoteId){
        return FinalizeServiceHandler_AQ.getQuoteApprovalComments(quoteId);
    }

    /* Description: Returns the approval record link for the quote */
    public static String generateApprovalURL(String quoteId){
        return FinalizeServiceHandler_AQ.generateApprovalURL(quoteId);
    }

    /* Description: Checks if any primary broker exists for the submission related to the quote */
    public static Boolean checkIsPrimaryBroker(string quoteId){
        return FinalizeServiceHandler_AQ.checkIsPrimaryBroker(quoteId);
    }

    /* Description: Initiates a synchronous sync call to Middleware for the quote */
    public static API_Log__c syncQuoteToMiddleware(String quoteId) {
        return FinalizeServiceHandler_AQ.syncQuoteToMiddleware(quoteId);
    }

    /* Description: Finalizes the quote in middleware and generates the quote documents for AQ */
    @AuraEnabled
    public static Quote finalizeAndGenerateDocAQ(Quote quote){
        return FinalizeServiceHandler_AQ.finalizeAndGenerateDocAQ(quote);
    }

}