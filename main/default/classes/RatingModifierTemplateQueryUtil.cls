/**************************************************************************************************
 * Class Name: RatingModifierTemplateQueryUtil
 * Author: 
 * Date: Dec 27th, 2021
 * Description: Class to keep rating modifier template queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class RatingModifierTemplateQueryUtil {
    /*************************************************
    * Method Name: fetchRatingModifierTemplatesByProductsForRiskCapture
    * Author: 
    * Date: 27th Dec 2021
    * Params: products
    * Return: list of rating modifier templates
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifier templates by products for Risk Capture Section
     *************************************************/
    public static List<Rating_Modifier_Template__c> fetchRatingModifierTemplatesByProductsForRiskCapture(List<String> products){
        return [SELECT Factor_Default_Value__c,Factor_Max__c,Factor_Min__c,Modifier_Format__c,Product__c,Name,Page_Section__c,
                Picklist_Default_Value__c,Picklist_Range__c,Picklist_Values__c,Sort_Order__c,Sort_Sub_Section__c,Comment__c,
                Sub_Section__c,Eligibility_Weighting_Factor__c,Rating_Modifier_Code__c,Display_Format__c,
                Profile_Name_for_Read_Only__c, Is_Required__c,Create_Criteria__c, Order_of_Page_Section__c 
                FROM Rating_Modifier_Template__c 
                WHERE Product__c IN: products
                AND Page_Section__c =: 'Risk Capture'];
    }
}