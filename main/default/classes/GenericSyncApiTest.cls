/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 09-17-2021
 * @last modified by  : Maeran Shaikh
**/
@isTest
public with sharing class GenericSyncApiTest {
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
        
        Product2 product = TestUtil.createProduct('MPL');
        
        insert product;
        
        Id pricebook2Id = Test.getStandardPricebookId();
        PricebookEntry pricebookEntryEquipment =  TestUtil.createPricebookEntry(pricebook2Id, product.Id);
        insert pricebookEntryEquipment;
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test', acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        insert opportunity;
        List<Quote> quotes = new List<Quote>();
        for(Integer i=0 ; i<=100 ;i++){
            Quote q = new Quote(Name = 'Test ' + i,OpportunityId =opportunity.Id,Status = 'In Progress');
            quotes.add(q);
        }
        insert  quotes;
        
    }
    @isTest 
    static void getGenericSyncApiTest() {
        Quote quoteTest = [Select Id, Status, Quote_Type__c, Parent_Quote__c, AccountId, OpportunityId from Quote limit 1];
        
        Quote q = new Quote(Name = 'Test',OpportunityId =quoteTest.OpportunityId,Status = 'Bound');
        insert q;
        
        Contract contractTest = new Contract();
        contractTest.AccountId = quoteTest.AccountId;
        insert contractTest;
        quoteTest.Status = 'In Progress';
        quoteTest.Parent_Quote__c = q.Id;
        quoteTest.Quote_Type__c = 'Extension';
        quoteTest.ContractId = contractTest.Id;
        update quoteTest;
        
        Document_Revision__c docTest = new Document_Revision__c();
        docTest.Name = 'Test';
        docTest.Quote_Id__c = quoteTest.Id;
        insert docTest;
        
        Quote updatedQuote = [Select Id, Status, ContractId, Quote_Type__c, Parent_Quote__c from Quote where Id =: quoteTest.Id];
        updatedQuote.Status = 'Bound';
        update updatedQuote;
        
        List<Quote> items = new List<Quote>();
        items.add(updatedQuote);
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        Test.startTest();
        API_Log__c res = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', updatedQuote, 'functionName');
        Test.stopTest();
        system.assert(res != null);
        system.assertEquals('Bound', updatedQuote.Status);
    }
}