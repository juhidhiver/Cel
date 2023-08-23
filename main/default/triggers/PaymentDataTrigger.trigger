trigger PaymentDataTrigger on Payment_Data__c (after insert, before insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('PaymentDataTrigger')){
       	
        PaymentDataTriggerHandler baseHanderObj = new PaymentDataTriggerHandler();
        baseHanderObj.run(); 
        if( !PaymentDataTriggerHandler.isBypassed('PaymentDataTriggerHandler')){
            new PaymentDataTriggerHandler().run();  
        }
    }
}