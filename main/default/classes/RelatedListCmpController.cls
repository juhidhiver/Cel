public with sharing class RelatedListCmpController {

    @AuraEnabled
    public static ObjectWrapper fetchData(String infoJSON) {
        ComponentInfo info = (ComponentInfo)JSON.deserialize(infoJSON, ComponentInfo.class);
        ObjectWrapper result = new ObjectWrapper();
        try {
            System.debug(info);
            String countQuery = getCountQueryString(info);
            String queryObjects = getObjectQueryString(info);

            System.debug(queryObjects);
            
            List<sObject> data = Database.query(queryObjects);
            Integer total = Database.countQuery(countQuery);

            result.data = data;
            result.total = total;
            result.page = info.pageNumber;
            result.pageSize = info.recordToDisplay;

        } catch (Exception ex) {
            result = new ObjectWrapper();
        }
       
       return result;
    }

    @AuraEnabled
    public static ResultResponse getDataTable(String infoJSON) {
        ResultResponse result = new ResultResponse();
        LightningDataTableWrapper tbl = new LightningDataTableWrapper();
        String msg = '';
        try {
            ComponentInfo info = (ComponentInfo)JSON.deserialize(infoJSON, ComponentInfo.class);

            Id parentRecordId = info.parentRecordId;
            if (parentRecordId == null || String.isBlank(info.fields)) {
                msg = 'Missing some Component attribute. Please contact your administrators.';
                result.errors.add(msg);
                result.data = tbl;
                return result;
            }

            
            // get field list
            String fields = info.fields.deleteWhitespace();
            System.debug(fields);
            // get sobject api name
            String parentObj = parentRecordId.getSObjectType().getDescribe().getName();

            // generate table and data structure
            tbl = CommonUtil.generateDatatable(parentRecordId, info.objectType, fields);

            result.data = tbl;
            result.isSuccess = true;
        } catch (Exception ex){
            System.debug(ex.getMessage());
            msg = 'An error occurred while retrieving data. Please contact administrator for more information.';
            result.errors.add(msg);
            result.data = new LightningDataTableWrapper();
        }
        return result;
    }

    private static String getCountQueryString(ComponentInfo info) {
        String objectType = String.escapeSingleQuotes(info.objectType);
        //String parentField = info.parentField;
        Id parentRecordId = info.parentRecordId;

        String countQuery = 'SELECT count() FROM ';
        countQuery += objectType;

        if (parentRecordId != null) {
            // get parent object name
            String parentObj = parentRecordId.getSObjectType().getDescribe().getName();

            // get relationship field
            String parentField = CommonUtil.getRelationshipField(parentObj, info.objectType);

            countQuery += ' WHERE ' + parentField +' =\'' + parentRecordId +'\'';
        }

        return countQuery;
    }



    /*
    private static String getObjectQueryString1(ComponentInfo info) {
        String objectType = String.escapeSingleQuotes(info.objectType);
        String parentField = info.parentField;
        Id parentRecordId = info.parentRecordId;
		
        String queryObjects = 'SELECT Id, Name, CreatedDate, Description FROM ';
        queryObjects += objectType;

        if (String.isNotEmpty(parentField) && parentRecordId != null) {
            parentField = String.escapeSingleQuotes(parentField);
			queryObjects += ' WHERE ' + parentField +' =\'' + parentRecordId +'\'';
        } else {
            queryObjects += ' ORDER BY Name ASC LIMIT ' + info.recordToDisplay
                    + ' OFFSET ' + (info.pageNumber - 1) * info.recordToDisplay;
        }

        return queryObjects;
    }
    */
    private static String getObjectQueryString(ComponentInfo info) {
        String result = '';
        try {

            if (info == null || String.isBlank(info.fields))
                return result;

            List<String> fields = info.fields.split(',');

            QueryObject obj = new QueryObject();
            obj.name = info.objectType;
            obj.pageNumber = info.pageNumber;
            obj.pageSize = info.recordToDisplay;
            obj.fields = fields;
            obj.orderByField = info.orderBy;
            obj.orderType = 'ASC'; 

            Id parentRecordId = info.parentRecordId;

            if (parentRecordId != null) {
                // get parent object name
                String parentObj = parentRecordId.getSObjectType().getDescribe().getName();

                // get relationship field
                String parentField = CommonUtil.getRelationshipField(parentObj, info.objectType);

                String condition = parentField +' =\'' + parentRecordId +'\'';
                obj.condition = condition;
            } 
            System.debug(obj);
            result = CommonUtil.buildQuery(obj);
            System.debug(result);
        } catch (Exception ex) {
            result = '';
            System.debug(ex.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static ObjectWrapper deleteRecord(String infoJSON) {
        ComponentInfo info = (ComponentInfo)JSON.deserialize(infoJSON, ComponentInfo.class);
        UserRecordAccess recAccess = [ SELECT  HasEditAccess, HasDeleteAccess, RecordId
                FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND RecordId =: info.recordId];

        if (recAccess != null && recAccess.HasDeleteAccess) {
            try {
                sObject sObj = Schema.getGlobalDescribe().get(info.objectType).newSObject();
                sObj.Id = info.recordId;
                delete sObj;
            } catch (DmlException e) {
                throw new AuraHandledException('Error while deleting data.');
            }
        }

        return fetchData(infoJSON);
    }

    public class ObjectWrapper {
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer page {get;set;}
        @AuraEnabled public Integer total {get;set;}
        @AuraEnabled public List<sObject> data {get;set;}
        ObjectWrapper(Integer pageSize, Integer page, Integer total, List<sObject> data) {
            this.pageSize = pageSize;
            this.page = page;
            this.total = total;
            this.data = data;
        }
        ObjectWrapper() {}
    }

    public class ComponentInfo {
        public Integer pageNumber {get;set;}
        public Integer recordToDisplay {get;set;}
        public String objectType {get;set;}
        public Id parentRecordId {get;set;}
        public Id recordId {get;set;}
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