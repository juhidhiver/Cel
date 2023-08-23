public class customSingleRelListCtrl {
    @AuraEnabled( cacheable=true )
    public static RelatedListWrapper fetchRecords(String recordId,
                                                  String objectName,
                                                  String fieldConfigDetails,
                                                  String relationshipFieldName,
                                                  String soqlAdditionalWhereCondition)  {
                                                      RelatedListWrapper objWrap = new RelatedListWrapper();
                                                      List<RecordDetails> lstRecordDetailsWrapper = new List<RecordDetails>();
                                                      List<String> lstFieldDetails = fieldConfigDetails.split(';;');
                                                      
                                                      String strFields = 'Id ,';
                                                      for(String objFieldDetails: lstFieldDetails){
                                                          strFields += objFieldDetails.substringBetween('"apiName":"','"') + ',';
                                                      }
                                                      strFields = strFields.removeEnd(',');
                                                      
                                                      String strFilter = ' FROM ' + objectName + ' WHERE ' + relationshipFieldName + ' = \'' + recordId + '\'';
                                                      if(String.isNotBlank(soqlAdditionalWhereCondition)){
                                                          strFilter += soqlAdditionalWhereCondition;
                                                      }
                                                      String strCountSOQL = ' SELECT COUNT() ' + strFilter;
                                                      objWrap.recordCount = Database.countQuery(strCountSOQL);
                                                      String strSOQL = 'Select ' + strFields + strFilter + ' ORDER BY CreatedDate DESC';
                                                      List<SObject> lstFetchedRecords = Database.query(strSOQL);
                                                      
                                                      for(SObject objRecord: lstFetchedRecords){
                                                          RecordDetails objRecordDetailsWrapper = new RecordDetails();
                                                          objRecordDetailsWrapper.fieldId = objRecord.Id;
                                                          List<FieldConfigurations> lstFieldDetailsWrapper = new List<FieldConfigurations>();
                                                          for(String strField: lstFieldDetails){
                                                              FieldConfigurations objFieldWrapper = new FieldConfigurations();
                                                              objFieldWrapper.fieldLabel = strField.substringBetween('"label":"','"');
                                                              objFieldWrapper.fieldAPIName = strField.substringBetween('"apiName":"','"');
                                                              objFieldWrapper.isHyperlink = Boolean.valueOf(strField.substringBetween('"isHyperlink":"','"'));
                                                              objFieldWrapper.navigateToRecord = Boolean.valueOf(strField.substringBetween('"navigateToRecord":"','"'));
                                                              objFieldWrapper.value = objRecord.get(objFieldWrapper.fieldAPIName);
                                                              objFieldWrapper.recordIdForNavigation = (String)objRecord.get('Id');
                                                              lstFieldDetailsWrapper.add(objFieldWrapper);
                                                          }
                                                          objRecordDetailsWrapper.fieldDetails = lstFieldDetailsWrapper;
                                                          lstRecordDetailsWrapper.add(objRecordDetailsWrapper);
                                                      }
                                                      objWrap.numberOfRecords = lstRecordDetailsWrapper;
                                                      return objWrap;
                                                  }

    @AuraEnabled
    public static Document_Revision__c getDocRevisionRecord(String documentId){
        Document_Revision__c objDocRevision = [SELECT Name, Policy_Wording_Link__c FROM Document_Revision__c WHERE Id =: documentId];
        return objDocRevision;
    }
    
    public class RelatedListWrapper {
        @AuraEnabled
        public List <SObject> lstRecords;
        @AuraEnabled
        public Integer recordCount;
        @AuraEnabled
        public List<RecordDetails> numberOfRecords;
    }
    
    public class RecordDetails {
        @AuraEnabled
        public String fieldId;
        @AuraEnabled
        public List<FieldConfigurations> fieldDetails;
    }
    
    public class FieldConfigurations {
        @AuraEnabled
        public String fieldLabel;
        @AuraEnabled
        public String fieldAPIName;
        @AuraEnabled
        public Object value;
        @AuraEnabled
        public Boolean isHyperlink;
        @AuraEnabled
        public Boolean navigateToRecord;
        @AuraEnabled
        public String recordIdForNavigation;
    }
}