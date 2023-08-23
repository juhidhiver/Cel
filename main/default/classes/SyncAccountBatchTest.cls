@isTest (SeeAllData = false)
private class SyncAccountBatchTest {
    @TestSetup
    static void setup() {
        //TestUtil.createQuoteOnOpportunity();
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = false;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        update setting;
        system.assert(setting != null);
        
        Account acc = TestUtil.createBusinessAccount('Account Test1', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
    }
    
    @isTest 
    static void SyncTest() {        
        Account accTest = [Select Id, Name,BillingCity from Account limit 1];
       //Set<Id> items = new Set<Id>();
      Map<Id,String> items = new Map<Id,String>();
        items.put(accTest.Id,accTest.Name);
        //items.add(accTest.Id);
        
        Test.startTest();
        SyncAccountBatch b = new SyncAccountBatch(items);
        String Jobid = Database.executeBatch(b,1);
        Test.stopTest();
        system.assertEquals('Account Test1', accTest.Name);
    }
}