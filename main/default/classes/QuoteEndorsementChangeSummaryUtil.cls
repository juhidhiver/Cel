/*************************************************
* Class Name: QuoteEndorsementChangeSummaryUtil 
* Author: Giang Phan
* Date: 09/June/2020
* Revison : QuoteEndorsementChangeSummary Util
*************************************************/
public with sharing class QuoteEndorsementChangeSummaryUtil {
    
    public static Map<String,List<QuoteEndorsementChangeSummaryInfo>> getQuoteEndorsementChangeSummary(
                                                                                    List<String> quoteIds) {
        List<Quote> result = getQuoteWithQuoteEndorChangeSummaryList(quoteIds);
		System.debug(' # # # ' + result);
        if(!result.isEmpty()) {
            return getMapQECSFilterSection(result[0].QuoteEndorsementChangeSummaries__r);
        }
        return null;
    }

    public static List<Quote> getQuoteWithQuoteEndorChangeSummaryList(List<String> quoteIds) {

        List<Quote> result = [SELECT Id,Policy__r.Policy_Number__c,Policy__r.Azure_ID__c,Policy__r.Policy_Status__c,
                                            Status,Policy__c,Policy__r.Expiration_Date__c,//Document_ID__c,
                                            Policy__r.Effective_Date__c,Policy__r.Total_Premium__c,
                                            OpportunityId,Opportunity.AccountId,Opportunity.Account.Name,
                                            Opportunity.Account.Azure_ID__c,Opportunity.Product__c,
                                            Opportunity.Product__r.Name,Opportunity.Product__r.Azure_ID__c,
                                            Quote_Type__c,Total_Premium__c,
                                            (SELECT Id,QuoteId__c,CoverageName__c,Deleted_Record_Summary__c,
                                                    FieldName__c,Name,New_Record_Summary__c,NewValue__c,
                                                    ObjectName__c,OldValue__c,Operation__c,SubCoverageName__c,
                                                    Update_Record_Summary__c,Limit_Deductible__c
                                            FROM QuoteEndorsementChangeSummaries__r)
                                    FROM Quote WHERE Id IN :quoteIds];
        return result;

    }


    public static Map<String,List<QuoteEndorsementChangeSummaryInfo>> 
                                    getMapQECSFilterSection(List<QuoteEndorsementChangeSummary__c> returnedList) {
        
        Map<String,List<QuoteEndorsementChangeSummaryInfo>> mapQuoteEndorsementChangeSummary = 
                                                        new Map<String,List<QuoteEndorsementChangeSummaryInfo>>();
        
        QuoteEndorsementChangeSummaryInfo quoteEndorsementChangeSummaryDetailsInfo = null;
        for(QuoteEndorsementChangeSummary__c obj : returnedList) {
            if(String.isBlank(obj.ObjectName__c)) continue;

            String sectionName = obj.ObjectName__c;
            quoteEndorsementChangeSummaryDetailsInfo = createQuoteEndorsementChangeSummaryInfo(obj);
            if(mapQuoteEndorsementChangeSummary.get(sectionName) != null) {
                mapQuoteEndorsementChangeSummary.get(sectionName).add(quoteEndorsementChangeSummaryDetailsInfo);
            } else {

                List<QuoteEndorsementChangeSummaryInfo> newListTemp = 
                                            new List<QuoteEndorsementChangeSummaryInfo>();
                newListTemp.add(quoteEndorsementChangeSummaryDetailsInfo);
                mapQuoteEndorsementChangeSummary.put(sectionName, newListTemp);
            }
        }
        return mapQuoteEndorsementChangeSummary;
    }


    public static QuoteEndorsementChangeSummaryInfo createQuoteEndorsementChangeSummaryInfo(QuoteEndorsementChangeSummary__c obj) {
        
        QuoteEndorsementChangeSummaryInfo returnedObj = new QuoteEndorsementChangeSummaryInfo();
        returnedObj.coverageName = obj.CoverageName__c;
        returnedObj.deletedRecordSummary = obj.Deleted_Record_Summary__c;
        returnedObj.fieldName = obj.FieldName__c;
        returnedObj.newRecordSummary = obj.New_Record_Summary__c;
        returnedObj.newValue = obj.NewValue__c;
        returnedObj.objectName = obj.ObjectName__c;
        returnedObj.oldValue = obj.OldValue__c;
        returnedObj.operation = obj.Operation__c;
        returnedObj.subCoverageName = obj.SubCoverageName__c;
        returnedObj.updateRecordSummary = obj.Update_Record_Summary__c;
        returnedObj.limitDeductibleName = obj.Limit_Deductible__c;
        return returnedObj;

    }

    public class QuoteEndorsementChangeSummaryInfo {

        public String coverageName          {get; set;}
        public String deletedRecordSummary  {get; set;}
        public String fieldName             {get; set;}
        //public String name                  {get; set;}
        public String newRecordSummary      {get; set;}
        public String newValue              {get; set;}
        public String objectName            {get; set;}
        public String oldValue              {get; set;}
        public String operation             {get; set;}
        public String subCoverageName       {get; set;}
        public String limitDeductibleName   {get; set;}
        public String updateRecordSummary   {get; set;}

        
    }   
}