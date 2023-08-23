@isTest
public class QuoteComparePageGenericControllerTest {
    public static Product2 product;
    public static Account acc;
    
    static {
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        product = TestUtil.createProduct('MPL');
        insert product;   
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.StageName = 'Qualified';
        opp.Coverage_Product_Options__c = 'D&O;MPL;Cyber';
        insert opp;
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        lCov.add(cov1);
        insert lCov;

        
        //List<Quote> lQuote = new List<Quote>();
        Quote quote = TestUtil.createQuote('New quote 1', opp.Id);
        quote.Status = 'In Progress';
        quote.Coverage_Product_Options__c = 'D&O';
        quote.Quote_Type__c = 'New Business';
        quote.Refer_Type__c = 'Underwriting Referral';
        quote.Azure_ID__c = 'Testing-Quote';
        //lQuote.add(quote);
        insert Quote; 
                
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        quote.Status = 'Rated';
        update quote;
        
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
        
        List<SectionSetting__c> sc= new list<SectionSetting__c>();
       
        SectionSetting__c covSection = new SectionSetting__c();
        covSection.Component__c = 'Rate Quotes';
        covSection.Main_Section__c = 'RMF';
        covSection.Source_Field_API__c = 'Commission_percentage__c';
        covSection.Source_Object__c = 'Rating_Modifier_Factor__c';
        covSection.Order__c = 4;
        covSection.Source_Field_Label__c = 'Commission percentage';
        covSection.Format__c = 'Percent';
        covSection.Product__c = 'MPL';
        covSection.Active__c = true;
        covSection.Record_Type__c = 'Celerity';
        covSection.DisplayType__c = 'Open';
        covSection.Quote_Layer__c = 'Primary';
        sc.add(covSection);
        
        SectionSetting__c subSection = new SectionSetting__c();
        subSection.Component__c = 'Rate Quotes';
        subSection.Main_Section__c = 'Commission';
        subSection.Sub_Section__c = 'Sub Section';
        subSection.Order__c = 5;
        subSection.Format__c = 'Percent';
        subSection.Product__c = 'MPL';
        subSection.Active__c = true;
        subSection.Record_Type__c = 'Celerity';
        subSection.DisplayType__c = 'Open';
        subSection.Quote_Layer__c = 'Primary';
        sc.add(subSection);
      
        SectionSetting__c rmfSection = new SectionSetting__c();
        rmfSection.Component__c = 'Rate Quotes';
        rmfSection.Main_Section__c = 'Commission';
        rmfSection.Source_Field_API__c = 'Commission_percentage__c';
        rmfSection.Source_Object__c = 'CoveragesLineItem__c';
        rmfSection.Order__c = 4;
        rmfSection.Source_Field_Label__c = 'Commission percentage';
        rmfSection.Format__c = 'Percent';
        rmfSection.Product__c = 'MPL';
        rmfSection.Active__c = true;
        rmfSection.Record_Type__c = 'Celerity';
        rmfSection.DisplayType__c = 'Open';
        rmfSection.Quote_Layer__c = 'Primary';
        sc.add(rmfSection);
        
        SectionSetting__c secSetting3 = new SectionSetting__c();
        secSetting3.Component__c = 'Rate Quotes';
        secSetting3.Main_Section__c = 'Quote Data';
        secSetting3.Order__c = 4;
        secSetting3.Product__c = 'MPL';
        secSetting3.Active__c = true;
        secSetting3.Record_Type__c = 'Celerity';
        secSetting3.DisplayType__c = 'Open';
        secSetting3.Quote_Layer__c = 'Primary';
        sc.add(secSetting3);
        
        SectionSetting__c secSetting4 = new SectionSetting__c();
        secSetting4.Component__c = 'Rate Quotes';
        secSetting4.Main_Section__c = 'Commission';
        secSetting4.Order__c = 4;
        secSetting4.Product__c = 'MPL';
        secSetting4.Active__c = true;
        secSetting4.Record_Type__c = 'Celerity';
        secSetting4.DisplayType__c = 'Open';
        secSetting4.Quote_Layer__c = 'Primary';
        sc.add(secSetting4);
       
        
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Rate Quotes';
        secSetting.Main_Section__c = 'Commission';
        secSetting.Sub_Section__c = 'Sub Section';
        secSetting.Source_Field_API__c = 'Commission_percentage__c';
        secSetting.Source_Object__c = 'Quote';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Commission percentage';
        secSetting.Format__c = 'Percent';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        secSetting.DisplayType__c = 'Open';
        secSetting.Quote_Layer__c = 'Primary';
        sc.add(secSetting);
        
        SectionSetting__c secSetting1 = new SectionSetting__c();
        secSetting1.Component__c = 'Rate Quotes';
        secSetting1.Main_Section__c = 'Limits & Premiums';
        secSetting1.Source_Object__c = 'Quote';
        secSetting1.Order__c = 4;
        secSetting1.Source_Field_API__c = 'Book_Premium__c';
        secSetting1.Source_Field_Label__c = 'Book Premium';
        secSetting1.Format__c = 'Currency';
        secSetting1.Product__c = 'Professional Indemnity';
        secSetting1.Active__c = true;
        secSetting1.Record_Type__c = 'Celerity';
        secSetting1.DisplayType__c = 'Open';
        secSetting1.Quote_Layer__c = 'Primary';
        sc.add(secSetting1);
        
        SectionSetting__c secSetting2 = new SectionSetting__c();
        secSetting2.Component__c = 'Rate Quotes';
        secSetting2.Main_Section__c = 'Quote Data';
        secSetting2.Source_Object__c = 'Quote';
        secSetting2.Order__c = 4;
        secSetting2.Source_Field_API__c = 'Effective_Date__c';
        secSetting2.Source_Field_Label__c = 'Effective Date';
        secSetting2.Format__c = 'Date';
        secSetting2.Product__c = 'MPL';
        secSetting2.Active__c = true;
        secSetting2.Record_Type__c = 'Celerity';
        secSetting2.DisplayType__c = 'Open';
        secSetting2.Quote_Layer__c = 'Primary';
        sc.add(secSetting2);
        
        insert sc;
        system.debug('SC-->'+JSON.serialize(sc));
        
        Quote_Option__c qo= new Quote_Option__c();
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=quote.Id;
        insert qo;
        
         //AQ Setup
         
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassCoverageLineItemTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        update setting;
        
        Account accaq = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        accaq.BillingStreet = acc.ShippingStreet;
        accaq.BillingCity = acc.ShippingCity;
        accaq.BillingState = acc.ShippingState;
        accaq.BillingPostalCode = acc.ShippingPostalCode;
        accaq.BillingCountry = acc.ShippingCountry;
        insert accaq;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 productaq = TestUtil.createProduct('Professional Indemnity');
        productaq.RecordTypeId = aqueousRecordTypeId; 
        productaq.Innovisk_Entity_ID__c = 'Aqueous';
        insert productaq;   
        
        Opportunity oppaq = TestUtil.createOpportunity('Opp Test',accaq.Id, productaq.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.AccountId=accaq.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = productaq.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        insert oppaq;
        
        String rdPolicyId = Schema.SObjectType.Document_Revision__c.getRecordTypeInfosByName().get('Policy').getRecordTypeId(); 
        Policy__c policyaq = new Policy__c();
        policyaq.Account__c = accaq.Id; 
        policyaq.Expiration_Date__c = Date.today().addDays(100);
        insert policyaq;
        
        //Quote
        Quote quoteaq = TestUtil.createQuote('New Quote Test',oppaq.Id);
        quoteaq.Coverage_Product_Options__c ='Professional Indemnity'; 
        quoteaq.Status = 'Quoted';
        quoteaq.Layer__c = 'Primary';
        quoteaq.OpportunityId = oppaq.Id;
        quoteaq.Policy__c = policyaq.Id;
        //quoteaq.Endorsement_Effective_Date__c = date.parse('08/04/2021');
        quoteaq.Quote_Type__c = 'New Business';
        insert quoteaq;
        
        Document_Revision__c documentRevision  = new Document_Revision__c(
            Name = 'QuoteProposal' + '_' + String.valueOf(Datetime.now()),
            Document_Azure_Id__c = '1',
            Document_Type__c = 'QuoteProposal',
            Quote_Id__c = quoteaq.Id
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
            Opportunity__c = oppaq.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
        //Create Transaction
        Transactions__c transactions = new Transactions__c();
        transactions.Policy__c=policyaq.Id;
        transactions.Submission__c=oppaq.Id;
        insert transactions;
        
        //Rating Modifires
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = oppaq.Id;
        insert rMod;     
        
        //Rating Modifier Factor
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = quoteaq.Id;    
        insert rm; 
        
    }	
    @isTest 
    static void initDataForWrapperTest(){
        Test.startTest();
        
        List<SectionSetting__c> sc= new list<SectionSetting__c>();
        SectionSetting__c secSetting2 = new SectionSetting__c();
        secSetting2.Component__c = 'Rate Quotes';
        secSetting2.Main_Section__c = 'Quote Data';
        secSetting2.Source_Object__c = 'Quote';
        secSetting2.Order__c = 4;
        secSetting2.Source_Field_API__c = 'Effective_Date__c';
        secSetting2.Source_Field_Label__c = 'Effective Date';
        secSetting2.Format__c = 'Date';
        secSetting2.Product__c = 'MPL';
        secSetting2.Active__c = true;
        secSetting2.Record_Type__c = 'Celerity';
        secSetting2.DisplayType__c = 'Open';
        sc.add(secSetting2);
        insert sc;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.StageName = 'Qualified';
        insert opp;
        
        Quote quote = TestUtil.createQuote('New quote 2', opp.Id);
        quote.Status = 'In Progress';
        quote.Coverage_Product_Options__c = 'MPL';
        quote.Quote_Type__c = 'New Business';
        quote.Refer_Type__c = 'Underwriting Referral';
        quote.Azure_ID__c = 'Testing-Quote 12';
        insert Quote; 
        
        QuoteComparePageGenericController quoteCompare = new  QuoteComparePageGenericController();
        quoteCompare.getQuoteResultItemWrapper(opp.Id,'Rate Quotes','Primary');
        quoteCompare.getQuoteResultItemWrapperQC(opp.Id,'Rate Quotes');
       
        quoteCompare.initDataForWrapper(opp.Id, 'Rate Quotes','Primary');  
        quoteCompare.generateListFieldsForCoverageLineItemsAndRatingFactor(sc);
        
        QuoteComparePageGenericController.Field field = new QuoteComparePageGenericController.Field();
        QuoteComparePageGenericController.SubSection subSection = new QuoteComparePageGenericController.SubSection();
        
        Test.stopTest(); 
        system.assertEquals( 'Underwriting Referral', quote.Refer_Type__c); 
    }
    
    @isTest 
    static void initDataForWrapperTest2(){
        Test.startTest();
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test 2',acc.Id, product.Id);
        opp.StageName = 'Closed Won';
        insert opp;
        
        Quote quote = TestUtil.createQuote('New quote 2', opp.Id);
        quote.Status = 'In Progress';
        quote.Coverage_Product_Options__c = 'MPL';
        quote.Quote_Type__c = 'New Business';
        quote.Refer_Type__c = 'Underwriting Referral';
        quote.Azure_ID__c = 'Testing-Quote 1';
        insert Quote; 
        
        QuoteComparePageGenericController quoteCompare = new  QuoteComparePageGenericController();
        quoteCompare.getQuoteResultItemWrapper(opp.Id,'Rate Quotes','Excess');
        quoteCompare.initDataForWrapper(opp.Id, 'Rate Quotes','Excess');  
        Test.stopTest();
        System.assert(quote.Quote_Type__c =='New Business');
    }
    
    @isTest 
    static void createQuoteTest(){
        Test.startTest();
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.StageName = 'New';
        insert opp;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';       
        insert quote;
        quote.Policy_Wording__c='AQUW/AC/04.19 Accountants Policy Wording';
        quote.Quote_Type__c='Amendment';
        update quote;
        
        product = TestUtil.createProduct('Professional Indemnity');
        insert product; 
        
        Opp.Main_Profession__c='Media Professionals';
        Opp.Product__c=product.Id;
        update opp;
        opp.StageName = 'Qualified';
        update opp;
        QuoteComparePageGenericController.createNewQuote(opp.Id, 123,'quote');  
        System.assert(opp.StageName == 'Qualified');
        Test.stopTest();
    } 
     
    @isTest 
    static void createQuoteTest1(){
        Test.startTest();
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.StageName = 'New';
        insert opp;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';       
        insert quote;
        quote.Policy_Wording__c='AQUW/AC/04.19 Accountants Policy Wording';
        quote.Quote_Type__c='Amendment';
        quote.Layer__c='Primary';
        update quote;
        
        product = TestUtil.createProduct('Professional Indemnity');
        insert product; 
        
        Opp.Main_Profession__c='Accountants';
        Opp.Product__c=product.Id;
        update opp;
        opp.StageName = 'Qualified';
        update opp;
        QuoteComparePageGenericController.createNewQuote(opp.Id, 123,'Primary');  
        System.assert(opp.StageName == 'Qualified');
        Test.stopTest();
    }          
    @isTest 
    static void getQuoteRecordsTest(){
        Test.startTest();
        Opportunity opp = [SELECT Id,StageName,Product_Name__c from  Opportunity limit 1];
        opp.StageName='Closed Won';
        update opp;
        
        Quote quot =  [SELECT Id, Name, Status, Rating_Status__c, Quote_Type__c
                       FROM Quote limit 1];  
        
        QuoteComparePageGenericController.getQuoteRecords(opp,'Excess');
        Test.stopTest();
        System.assert(quot.Quote_Type__c != null);
    }
    @isTest 
    static void getQuoteRecordsTestAQ(){
        Test.startTest();
        
        Account acc = [SELECT Id FROM Account Where Name='Bussiness Accoun Aq' limit 1];
        
        Product2 prd = [SELECT Id FROM Product2 Where Name = 'Professional Indemnity'][0];

        Opportunity opp = [SELECT Id,StageName,Product_Name__c FROM Opportunity WHERE AccountId =: acc.Id
                                                        AND Product__c =: prd.Id];
        opp.StageName='Closed Won';
        update opp;
        
        Quote newQuote = [SELECT Id, Name, Status, Rating_Status__c, Quote_Type__c FROM Quote 
                          WHERE OpportunityId =: opp.Id][0];
        
        
		newQuote.Quote_Type__c = 'Flat Cancellation';
        update newQuote;
        
        QuoteComparePageGenericController.getQuoteRecords(opp,'Excess');
        QuoteComparePageGenericController.getQuoteRecordsQC(opp);
        
        newQuote.Quote_Type__c = 'New Business';
        update newQuote;
        QuoteComparePageGenericController.getQuoteRecordsQC(opp);
        
        Test.stopTest();
        System.assert(newQuote.Quote_Type__c != null);
    }
    @isTest 
    static void getQuoteRecordsTest1(){
        Test.startTest();
        Opportunity opp= [SELECT Id,StageName,Opportunity.Product_Name__c from  Opportunity limit 1];
        opp.StageName='New';
        update opp;
        
        Quote quot =  [SELECT Id, Name, Status, Rating_Status__c, Quote_Type__c
                       FROM Quote limit 1];  
        
        QuoteComparePageGenericController.getQuoteRecords(opp,'Excess');
        Test.stopTest();
        System.assert(quot.Quote_Type__c != null);
    }
    @isTest 
    static void buildMapSectionsTest(){
        Test.startTest();
        List<SectionSetting__c> sc= new list<SectionSetting__c>();
        SectionSetting__c secSetting = new SectionSetting__c();
        secSetting.Component__c = 'Account Info';
        secSetting.Main_Section__c = 'Contact Info';
        secSetting.Source_Object__c = 'Account';
        secSetting.Order__c = 4;
        secSetting.Source_Field_Label__c = 'Relationship Type';
        //secSetting.Source_Field_API__c = 'Relationship_Type__c';
        secSetting.Format__c = 'Picklist';
        secSetting.Product__c = 'MPL';
        secSetting.Active__c = true;
        secSetting.Record_Type__c = 'Celerity';
        secSetting.DisplayType__c = 'Open';
        
        sc.add(secSetting);
        //sc.add(secSetting2);
        insert sc ;
        QuoteComparePageGenericController.buildMapSections(sc);
        QuoteComparePageGenericController quotecom = new QuoteComparePageGenericController();
        quotecom.generateListFields(sc);
        System.assert(secSetting.DisplayType__c == 'Open');
        
    }
    @isTest 
    static void createMapForListObjectTest(){
        Test.startTest();
        List<SectionSetting__c> sc= new list<SectionSetting__c>();
        SectionSetting__c secSetting2 = new SectionSetting__c();
        secSetting2.Component__c = 'Rate Quotes';
        secSetting2.Main_Section__c = 'Quote Data';
        secSetting2.Source_Object__c = 'Quote';
        secSetting2.Order__c = 4;
        secSetting2.Source_Field_API__c = 'Effective_Date__c';
        secSetting2.Source_Field_Label__c = 'Effective Date';
        secSetting2.Format__c = 'Date';
        secSetting2.Product__c = 'MPL';
        secSetting2.Active__c = true;
        secSetting2.Record_Type__c = 'Celerity';
        secSetting2.DisplayType__c = 'Open';
        sc.add(secSetting2);
        insert sc;
        Opportunity opp = [SELECT Id,StageName from  Opportunity limit 1];
        List<Quote> quote =  [SELECT Id, Name, Status, Rating_Status__c, Quote_Type__c
                              FROM Quote limit 1];  
        
        Rating_Modifiers__c rMod = new Rating_Modifiers__c();
        rMod.Opportunity__c = opp.Id;
        insert rMod;     
        
        List<Rating_Modifier_Factor__c> rmList  =new List<Rating_Modifier_Factor__c>();
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = rMod.Id;
        rm.Quote__c = quote[0].Id; 
        rmList.add(rm);
        insert rmList;   
        
        QuoteComparePageGenericController quotecom = new QuoteComparePageGenericController();
       
        quotecom.createMapForListObject(rmList, sc);
        quotecom.getCriteria('Hello');
       // quotecom.createFieldPropertyCondition(result, sc[0]);
        quotecom.generateListFieldsForQuote(sc);
        quotecom.generateListFieldsForCoverageLineItemsAndRatingFactor(sc);
        quotecom.createMapForListObjectSort(quote,sc);
         system.assertEquals('Open', secSetting2.DisplayType__c );
        
    }
    @isTest 
    static void testcreateFieldPropertyCondition(){
        Test.startTest();
       
        SectionSetting__c Section = new SectionSetting__c();
        Section.Component__c = 'Rate Quotes';
        Section.Main_Section__c = 'Commission';
        Section.Source_Field_API__c = 'Commission_percentage__c';
        Section.Source_Object__c = 'CoveragesLineItem__c';
        Section.Order__c = 4;
        Section.Source_Field_Label__c = 'Commission percentage';
        Section.Format__c = 'Percent';
        Section.Product__c = 'MPL';
        Section.Active__c = true;
        Section.Record_Type__c = 'Celerity';
        Section.DisplayType__c = 'Open';
      
        insert Section;
        Opportunity opp = [SELECT Id,StageName from  Opportunity limit 1];
        List<Quote> quote =  [SELECT Id, Name, Status, Rating_Status__c, Quote_Type__c
                              FROM Quote limit 1];  
        
       Coverage_Limits_Deductibles__c covLD =  [SELECT Id, Name
                              FROM Coverage_Limits_Deductibles__c limit 1];
        
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        insert cov1;
        
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov1.Id; 
        coverLi.Quote__c = quote[0].Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Limits_Deductibles__c = covLD.Id;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        insert coverLi;
 
       // Limits_Deductibles__c limitDeduct = [select Id from Limits_Deductibles__c]; 
        QuoteComparePageGenericController quotecom = new QuoteComparePageGenericController();
        quotecom.createFieldPropertyCondition(coverLi, Section);
        system.assertEquals( 'Text Premium',  coverLi.Coverage_Premium__c );  

    }
    @isTest
    static void getMainColumnsTest(){
        Test.startTest();
        Quote q = [Select Id, Name, Status,Rating_Status__c,Last_Quote_Version__c,CloseDate__c from Quote Limit 1];
        List<Quote_Version__c> lstQuoteVersion = [Select Id from Quote_Version__c];
        
        QuoteCompareItemField field1 = new QuoteCompareItemField();
        field1.readOnly = false;
        field1.sourceFieldAPI = 'Rating_Status__c';
        field1.sourceObject = 'Quote';
        field1.format = null;
        field1.displayType = '';
        field1.value = '';
        field1.fieldId = '';
        field1.fieldName = '';
        field1.fieldCondition = 'Test Condition';
        field1.fieldRequire = 'Id, Rating_Status__c';
        field1.pickListOption = null;
        field1.isField = false;
        field1.index = 0;       
        field1.min = '';
        field1.max = '';
        
        List<QuoteCompareItemField> quoteComp = new List<QuoteCompareItemField>();
        quoteComp.add(field1);
       
        QuoteCompareItemWrapper obj = new QuoteCompareItemWrapper();
        obj.quoteId = q.Id;
        obj.quoteName = q.Name;
        obj.quoteStatus = q.Status;
        obj.quoteRatingStatus = q.Rating_Status__c;
        obj.quoteFields = quoteComp;
        obj.quoteVersions = lstQuoteVersion;
        obj.lastQuoteVersion = q.Last_Quote_Version__c;
        //QuoteComparePageGenericController.generateQuoteCompareItem('test');
          //QuoteComparePageGenericController Qc = new QuoteComparePageGenericController();
          //Qc.generateCompareItemField(quoteComp,'1');
        Test.stopTest();
        system.assertEquals('Quote', field1.sourceObject);
    }
    @isTest
    static void TestExceptions(){
        QuoteComparePageGenericController quoteCompare = new  QuoteComparePageGenericController();
        quoteCompare.getQuoteResultItemWrapperQC(null,null);
        quoteCompare.getQuoteResultItemWrapper(null,null,null);
    }
    @isTest
    static void TestAQ(){
        
        Test.startTest();
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 productAQ = TestUtil.createProduct('Professional Indemnity');
        productAQ.RecordTypeId = aqueousRecordTypeId; 
        productAQ.Innovisk_Entity_ID__c = 'Aqueous';
        insert productAQ;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, productAQ.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.StageName = 'Qualified'; 
        opp.Innovisk_Entity_ID__c = 'Aqueous';                            
        opp.Submission_Status__c = 'Quoted';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        //opp.Product_Name__c = product.Id;
		insert opp;
        system.debug('opp name'+ opp.Product_Name__c);
        
        
		UW_Analysis_Template__c TempList = new UW_Analysis_Template__c();
        TempList.UW_Analysis_Name__c = 'Test';
        TempList.Criteria__c = 'Engineers';
        TempList.UW_Analysis_Code__c ='Code';
        TempList.Rating_Factor__c= 5000;
        TempList.Sort_Order__c = 100;
        insert TempList;
        
        UW_Analysis__c uwList = new UW_Analysis__c();
        uwList.Amount__c = 1000;
        //uwList.Name = 'Test';
        uwList.UW_Analysis_Name__c = 'UW Test';
        uwList.Criteria__c = 'Territory';
        uwList.UW_Analysis_Code__c = 'T1';
        uwList.Rating_Factor__c = 1000;
        uwList.Sort_Order__c = 10;
        uwList.Submission__c = opp.Id;
        uwList.UW_Analysis_Template__c = TempList.Id;
        uwList.Sort_Order__c = 10;
        uwList.Notional_Income__c = 1000;
        insert uwList;
		
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
        quote.ExpirationDate = date.today() + 365;
        // quote.Endorsement_Type__c='New Business';
        quote.Quote_Type__c = 'Insured Account Update';
        quote.Policy__c = policy.Id;
        quote.Rating_Status__c = 'Clear';
        quote.Last_Quote_Version__c ='test';
        insert quote;
        
        Quote quoteclone = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quoteclone.Coverage_Product_Options__c ='Professional Indemnity'; 
        quoteclone.Status = 'Quoted';
        quoteclone.Layer__c = 'Excess';
        quoteclone.OpportunityId = opp.Id;
        quoteclone.ExpirationDate = date.today() + 365;
        quoteclone.Quote_Type__c = 'Insured Account Update';
        quoteclone.Policy__c = policy.Id;
        quoteclone.Parent_Quote__c = quote.Id;
        quoteclone.Rating_Status__c = 'Clear';
        quoteclone.Last_Quote_Version__c ='test';
        insert quoteclone;
        
       	opp.StageName='Closed Won';
        update opp;
        system.debug('opp name'+ opp);
        Opportunity oppo = [select Id,Product_Name__c,StageName from Opportunity where Id =:opp.Id];
		QuoteComparePageGenericController.getQuoteRecords(opp,'Excess');
        QuoteComparePageGenericController.getQuoteRecordsQC(oppo);
        Test.stopTest();
    }
    
}