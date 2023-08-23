public with sharing class RelatedListController {

    @AuraEnabled(cacheable=true)
    public static ResultResponse getDataTable(String objectType,String parentRecordId,String fields,String orderBy,String recordId){
        System.debug('infoJSON:' + parentRecordId);
        System.debug('infoJSON 22222222222:' + fields);
        ResultResponse result = new ResultResponse();
        LightningDataTableWrapper tbl = new LightningDataTableWrapper();
        String msg = '';
        try {
            ComponentInfo info = new ComponentInfo();//(ComponentInfo)JSON.deserialize(infoJSON, ComponentInfo.class);
            info.objectType = objectType;
            info.parentRecordId = parentRecordId;
            info.recordId = recordId;
            info.fields = fields;
            info.orderBy = orderBy;
            Id parentRecordId1 = info.parentRecordId;
            if (parentRecordId1 == null || String.isBlank(info.fields)) {
                msg = 'Missing some Component attribute. Please contact your administrators.';
                result.errors.add(msg);
                result.data = tbl;
                return result;
            }
            // get field list
            String fields1 = info.fields.deleteWhitespace();
            System.debug('FieldsValue'+fields1);
            // get sobject api name
            String parentObj = parentRecordId1.getSObjectType().getDescribe().getName();

            // generate table and data structure
            tbl = CommonUtil.generateDatatable(parentRecordId, objectType, fields, recordId);

            result.data = tbl;
            result.isSuccess = true;
        } catch (Exception ex){
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            msg = 'An error occurred while retrieving data. Please contact administrator for more information.';
            result.errors.add(msg);
            result.data = new LightningDataTableWrapper();
        }
        return result;
    }

    public class ComponentInfo {
        public Integer pageNumber {get;set;}
        public Integer recordToDisplay {get;set;}
        public String objectType {get;set;}
        public String parentRecordId {get;set;}
        public String recordId {get;set;}
        public String fields {get;set;}
        public String orderBy {get;set;}

        public ComponentInfo() {
            this.pageNumber = 0;
            this.recordToDisplay = 0;
            this.objectType = '';
            this.parentRecordId = '';
            this.recordId = '';
            this.fields = '';
            this.orderBy = '';
        }
    }
}