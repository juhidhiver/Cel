/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 12-06-2021
 * @last modified by  : Vinayesh
**/
public with sharing class DefaultCoveragesUtil_AQ {
    private static final String EQUALS_OPERATOR = 'equals';
    private static final String NOT_EQUALS_OPERATOR = 'not equals';
    private static final String IN_OPERATOR = 'in';

    /**
    * @description : Populate default coverages applicable to quote.
    * @author Vinayesh | 11-30-2021 
    * @param quoteId 
    * @return List<Coverage> 
    **/
    public static Set<String> GetDefaultCoveragesForQuote(String quoteId) {
        //Need to look at error handling. Probably need a wrapper result class with error msg
       Map<String,List<sObject>> quoteRelatedDataMap = getDataMap(quoteId);
       String productName = (String)quoteRelatedDataMap.get(((Id)quoteId).getSObjectType().getDescribe().getName())[0].get('Product_Name__c');

       
       Map<String, List<Coverage_Matrix__c>> filterCriteriaParentMap = getFilterCriteriaParentMap(productName);
       Map<String, List<Coverage_Matrix_Rule__c>> filterCriteriaRuleMap = getFilterCriteriaRuleMap(productName);
       
       Set<String> filteredDefaultCovIds = filterCoverages(quoteRelatedDataMap, filterCriteriaParentMap, filterCriteriaRuleMap);

       
       System.debug(filteredDefaultCovIds);
       return filteredDefaultCovIds;
    }

    /**
     * Logic to filter default coverages for quote
     */
    private static Set<String> filterCoverages(Map<String,List<sObject>> quoteRelatedDataMap, Map<String, List<Coverage_Matrix__c>> filterCriteriaParentMap,
                                                            Map<String, List<Coverage_Matrix_Rule__c>> filterCriteriaRuleMap) {
       Set<String> covIds = new Set<String>();
       for(String covId : filterCriteriaParentMap.keySet()){
          covIds.add(covId);
       }

       Set<String> defaultCovIds = new Set<String>();
       for(String covId : covIds){  
           boolean coverageMatchFound = false;       
           for(Coverage_Matrix__c parentRule : filterCriteriaParentMap.get(covId)){
               for(Coverage_Matrix_Rule__c criteriaRule : filterCriteriaRuleMap.get(parentRule.Id)){
                   boolean ruleMatch = false;
                   List<sObject> dataObjList = quoteRelatedDataMap.get(criteriaRule.Object_API_Name__c);
                   //Object dataValue = dataObj.get(criteriaRule.Field_API_Name__c);
                    for(sObject dataObj : dataObjList){
                        if(criteriaRule.Rule_Type__c == 'Key Value Query'){
                            List<String> lstKey = criteriaRule.Field_API_Name__c.split(';',2);
                            List<String> lstValue = criteriaRule.Value__c.split(';',2);
                            Object dataKey = dataObj.get(lstKey[0]);
                            Object dataValue = dataObj.get(lstValue[0]);
                            if(criteriaRule.Field_Type__c == 'Text'){
                                if(criteriaRule.Operat__c == EQUALS_OPERATOR){
                                    if((String)dataKey == lstKey[1] && (String)dataValue == lstValue[1]){
                                        ruleMatch = true;
                                    }
                                }
                            }
                        }
                        else{
                            Object dataValue = dataObj.get(criteriaRule.Field_API_Name__c);
                            if(criteriaRule.Field_Type__c == 'Text'){
                                if(criteriaRule.Operat__c == EQUALS_OPERATOR){
                                    if((String)dataValue == criteriaRule.Value__c){
                                        ruleMatch = true;
                                    }
                                }
                                if(criteriaRule.Operat__c == NOT_EQUALS_OPERATOR){
                                    if((String)dataValue != criteriaRule.Value__c){
                                    ruleMatch = true;
                                    }
                                }
                                if(criteriaRule.Operat__c == IN_OPERATOR){
                                    if(criteriaRule.Value__c.containsIgnoreCase((String)dataValue)){
                                        ruleMatch = true;
                                    }
                                }
                            }
                            if(criteriaRule.Field_Type__c == 'Number'){
                                //Need to implement
                            }
                        }
                    }

                   if(ruleMatch) {
                       coverageMatchFound = true;
                   }
                   else{
                       coverageMatchFound = false;
                       break;
                   }
                   
               }
               
               if(coverageMatchFound) break;
           }

           if(coverageMatchFound) defaultCovIds.add(covId);
       }

       return defaultCovIds;
    }


    /**
     * Get all quote related data used in filtering coverages.
     */
    private static Map<String,List<sObject>> getDataMap(String quoteId) {
      Map<String,List<sObject>> dataMap = new Map<String,List<sObject>>();
      //Need to do normal soql here as static query for metadata has issue with long text area
      List<Filter_Default_Coverages_Query_Setting__mdt> queryList = Filter_Default_Coverages_Query_Setting__mdt.getall().values();
      List<Quote> currQuote;
      List<Opportunity> currOpp;
      for(Filter_Default_Coverages_Query_Setting__mdt queryItem : queryList){
          if(queryItem.Object_API_Name__c == 'Quote'){
              String quoteQuery = queryItem.Object_Query__c + ' Where Id' + ' =: quoteId';
              currQuote = Database.query(quoteQuery);
              dataMap.put(queryItem.Object_API_Name__c, currQuote);
              break;
          }
      }
      for(Filter_Default_Coverages_Query_Setting__mdt queryItem : queryList){
        if(queryItem.Object_API_Name__c == 'Opportunity'){
          String oppId = currQuote[0].OpportunityId;
          String oppQuery = queryItem.Object_Query__c + ' Where Id' + ' =: oppId';
          currOpp = Database.query(oppQuery);
          dataMap.put(queryItem.Object_API_Name__c, currOpp);
          break;
      }
    }
    for(Filter_Default_Coverages_Query_Setting__mdt queryItem : queryList){
        if(queryItem.Parent_Object_API_Name__c != null){
            String parentId = queryItem.Parent_Object_API_Name__c == 'Quote' ? currQuote[0].Id : currOpp[0].Id;
            String childQuery = queryItem.Object_Query__c + ' Where ' + queryItem.Lookup_To_Parent_Field_API_Name__c + ' =: parentId';
            dataMap.put(queryItem.Object_API_Name__c, Database.query(childQuery));
        }  
    }

      
    //   List<Quote> currQuote = [SELECT Id, Status, OpportunityId, Product_Name__c 
    //                            FROM Quote
    //                            WHERE Id =:quoteId];
    //   dataMap.put(currQuote[0].getSObjectType().getDescribe().getName(), currQuote);
    //   List<Opportunity> currOpp = [SELECT Id, Main_Profession__c 
    //                                FROM Opportunity
    //                                WHERE Id =:currQuote[0].OpportunityId];
    //   dataMap.put(currOpp[0].getSObjectType().getDescribe().getName(), currOpp);
    //   List<UW_Analysis__c> workTypesForOpp = [SELECT Id, Name, UW_Analysis_Name__c, Criteria__c, UW_Analysis_Code__c, Rating_Factor__c, 
    //                                           Sort_Order__c,Split_Percentage__c, Amount__c, Notional_Income__c, Submission__c,
    //                                           UW_Analysis_Template__c, Base_Rates__c
    //                                           FROM UW_Analysis__c
    //                                           WHERE Submission__c =:currOpp[0].Id];
    //   if(workTypesForOpp.size() > 0)
    //     dataMap.put(workTypesForOpp[0].getSObjectType().getDescribe().getName(), workTypesForOpp);
    //   List<Rating_Modifiers__c> ratModsForOpp = [SELECT  Name, CurrencyIsoCode, Product__c, Format__c, Picklist_Values__c, Is_Required__c,
    //                                              SME_Question__c, Factor_Max__c, Factor_Min__c, Factor_Value__c, Azure_ID__c, Order_of_Page_Section__c, 
    //                                              Page_Section__c, Sort_Order__c, Opportunity__c
    //                                              FROM Rating_Modifiers__c
    //                                              WHERE Opportunity__c =:currOpp[0].Id];
    //   if(ratModsForOpp.size() > 0)
    //     dataMap.put(ratModsForOpp[0].getSObjectType().getDescribe().getName(), ratModsForOpp);

      return dataMap;
    }

      /**
       * Get Coverages to parent rule records map.
       */
      private static Map<String, List<Coverage_Matrix__c>> getFilterCriteriaParentMap(String productName){

        List<Coverage_Matrix__c> covMatrixList = [SELECT  Name, Coverage__c, IsActive__c, Coverage_Product__c, Description__c
                                                  FROM Coverage_Matrix__c
                                                  WHERE IsActive__c = true AND Coverage_Product__c =: productName];
        Map<String, List<Coverage_Matrix__c>> covParentMap = new Map<String, List<Coverage_Matrix__c>>();
        for(Coverage_Matrix__c rootItem : covMatrixList){
            if(!covParentMap.containsKey(rootItem.Coverage__c)){
                covParentMap.put(rootItem.Coverage__c, new List<Coverage_Matrix__c>());
            }
            covParentMap.get(rootItem.Coverage__c).add(rootItem);
        }
        return covParentMap;
        
      }


    /**
     * Get Parent to Child Criteria Rule records map.
     */
    private static Map<String, List<Coverage_Matrix_Rule__c>> getFilterCriteriaRuleMap(String productName){

        List<Coverage_Matrix_Rule__c> covMatrixLineList = [SELECT Name, Rule_Type__c, Coverage_Matrix__c, IsActive__c, Field_API_Name__c,
                                                           Field_Type__c, Value__c, Operat__c, Object_API_Name__c
                                                           FROM Coverage_Matrix_Rule__c
                                                           WHERE Coverage_Matrix__r.IsActive__c = true AND IsActive__c = true
                                                           AND Coverage_Matrix__r.Coverage_Product__c =: productName];
        Map<String, List<Coverage_Matrix_Rule__c>> covRuleMap = new Map<String, List<Coverage_Matrix_Rule__c>>();
        for(Coverage_Matrix_Rule__c ruleItem : covMatrixLineList){
            if(!covRuleMap.containsKey(ruleItem.Coverage_Matrix__c)){
                covRuleMap.put(ruleItem.Coverage_Matrix__c, new List<Coverage_Matrix_Rule__c>());
            }
            covRuleMap.get(ruleItem.Coverage_Matrix__c).add(ruleItem);
        }
        
        return covRuleMap;
    }

    public static void addEndorsementCLI(Map<Id, Set<String>> mapOfQuoteIdVsSetOfCoverageIds){
        List<CoveragesLineItem__c> listOfExistingCLIs = new List<CoveragesLineItem__c>();
        Map<Id, Set<String>> mapOfExistingQuoteIdVsCoverageId = new Map<Id, Set<String>>();
        Map<Id, Set<String>> mapOfNewQuoteIdVsCovIds = new Map<Id, Set<String>>();
        List<CoveragesLineItem__c> insertItems = new List<CoveragesLineItem__c>();

        listOfExistingCLIs = getEndorsementCoverageLineItem(mapOfQuoteIdVsSetOfCoverageIds.keySet());

        for(CoveragesLineItem__c objCLI: listOfExistingCLIs){
            if(objCLI.Coverage__c != null){
                if(mapOfExistingQuoteIdVsCoverageId.containsKey(objCLI.Quote__c)){
                    Set<String> setOfCoverageIds = new Set<String>();
                    setOfCoverageIds = mapOfExistingQuoteIdVsCoverageId.get(objCLI.Quote__c);
                    setOfCoverageIds.add(objCLI.Coverage__c);
                    mapOfExistingQuoteIdVsCoverageId.put(objCLI.Quote__c, setOfCoverageIds);
                }
                else{
                    mapOfExistingQuoteIdVsCoverageId.put(objCLI.Quote__c, new Set<String> {String.valueOf(objCLI.Coverage__c)});
                }
            }
        }

        mapOfNewQuoteIdVsCovIds = getCoverageForInsert(mapOfQuoteIdVsSetOfCoverageIds, mapOfExistingQuoteIdVsCoverageId);

        insertItems = getCLIForInsert(mapOfNewQuoteIdVsCovIds);
        insert insertItems;
    }

    private static List<CoveragesLineItem__c> getEndorsementCoverageLineItem(Set<Id> quoteIds) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        result = [SELECT Id, Name, Coverage__c, Coverage__r.Endorsement_Tags__c, Type__c, Rating__c, Quote__c
                  FROM CoveragesLineItem__c 
                  WHERE Quote__c IN :quoteIds 
                  AND Type__c LIKE 'Endorsement%' AND Coverage__r.Name !='MPL Manuscript Template'];
        return result;
    }

    private static Map<Id, Set<String>> getCoverageForInsert(Map<Id, Set<String>> mapOfQuoteIdVsCoverageIdsSet, Map<Id, Set<String>> mapOfExistingQuoteIdVsCoverageIdsSet) {
        Map<Id, Set<String>> mapOfQuoteIdVsCoverageIdsSetToInsert = new Map<Id, Set<String>>();

        for(Id objQuoteId: mapOfQuoteIdVsCoverageIdsSet.keySet()){
            if(!mapOfExistingQuoteIdVsCoverageIdsSet.isEmpty() && mapOfExistingQuoteIdVsCoverageIdsSet.containsKey(objQuoteId)){
                Set<String> setOfNewCoverageIds = new Set<String>();
                setOfNewCoverageIds = mapOfQuoteIdVsCoverageIdsSet.get(objQuoteId);
                setOfNewCoverageIds.removeAll(mapOfExistingQuoteIdVsCoverageIdsSet.get(objQuoteId));
                mapOfQuoteIdVsCoverageIdsSetToInsert.put(objQuoteId, setOfNewCoverageIds);
            }
            else{
                mapOfQuoteIdVsCoverageIdsSetToInsert.put(objQuoteId, mapOfQuoteIdVsCoverageIdsSet.get(objQuoteId));
            }
        }

        return mapOfQuoteIdVsCoverageIdsSetToInsert;
    }

    private static List<CoveragesLineItem__c> getCLIForInsert(Map<Id, Set<String>> mapOfNewQuoteIdVsCovIds) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        Set<String> setOfNewCoverages = new Set<String>();

        for(Id objQuoteId: mapOfNewQuoteIdVsCovIds.keySet()){
            setOfNewCoverages.addAll(mapOfNewQuoteIdVsCovIds.get(objQuoteId));
        }

        Map<Id, Quote> mapOfQuoteIdVsObject = new Map<Id, Quote>([SELECT Id, Quote_Type__c, Product_Name__c, Effective_Date__c, Endorsement_Effective_Date__c, Layer__c FROM Quote WHERE Id IN: mapOfNewQuoteIdVsCovIds.keySet()]);
        Map<Id, Coverage__c> mapOfCoverageIdVsObject = new Map<Id, Coverage__c>([SELECT Id, Coverage_Product__c, Page_Section__c, Form_Number__c, Endorsement_Tags__c, Rating__c, Apply_to_Quote__c, Coverage_Code__c,
                                                                                (SELECT Id, Name, Type__c, Endorsement_Data_Type__c, Page_Section__c 
                                                                                FROM FeaturesProductOptions__r) 
                                                                                FROM Coverage__c 
                                                                                WHERE Id IN :setOfNewCoverages]);

        for(Id objQuoteId: mapOfNewQuoteIdVsCovIds.keySet()){
            if(mapOfQuoteIdVsObject.containsKey(objQuoteId)){
                for(String strCoverageId: mapOfNewQuoteIdVsCovIds.get(objQuoteId)){
                    if(mapOfCoverageIdVsObject.containsKey(strCoverageId) && (mapOfCoverageIdVsObject.get(strCoverageId).Apply_to_Quote__c == null ||
                        (mapOfCoverageIdVsObject.get(strCoverageId).Apply_to_Quote__c != null && mapOfCoverageIdVsObject.get(strCoverageId).Apply_to_Quote__c.contains(mapOfQuoteIdVsObject.get(objQuoteId).Layer__c)))){
                        List<CoveragesLineItem__c> clis = GenerateCLIByCoverage(mapOfCoverageIdVsObject.get(strCoverageId), mapOfQuoteIdVsObject.get(objQuoteId));
                        result.addAll(clis);
                    }
                }
            }
        }
        return result;
    }

    private static List<CoveragesLineItem__c> GenerateCLIByCoverage(Coverage__c obj, Quote quo) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> limitItems = new List<CoveragesLineItem__c>();
        CoveragesLineItem__c cov = new CoveragesLineItem__c();
        
        Date effectiveDate; // add effective date to coverage line item
        if(quo != null){

            Id cliRecordTypeId = null;
            //Assign Record type based on product of code of quote (added by Jai)
            if( quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_CYBER ) ||
                quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_MPL ) ||
                quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PCC )
            ){  //Commented CLI_RecordType temporarily as it does not exist yet
                cliRecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
            }else if(quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PI ) ){
                //Commented CLI_RecordType temporarily as it does not exist yet
                cliRecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
            }

            if(quo.Quote_Type__c == 'New Business' || quo.Quote_Type__c == 'Renewal')
                effectiveDate = quo.Effective_Date__c;
            else if(quo.Quote_Type__c == 'Amendment')
                effectiveDate = quo.Endorsement_Effective_Date__c;

                Boolean addedInTxn = false; 

                if( quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_CYBER ) ||
                    quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_MPL ) ||
                    quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PCC )
                ){
                    List<Product_Setting__mdt> endorsementOpts = [SELECT Endorsement_Operation__c
                                                                FROM Product_Setting__mdt 
                                                                WHERE MasterLabel =: quo.Product_Name__c];

                                                            
                    if(endorsementOpts.size() > 0){
                        if(endorsementOpts[0].Endorsement_Operation__c != null && quo.Quote_Type__c != null){
                            if(endorsementOpts[0].Endorsement_Operation__c.contains(quo.Quote_Type__c)){
                                addedInTxn = true;
                            }
                        }
                    }
                }
                                                            
            try {  
                if( cliRecordTypeId != null ){
                    //Commented CLI_RecordType temporarily as it does not exist yet
                    cov.RecordTypeId = cliRecordTypeId;
                }
                cov.Added_by_Default__c = true;
                cov.Quote__c = quo.Id;
                cov.Coverage_Product__c = obj.Coverage_Product__c;
                cov.Page_Section__c = obj.Page_Section__c;
                cov.Coverage__c = obj.Id;
                cov.Form_Number__c = obj.Form_Number__c;
                cov.Coverage_Effective_Date__c = effectiveDate;
                cov.Added_in_current_transaction__c = addedInTxn;
                // create limit and deductibles
                for (Coverage_Limits_Deductibles__c item : obj.FeaturesProductOptions__r) {
                    CoveragesLineItem__c cli = cov.clone(false, true, false, false);
                    cli.Limits_Deductibles__c = item.Id;
                    cli.Page_Section__c = item.Page_Section__c;
                    String type = item.Endorsement_Data_Type__c;
                    cli.Option_Type__c = String.isBlank(type) ? 'Text' : type;
                    cli.Group__c = 1;
                    cli.Coverage_Effective_Date__c = effectiveDate;
                    if(obj.Coverage_Code__c == 'AQUW198'){
                        cli.Option_Value_Default__c = '5000';
                    }
                    limitItems.add(cli);
                }
                result.add(cov);
                result.addAll(limitItems);
            } catch (Exception ex) {
                System.debug(ex.getMessage());
                result.clear();
            }
        }
        return result;  
    }
}