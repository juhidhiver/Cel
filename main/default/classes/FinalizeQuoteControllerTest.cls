@isTest
private class FinalizeQuoteControllerTest {      
    static { 
        // create broker account        
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
        
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassQuoteTrigger__c = true;
        insert setting;
        
        // create Quote
        Quote q = TestUtil.createQuote('Test Quote', opp.Id);
        q.Rating_Status__c = 'Refer';
        q.Status = 'Rated';
        q.Azure_ID__c = 'ABC';
        insert q;
        
        Quote q1 = TestUtil.createQuote('InProgress Quote', opp.Id);
        q1.Rating_Status__c = 'Clear';
        q1.Status = 'In Progress';
        insert q1;
        
        
        
        FinalizeServiceHandler_Common.ReferralReasonWrapper referralreason= new FinalizeServiceHandler_Common.ReferralReasonWrapper();
        referralreason.Name='New referral';
        referralreason.ApprovalLevelRequired='yes';
        referralreason.ApprovalStatus='Approved';
        referralreason.ApprovedBy='Test1';
        referralreason.Reason='test';
        referralreason.ApprovalRejectedDate=date.today()+120;
        referralreason.EntityPath='test';
        referralreason.ReasonType='test';
        referralreason.Status='test';
        referralreason.Id='test123';
        referralreason.ApproverLevel='2';
        
    }  
    @isTest 
    static void testMethod_X1() {   
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        Quote q = [SELECT Id FROM Quote WHERE Name='Test Quote']; 
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test';
        quoteOpt.Quote__c =  q.Id;
        quoteOpt.Selected__c = true;
        insert quoteOpt;
        Coverage__c cov = TestUtil.createCoverage('Test Coverage','D&O');
        insert cov;
        Coverage_Limits_Deductibles__c lded = new Coverage_Limits_Deductibles__c(Name = 'Test');
        lded.RecordTypeId = Schema.SObjectType.Coverage_Limits_Deductibles__c.getRecordTypeInfosByName().get('Deductible Option').getRecordTypeId(); 
        lded.Parent_Coverage__c = cov.Id;
        lded.Limit_Deductible_Type__c = 'Endorsement';
        insert lded;
        CoveragesLineItem__c cli = new CoveragesLineItem__c();
        cli.Quote__c = q.Id;
        //cli.CoverageLineItemType__c='Limit Option';
        cli.Limits_Deductibles__c = lded.Id;
        cli.Coverage__c = cov.Id;
        insert cli;
        Test.startTest();
        //HttpResponse res = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', q, 'functionName');
        FinalizeQuoteController.syncQuoteToMiddleware(q.Id);  
        FinalizeQuoteController.checkSelectedQuoteOption(q.Id);
        FinalizeQuoteController.checkPartFixedEndorsement(q.Id);
        Test.stopTest();
        System.assertNotEquals(q.Id, null);
    }
    static testMethod void testMethod1() {   
        Test.startTest();
        Quote q = [SELECT Id FROM Quote WHERE Name='Test Quote']; 
        q.Rating_Status__c= 'Refer';
        update q;
        ResultResponse res = new ResultResponse(); 
        res = FinalizeQuoteController.finalizeQuote(q.Id);  
        FinalizeQuoteController.getReferralReasons(q.Id);
        
        List<Referral_Reason__c> refreason= new List<Referral_Reason__c>();
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Status__c='Approved';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=q.id;
        refreason.add(ref1);
        Referral_Reason__c ref2=new Referral_Reason__c();
        ref2.Approval_Level_Required__c='2';
        ref2.Approval_Status__c='Rejected';
        ref2.Approval_Rejected_Date__c= date.today()+365;
        ref2.Quote__c=q.id;
        refreason.add(ref2);
        insert refreason;
        FinalizeServiceHandler_Common.getLowestApprover(refreason);  
        
        Test.stopTest();
        //System.assertNotEquals(res.data, null);
    }
    static testMethod void finaliseTest() { 
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Account Test Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
        Quote quot = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quot.OpportunityId = opp.Id;
        quot.Rating_Status__c = 'Refer';
        quot.Status = 'Rated';
        quot.Coverage_Product_Options__c = 'Professional Indemnity';
        insert quot; 
        quot.Rating_Status__c='clear';
        update quot;
        Quote_Option__c quoteOption = new  Quote_Option__c();
        quoteOption.Quote__c=quot.Id;
        quoteOption.Selected__c=true;
        insert quoteOption;
        
        List<Referral_Reason__c> refreason= new List<Referral_Reason__c>();
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='1';
        ref1.Approval_Level_Required__c='1';
        ref1.Approval_Status__c='';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote_Option__c= quoteOption.Id;
        ref1.Quote__c=quot.id;
        ref1.Reason__c='Test';
        refreason.add(ref1);
        insert refreason;  
        
        Test.startTest();
        FinalizeQuoteController.finalizeQuote(quot.Id);  
        
        ref1.Approval_Level_Required__c='2';
        update ref1;
        FinalizeQuoteController.finalizeQuote(quot.Id);  
        
        ref1.Approval_Level_Required__c='3';
        update ref1;
        
        FinalizeQuoteController.finalizeQuote(quot.Id);  
        FinalizeQuoteController.getReferralReasons(quot.Id);
        FinalizeQuoteController.getReferralReasons('');
        FinalizeServiceHandler_Common.getLowestApprover(refreason);
        Test.stopTest();
        System.assertNotEquals(refreason, null);
    }
    
    static testMethod void finaliseTest2() { 
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Account Test Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
        Quote quot = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quot.OpportunityId = opp.Id;
        quot.Rating_Status__c = 'Refer';
        quot.Status = 'Rated';
        quot.Coverage_Product_Options__c = 'Professional Indemnity';
        insert quot; 
        quot.Rating_Status__c='clear';
        update quot;
        Quote_Option__c quoteOption = new  Quote_Option__c();
        quoteOption.Quote__c=quot.Id;
        quoteOption.Selected__c=true;
        insert quoteOption;
        
        List<Referral_Reason__c> refreason= new List<Referral_Reason__c>();
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='2';
        ref1.Approval_Level_Required__c='2';
        ref1.Approval_Status__c='';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote_Option__c= quoteOption.Id;
        ref1.Quote__c=quot.id;
        ref1.Reason__c='Test';
        refreason.add(ref1);
        insert refreason;  
        
        Test.startTest();
        FinalizeQuoteController.finalizeQuote(quot.Id);  
        
        
        Test.stopTest();
        System.assertNotEquals(refreason, null);
    }
    
    static testMethod void finaliseTest_X3() { 
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Account Test Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
        Quote quot = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quot.OpportunityId = opp.Id;
        quot.Rating_Status__c = 'Refer';
        quot.Status = 'Rated';
        quot.Coverage_Product_Options__c = 'Professional Indemnity';
        insert quot; 
        quot.Rating_Status__c='clear';
        update quot;
        Quote_Option__c quoteOption = new  Quote_Option__c();
        quoteOption.Quote__c=quot.Id;
        quoteOption.Selected__c=true;
        insert quoteOption;
        
        List<Referral_Reason__c> refreason= new List<Referral_Reason__c>();
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='3';
        ref1.Approval_Status__c='';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote_Option__c= quoteOption.Id;
        ref1.Quote__c=quot.id;
        //ref1.Reason__c='Test';
        refreason.add(ref1);
        insert refreason;  
        
        Test.startTest();
        FinalizeQuoteController.finalizeQuote(quot.Id);  
        
        
        Test.stopTest();
        System.assertNotEquals(refreason, null);
    }	
    
    static testMethod void finaliseTest3() { 
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Account Test Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
        Quote quot = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quot.OpportunityId = opp.Id;
        quot.Rating_Status__c = 'Refer';
        quot.Status = 'Rated';
        quot.Coverage_Product_Options__c = 'Professional Indemnity';
        insert quot; 
        quot.Rating_Status__c='clear';
        update quot;
        Quote_Option__c quoteOption = new  Quote_Option__c();
        quoteOption.Quote__c=quot.Id;
        quoteOption.Selected__c=true;
        insert quoteOption;
        
        List<Referral_Reason__c> refreason= new List<Referral_Reason__c>();
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='3';
        ref1.Approval_Status__c='';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote_Option__c= quoteOption.Id;
        ref1.Quote__c=quot.id;
        ref1.Reason__c='Test';
        refreason.add(ref1);
        insert refreason;  
        
        Test.startTest();
        FinalizeQuoteController.finalizeQuote(quot.Id);  
        
        
        Test.stopTest();
        System.assertNotEquals(refreason, null);
    }	
    
    static testMethod void finaliseTest4() { 
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Account Test Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
        Quote quot = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quot.OpportunityId = opp.Id;
        quot.Rating_Status__c = 'Refer';
        quot.Status = 'Rated';
        quot.Coverage_Product_Options__c = 'Professional Indemnity';
        insert quot; 
        quot.Rating_Status__c='clear';
        update quot;
        Quote_Option__c quoteOption = new  Quote_Option__c();
        quoteOption.Quote__c=quot.Id;
        quoteOption.Selected__c=true;
        insert quoteOption;
        
        List<Referral_Reason__c> refreason= new List<Referral_Reason__c>();
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='4';
        ref1.Approval_Status__c='';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote_Option__c= quoteOption.Id;
        ref1.Quote__c=quot.id;
        ref1.Reason__c='Test';
        refreason.add(ref1);
        insert refreason;  
        
        Test.startTest();
        FinalizeQuoteController.finalizeQuote(quot.Id);  
        
        
        Test.stopTest();
        System.assertNotEquals(refreason, null);
    }
    
    static testMethod void testMethod_X2() { 
        Quote q = [SELECT Rating_Status__c,Id,OpportunityId, Opportunity.AccountId FROM Quote WHERE Name='Test Quote'];
        q.Rating_Status__c = '';
        update q;
        Additional_Insured__c addIn = new Additional_Insured__c();
        addIn.Submission__c = q.OpportunityId;
        addIn.Additional_Insured_Account__c = q.Opportunity.AccountId;
        insert addIn;
        Test.startTest();
        ResultResponse res = new ResultResponse(); 
        // ProcessInstanceWorkitem instanceworkItem = [SELECT id  FROM ProcessInstanceWorkitem Limit 1];
        
        res = FinalizeQuoteController.finalizeQuote(q.Id);
        FinalizeQuoteController.quoteDetails(q.Id);
        FinalizeQuoteController.generateApprovalURL(q.Id);
        FinalizeQuoteController.handleCloseReasons(q.Id);
        FinalizeQuoteController.checkIsPrimaryBroker(q.Id);
        System.assertNotEquals(res.data, null);
        Test.stopTest();        
    } 
    
    static testMethod void testMethod2() {                 
        Quote q = [SELECT Rating_Status__c,Id FROM Quote WHERE Name='Test Quote'];
        q.Rating_Status__c = '';
        update q;
        Test.startTest();
        ResultResponse res = new ResultResponse(); 
        // ProcessInstanceWorkitem instanceworkItem = [SELECT id  FROM ProcessInstanceWorkitem Limit 1];
        
        res = FinalizeQuoteController.finalizeQuote(q.Id);
        FinalizeQuoteController.quoteDetails(q.Id);
        FinalizeQuoteController.generateApprovalURL(q.Id);
        FinalizeQuoteController.handleCloseReasons(q.Id);
        FinalizeQuoteController.checkIsPrimaryBroker(q.Id);
        System.assertNotEquals(res.data, null);
        Test.stopTest();        
    }   
    
    static testMethod void testMethod3() {                 
        Quote q = [SELECT Status,Id FROM Quote WHERE Name='Test Quote'];
        q.Status = 'Quoted';
        update q;
        ResultResponse res = new ResultResponse();    
        Test.startTest();
        res = FinalizeQuoteController.finalizeQuote(q.Id);                 
        System.assertNotEquals(res.data, null);
        Test.stopTest();        
    }   
    
    static testMethod void testMethod_X4() {      
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product; 
        Opportunity opp = TestUtil.createOpportunity('Test opp', null, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        Quote q = TestUtil.createQuote('New Quote Test 2',opp.Id);
        q.Rating_Status__c = 'Refer';
        q.Status = 'Rated';
        q.Coverage_Product_Options__c = 'Professional Indemnity';
        insert q;
        Account acc = new Account();
        acc.Name = 'Test';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        acc.Appointed__c = false;
        insert acc;
        // Create contact
        Contact con = new Contact(
            Lastname = 'Huy broker',
            AccountId = acc.Id,
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        // Create broker
        Broker_Account__c broker = new Broker_Account__c(
            Broker_Contact__c = con.Id,
            Opportunity__c = q.OpportunityId,
            IsPrimaryBroker__c = true,
            Relationship_Type__c = 'Broker'
        );
        insert broker;
        ResultResponse res = new ResultResponse();  
        Test.startTest();
        res = FinalizeQuoteController.finalizeQuote(q.Id);                 
        System.assertNotEquals(res.data, null);
        Test.stopTest();
    } 
    
    static testMethod void testMethod4() {                 
        Quote q = [SELECT Rating_Status__c,Id FROM Quote WHERE Name='InProgress Quote'];
        q.Status = 'Rated';
        q.Rating_Status__c = 'Ineligible';
        update q;
        ResultResponse res = new ResultResponse();  
        Test.startTest();
        res = FinalizeQuoteController.finalizeQuote(q.Id);                 
        System.assertNotEquals(res.data, null);
        Test.stopTest();
    } 
    
    static testMethod void testMethod_X6() {    
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product; 
        Opportunity opp = TestUtil.createOpportunity('Test opp', null, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Source__c = 'SME';
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        Quote q = TestUtil.createQuote('New Quote Test 2',opp.Id);
        q.Rating_Status__c = 'Refer';
        q.Status = 'Rated';
        q.Coverage_Product_Options__c = 'Professional Indemnity';
        insert q;
        Quote_Option__c quoteOption = new  Quote_Option__c();
        quoteOption.Quote__c=q.Id;
        quoteOption.Selected__c=true;
        insert quoteOption;
        
        List<Referral_Reason__c> refreason= new List<Referral_Reason__c>();
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='3';
        ref1.Approval_Status__c='';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote_Option__c= quoteOption.Id;
        ref1.Quote__c=q.id;
        //ref1.Reason__c='Test';
        refreason.add(ref1);
        insert refreason; 
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        ResultResponse res = new ResultResponse();    
        Test.startTest();
        res = FinalizeQuoteController.finalizeQuote(q.Id); 
        FinalizeServiceHandler_Common.IncomingFinaliseQuoteResponse ifqr = new FinalizeServiceHandler_Common.IncomingFinaliseQuoteResponse();
        ifqr.status = 'test';
        ifqr.message = 'Test';
        ifqr.data = new FinalizeServiceHandler_Common.Data();
        ifqr.data.quoteId = 'Test';
        ifqr.data.status = 'Test';
        ifqr.data.Documents = new List<FinalizeServiceHandler_Common.Documents>();
        FinalizeServiceHandler_Common.Documents ifqrDoc = new FinalizeServiceHandler_Common.Documents();
        ifqrDoc.Id = 'test';
        ifqrDoc.GeneratedDate = 'Test';
        ifqrDoc.Type = 'test';
        ifqr.data.Documents.add(ifqrDoc);
        System.assert(res != null);
        Test.stopTest();
    }
    static testMethod void testMethod_X5() {                 
        Quote q = [SELECT Rating_Status__c,Id FROM Quote WHERE Name='InProgress Quote'];
        q.Status = 'Rated'; 
        q.Rating_Status__c = 'Clear';
        update q;
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        ResultResponse res = new ResultResponse();    
        Test.startTest();
        res = FinalizeQuoteController.finalizeQuote(q.Id);                 
        System.assert(res != null);
        Test.stopTest();
    } 
    
    static testMethod void testMethod5() {                 
        Quote q = [SELECT Rating_Status__c,Id FROM Quote WHERE Name='InProgress Quote'];
        q.Status = 'Rated'; 
        q.Rating_Status__c = 'Clear';
        update q;
        ResultResponse res = new ResultResponse();    
        Test.startTest();
        res = FinalizeQuoteController.finalizeQuote(q.Id);                 
        System.assert(res != null);
        Test.stopTest();
    } 
    
    static testMethod void testException() {    
        Test.startTest();
        ResultResponse res = new ResultResponse();        
        res = FinalizeQuoteController.finalizeQuote('1');                 
        System.assertEquals(res.data, null);
        Test.stopTest();
    }
    
    static testMethod void testGetQuoteDetails() {
        Quote q = [SELECT Id FROM Quote WHERE Name='InProgress Quote'];
        q.Status = 'Rated';
        update q;
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(q.id);
        app.setNextApproverIds(new List<Id>{userInfo.getUserId()});
        Approval.ProcessResult result = Approval.process(app);
        Test.startTest();
        Boolean isMatching = FinalizeQuoteController.getQuoteDetails(q.id);
        System.assertEquals(false,isMatching);
        Test.stopTest();
    }
    
    static testMethod void testGetQuoteDetails2() {
        Quote q = [SELECT Id FROM Quote WHERE Name='InProgress Quote'];
        q.Status = 'Rated';
        update q;
        User u = [SELECT id FROM User Where id!=:UserInfo.getUserId() AND Profile.Name='System Administrator' AND isActive=true LIMIT 1];
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(q.id);
        app.setNextApproverIds(new List<Id>{u.Id});
        Approval.ProcessResult result = Approval.process(app);
        Test.startTest();
        Boolean isMatching = FinalizeQuoteController.getQuoteDetails(q.id);
        System.assertEquals(true,isMatching);
        Test.stopTest();
    }
    
    static testMethod void getQuoteApprovalCommentsTest(){
        FinalizeServiceHandler_AQ.CommentsWrapper cws = new FinalizeServiceHandler_AQ.CommentsWrapper(new ProcessInstanceStep(Comments='Test'));
        Quote q = [SELECT Id FROM Quote WHERE Name='InProgress Quote'];        
        Test.startTest();
        List<FinalizeServiceHandler_AQ.CommentsWrapper> wrapper = FinalizeServiceHandler_AQ.getQuoteApprovalComments(q.Id);
        Test.stopTest();
        System.assert(wrapper != null);
    }
    
    /*static testMethod void testFinalizeQuoteResult() {
Test.startTest();
Quote q = [SELECT Id FROM Quote WHERE Name='InProgress Quote'];
FinalizeQuoteController.FinalizeQuoteResult res = new FinalizeQuoteController.FinalizeQuoteResult();
res.errorMessage = 'Testing Error';
System.assertEquals('Testing Error', res.errorMessage);
res.updatedQuote = q;
System.assertEquals(q.Id, (res.updatedQuote).Id);
Test.stopTest();
}*/
    
    static testMethod void testcheckPartFixedEndorsement() { 
        Test.startTest();
        Quote q = [SELECT Status,Id FROM Quote WHERE Name='Test Quote'];
        q.Status = 'Quoted';
        update q;
        
        
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
        insert cov;
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        List< CoveragesLineItem__c> lCov = new List< CoveragesLineItem__c>();
        CoveragesLineItem__c coverLi = new CoveragesLineItem__c();
        coverLi.Coverage__c  = cov.Id; 
        coverLi.Quote__c = q.Id;
        coverLi.Coverage_Premium__c  = 'Text Premium'; 
        coverLi.Min_amt__c  = 1000;
        coverLi.Max_amt__c  = 5000;
        coverLi.Deductible_Frequency__c  = 'Daily';
        coverLi.Options_Value_Percent__c  = 5;
        coverLi.Limits_Deductibles__c=ded.id;
        coverLi.Option_Value_Default__c=null;
        lCov.add(coverLi);
        insert lCov;
        
        List<Quote_Option__c> listQuoteOption= new List<Quote_Option__c>();
        Quote_Option__c qo= new Quote_Option__c();
        qo.Actual_Premium_Final__c=10000;
        qo.Actual_Premium_Annual__c=30000;
        qo.Quote__c=q.Id;
        Quote_Option__c qo1= new Quote_Option__c();
        qo1.Actual_Premium_Final__c=10000;
        qo1.Actual_Premium_Annual__c=30000;
        qo1.Quote__c=q.Id;
        listQuoteOption.add(qo);
        listQuoteOption.add(qo1);
        
        
        
        FinalizeQuoteController.checkPartFixedEndorsement(q.Id);
        FinalizeQuoteController.checkSelectedQuoteOption(q.Id);
        Test.stopTest();   
        System.assertNotEquals(lCov, null);
    }   
    
    @isTest
    static void forApprovalTest(){
        Test.startTest();
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Account Test Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 product = TestUtil.createProduct('Professional Indemnity');
        product.RecordTypeId = aqueousRecordTypeId; 
        product.Innovisk_Entity_ID__c = 'Aqueous';
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Test opp', acc1.Id, product.Id);
        opp.Innovisk_Entity_ID__c = 'Aqueous';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();                            
        opp.Product__c = product.Id;
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New Quote Test 2',opp.Id);
        quote1.OpportunityId = opp.Id;
        quote1.Rating_Status__c = 'Refer';
        quote1.Status = 'In Approval';
        quote1.Coverage_Product_Options__c = 'Professional Indemnity';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1; 
        List<Referral_Reason__c> refreason= new List<Referral_Reason__c>();
        Referral_Reason__c ref1=new Referral_Reason__c();
        ref1.Approver_Level__c='3';
        ref1.Approval_Level_Required__c='1';
        //ref1.Approval_Status__c='Approved';
        ref1.Approval_Rejected_Date__c= date.today()+365;
        ref1.Quote__c=quote1.id;
        refreason.add(ref1);
        Referral_Reason__c ref2=new Referral_Reason__c();
        ref2.Approver_Level__c='0';
        ref2.Approval_Level_Required__c='2';
        //ref2.Approval_Status__c='Rejected';
        ref2.Approval_Rejected_Date__c= date.today()+365;
        ref2.Quote__c=quote1.id;
        refreason.add(ref2);
        insert refreason;  
        
        quote1.Status = 'Rated';
        update quote1;
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(quote1.id);
        
        app.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        Approval.ProcessResult result = Approval.process(app);
        
        FinalizeQuoteController.finalizeQuote(quote1.id);
        FinalizeQuoteController.handleCloseReasons(quote1.Id);
        Test.stopTest();
        system.assertNotEquals(refreason, null);
    }
    @isTest
    static void TestvalidateSyncForQuoteBind(){
        Test.startTest();
        AsyncApexJob job = [select Status,NumberOfErrors FROM AsyncApexJob LIMIT 1];
        FinalizeQuoteController.validateSyncForQuoteBind(job.Id);
        Test.stopTest();
        system.assert(job != null);
        
    }
    
    //Mary
    @istest
    static void testMethod_Doc() {
         
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        
        Quote q = [SELECT Id, Azure_ID__c FROM Quote WHERE Name='Test Quote']; 
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test';
        quoteOpt.Quote__c =  q.Id;
        quoteOpt.Selected__c = true;
        insert quoteOpt;
        Coverage__c cov = TestUtil.createCoverage('Test Coverage','D&O');
        insert cov;
        Coverage_Limits_Deductibles__c lded = new Coverage_Limits_Deductibles__c(Name = 'Test');
        lded.RecordTypeId = Schema.SObjectType.Coverage_Limits_Deductibles__c.getRecordTypeInfosByName().get('Deductible Option').getRecordTypeId(); 
        lded.Parent_Coverage__c = cov.Id;
        lded.Limit_Deductible_Type__c = 'Endorsement';
        insert lded;
        CoveragesLineItem__c cli = new CoveragesLineItem__c();
        cli.Quote__c = q.Id;
        //cli.CoverageLineItemType__c='Limit Option';
        cli.Limits_Deductibles__c = lded.Id;
        cli.Coverage__c = cov.Id;
        insert cli;
        
        Test.startTest();
        //HttpResponse res = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', q, 'functionName');
       // FinalizeServiceHandler_Common.generateFinalizeDocument(q.Azure_ID__c,q.Id);
        FinalizeService.finalizeAndGenerateDocAQ(q);
      /*  FinalizeServiceHandler_Common.finalizeAndGenerateDoc(q);
        FinalizeQuoteController.checkSelectedQuoteOption(q.Id);
        FinalizeQuoteController.checkPartFixedEndorsement(q.Id); */ 
        Test.stopTest();
        System.assertNotEquals(q.Id, null);
    }
    
     @istest
    static void testMethod_Doc_Cont() {
         
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        
        Quote q = [SELECT Id, Azure_ID__c FROM Quote WHERE Name='Test Quote']; 
        Quote_Option__c quoteOpt = new Quote_Option__c();
        quoteOpt.Azure_ID__c = 'Test';
        quoteOpt.Quote__c =  q.Id;
        quoteOpt.Selected__c = true;
        insert quoteOpt;
        Coverage__c cov = TestUtil.createCoverage('Test Coverage','D&O');
        insert cov;
        Coverage_Limits_Deductibles__c lded = new Coverage_Limits_Deductibles__c(Name = 'Test');
        lded.RecordTypeId = Schema.SObjectType.Coverage_Limits_Deductibles__c.getRecordTypeInfosByName().get('Deductible Option').getRecordTypeId(); 
        lded.Parent_Coverage__c = cov.Id;
        lded.Limit_Deductible_Type__c = 'Endorsement';
        insert lded;
        CoveragesLineItem__c cli = new CoveragesLineItem__c();
        cli.Quote__c = q.Id;
        //cli.CoverageLineItemType__c='Limit Option';
        cli.Limits_Deductibles__c = lded.Id;
        cli.Coverage__c = cov.Id;
        insert cli;
        
        Test.startTest();
        //HttpResponse res = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', q, 'functionName');
       // FinalizeServiceHandler_Common.generateFinalizeDocument(q.Azure_ID__c,q.Id);
      //  FinalizeService.finalizeAndGenerateDocAQ(q);
        FinalizeServiceHandler_Common.finalizeAndGenerateDoc(q);
        FinalizeQuoteController.checkSelectedQuoteOption(q.Id);
        FinalizeQuoteController.checkPartFixedEndorsement(q.Id);
        Test.stopTest();
        System.assertNotEquals(q.Id, null);
    }
    
    
    @isTest static void finalizeAndGenerateDocAQTest(){
        test.startTest();
        API_Log__c apiLog = new API_Log__c();
        apiLog.Name = 'Test';
        apiLog.Status__c = 'OK';
        test.stopTest(); 
    }
}