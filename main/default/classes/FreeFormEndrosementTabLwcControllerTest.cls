/*************************************************
* Class Name: FreeFormEndrosementTabLwcControllerTest
* Author: Namana K G and Prakhya B ravi
* Updated: 15/03/2021
* Description:FreeFormEndrosementTabLwcController Test
*              
*************************************************/
@isTest
public class FreeFormEndrosementTabLwcControllerTest {
    public static Product2 product;
    public static Account acc;
    
    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassQuoteTrigger__c = false;
        update setting;
        
        acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        product = TestUtil.createProduct('D&O');
        insert product;   
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opportunity.StageName = 'Qualified';
        opportunity.Coverage_Product_Options__c = 'D&O;MPL';
        insert opportunity;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
        quote.Coverage_Product_Options__c ='D&O;MPL';
        quote.Layer__c = 'Excess';
        insert quote;
        
        quote.Status = 'Rated';
        update quote;

        Free_Form_Endorsements__c freeForm=new Free_Form_Endorsements__c();
        freeForm.Quote__c=quote.id;
        freeForm.Coverage_Effective_Date__c=Date.today().addDays(30);
        freeForm.Form_Number__c='12345';
        freeForm.Endorsement_Name__c='New Endorsement';
        freeForm.Endorsement_Wording__c= 'NewEndorsement' ;
        insert freeForm;
        
        
    }
    @isTest static void getFFEndorsementByQuoteIdTest(){
        
        Quote quote=[select id,Effective_Date__c,Status from Quote limit 1];
        quote.Effective_Date__c=Date.today();
        update quote;
        
        Test.startTest();
        FreeFormEndorsementTabLwcController.getCoverageEffDate(quote.Id);
        FreeFormEndorsementTabLwcController.getFFEndorsementByQuoteId(quote.Id);
        FreeFormEndorsementTabLwcController.generateFormNumber(quote.Id);
        FreeFormEndorsementTabLwcController.getNextChar('Character');
        Test.stopTest();  
        System.assert(quote.Status == 'Rated');
    }
    @isTest static void generateFormNumberTest(){
        
        Quote quote=[select id,Effective_Date__c,Layer__c from Quote limit 1];
        quote.Effective_Date__c=Date.today();
        update quote;
        Free_Form_Endorsements__c freeForm =[select id from Free_Form_Endorsements__c  limit 1];
        delete freeForm;
        Test.startTest();
        FreeFormEndorsementTabLwcController.generateFormNumber(quote.Id);
        Test.stopTest();
          System.assert(quote.Layer__c == 'Excess');
        
    }
}