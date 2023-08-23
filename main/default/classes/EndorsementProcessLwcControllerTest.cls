@isTest
public class EndorsementProcessLwcControllerTest {
	@testSetup
    private static void setup() {
        Policy__c policy = new Policy__c();
        policy.Policy_Status__c = 'Active';
        policy.Policy_Number__c = 'POLTEST';
        policy.Effective_Date__c = Date.today().addMonths(2);
        policy.Expiration_Date__c = Date.today().addMonths(1);
        policy.Total_Premium__c = 2000;
        insert policy;
    }
    
    @isTest
    public static void testGetPolicyList() {
        List<EndorsementProcessLwcController.ItemWrapper> result = EndorsementProcessLwcController.getPolicyList('POL');
        System.assertEquals(2000, result[0].Total_Premium);
        
    }
}