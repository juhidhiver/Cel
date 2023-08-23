public class CloneService {

    /****************************************************** Common ***************************************************************/

    /* Description: Returns a list of cloned quotes */
    public static List<Quote> cloneQuote(List<Quote> quotes){
        return CloneServiceHandler_Common.cloneQuote(quotes);
    }

    /* Description: To create specified number of quote options */
    public static List<Quote_Option__c> createQuoteOptions(Integer count, Id quoteId, String type){
        return CloneServiceHandler_Common.createQuoteOptions(count, quoteId, type);
    }

    /* Description: To clone a quote along with its child objects */
    public static ResultResponse cloneQuoteWithChildren(String quoteId, Map<String,Object> fieldUpdateMap) {
        return CloneServiceHandler_Common.cloneQuoteWithChildren(quoteId, fieldUpdateMap);
    }

    /****************************************************** Aqueous ***************************************************************/

    /* Description: To clone submission and all its related objects for AQ Full Amendment */
    public static NewEndorsementAQController.ResultWrapper fullAmendment(String policyId, String endorsementType, String effDate, String endorsementReason, String endoresementReasonOther){
        return CloneServiceHandler_AQ.fullAmendment(policyId, endorsementType, effDate, endorsementReason, endoresementReasonOther);
    }

    /* Description: Returns a clone of the submission */
    public static Opportunity cloneOpportunityDetails(Opportunity opp) {
        return CloneServiceHandler_AQ.cloneOpportunityDetails(opp);
    }

    /* Description: Clones related objects of the original submission and inserts into the cloned sub */
    public static void cloneOppRelatedRecords(String oldOppId, Opportunity clonedOpp){
        CloneServiceHandler_AQ.cloneOppRelatedRecords(oldOppId, clonedOpp);
    }

    /* Description: Clones related objects of the original quote and inserts into the cloned quote */
    public static void cloneQuoteRelatedRecords(List<String> quoteIdList, Map<String,String> parentQuoteIdToClonedQuoteIdMap, Id clonedOppId){
        CloneServiceHandler_AQ.cloneQuoteRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap, clonedOppId);
    }

    /* Description: Clones the active submission and quotes related to policy during Renewal transaction */
    public static RenewalPolicyAQController.ResultWrapper policyRenewal(String policyId){
        return CloneServiceHandler_AQ.policyRenewal(policyId);
    }

    /* Description: Clones related objects of the quote during Renewal transaction */
    public static void cloneQuoteRenewalRelatedRecords(List<String> quoteIdList, Map<String,String> parentQuoteIdToClonedQuoteIdMap, String clonedOppId){
        CloneServiceHandler_AQ.cloneQuoteRenewalRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap, clonedOppId);
    }

    /* Description: Clones all the submission and quote related objects during Renewal transaction */
    public static RenewalPolicyAQController.ResultWrapper createRenewalQuotes(string clonedOpp,String policyId,List<Quote> quoteListToClone,string binderPrimary,string binderExcess){
        return CloneServiceHandler_AQ.createRenewalQuotes(clonedOpp, policyId, quoteListToClone, binderPrimary, binderExcess);
    }

    /* Description: Returns a list of cloned quotes for Coverage Cancel transaction */
    public static List<Quote> cloneQuoteCancelCoverage(List<Quote> quotes){
        return CloneServiceHandler_AQ.cloneQuoteCancelCoverage(quotes);
    }

    /* Description: Clones quotes and its related objects for Coverage Cancel transaction */
    public static NewEndorsementAQController.ResultWrapper coverageCancelProcess(set<Id> quoteId,string selectedId,string policyId){
        return CloneServiceHandler_AQ.coverageCancelProcess(quoteId, selectedId, policyId);
    }

    /****************************************************** Celerity ***************************************************************/

    /* Description: Clones quotes and its related objects for Coverage Cancel transaction */
    public static NewEndorsementController.ResultWrapper coverageCancelProcessCEL(set<Id> quoteId,string selectedId,string policyId){
        return CloneServiceHandler_CEL.coverageCancelProcessCEL(quoteId, selectedId, policyId);
    }

    /****************************************************** Queries ***************************************************************/

    /* Description: AQ Query to fetch the active submission record based on sub id */
    public static List<Opportunity> queryOpportunityAQ(String oppId) {
        return CloneQueryUtil.queryOpportunityAQ(oppId);
    }

    /* Description: AQ Query to fetch list of bound quotes based on policy ids */
    public static List<Quote> queryQuoteAQ(Set<Id> policyIds){
        return CloneQueryUtil.queryQuoteAQ(policyIds);
    }

    /* Description: AQ Query to fetch list of quotes based on quote ids for Renewal */
    public static List<Quote> queryRenewalQuoteAQ(Set<Id> quoteId){
        return CloneQueryUtil.queryRenewalQuoteAQ(quoteId);
    }

    /* Description: AQ Query to fetch list of quotes based on quote ids for Coverage Cancel transaction */
    public static List<Quote> queryCoverageCancelQuoteAQ(Set<Id> quoteId){
        return CloneQueryUtil.queryCoverageCancelQuoteAQ(quoteId);
    }

}