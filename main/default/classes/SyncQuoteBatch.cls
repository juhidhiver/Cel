/*************************************************
* Author: Saumyak
* Date: 02-November-2020
* Description: Call synchronization when QuoteTriggerHandler fired
* Revision: 
*************************************************/
global class SyncQuoteBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global final List<String> items {get;set;}
    
    global SyncQuoteBatch(List<Quote> items) {
        List<String> idList = new List<String>();
        for(Quote quo:items){
            idList.add(quo.Id);
        }
       
        this.items = idList;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> idList = this.items;
        String query = 'SELECT Id, Status, Name, Rating_Status__c,Accept_Terror_Premium__c,Endorsement_Quote_Bound_Date__c,' +
        ' Quote_Type__c,Non_Prorated_Quote_Premium__c, Parent_Quote__c, Product_Name__c, Opportunity.LastSource__c ,Opportunity.Id' +
        ' FROM Quote WHERE Id IN:idList AND Status != \'In Progress\'' ;
           return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Quote> listQuote) {
        List<Quote> cel_quote = new List<Quote>();
        List<Quote> aq_quote = new List<Quote>();
        
         for(Quote quo: listquote){
            if(quo.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                aq_quote.add(quo);
            }else{
                cel_quote.add(quo);
            }
        }
        if(!aq_quote.isEmpty()){
          SyncService.SyncServiceCall_AQ(aq_quote);
        }
        if(!cel_quote.isEmpty()){
          SyncService.SyncServiceCall_Cel(cel_quote);
        }
            
       
    }    
    
    public void finish(Database.BatchableContext info) {}
    
   
}