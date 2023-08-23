public with sharing class QuoteInitFormCmpController {
    @AuraEnabled 
    public static Opportunity getOpportunityInfo(String id) {
        return [SELECT Id, Name, AccountId, Product_Name__c, StageName,
                    Effective_Date__c, Expiration_Date__c, CloseDate, Policy__c //29-May-20 Hoang added Policy__c for #19275
				FROM Opportunity 
                WHERE Id =: id LIMIT 1];
    }	

    @AuraEnabled
    public static ResultResponse initialize(String id) {
        ResultResponse result = new ResultResponse();
        try {
            Opportunity obj = getOpportunityInfo(id);
            if (obj.StageName != 'Qualified' 
                && obj.StageName != 'Closed Won') {//29-May-20 Hoang added for #19275
                result.errors.add('Opportunity must be qualified before creating new quote.');
                result.isSuccess = false;

                return result;
            }
            /* Hoang comment to waiting confirm 
            if (obj.StageName == 'Closed Won') {
                List<Quote> quotes = [Select Id 
                                        From Quote 
                                        Where Quote_Type__c = 'Amendment' 
                                            And Status = 'In Progress'
                                            And OpportunityId =:id];
                if (!quotes.isEmpty()){
                    result.errors.add('Amendment Quote is already created.');
                    result.isSuccess = false;
                    return result; 
                }
            }*/

            result.isSuccess = true;
        } catch (Exception ex) {
            result.errors.add('Failed to init New Quote form.');
            result.isSuccess = false;
        }
        return result;
    }
}