/**************************************************************************************************
 * Class Name: PolicyTrigger
 * Author: Phuc Ha
 * Date: 15-May-2020
 * Description: Trigger on object Policy__c
 **************************************************************************************************/
trigger PolicyTrigger on Policy__c (before insert, after insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('PolicyTrigger')){
       
        PolicyTriggerBaseHandler baseHanderObj = new PolicyTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !PolicyTriggerBaseHandler.isBypassed('PolicyTriggerBaseHandler')){
            new PolicyTriggerBaseHandler().runBaseHandler();  
        }
    }
}