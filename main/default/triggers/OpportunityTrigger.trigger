/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 12-29-2021
 * @last modified by  : Vinayesh
**/
trigger OpportunityTrigger on Opportunity (after insert, before insert, before update, after update, before delete, after delete) {
    //if(Trigger.new[0].Azure_ID__c == '8d28d956-022c-4cac-ac2c-4311bf2aa1f0') return;
    if(!CommonUtil.isTriggerBypass('OpportunityTrigger') && !GlobalStaticVar.byPassOpportunityTrigger){
        system.debug('InsideOpportunityTriggerInbeforeInsert');
        //new OpportunityTriggerHandler().run(); 
       // new SubmissionTriggerBaseHandler().run();  
        SubmissionTriggerBaseHandler baseHanderObj = new SubmissionTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !SubmissionTriggerBaseHandler.isBypassed('SubmissionTriggerBaseHandler')){
            new SubmissionTriggerBaseHandler().runBaseHandler();  
        }
    }
}