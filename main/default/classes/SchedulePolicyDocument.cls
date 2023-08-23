public class SchedulePolicyDocument implements Schedulable {
    public string policyId; 
    public string accountId; 
    
    public SchedulePolicyDocument(String accountId,String policyId){
        this.policyId = policyId;
        this.accountId = accountId;
    }

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new QueuablePolicyDocumentSync(accountId,policyId));
        // Abort the job once the job is queued
        System.abortJob(sc.getTriggerId());
    }
}