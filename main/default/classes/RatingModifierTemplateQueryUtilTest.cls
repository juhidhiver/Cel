/**************************************************************************************************
* Class Name: RatingModifierTemplateQueryUtilTest
* Author: 
* Date: Dec 30th, 2021
* Description: 
**************************************************************************************************/

@isTest
public class RatingModifierTemplateQueryUtilTest {
    
    public static testmethod void coverRatingModifierTemplate(){
        Test.startTest();
        
        Rating_Modifier_Template__c rMT = TestUtil.createRatingModifierTemplate('Test Service Classification','D&O','Number');
        rMT.Display_Format__c = 'Clearance';
        rMT.Page_Section__c = 'Risk Capture';
        insert rMT;
        
        RatingModifierTemplateQueryUtil.fetchRatingModifierTemplatesByProductsForRiskCapture( New List<String>{'D&O'});
        
        Test.stopTest();
    }
}