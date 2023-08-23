/**************************************************************************************************
 * Class Name: RatingModifiersTriggerHandler_Other
 * Author: 
 * Date: 
 * Description: Class to keep method related to products other than PCC, MPL, Prof Idemnity and EPL
 * Test Class : RatingModifiersTriggerHandlerTest
 **************************************************************************************************/
public with sharing class RatingModifiersTriggerHandler_Other extends TriggerHandler {
    private List<Rating_Modifiers__c> oldDataList;
    private List<Rating_Modifiers__c> newDataList; 
    private Map<Id, Rating_Modifiers__c> newDataMap;
    private Map<Id, Rating_Modifiers__c> oldDataMap; 
    
    public RatingModifiersTriggerHandler_Other(List<Rating_Modifiers__c> newDataList, List<Rating_Modifiers__c> oldDataList, Map<Id, Rating_Modifiers__c> newDataMap, Map<Id, Rating_Modifiers__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

    public override void beforeInsert()	{
        //generate external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

    public override void beforeUpdate(){
        //generate external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

	public override void afterInsert(){

    }

	public override void afterUpdate(){
        //if proposal form date is empty, create a subjectivity record
        //CommonRatingModifiersUtil.createSubjectivityIfProposalFormDateEmpty(newDataList);
    }
}