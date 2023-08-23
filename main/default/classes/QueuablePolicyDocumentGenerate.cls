public class QueuablePolicyDocumentGenerate implements Queueable,Database.AllowsCallouts {
    
    public string policyId; 
    public string accountId; 
    
    public QueuablePolicyDocumentGenerate(String accountId,String policyId){
       this.policyId = policyId;
       this.accountId = accountId;
    }
    
    public void execute(QueueableContext context) {
        
        List<Quote> lstQuote = [Select Id,QuoteNumber,Quote_Type__c,Binder__c,Master_Binder__c,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, 
                                Azure_Id__c,Rating_Status__c,Layer__c from Quote where Policy__c=:policyId And Status='Bound' 
                                AND Opportunity.RecordType.Name =: 'Aqueous' And Rating_Status__c='Clear' And Binder__c!=null
                                order by Endorsement_Quote_Bound_Date__c desc limit 1];
        
        GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', lstQuote[0], 'PreDocGenerationSync_Synchronous'); // PreSync before Finalize  
        /*** Sync Call to generate Document***/
        GenerateDocumentApiHandler.GenerateResult genresult =  NewEndorsementAQController.generateDocOnPolicy(lstQuote[0],policyId);
        
        if(Limits.getQueueableJobs() == 1 || Test.isRunningTest()){
            String hour = String.valueOf(Datetime.now().hour());
            String min = String.valueOf(Datetime.now().minute()); 
            String ss = String.valueOf(Datetime.now().second() + 1);
            system.debug('hour'+hour);
            system.debug('min'+min);
            system.debug('ss'+ss);
            //parse to cron expression
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
            System.schedule('ScheduleSyncCalloutForPolicyGenerate' + String.valueOf(Math.random()), nextFireTime, new SchedulePolicyDocument(accountId,policyId));
        }else{
            System.enqueueJob(new QueuablePolicyDocumentSync(accountId,policyId));
        }
        
        //Chaining Another Queuebale that make sync callout and send email
      // System.enqueueJob(new QueuablePolicyDocumentSync(accountId,policyId));
        
    }
  
}