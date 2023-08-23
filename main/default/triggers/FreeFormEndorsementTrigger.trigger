/**************************************************************************************************
* Class Name: FreeFormEndorsementTrigger
* Author: Sarthak Roy
* Created date: 24-March-2021
* Description: Trigger for Free_Form_Endorsements__c Object
**************************************************************************************************/
trigger FreeFormEndorsementTrigger on Free_Form_Endorsements__c ( after insert, after update, after delete) {
    if(!CommonUtil.isTriggerBypass('FreeFormEndorsementTrigger') && !GlobalStaticVar.byPassFreeFormEndorsementTrigger){
        
        FreeFormEndorsementTriggerBaseHandler baseHanderObj = new FreeFormEndorsementTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !FreeFormEndorsementTriggerBaseHandler.isBypassed('FreeFormEndorsementTriggerBaseHandler')){
            new FreeFormEndorsementTriggerBaseHandler().runBaseHandler();  
        }
    }
}