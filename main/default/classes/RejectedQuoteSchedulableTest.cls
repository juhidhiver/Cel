@isTest public class RejectedQuoteSchedulableTest {
 static testmethod void testScheduledJob() {
        Test.startTest();
        RejectedQuoteSchedulable sche = new RejectedQuoteSchedulable();       
        String schTime = '20 30 8 10 2 ?';
        String jobID = System.schedule('Test Close Quote', schTime, sche); 
        Test.stopTest();
        System.assert(jobID != null);
    }
}