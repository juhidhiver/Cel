@isTest
public class DemoLightningFlowControllerTest {
	@testSetup
    public static void setup() {
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;              	
        
        // create product
        Product2 product = TestUtil.createProduct('Test Product');
        insert product;
        
        // create opportunity        
        Opportunity opp = TestUtil.createOpportunity('Test Opportunity', accBroker.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
    }
    
    @isTest
    public static void testCreateOpportunity() {
        Opportunity opp = [SELECT id,AccountId,Product__c FROM Opportunity LIMIT 1];
        try {
            DemoLightningFlowController.createOpportunity(new List<Opportunity>{opp});
        }
        catch(Exception ex) {
            
        }
    }
}