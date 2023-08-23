/*************************************************
* Author: Saumyak
* Date: 02-November-2020
* Description: Call synchronization when QuoteTriggerHandler fired
* Revision: 
*************************************************/
global class SyncQuoteQueueable implements System.Queueable,Database.AllowsCallouts {
    
    global final List<Quote> listQuote {get; set;}
    
    global SyncQuoteQueueable(List<Quote> listQuote){
        this.listQuote = listQuote;
    }
    
    public void execute(QueueableContext info){
        SyncQuoteBatch syncQuoteBatch = new SyncQuoteBatch(listQuote);
        Database.executeBatch(syncQuoteBatch, 1);
    }
}