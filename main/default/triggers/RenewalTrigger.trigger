/**************************************************************************************************
 * Class Name: RenewalTrigger
 * Author: Mary Elizabeth
 * Date: 18-July-2022
 * Description: Trigger on object Renewal__c
 **************************************************************************************************/
trigger RenewalTrigger on Renewal__c (before insert, after insert, before update, after update) {
    if(!CommonUtil.isTriggerBypass('RenewalTrigger') && !GlobalStaticVar.byPassRenewalTrigger){
        RenewalTriggerHandler baseHanderObj = new RenewalTriggerHandler();
        baseHanderObj.run(); 
        if( !RenewalTriggerHandler.isBypassed('RenewalTriggerHandler')){
            new RenewalTriggerHandler().run();  
        }
    }
}