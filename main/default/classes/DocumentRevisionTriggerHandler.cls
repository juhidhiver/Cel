public class DocumentRevisionTriggerHandler extends TriggerHandler{
    
    private List<Document_Revision__c> oldDataList;
    private List<Document_Revision__c> newDataList;
    private Map<Id, Document_Revision__c> newDataMap;
    private Map<Id, Document_Revision__c> oldDataMap;
    
    public DocumentRevisionTriggerHandler (){
        this.oldDataList = (List<Document_Revision__c>) Trigger.old;
        this.newDataList = (List<Document_Revision__c>) Trigger.new;
        this.newDataMap = (Map<Id, Document_Revision__c>) Trigger.newMap;
        this.oldDataMap = (Map<Id, Document_Revision__c>) Trigger.oldMap;
    }
    
    public override void beforeInsert() {
        
    }
    public override void afterInsert(){
        callSyncQuoteBatch(this.newDataList);
    }
    
    public override void beforeUpdate() {
        
    }
    
    public override void afterUpdate() {
        callSyncQuoteBatch(this.newDataList);
    }    
    
    public static void callSyncQuoteBatch(List<Document_Revision__c> newDataList){
        Set<String> quoteIds  = new Set<String>();
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
        for(Quote q : [select Id, Status, Name, Rating_Status__c,Endorsement_Quote_Bound_Date__c,
                       Quote_Type__c, Parent_Quote__c, Product_Name__c, Opportunity.Id 
                       from Quote where (Product_Name__c = 'MPL Standalone' OR Product_Name__c = 'Cyber Standalone') and (id in :quoteIds )
                       and (Status != 'In Progress' and Status != 'Rated')]){
                           quotes.add(q);
                       }

        System.enqueueJob(new SyncQuoteQueueable(quotes));
    }    
}