@isTest
private class SyncQuoteBatchTest {
    @TestSetup
    static void setup() {
        Test.startTest();
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = false;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        update setting;
        system.assert(setting != null);
        
        Account acc = TestUtil.createBusinessAccount('Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('Cyber Standalone');
        insert product;
        
        Product2 product2 = TestUtil.createProduct('Professional Indemnity');
        insert product2;
        
        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Test';
        opportunity.CloseDate = Date.today()+365;
        opportunity.StageName = 'Qualified';
        opportunity.LastSource__c = 'UnderWriter';
        opportunity.Product__c = product.id;
        insert opportunity;
        
        Opportunity opportunity2 = new Opportunity();
        opportunity2.Name = 'Test';
        opportunity2.CloseDate = Date.today()+365;
        opportunity2.StageName = 'Qualified';
        opportunity2.LastSource__c = 'UnderWriter';
        opportunity2.Product__c = product2.id;
        insert opportunity2;
       
        
        List<Quote> quotes = new List<Quote>();
        for(Integer i=0 ; i<=100 ;i++){
            Quote q = new Quote(Name = 'Test ' + i,OpportunityId =opportunity.Id,Status = 'In Progress');
            Quote q2 = new Quote(Name = 'Test ' + i+1,OpportunityId =opportunity2.Id,Status = 'In Progress');
            quotes.add(q);
            quotes.add(q2);
        }
        insert  quotes;
        Test.stopTest();
    }
    
    @isTest 
    static void SyncQuoteBatchTest() {
        Test.startTest();
        Quote quoteTest = [Select Id, Status, Parent_Quote__c, AccountId from Quote limit 1];
        quoteTest.Status = 'In Progress';
        update quoteTest;
        
        Quote quoteTest2 = [Select Id,Status,ContractId,Parent_Quote__c,Quote_Type__c from Quote where Id =: quoteTest.Id];
        quoteTest2.Status = 'Bound';
        update quoteTest2;
        
        List<Quote> items = new List<Quote>();
        items.add(quoteTest2);
        
       
        SyncQuoteBatch b = new SyncQuoteBatch(items);
        String Jobid = Database.executeBatch(b);
        Test.stopTest();
        system.assertEquals('In Progress', quoteTest.Status);
    }
    
     @isTest 
    static void SyncQuoteBatchTest_Cel() {
        Test.startTest();
        
       
        Quote quoteTest = [Select Id, Status, Parent_Quote__c, AccountId,Product_Name__c from Quote where Product_Name__c=: 'Cyber Standalone' limit 1];
        quoteTest.Status = 'In Progress';
        update quoteTest;
        
        Quote quoteTest2 = [Select Id,Status,ContractId,Parent_Quote__c,Quote_Type__c from Quote where Id =: quoteTest.Id];
        quoteTest2.Status = 'Bound';
        update quoteTest2;
        
        List<Quote> items = new List<Quote>();
        items.add(quoteTest2);
        
       
        SyncQuoteBatch b = new SyncQuoteBatch(items);
        String Jobid = Database.executeBatch(b);
        system.assertEquals('In Progress', quoteTest.Status);
        
        //HttpRequest req = new HttpRequest();
        //HttpResponse res = new HttpResponse();       
        //ApiUtil.createLogAPICall(req, res, 'Sync Quote Status','SyncQuoteBatch','Quote_Sync', 'Outbound');
        Test.stopTest();
    }
    
     @isTest 
    static void SyncQuoteBatchTest_AQ() {
        Test.startTest();
        
        Quote quoteTest = [Select Id, Status, Parent_Quote__c, AccountId ,Product_Name__c from Quote where Product_Name__c =: 'Professional Indemnity' limit 1];
        quoteTest.Status = 'In Progress';
        update quoteTest;
        
        Quote quoteTest2 = [Select Id,Status,ContractId,Parent_Quote__c,Quote_Type__c from Quote where Id =: quoteTest.Id];
        quoteTest2.Status = 'Bound';
        update quoteTest2;
        
        List<Quote> items = new List<Quote>();
        items.add(quoteTest2);
        
       
        SyncQuoteBatch b = new SyncQuoteBatch(items);
        String Jobid = Database.executeBatch(b);
        system.assertEquals('In Progress', quoteTest.Status);
       
        Test.stopTest();
    }
}