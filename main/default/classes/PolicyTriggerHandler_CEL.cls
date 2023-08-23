/**************************************************************************************************
 * Class Name: PolicyTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: Class to keep Celerity related  common methods
 * Test Class : PolicyTriggerTest
 **************************************************************************************************/
public class PolicyTriggerHandler_CEL extends TriggerHandler {


    private List<Policy__c> oldDataList;
    private List<Policy__c> newDataList; 
    private Map<Id, Policy__c> newDataMap;
    private Map<Id, Policy__c> oldDataMap; 
    
    public PolicyTriggerHandler_CEL(List<Policy__c> newDataList, List<Policy__c> oldDataList, 
                                         Map<Id, Policy__c> newDataMap, Map<Id, Policy__c> oldDataMap){
                                             this.oldDataList = oldDataList;
                                             this.newDataList = newDataList;
                                             this.newDataMap = newDataMap;
                                             this.oldDataMap = oldDataMap;
                                         }  

	public override void beforeInsert()	{
        //set initial premium value
		CommonPolicyUtil.setInitialPremiumValue(newDataList);
	}

    public override void beforeUpdate(){
        //set initial premium value
		CommonPolicyUtil.setInitialPremiumValue(newDataList);
    }

	
	public override void afterInsert(){}

	
	public override void afterUpdate(){
        //calls sync quote
        callSyncQuoteBatch(this.newDataList);
    }



	/*************************************************
    * Method Name: callSyncQuoteBatch
    * Author:
    * Date: 
    * Params: list<Policy__c>
    * Return: 
    * Exceptions:
    * Description: To make to call SyncQuoteQueueable class
    * Revision: 
     *************************************************/
    public static void callSyncQuoteBatch(List<Policy__c> newDataList){
       
        List<Quote> quotes  = QuoteQueryUtil.fetchQuotes_CEL(newDataList);

        // Will call MW with details of Quotes when Policy gets updated
        System.enqueueJob(new SyncQuoteQueueable(quotes));
    } 

}