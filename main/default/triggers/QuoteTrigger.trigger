trigger QuoteTrigger on Quote (after insert, before insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('QuoteTrigger') && !GlobalStaticVar.byPassQuoteTrigger){
        //new QuoteTriggerHandler().run();	
      
        QuoteTriggerBaseHandler baseHanderObj = new QuoteTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !QuoteTriggerBaseHandler.isBypassed('QuoteTriggerBaseHandler')){
            new QuoteTriggerBaseHandler().runBaseHandler();  
        }
    }
}