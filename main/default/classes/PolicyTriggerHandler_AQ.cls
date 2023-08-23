/**************************************************************************************************
 * Class Name: PolicyTriggerHandler_AQ
 * Author: 
 * Date: 
 * Description: Class to keep Aqueous related  common methods
 * Test Class: PolicyTriggerTest
 **************************************************************************************************/
public class PolicyTriggerHandler_AQ extends TriggerHandler {
    private List<Policy__c> oldDataList;
    private List<Policy__c> newDataList; 
    private Map<Id, Policy__c> newDataMap;
    private Map<Id, Policy__c> oldDataMap; 
    
    public PolicyTriggerHandler_AQ(List<Policy__c> newDataList, List<Policy__c> oldDataList, 
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

	
    
	public override void afterUpdate(){}
}