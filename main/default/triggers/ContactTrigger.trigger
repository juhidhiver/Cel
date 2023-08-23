trigger ContactTrigger on Contact (before insert, before update, after insert, after update, before delete, after undelete) {
	if(!CommonUtil.isTriggerBypass('ContactTrigger')){
				
        ContactTriggerBaseHandler baseHanderObj = new ContactTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !ContactTriggerBaseHandler.isBypassed('ContactTriggerBaseHandler')){
            new ContactTriggerBaseHandler().runBaseHandler();  
        }
	}
}