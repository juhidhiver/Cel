/**************************************************************************************************
* Class Name: FreeFormEndorsementTriggerHandler_AQ
* Author: 
* Date: 
* Description: Class to keep Celerity related  common methods
* Test Class : FreeFormEndorsementTriggerTest
**************************************************************************************************/

public class FreeFormEndorsementTriggerHandler_AQ extends TriggerHandler {
    
    private List<Free_Form_Endorsements__c> oldDataList;
    private List<Free_Form_Endorsements__c> newDataList;
    private Map<Id, Free_Form_Endorsements__c> newDataMap;
    private Map<Id, Free_Form_Endorsements__c> oldDataMap;
    
    public FreeFormEndorsementTriggerHandler_AQ(List<Free_Form_Endorsements__c> newDataList, List<Free_Form_Endorsements__c> oldDataList, 
                                                Map<Id, Free_Form_Endorsements__c> newDataMap, Map<Id, Free_Form_Endorsements__c> oldDataMap) {
                                                    this.oldDataList = oldDataList;
                                                    this.newDataList = newDataList;
                                                    this.newDataMap = newDataMap;
                                                    this.oldDataMap = oldDataMap;
                                                }
    public override void afterinsert(){
        //update quote status
        updateQuoteStatusAQ(newDataList);
    }
    public override void afterupdate(){
        //update quote status
        updateQuoteStatusAQ(newDataList);
    }
    public override void afterdelete(){
        //update quote status
        updateQuoteStatusAQ(oldDataList);
    }
    
    /*************************************************
    * Method Name: updateQuoteStatusAQ
    * Author:
    * Date: 
    * Params: 
    * Return: 
    * Exceptions:
    * Description: update quote status
    * Revision: 
     *************************************************/
    private static void updateQuoteStatusAQ(List<Free_Form_Endorsements__c> freeEndorsements){
        Set<Id> quoteIds = new Set<Id>();
        for(Free_Form_Endorsements__c endorsement:freeEndorsements){
            quoteIds.add(endorsement.Quote__c);
        }
        
        List<Quote> updateQuote = new List<Quote>();
        String queryFields = 'Id,Celerity_Excess_Limit__c,Underlying_Excess_Limit__c, Celerity_Technical_Premium__c, Status, Product_Name__c';
        for(Quote quote: QuoteQueryUtil.fetchQuotesForQuoteIds(quoteIds,queryFields) ){
            if(quote.status != 'In Progress' && quote.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                quote.status = 'In Progress';
            }
            updateQuote.add(quote);
        }
        
        if(updateQuote.size()>0){
            update updateQuote;
        }
    }
}