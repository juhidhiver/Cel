/**************************************************************************************************
 * Class Name: DocumentRevisionTriggerBaseHandler
 * Author: 
 * Date: 
 * Description: Base Handler for Content Document Link
 **************************************************************************************************/
public class DocumentRevisionTriggerBaseHandler extends TriggerHandler{
    private List<Document_Revision__c> oldDataList;
    private List<Document_Revision__c> newDataList; 
    private Map<Id, Document_Revision__c> newDataMap;
    private Map<Id, Document_Revision__c> oldDataMap;

    public void runBaseHandler(){        
        oldDataList = (List<Document_Revision__c>)Trigger.old;
        newDataList = (List<Document_Revision__c>)Trigger.new;
        newDataMap = (Map<Id, Document_Revision__c>)Trigger.newMap;
        oldDataMap = (Map<Id, Document_Revision__c>)Trigger.oldMap;
        new DocumentRevisionTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
    }  
}