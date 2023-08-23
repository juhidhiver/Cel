/**************************************************************************************************
 * Class Name: CoverageQueryUtil
 * Author: Vinay
 * Date: Dec 23, 2021
 * Description: Class to keep coverage queries
 * Test Class : CoverageQueryUtil
 **************************************************************************************************/
public with sharing class CoverageQueryUtil {
    /*************************************************
    * Method Name: fetchCoveragesByProducts
    * Author: Vinay
    * Date: 23 Dec 2021
    * Params: List<String>
    * Return: list<Coverage__c>
    * Exceptions:
    * Revision: 
    * Description: Fetch coverages by product names
     *************************************************/
    public static List<Coverage__c> fetchCoveragesByProducts(List<String> productnames){
       return [SELECT Id, Name, Coverage_Product__c, Form_Number__c FROM Coverage__c WHERE Coverage_Type__c = 'Endorsement' AND Coverage_Product__c IN:productnames AND Form_Number__c != NULL];
    }
    
     /*************************************************
    * Method Name: fetchCoveragesByProductName
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: List<String>
    * Return: list<Coverage__c>
    * Exceptions:
    * Revision: 
    * Description: Fetch coverages by product names
     *************************************************/
    public static List<Coverage__c> fetchCoveragesByProductName(List<String> products){
        return  [Select Id,Name,Coverage_Product__c,Coverage_Product_Combo__c,RecordType.Name,Coverage_or_Sub__c, State__c, Coverage_to_replace__c,
                 Default_Notes__c, Coverage_Code__c, Coverage_Type__c,Page_Section__c,Form_Number__c,Apply_to_Quote__c, Optional_Coverage_Name__c, Optional_Factor_Label__c,
                 (Select Id,RecordTypeId,RecordType.Name,Page_Section__c,Endorsement_Data_Type__c,Option_Picklist__c,Default_Value__c From FeaturesProductOptions__r)
                 From Coverage__c 
                 Where ((Coverage_Type__c = 'Endorsement' AND (Additional_Requirements__c INCLUDES ('Load by Default') or Additional_Requirements__c INCLUDES ('Load without limit')) )
                        OR Coverage_Type__c != 'Endorsement') 
                 AND Coverage_Product__c In : products];
    }

     /*************************************************
    * Method Name: fetchCoveragesByProduct
    * Author: 
    * Date: 31st Jan 2022
    * Params: List<String>
    * Return: list<Coverage__c>
    * Exceptions:
    * Revision: 
    * Description: Fetch coverages by product names
     *************************************************/
    public static List<Coverage__c> fetchAllCoveragesByProductName(List<String> products){
        return  [Select Id,Name,Coverage_Product__c,Coverage_Product_Combo__c,RecordType.Name,Coverage_or_Sub__c, State__c, Coverage_to_replace__c,
                 Default_Notes__c, Coverage_Type__c,Page_Section__c,Form_Number__c,Apply_to_Quote__c, Optional_Coverage_Name__c,Optional_Factor_Label__c,
                 (Select Id,RecordTypeId,RecordType.Name,Page_Section__c,Endorsement_Data_Type__c,Option_Picklist__c,Default_Value__c From FeaturesProductOptions__r)
                 From Coverage__c 
                 Where Coverage_Product__c In : products];
    }
}