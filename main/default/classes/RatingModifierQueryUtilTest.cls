/**************************************************************************************************
 * Class Name: RatingModifierQueryUtilTest
 * Author: RINKU SAINI
 * Date: Dec 28th, 2021
 * Description: Class to keep rating modifiers queries
 **************************************************************************************************/

@isTest
public class RatingModifierQueryUtilTest {
    
    public static testmethod void coverRatingModifierQueryUtil(){
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
        
        
        Rating_Modifiers__c ratingModifier = new Rating_Modifiers__c(Name = 'New Rating Modifier1',Product__c='MPL',
                                                                     Rating_Modifier_Code__c='abcd', Opportunity__c = opp.Id );
        insert ratingModifier;
        
        RatingModifierQueryUtil.fetchRatingModifiersByOpportunity(opp.Id);   
        RatingModifierQueryUtil.fetchRatingModifiersByOpportunityAndProduct( New Set<Id>{opp.Id}, New List<String>{'MPL Standalone'});
        RatingModifierQueryUtil.fetchRatingModifiersByOpportunityForRiskCapture( New Set<String>{opp.Id});
        RatingModifierQueryUtil.fetchRatingModifiersByNameAndOppId( New Set<Id>{opp.Id} );
        RatingModifierQueryUtil.fetchRatingModifiersByCodeAndOppId( New Set<String>{opp.Id} );
        RatingModifierQueryUtil.fetchRatingModifiersByDisplayFormate( New List<Id>{opp.Id}, New List<String>{''});
        Test.stopTest();
    }
}