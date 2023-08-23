/**************************************************************************************************
 * Class Name: DocumentRevisionTriggerHandler_CEL
 * Author: Vinay
 * Date: 24th Dec 2021
 * Description: Class to keep document revision methods
 * Test Class : 
 **************************************************************************************************/
public with sharing class DocumentRevisionTriggerHandler_CEL extends TriggerHandler{
    private List<Document_Revision__c> oldDataList;
    private List<Document_Revision__c> newDataList; 
    private Map<Id, Document_Revision__c> newDataMap;
    private Map<Id, Document_Revision__c> oldDataMap; 
    
    public DocumentRevisionTriggerHandler_CEL(List<Document_Revision__c> newDataList, List<Document_Revision__c> oldDataList, Map<Id, Document_Revision__c> newDataMap, Map<Id, Document_Revision__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    }  

    public override void beforeInsert()	{

    }

    public override void beforeUpdate(){

    }

	public override void afterInsert(){
        callSyncQuoteBatch(this.newDataList);
    }

	public override void afterUpdate(){
        callSyncQuoteBatch(this.newDataList);
    }

    /*************************************************
    * Method Name: callSyncQuoteBatch
    * Author: 
    * Date: 
    * Params: List<Document_Revision__c>
    * Return: 
    * Description: Sync quotes when document revision type is set as "Quote Proposal"
     *************************************************/
    public static void callSyncQuoteBatch(List<Document_Revision__c> newDataList){
        Set<Id> quoteIds  = new Set<Id>();
        List<Quote> quotes  = new List<Quote>();
        
        for(Document_Revision__c doc :newDataList){
                if(String.isNotBlank(doc.Quote_Id__c))
                {
                    if(doc.Document_Type__c =='QuoteProposal')
                	{                       
                    	quoteIds.add(doc.Quote_Id__c);
                    }
                }            
        }
        for(Quote q : QuoteQueryUtil.fetchCyberMPLQuotesByQuoteIDs(quoteIds)){
            quotes.add(q);
        }

        System.enqueueJob(new SyncQuoteQueueable(quotes));
    } 
}