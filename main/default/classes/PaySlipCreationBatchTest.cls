@isTest
public with sharing class PaySlipCreationBatchTest {
    @TestSetup
    static void makeData(){
        // Create provider
        // Account provider = TestDataFactory.createPensionProvider();
        // insert provider;
        // System.debug('==Provider Id==' + provider.Id);
    }
    @IsTest 
    static void testPaySlipCreationBatch(){
        // Account provider = [SELECT Id FROM Account WHERE Name =: TestDataFactory.PENSION_PROVIDER_NAME LIMIT 1];
        // System.debug('==Provider Id==' + provider.Id);

        // PaySlipCreationBatch paySlipBatch = new PaySlipCreationBatch(provider.Id);

        Test.startTest();
        // Database.executeBatch(paySlipBatch);
        Test.stopTest();
    }
}