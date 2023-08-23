({
	init : function(component, event, helper) {
		//helper.doInit(component);
	},
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        // Check fein value before call api
        var fein = component.get("v.accountRecord.FEIN__c");
        if (fein == null) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Failed!",
                "message": "FEIN has no value.",
                "type":"error"
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
        }
        // Check fein value END 
        if(eventParams.changeType === "LOADED") {
            component.set("v.fein", fein);
            helper.doInit(component);
        }
    }
})