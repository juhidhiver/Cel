/*************************************************
* Class Name: QuoteEndorsementChangeSummaryCtrl 
* Author: Giang Phan
* Date: 09/June/2020
* Requirement/Project Description: Show Quote Difference Design
* Revison : 
*************************************************/
public with sharing class QuoteEndorsementChangeSummaryCtrl {
    @AuraEnabled
    public static List<QuoteEndorsementChangeSummary__c> getQuoteEndorsementChangeSummary(String newQuoteId, Boolean dml) {
        system.debug('@@@@@getQuoteEndorsementChangeSummary@@@@@@@');
        List<QuoteEndorsementChangeSummary__c> quoteEndorChangeSummaryInserts = new List<QuoteEndorsementChangeSummary__c>();

        // get current quotes from parameter quote azure id
        List<Quote> newQuotes = getQuotesFromId(newQuoteId);            
        if(newQuotes.isEmpty() || String.isBlank(newQuotes[0].Policy__c) || String.isBlank(newQuotes[0].Parent_Quote__c)) {
            // show message error
            return quoteEndorChangeSummaryInserts;
        }       
        String productName = newQuotes[0].Product_Name__c;

        // get old Quotes is Parent of current Quote
        List<Quote> oldQuotes = getQuotesFromId(newQuotes[0].Parent_Quote__c);
   
        if(oldQuotes.isEmpty()) return quoteEndorChangeSummaryInserts;
    
        Quote newQuote = newQuotes[0];
        Quote oldQuote = oldQuotes[0];

        quoteEndorChangeSummaryInserts = compareQuoteByMetadata(oldQuote, newQuote);

        if(!quoteEndorChangeSummaryInserts.isEmpty() && dml) {
            List<QuoteEndorsementChangeSummary__c> qecsDeletes = [Select Id From QuoteEndorsementChangeSummary__c
                                                                Where QuoteId__c =: newQuote.Id And Old_QuoteId__c =: oldQuote.Id];
            if(!qecsDeletes.isEmpty()) delete qecsDeletes; // Delete old data
            insert quoteEndorChangeSummaryInserts;// Insert new data

            quoteEndorChangeSummaryInserts = [Select Id, ObjectName__c, QuoteId__c, Old_QuoteId__c, CoverageName__c, FieldName__c,
                                            Operation__c, OldValue__c, NewValue__c, SubCoverageName__c, RecordId__c, New_Record_Summary__c,
                                            Deleted_Record_Summary__c, Update_Record_Summary__c, RecordIdLink__c
                                            From QuoteEndorsementChangeSummary__c Where QuoteId__c =: newQuote.Id 
                                            And Old_QuoteId__c =: oldQuote.Id Order By SortOrder__c ASC];
            
        }
        System.debug('quoteEndorChangeSummaryInserts '+quoteEndorChangeSummaryInserts);
        return quoteEndorChangeSummaryInserts;
    }

    /*************************************************
    * Method Name: createQuoteEndorChangeSummary
    * Author: Quang Pham
    * Date: 17-Apr-2019
    * Params: 
    * Return: summary Quote Endorsement Change Summary Object
    * Exceptions: 
    * Revision:
    *************************************************/
    private static QuoteEndorsementChangeSummary__c createQuoteEndorChangeSummary(QuoteEndorChangeSummaryWrapper qECSWrap) {
        QuoteEndorsementChangeSummary__c summary = new QuoteEndorsementChangeSummary__c(
            ObjectName__c               = qECSWrap.objName, // required
            CoverageName__c             = qECSWrap.covName,
            SubCoverageName__c          = qECSWrap.subCovName,
            FieldName__c                = qECSWrap.fieldName,
            NewValue__c                 = qECSWrap.newValue,
            OldValue__c                 = qECSWrap.oldValue,
            QuoteId__c                  = qECSWrap.quoteId,
            Operation__c                = qECSWrap.operation,
            Old_QuoteId__c              = qECSWrap.oldQuoteId,
            RecordId__c                 = qECSWrap.recordId,
            New_Record_Summary__c       = qECSWrap.newRecSummary,
            Deleted_Record_Summary__c   = qECSWrap.deleteRecSummary,
            Update_Record_Summary__c    = qECSWrap.updateRecSummary,
            SortOrder__c                = qECSWrap.sortOrder,
            Limit_Deductible__c         = qECSWrap.limitsDeductibles
        );

        return summary;
    }

    /*************************************************
    * Method Name: getNewOrDeleteRecordSummary
    * Author: Quang Pham
    * Date: 17-Apr-2019
    * Params: strChk String Check
    * Return: 
    * Exceptions:
    * Revision: 13-05-19 Quang Pham a pipe separator like | in the New_Record_Summary attribute after each field within the record
    *************************************************/
    private static String getNewOrDeleteRecordSummary(Map<String, String> fieldMap) {
        String strSummary = '';
        for(String fieldName : fieldMap.keySet()) {
            strSummary += '' + fieldName + ': ' + fieldMap.get(fieldName) + '|';
        }
        if(String.isNotBlank(strSummary)) strSummary = strSummary.removeEnd('|');
        return strSummary;
    }

    /*************************************************
    * Method Name: getNewOrDeleteRecordSummary
    * Author: Quang Pham
    * Date: 17-Apr-2019
    * Params: strChk String Check
    * Return: 
    * Exceptions:
    * Revision: 
    *************************************************/
    private static String getNewOrDeleteRecordSummary(Map<String, String> fieldAPINameMap, SObject sobj) {
        String strSummary = '';
        for(String fieldAPI : fieldAPINameMap.keySet()) {
            strSummary += '' + fieldAPINameMap.get(fieldAPI) + ': ' + sobj.get(fieldAPI) + '|';
        }
        if(String.isNotBlank(strSummary)) strSummary = strSummary.removeEnd('|');
        return strSummary;
    }

    /*************************************************
    * Method Name: compareQuoteByMetadata
    * Author: Duc Pham
    * Date: 30-Jun-2019
    * Params: 
    * Return: 
    * Exceptions:
    * Revision: 
    *************************************************/
    private static List<QuoteEndorsementChangeSummary__c> compareQuoteByMetadata(Quote oldQuote, Quote newQuote) {
        List<QuoteEndorsementChangeSummary__c> qecsInsert = new List<QuoteEndorsementChangeSummary__c>();
        String productName = CommonUtil.getProductNameByQuoteId(newQuote.Id);
		
        //Get compare fields from 'Product Setting' Custom Meta Data Type
        List<String> fieldList = new List<String>();
        Product_Setting__mdt mdtSetting = (Product_Setting__mdt)CommonUtil.getSettingByField('Product_Setting__mdt',
                                                                            'Compared_Fields__c','MasterLabel', productName);
        // Map Object Fields
        Map<String, Object> objAPI_FieldsAPIMap = (Map<String, Object>)JSON.deserializeUntyped(mdtSetting.Compared_Fields__c);
        for(String key : objAPI_FieldsAPIMap.keySet()){
            String strFields = (String)objAPI_FieldsAPIMap.get(key);
            if(String.isNotBlank(strFields))
            {
                List<String> fields = strFields.split(',');
                System.debug('key -> '+ key);
                System.debug('fields -> '+ fields);
                Map<String, String> fieldAPINameMap = getCustomFieldsByObjectMap(key,fields);
                Map<String,String> mapSpecialParentField = new Map<String,String>{
                    'Quote' => 'Id',
                    'CoveragesLineItem__c'=>'Parent_Coverages_Line_Item__c'
                };
                String quoteField = (key =='Quote' ? mapSpecialParentField.get('Quote'): CommonUtil.getRelationshipField('Quote', key));
                String parentField = (key =='CoveragesLineItem__c' ? mapSpecialParentField.get('CoveragesLineItem__c') : CommonUtil.getRelationshipField(key, key));
                System.debug('quoteField -> '+quoteField);
                System.debug('parentField -> '+parentField);
                fields.add(parentField);
                fields.add(quoteField);
                // old SObject
                List<SObject> oldObjects = getRecordByQuoteId(key, fields, oldQuote.Id, quoteField);
                Map<String, SObject> sObjectId_sObjectOldMap = new Map<String, SObject>();
                for(SObject oldObj : oldObjects){
                    sObjectId_sObjectOldMap.put(oldObj.Id, oldObj);
                }
				System.debug('Old SObjects'+oldObjects);
                // new SObject
                List<SObject> newObjects = getRecordByQuoteId(key, fields, newQuote.Id, quoteField);
                System.debug('New Sobjects'+newObjects);
                Map<String, SObject> sObjectId_sObjectNewMap = new Map<String, SObject>();
                Map<String, SObject> sObjectId_sObjectParentMap = new Map<String, SObject>();
                for(SObject newObj : newObjects){
                    sObjectId_sObjectNewMap.put(newObj.Id, newObj);
                    if(String.isNotBlank((String)newObj.get(quoteField)))
                        sObjectId_sObjectParentMap.put((String)newObj.get(parentField), newObj);
                }
                Map<String, Map<String,String>> recIdTofieldUpdateMap = new Map<String, Map<String,String>>();
                List<QuoteEndorChangeSummaryWrapper> wrapQEObjUpdateList = new List<QuoteEndorChangeSummaryWrapper>();
                // repeat New Quote Schedule Stock
                for(SObject newQD : sObjectId_sObjectNewMap.values()) {
                    // get fields value for case new
                    Map<String, String> fieldRecMap = createFieldNameToValueMapQuoteChildObject(mdtSetting,newQD);
                    // Created new  Schedule Stock
                    if(String.isBlank((String)newQD.get(parentField)) && !sObjectId_sObjectOldMap.containsKey(newQD.Id)) {
                        // create Quote Endorsement Change Summary for case New
                        QuoteEndorChangeSummaryWrapper wrapQE = new QuoteEndorChangeSummaryWrapper();
                        wrapQE.quoteId            = newQuote.Id;
                        wrapQE.oldQuoteId         = oldQuote.Id;
                        wrapQE.objName            = key;
                        wrapQE.sortOrder          = 2;
                        wrapQE.operation          = 'Add';
                        wrapQE.fieldName          = '';
                        wrapQE.oldValue           = '';
                        wrapQE.newValue           = '';
                        wrapQE.recordId           = String.valueOf(newQD.Id);
                        wrapQE.newRecSummary      = getNewOrDeleteRecordSummary(fieldRecMap);
                        wrapQE.deleteRecSummary   = '';
                        wrapQE.covName            = '';
                        wrapQE.subCovName         = '';
        
                        qecsInsert.add(createQuoteEndorChangeSummary(wrapQE));
                    }
        
                    // for update Schedule Stock
                    else if(String.isNotBlank((String)newQD.get(parentField)) 
                            && sObjectId_sObjectOldMap.containsKey((String)newQD.get(parentField))) {
                        // Old value
                        SObject oldQD = sObjectId_sObjectOldMap.get((String)newQD.get(parentField));
                        for(String fieldAPI : fieldAPINameMap.keySet()) {
                            // Changed value of field
                            if(oldQD.get(fieldAPI) != newQD.get(fieldAPI)) {
                                // create Quote Endorsement Change Summary for case update
                                QuoteEndorChangeSummaryWrapper wrapQESC = new QuoteEndorChangeSummaryWrapper(); 
                                wrapQESC.quoteId            = newQuote.Id;
                                wrapQESC.oldQuoteId         = oldQuote.Id;
                                wrapQESC.objName            = key;
                                wrapQESC.sortOrder          = 6;
                                wrapQESC.operation          = 'Update';
                                wrapQESC.fieldName          = fieldAPINameMap.get(fieldAPI);
                                wrapQESC.oldValue           = String.valueOf(oldQD.get(fieldAPI));
                                wrapQESC.newValue           = String.valueOf(newQD.get(fieldAPI));
                                wrapQESC.recordId           = String.valueOf(newQD.Id);
                                wrapQESC.newRecSummary      = '';
                                wrapQESC.deleteRecSummary   = '';
                                wrapQESC.covName            = '';
                                wrapQESC.subCovName         = '';
                                wrapQESC.updateRecSummary   = getNewOrDeleteRecordSummary(fieldRecMap);
                                qecsInsert.add(createQuoteEndorChangeSummary(wrapQESC));
                            }
                        }
                    }
                }
                // repeat Old Quote_Schedule Stock
                for(SObject oldObj : sObjectId_sObjectOldMap.values()) {
                    if(!sObjectId_sObjectParentMap.containsKey(oldObj.Id)) {
                        // get fields value for case delete
                        Map<String, String> fieldRecDeleteMap = createFieldNameToValueMapQuoteChildObject(mdtSetting, oldObj);
                        // create Quote Endorsement Change Summary for case New
                        QuoteEndorChangeSummaryWrapper wrapQE = new QuoteEndorChangeSummaryWrapper();
                        wrapQE.quoteId            = newQuote.Id;
                        wrapQE.oldQuoteId         = oldQuote.Id;
                        wrapQE.objName            = key;
                        wrapQE.sortOrder          = 6;
                        wrapQE.operation          = 'Delete';
                        wrapQE.fieldName          = '';
                        wrapQE.oldValue           = '';
                        wrapQE.newValue           = '';
                        wrapQE.recordId           = String.valueOf(oldObj.Id);
                        wrapQE.newRecSummary      = '';
                        wrapQE.deleteRecSummary   = getNewOrDeleteRecordSummary(fieldRecDeleteMap);
                        wrapQE.covName            = '';
                        wrapQE.subCovName         = '';
        
                        qecsInsert.add(createQuoteEndorChangeSummary(wrapQE));
                    }
                }
            }
        }
        
        return qecsInsert;
    }

    public class QuoteEndorChangeSummaryWrapper {
        public String objName {get; set;}
        public String covName {get; set;}
        public String subCovName {get; set;}
        public String fieldName {get; set;}
        public String oldValue {get; set;}
        public String newValue {get; set;}
        public String operation {get; set;}
        public Id oldQuoteId {get; set;}
        public Id quoteId {get; set;}
        public String recordId {get; set;}
        public String newRecSummary {get; set;}
        public String deleteRecSummary {get; set;}
        public String updateRecSummary {get; set;}
        public Integer sortOrder {get; set;}
        public String limitsDeductibles {get; set;}

        public QuoteEndorChangeSummaryWrapper() {
            this.limitsDeductibles = '';
        }
    }

    

    

    /*************************************************
    * Method Name: Example
    * Author: Quang Pham
    * Date: 17-Apr-2019
    * Params: quoteId Quote Id
    * Return: quotes List of Quote
    * Exceptions:
    * Revision:
    *************************************************/
    private static List<Quote> getQuotesFromId(String quoteId) {
        List<Quote> quotes = [Select Id, Name, Product_Name__c,
                                Parent_Quote__c,
                                Azure_Id__c,
                                Effective_Date__c,
                                ExpirationDate,
                                CloseDate__c,
                                QuoteNumber,
                                Status,
                                Declined_Reason__c,
                                UW_Reason__c,
                                Rating_Status__c,
                                Tax,
                                Total_Premium__c,
                                Commission__c,
                                Commission_percentage__c,
                                QuotePremium__c,
                                Overall_UW_Codes__c,
                                Quote_Type__c,
                                OpportunityId,
                                AccountId,
                                Policy__c
                        From Quote Where Id = :quoteId];
        return quotes;
    }

    private static List<SObject> getRecordByQuoteId(String objName, List<String> fields, String quoteId, String quoteField){
        String condition = quoteField+' = ' + ':quoteId';
        String query = CommonUtil.buildQuery(fields, objName, condition);
        System.debug('query '+query);
        List<SObject> result = new List<SObject>();
        try {
            result = Database.query(query);
        } catch (Exception e) {
            System.debug(e.getMessage()+' '+e.getLineNumber());
            return result;
        }
        return result;
    }

    private static Map<String, String> createFieldNameToValueMapQuoteChildObject(Product_Setting__mdt mdtSetting, SObject sObj) {
        Map<String, String> returnMap = new Map<String, String>();
        if(sObj==NULL) return returnMap;

        List<String> fieldList = new List<String>();
        String sObjAPIName = sObj.Id.getSObjectType().getDescribe().getName();

        String strFields = (String)mdtSetting.Compared_Fields__c;
        if(mdtSetting.Compared_Fields__c.contains('{')){
        // Map Object Fields
            Map<String, Object> objAPI_FieldsAPIMap = (Map<String, Object>)JSON.deserializeUntyped(mdtSetting.Compared_Fields__c);
            strFields = (String)objAPI_FieldsAPIMap.get(sObjAPIName);
        }
        
        if(String.isNotBlank(strFields)) fieldList = strFields.split(',');
        
        Map<String, String> fieldAPINameMap = getCustomFieldsByObjectMap(sObjAPIName,fieldList);
    
        for(String strFieldName : fieldAPINameMap.keySet()){
            returnMap.put(fieldAPINameMap.get(strFieldName), String.valueOf(sObj.get(strFieldName)));
        }
    
        return returnMap;
    }
    private static Map<String, String> getCustomFieldsByObjectMap(String objName, List<String> fieldList) {
        Map<String, String> returnMap = new Map<String, String> ();
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objName).getDescribe().fields.getMap();
		for(Schema.SObjectField sfield : fieldMap.Values())
		{
            Schema.DescribeFieldResult dfield = sfield.getDescribe();
            if(fieldList.contains(dfield.getname()))
			returnMap.put(dfield.getname(),dfield.getLabel());
		}

        return returnMap;
    }
}