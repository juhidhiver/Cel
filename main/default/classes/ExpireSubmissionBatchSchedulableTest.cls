@isTest public class ExpireSubmissionBatchSchedulableTest {
    static testmethod void testScheduledJob() {
        Test.startTest();
        ExpireSubmissionBatchSchedulable sche = new ExpireSubmissionBatchSchedulable();       
        String schTime = '20 30 8 10 2 ?';
        String jobID = System.schedule('Test Close Opportunity', schTime, sche); 
        Test.stopTest();
        System.assert(jobID != null);
    }
}