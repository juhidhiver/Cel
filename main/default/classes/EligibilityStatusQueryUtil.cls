/**************************************************************************************************
 * Class Name: EligibilityStatusQueryUtil
 * Author: 
 * Date: 27th Dec 2021
 * Description: Query util class for Account Loss Object.
 **************************************************************************************************/
public with sharing class EligibilityStatusQueryUtil{
    /*************************************************
   * Method Name: fetchELStatusForServiceClassification
   * Author:  
   * Date: 27 Dec 2021
   * Params: 
   * Return: list of Eligibility Status
   * Exceptions:
   * Revision: 
   * Description: Get Eligibility Status for 'Service Classification' Ratings Modifiers.
    *************************************************/
   public static List<Eligibility_Status__c> fetchELStatusForServiceClassification(){
       return [SELECT Id,Eligibility_Status__c,Rating_Modifier_Value__c,Modifier_Product__c 
               FROM Eligibility_Status__c WHERE Rating_Modifier_Name__c = 'Service Classification'];
   }
}