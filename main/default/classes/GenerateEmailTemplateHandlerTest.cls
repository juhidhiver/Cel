/**************************************************************************************************
* Class Name: GenerateEmailTemplateHandler
* Author: Ashik Zahir
* Created date: 06-April-2021
* Description: Test class for GenerateEmailTemplateHandler 
**************************************************************************************************/
@isTest
public class GenerateEmailTemplateHandlerTest {

    @testSetup 
    static void createData(){
        TriggerHandler.bypass('SubmissionTriggerBaseHandler');
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
        
        insert opp;

        Quote_Process__c quoteProcess = new Quote_Process__c();
        quoteProcess.Account__c = acc.Id;
        quoteProcess.Submission__c = opp.Id;
        insert quoteProcess;
        
        //Quote
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='Professional Indemnity'; 
        quote.Status = 'Quoted';
        quote.Layer__c = 'Primary';
        quote.OpportunityId = opp.Id;
        quote.Policy_Wording_ContentDoc_Id__c = 'selectedQuoteId';
        quote.IPID_ContentDoc_Id__c = 'checking';
       // quote.Endorsement_Type__c='New Business';
        insert quote;
        
        Document_Revision__c documentRevision  = new Document_Revision__c(
            Name = 'QuoteProposal' + '_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '1',
            Document_Type__c = 'QuoteProposal',
            Quote_Id__c = quote.Id
            //Contract__c = lstQuote2[0].ContractId
        );
        insert documentRevision;
        
       String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
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

        GenerateEmailTemplateHandler.AttachmentEmail mail = new GenerateEmailTemplateHandler.AttachmentEmail();
        mail.Body = 'Email Body';
        mail.FileName = 'Email FieldName';
        mail.FileType = 'Email Fieldtype';
        TriggerHandler.clearBypass('SubmissionTriggerBaseHandler'); 
    
    }
    
    @isTest
    static void testOppId(){
        GenerateEmailTemplateHandler.AttachmentEmail mail = new GenerateEmailTemplateHandler.AttachmentEmail();
        mail.Body = 'Email Body';
        mail.FileName = 'Email FieldName';
        mail.FileType = 'Email Fieldtype';
        
        Id oppId = [Select Id from Opportunity Limit 1].Id;
        Id quoteProcessId = [Select Id from Quote_Process__c Limit 1].Id;
        
        EmailTemplate emailTemp = new EmailTemplate();
        emailTemp.Name = 'Bind Email Primary';
        emailTemp.TemplateStyle = 'none';
        emailTemp.IsActive = true;
        emailTemp.TemplateType = 'text';
        emailTemp.Encoding = 'ISO-8859-1';
        emailTemp.DeveloperName = 'Test_Email_AZ';
        emailTemp.HtmlValue = '<p> test  Kind regards www.aqueousuw.com </p>';
        emailTemp.FolderId = UserInfo.getUserId();
        insert emailTemp;
        
        Id QuotedId = [Select Id from Quote Limit 1].Id;

        List<string> emails = new List<string>{'test@123','test@231'};
        List<string> attFiles = new List<string>{'test@123','test@231'};
        List<string> attFiles2 = new List<string>();
        attFiles2.add(Json.serialize(mail));
        
        List<Document_Revision__c> docs = [SELECT Id,Name,Document_Type__c FROM Document_Revision__c];  
        
        Id templateId = [Select Id from EmailTemplate Limit 1].Id;
        GenerateEmailTemplateHandler.getEmailTemplates(oppId);
        GenerateEmailTemplateHandler.getEmailList(oppId);
        GenerateEmailTemplateHandler.genKeyToHTML('Key');
        GenerateEmailTemplateHandler.getSubmissionId(oppId);
        GenerateEmailTemplateHandler.getOpportunityRecordType(oppId);
        //GenerateEmailTemplateHandler.getTemplateDetails(templateId, oppId,QuotedId);
        GenerateEmailTemplateHandler.convertDateTimeUS(DateTime.now());
        GenerateEmailTemplateHandler.convertDateUS(Date.today());
        GenerateEmailTemplateHandler.genKeyToText('key');
        GenerateEmailTemplateHandler.getQuoteList(oppId,emailTemp.Name);
        GenerateEmailTemplateHandler.getQuoteList(oppId,'Quote Email Primary');
        Test.startTest();
        GenerateEmailTemplateHandler.sendEmailMsg(templateId, emailTemp, emails, 'ccEmails', 'bccEmails', attFiles,quoteProcessId);
        GenerateEmailTemplateHandler.sendEmailMsg(templateId, emailTemp, emails, '','bccEmails', attFiles,quoteProcessId);
        GenerateEmailTemplateHandler.sendEmailMsg(templateId, emailTemp, emails, 'ccEmails', 'bccEmails', attFiles2,quoteProcessId);
		//GenerateEmailTemplateHandler.getQuoteDocumentBySubmissionId(oppId, emailTemp.Name, );
        Test.stopTest();
        
        System.assert(oppId != null);
    }
    
    @isTest
    static void testExp(){
        Id oppId = [Select Id from Opportunity Limit 1].Id;
        //Id templateId = [Select Id from EmailTemplate Limit 1].Id;
        Id selectedQuoteId = [Select Id from Quote Limit 1].Id;
        
        EmailTemplate emailTemp = new EmailTemplate();
        emailTemp.Name = 'Bind Email Primary';
        emailTemp.TemplateStyle = 'none';
        emailTemp.IsActive = true;
        emailTemp.TemplateType = 'text';
        emailTemp.Encoding = 'ISO-8859-1';
        emailTemp.DeveloperName = 'Test_Email_AZ';
        emailTemp.Subject = 'Test Subject';
        emailTemp.HtmlValue = '<p> test www.aqueousuw.com Kind regards</p>';
        emailTemp.FolderId = UserInfo.getUserId();
        insert emailTemp;
        
        Id templateId = [Select Id from EmailTemplate WHERE Name = 'Bind Email Primary' Limit 1].Id;
        
        Test.startTest();
        
        GenerateEmailTemplateHandler.getTemplateDetails(templateId, oppId,selectedQuoteId);
        GenerateEmailTemplateHandler.checkQuotesEmpty(oppId);
        GenerateEmailTemplateHandler.getTemplateName(templateId);
        GenerateEmailTemplateHandler.getQuoteDocumentBySubmissionId(oppId, emailTemp.Name, selectedQuoteId );
        Test.stopTest();
        System.assert(oppId != null);
    }
      
      
    
}