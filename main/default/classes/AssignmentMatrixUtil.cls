/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 07-26-2022
 * @last modified by  : Vinayesh
**/
public with sharing class AssignmentMatrixUtil {
    private static final String EQUALS_OPERATOR = 'equals';
    private static final String NOT_EQUALS_OPERATOR = 'not equals';
    private static final String IN_OPERATOR = 'in';
    private static final String GREATER_THAN_OPERATOR = 'greater than';
    private static final String LESS_THAN_OPERATOR = 'less than';
    private static final String GREATER_THAN_EQUALS_OPERATOR = 'greater than equals';
    private static final String LESS_THAN_EQUALS_OPERATOR = 'less than equals';
    private static final String IS_NULL_OPERATOR = 'is null';
    private static final String NOT_NULL_OPERATOR = 'not null';

    private static final String DOCUMENT_TYPE = 'Document';


    /**
    * @description : Populate default assignments.
    * @author
    * @param primaryId, assignmentObjectType, productName 
    * @return List<String>
    **/
    public static Set<String> GetAssignmentData(String primaryId, String assignmentObjectType, String productName) {
       String prodName = productName.split(' ')[0];
        //Need to look at error handling. Probably need a wrapper result class with error msg
       Map<String,List<sObject>> relatedDataMap = getDataMap(primaryId, assignmentObjectType, prodName);
       //String productName = (String)quoteRelatedDataMap.get(((Id)quoteId).getSObjectType().getDescribe().getName())[0].get('Product_Name__c');

       
       Map<String, List<Assignment_Matrix__c>> filterCriteriaParentMap = getFilterCriteriaParentMap(assignmentObjectType, productName);
       Map<String, List<Assignment_Matrix_Rule__c>> filterCriteriaRuleMap = getFilterCriteriaRuleMap(filterCriteriaParentMap.values());
       
       Set<String> filteredDefaultDataIds = filterAssignments(relatedDataMap, filterCriteriaParentMap, filterCriteriaRuleMap);

       
       System.debug(filteredDefaultDataIds);
       return filteredDefaultDataIds;
    }

    /**
     * Logic to filter default coverages for quote
     */
    private static Set<String> filterAssignments(Map<String,List<sObject>> relatedDataMap, Map<String, List<Assignment_Matrix__c>> filterCriteriaParentMap,
                                                 Map<String, List<Assignment_Matrix_Rule__c>> filterCriteriaRuleMap) {
       Set<String> dataIds = new Set<String>();
       for(String dataId : filterCriteriaParentMap.keySet()){
           dataIds.add(dataId);
       }
       
       Set<String> defaultAssignments = new Set<String>();
       for(String dataId : dataIds){  
           boolean assignmentMatchFound = false;       
           for(Assignment_Matrix__c parentRule : filterCriteriaParentMap.get(dataId)){
               Map<Integer, Boolean> groupMatch = new Map<Integer, Boolean>();
               Boolean hasNonGroupCriteria = false;
               for(Assignment_Matrix_Rule__c criteriaRule : filterCriteriaRuleMap.get(parentRule.Id)){
                   boolean ruleMatch = false;
                   if(criteriaRule.Includes_Group_Number__c == null) hasNonGroupCriteria = true;
                   List<sObject> dataObjList = relatedDataMap.get(criteriaRule.Object_API_Name__c);
                   //Object dataValue = dataObj.get(criteriaRule.Field_API_Name__c);
                    for(sObject dataObj : dataObjList){
                        if(criteriaRule.Rule_Type__c == 'Key Value Query'){
                            List<String> lstKey = criteriaRule.Field_API_Name__c.split(';');
                            List<String> lstValue = criteriaRule.Value__c.split(';');
                            if(checkMatch(dataObj, lstKey[0], lstValue[0], 'Text', EQUALS_OPERATOR)
                                && checkMatch(dataObj, lstKey[1], lstValue[1], criteriaRule.Field_Type__c, criteriaRule.Operator__c)){
                                ruleMatch = true;
                            }
                        }
                        else{
                            ruleMatch = checkMatch(dataObj, criteriaRule.Field_API_Name__c, criteriaRule.Value__c, criteriaRule.Field_Type__c, criteriaRule.Operator__c);
                        }
                    }
                   
                    if(criteriaRule.Is_NOT__c) ruleMatch = !ruleMatch; //If IsNOT checked we want to return the inverse.
                    System.debug(criteriaRule.Name);
                    System.debug(ruleMatch);
                    if(ruleMatch && criteriaRule.Includes_Group_Number__c == null){
                        assignmentMatchFound = true;
                    }
                    else if(!ruleMatch && criteriaRule.Includes_Group_Number__c == null){
                        assignmentMatchFound = false;
                        break;
                    }
                    else{
                        Integer grpNum = criteriaRule.Includes_Group_Number__c.intValue();
                        if(!groupMatch.containsKey(grpNum)){
                            groupMatch.put(grpNum, ruleMatch);
                        }
                        if(ruleMatch){
                            groupMatch.put(grpNum, true);
                        }
                    }

                //    if(ruleMatch) {
                //         assignmentMatchFound = true;
                //    }
                //    else{
                //         assignmentMatchFound = false;
                //        break;
                //    }
                   
               }
                boolean groupsMatch = true;
                if(groupMatch.size() > 0){
                    for(Boolean currMatch : groupMatch.values()){
                        if(!currMatch) groupsMatch = false;
                    }
                }
               if(assignmentMatchFound && groupsMatch) break;
               if(!hasNonGroupCriteria && groupsMatch){
                   assignmentMatchFound = true;
                   break;
               }
               else{
                   assignmentMatchFound = false;
               }
           }

           if(assignmentMatchFound) defaultAssignments.add(dataId);
       }

       return defaultAssignments;
    }
    
    /**
     * check for field match
     */
    private static boolean checkMatch(sObject dataObj, String fieldName, String checkValue, String fieldType, String operator){
        Object dataValue = dataObj.get(fieldName);
        if(dataValue == null){
            if(operator == IS_NULL_OPERATOR){
                return true;
            }
            else return false;
        }
        else{
            if(operator == NOT_NULL_OPERATOR){
                return true;
            }
        }
        boolean ruleMatch = false;
        switch on fieldType {
            when 'Text' {
                String textVal = (String)dataValue;
                    if(operator == EQUALS_OPERATOR) {
                        if(textVal == checkValue){
                            ruleMatch = true;
                        }
                    }
                    else if(operator == NOT_EQUALS_OPERATOR) {
                        if(textVal != checkValue){
                            ruleMatch = true;
                        }
                    }
                    else if(operator == IN_OPERATOR) {
                        //Need to split values and check individually. Make this change in coverages matrix also.
                        if(checkValue.containsIgnoreCase(textVal)){
                            ruleMatch = true;
                        }
                    }
            }
            when 'Number' {
                decimal numVal = Decimal.valueOf(String.valueOf(dataValue));
                decimal numCheckValue = Decimal.valueOf(checkValue);
                if(operator == EQUALS_OPERATOR) {
                    if(numval == numCheckValue){
                        ruleMatch = true;
                    }
                }
                else if(operator == NOT_EQUALS_OPERATOR) {
                    if(numval != numCheckValue){
                        ruleMatch = true;
                    }
                }
                else if(operator == LESS_THAN_OPERATOR) {
                    if(numval < numCheckValue){
                        ruleMatch = true;
                    }
                }
                else if(operator == LESS_THAN_EQUALS_OPERATOR) {
                    if(numval <= numCheckValue){
                        ruleMatch = true;
                    }
                }
                else if(operator == GREATER_THAN_OPERATOR) {
                    if(numval > numCheckValue){
                        ruleMatch = true;
                    }
                }
                else if(operator == GREATER_THAN_EQUALS_OPERATOR) {
                    if(numval >= numCheckValue){
                        ruleMatch = true;
                    }
                }
            }
            when 'Boolean' {
                boolean isChecked = (boolean)dataValue;
                if(operator == EQUALS_OPERATOR) {
                    if(isChecked && checkValue == 'true'){
                        ruleMatch = true;
                    }
                    else if(!isChecked && checkValue == 'false'){
                        ruleMatch = true;
                    }
                }
            }
         }
         return ruleMatch;
    }

    /**
     * Get all related data used in filtering result.
     */
    private static Map<String,List<sObject>> getDataMap(String primaryId, String assignmentObjectType, String productName) {
      Map<String,List<sObject>> dataMap = new Map<String,List<sObject>>();
      String likeCondition = '%' + productName + '%';
      //Need to do normal soql here as static query for metadata has issue with long text area
      List<Assignment_Matrix_Query_Settings__mdt> queryList = [select Id, DeveloperName, MasterLabel, Label, QualifiedApiName, 
                                                               Object_Query__c, Is_Primary_Object__c, Related_Field_On_Primary_API_Name__c,
                                                               Lookup_Field_Api_name__c, Assignment_Object__c, Product_Name__c, Object_API_Name__c
                                                               From Assignment_Matrix_Query_Settings__mdt
                                                               Where Assignment_Object__c =: assignmentObjectType And Product_Name__c like :likeCondition And IsActive__c = true];
      //List<Assignment_Matrix_Query_Settings__mdt> queryList = Assignment_Matrix_Query_Settings__mdt.getall().values();
      List<sObject> primaryObj;
      for(Assignment_Matrix_Query_Settings__mdt queryItem : queryList){
          if(queryItem.Is_Primary_Object__c){
              String primaryQuery = queryItem.Object_Query__c + ' Where Id' + ' =: primaryId';
              primaryObj = Database.query(primaryQuery);
              dataMap.put(queryItem.Object_API_Name__c, primaryObj);
              break;
          }
      }
      for(Assignment_Matrix_Query_Settings__mdt queryItem : queryList){
        if(!queryItem.Is_Primary_Object__c){
          String lookupField = queryItem.Lookup_Field_API_name__c;
          String relatedFieldValue = (String)primaryObj[0].get(queryItem.Related_Field_On_Primary_API_Name__c);
          String relatedQuery = '';
          if(queryItem.Object_Query__c.containsIgnoreCase(' where ')){
              relatedQuery = queryItem.Object_Query__c + ' And ' + lookupField + ' =: relatedFieldValue';
          }
          else{
              relatedQuery = queryItem.Object_Query__c + ' Where ' + lookupField + ' =: relatedFieldValue';
          }
            
          List<sObject> relatedList = Database.query(relatedQuery);
          dataMap.put(queryItem.Object_API_Name__c, relatedList);
      }
    }
      return dataMap;
    }

      /**
       * Get Assignment Object Id to parent matrix records map.
       */
      private static Map<String, List<Assignment_Matrix__c>> getFilterCriteriaParentMap(String assignmentObjectType, String productName){

        List<Assignment_Matrix__c> matrixList = [SELECT  Name, Document_Template__c, Assignment_Object_Type__c, Product__c,
                                                 Lookup_Field_API_Name__c, IsActive__c, Description__c, Unique_Identifier__c
                                                 FROM Assignment_Matrix__c
                                                 WHERE IsActive__c = true AND Product__c like: productName AND Assignment_Object_Type__c =: assignmentObjectType];
        Map<String, List<Assignment_Matrix__c>> matrixMap = new Map<String, List<Assignment_Matrix__c>>();
        for(Assignment_Matrix__c rootItem : matrixList){
            String lookupField = (String)rootItem.get(rootItem.Lookup_Field_API_Name__c);
            if(!matrixMap.containsKey(lookupField)){
                matrixMap.put(lookupField, new List<Assignment_Matrix__c>());
            }
            matrixMap.get(lookupField).add(rootItem);
        }
        return matrixMap;
      }


    /**
     * Get Parent to Child Criteria Rule records map.
     */
    private static Map<String, List<Assignment_Matrix_Rule__c>> getFilterCriteriaRuleMap(List<List<Assignment_Matrix__c>> parentList){
        List<Assignment_Matrix__c> parentMatrices = new List<Assignment_Matrix__c>();
        for(List<Assignment_Matrix__c> listItems : parentList){
            parentMatrices.addAll(listItems);
        }
        List<Assignment_Matrix_Rule__c> filterRuleList = [SELECT Name, Assignment_Matrix__c, Field_API_Name__c, Field_Type__c, IsActive__c, 
                                                          Operator__c, Object_API_Name__c, Rule_Type__c, Value__c, Includes_Group_Number__c, Is_NOT__c
                                                          FROM Assignment_Matrix_Rule__c
                                                          WHERE Assignment_Matrix__c in: parentMatrices AND IsActive__c = true order by Includes_Group_Number__c];
        Map<String, List<Assignment_Matrix_Rule__c>> filterRuleMap = new Map<String, List<Assignment_Matrix_Rule__c>>();
        for(Assignment_Matrix_Rule__c ruleItem : filterRuleList){
            if(!filterRuleMap.containsKey(ruleItem.Assignment_Matrix__c)){
                filterRuleMap.put(ruleItem.Assignment_Matrix__c, new List<Assignment_Matrix_Rule__c>());
            }
            filterRuleMap.get(ruleItem.Assignment_Matrix__c).add(ruleItem);
        }
        
        return filterRuleMap;
    }

     /**
    * @description : Populate default documents.
    * @author
    * @param primaryId, productName 
    * @return List<Document_Template__c>
    **/
    public static List<Document_Template__c> GetDocumentsData(String primaryId, String productName) {       
        Set<String> filteredDefaultDocIds = GetAssignmentData(primaryId, DOCUMENT_TYPE, productName);
        System.debug(filteredDefaultDocIds);
        List<Document_Template__c> docList = [Select Id, Document_Name__c
                                              From Document_Template__c
                                              Where Id in: filteredDefaultDocIds];
        System.debug(docList);
        return docList;
        //return filteredDefaultDocIds;
     }
}