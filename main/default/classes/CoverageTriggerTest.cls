@isTest
public class CoverageTriggerTest {
	
    @isTest
    public static void testCoverage() {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        System.assertEquals(true,setting.BypassCoverageTrigger__c);
        setting.BypassCoverageTrigger__c = false;
		update setting;
        
        //Create coverage
		Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
		insert cov1;
        
        cov1.Coverage_Product__c = 'Cyber';
        update cov1;
    }
}