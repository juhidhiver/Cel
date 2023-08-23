/*oba*************************************************************************************************
* Class Name: SubjectivityTrigger
* Author: Sarthak Roy
* Created date: 17-Dec-2020
* Description: Trigger for Subjectivity__c Object
**************************************************************************************************/
trigger SubjectivityTrigger on Subjectivity__c (before update, before insert, before delete, after insert, after update, after delete) {
    if(!CommonUtil.isTriggerBypass('SubjectivityTrigger') && !GlobalStaticVar.byPassSubjectivityTrigger){
	 new SubjectivityTriggerBaseHandler().run();
        SubjectivityTriggerBaseHandler baseHanderObj = new SubjectivityTriggerBaseHandler();
        baseHanderObj.run(); 
        if( !SubjectivityTriggerBaseHandler.isBypassed('SubjectivityTriggerBaseHandler')){
            new SubjectivityTriggerBaseHandler().runBaseHandler();  
        }
    }
}