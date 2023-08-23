public class InsurerLayerLimitTriggerHandler extends TriggerHandler{
    private List<Insurer_Layer_Limit__c> oldDataList;
    private List<Insurer_Layer_Limit__c> newDataList;
    private Map<Id, Insurer_Layer_Limit__c> newDataMap;
    private Map<Id, Insurer_Layer_Limit__c> oldDataMap;

    public InsurerLayerLimitTriggerHandler() {
        this.oldDataList = (List<Insurer_Layer_Limit__c>) Trigger.old;
        this.oldDataMap = (Map<Id, Insurer_Layer_Limit__c>) Trigger.oldMap;
        
        this.newDataList = (List<Insurer_Layer_Limit__c>) Trigger.new;
        this.newDataMap = (Map<Id, Insurer_Layer_Limit__c>) Trigger.newMap;
    }
    public override void afterinsert(){
		updateStatusAfterInsert(newDataList);
    }
    public override void afterupdate(){
        updateQuoteStatusAQ(newDataList,oldDataMap);
    }
    public override void afterdelete(){
        updateStatusAfterInsert(oldDataList);
    }

    private static void updateQuoteStatusAQ(List<Insurer_Layer_Limit__c> insurerList,Map<Id, Insurer_Layer_Limit__c> olddataMap){
        set<string> quoteId = new set<string>();
        Boolean isChangeQuote = false;
        List<Quote> quoteList = new List<Quote>();
        
        for(Insurer_Layer_Limit__c insurer : insurerList) {
            quoteId.add(insurer.Quote__c);
            if(olddataMap.get(insurer.Id).Insurer_Layer_Limit__c != insurer.Insurer_Layer_Limit__c){
                isChangeQuote = true;  
            }
            quoteList = [select Id,Status from Quote where Id IN :quoteId AND (Status != 'Closed' AND Status != 'Rejected' AND Status != 'Bound')];
            
            if(!quoteList.isEmpty() && isChangeQuote){
                for(Quote quote : quoteList){
                    if(quote.status != 'In Progress') quote.status = 'In Progress';
                }
                update quoteList;
            }
            
        }
    }
    
    private static void updateStatusAfterInsert(List<Insurer_Layer_Limit__c> insurerList){
        set<string> quoteId = new set<string>();      
        List<Quote> quoteList = new List<Quote>();
        
        for(Insurer_Layer_Limit__c insurer : insurerList) {
            quoteId.add(insurer.Quote__c);
        }
        
        quoteList = [select Id,Status from Quote where Id IN :quoteId AND (Status != 'Closed' AND Status != 'Rejected' AND Status != 'Bound')];
        
        if(!quoteList.isEmpty()){
            for(Quote quote : quoteList){
                if(quote.status != 'In Progress') quote.status = 'In Progress';
            }
            update quoteList;
        }
        
    }
}