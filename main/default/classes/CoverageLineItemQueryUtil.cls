/**************************************************************************************************
 * Class Name: CoveragesLineItemQueryUtil
 * Author: Jai
 * Date: Dec 07, 2021
 * Description: Class to keep CoveragesLineItem queries
 * Test Class : CoverageLineItemQueryUtilTest
 **************************************************************************************************/

public with sharing class CoverageLineItemQueryUtil {
    
    /*************************************************
    * Method Name: fetchNewCLIs
    * Author: 
    * Date: 
    * Params: set<Id>
    * Return: 
    * Exceptions:
    * Description: 
    * Revision: 
     *************************************************/
    public static list<CoveragesLineItem__c> fetchNewCLIs ( set<Id> newCLIIds ){
        return  [SELECT Id, Name, Quote__c, Option_Value_Default__c,
                                                        Limits_Deductibles__r.Name 
                                                        FROM CoveragesLineItem__c     
                                                        WHERE Id IN : newCLIIds ]; 

    }

    /*************************************************
    * Method Name: fetchChangedCLIs
    * Author: 
    * Date: 
    * Params: set<Id>
    * Return: 
    * Exceptions:
    * Description: 
    * Revision: 
     *************************************************/
    public static list<CoveragesLineItem__c> fetchChangedCLIs ( Set<String> quoteSet, Set<String> SyncFromCLI ){
        return  [SELECT Id, Limits_Deductibles__r.Name, Quote__c,Quote__r.Status,
                    Limits_Deductibles__r.Sync_From__c, Option_Value_Default__c,
                    Limits_Deductibles__r.Sync_From__r.Name
                    FROM CoveragesLineItem__c 
                    WHERE Limits_Deductibles__r.Sync_From__r.Name IN : SyncFromCLI
                    AND Quote__c IN : quoteSet ]; 

    }

    /*************************************************
    * Method Name: fetchExcessCLIs
    * Author: 
    * Date: 
    * Params: Map<Id,CoveragesLineItem__c >, List<String>
    * Return: 
    * Exceptions:
    * Description: query excess CLIs
    * Revision: 
     *************************************************/
    public static list<CoveragesLineItem__c> fetchExcessCLIs (Map<Id,CoveragesLineItem__c > newDataMap, List<String> ExcessLimitDeductibles ){   
        return  [   SELECT Id, Name, Quote__c, Option_Value_Default__c,Quote__r.Status,
                    Limits_Deductibles__r.LmtDedCode__c
                    FROM CoveragesLineItem__c WHERE  Id IN :newDataMap.keySet() AND 
                    Limits_Deductibles__r.LmtDedCode__c IN :ExcessLimitDeductibles ];
    } 

    /*************************************************
    * Method Name: fetchCLIsForTechnicalPremium
    * Author: 
    * Date: 
    * Params: List<CoveragesLineItem__c>
    * Return: 
    * Exceptions:
    * Description: query CLIs
    * Revision: 
     *************************************************/
    public static list<CoveragesLineItem__c> fetchCLIsForTechnicalPremium (List<CoveragesLineItem__c> newDataList ){   
        return  [   SELECT Id, Name, Quote__r.Layer__c, Quote__c, Coverage_Premium__c,Coverage_Product__c,Quote__r.Status,Technical_Premium__c
                    FROM CoveragesLineItem__c WHERE  Id IN: newDataList AND 
                    CoverageLineItemType__c  =:'Main Coverage' AND 
                    (Coverage__r.Name =:'Cyber Coverage' OR Coverage__r.Name =:'Miscellaneous Professional Liability') ];
    } 

    /*************************************************
    * Method Name: fetchCLIsByProductNamesAndQuotes
    * Author: 
    * Date: 
    * Params: List<CoveragesLineItem__c>
    * Return: 
    * Exceptions:
    * Description: query CLIs filtered by product names and quote names
    * Revision: 
     *************************************************/
    public static list<CoveragesLineItem__c> fetchCLIsByProductNamesAndQuotes (String prodNamesQuerySelector, Set<id> quoteIds ){   
        return [select id from CoveragesLineItem__c where Coverage_Product_Combo__c INCLUDES (:prodNamesQuerySelector) and Quote__c in: quoteIds];
    } 
    
     /*************************************************
    * Method Name: fetchCLIsByCoverageTypeAndQuotes
    * Author: RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: Set of Quote Ids
    * Return: 
    * Exceptions:
    * Description: query CLIs filtered by CoverageTypes and quote names
    * Revision: 
     *************************************************/
    public static list<CoveragesLineItem__c> fetchCLIsByCoverageTypeAndQuotes (Set<id> quoteIds ){   
        return [SELECT Quote__c,Quote__r.Product_Name__c FROM CoveragesLineItem__c 
                WHERE Quote__c IN : quoteIds
                AND Coverage__r.Coverage_Type__c = 'Endorsement'
                //added by Yogesh Mandlik for 58840
                AND (((Quote__r.Product_Name__c!='Cyber Standalone' OR Quote__r.Product_Name__c!='Private Company Combo' OR Quote__r.Product_Name__c!='MPL Standalone') AND Parent_Coverages_Line_Item__c = null) OR
                    ((Quote__r.Product_Name__c!='Cyber Standalone' OR Quote__r.Product_Name__c!='Private Company Combo' OR Quote__r.Product_Name__c!='MPL Standalone') AND Parent_Coverages_Line_Item__c != null))];
            } 
     
      /*************************************************
    * Method Name: fetchCLIsByQuoteId
    * Author: JUHI
    * Date: 
    * Params: Quote Ids
    * Return: 
    * Exceptions:
    * Description: query CLIs filtered by CoverageTypes and quote names
    * Revision: 
     *************************************************/
    public static list<CoveragesLineItem__c> fetchCLIsByQuoteId(Id parentQuoteId){   
        return[SELECT ID, Name, Azure_ID__c, 
                                              Sub_Coverage__r.Id, Sub_Coverage__r.Name,
                                              Sub_Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Code__c,
                                              Coverage__r.Id, Coverage__r.Azure_ID__c, Coverage__r.Name, Coverage_Premium__c,
                                              Factor_Value__c, Coverage__r.Coverage_Product__c,Coverage__r.Coverage_Product_Combo__c,
                                              Coverage__r.Additional_Requirements__c,Coverage__r.Form_Number__c,
                                              Non_Prorated_Coverage_Premium__c, // Added Non_Prorated_Coverage_Premium__c for US:52937
                                              Factor_Min__c, Factor_Max__c, Increment_Step__c, 
                                              Factor_Default_Value__c,Limits_Deductibles__c, Limits_Deductibles__r.Azure_ID__c,
                                              Limits_Deductibles__r.Name, Limits_Deductibles__r.Type__c,
                                              Limits_Deductibles__r.RecordTypeId,Limits_Deductibles__r.LmtDedCode__c,
                                              Limits_Deductibles__r.RecordType.DeveloperName,
                                              Limits_Deductibles__r.RecordType.Name, Max_amt__c, Min_amt__c,
                                              Option_Type__c, Option_Value_Default__c, IsSelected__c,
                                              Option_Picklist__c,Override_Premium__c, Rating__c,
                                              Added_in_current_transaction__c,Coverage_Effective_Date__c
                                              FROM CoveragesLineItem__c WHERE Quote__c =: parentQuoteId];
    }
}