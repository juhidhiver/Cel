/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 07-25-2022
 * @last modified by  : Vinayesh
**/
public with sharing class EndorsementTabLwcController {
    private static final String PCC_PRODUCT_NAME = Label.Product_Name_for_PCC;

    @AuraEnabled
    public static List<String> getCategoryOptions(String quoteId){
        String productName = '';
        List<String> pccTagList = new List<String>();
        List<Endorsement_Tags__mdt> endorsementTags = [SELECT Tags__c FROM Endorsement_Tags__mdt
                                                       WHERE Product_Name__c =:PCC_PRODUCT_NAME];
        if(endorsementTags.size() > 0){
            String tagData = endorsementTags[0].Tags__c;
            if(tagData != null){
                pccTagList = tagData.split(';');
            }
        }

        List<Quote> qt = [select Product_Name__c from quote where Id=:quoteId];
        if(qt.size() > 0){
            productName = qt[0].Product_Name__c;
        }

        List<String> pickListValuesList= new List<String>();
        if(productName == PCC_PRODUCT_NAME){
            return pccTagList;
        }
        else{
            Schema.DescribeFieldResult fieldResult = Coverage__c.Endorsement_Tags__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(pickListVal.getLabel());
            }
            for(String pccTag : pccTagList){
                Integer idx = pickListValuesList.indexOf(pccTag);
                if(idx != -1){
                    pickListValuesList.remove(idx);
                }
            }
            return pickListValuesList;
        }
       
    }

    @AuraEnabled
    public static List<Coverage__c> searchCoverage(String searchName, List<String> searchCategories, String quoteId){
        List<Coverage__c> searchResult = new List<Coverage__c>();
        List<String> existedCoverageIds = new List<String>();
        List<Quote> quotes = new List<Quote>();
        List<String> fields = new List<String>();
        List<String> params = new List<String>();
        List<String> addRequirementValues = new List<String>();
        Set<String> clearedProductNames = new Set<String>();
        String condition = '';
        String temp = '';
        String productName = '';
        Id submissionId;
        String quoteLayer = '';
        // select object to query
        String objName = 'Coverage__c'; 
        
        try {
            quotes = [SELECT Id, AccountId, Product_Name__c, Coverage_Product_Options__c,OpportunityId, Opportunity.Main_Profession__c,Layer__c,Quote_Type__c 
                     FROM Quote WHERE Id =:quoteId];
            if (quotes.size() == 0) {
                return searchResult;
            }
            productName = quotes[0].Product_Name__c;
            quoteLayer = quotes[0].Layer__c;
            submissionId = quotes[0].OpportunityId;

            if(productName == GlobalVariables.PROD_NAME_FOR_PCC){
                //fetch existing Cleared POLIs
                for(Product_Option_Line_Item__c  poli : [SELECT Id,Product__r.Name from Product_Option_Line_Item__c where Submission__c =: submissionId AND Clearance_Status__c = 'Cleared']){
                    clearedProductNames.add(poli.Product__r.Name);
                }
                params.add('Coverage_Product_Combo__c INCLUDES (\''+ String.join(new List<String>(clearedProductNames),'\',\'') + '\')');
            }
            // select field to query
            fields.add('Id');
            fields.add('Name');
            fields.add('Endorsement_Categories__c');
            fields.add('Endorsement_Tags__c');
            fields.add('Form_Number__c');
            fields.add('Link_Document__c');
            fields.add('State__c');
            fields.add('Coverage_to_replace__c');
            fields.add('Coverage_Product__c');
            fields.add('Coverage_Product_Combo__c');
            fields.add('Apply_to_Quote__c');
            
            
            //fields.add('Is_Modified__c');
            if(productName =='Professional Indemnity'){
                //fields.add('Type__c');
                fields.add('Additional_Requirements__c');
            }
            List<CoveragesLineItem__c> listExistedCLI = [SELECT Id, Coverage__c,Coverage__r.Name FROM CoveragesLineItem__c WHERE Quote__c =: quoteId];
            for(CoveragesLineItem__c cli : listExistedCLI) {
                if(cli.Coverage__r.Name !='MPL Manuscript Template')
                existedCoverageIds.add(cli.Coverage__c);
            }
            
            // select condition to query
            String exceptionCoverages = '';
            String categoriesString = '';
            String predefinedString = '';
            String excessQuoteCondition = '';
            
            // additional requirements
            List<String> requirements = new List<String>();
            requirements.add('Load by Default');
            
            // filter by coverage type
            params.add('Coverage_Type__c = \'Endorsement\'');

            /** added by Vinay : to exclude NB and renewal coverages **/
            if(quotes[0].Quote_Type__c == 'New Business' || quotes[0].Quote_Type__c == 'Renewal')
                params.add('Additional_Requirements__c EXCLUDES (\'Exclude from NB and Renewal view\')');
            /** added by Vinay : to exclude NB and renewal coverages **/

            if(productName !='Professional Indemnity'){
                predefinedString = 'Additional_Requirements__c EXCLUDES (\''+ String.join(requirements,'\',\'') + '\') ';
                params.add('Additional_Requirements__c EXCLUDES (\'Do not show on Endorsement widget\')');
                params.add(predefinedString);
            }
            //changing search categories to Main Profession for AQ PI
            if(productName =='Professional Indemnity'){
                searchCategories = new List<String>{quotes[0].Opportunity.Main_Profession__c};
            }

            // filter by endorsement tag
            if(!searchCategories.isEmpty()) {
                categoriesString = 'AND Endorsement_Tags__c INCLUDES (\'' + String.join(searchCategories, '\', \'') + '\') ' ;
                if(productName !='Professional Indemnity'){
                    temp = 'Endorsement_Tags__c INCLUDES (\''+ String.join(searchCategories,'\',\'') + '\') ';
                }
                else{
                    temp = 'Main_Profession__c INCLUDES (\''+ String.join(searchCategories,'\',\'') + '\') ';
                }
                params.add(temp);
            }
            
            // filter by name
            String nameString = '';
            String key = '';
            String key1 = '';
            String key2 = '';
              if(String.isNotBlank(searchName)) {
                //searchName = 'AND Name Like \'%' + searchName + '%\'';
                key = '%' + searchName + '%'; 
                params.add('('+'Name LIKE :key OR Form_Number__c LIKE :key OR Form_Number__c=:key'+')');
            }

            
            // filter by product
            String productParam = '';
            List<String> product = new List<String>();
            if(quoteLayer == 'Excess' && productName.contains('Standalone')){
                product.add(quoteLayer);
                productParam = 'Coverage_Product__c IN(\''+ String.join(product,'\',\'') + '\')';
            }else if (productName.contains('Standalone') && quoteLayer != 'Excess') {
                product.add(productName.split(' ')[0]);
              /*  if(quotes[0].Attachment_Point__c=='Excess'){
                    product.add('Excess'); 
                }*/
                productParam = 'Coverage_Product__c IN(\''+ String.join(product,'\',\'') + '\')';
                
            } else {
                List<String> products = quotes[0].Product_Name__c.split(',');
                productParam = 'Coverage_Product__c IN (\''+ String.join(products,'\',\'') + '\')';
            }
            
            params.add(productParam);
            
            //filter coverage that not existed in quote //tuan.d.nguyen 14-Oct-2020
            exceptionCoverages = 'Id NOT IN (\''+ String.join(existedCoverageIds,'\',\'') + '\') ';
            params.add(exceptionCoverages);
            
            //filter coverages for excess
            String sortCondition = ' ORDER BY Name ASC';
            if(productName =='Professional Indemnity'){
                if(quotes[0].Layer__c == 'Excess'){
                    excessQuoteCondition = 'Apply_to_Quote__c includes (\'Primary;Excess\' , \'Excess\')';
                    params.add(excessQuoteCondition);
                }
                else if(quotes[0].Layer__c == 'Primary'){
                    excessQuoteCondition = 'Apply_to_Quote__c includes (\'Primary;Excess\' , \'Primary\')';
                    params.add(excessQuoteCondition);
                }
                //params.add(sortCondition);    
            }

            if(productName == PCC_PRODUCT_NAME){
                if(quotes[0].Layer__c == 'Excess'){
                    excessQuoteCondition = '(Apply_to_Quote__c includes (\'Primary;Excess\' , \'Excess\') Or Apply_to_Quote__c = null)';
                    params.add(excessQuoteCondition);
                }
                else if(quotes[0].Layer__c == 'Primary'){
                    excessQuoteCondition = '(Apply_to_Quote__c includes (\'Primary;Excess\' , \'Primary\') Or Apply_to_Quote__c = null)';
                    params.add(excessQuoteCondition);
                }
                //params.add(sortCondition);    
            }
          
            

            condition = String.join(params, ' AND ');
            String query = CommonUtil.buildQuery(fields, objName, condition) + sortCondition;
            
            //String query = 'SELECT Id, Name, Endorsement_Categories__c, Endorsement_Tags__c, Form_Number__c ' +
            //                'FROM Coverage__c WHERE Coverage_Type__c = \'Endorsement\' ' 
            //                + searchName + categoriesString + exceptionCoverages;
            
            searchResult = (List<Coverage__c>) Database.query(query);
            for(Coverage__c cov :  searchResult ) {
                if(String.isBlank(cov.Link_Document__c)) {
                    cov.Link_Document__c = '/lightning/r/Coverage__c/' + cov.Id + '/view';
                }
                if(productName =='Professional Indemnity'){
                    if(!String.isBlank(cov.Additional_Requirements__c)){
                        String filterValue = cov.Additional_Requirements__c;
                        if(filterValue.contains('Part')) {
                            cov.Additional_Requirements__c = 'Part-Fixed';
                        }
                        else if(filterValue.contains('Fixed')) {
                            cov.Additional_Requirements__c = 'Fixed';
                        }
                    }
                }
            }

            //Filtering Coverages by State and performing replacement for coverages.
            searchResult = QuoteTriggerHandler_Common.filterCoveragesForQuote(searchResult, quotes[0],
                               QuoteTriggerHandler_Common.generateAccountStateMap(quotes),searchResult);

        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
        return searchResult; 
    }
    
    @AuraEnabled
    public static ResultResponse insertEndorsementCLI(String quoteId, String coverageId){
        ResultResponse response = new ResultResponse();
        Coverage__c selectedCoverage = [SELECT Id, Default_Notes__c, Coverage_Product__c, (SELECT Id, Name, Type__c, Endorsement_Data_Type__c,Option_Picklist__c,Default_Value__c FROM FeaturesProductOptions__r) FROM Coverage__c WHERE Id =: coverageId LIMIT 1];
        List<Coverage_Limits_Deductibles__c> listLimitDeductibles = selectedCoverage.FeaturesProductOptions__r;
        List<CoveragesLineItem__c> insertCLI = new List<CoveragesLineItem__c>();
        
        Quote quo = [SELECT Quote_Type__c, Effective_Date__c, Endorsement_Effective_Date__c, Product_Name__c FROM Quote WHERE Id =: quoteId LIMIT 1];
        if( quo != null ){

            Id cliRecordTypeId = null;
            //Assign Record type based on product of code of quote (added by Jai)
            if( quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_CYBER ) ||
                quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_MPL ) ||
                quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PCC )
            ){
                cliRecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
            }else if(quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PI ) ){
                cliRecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
            }

            CoveragesLineItem__c newCLI = new CoveragesLineItem__c();
            //Assign Record type (added by Jai)
            if( cliRecordTypeId != null ){
                newCLI.RecordTypeId = cliRecordTypeId;
            }
            newCLI.Quote__c = quoteId;
            newCLI.Coverage_Product__c = selectedCoverage.Coverage_Product__c;
            newCLI.Coverage__c = coverageId;
            newCLI.Notes__c = selectedCoverage.Default_Notes__c;//added by Jai
            
            insertCLI.add(newCLI);
            if(!listLimitDeductibles.isEmpty()) {
                for(Coverage_Limits_Deductibles__c item : listLimitDeductibles) {
                    CoveragesLineItem__c newCLI2 = new CoveragesLineItem__c();
                    //Assign Record type (added by Jai)
                    if( cliRecordTypeId != null ){
                        newCLI2.RecordTypeId = cliRecordTypeId;
                    }
                    newCLI2.Quote__c = quoteId;
                    newCLI2.Coverage_Product__c = selectedCoverage.Coverage_Product__c;
                    newCLI2.Coverage__c = coverageId;
                    newCLI2.Limits_Deductibles__c = item.Id;
                    // newCLI2.Option_Type__c = item.Type__c;
                    newCLI2.Option_Type__c = item.Endorsement_Data_Type__c;
                    if(String.isBlank(newCLI2.Option_Type__c)) 
                        newCLI2.Option_Type__c = 'Text';
                    newCLI2.Group__c = 1;
                    insertCLI.add(newCLI2);
                }
            } 
            
            
            Savepoint sp = Database.setSavepoint();
            // List<CoveragesLineItem__c> resultCLI = new List<CoveragesLineItem__c>();
            try {
                insert insertCLI;
                //resultCLI = getEndorsementCLI(quoteId, coverageId);
                response.isSuccess = true;
            } catch (Exception ex) {
                Database.rollback(sp);
                response.isSuccess = false;
                response.errors.add(ex.getMessage() + ' - ' + ex.getLineNumber());
            }
            // List<String> cliIds = new List<String>();
            // for(Integer i = 0; i < insertCLI.size(); i++)
            //     cliIds.add(insertCLI[i].Id);
            // List<CoveragesLineItem__c> resultCLI = [SELECT Id, Coverage__r.Name, Limits_Deductibles__r.Name, Option_Type__c, Option_Value_Default__c
            //                                         FROM CoveragesLineItem__c WHERE Id In :cliIds];
        }
        return response;
    }
    
    @AuraEnabled
    public static ResultResponse addEndorsementCLI(String quoteId, List<Coverage__c> items, List<String> tags){
        ResultResponse result = new ResultResponse();
        List<CoveragesLineItem__c> insertItems = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> deleteItems = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> oldItems = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> newItems = new List<CoveragesLineItem__c>();
        List<Coverage__c> deleteCovs = new List<Coverage__c>();
        List<Coverage__c> insertCovs = new List<Coverage__c>();
        List<Endorsement> selectedCovs = new List<Endorsement>();
        Set<String> newCovIds = new Set<String>();
        Set<String> oldCovIds = new Set<String>();
        
        Savepoint sp = Database.setSavepoint();
        try {
            if (items == null) {
                return result;
            }
            
            for (Coverage__c item : items) {
                newCovIds.add(item.Id);
            }
            
            // get exist coverage line items
            oldItems = getEndorsementCoverageLineItem(quoteId);
            // remove coverage line item which does not have specific tags
            // oldItems = removeCLIByTag(oldItems, tags);
            // group old cli by coverage
            Map<String, List<CoveragesLineItem__c>> itemMap = generateCLIMap(oldItems);
            oldCovIds = itemMap.keySet();
            // get new coverage for insert
            insertCovs = getCoverageForInsert(items, oldCovIds);
            
            // get coverage line item for deleting
            //deleteItems = getCLIForDelete(oldItems, newCovIds);
            // generate coverage line item for inserting
            insertItems = getCLIForInsert(quoteId, insertCovs);
            //delete deleteItems;
            insert insertItems;
            // Update Quote Status when Endorsement is changed
            List<Quote> lstQuote = [SELECT Id,Quote.Product_Name__c ,Status FROM Quote WHERE Id =: quoteId ];
            Quote quoteUpdate = new Quote();
            if(!lstQuote.isEmpty()) {
                quoteUpdate = lstQuote[0];
            }
            if (updateQuoteStatus(insertCovs, deleteItems) && quoteUpdate.Product_Name__c != 'Professional Indemnity') {
                quoteUpdate.Status = 'In Progress';
                update quoteUpdate;
            }
            else if(quoteUpdate.Product_Name__c == 'Professional Indemnity' && (quoteUpdate.Status != 'In Progress')){
                quoteUpdate.Status = 'In Progress';
                update quoteUpdate;
            }

            //selectedCovs = getSelectedEndorsement(quoteId);
            selectedCovs = getSelectedEndorsement(quoteId);
            result.data = selectedCovs;
            result.isSuccess = true;
        } catch (Exception ex) {
            Database.rollback(sp);
            result.isSuccess = false;
            result.errors.add(ex.getMessage() + ' - ' + ex.getLineNumber());
        }
        
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 04-Aug-2020
* Params: list1 - List of String
* Params: list2 - List of String
* Description: Check if two list has any common member
* Revision: 
*************************************************/ 
    private static Boolean hasCommon(List<String> list1, List<String> list2) {
        Boolean result = false;
        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();
        
        if (list1 == null || list2 == null) return result;
        
        set1.addAll(list1);
        set2.addAll(list2);
        
        for (String s1 : list1) {
            if (list2.contains(s1)) return true; 
        }
        
        return result;
    }
    
    public static List<CoveragesLineItem__c> removeCLIByTag(List<CoveragesLineItem__c> items, List<String> tags) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        List<String> cliTags = new List<String>();
        String tag = '';
        
        for (CoveragesLineItem__c item : items) {
            cliTags.clear();
            // Coverages without tag are invalid
            if (String.isBlank(item.Coverage__r.Endorsement_Tags__c)) 
                continue;
            
            // get coverage line item tags
            tag = item.Coverage__r.Endorsement_Tags__c;
            cliTags.addAll(tag.split(';'));
            
            // get coverage line item with specific tag
            if (hasCommon(cliTags, tags)) {
                result.add(item);
            }
        }
        return result;
    }
    
    private static List<CoveragesLineItem__c> getEndorsementCoverageLineItem(String quoteId) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        result = [SELECT Id, Name, Coverage__c, Coverage__r.Endorsement_Tags__c, Type__c, Rating__c
                  FROM CoveragesLineItem__c 
                  WHERE Quote__c = :quoteId 
                  AND Type__c LIKE 'Endorsement%' AND Coverage__r.Name !='MPL Manuscript Template' ];
        return result;
    }
    
    @AuraEnabled
    public static ResultResponse saveEndorsement(List<Endorsement> items){
        ResultResponse result = new ResultResponse();
        List<CoveragesLineItem__c> clis = new List<CoveragesLineItem__c>();
        try {
            // List<Endorsement> items = new List<Endorsement>();
            if (items == null) {
                result.errors.add('No endorsement to save.');
                return result;
            }

            for (Endorsement item : items) {
                CoveragesLineItem__c cli = item.generateCoverageLineItem();
                clis.add(cli);
            }
            update clis;

             //added by Jai to rate after save on Endosment start
             if( items.size() > 0 ){
                list<CoveragesLineItem__c> cliList = [Select Id, Quote__c, Quote__r.Opportunity.RecordType.Name from CoveragesLineItem__c where Id =: items[0].cli ];
                if( cliList.size() > 0 && cliList[0].Quote__r.Opportunity.RecordType.Name == GlobalVariables.RT_NAME_CELERITY){
                    ID jobID = System.enqueueJob(new SyncQuoteQueueable( new list<Quote>{new Quote(Id = cliList[0].Quote__c)} ));
                }
            }
            //added by Jai to rate after save on Endosment end
            result.errors.add('Save selected endorsements successfully.');
            result.isSuccess = true;
        } catch (Exception ex) {
            result.errors.add(ex.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static List<String> getSelectedCoverages(String quoteId, List<Coverage__c> items) {
        List<String> result = new List<String>();
        List<String> quotes = new List<String>();
        List<CoveragesLineItem__c> clis = new List<CoveragesLineItem__c>();
        Set<String> ids = new Set<string>();
        quotes.add(quoteId);
        // get new coverage line items
        clis = getEndorsementCoverageLineItem(quoteId);
        for (CoveragesLineItem__c cli : clis) {
            ids.add(cli.Coverage__c);
        }
        
        for (Coverage__c item : items) {
            if (ids.contains(item.Id)) {
                result.add(item.Id);
            }
        }
        
        return result;
    }
    
    private static List<Coverage__c> getCoverageForInsert(List<Coverage__c> newitems, Set<String> oldItems) {
        List<Coverage__c> result = new List<Coverage__c>();
        List<String> ids = new List<String>();
        for (Coverage__c item : newitems) {
            if (oldItems.contains (item.Id)) continue;
            ids.add(item.Id);
            
            //result.add(item);
        }
        
        result = [SELECT Id, Coverage_Product__c, Page_Section__c, Form_Number__c, Endorsement_Tags__c, Rating__c,
                  (SELECT Id, Name, Type__c, Endorsement_Data_Type__c, Page_Section__c , Option_Picklist__c,Default_Value__c
                   FROM FeaturesProductOptions__r) 
                  FROM Coverage__c 
                  WHERE Id IN :ids];
    
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 04-Aug-2020
* Params: oldItems - List of existing Coverage Line Item
* Params: newItemIds - Id of new Coverage
* Description: Generate list coverage line item for deleting
* Revision: 
*************************************************/ 
    private static List<CoveragesLineItem__c> getCLIForDelete(List<CoveragesLineItem__c> oldItems, 
                                                              Set<String> newItemIds) {
                                                                  List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
                                                                  try {
                                                                      if (oldItems == null) return result;
                                                                      
                                                                      for (CoveragesLineItem__c item : oldItems) {
                                                                          // coverage is already existed
                                                                          if (newItemIds.contains(item.Coverage__c)) continue;
                                                                          
                                                                          // Coverage line item belong to removed coverage
                                                                          result.add(item);
                                                                      }
                                                                  } catch (Exception ex) {
                                                                      result.clear();
                                                                  }
                                                                  
                                                                  return result;                                                            
                                                              }
    
    private static Map<String, List<CoveragesLineItem__c>> generateCLIMap(List<CoveragesLineItem__c> objs) {
        Map<String, List<CoveragesLineItem__c>> result = new Map<String, List<CoveragesLineItem__c>>();
        for (CoveragesLineItem__c obj : objs) {
            if (result.containsKey(obj.Coverage__c)) {
                List<CoveragesLineItem__c> items = result.get(obj.Coverage__c);
                items.add(obj);
                result.put(obj.Coverage__c, items);
            } else {
                result.put(obj.Coverage__c, new List<CoveragesLineItem__c> {obj});
            }
        }
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 05-Aug-2020
* Params: quoteId - Id of quote
* Params: items - List of selected Endorsement
* Description: generate list of new coverage line item from coverage and limit deductible
for inserting 
* Revision: 
*************************************************/ 
    private static List<CoveragesLineItem__c> getCLIForInsert(String quoteId, List<Coverage__c> items) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        List<String> ids = new List<String>();
        try {
            if (items == null) return result;
            Quote quo = [SELECT Quote_Type__c, Product_Name__c, Effective_Date__c, Endorsement_Effective_Date__c FROM Quote WHERE Id =: quoteId LIMIT 1];
            for (Coverage__c item : items) {
                List<CoveragesLineItem__c> clis = GenerateCLIByCoverage(item, quo);
                result.addAll(clis);
            }
        } catch (Exception ex) {
            result.clear();
        }
        
        return result;                                                            
    }
    
    private static List<CoveragesLineItem__c> GenerateCLIByCoverage(Coverage__c obj, Quote quo) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> limitItems = new List<CoveragesLineItem__c>();
        CoveragesLineItem__c cov = new CoveragesLineItem__c();
        Coverage__c selectedCoverage = [SELECT Id, Default_Notes__c FROM Coverage__c WHERE Id =: obj.Id LIMIT 1];
        Date effectiveDate; // add effective date to coverage line item
        if(quo != null){

            Id cliRecordTypeId = null;
            //Assign Record type based on product of code of quote (added by Jai)
            if( quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_CYBER ) ||
                quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_MPL ) ||
                quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PCC )
            ){
                cliRecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
            }else if(quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PI ) ){
                cliRecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
            }

              // Changes made as per Bug 56783 - Juhi 26/5/2022	
            if(quo.Quote_Type__c == 'New Business' || quo.Quote_Type__c == 'Renewal' || quo.Quote_Type__c == 'Coverage Cancel and Replace'){	
                effectiveDate = quo.Effective_Date__c;	
            }else {	
                if(quo.Endorsement_Effective_Date__c != NULL)	
                effectiveDate = quo.Endorsement_Effective_Date__c;	
            }

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
                    cov.RecordTypeId = cliRecordTypeId;
                }
                cov.Quote__c = quo.Id;
                cov.Coverage_Product__c = obj.Coverage_Product__c;
                cov.Page_Section__c = obj.Page_Section__c;
                cov.Coverage__c = obj.Id;
                cov.Form_Number__c = obj.Form_Number__c;
                cov.Coverage_Effective_Date__c = effectiveDate;
                cov.Added_in_current_transaction__c = addedInTxn;
                cov.Notes__c = selectedCoverage.Default_Notes__c;//added by Jai
                // create limit and deductibles
                for (Coverage_Limits_Deductibles__c item : obj.FeaturesProductOptions__r) {
                    CoveragesLineItem__c cli = cov.clone(false, true, false, false);
                    cli.Limits_Deductibles__c = item.Id;
                    cli.Page_Section__c = item.Page_Section__c;
                    String type = item.Endorsement_Data_Type__c;
                    cli.Option_Type__c = String.isBlank(type) ? 'Text' : type;
                    cli.Group__c = 1;
                    cli.Coverage_Effective_Date__c = effectiveDate;
                    cli.Option_Picklist__c = item.Option_Picklist__c; // Added by Maeran 54322 on 24/1/2022 to have picklist in Endorsement Limits edit
                    cli.Option_Value_Default__c = item.Default_Value__c; // Added by Maeran for US: 54294
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
    
    //get the list coverageLineItem to edit
    @AuraEnabled
    public static EndorsementTable getEndorsementCLI(String quoteId, String coverageId) {
        List<CoveragesLineItem__c> listCLI = [SELECT Id, Coverage__r.Name, Limits_Deductibles__r.Name, 
                                              Option_Type__c, Option_Value_Default__c, Group__c,
                                              Option_Picklist__c, Min_amt__c, Max_amt__c 
                                              FROM CoveragesLineItem__c WHERE Quote__c =: quoteId 
                                              AND Coverage__c =: coverageId 
                                              ORDER BY Limits_Deductibles__r.Sort_Order__c NULLS LAST,Limits_Deductibles__r.Name NULLS LAST];
        									  //ORDER BY Limits_Deductibles__r.Name];
        
        
        // Coverage__c endorsementCoverage = [SELECT Id, Name, Schedule__c FROM Coverage__c 
        //                                     WHERE Id =: coverageId LIMIT 1];
        
        // EndorsementTable table = new EndorsementTable();
        // table.setEndorsementTable(listCLI, endorsementCoverage.Schedule__c);
        
        //Vien Pham code modified in 5 Octorber, 2020, ticket 31181
        Coverage__c endorsementCoverage = [SELECT Id, Name, Additional_Requirements__c FROM Coverage__c 
                                           WHERE Id =: coverageId LIMIT 1];
        
        EndorsementTable table = new EndorsementTable();
        //Added by Giang 14/Oct/2020
        Boolean isSchedule = endorsementCoverage.Additional_Requirements__c == null ? false : endorsementCoverage.Additional_Requirements__c.contains('Schedule');
        
        table.setEndorsementTable(listCLI, isSchedule);
        
        return table;
    }
    
    @AuraEnabled
    public static ResultResponse saveUpdatedCLI(String updatedRecordsString, Endorsement endorsement, String quoteId) {
        List<UpdateObject> listUpdateObject = (List<UpdateObject>)System.JSON.deserialize(updatedRecordsString, List<UpdateObject>.class);
        ResultResponse response = new ResultResponse();
        List<sObject> listUpdate = new List<sObject>();
        for(UpdateObject updateObject : listUpdateObject) {
            sObject obj = Id.valueOf(updateObject.Id).getSObjectType().newSObject();
            obj.put('Id', updateObject.Id);
            obj.put('Is_Modified__c',true);
            SObjectType r = obj.getSObjectType();
            DescribeSObjectResult d = r.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = d.fields.getMap().get('Option_Value_Default__c').getDescribe();
            if(fieldDescribe.getType() == Schema.DisplayType.Double)
                obj.put('Option_Value_Default__c', Double.valueOf(updateObject.value));
            else
                obj.put('Option_Value_Default__c', updateObject.value);
            listUpdate.add(obj);
        }

        // Added logic to update all CLI with isMOdified true for Save on CLI... This will hightlight edit button 
        if(endorsement != null && String.isNotBlank(quoteId)){
            for(CoveragesLineItem__c cli : [Select Id,Is_Modified__c from CoveragesLineItem__c where Coverage__c =:endorsement.Id and Quote__c =:quoteId and CoverageLineItemType__c ='Main Coverage']){
                cli.Is_Modified__c = true;            
                listUpdate.add(cli);
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try{
            update listUpdate;
            /*
            if(endorsement != null && endorsement.id != null){
                Coverage__c cov = new Coverage__c(Id = endorsement.id);
                cov.Is_Modified__c = true;
                update cov;
            }
            */
            if (endorsement != null && endorsement.rating) {
                // Mark as edited on parent coverage record
                
                Quote q = new Quote();  
                q.id = quoteId;
                q.Status = 'In Progress';
                
                update q;
            }
            response.isSuccess = true;
        } catch(Exception ex) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.errors.add(ex.getMessage());
        }
        return response;
    }
    
    @AuraEnabled
    public static List<Endorsement> getSelectedEndorsement(String quoteId){
        List<Endorsement> result = new List<Endorsement>();
        try {
            List<String> listCoverageId = new List<String>();
            List<CoveragesLineItem__c> clis = new List<CoveragesLineItem__c>();
            Quote que=[select id,layer__c,Product_Name__c,OpportunityId from quote where Id=:quoteId];
            Opportunity opp = new Opportunity();
            if(que.Product_Name__c == 'Professional Indemnity'){
                clis = [SELECT Id, Coverage__r.Name, Coverage__r.Id, Coverage__r.Link_Document__c,//added Link_Document__c
                    Limits_Deductibles__r.Name, Notes__c, Form_Number__c,Is_Modified__c,//added Is_Modified__c
                    Option_Type__c, Option_Value_Default__c, Group__c,Coverage__r.Coverage_Code__c,
                    Option_Picklist__c, Min_amt__c, Max_amt__c, Rating__c,IsSelected__c,
                    CoverageLineItemType__c, Coverage_Effective_Date__c, Parent_Coverages_Line_Item__c// tuan.d.nguyen added 3-Dec-2020
                    FROM CoveragesLineItem__c 
                    WHERE Quote__c =: quoteId 
                    AND Coverage__r.Coverage_Type__c = 'Endorsement' AND Coverage__r.Additional_Requirements__c EXCLUDES ('Do not show on Endorsement widget')];
            }else {
                if(que.Layer__c=='Primary' )
            {
            opp =[select id, LeadSource from Opportunity where Id=:que.OpportunityId];
            clis = [SELECT Id, Coverage__r.Name, Coverage__r.Id, Coverage__r.Link_Document__c,//added Link_Document__c
                    Limits_Deductibles__r.Name, Notes__c, Form_Number__c,Is_Modified__c, //added Is_Modified__c
                    Option_Type__c, Option_Value_Default__c, Group__c,Coverage__r.Coverage_Code__c,
                    Option_Picklist__c, Min_amt__c, Max_amt__c, Rating__c,IsSelected__c,
                    CoverageLineItemType__c, Coverage_Effective_Date__c, Parent_Coverages_Line_Item__c// tuan.d.nguyen added 3-Dec-2020
                    FROM CoveragesLineItem__c 
                    WHERE Quote__c =: quoteId 
                    AND Coverage__r.Coverage_Type__c = 'Endorsement' AND Coverage__r.Additional_Requirements__c EXCLUDES ('Do not show on Endorsement widget') order by Coverage__r.Name ASC];
            }
            else{
                clis = [SELECT Id, Coverage__r.Name, Coverage__r.Id, Coverage__r.Link_Document__c,//added Link_Document__c
                    Limits_Deductibles__r.Name, Notes__c, Form_Number__c,Is_Modified__c, //added Is_Modified__c
                    Option_Type__c, Option_Value_Default__c, Group__c,Coverage__r.Coverage_Code__c,
                    Option_Picklist__c, Min_amt__c, Max_amt__c, Rating__c,IsSelected__c,
                    CoverageLineItemType__c, Coverage_Effective_Date__c, Parent_Coverages_Line_Item__c// tuan.d.nguyen added 3-Dec-2020
                    FROM CoveragesLineItem__c 
                    WHERE Quote__c =: quoteId 
                    AND Coverage__r.Coverage_Type__c = 'Endorsement' AND Coverage__r.Additional_Requirements__c EXCLUDES ('Do not show on Endorsement widget') and (coverage_product__c like '%Excess' OR coverage_product__c=: GlobalVariables.PROD_NAME_FOR_PCC) order by Coverage__r.Name ASC ];
                
            } 
                
            }
            

            // AND Type__c = 'Endorsement Coverage'
            // AND CoverageLineItemType__c = 'Main Coverage'];
            List<CoveragesLineItem__c> mainCLI = new List<CoveragesLineItem__c>();
            Map<String, List<CoveragesLineItem__c>> mapMainCLI = new Map<String, List<CoveragesLineItem__c>>();
            for (CoveragesLineItem__c cli : clis) {
                if(cli.CoverageLineItemType__c == 'Main Coverage') {
                    mainCLI.add(cli);
                    listCoverageId.add(cli.Coverage__r.Id);
                } else if(cli.CoverageLineItemType__c == 'Limit Option') {
                    List<CoveragesLineItem__c> listCLI = new List<CoveragesLineItem__c>();
                    if(mapMainCLI.get(cli.Coverage__r.Id) != null) 
                        listCLI = mapMainCLI.get(cli.Coverage__r.Id);
                    listCLI.add(cli);
                    mapMainCLI.put(cli.Coverage__r.Id, listCLI);
                }
            }
            Map<Id, Coverage__c> mapCLItoCoverage = new Map<Id, Coverage__c>([SELECT Id, Name, Additional_Requirements__c, Coverage_Product__c,
                                                                              (SELECT Id, Name FROM FeaturesProductOptions__r) 
                                                                              FROM Coverage__c WHERE Id IN :listCoverageId]);
            for (CoveragesLineItem__c cli : mainCLI) {
                if(mapCLItoCoverage.get(cli.Coverage__r.Id) != null) 
                    if (String.isNotBlank(mapCLItoCoverage.get(cli.Coverage__r.Id).Additional_Requirements__c) &&
                        (mapCLItoCoverage.get(cli.Coverage__r.Id).Additional_Requirements__c.contains('Load by Default') 
                        || mapCLItoCoverage.get(cli.Coverage__r.Id).Additional_Requirements__c.contains('Load without limit'))) {
                            if(/*!mapCLItoCoverage.get(cli.Coverage__r.Id).Coverage_Product__c.contains('Cyber') &&*/ !mapCLItoCoverage.get(cli.Coverage__r.Id).Additional_Requirements__c.contains('Load without limit')){
                                Boolean isShowed = checkIsShowed(cli.Coverage__r.Id, mapMainCLI);
                                //Added for US:56764 --- Showing coverages that have no limit asscociated for CYber.
                                if(mapCLItoCoverage.get(cli.Coverage__r.Id).Coverage_Product__c.contains('Cyber') || mapCLItoCoverage.get(cli.Coverage__r.Id).Coverage_Product__c.contains('MPL') 
                                || mapCLItoCoverage.get(cli.Coverage__r.Id).Coverage_Product__c == 'Excess'){
                                    List<CoveragesLineItem__c> listCLI = mapMainCLI.get(cli.Coverage__r.Id);
                                    if(listCLI == null || listCLI.isEmpty()) 
                                        isShowed = true;
                                    if(cli.CoverageLineItemType__c == 'Main Coverage' && cli.Coverage__r.Coverage_Code__c == 'BIandExtraExpenses')
                                        isShowed = checkVisibilityForCoverage(quoteId, cli.Coverage__r.Coverage_Code__c);
                                    if(cli.CoverageLineItemType__c == 'Main Coverage' && cli.Coverage__r.Coverage_Code__c == 'CyberCrime')
                                        isShowed = checkVisibilityForCoverage(quoteId, cli.Coverage__r.Coverage_Code__c);
                                    if(cli.CoverageLineItemType__c == 'Main Coverage' && (cli.Coverage__r.Coverage_Code__c == 'TechnologyEO' || cli.Coverage__r.Coverage_Code__c == 'TechnologyEONonProf'))
                                        isShowed = checkVisibilityForCoverage(quoteId, cli.Coverage__r.Coverage_Code__c);
                                }
                                if(isShowed) {
                                    Endorsement obj = new Endorsement(cli, mapCLItoCoverage);
                                    result.add(obj);
                                }
                            }
                            else{
                                System.debug('Coverage name-->'+mapCLItoCoverage.get(cli.Coverage__r.Id).Name);
                                Endorsement obj = new Endorsement(cli, mapCLItoCoverage);
                                result.add(obj);
                            }
                        }
                else{
                        Endorsement obj = new Endorsement(cli, mapCLItoCoverage);
                        result.add(obj);
                }
            }
           //Below Code run only for Cyber ShopX -- creating only the list of Coverages with Is_Selected true 59750
           if((opp.LeadSource == 'Shopping X' || opp.LeadSource == 'ShopX') && que.Product_Name__c == 'Cyber Standalone'){
            List<Endorsement> cyberCovList = new List<Endorsement>();
            for(Endorsement res : result){
            if(res.isSelected == true ){
                cyberCovList.add(res);
             }
            }
             result = new List<Endorsement>();
             if(!cyberCovList.isEmpty()) result.addAll(cyberCovList);
            }  
        } catch (Exception ex) {
           System.debug(ex.getMessage()+ex.getLineNumber() + ex.getStackTraceString());
       }
      
    return result;
   }
    
    public static Boolean checkVisibilityForCoverage(String quoteId, String covCode) {
        List<CoveragesLineItem__c> listCLi = new List<CoveragesLineItem__c>();
        if(covCode == 'BIandExtraExpenses')
            listCLi = [SELECT Id, Coverage__r.Name, Coverage__r.Id, Coverage__r.Link_Document__c,//added Link_Document__c
                                            Limits_Deductibles__r.Name, Notes__c, Form_Number__c,Is_Modified__c, //added Is_Modified__c
                                            Option_Type__c, Option_Value_Default__c, Group__c,Coverage__r.Coverage_Code__c,
                                            Option_Picklist__c, Min_amt__c, Max_amt__c, Rating__c,
                                            CoverageLineItemType__c, Coverage_Effective_Date__c, Parent_Coverages_Line_Item__c// tuan.d.nguyen added 3-Dec-2020
                                            FROM CoveragesLineItem__c 
                                            WHERE Quote__c =: quoteId 
                                            AND (Limits_Deductibles__r.LmtDedCode__c = 'OutsourcedSecurityAggregateLimit' or Limits_Deductibles__r.LmtDedCode__c = 'BIEESchedule'
                                                 or Limits_Deductibles__r.LmtDedCode__c = 'InsuredSystemAggregateLimit' or Limits_Deductibles__r.LmtDedCode__c = 'OutsourcedSystemAggregateLimit')];
        if(covCode == 'CyberCrime')
            listCLi = [SELECT Id, Coverage__r.Name, Coverage__r.Id, Coverage__r.Link_Document__c,//added Link_Document__c
                                        Limits_Deductibles__r.Name, Notes__c, Form_Number__c,Is_Modified__c, //added Is_Modified__c
                                        Option_Type__c, Option_Value_Default__c, Group__c,Coverage__r.Coverage_Code__c,
                                        Option_Picklist__c, Min_amt__c, Max_amt__c, Rating__c,
                                        CoverageLineItemType__c, Coverage_Effective_Date__c, Parent_Coverages_Line_Item__c// tuan.d.nguyen added 3-Dec-2020
                                        FROM CoveragesLineItem__c 
                                        WHERE Quote__c =: quoteId 
                                        AND (Limits_Deductibles__r.LmtDedCode__c = 'FundsTransferLimit' or Limits_Deductibles__r.LmtDedCode__c = 'SocialEngineeringLimit'
                                            or Limits_Deductibles__r.LmtDedCode__c = 'InvoiceManipulationLimit' or Limits_Deductibles__r.LmtDedCode__c = 'TelecommunicationsLimit')];
        if(covCode == 'TechnologyEO' || covCode == 'TechnologyEONonProf')
            listCLi = [SELECT Id, Coverage__r.Name, Coverage__r.Id, Coverage__r.Link_Document__c,//added Link_Document__c
                                        Limits_Deductibles__r.Name, Notes__c, Form_Number__c,Is_Modified__c, //added Is_Modified__c
                                        Option_Type__c, Option_Value_Default__c, Group__c,Coverage__r.Coverage_Code__c,
                                        Option_Picklist__c, Min_amt__c, Max_amt__c, Rating__c,Limits_Deductibles__r.LmtDedCode__c,
                                        CoverageLineItemType__c, Coverage_Effective_Date__c, Parent_Coverages_Line_Item__c// tuan.d.nguyen added 3-Dec-2020
                                        FROM CoveragesLineItem__c 
                                        WHERE Quote__c =: quoteId 
                                        AND (Limits_Deductibles__r.LmtDedCode__c = 'TechEOoptionType' or Limits_Deductibles__r.LmtDedCode__c = 'TechEOLimit')];
         
        
        
        //Changes for US:58386
        if(covCode == 'TechnologyEO' || covCode == 'TechnologyEONonProf'){
            String techOptionType,techOptionVal;
            for(CoveragesLineItem__c item : listCLI) {
                if(item.Limits_Deductibles__r.LmtDedCode__c == 'TechEOoptionType'){
                    techOptionType = item.Option_Value_Default__c;
                }
                else if(item.Limits_Deductibles__r.LmtDedCode__c == 'TechEOLimit'){
                    techOptionVal = item.Option_Value_Default__c;
                }
            }
            if(covCode == 'TechnologyEONonProf' && techOptionType == 'Tech E&O' && String.isNotBlank(techOptionVal) && techOptionVal != '0'){
                return true;
            }
            if(covCode == 'TechnologyEO' && techOptionType == 'Tech & Prof E&O' && String.isNotBlank(techOptionVal) && techOptionVal != '0'){
                return true;
            }
        }
        else{
            for(CoveragesLineItem__c item : listCLI) {
                if(String.isNotBlank(item.Option_Value_Default__c) && item.Option_Value_Default__c != '0'
                   && item.Option_Value_Default__c != 'No Coverage') {
                       return true;
                   }
            }
        }
        
        return false;
    }

    public static Boolean checkIsShowed(String coverageId, Map<String, List<CoveragesLineItem__c>> mapMainCLI) {
        List<CoveragesLineItem__c> listCLI = mapMainCLI.get(coverageId);
        if(listCLI == null || listCLI.isEmpty()) 
            return false;
        else {
            for(CoveragesLineItem__c item : listCLI) {
                if(String.isNotBlank(item.Option_Value_Default__c) && item.Option_Value_Default__c != '0'
                   && item.Option_Value_Default__c != 'No Coverage') {
                       return true;
                   }
            }
        }
        return false;
    }
    
    @AuraEnabled
    public static Boolean deleteEndorsementCLI(String quoteId, String coverageLineItemId){


        List<CoveragesLineItem__c> listCLI = [SELECT Id, Coverage__r.Name, Coverage_Product__c,
                                              Limits_Deductibles__r.Name, Option_Type__c,
                                              Option_Value_Default__c, Type__c, Rating__c, Coverage__c
                                              FROM CoveragesLineItem__c 
                                              WHERE Quote__c =: quoteId AND Id =: coverageLineItemId];
        String covName = listCLI[0].Coverage__r.Name;

        system.debug('listCLI1'+listCLI);

        //if(listCLI[0].Coverage_Product__c == 'Professional Indemnity'){
            listCLI = [SELECT Id, Coverage__r.Name, Coverage_Product__c,
                                              Limits_Deductibles__r.Name, Option_Type__c,
                                              Option_Value_Default__c, Type__c, Rating__c
                       FROM CoveragesLineItem__c WHERE Coverage__r.Name =: covName
                  							  AND Quote__c =: quoteId];
        //}
       	
        system.debug('listCLI2'+listCLI);

        Savepoint sp = Database.setSavepoint();
        try {
            delete listCLI;

            /*
            Coverage__c cov = new Coverage__c(id = listCLI[0].Coverage__c, Is_Modified__c = false);
            update cov;
            */

            List<Quote> lstQuote = [SELECT Id, Status FROM Quote WHERE Id = :quoteId];
            List<Quote> lstUpdate = new List<Quote>();
            Set<Id> checkQuoteAlreadyExist = new Set<Id>();
            if(!lstQuote.isEmpty()) {
                for(CoveragesLineItem__c item : listCLI){
                    if(item.Type__c == 'Endorsement Coverage' && item.Rating__c == true){
                        lstQuote[0].Status = 'In Progress';                      
                        lstUpdate.add(lstQuote[0]);
                    }
                }

                system.debug('lstUpdate'+lstUpdate.size());
                system.debug('listCLI'+listCLI.size());

                if(lstUpdate.size()>0){
                update lstUpdate[0];
                }
             
            }
            
        } catch(Exception ex) {
            Database.rollback(sp);
            return false;
        }
        return true;
    }
    
    public static List<CoveragesLineItem__c> filterListCLI(List<CoveragesLineItem__c> listCLI, Boolean onlyCoverageCLI) {
        List<CoveragesLineItem__c> filterdListCLI = new List<CoveragesLineItem__c>();
        for(CoveragesLineItem__c item: listCLI) {
            if(onlyCoverageCLI) {
                if(item.Limits_Deductibles__r.Name == null) 
                    filterdListCLI.add(item);
            }
            else {
                if(item.Limits_Deductibles__r.Name != null) 
                    filterdListCLI.add(item);
            } 
        }
        
        return filterdListCLI;
    }
    
    @AuraEnabled
    public static EndorsementTable addNewRow(String quoteId, String coverageId){
        Coverage__c selectedCoverage = [SELECT Id, Default_Notes__c, Coverage_Product__c, (SELECT Id, Name, Type__c, Endorsement_Data_Type__c,Option_Picklist__c,Default_Value__c FROM FeaturesProductOptions__r) FROM Coverage__c WHERE Id =: coverageId LIMIT 1];
        List<Coverage_Limits_Deductibles__c> listLimitDeductibles = selectedCoverage.FeaturesProductOptions__r;
        List<CoveragesLineItem__c> insertCLI = new List<CoveragesLineItem__c>();
        
        //get max group;
        List<CoveragesLineItem__c> listExistedCLI = new List<CoveragesLineItem__c>();
        if(!listLimitDeductibles.isEmpty())
            listExistedCLI = [SELECT Id, Group__c FROM CoveragesLineItem__c WHERE Limits_Deductibles__c =: listLimitDeductibles[0].Id AND Quote__c =:quoteId ORDER BY Group__c desc];
        Integer maxGroup = 0;
        if(!listExistedCLI.isEmpty())
            maxGroup = Integer.valueOf(listExistedCLI[0].Group__c);
        
        //tuan.d.nguyen 11-Dec-2020 start: apply coverage effective date
        Quote quo = [SELECT Quote_Type__c, Effective_Date__c, Endorsement_Effective_Date__c, Product_Name__c FROM Quote WHERE Id =: quoteId LIMIT 1];
        Date effectiveDate; // add effective date to coverage line item
        if(quo != null)
            if(quo.Quote_Type__c == 'New Business')
            effectiveDate = quo.Effective_Date__c;
        else if(quo.Quote_Type__c == 'Amendment')
            effectiveDate = quo.Endorsement_Effective_Date__c;
        //tuan.d.nguyen 11-Dec-2020 end
        
        //Assign Record type based on product of code of quote (added by Jai)
        Id cliRecordTypeId = null;
        if( quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_CYBER ) ||
            quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_MPL ) ||
            quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PCC )
        ){
            cliRecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
        }else if(quo.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PI ) ){
            cliRecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        }

        if(!listLimitDeductibles.isEmpty()) {
            for(Coverage_Limits_Deductibles__c item : listLimitDeductibles) {
                CoveragesLineItem__c newCLI = new CoveragesLineItem__c();
                //Assign Record type (added by Jai)
                if( cliRecordTypeId != null ){
                    newCLI.RecordTypeId = cliRecordTypeId;
                }               

                newCLI.Quote__c = quoteId;
                newCLI.Coverage_Product__c = selectedCoverage.Coverage_Product__c;
                newCLI.Coverage__c = coverageId;
                newCLI.Limits_Deductibles__c = item.Id;
                newCLI.Group__c = maxGroup + 1;
                newCLI.Option_Type__c = item.Endorsement_Data_Type__c;
                if(String.isBlank(newCLI.Option_Type__c)) 
                    newCLI.Option_Type__c = 'Text';
                newCLI.Coverage_Effective_Date__c = effectiveDate; //tuan.d.nguyen 9-Dec-2020
                newCLI.Notes__c = selectedCoverage.Default_Notes__c;
                insertCLI.add(newCLI);
            }
        } 
        Savepoint sp = Database.setSavepoint();
        // List<CoveragesLineItem__c> resultCLI = new List<CoveragesLineItem__c>();
        EndorsementTable resultTable = new EndorsementTable();
        try {
            insert insertCLI;
            // List<String> cliIds = new List<String>();
            // for(Integer i = 0; i < insertCLI.size(); i++)
            //     cliIds.add(insertCLI[i].Id);
            // resultCLI = [SELECT Id, Coverage__r.Name, Limits_Deductibles__r.Name, 
            //                 Option_Type__c, Option_Value_Default__c, Group__c,
            //                 Option_Picklist__c, Min_amt__c, Max_amt__c 
            //                 FROM CoveragesLineItem__c WHERE Id In :cliIds];
            resultTable = getEndorsementCLI(quoteId, coverageId);
        } catch (Exception ex) {
            Database.rollback(sp);   
        }
        return resultTable;
    }
    
    //delete row
    @AuraEnabled
    public static String deleteRow(List<String> listIds){
        List<sObject> listDelete = new List<sObject>();
        for(String objId : listIds) {
            sObject obj = Id.valueOf(objId).getSObjectType().newSObject();
            obj.put('Id', objId);
            listDelete.add(obj);
        }
        Savepoint sp = Database.setSavepoint();
        try{
            delete listDelete;
        } catch(Exception ex) {
            Database.rollback(sp);
            return ex.getMessage();
        }
        return 'success';
    }
    
    
    public class UpdateObject {
        public String id {get;set;}
        public String value {get;set;}
        public UpdateObject() {
            this.id = '';
            this.value = '';
        }
    }
    
    public class EndorsementTable {
        @AuraEnabled
        public List<EndorsementTableColumn> listColumns {get; set;}
        @AuraEnabled
        public List<CoveragesLineItem__c> data {get; set;}
        @AuraEnabled
        public List<CoveragesLineItem__c> onlyCoverageCLI {get; set;}
        @AuraEnabled
        public Map<String, List<CoveragesLineItem__c>> groupedData {get;set; }
        @AuraEnabled
        public Boolean isSchedule {get; set;}
        
        
        public EndorsementTable() {
            this.listColumns = new List<EndorsementTableColumn>();           
            this.onlyCoverageCLI = new List<CoveragesLineItem__c>();
            this.isSchedule = false;
            this.data = new List<CoveragesLineItem__c>();
            this.groupedData = new Map<String, List<CoveragesLineItem__c>>();    
        }
        
        public void setEndorsementTable(List<CoveragesLineItem__c> listCLI, Boolean schedule) {
            this.isSchedule = schedule;
            this.data = filterListCLI(listCLI, false);
            this.onlyCoverageCLI = filterListCLI(listCLI, true);
            List<String> listGroup = new List<String>();
            List<String> columnNames = new List<String>();
            String name = '';
            List<String> columnIds = new List<String>();
            String columnId = '';
            for(CoveragesLineItem__c item : this.data) {
                name = item.Limits_Deductibles__r.Name;
                columnId = item.Limits_Deductibles__c;
                if(!columnIds.contains(columnId)) {
                    columnIds.add(columnId);
                    EndorsementTableColumn tableColumn = new EndorsementTableColumn();
                    tableColumn.setEndorsementTableColumn(item);
                    this.listColumns.add(tableColumn); 
                }
                
                if(!listGroup.contains(String.valueOf(item.Group__c))) 
                    listGroup.add(String.valueOf(item.Group__c));
            }
            
            //filter group;
            for(String groupName : listGroup) {
                List<CoveragesLineItem__c> listCLIByGroup = new List<CoveragesLineItem__c>();
                for(CoveragesLineItem__c item : this.data) {
                    if(String.valueOf(item.Group__c) == groupName)
                        listCLIByGroup.add(item);
                }
                this.groupedData.put(groupName, listCLIByGroup);
            }
        }
    }
    
    public class EndorsementTableColumn {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String fieldName {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public Boolean editable {get; set;}
        // @AuraEnabled
        // public static String format {get;set;}
        @AuraEnabled
        public List<String> options {get;set;}
        @AuraEnabled
        public String min {get;set;}
        @AuraEnabled
        public String max {get;set;}
        
        public EndorsementTableColumn() {
            this.id = '';
            this.label = '';
            this.fieldName = '';
            this.type = 'text';
            this.editable = false;
            //
            this.options = new List<String>();
            this.min = '';
            this.max = '';
        }
        
        public void setEndorsementTableColumn(CoveragesLineItem__c item) {
            this.id = item.Limits_Deductibles__c;
            String name = '';
            name = item.Limits_Deductibles__r.Name;
            this.label = name;
            this.fieldName = name;
            this.type = 'Text';
            if(String.isNotBlank(item.Option_Type__c))
                this.type = item.Option_Type__c;
            
            String picklist = String.valueOf(item.Option_Picklist__c);  
            if(String.isNotBlank(picklist))
                this.options = picklist.split(';');
            this.min = String.valueOf(item.Min_amt__c);
            this.max = String.valueOf(item.Max_amt__c);
        }
    }
    
    public class Endorsement {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String cli {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String formNumber {get; set;}
        @AuraEnabled
        public String note {get; set;}
        @AuraEnabled
        public Boolean rating {get; set;}
        @AuraEnabled
        public String documentUrl {get; set;}
        @AuraEnabled
        public Boolean limitsDeductibles {get; set;}
        @AuraEnabled
        public Boolean isDeleteTable {get; set;} //Added 5/Oct/2020 Remove the Delete Icon 
        @AuraEnabled
        public String effectiveDate {get; set;}
        @AuraEnabled
        public Boolean isModified {get;set;}
         @AuraEnabled
        public Boolean IsSelected {get;set;}

        public Endorsement() {
            
        }
        
        public Endorsement(CoveragesLineItem__c item, Map<Id, Coverage__c> mapCLItoCoverage) {
            if (item.Coverage__r == null) return;
            
            this.id = item.Coverage__r.Id;
            this.cli = item.Id;
            this.isSelected = item.IsSelected__c;
            this.name = item.Coverage__r.Name;
            this.formNumber = item.Form_Number__c;
            this.isModified = item.Is_Modified__c; //added check to see if modified
            this.rating = item.Rating__c;
            this.note = item.Notes__c;
            this.limitsDeductibles = false; //added check Limit & Deductibles
            this.isDeleteTable = true; //Added 5/Oct/2020 Remove the Delete Icon 
            this.documentUrl = item.Coverage__r.Link_Document__c; //added Link_Document__c
            if(String.isBlank(this.documentUrl)) 
                this.documentUrl = '/lightning/r/Coverage__c/' + this.id + '/view';
            //29/Sep/2020 Check Limit&Deductibles in Coverage from CLI
            if(mapCLItoCoverage.get(item.Coverage__r.Id) != null && !mapCLItoCoverage.get(item.Coverage__r.Id).FeaturesProductOptions__r.isEmpty())
                this.limitsDeductibles = true; 
            //Added 5/Oct/2020 Remove the Delete Icon 
            if(mapCLItoCoverage.get(item.Coverage__r.Id) != null && mapCLItoCoverage.get(item.Coverage__r.Id).Additional_Requirements__c != null){
                if(mapCLItoCoverage.get(item.Coverage__r.Id).Additional_Requirements__c.contains('Rating Required') 
                   && mapCLItoCoverage.get(item.Coverage__r.Id).Additional_Requirements__c.contains('Load by Default')){
                       this.isDeleteTable = false;
                   }
            }
            this.effectiveDate =  item.Coverage_Effective_Date__c != null? item.Coverage_Effective_Date__c.format(): '';
            
        }
        
        public CoveragesLineItem__c generateCoverageLineItem() {
            CoveragesLineItem__c result = new CoveragesLineItem__c();
            result.Id = this.cli;
            result.Notes__c = this.note;
            
            return result;
        }
    }
    /*************************************************
* Author: Phuong La
* Date: 03-Sep-2020
* Params: insertItems - List Coverages
* Params: deleteItems - List CoveragesLineItems
* Description: Check Rating__c of CLI which are changed(add, delete), if true => update Quote Status to 'In Progress'
* Revision: 
*************************************************/ 
    public static Boolean updateQuoteStatus(List<Coverage__c> insertItems, List<CoveragesLineItem__c> deleteItems) {
        // insert
        for(Coverage__c item : insertItems) {
            if(item.Rating__c == true){
                return true;
            }
        }
        // delete
        for(CoveragesLineItem__c item : deleteItems) {
            if(item.Type__c == 'Endorsement Coverage' && item.Rating__c == true){
                return true;
            }
        }
        return false;
    }
}