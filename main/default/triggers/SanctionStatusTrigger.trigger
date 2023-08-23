trigger SanctionStatusTrigger on Sanction_Status__c (after insert, before insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('SanctionStatusTrigger')){
        //new SanctionStatusTriggerBaseHandler().run();	
      
        SanctionStatusTriggerBaseHandler baseHanderObj = new SanctionStatusTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !SanctionStatusTriggerBaseHandler.isBypassed('SanctionStatusTriggerBaseHandler')){
            new SanctionStatusTriggerBaseHandler().runBaseHandler();  
        }
    }
}