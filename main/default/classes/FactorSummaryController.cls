public with sharing class FactorSummaryController {
    
    @AuraEnabled
    public static ResultResponse getFactorSummarys(String quoteId) {
        ResultResponse result = new ResultResponse();
        List<FactorSummaryComparisonWrapper> wrappers = new List<FactorSummaryComparisonWrapper>();
        
        List<Quote> quotes = [SELECT Id, Name,Parent_Quote__c,Quote_Type__c,Opportunity.Type, Opportunity.Parent_Opportunity__c FROM Quote WHERE Id =: quoteId];
        
        String oppType = quotes.isEmpty() ? '' : quotes[0].Opportunity.Type;
        String parentQuoteId= quotes.isEmpty() ? '' : quotes[0].Parent_Quote__c;
        String parentSubmissonId= quotes.isEmpty() ? '' : quotes[0].Opportunity.Parent_Opportunity__c;
        
        if(String.isBlank(parentQuoteId) && String.isNotBlank(parentSubmissonId)){
            List<Quote> parentQuotes = [SELECT Id FROM Quote WHERE OpportunityId = :parentSubmissonId AND Status = 'Bound' ORDER BY CreatedDate DESC];
            if(!parentQuotes.isEmpty()){
                parentQuoteId = parentQuotes[0].Id;
            }
        }
        
        Map<String,String> mapParent = new Map<String,String>();
        if(String.isNotBlank(parentQuoteId)){
            for (Factor_Summary__c parent : [SELECT Id, Quote__c,Quote__r.Name, Code__c, Value__c FROM Factor_Summary__c WHERE Quote__c =: parentQuoteId ORDER By Code__c]) {
                mapParent.put(parent.Code__c, parent.Value__c);
            }
        }
        
        List<Factor_Summary_Template__c> templates = [SELECT Id,Sort_Order__c,Format__c,Code__c FROM Factor_Summary_Template__c WHERE Active__c = true ORDER BY Sort_Order__c];
        Map<String,Decimal> mapTemplate = new Map<String,Decimal>();
        Map<String,string> mapFormat = new Map<String,string>();
        
        for (Factor_Summary_Template__c template : templates) {
            mapTemplate.put(template.Code__c, template.Sort_Order__c);
            mapFormat.put(template.Code__c, template.Format__c);
        }
        
        for (Factor_Summary__c child : [SELECT Id, Quote__c,CurrencyIsoCode,Quote__r.Name, Code__c, Value__c FROM Factor_Summary__c WHERE Code__c IN :mapTemplate.keySet() AND Quote__c =: quoteId ORDER By Code__c]) {
            wrappers.add(
                new FactorSummaryComparisonWrapper(
                    child.Code__c, child.Value__c, mapParent.get(child.Code__c),mapTemplate.get(child.Code__c),mapFormat.get(child.Code__c),child.CurrencyIsoCode)
            );
        }
        
        result.data = wrappers;
        result.extraData = oppType;
        return result;
    }

    @AuraEnabled
    public static ResultResponse getFactorSummarysQC(String quoteOptionId) {
        ResultResponse result = new ResultResponse();
        List<FactorSummaryComparisonWrapper> wrappers = new List<FactorSummaryComparisonWrapper>();
        String quoteId =[Select Id, Quote__c from Quote_Option__c where Id =: quoteOptionId].Quote__c;
        List<Quote_Option__c> listParentQO = new List<Quote_Option__c>();
        String parentQOId = quoteOptionId;
        
        List<Quote> quotes = [SELECT Id, Name,Parent_Quote__c,Quote_Type__c,Opportunity.Type, Opportunity.Parent_Opportunity__c FROM Quote WHERE Id =: quoteId];
        
        String oppType = quotes.isEmpty() ? '' : quotes[0].Opportunity.Type;
        String parentQuoteId= quotes.isEmpty() ? '' : quotes[0].Parent_Quote__c;
        String parentSubmissonId= quotes.isEmpty() ? '' : quotes[0].Opportunity.Parent_Opportunity__c;
        System.debug('parentSubmissonId'+parentSubmissonId);
        System.debug('parentQuoteId'+parentQuoteId);
        if(String.isBlank(parentQuoteId) && String.isNotBlank(parentSubmissonId)){
            List<Quote> parentQuotes = [SELECT Id,(Select Id from Quote_Options__r where Bound__c = true) FROM Quote WHERE OpportunityId = :parentSubmissonId AND Status = 'Bound' ORDER BY CreatedDate DESC];
            if(!parentQuotes.isEmpty()){
                parentQuoteId = parentQuotes[0].Id;
                System.debug('parentQuoteId'+parentQuoteId);
                if(!parentQuotes[0].Quote_Options__r.isEmpty()){
                    listParentQO =parentQuotes[0].Quote_Options__r;
                    parentQOId = listParentQO[0].Id;
                }
            }
        }
        else if(String.isNotBlank(parentQuoteId)){
            listParentQO = [Select Id from Quote_Option__c where Quote__c =:parentQuoteId and Bound__c = true];
            if(!listParentQO.isEmpty()){
                parentQOId = listParentQO[0].Id;
            }
        }
        
        Map<String,String> mapParent = new Map<String,String>();
        if(String.isNotBlank(parentQuoteId)){
            for (Factor_Summary__c parent : [SELECT Id, Quote__c,Quote__r.Name, Code__c, Value__c FROM Factor_Summary__c WHERE Quote_Option__c =: parentQOId ORDER By Code__c]) {
                mapParent.put(parent.Code__c, parent.Value__c);
            }
        }
        
        List<Factor_Summary_Template__c> templates = [SELECT Id,Sort_Order__c,Format__c,Code__c FROM Factor_Summary_Template__c WHERE Active__c = true ORDER BY Sort_Order__c];
        Map<String,Decimal> mapTemplate = new Map<String,Decimal>();
        Map<String,string> mapFormat = new Map<String,string>();
        
        for (Factor_Summary_Template__c template : templates) {
            mapTemplate.put(template.Code__c, template.Sort_Order__c);
            mapFormat.put(template.Code__c, template.Format__c);
        }
        
        for (Factor_Summary__c child : [SELECT Id, Quote__c,CurrencyIsoCode,Quote__r.Name, Code__c, Value__c FROM Factor_Summary__c WHERE Code__c IN :mapTemplate.keySet() AND Quote_Option__c =: quoteOptionId ORDER By Code__c]) {
            wrappers.add(
                new FactorSummaryComparisonWrapper(
                    child.Code__c, child.Value__c, mapParent.get(child.Code__c),mapTemplate.get(child.Code__c),mapFormat.get(child.Code__c),child.CurrencyIsoCode)
            );
        }
        
        result.data = wrappers;
        result.extraData = oppType;
        return result;
    }
    
    public class FactorSummaryComparisonWrapper{
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String priorValue;
        @AuraEnabled
        public String currentValue;
        @AuraEnabled
        public Decimal sortOrder;
        @AuraEnabled
        public String format;
        @AuraEnabled
        public String currencyType;
        public FactorSummaryComparisonWrapper(){
            name = '';
            priorValue = '';
            currentValue = '';
            sortOrder = 0;
            format = '';
            currencyType = '';
        }
        public FactorSummaryComparisonWrapper(String name,String current, String prior, Decimal order,string format,string currencyType){
            this.name = name;
            this.priorValue = prior;
            this.currentValue = current;
            this.sortOrder = order;
            this.format = format;
            this.currencyType = currencyType;
        }
    }
    
    
}