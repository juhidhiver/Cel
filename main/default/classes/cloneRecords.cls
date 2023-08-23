/*
To clone records for different amendments
Saumyak - 9 April 2021
*/
public with sharing class cloneRecords {
    
    //method_AQ
    public static NewEndorsementAQController.ResultWrapper fullAmendment(String policyId, String endorsementType, String effDate, String endorsementReason, String endoresementReasonOther){
        return CloneService.fullAmendment(policyId, endorsementType, effDate, endorsementReason, endoresementReasonOther);
    }

    //method_AQ
    public static RenewalPolicyAQController.ResultWrapper policyRenewal(String policyId){
        return CloneService.policyRenewal(policyId);
    }
    
    //method_AQ
    public static RenewalPolicyAQController.ResultWrapper createRenewalQuotes(string clonedOpp,String policyId,List<Quote> quoteListToClone,string binderPrimary,string binderExcess){
        return CloneService.createRenewalQuotes(clonedOpp, policyId, quoteListToClone, binderPrimary, binderExcess);
    }
    
    //method_AQ
    public static NewEndorsementAQController.ResultWrapper coverageCancelProcess(set<Id> quoteId,string selectedId,string policyId){
        return CloneService.coverageCancelProcess(quoteId, selectedId, policyId);
    }
    
    //method_AQ
    public static List<Opportunity> queryOpportunity(String oppId) {
        return CloneService.queryOpportunityAQ(oppId);
    }
    
    //method_AQ
    public static List<Quote> queryQuote(Set<Id> policyIds){
        return CloneService.queryQuoteAQ(policyIds);
    }
    
    //method_AQ
    public static List<Quote> queryRenewalQuote(Set<Id> quoteId){
        return CloneService.queryRenewalQuoteAQ(quoteId);
    }
    
    //method_AQ
    public static List<Quote> queryCoverageCancelQuote(Set<Id> quoteId){
        return CloneService.queryCoverageCancelQuoteAQ(quoteId);
    }
    
    //method_AQ
    public static Opportunity cloneOpportunityDetails(Opportunity opp) {
        return CloneService.cloneOpportunityDetails(opp);
    }
    
    //method_AQ
    public static void cloneOppRelatedRecords(String oldOppId, Opportunity clonedOpp){
        CloneService.cloneOppRelatedRecords(oldOppId, clonedOpp);
    }
    
    //method_Common
    public static List<Quote> cloneQuote(List<Quote> quotes){
        return CloneService.cloneQuote(quotes);
    }
    
    //method_AQ
    public static List<Quote> cloneQuoteCancelCoverage(List<Quote> quotes){
        return CloneService.cloneQuoteCancelCoverage(quotes);
    }

    //method_AQ
    public static void cloneQuoteRelatedRecords(List<String> quoteIdList, Map<String,String> parentQuoteIdToClonedQuoteIdMap, Id clonedOppId){
        CloneService.cloneQuoteRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap, clonedOppId);
    }
    
    //method_AQ
    public static void cloneQuoteRenewalRelatedRecords(List<String> quoteIdList, Map<String,String> parentQuoteIdToClonedQuoteIdMap, String clonedOppId){
        CloneService.cloneQuoteRenewalRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap, clonedOppId);
    }

    //method_Unknown_common
    public static List<Quote_Option__c> createQuoteOptions(Integer count, Id quoteId, String type){
        return CloneService.createQuoteOptions(count, quoteId, type);
    }

}