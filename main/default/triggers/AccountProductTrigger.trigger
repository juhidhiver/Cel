trigger AccountProductTrigger on Account_Product__c (after insert, before insert, before update, after update) {

    if(!CommonUtil.isTriggerBypass('AccountProductTrigger') && !GlobalStaticVar.byPassAccountProductTrigger){
       
        AccountProductTriggerBaseHandler baseHanderObj = new AccountProductTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !AccountProductTriggerBaseHandler.isBypassed('AccountProductTriggerBaseHandler')){
            new AccountProductTriggerBaseHandler().runBaseHandler();  
        }

       } 
    }