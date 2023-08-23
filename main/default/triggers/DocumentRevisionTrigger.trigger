Trigger DocumentRevisionTrigger on Document_Revision__c (before insert, after insert, before update, after update)  {
    if(!CommonUtil.isTriggerBypass('DocumentRevisionTrigger')){
       new DocumentRevisionTriggerBaseHandler().run();
        DocumentRevisionTriggerBaseHandler baseHanderObj = new DocumentRevisionTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !DocumentRevisionTriggerBaseHandler.isBypassed('DocumentRevisionTriggerBaseHandler')){
            new DocumentRevisionTriggerBaseHandler().runBaseHandler();  
        }
    }	
}