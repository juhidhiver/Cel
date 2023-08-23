/**************************************************************************************************
 * Class Name: CoverageLineItemTrigger
 * Author: Hoang Bui
 * Date: 18-Sep-19
 * Description: Trigger on object CoveragesLineItem__c
 **************************************************************************************************/
trigger CoverageLineItemTrigger on CoveragesLineItem__c (before insert,after delete, before update, after insert, after update) {
    if(!CommonUtil.isTriggerBypass('CoverageLineItemTrigger') && !GlobalStaticVar.byPassCoverageLineItemTrigger){
        
        CoverageLineItemTriggerBaseHandler baseHanderObj = new CoverageLineItemTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !CoverageLineItemTriggerBaseHandler.isBypassed('CoverageLineItemTriggerBaseHandler')){
            new CoverageLineItemTriggerBaseHandler().runBaseHandler();  
        }
    }
}