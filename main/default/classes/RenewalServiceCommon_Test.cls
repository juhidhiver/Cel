@isTest
public class RenewalServiceCommon_Test {
    @testSetup static void setup() {
        String RecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Contact con = new Contact(
            Email = 'test@j.com',
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = 'England';
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        Account accaq = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        accaq.BillingStreet = acc.ShippingStreet;
        accaq.BillingCity = acc.ShippingCity;
        accaq.BillingState = 'England';
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
        oppaq.AccountId = accaq.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = productaq.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.Tax_Country__c = 'United Kingdom';
        insert oppaq;
        
        Broker_Account__c broketAccount = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = oppaq.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
        Renewal__c rn = new Renewal__c(
        Broker__c = broketAccount.id,
        recordtypeId = RecordTypeId);
        insert rn;
        
        List<SectionSetting__c> sc= new list<SectionSetting__c>();
        SectionSetting__c covSection = new SectionSetting__c();
        covSection.Component__c = 'Auto Renewals';
        covSection.Main_Section__c = 'RMF';
        covSection.Source_Field_API__c = 'Commission_percentage__c';
        //covSection.Source_Object__c = 'Rating_Modifier_Factor__c';
        //covSection.Sub_Section__c = 'Sub Section';
        covSection.Profile_Name_for_Read_Only__c = 'ALL';
        covSection.Order__c = 4;
        covSection.Source_Field_Label__c = 'Commission percentage';
        covSection.Format__c = 'Percent';
        covSection.Product__c = 'Professional Indemnity';
        covSection.Active__c = true;
        covSection.Record_Type__c = 'Celerity';
        covSection.DisplayType__c = 'Open';
        covSection.Quote_Layer__c = 'Primary';
        sc.add(covSection);
        
        SectionSetting__c covSection1 = new SectionSetting__c();
        covSection1.Component__c = 'Auto Renewals';
        covSection1.Main_Section__c = 'RMF';
        covSection1.Source_Field_API__c = 'Commission_percentage__c';
        //covSection.Source_Object__c = 'Rating_Modifier_Factor__c';
        covSection.Sub_Section__c = 'Sub Section';
        covSection1.Profile_Name_for_Read_Only__c = 'ALL';
        covSection1.Order__c = 4;
        covSection1.Source_Field_Label__c = 'Commission percentage';
        covSection1.Format__c = 'Percent';
        covSection1.Product__c = 'Professional Indemnity';
        covSection1.Active__c = true;
        covSection1.Record_Type__c = 'Celerity';
        covSection1.DisplayType__c = 'Open';
        covSection1.Quote_Layer__c = 'Primary';
        sc.add(covSection1);      
        Insert sc;
     
    }
    public testmethod static void  testmthod(){
        String RecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        RenewalService.fetchRenewalRecords(RecordTypeId);
        RenewalService.getListSectionSetting('Professional Indemnity');
    }
    
    public testmethod static void  testmthod1(){
        SectionSetting__c sc = [Select Id,Sub_Section__c,Source_Object__c,DisplayType__c From SectionSetting__c LIMIT 1];
        sc.Source_Object__c = 'Rating_Modifier_Factor__c';
        update sc;
        String RecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        RenewalService.fetchRenewalRecords(RecordTypeId);
        RenewalService.getListSectionSetting('Professional Indemnity');
    }
    
     public testmethod static void  testmthod2(){
        SectionSetting__c sc = [Select Id,Sub_Section__c,Source_Object__c,DisplayType__c,Source_Field_API__c From SectionSetting__c LIMIT 1];
         sc.Source_Object__c = 'Rating_Modifier_Factor__c';
         //sc.Source_Field_API__c = 'Rating_Status__c';
         sc.Sub_Section__c = 'Sub Section';
         //sc.Format__c = 'Picklist';
         update sc;
         Broker_Account__c bk = [SELECT Id FROM Broker_Account__c LIMIT 1];
         RenewalServiceHandler_Common.FilteredWrapper wrap = new RenewalServiceHandler_Common.FilteredWrapper();
         wrap.year = 2022;
         wrap.brokerWarning= true;
         wrap.docRequiredWarning=true;
         wrap.hasClaimWarning=true;
         wrap.month = '1';
         wrap.noRecepientWarning=true;
         wrap.paymentWarning=true;
         wrap.selectedBroker = bk.Id;
        // wrap.selectedInsured = 'test';
         wrap.statusValue = 'test';
         wrap.largeClaimWarning=true;
         wrap.docRequiredWarning=true;
         wrap.renewalWarning=true;
         

         String RecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
         RenewalService.fetchRenewalRecords(RecordTypeId);
         RenewalService.getListSectionSetting('Professional Indemnity');
         RenewalService.fetchFilteredRenewalRecords(JSON.serialize(wrap),RecordTypeId);
         RenewalService.getRenewalWrappInfo();
     }
    
    public testmethod static void  testmthod3(){
        
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c  = true;
        update setting;
       
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
		Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        insert acc;
        
         // Create contact
		Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
		);
		insert con;
        
        Product2 product = TestUtil.createProduct('D&O');
        insert product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Main_Profession__c = 'Property Professionals';
        insert opportunity; 
      	
        List<Policy__c> policyList = new List<Policy__c>();
        Policy__c policy = new Policy__c();
        	policy.Account__c = acc.Id;
        	policy.Product_Name__c = 'Professional Indemnity';
        	policy.Expiration_Date__c = Date.today().addmonths(3);
        	policy.Total_Premium__c = 2000;
        	policy.Initial_Premium__c = null;
        	policy.Policy_Status__c = 'Bound';        	
        	policyList.add(policy);
        
        	Policy__c policy1 = new Policy__c();
        	policy1.Account__c = acc.Id;
        	policy1.Product_Name__c = 'Professional Indemnity';
        	policy1.Expiration_Date__c = Date.today().addmonths(3);
        	policy1.Total_Premium__c = 2000;
        	policy1.Initial_Premium__c = null;
        	policy1.Policy_Status__c = 'Bound';
        	policyList.add(policy1);
        insert policyList;
        
        Quote quote = TestUtil.createQuote('Quote Test',opportunity.Id);
        quote.Azure_ID__c = 'Test Az 1';
        quote.Policy__c = policy.Id;
        quote.Status = 'Bound';
        quote.Layer__c = 'Primary';
        insert quote;
        
         Quote quote1 = TestUtil.createQuote('Quote Test1',opportunity.Id);
        quote1.Azure_ID__c = 'Testaz2';
        quote1.Policy__c = policy1.Id;
        quote1.Status = 'Bound';
        quote1.Layer__c = 'Primary';
        insert quote1;
        
        // Create broker
		Broker_Account__c broketAccount = new Broker_Account__c(
			Broker_Contact__c = con.Id,
			Opportunity__c = opportunity.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert broketAccount;
        
            //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
        cov.Coverage_Type__c = 'Endorsement';
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
         coverLi.Parent_Coverages_Line_Item__c = null; 
         coverLi.Form_Number__c = 'AQUW153';
         insert coverLi;
        
        Claim_Data__c cd = new Claim_Data__c();
        cd.Account__c = acc.id;
        cd.Policy__c  = policy.id;
        cd.Claim_status__c = 'Test Status';
        cd.Indemnity_Paid__c = 10000.7;
        cd.Fees_Paid__c = 2000.66;
        cd.Fees_Reserve__c = 3000.24;
        cd.Indemnity_Reserve__c = 4000.11;
        cd.TPA_Fees__c = 1223.11;
        insert cd;
        
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test 1';
        quoteOpt.Quote__c =  quote.Id;
        quoteOpt.Bound__c = true;
        insert quoteOpt;
        
       	Rating_Modifiers__c ratingModifier = TestUtil.createRatingModifier('Is the business regulated by the Royal Institution of Chartered Surveyors?', 'Professional Indemnity', opportunity.Id);
        ratingModifier.Rating_Modifier_Value__c ='YES';
        insert ratingModifier;
        
        Payment_Data__c paymentData = new  Payment_Data__c();
        paymentData.Policy__c = policy.Id ; 
        paymentData.Quote__c = quote.id;
        paymentData.Paid_Status__c = 'Not Paid';        
        paymentData.Last_Modified_Date__c = System.now();
        insert paymentData;
		
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standardusertest@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@prodorg.com',Is_AQ_Auto_Renewals_Underwriter__c =true);
        
        
        insert u;        
        Test.startTest();     
        	AutoRenewalsCreationBatch b = new AutoRenewalsCreationBatch('Professional Indemnity', System.today());
        	database.executebatch(b,2);
        	String sch = '0 0 23 * * ?';
        	//system.schedule('Test status Check', sch, b );
        Test.stopTest();
         
    }
    
     public testmethod static void  testmthod4(){
         
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c  = true;
        setting.BypassContactTrigger__c  = true; 
        setting.BypassContentDocumentLinkTrigger__c = true;
        setting.BypassPolicyTrigger__c = true;
        setting.BypassBrokerAccountTrigger__c =true;
        setting.BypassRenewalTrigger__c = true;
        update setting;
          GlobalStaticVar.byPassRenewalTrigger = true;
        String RecordTypeId = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        
        Account acc = TestUtil.createBusinessAccount('Broker Account Test', 'Broker_Account', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = 'England';
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
         List<Id> ConIdListRemove = new List<Id>();
         Contact con = new Contact(
             AccountId = acc.Id,
             Email = 'test@j.com',
             Lastname = 'Test broker',
             RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId(),
             Role__c = 'Renewals;'
         );
         insert con;
         ConIdListRemove.add(con.Id);
         
         List<Id> ConIdListAdd = new List<Id>();
         Id recordTypeContactAgency = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
         Contact conAq = TestUtil.createContact(acc.Id, 'Broker_Contact', 'New broker contact');
         conAq.RecordTypeId = recordTypeContactAgency;
         conAq.Email = 'test@hu.com';       
         insert conAq;
         ConIdListAdd.add(conAq.Id);
         
        Account accaq = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        accaq.BillingStreet = acc.ShippingStreet;
        accaq.BillingCity = acc.ShippingCity;
        accaq.BillingState = 'England';
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
        oppaq.AccountId = accaq.Id;
        oppaq.StageName = 'Qualified'; 
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';                            
        oppaq.Product__c = productaq.Id;
        oppaq.Submission_Status__c = 'Quoted';
        oppaq.Transaction_Status__c = 'Active';
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.Tax_Country__c = 'United Kingdom';
        insert oppaq;
         
        Broker_Account__c broketAccount = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = oppaq.Id,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broketAccount;
        
         List<String> renewalList = new List<String>();
         Renewal__c rn = new Renewal__c(
             Broker__c = broketAccount.id,
             recordtypeId = RecordTypeId);  
          insert rn;
         renewalList.add(rn.Id);
         
         Policy__c policy = new Policy__c();
         policy.Account__c = acc.Id;
         policy.Product_Name__c = 'Professional Indemnity';
         policy.Expiration_Date__c = Date.today().addmonths(2);
         policy.Total_Premium__c = 2000;
         policy.Initial_Premium__c = null;
         policy.Policy_Status__c = 'Bound';   
         insert policy;    
         
        Document_Template__c doc = new Document_Template__c();
        doc.Document_Name__c = 'Accountants Proposal Form';
        Insert doc;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document 123';
        cv.PathOnClient = 'Test123Document.pdf';
        cv.VersionData = Blob.valueOf('Test 123 Content');
        cv.IsMajorVersion = true;
        Insert cv;         
        
        //Get Content Version
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];       
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = doc.id;
        cdl.ContentDocumentId = cvList[0].ContentDocumentId;
        cdl.shareType = 'V';
        insert cdl;  
        Document_Template__c doc1 = new Document_Template__c();
        doc1.Document_Name__c = 'Accountants Renewal Declaration test';
        Insert doc1;
         
         String RecordTypeIdREN = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
         Renewal__c renw = new Renewal__c(
             Broker__c = broketAccount.id,
             Policy__c = policy.Id,
             recordtypeId = RecordTypeIdREN,
             status__c= 'Ready to Send',
             Documents_Required__c = 'Accountants Proposal Form;Accountants Renewal Declaration Form');          
         insert renw;
         renewalList.add(renw.Id);
          Test.startTest();
         RenewalService.fetchContactsofRenewal(renw.Id);
         RenewalService.updateRenewalRecords(renewalList, 'Ready to Send');
         RenewalService.sendTestEmail(renw.Id);
         RenewalService.manualEmailSend(renw.Id);
         RenewalService.updateRoleOnContact(ConIdListRemove,ConIdListAdd,renw.Id);
         RenewalService.getListOfBrokerContacts(renw.Id);
         Test.stopTest();
     }
    
     public static testmethod void  testScenario1(){
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c  = true;
        setting.BypassContactTrigger__c  = true; 
        setting.BypassPolicyTrigger__c = true;
        setting.BypassBrokerAccountTrigger__c =true;
        setting.BypassRenewalTrigger__c = true;
        update setting;
       
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
		Account acc  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
												'California','90000', 'United States');
        insert acc;
        
         // Create contact
		Contact con = new Contact(
			Lastname = 'Test broker',
			RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId(),
            Role__c='Renewals',
            Email = 'abc@gmail.com',
            AccountId = acc.Id
		);
		insert con;
        
        Product2 product = TestUtil.createProduct('D&O');
        insert product;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Main_Profession__c = 'Property Professionals';
        insert opportunity; 
      	
        List<Policy__c> policyList = new List<Policy__c>();
        Policy__c policy = new Policy__c();
        	policy.Account__c = acc.Id;
        	policy.Product_Name__c = 'Professional Indemnity';
        	policy.Expiration_Date__c = Date.today().addmonths(2);
        	policy.Total_Premium__c = 2000;
        	policy.Initial_Premium__c = null;
        	policy.Policy_Status__c = 'Bound';        	
        	policyList.add(policy);
        
        	Policy__c policy1 = new Policy__c();
        	policy1.Account__c = acc.Id;
        	policy1.Product_Name__c = 'Professional Indemnity';
        	policy1.Expiration_Date__c = Date.today().addmonths(2);
        	policy1.Total_Premium__c = 2000;
        	policy1.Initial_Premium__c = null;
        	policy1.Policy_Status__c = 'Bound';
        	policyList.add(policy1);
        insert policyList;
        
        Quote quote = TestUtil.createQuote('Quote Test',opportunity.Id);
        quote.Azure_ID__c = 'Test Az 1';
        quote.Policy__c = policy.Id;
        quote.Status = 'Bound';
        quote.Layer__c = 'Primary';
        insert quote;
        
         Quote quote1 = TestUtil.createQuote('Quote Test1',opportunity.Id);
        quote1.Azure_ID__c = 'Testaz2';
        quote1.Policy__c = policy1.Id;
        quote1.Status = 'Bound';
        quote1.Layer__c = 'Primary';
        insert quote1;
        
        // Create broker
		Broker_Account__c broketAccount = new Broker_Account__c(
			Broker_Contact__c = con.Id,
			Opportunity__c = opportunity.Id,
			IsPrimaryBroker__c = true,
			Relationship_Type__c = 'Broker'
		);
		insert broketAccount;
        
            //Create coverage
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'Professional Indemnity');
        cov.Coverage_Type__c = 'Endorsement';
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
         coverLi.Parent_Coverages_Line_Item__c = null; 
         coverLi.Form_Number__c = 'AQUW153';
         insert coverLi;
        
        Claim_Data__c cd = new Claim_Data__c();
        cd.Account__c = acc.id;
        cd.Policy__c  = policy.id;
        cd.Claim_status__c = 'Test Status';
        cd.Indemnity_Paid__c = 10000.7;
        cd.Fees_Paid__c = 2000.66;
        cd.Fees_Reserve__c = 3000.24;
        cd.Indemnity_Reserve__c = 4000.11;
        cd.TPA_Fees__c = 1223.11;
        insert cd;
        
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test 1';
        quoteOpt.Quote__c =  quote.Id;
        quoteOpt.Bound__c = true;
        insert quoteOpt;
        
       	Rating_Modifiers__c ratingModifier = TestUtil.createRatingModifier('Is the business regulated by the Royal Institution of Chartered Surveyors?', 'Professional Indemnity', opportunity.Id);
        ratingModifier.Rating_Modifier_Value__c ='YES';
        insert ratingModifier;
        
        Payment_Data__c paymentData = new  Payment_Data__c();
        paymentData.Policy__c = policy.Id ; 
        paymentData.Quote__c = quote.id;
        paymentData.Paid_Status__c = 'Not Paid';        
        paymentData.Last_Modified_Date__c = System.now();
        insert paymentData;
        
        String RecordTypeIdREN = Schema.SObjectType.Renewal__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Renewal__c rn = new Renewal__c(
        Broker__c = broketAccount.id,
        Policy__c = policy.Id,
        recordtypeId = RecordTypeIdREN,
        status__c= 'Ready to Send',
        Documents_Required__c = 'Accountants Proposal Form;Accountants Renewal Declaration Form');
        insert rn;
        
        // rn.status__c= 'Ready to Send';
        // update rn;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
        Group grp = new Group();
        grp.name = 'Admin Renewals';
        grp.Type = 'Regular'; 
        Insert grp;
        
        //Create Group Member
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = UserInfo.getUserId();
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
        }

        Test.startTest();
        AutoRenewalsEmailBatch b = new AutoRenewalsEmailBatch(true, Date.today(), 'Professional Indemnity');
        database.executebatch(b,2);
        Test.stopTest();
    }
}