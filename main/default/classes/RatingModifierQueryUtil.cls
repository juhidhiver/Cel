/**************************************************************************************************
 * Class Name: RatingModifierQueryUtil
 * Author: Vinay
 * Date: Dec 22nd, 2021
 * Description: Class to keep rating modifiers queries
 * Test Class : RatingModifierQueryUtil
 **************************************************************************************************/
public with sharing class RatingModifierQueryUtil {
    /*************************************************
    * Method Name: fetchRatingModifiersByOpportunity
    * Author: Vinay Vernekar
    * Date: 22nd Dec 2021
    * Params: Opportunity Id
    * Return: list of rating modifiers
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifiers by opportunity id
     *************************************************/
    public static List<Rating_Modifiers__c> fetchRatingModifiersByOpportunity(Id opportunityId){
        return [Select Id, IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
                SystemModstamp, LastViewedDate, LastReferencedDate, Product__c, Format__c, Picklist_Values__c, Is_Required__c, 
                SME_Question__c, Factor_Default_Value__c, Factor_Max__c, Factor_Min__c, Factor_Value__c, Azure_ID__c, 
                Order_of_Page_Section__c, Page_Section__c, Sort_Order__c, Opportunity__c, External_ID__c, Sub_Section__c, 
                Controlling_Picklist_API_Name__c, Submission_Field_API_Name__c, Rating_Modifier_Value__c,
                 Eligibility_Weighting_Factor__c, Eligibility_Status__c, Sort_Sub_Section__c, Rating_Modifier_Code__c, 
                 Display_Format__c, Object_API_Name_of_Picklist__c, Profile_Name_for_Read_Only__c, Controlling_Picklist_Label__c,
                  Dependent_Picklist_API_Name__c, Dependent_Picklist_Label__c, Controlling_Picklist_Value__c, Dependent_Picklist_Value__c, 
                Rating_Modifier_Template_Code__c, Rating__c, Rating_Reference_Name__c, Coverage_Code__c From Rating_Modifiers__c Where Opportunity__c =: opportunityId];
    }

     /*************************************************
    * Method Name: fetchRatingModifiersByOpportunity
    * Author: 
    * Date: 2 Feb 2022
    * Params: Opportunity Ids
    * Return: list of rating modifiers
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifiers by opportunity ids
     *************************************************/
    public static List<Rating_Modifiers__c> fetchRatingModifiersByOpportunities(Set<String> oppIds){
        return [Select Id, IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
                SystemModstamp, LastViewedDate, LastReferencedDate, Product__c, Format__c, Picklist_Values__c, Is_Required__c, 
                SME_Question__c, Factor_Default_Value__c, Factor_Max__c, Factor_Min__c, Factor_Value__c, Azure_ID__c, 
                Order_of_Page_Section__c, Page_Section__c, Sort_Order__c, Opportunity__c, External_ID__c, Sub_Section__c, 
                Controlling_Picklist_API_Name__c, Submission_Field_API_Name__c, Rating_Modifier_Value__c,
                 Eligibility_Weighting_Factor__c, Eligibility_Status__c, Sort_Sub_Section__c, Rating_Modifier_Code__c, 
                 Display_Format__c, Object_API_Name_of_Picklist__c, Profile_Name_for_Read_Only__c, Controlling_Picklist_Label__c,
                  Dependent_Picklist_API_Name__c, Dependent_Picklist_Label__c, Controlling_Picklist_Value__c, Dependent_Picklist_Value__c, 
                Rating_Modifier_Template_Code__c, Rating__c, Rating_Reference_Name__c, Coverage_Code__c From Rating_Modifiers__c Where Opportunity__c in : oppIds];
    }

    /*************************************************
    * Method Name: fetchRatingModifiersByOpportunityAndProduct
    * Author: Vinay Vernekar
    * Date: 22nd Dec 2021
    * Params: Opportunity Ids amd Product Names
    * Return: list of rating modifiers
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifiers by opportunity ids and product names
     *************************************************/
    public static List<Rating_Modifiers__c> fetchRatingModifiersByOpportunityAndProduct(Set<Id> opportunityIds, List<String> productNames){
        return [Select Id, Opportunity__c, Product__c from Rating_Modifiers__c where Opportunity__c in: opportunityIds and Product__c in: productNames];
    }

     /*************************************************
    * Method Name: fetchRatingModifiersByOpportunity
    * Author: 
    * Date: 27th Dec 2021
    * Params: Opportunity Ids amd Product Names
    * Return: list of rating modifiers
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifiers by opportunity ids and product names
     *************************************************/
    public static List<Rating_Modifiers__c> fetchRatingModifiersByOpportunityForRiskCapture(Set<String> oppIds){
        return [SELECT Id, Rating_Modifier_Code__c, Opportunity__c, Page_Section__c               
                FROM Rating_Modifiers__c
                WHERE Opportunity__c IN :oppIds
                AND Page_Section__c =: 'Risk Capture'];
    }


     /*************************************************
    * Method Name: fetchRatingModifiersByOpportunityForServiceClassification
    * Author: 
    * Date: 27th Dec 2021
    * Params: Opportunity Ids amd Product Names
    * Return: list of rating modifiers
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifiers by opportunity ids and product names
     *************************************************/
    public static List<Rating_Modifiers__c> fetchRatingModifiersByOpportunityForServiceClassification(Set<Id> oppIds){
        return [select Id,Rating_Modifier_Value__c,Opportunity__c,
                Eligibility_Status__c From Rating_Modifiers__c 
                where Opportunity__c in:oppIds And Name ='Service Classification'];
    }
    
     /*************************************************
    * Method Name: fetchRatingModifiersByNameAndOppId
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: Opportunity Ids 
    * Return: list of rating modifiers
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifiers by opportunity ids 
     *************************************************/
    public static List<Rating_Modifiers__c> fetchRatingModifiersByNameAndOppId( Set<Id> oppIds ){
        return [SELECT Rating_Modifier_Code__c, Opportunity__c,Rating_Modifier_Value__c, Name, Id 
                FROM Rating_Modifiers__c 
                WHERE Name='Proposal Form Date' AND Opportunity__c IN: oppIds ];
    }
    
     /*************************************************
    * Method Name: fetchRatingModifiersByCodeAndOppId
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: Opportunity Ids and Modifier Code
    * Return: list of rating modifiers
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifiers by opportunity ids and Name
     *************************************************/
    public static List<Rating_Modifiers__c> fetchRatingModifiersByCodeAndOppId( Set<String> setOppId ){
        return [Select Id,Rating_Modifier_Code__c,Rating_Modifier_Value__c,Opportunity__c from Rating_Modifiers__c 
                where Opportunity__c IN : setOppId AND Rating_Modifier_Code__c = 'PI0000015'];
    }
    
     /*************************************************
    * Method Name: fetchRatingModifiersByDisplayFormate
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: list oppIds and displayFormate List String 
    * Return: list of rating modifiers
    * Exceptions:
    * Revision: 
    * Description: Fetch rating modifiers by displayFormate
     *************************************************/
    public static List<Rating_Modifiers__c> fetchRatingModifiersByDisplayFormate( List<Id> oppIds, List<String> displayFormatList ){
        return [SELECT Id, Name, Rating_Modifier_Code__c, Product__c, Display_Format__c, Page_Section__c, Opportunity__r.Product_Name__c
                FROM Rating_Modifiers__c 
                WHERE Opportunity__c =: oppIds
                AND Display_Format__c =: displayFormatList AND Page_Section__c !=: 'SME Eligibility'];
            }
}