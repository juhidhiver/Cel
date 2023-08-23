/**************************************************************************************************
* Class Name: GenerateEmailTemplateHandlerPolicyTest
* Author:Namana K G
* Created date: 27-April-2021
* Description: 
**************************************************************************************************/
@isTest
public class GenerateEmailTemplateHandlerPolicyTest {
    
    @testSetup 
    static void createData(){
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        update setting;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
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
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Submission_Status__c = 'Quoted';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        opp.Transaction_Status__c= 'Active';
        insert opp;

        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Bound';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = opp.Id;
        quote.Policy_Wording_ContentDoc_Id__c = 'selectedQuoteId';
        quote.IPID_ContentDoc_Id__c = 'checking';
        insert quote;
        
                
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policy = new Policy__c();
        policy.Account__c = acc.Id; 
        policy.Policy_Status__c = 'Bound';
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        quote.Policy__c = policy.Id;
        update quote;
        
        system.debug('quote--'+quote.Policy__c);
      
        
        Document_Revision__c documentRevision  = new Document_Revision__c(
            Name = 'QuoteProposal' + '_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '1',
            Document_Type__c = 'QuoteProposal',
            Quote_Id__c = quote.Id,
            policy__c = policy.Id
            //Contract__c = lstQuote2[0].ContractId
        );
        insert documentRevision;
        
       String dtNow = String.valueOf(Datetime.now());
       Document_Revision__c newDoc = new Document_Revision__c(
            Name = 'PolicyForm' + '_' + dtNow,
            Document_Azure_Id__c = '3',
            Document_Type__c = 'PolicyForm',
            RecordTypeId = rdPolicyId,
            policy__c = policy.Id
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
        
    }
    
    @isTest 
    Public static void getEmailListTest(){
       
        Policy__c policy = [select Id from Policy__c limit 1];
        system.debug('policy-->'+policy);
        Quote quote = [Select id,Layer__c from Quote limit 1];
        quote.Layer__c = 'Excess';
        //update quote;
       
        EmailTemplate template = new EmailTemplate();
        template.Name = 'Bind Email Primary';
        template.TemplateStyle = 'none';
        template.IsActive = true;
        template.TemplateType = 'text';
        template.Encoding = 'ISO-8859-1';
        template.DeveloperName = 'Test_Email_AZ';
        template.FolderId = UserInfo.getUserId();
        template.Subject ='Test';
        template.HtmlValue='testing Kind regards www.aqueousuw.com ';
        insert template;
        
        List<String> emails = new List<String>{'testEmail@cg.com'};
            List<string> attFiles = new List<string>{'{"FileName":"test","Body":"test1","FileType":"application/pdf"}'};
                
        GenerateEmailTemplateHandlerPolicy.getEmailList(policy.Id);
        GenerateEmailTemplateHandlerPolicy.getPolicyRecordType(policy.Id);
        GenerateEmailTemplateHandlerPolicy.getQuoteDocumentBySubmissionId(policy.Id, template.Name);
        
        
        //GenerateEmailTemplateHandlerPolicy.convertDateUS('08-08-2020');
        GenerateEmailTemplateHandlerPolicy.getTemplateName(template.Id);
        GenerateEmailTemplateHandlerPolicy.getEmailTemplates(policy.Id);
        GenerateEmailTemplateHandlerPolicy.getTemplateDetails(template.Id, policy.Id);
        Test.startTest();
        GenerateEmailTemplateHandlerPolicy.sendEmailMsg(template.Id, template, emails, 'test1@ch.com', 'test11@cg.com', attFiles, policy.Id);
        Test.stopTest();
        
        
        system.assert(emails!=null);
    }
    
    /* New Method added By Navdeep ***/
    @isTest
    public static void testAmendmentTemplates(){
        Test.startTest();
        Policy__c policy = [select Id from Policy__c limit 1];
        
        system.debug('policy-->'+policy);
        Quote quote = [Select id,Layer__c from Quote limit 1];
        quote.Layer__c = 'Excess';
        //update quote;
        EmailTemplate template = new EmailTemplate();
        template.Name = 'Bind Amendment Template for Primary';
        template.TemplateStyle = 'none';
        template.IsActive = true;
        template.TemplateType = 'text';
        template.Encoding = 'ISO-8859-1';
        template.DeveloperName = 'Test_Email_AZ';
        template.FolderId = UserInfo.getUserId();
        template.Subject ='Test';
        template.HtmlValue='testing Kind regards www.aqueousuw.com ';
        insert template;
        
    
        GenerateEmailTemplateHandlerPolicy.getAmendmentDocuments(policy.Id, template.Name);
        GenerateEmailTemplateHandlerPolicy.getLatestQuote(policy.Id);
        Test.stopTest();
    } 
}