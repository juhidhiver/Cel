/***************************************************************************************************
	class: RatingModifiersTriggerHandler
	created date: 18-Sep-2019
	created by: Hoang Bui
***************************************************************************************************/
public with sharing class RatingModifiersTriggerHandler extends TriggerHandler {
	private List<Rating_Modifiers__c> oldDataList;
	private List<Rating_Modifiers__c> newDataList;
	private Map<Id, Rating_Modifiers__c> newDataMap;
	private Map<Id, Rating_Modifiers__c> oldDataMap;
    public RatingModifiersTriggerHandler (){  
		this.oldDataList = (List<Rating_Modifiers__c>) Trigger.old;
		this.newDataList = (List<Rating_Modifiers__c>) Trigger.new;
		this.newDataMap = (Map<Id, Rating_Modifiers__c>) Trigger.newMap;
		this.oldDataMap = (Map<Id, Rating_Modifiers__c>) Trigger.oldMap;
	}

	public override void beforeInsert()	{
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);		
	}

	public override void beforeUpdate() {
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);	
    }
	public override void afterUpdate() {
		//OpportunityModifiersCmpController.updateQuoteStatus(newDataList);
	}
	public override void afterInsert() {
	}


}