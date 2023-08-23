/**************************************************************************************************
 * Class Name: ContentDocumentLinkTriggerBaseHandler
 * Author: 
 * Date: 
 * Description: Base Handler for Content Document Link
 **************************************************************************************************/
public class ContentDocumentLinkTriggerBaseHandler extends TriggerHandler{
    private List<ContentDocumentLink> oldDataList;
    private List<ContentDocumentLink> newDataList; 
    private Map<Id, ContentDocumentLink> newDataMap;
    private Map<Id, ContentDocumentLink> oldDataMap;

    public void runBaseHandler(){        
        oldDataList = (List<ContentDocumentLink>)Trigger.old;
        newDataList = (List<ContentDocumentLink>)Trigger.new;
        newDataMap = (Map<Id, ContentDocumentLink>)Trigger.newMap;
        oldDataMap = (Map<Id, ContentDocumentLink>)Trigger.oldMap;
        new ContentDocumentLinkTriggerHandler_CEL(newDataList, oldDataList, newDataMap, oldDataMap).run();
    }  
}