/**************************************************************************************************
 * Class Name: AdditionalInterestTriggerHandler_CEL
 * Author: 
 * Date: 15th Dec 2021
 * Description: Handler for Celerity
 * Test Class: AdditionalInterestTriggerTest
 **************************************************************************************************/
public with sharing class AdditionalInterestTriggerHandler_CEL extends TriggerHandler{
    private List<Additional_Interests__c> oldDataList;
    private List<Additional_Interests__c> newDataList; 
    private Map<Id, Additional_Interests__c> newDataMap;
    private Map<Id, Additional_Interests__c> oldDataMap; 
    
    public AdditionalInterestTriggerHandler_CEL(List<Additional_Interests__c> newDataList, List<Additional_Interests__c> oldDataList, Map<Id, Additional_Interests__c> newDataMap, Map<Id, Additional_Interests__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

	public override void beforeInsert()	{
        //generate external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);

        //Check if the list of AdditionalInterest is existed, if existed add the error to prevent save it to DB
        CommonAdditionalInterestUtil.checkDuplicateAdditionalInterest(newDataList);
    }

    public override void beforeUpdate(){
        //generate external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
        
        // 06-19-2019 Quang Pham save old value of Account
        CommonAdditionalInterestUtil.setOldValueWhenAccountChanged(oldDataMap, newDataList);
    }

	public override void afterInsert(){

    }

	public override void afterUpdate(){

    }
    
    public override void beforeDelete() {
        //show validation when quote is 'Bound' or 'Bound Pending'
        CommonAdditionalInterestUtil.deleteValidationWhenQuoteLock(oldDataList);
    }
}