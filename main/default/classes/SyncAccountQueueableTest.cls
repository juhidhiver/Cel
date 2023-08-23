/*************************************************
* Author: Saumyak
* Date: 10-November-2020
* Description: Call synchronization when AccountTriggerHandler fired - SF to MW Sync
*************************************************/
@isTest
private class SyncAccountQueueableTest {
	@TestSetup
	public static void setupData(){
		TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassOpportunityTrigger__c = false;
		setting.BypassAccountTrigger__c = true;
		setting.BypassProductTrigger__c = true;
		update setting;
        system.assert(setting != null);
		Account acc = TestUtil.createBusinessAccount('Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
	}
    
	@isTest 
	static void SyncAccountQueueableTest() {
        Account accTest = [Select Id, Name,BillingCity from Account limit 1];
        
        accTest.BillingCity = 'Test';
		update accTest;
        
		//Set<Id> items = new Set<Id>();
		//items.add(accTest.Id);
          Map<Id,String> items = new Map<Id,String>();
        items.put(accTest.Id,accTest.Name);
		
        Test.startTest();
        String Jobid = System.enqueueJob(new SyncAccountQueueable(items));  
        Test.stopTest();
        system.assert(Jobid != null);
        system.assertEquals('Test', accTest.BillingCity);
    }
}