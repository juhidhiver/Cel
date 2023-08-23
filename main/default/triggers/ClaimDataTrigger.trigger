/**************************************************************************************************
 * Class Name: ClaimDataTrigger
 * Author: Mary Elizabeth
 * Date: 18-July-2022
 * Description: Trigger on object Renewal__c
 **************************************************************************************************/
trigger ClaimDataTrigger on Claim_Data__c (before insert, after insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('ClaimDataTrigger')){
        ClaimDataTriggerHandler baseHanderObj = new ClaimDataTriggerHandler();
        baseHanderObj.run(); 
        if(!ClaimDataTriggerHandler.isBypassed('ClaimDataTriggerHandler')){
            new ClaimDataTriggerHandler().run();
        }
    }
}