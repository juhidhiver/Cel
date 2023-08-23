@isTest
public class QueuablePolicyDocumentGenerate_Test {
    @testsetup
    public static void init() {
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        acc.Review_Requested_By__c = UserInfo.getUserId();
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product;   
        
        Opportunity oppaq = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.AccountId=acc.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = product.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        insert oppaq;
        
        //String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policyaq = new Policy__c();
        policyaq.Account__c = acc.Id; 
        policyaq.Expiration_Date__c = Date.today().addDays(10);
        insert policyaq;
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',oppaq.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Bound';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = oppaq.Id;
        quote.Policy__c = policyaq.Id;
        quote.Rating_Status__c = 'Clear';
        quote.Endorsement_Effective_Date__c = date.parse('08/04/2021');
        quote.Binder__c = 'Current Year Binder';
        // quote.Endorsement_Type__c='New Business' - date.parse('08/08/2021');
        insert quote;
        
    } 
    
    @isTest
    static void testGetInitData1() {
        
        Test.setMock(HttpCalloutMock.class, new GenericSybcApiMockResponse());
            
        ID accountId = [SELECT Id FROM Account limit 1].Id;
        ID policyId = [SELECT Id FROM Policy__c limit 1].Id;
        
        List<Quote> lstQuote = [Select Id,QuoteNumber,Quote_Type__c,Binder__c,Master_Binder__c,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, 
                                Azure_Id__c,Rating_Status__c,Layer__c from Quote where Policy__c=:policyId And Status='Bound' 
                                AND Opportunity.RecordType.Name =: 'Aqueous' And Rating_Status__c='Clear' And Binder__c!=null
                                order by Endorsement_Quote_Bound_Date__c desc limit 1];
        System.debug('lstQuote 1: '+Limits.getQueueableJobs());
        
        Test.startTest();
        System.enqueueJob(new QueuablePolicyDocumentGenerate(accountId,policyId));
        
        Test.stopTest();
        
    }
    
    
    
    public class GenericSybcApiMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('success');
            res.setStatusCode(200);
            return res;
        }
    }
    
}