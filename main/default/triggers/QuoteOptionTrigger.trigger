trigger QuoteOptionTrigger on Quote_Option__c (after insert, before insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('QuoteOptionTrigger')){
        new QuoteOptionTriggerHandler().run();    
    }
}