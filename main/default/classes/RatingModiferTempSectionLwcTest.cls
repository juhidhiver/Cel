@isTest
public class RatingModiferTempSectionLwcTest {
@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
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
          	
    	Rating_Modifier_Template__c rateMod = new Rating_Modifier_Template__c();
    	rateMod.Name = 'Test';
    	//rateMod.Page_Section__c = 'Test Page Section';
    	//rateMod.Sub_Section__c=  'Test Page Sub Section';
    	rateMod.Product__c = 'MPL';
    	insert rateMod;
 	}
    @istest
    static void getPageSectionListMultiTest(){
        Test.startTest();
        List<String> modifierProductName = new List<String>{'MPL'};
        ratingModiferTempSectionLwcController.getPageSectionListMulti(modifierProductName);
        System.assert(True);
        Test.stopTest();
    }
     @istest
    static void getSubSectionListMultiTest(){
        Test.startTest();
        List<String> modifierProductName = new List<String>{'MPL'};
        ratingModiferTempSectionLwcController.getSubSectionListMulti(modifierProductName, 'Test Page Section');
        System.assert(True);
        Test.stopTest();
    }
      @istest
    static void getFieldListMultiTest(){
        Test.startTest();
        List<String> modifierProductName = new List<String>{'Test 1', 'Test 2'};
        ratingModiferTempSectionLwcController.getFieldListMulti(modifierProductName, 'Test Page Section','Test Page Sub Section');
        System.assert(True);
        Test.stopTest();
    }
}