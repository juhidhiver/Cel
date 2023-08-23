/**************************************************************************************************
* Class Name: UWAnalysisTrigger
* Author: Sarthak Roy
* Created date: 06-April-2021
* Description: Trigger for UWAnalysisTrigger Object
**************************************************************************************************/
trigger UWAnalysisTrigger on UW_Analysis__c (after insert, after update, after delete) {
    if(/*!CommonUtil.isTriggerBypass('FreeFormEndorsementTrigger') &&*/ !GlobalStaticVar.byPassUWAnalysisTrigger){
        new UWAnalysisTriggerHandler().run();
       }
}