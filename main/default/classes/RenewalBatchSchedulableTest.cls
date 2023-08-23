@isTest 
public class RenewalBatchSchedulableTest {
         static testmethod void testQueueable() {
         Test.startTest();
         RenewalBatchSchedulable rb = new RenewalBatchSchedulable();
         rb.execute(null);
         Test.stopTest();
         system.assert([Select Id from AsyncApexJob] != null);
     }
}