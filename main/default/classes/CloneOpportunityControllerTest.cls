@isTest
public class CloneOpportunityControllerTest {
    @testSetup static void setup() {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassQuoteTrigger__c = false;
        update setting;
 
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
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
        
        Rating_Modifiers__c rateMod = TestUtil.createRatingModifier('Cyber Intel Average Score', 'Cyber', oppaq.Id);
        rateMod.Rating_Modifier_Code__c='MPL000012';
        insert rateMod;
        
        Quote quoteaq = Testutil.createQuote('New Quote 2', oppaq.Id);
        quoteaq.Rating_Status__c = 'Clear';
        quoteaq.Status = 'Quoted';       
        insert quoteaq;
        quoteaq.Layer__c='Excess';
        update quoteaq;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = acc.Id;
        qp.Submission__c = oppaq.Id;
        insert qp;
        UW_Analysis_Template__c TempList = new UW_Analysis_Template__c();
        TempList.UW_Analysis_Name__c = 'Test';
        TempList.Criteria__c = 'Engineers';
        TempList.UW_Analysis_Code__c ='Code';
        TempList.Rating_Factor__c= 5000;
        TempList.Sort_Order__c = 100;
        insert TempList;
        
        List<UW_Analysis__c> uw = new List<UW_Analysis__c>();
        
        UW_Analysis__c uwList = new UW_Analysis__c();
        uwList.Amount__c = 1000;
        uwList.UW_Analysis_Name__c = 'UW Test';
        uwList.Criteria__c = 'Territory';
        uwList.UW_Analysis_Code__c = 'T1';
        uwList.Rating_Factor__c = 1000;
        uwList.Sort_Order__c = 10;
        uwList.Submission__c = oppaq.Id;
        uwList.UW_Analysis_Template__c = TempList.Id;
        uwList.Sort_Order__c = 10;
        uwList.Notional_Income__c = 1000;
        insert uwList;
        
    }
    @isTest
    static void   cloneOpportunityTest(){
        Opportunity opp = [Select id,StageName,Received_Date__c,CloseDate from Opportunity limit 1];
        Test.startTest();
        CloneOpportunityController.cloneOpportunity(opp.id);
        
        CloneOpportunityController.cloneOpportunity(null);
        
        date dt = date.today();
        opp.Received_Date__c=dt.addDays(-450);
        opp.CloseDate=dt.addDays(-400);
        update opp;
        CloneOpportunityController.cloneOpportunity(opp.Id);
        Test.stopTest();
        system.assert( opp.StageName == 'Qualified');
    }
}