/**************************************************************************************************
* Class Name: RatingModifierFactorQueryUtilTest
* Author: RINKU SAINI
* Date: Dec 28th, 2021
* Description: 
**************************************************************************************************/
@isTest
public class RatingModifierFactorQueryUtilTest {
    
    public static testmethod void coverRatingModifierFactor(){
        Test.startTest();
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('MPL Standalone');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        opp.Azure_ID__c = '123';
        insert opp;
        
        // Create quote
        Quote quote = TestUtil.createQuote('Test quote 1',opp.Id);
        quote.Coverage_Product_Options__c = 'D&O';
        quote.Pricebook2Id = Test.getStandardPricebookId();
        insert quote;
        
        Rating_Modifiers__c ratingModifier = new Rating_Modifiers__c(Name = 'New Rating Modifier1',Product__c='MPL',
                                                                     Rating_Modifier_Code__c='abcd', Opportunity__c = opp.Id );
        insert ratingModifier;
        
        
        //Rating Modifier Factor
        Rating_Modifier_Factor__c rm = new Rating_Modifier_Factor__c();
        rm.Factor_Default_Value__c = 123;
        rm.Factor_Max__c = 300;
        rm.Factor_Min__c = 100;
        rm.Factor_Value__c = 120;
        rm.Rating_Modifier__c = ratingModifier.Id;
        rm.Quote__c = quote.Id;    
        insert rm; 
        
        RatingModifierFactorQueryUtil.fetchNewCLIs( New List<String>{'MPL Standalone'}, New Set<Id>{quote.Id});
        
        Test.stopTest();
    }
    
}