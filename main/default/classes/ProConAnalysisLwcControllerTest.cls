@isTest
public class ProConAnalysisLwcControllerTest {
	@testsetup static void testSetup(){
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
		insert acc;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 

        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
    	opp.Expiration_Date__c = Date.today()+60;
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
     	quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1;  

		Quote quote2 = Testutil.createQuote('New Quote 2', opp.Id);
        quote2.Status = 'Bound';
        quote2.Coverage_Product_Options__c = 'D&O';
        quote2.Refer_Type__c = 'Underwriting Referral';
        insert quote2; 
        
        Rating_Modifiers__c rateMod = new Rating_Modifiers__c();
        rateMod.Name = 'Test Rating Modifier';
        rateMod.Opportunity__c = opp.Id;
        rateMod.Page_Section__c = 'Pros and Cons';
        rateMod.Rating_Modifier_Value__c = 'Test Values 12';
        insert rateMod;
        
        Rating_Modifiers__c rateMod2 = new Rating_Modifiers__c();
        rateMod2.Name = 'Test Rating Modifier2';
        rateMod2.Opportunity__c = opp.Id;
        rateMod2.Page_Section__c = 'Pros and Cons';
        rateMod2.Rating_Modifier_Value__c = 'Test Values 123';
        insert rateMod2;
    }
    @isTest
    static void clearRatingModifierTest(){
        Test.startTest();
        List<String> rateIds = new List<String>();
        for(Rating_Modifiers__c rateMod :[Select Id from Rating_Modifiers__c]){
            rateIds.add(rateMod.Id);
        }      
        String clearRatingModifierList = ProConAnalysisLwcController.clearRatingModifier(rateIds);  
        System.assert(clearRatingModifierList!=null);
        Test.stopTest();
    }
    @isTest
    static void getCategoriesTest(){
        Test.startTest();
        Opportunity opp = [Select Id from Opportunity Limit 1];
        List<String> getCategoriesList =  ProConAnalysisLwcController.getCategories(opp.Id);
        System.assert(getCategoriesList!=null);
        Test.stopTest();
    }
    @isTest
    static void getProsConsListTest(){
        Test.startTest();
        Opportunity opp = [Select Id from Opportunity Limit 1];
       	List<Rating_Modifiers__c> getProsConsList = ProConAnalysisLwcController.getProsConsList(opp.Id);
        System.assert(getProsConsList!=null);
        Test.stopTest();
    }
    @isTest
    static void searchRatingModifierTest(){
        Test.startTest();
        List<String> listAddedRatingModifier = new List<String>();
        Opportunity opp = [Select Id from Opportunity Limit 1];
        List<String> searchCategories = new List<String>{'Test 1', 'Test 2'};
        List<Rating_Modifiers__c> searchRatingModifierlist = ProConAnalysisLwcController.searchRatingModifier(opp.Id, searchCategories, listAddedRatingModifier);
        System.assert(searchRatingModifierlist!=null);
        Test.stopTest();
    }
       @isTest
    static void saveRatingModifierTest(){
        Test.startTest();
        List<String> prosId = new List<String>();
        List<String> consId = new List<String>();        
        for(Rating_Modifiers__c rateMod :[Select Id from Rating_Modifiers__c where Name = 'Test Rating Modifier']){
            prosId.add(rateMod.Id);
        } 
         for(Rating_Modifiers__c rateMod :[Select Id from Rating_Modifiers__c where Name = 'Test Rating Modifier2']){
            consId.add(rateMod.Id);
        } 
        String saveRatingModifierValue = ProConAnalysisLwcController.saveRatingModifier(prosId, consId);
        System.debug(saveRatingModifierValue!=null);
        Test.stopTest();
    }
 
}