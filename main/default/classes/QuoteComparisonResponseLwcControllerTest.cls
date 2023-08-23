/**************************************************************************************************
* Class Name: QuoteComparisonResponseLwcControllerTest
* Modified By: Ashik Zahir
* Modifiied date: 15-Feb-2021
* Description: Test class for QuoteComparisonResponseLwcController
**************************************************************************************************/
@isTest
public class QuoteComparisonResponseLwcControllerTest {
	@testsetup static void testSetup(){
        
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
		setting.BypassOpportunityTrigger__c = true;
		setting.BypassAccountTrigger__c = true;
        setting.BypassProductTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        update setting;
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('MPL Standalone');
		insert product; 
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
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        opp.Policy__c = pol.id;
        insert opp;
       
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
     	quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;  

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'In Progress';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
        insert quote2; 
        
        //Creating Opportunities without Quote
        Account acc2 = TestUtil.createBusinessAccount('Bussiness Account Test2', 'Business', '123 Main Street', 'Anycity', 'New York', '11355', 'United States');
		insert acc2;
        
        Product2 product2 = TestUtil.createProduct('Product 2');
		insert product2; 

        Opportunity opp2 = TestUtil.createOpportunity('Opp Test2',acc2.Id, product2.Id);
        opp2.CloseDate = Date.today();
        opp2.StageName = 'Prospect';
        insert opp2;

        //SectionSetting
        SectionSetting__c secSettings1 = new SectionSetting__c();
    	secSettings1.Component__c = 'Rate Quotes';
        secSettings1.Quote_Layer__c = 'Primary;Excess';
        secSettings1.Order__c = 4;
   		secSettings1.Main_Section__c = 'Premium Data';
    	secSettings1.Source_Object__c = 'Quote';
   		//secSettings1.Source_Field_API__c = 'Tax';
        secSettings1.Source_Field_Label__c = 'Tax';
        secSettings1.Format__c = 'Currency';
    	//secSettings1.Sub_Section__c = 'Premium Data';
        secSettings1.Record_Type__c = 'Celerity';
        secSettings1.Active__c = True;
        secSettings1.Product__c = 'MPL';
		insert secSettings1;  
        
        SectionSetting__c secSettings2 = new SectionSetting__c();
    	secSettings2.Component__c = 'Rate Quotes';
        secSettings2.Quote_Layer__c = 'Primary;Excess';
        secSettings2.Order__c = 4;
   		secSettings2.Main_Section__c = 'Premium Data';
    	secSettings2.Source_Object__c = 'Quote';
   		//secSettings2.Source_Field_API__c = 'Tax';
        secSettings2.Source_Field_Label__c = 'Tax';
        secSettings2.Format__c = 'Currency';
    	secSettings2.Sub_Section__c = 'Premium Data';
        secSettings2.Record_Type__c = 'Celerity';
        secSettings2.Active__c = True;
        secSettings2.Product__c = 'MPL';
		insert secSettings2;  
        
        SectionSetting__c secSettings3 = new SectionSetting__c();
    	secSettings3.Component__c = 'Rate Quotes';
        secSettings3.Quote_Layer__c = 'Primary;Excess';
        secSettings3.Order__c = 4;
   		secSettings3.Main_Section__c = 'Premium Data';
    	secSettings3.Source_Object__c = 'Quote';
   		//secSettings3.Source_Field_API__c = 'Tax';
        secSettings3.Source_Field_Label__c = 'Tax';
        secSettings3.Format__c = 'Currency';
    	secSettings3.Sub_Section__c = 'Premium Data';
        secSettings3.Record_Type__c = 'Celerity';
        secSettings3.Active__c = True;
        secSettings3.Product__c = 'MPL';
		insert secSettings3;  
          	
        Quote_Version__c quoteVersion = new Quote_Version__c();
        quoteVersion.Name = 'Test Version1';
        quoteVersion.Quote__c = quote1.Id;
        insert quoteVersion;
        
        Master_Binder__c masterBind =  new Master_Binder__c();
        masterBind.Name = 'masterBind Name';
        masterBind.Expiry_Date__c = Date.today()+365;
        masterBind.Inception_Date__c = Date.today();
        masterBind.MGA_Commission__c = 15;
        masterBind.Layer__c = 'Primary;Excess';
        masterBind.Coverholder_Name__c = ' masterBind Holder';
        masterBind.Coverholder_Pin__c = 'masterBind Pin';
        insert masterBind;
              
    }
    
    @isTest
    static void getMainTitlesTest(){
        Test.startTest();
        Opportunity opp = [Select Id,StageName from Opportunity where StageName='Prospect' Limit 1];
        Quote q = [Select Id from Quote Limit 1];
        QuoteComparisonResponseLwcController.getMainTitles(opp.Id, true);
        new QuoteComparisonResponseLwcController.ListRowTittleWrapper(new List<QuoteComparisonResponseLwcController.RowTitleWrapper>{}, new List<QuoteCompareItemWrapper>{});
        Test.stopTest();
        system.assertEquals('Prospect', opp.StageName);
    }
    
    @isTest
    static void createInitQuoteTest(){
        Test.startTest();
        Opportunity opp = [Select Id,StageName from Opportunity where StageName='Prospect' Limit 1];
        QuoteComparisonResponseLwcController.createInitQuote(opp.Id, 'Primary','Test',True);
        Test.stopTest();
        system.assertEquals('Prospect', opp.StageName);
    }
      
    @isTest
    static void createInitQuoteTest1(){
        Test.startTest();
         Quote q = [Select Id,Layer__c from Quote Limit 1];
        q.Layer__c='Excess';
        update q;
        Opportunity opp = [Select Id,StageName from Opportunity where StageName='Prospect' Limit 1];
        QuoteComparisonResponseLwcController.createInitQuote(opp.Id, 'Excess','Test',True);
        Test.stopTest();
        system.assertEquals('Prospect', opp.StageName);
    }
    
     @isTest
    static void createInitQuoteTestforNoQuotes(){
        Test.startTest();       
        Opportunity opp = [Select Id,StageName from Opportunity where StageName='Prospect' Limit 1];
        List<Quote> qouteList = [Select Id, OpportunityId from Quote where OpportunityId=:opp.Id];
        delete qouteList;
        QuoteComparisonResponseLwcController.createInitQuote(opp.Id, 'Primary','Test',True);
        Test.stopTest();
        system.assertEquals('Prospect', opp.StageName);
    }
     
     @isTest
    static void createInitQuoteTestforException(){
        Test.startTest();       
        Opportunity opp = [Select Id,StageName from Opportunity where StageName='Prospect' Limit 1];
        List<Quote> qouteList = [Select Id, OpportunityId from Quote where OpportunityId=:opp.Id];
        delete qouteList;
        QuoteComparisonResponseLwcController.createInitQuote(qouteList[0].id, 'Primary','Test',True);
        Test.stopTest();
        system.assertEquals('Prospect', opp.StageName);
    }
    
    @isTest
    static void sortListQuoteTest(){
        Test.startTest();
        List<Quote> quotes = [Select Id, Name from Quote];
        List<Id> quoteIds = new List<Id>();
        for(Quote q:quotes){
            quoteIds.add(q.Id);
        }        
        QuoteComparisonResponseLwcController.sortListQuote(quotes, quoteIds);
        Test.stopTest();
        system.assert(quoteIds!=null);
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
        QuoteComparisonResponseLwcController.getMainColumns(Json.serialize(obj));
        Test.stopTest();
        system.assertEquals('Quote', field1.sourceObject);
    }

    
    @isTest
    static void getListRowTittleWrapperTest(){
        
        Opportunity opp = [Select Id,StageName from Opportunity where StageName='Prospect' Limit 1];
            
        Test.startTest();
        QuoteComparisonResponseLwcController.getListRowTittleWrapper(opp.Id, true);
        QuoteComparisonResponseLwcController.getMainColumns('5S');
        Test.stopTest();
        system.assertEquals('Prospect', opp.StageName);
    }
     @isTest
    static void testGetQuoteRecords(){
        
        //Opportunity opp = [Select Id,StageName from Opportunity where StageName='Closed Won' Limit 1];
        Opportunity opp = [SELECT Id,StageName from Opportunity limit 1];
		opp.StageName='Closed Won';
		update opp;   
        Test.startTest();
        QuoteComparisonResponseLwcController.getQuoteRecords(opp);
        QuoteComparisonResponseLwcController.getMainColumns('5S');
        Test.stopTest();
        system.assertEquals('Closed Won', opp.StageName);
    }
    @isTest
    static void TestGetDefaultLayer(){
        Test.startTest();
        List<Quote> quotes = [Select Id, Name, Layer__c from Quote];
        quotes[0].Layer__c = 'Excess';
        update quotes[0];
        
     	String result = QuoteComparisonResponseLwcController.getDefaultLayer(quotes);
        Test.stopTest();
        system.assertEquals('Excess', quotes[0].Layer__c);
    }
        @isTest
        static void TestAqueous(){
        Test.startTest();
       
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'AnyCity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 prod = TestUtil.createProduct('Professional Indemnity');
        prod.RecordTypeId = aqueousRecordTypeId;
        prod.Innovisk_Entity_ID__c = 'Aqueous';
		insert prod;
       
        Opportunity oppaq = TestUtil.createOpportunity('Aqueous Test',acc.Id, prod.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';        
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.StageName = 'Prospect';
        insert oppaq;
        
        Quote quoteaq = Testutil.createQuote('New Quote 2', oppaq.Id);
        quoteaq.Status = 'In Progress';
        quoteaq.Refer_Type__c = 'Underwriting Referral';
        insert quoteaq;
        quoteaq.Layer__c='Excess';
        update quoteaq;
        
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.id= quoteaq.Master_Binder__c;
        
        //Opportunity oppaq = [Select Id,StageName from Opportunity where Name='Aqueous Test' Limit 1];
        QuoteComparisonResponseLwcController.createInitQuote(oppaq.Id,'Excess','Test',true);
          QuoteComparisonResponseLwcController.createInitQuote(oppaq.Id,'Excess',System.JSON.serialize(masterbinder),true);
        QuoteComparisonResponseLwcController.createInitQuote(oppaq.Id,'Excess',System.JSON.serialize(masterbinder),false);
        Test.stopTest();
        system.assertEquals('Underwriting Referral',quoteaq.Refer_Type__c);
    }
     @isTest
     static void TestAqueous1(){
        Test.startTest();
       
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'AnyCity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 prod = TestUtil.createProduct('Professional Indemnity');
        prod.RecordTypeId = aqueousRecordTypeId;
        prod.Innovisk_Entity_ID__c = 'Aqueous';
		insert prod;
        
        Opportunity oppaq = TestUtil.createOpportunity('Aqueous Test',acc.Id, prod.Id);
        oppaq.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        oppaq.Innovisk_Entity_ID__c = 'Aqueous';        
        oppaq.Coverage_Product_Options__c = 'Professional Indemnity';
        oppaq.StageName = 'Qualified';
        insert oppaq;
        
        Quote quoteaq = Testutil.createQuote('New Quote 2', oppaq.Id);
        //quoteaq.Status = 'In Progress';
        //quoteaq.Refer_Type__c = 'Underwriting Referral';
        quoteaq.Quote_Type__c='Renewal';
        insert quoteaq;
       
        Master_Binder__c masterbinder =new Master_Binder__c();
        masterbinder.id= quoteaq.Master_Binder__c;
        delete quoteaq;
        //Opportunity oppaq = [Select Id,StageName from Opportunity where Name='Aqueous Test' Limit 1];
        QuoteComparisonResponseLwcController.createInitQuote(oppaq.Id,null,'Test',true);
        Test.stopTest();
        system.assertEquals('Renewal', quoteaq.Quote_Type__c);
    }
 
}