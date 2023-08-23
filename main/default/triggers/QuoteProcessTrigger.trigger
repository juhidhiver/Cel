trigger QuoteProcessTrigger on Quote_Process__c (after insert, before insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('QuoteProcessTrigger')){
        QuoteProcessTriggerBaseHandler baseHanderObj = new QuoteProcessTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !QuoteProcessTriggerBaseHandler.isBypassed('QuoteProcessTriggerBaseHandler')){
            new QuoteProcessTriggerBaseHandler().runBaseHandler();  
        }
    }
}