/**************************************************************************************************
* Class Name: EligibilityStatusQueryUtilTest
* Author: RINKU SAINI 
* Date: 30th Dec 2021
* Description: 
**************************************************************************************************/
@isTest
public class EligibilityStatusQueryUtilTest {
    
    public static testmethod void coverfetchELStatusForServiceClassification(){
        Test.startTest();
        
        Rating_Modifier_Template__c ratingModifiersTemp = TestUtil.createRatingModifierTemplate('Service Classification', 'MPL' , 'Integer');
        insert ratingModifiersTemp;
        
        //Create Eligibility Status
        Eligibility_Status__c es = new Eligibility_Status__c();
        es.Rating_Modifier_Template__c = ratingModifiersTemp.Id;
        es.Rating_Modifier_Value__c = 'Yes';
        es.Eligibility_Status__c = 'Proceed';
        es.Modifier_Product__c = 'MPL';
        insert es;
        
        EligibilityStatusQueryUtil.fetchELStatusForServiceClassification();
        
        Test.stopTest();
    }
}