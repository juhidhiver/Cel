trigger AdditionalInsuredTrigger on Additional_Insured__c (after insert, before insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('AdditionalInsuredTrigger')){
        //new SanctionStatusTriggerBaseHandler().run();	
      
        AdditionalInsuredTriggerBaseHandler baseHanderObj = new AdditionalInsuredTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !AdditionalInsuredTriggerBaseHandler.isBypassed('AdditionalInsuredTriggerBaseHandler')){
            new AdditionalInsuredTriggerBaseHandler().run();  
        }
    }
}