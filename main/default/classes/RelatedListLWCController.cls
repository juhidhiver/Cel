public with sharing class RelatedListLWCController {
    
    //Lightning Web Components get List Opportunity
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunityList(String accId) {
        system.debug('2222222222222222:' + accId);
        return [SELECT Id, Name FROM Opportunity WHERE AccountId = :accId];
    }

    //Delete record Opportunity
    @AuraEnabled
    public static void deleteOpportunity(list<Id> lstOppIds){
        try {
            list<Opportunity> lstOppsToDelete = new list<Opportunity>();
            for(Id idOpp : lstOppIds) {
                lstOppsToDelete.add(new Opportunity(Id = idOpp));
            }
            if(!lstOppsToDelete.isEmpty()) {
                delete lstOppsToDelete;
            }
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
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