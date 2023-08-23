/**************************************************************************************************
 * Class Name: CommonSubjectivityUtil
 * Author: 
 * Date: 
 * Description: Common methods for Subjectivity triggers
 **************************************************************************************************/
public class CommonSubjectivityUtil {

	
    /*************************************************
    * Method Name: populateClearedDate
    * Author:
    * Date: 
    * Params: (List<Subjectivity__c> newDataList, Map<Id, Subjectivity__c> oldDataMap
    * Return: 
    * Exceptions:
    * Description: sets the Cleared_Date__c to today if Cleared__c is checked
    * Revision: 
    *************************************************/
    public static void populateClearedDate(List<Subjectivity__c> newDataList, Map<Id, Subjectivity__c> oldDataMap){
       for (Subjectivity__c subRec : newDataList){
            if (subRec.Cleared__c == true)
            {
                subRec.Cleared_Date__c = Date.today();
            }
            else{
                subRec.Cleared_Date__c = null;
            }
        } 
    }


    /*************************************************
    * Method Name: updateQuoteStatusAQ
    * Author:
    * Date: 
    * Params: (List<Subjectivity__c> newDataList, Map<Id, Subjectivity__c> oldDataMap
    * Return: 
    * Exceptions:
    * Description: update quote status
    * Revision: 
    *************************************************/
    public static List<Quote> updateQuoteStatus(List<Subjectivity__c> subjectivities){
        Set<Id> quoteIds = new Set<Id>();
         List<Quote> syncQuotes = new List<Quote>();
        for(Subjectivity__c sub:subjectivities){
            quoteIds.add(sub.Quote__c);
        }

        List<Quote> updateQuote = new List<Quote>();
        String queryFields = 'Id, Status, OpportunityId, Product_Name__c';
        for(Quote quote : QuoteQueryUtil.fetchQuotesForQuoteIds( quoteIds, queryFields ) ){
            if(quote.status == 'Quoted' ){
                quote.status = 'Rated';
                updateQuote.add(quote);
            }
        }
        if(updateQuote.size()>0){
            update updateQuote;
        }
        return updateQuote;
    }
    
}