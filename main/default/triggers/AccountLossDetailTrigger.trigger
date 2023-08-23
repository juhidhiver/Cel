/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-03-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-03-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
trigger AccountLossDetailTrigger on Account_Loss_Detail__c (after insert, before insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('AccountLossDetailTrigger')){
            
        AccountLossDetailTriggerBaseHandler baseHanderObj = new AccountLossDetailTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !AccountLossDetailTriggerBaseHandler.isBypassed('AccountLossDetailTriggerBaseHandler')){
            new AccountLossDetailTriggerBaseHandler().runBaseHandler();  
        }
        
    }
}