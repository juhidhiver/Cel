Trigger AdditionalInterestTrigger on Additional_Interests__c (before insert, after insert, before update, after update, before delete) {
    if(!CommonUtil.isTriggerBypass('AdditionalInterestTrigger')){
        
        AdditionalInterestTriggerBaseHandler baseHanderObj = new AdditionalInterestTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !AdditionalInterestTriggerBaseHandler.isBypassed('AdditionalInterestTriggerBaseHandler')){
            new AdditionalInterestTriggerBaseHandler().runBaseHandler();  
        }
    }
	/*
	{
		AdditionalInterestTriggerHandler handler = new AdditionalInterestTriggerHandler();
		switch on Trigger.operationType {
			when BEFORE_INSERT {
				CommonUtil.generateExternalID('Azure_ID__c', Trigger.new);
			   	handler.checkDuplicateAdditionalInterest(Trigger.new);
			}
			when BEFORE_UPDATE {
				CommonUtil.generateExternalID('Azure_ID__c', Trigger.new);
			}
			when BEFORE_DELETE {
				AdditionalInterestTriggerHandler.deleteValidationWhenQuoteLock(Trigger.old);
			}
		}
	}
	*/
}