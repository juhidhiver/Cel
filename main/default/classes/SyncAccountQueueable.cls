/*************************************************
* Author: Saumyak
* Date: 29-Oct-2020
* Description: Call synchronization when AccountTriggerHandler fired - SF to MW Sync
*************************************************/
global class SyncAccountQueueable implements Queueable {    
    global final Map<Id, String> accountIds  {get;set;}
    
    global SyncAccountQueueable(Map<Id, String> accountIds) {
        this.accountIds = accountIds;
    }
    
    public void execute(QueueableContext context) {
       SyncAccountBatch syncAccountBatch = new SyncAccountBatch(accountIds);
       Database.executeBatch(syncAccountBatch, 1);
    }  
}