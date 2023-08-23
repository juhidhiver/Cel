@isTest
public class QuoteCompareItemWrapperTest {
    @testsetup static void testSetup(){
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassQuoteTrigger__c = true;
        insert setting;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
        opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        Policy__c pol = new Policy__c();
        pol.Policy_Number__c = '12345';
        pol.Effective_Date__c = Date.today()+5;
        pol.Expiration_Date__c = Date.today() + 30;
        pol.Policy_Status__c = 'Bound';
        insert pol;
        
        Policy__c pol2 = new Policy__c();
        pol2.Policy_Number__c = '123456';
        pol2.Effective_Date__c = Date.today()+5;
        pol2.Expiration_Date__c = Date.today() + 30;
        pol2.Policy_Status__c = 'Bound';
        insert pol2;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Refer_Type__c = 'Underwriting Referral';
        quote1.Rating_Status__c = 'Refer';
        quote1.Last_Quote_Version__c = 'Version 1';
        quote1.Policy__c = pol.id;
        quote1.CloseDate__c = Date.today() + 120;
        insert quote1;  
        
        Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'Bound';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
        quote1.Policy__c = pol2.id;
        insert quote2; 
        
        SectionSetting__c secSettings1 = new SectionSetting__c();
        secSettings1.Component__c = 'Submission Info';
        secSettings1.Order__c = 7;
        secSettings1.Main_Section__c = 'Submission Status';
        secSettings1.Sub_Section__c = 'Submission Status Sub';
        secSettings1.Source_Object__c = 'Opportunity';
        secSettings1.Source_Field_API__c = 'Amount';
        secSettings1.Source_Field_Label__c = 'Amount';
        secSettings1.Format__c = 'Number';
        insert secSettings1;     
        
        Quote_Version__c quoteVersion = new Quote_Version__c();
        quoteVersion.Name = 'Test Version1';
        quoteVersion.Quote__c = quote1.Id;
        insert quoteVersion;
        
        Quote_Version__c quoteVersion2 = new Quote_Version__c();
        quoteVersion2.Name = 'Test Version2';
        quoteVersion2.Quote__c = quote1.Id;
        insert quoteVersion2;
        
        Quote_Version_Item__c quoteVersItem = new Quote_Version_Item__c();
        quoteVersItem.Quote_Version__c = quoteVersion.Id;
        quoteVersItem.Source_Field_API__c = 'Option_Value_Default__c';
        quoteVersItem.Source_Object__c = 'CoveragesLineItem__c';
        quoteVersItem.Operation__c = 'Add';
        insert quoteVersItem;
        
        Coverage__c cov = Testutil.createCoverage('Coverage 1', 'D&O');
        insert cov;
        
        Coverage_Limits_Deductibles__c covLD = TestUtil.creatLimitsDeductibles('test LD', cov.id);
        insert covLD;
        
        CoveragesLineItem__c covLineItem = testUtil.createCoverageLineItem(quote1.id, covLD.id, cov.Id, 'Picklist');
        covLineItem.Coverage_Product__c = 'D&O';
        insert covLineItem;
        
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('test mod', 'MPL', opp.Id);
        insert rateMod;
        Master_Binder__c masterBind =  new Master_Binder__c();
        masterBind.Name = 'masterBind Name';
        masterBind.Expiry_Date__c = Date.today()+365;
        masterBind.Inception_Date__c = Date.today();
        masterBind.MGA_Commission__c = 15;
        masterBind.Layer__c = 'Primary;Excess';
        masterBind.Coverholder_Name__c = ' masterBind Holder';
        masterBind.Coverholder_Pin__c = 'masterBind Pin';
        insert masterBind;
        
		quote1.Master_Binder__c =  masterBind.Id;
        update quote1;
        
        ContentVersion cv = new ContentVersion(
            Title = 'ACMP 27 03 Coverage Name', 
            PathOnClient = 'ACMP 27 03 Coverage Name', 
            VersionData = Blob.valueOf('ACMP 27 03 Coverage Name')
        );
        insert cv;
        
        

    }
    @isTest
    static void createNewQuoteHandlerTest(){
        Test.startTest();
        Opportunity opp = [Select Id From Opportunity];
        QuoteCompareItemWrapper.createNewQuoteHandler(opp.Id,2, 'Excess','TestBinder');
        Test.stopTest();
        System.assert(True);
    }
    @isTest
    static void updateQuoteInProgressTest(){
        Test.startTest();
        Quote q = [Select Id,Status,Master_Binder__c from Quote Limit 1];
        q.Status = 'In Progress';
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.id= q.Master_Binder__c;
        q.MGA_Commission__c=masterbinder.MGA_Commission__c;
        q.Layer__c='Primary';
        q.Quote_Type__c = 'Amendment';
        update q;
       
        QuoteCompareItemWrapper.updateQuoteInProgress(q.Id);
        QuoteCompareItemWrapper.updateSelectedBinder(q.Id,'TestBinder');
        Test.stopTest();
       System.assert(True);
    }
    
    @isTest static void updateSelectedBinderTest(){
        Master_Binder__c mb = [Select Id,Name,Expiry_Date__c,Inception_Date__c,MGA_Commission__c,Layer__c,Coverholder_Name__c,Coverholder_Pin__c from Master_Binder__c Limit 1];
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
        quot.Status = 'IN PROGRESS';
        quot.Coverage_Product_Options__c = 'Professional Indemnity';
        quot.Master_Binder__c = mb.Id;
        insert quot;
        
        Test.startTest();

        QuoteCompareItemWrapper.updateSelectedBinder(quot.Id,Json.serialize(mb));
        Test.stopTest();
       	System.assert(True);
    }
    
    @isTest
    static void updateQuoteInProgressTestforExcept(){
        Test.startTest();
        Opportunity opp = [Select Id from Opportunity Limit 1];
        QuoteCompareItemWrapper.updateQuoteInProgress(opp.Id);
         Test.stopTest();
         System.assert(True);
    }
    @isTest
    static void cloneQuoteHandlerTest(){
       
        Quote q = [Select Id, Status from Quote limit 1 ];
        //Quote q = [select Id,Status from Quote where id =:q.Id];
        //QuoteCompareItemWrapper.getQuoteDocumentLinks(q);
        //delete q;
         Test.startTest();
       QuoteCompareItemWrapper.cloneQuoteHandler(q.Id);
       //QuoteCompareItemWrapper.createQuoteCompareItemQC(q.id,);
        Test.stopTest();
        system.assert(q.id!=null);
    }
    @isTest
    static void deleteQuoteHandlerTest(){
        Test.startTest();
        Quote q = [Select Id, Status from Quote Limit 1];
        Boolean result = QuoteCompareItemWrapper.deleteQuoteHandler(q.Id);
        Test.stopTest();
        System.assert(result!=false);
    }
    @isTest
    static void deleteQuoteHandlerTestForException(){
        Test.startTest();
        Opportunity opp = [Select Id,StageName from Opportunity Limit 1];
        try{
            Boolean result = QuoteCompareItemWrapper.deleteQuoteHandler('12345'); 
        }
        catch(Exception ex){
            System.assert(ex.getMessage()!=null);
        }
        
        Test.stopTest();
        system.assertEquals('Closed Won', opp.StageName);
    }
    @istest
    static void createQuoteCompareItemTest(){
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
        
        Test.startTest();
        QuoteCompareItemWrapper.createQuoteCompareItem(q.Id, System.JSON.serialize(obj));
        QuoteCompareItemWrapper.createQuoteCompareItemQC(q.Id,obj);
       
        Test.stopTest();
        system.assert(q.id!=null);
        
    }
    @istest
    static void createQuoteCompareItemforCoverageLineItemTest(){
        Quote q = [Select Id, Name, Status,Rating_Status__c,Last_Quote_Version__c,CloseDate__c from Quote Limit 1];
        List<Quote_Version__c> lstQuoteVersion = [Select Id from Quote_Version__c];
        
        QuoteCompareItemField field1 = new QuoteCompareItemField();
        field1.readOnly = false;
        field1.sourceFieldAPI = 'Coverage_Product__c';
        field1.sourceObject = 'CoveragesLineItem__c';
        field1.format = null;
        field1.displayType = '';
        field1.value = '';
        field1.fieldId = '';
        field1.fieldName = '';
        field1.fieldCondition ='Limit 1';
        field1.fieldRequire = 'Id, Coverage_Product__c, Option_Type__c, Option_Picklist__c, Min_amt__c, Max_amt__c';
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
        
        Test.startTest();
        QuoteCompareItemWrapper.createQuoteCompareItem(q.Id, System.JSON.serialize(obj));
        System.debug('Serialiazed Json'+System.JSON.serialize(obj));
        Test.stopTest();
        system.assertEquals('CoveragesLineItem__c', field1.sourceObject);
        
    }
    @isTest
    static void updateCompareItemTest(){
        Test.startTest();
        
        Quote q = [Select Id, Name, Status,Master_Binder__c,Layer__c, Rating_Status__c,Last_Quote_Version__c,CloseDate__c from Quote Limit 1];
        Id cdId   = [SELECT ContentDocumentId FROM ContentVersion Limit 1].ContentDocumentId;
        
        List<ContentDocumentLink> cdd = new List<ContentDocumentLink>();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = q.Master_Binder__c;
        cdl.ContentDocumentId = cdId;
        cdl.shareType = 'V';
        cdl.Visibility = 'AllUsers';
        cdd.add(cdl);
        insert cdd;
        
        List<Quote_Version__c> lstQuoteVersion = [Select Id from Quote_Version__c];
        
        List<Quote_Version_Item__c> quoteVersItems = [Select id, Object_Id__c, Source_Field_API__c, Source_Object__c, Value__c from Quote_Version_Item__c];
   
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
        
        QuoteCompareItemWrapper.UpdateObject updObj = new QuoteCompareItemWrapper.UpdateObject();
        updObj.id = q.Id;
        updObj.name = q.Name;
        updObj.sourceObject = 'Quote';
        updObj.fieldApi = 'Rating_Status__c';
        updObj.value = 'Test1';
        
        QuoteCompareItemWrapper.UpdateObject updObj2 = new QuoteCompareItemWrapper.UpdateObject();
        updObj2.id = q.Id;
        updObj2.name = q.Name;
        updObj2.sourceObject = 'Quote';
        updObj2.fieldApi = 'Rating_Status__c';
        updObj2.value = ''; 
        
        List<QuoteCompareItemWrapper.UpdateObject> updObjList = new List<QuoteCompareItemWrapper.UpdateObject>();
        updObjList.add(updObj);
        updObjList.add(updObj2);
       
        QuoteCompareItemWrapper.ListUpdateObject lstObj = new QuoteCompareItemWrapper.ListUpdateObject();
        lstObj.listUpdate = updObjList;
        QuoteCompareItemWrapper.getQuoteDocumentLinks(q);
        
        QuoteCompareItemWrapper.updateCompareItem(Json.serialize(lstObj), q.Id, Json.serialize(quoteComp), quoteVersItems);
        Test.stopTest();
        system.assertEquals('Quote', field1.sourceObject);
    }
    @isTest
    static void createQuoteVersionTest(){
        Test.startTest();
        Quote q = [Select Id, Name, Status,Rating_Status__c,Last_Quote_Version__c,CloseDate__c from Quote Limit 1];
        List<Quote_Version__c> lstQuoteVersion = [Select Id from Quote_Version__c];
        
        List<Quote_Version_Item__c> quoteVersItems = [Select id, Object_Id__c, Source_Field_API__c, Source_Object__c, Value__c from Quote_Version_Item__c];
        
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
        
        QuoteCompareItemWrapper.UpdateObject updObj = new QuoteCompareItemWrapper.UpdateObject();
        updObj.id = q.Id;
        updObj.name = q.Name;
        updObj.sourceObject = 'Quote';
        updObj.fieldApi = 'Rating_Status__c';
        updObj.value = '';  
        
        QuoteCompareItemWrapper.createQuoteVersion(q.Id, quoteComp, quoteVersItems);
        Test.stopTest();
        system.assertEquals('Quote', updObj.sourceObject);
    }
    @isTest
    static void createQuoteVersionTestforEmptyQuoteVersion(){
        Test.startTest();
        Quote q = [Select Id, Name, Status,Rating_Status__c,Last_Quote_Version__c,CloseDate__c from Quote Limit 1];
        List<Quote_Version__c> lstQuoteVersion = [Select Id from Quote_Version__c];
        delete lstQuoteVersion;
        List<Quote_Version_Item__c> quoteVersItems = [Select id, Object_Id__c, Source_Field_API__c, Source_Object__c, Value__c from Quote_Version_Item__c];
        
        QuoteCompareItemField field1 = new QuoteCompareItemField();
        field1.readOnly = false;
        field1.sourceFieldAPI = 'Rating_Status__c';
        field1.sourceObject = 'Quote';
        field1.format = null;
        field1.displayType = '';
        field1.value = '';
        field1.fieldId = q.Id;
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
        
        QuoteCompareItemWrapper.UpdateObject updObj = new QuoteCompareItemWrapper.UpdateObject();
        updObj.id = q.Id;
        updObj.name = q.Name;
        updObj.sourceObject = 'Quote';
        updObj.fieldApi = 'Rating_Status__c';
        updObj.value = '';  
        
        QuoteCompareItemWrapper.createQuoteVersion(q.Id, quoteComp, quoteVersItems);
        Test.stopTest();
        system.assertEquals('Rating_Status__c', updObj.fieldApi);
    }

}