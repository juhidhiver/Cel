({
    doInit : function(component, event, helper) {
        
        component.set('v.columns', [
            {label: 'Record Id', fieldName: 'RecordIdLink__c', type: 'url', typeAttributes: { label: { fieldName: 'RecordId__c' }, target:'_blank'}},
            {label: 'Object Name', fieldName: 'ObjectName__c', type: 'text'},
            {label: 'Field Name', fieldName: 'FieldName__c', type: 'text'},
            {label: 'Coverage Name', fieldName: 'CoverageName__c', type: 'text'},
            {label: 'Operation', fieldName: 'Operation__c', type: 'text'},
            {label: 'OldValue', fieldName: 'OldValue__c', type: 'text'},
            {label: 'NewValue', fieldName: 'NewValue__c', type: 'text'},
            {label: 'New Record Summary', fieldName: 'New_Record_Summary__c', type: 'text'},
            {label: 'Deleted Record Summary', fieldName: 'Deleted_Record_Summary__c', type: 'text'}
        ]);
        
        var action = component.get("c.getQuoteEndorsementChangeSummary");
        
        action.setParams({
            "newQuoteId": component.get("v.recordId"),
			"dml": true
        });
        
        //console.log('==QuoteId==' + component.get("v.recordId"));
        
        action.setCallback(this, function(response){
            
            component.set("v.isShowSpinner", false);
			            
            var state = response.getState();
            if (state === "SUCCESS") {
                var records =response.getReturnValue();
                
                records.forEach(function(record){
                    record.RecordIdLink__c = '/' + record.RecordId__c;
                });
                component.set("v.listData", records);
            }
            console.log('==listData==');
            console.log(component.get("v.listData"));
        });
        
        $A.enqueueAction(action);
    }
})