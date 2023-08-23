@isTest
public class fullCancellationTest {
    
        @testSetup 
    static void createData(){
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        update setting;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product;   
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';                            
        opp.Product__c = product.Id;
        opp.Submission_Status__c = 'Quoted';
        opp.Transaction_Status__c = 'Active';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
		insert opp;      
      
        //Vivek        
        Quote_Process__c obj =  new Quote_Process__c();
            obj.Record_Type__c = 'Aqueous';
            obj.Product__c = 'Professional Indemnity';           
            obj.Submission__c = opp.Id;
            insert obj;
       
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
           Policy__c policy = new Policy__c();
           policy.Account__c = acc.Id; 
           policy.Expiration_Date__c = Date.today().addDays(100);
           insert policy;
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Quoted';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = opp.Id;
        quote.Policy__c = policy.Id;
        quote.Quote_Type__c='New Business';
        quote.Effective_Date__c= date.today();
        quote.Endorsement_Effective_Date__c = System.today() + 5;
       // quote.Endorsement_Type__c='New Business' - date.parse('08/08/2021');
        insert quote;
        
         Quote quote1 = TestUtil.createQuote('New Quote',opp.Id);
        quote1.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote1.Status = 'Quoted';
        quote1.Layer__c = 'Primary';
        quote1.OpportunityId = opp.Id;
        quote1.Policy__c = policy.Id;
        quote1.Quote_Type__c='Full Amendment';
        quote1.Effective_Date__c= date.today();
        quote1.Endorsement_Effective_Date__c = System.today() + 5;
        insert quote1;
        
        Document_Revision__c documentRevision  = new Document_Revision__c(
            Name = 'QuoteProposal' + '_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '1',
            Document_Type__c = 'QuoteProposal',
            Quote_Id__c = quote.Id
            //Contract__c = lstQuote2[0].ContractId
        );
        insert documentRevision;
        
       
       String dtNow = String.valueOf(Datetime.now());
       Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'PolicyForm' + '_' + dtNow,
            Document_Azure_Id__c = '3',
            Document_Type__c = 'PolicyForm',
            RecordTypeId = rdPolicyId
            //Contract__c = lstQuote2[0].ContractId
        ); 
        insert newDoc; 
        
        // Create contact
        Contact con = new Contact(
            Email = 'test@j.com',
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;

        // Create broker
        Broker_Account__c broketAccount = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = opp.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policy.Id;
        transactions.Submission__c=opp.Id;
        insert transactions;
        
               //Create Coverage
		Coverage__c cov = TestUtil.createCoverage('Test Coverage','D&O');
		insert cov;

		// Coverages Line Item
		CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
		coverLi.Coverage__c  = cov.Id; 
		coverLi.Quote__c = quote.Id;
		coverLi.Coverage_Premium__c  = 'Text Premium'; 
		coverLi.Min_amt__c  = 1000;
		coverLi.Max_amt__c  = 5000;
		coverLi.Deductible_Frequency__c  = 'Daily';
		coverLi.Options_Value_Percent__c  = 5;
		insert coverLi;
        
        //Rating Modifires
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opp.Id;
        insert rMod;     
         
        //Rating Modifier Factor
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = quote.Id;    
        insert rm; 

    }
    @isTest 
    static void fullCancellationTest(){
        
        Policy__c pol = [SELECT id,Name FROM Policy__c LIMIT 1];
        Quote q = [SELECT id,Name,CreatedDate,Effective_Date__c,Policy__c FROM Quote LIMIT 1];
        pol.Policy_Status__c = 'Bound';
        update pol;
        q.Status='Bound';
        q.Fee__c =100;
        q.Actual_Premium__c =100;
        q.Broker_Netted_Down_Premium__c=100;
        q.Total_Cost_to_Client__c=100;
        q.Policy__c=pol.Id;
        update q;
        
        Test.startTest();
        Quote q1 = [SELECT id,Name,CreatedDate,Effective_Date__c,Policy__c FROM Quote where Name='New Quote' LIMIT 1];
        q1.Status='Bound';
        q1.Policy__c=pol.Id;
        update q1;
        NewEndorsementAQController.ResultWrapper result1= fullCancellation.fullCancellation(
            String.valueOf(q.Id),Date.valueOf(q.CreatedDate),String.valueOf(q.Effective_Date__c),String.valueOf(q.Policy__c));
        Test.stopTest();
        System.assert(result1 != null);
    }   

}