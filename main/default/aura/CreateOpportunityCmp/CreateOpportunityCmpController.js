({
    doInit : function(component,event,helper){
		helper.getRecordTypes(component,event);        
    },
	createRecord: function (component, event, helper) {
		//component.set("v.isOpen", true);
		var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({ 
            "entityApiName": "Opportunity",
			"defaultFieldValues": {
				'Name' : component.get("v.defaultvalue"),
				'AccountId' : component.get("v.accountId"),
				'Product__c' : component.get("v.productId")
			}
        });
        createRecordEvent.fire();
	},

	closeModel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
	handleRecordUpdated: function(component, event, helper) {
		component.find("AccrecordLoader").reloadRecord(true);
		component.find("ProrecordLoader").reloadRecord(true);
		component.set("v.defaultvalue",component.get("v.accountRecord.Name") + component.get("v.productRecord.Name"));
    },
    optionSelected : function(component,event,helper){
        component.set("v.loading",true);
        var recordName = event.target.getAttribute("value");
        var recordTypes = component.get("v.availableRecordTypes");
        for(var i=0;i<recordTypes.length;i++){
            if(recordName==recordTypes[i].value){   
                component.set("v.recordTypeId",recordTypes[i].key);
                break;
            }
        }
    }
})