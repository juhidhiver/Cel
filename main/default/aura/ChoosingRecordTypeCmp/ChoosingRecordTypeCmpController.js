({
	doInit: function(component, event, helper) {    
	console.log('##recordtypeCmp Init');    
        var action = component.get("c.getRecordTypeValues");
		action.setParams({
			"objName": component.get("v.objName")
		});
        action.setCallback(this, function(response) {
            var state = response.getState();
			var count = 0;

            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var recordTypes = result.objRecordTypes;
                var recordtypeMap = [];
                for(var key in recordTypes){
                    recordtypeMap.push({label: recordTypes[key], value: key});
					count++;
                }
				
                component.set("v.recordTypeMap", recordtypeMap);
                component.set("v.selectedRecordTypeId", result.defaultRecordTypeId);
				component.set("v.count", count);
				
				//console.log('##recordTypesize: ' + count);
				if(count==0){
					var createRecordEvent = $A.get("e.force:createRecord");
						createRecordEvent.setParams({
							"entityApiName": component.get("v.objName"),
							"navigationLocation":"LOOKUP"
						});
					createRecordEvent.fire();
					component.find("overlayLib").notifyClose();
				}
            }
        });
        $A.enqueueAction(action);
    },
     
    handleCreateRecord: function(component, event, helper) { 
        var selectedRecordTypeId = component.get("v.selectedRecordTypeId");
        if(selectedRecordTypeId){
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": component.get("v.objName"),
				"navigationLocation":"LOOKUP",
                "recordTypeId": selectedRecordTypeId
            });
            createRecordEvent.fire();
			component.find("overlayLib").notifyClose();
        }
    },

	handleCreateRecord2: function(component, event, helper) { 
        var selectedRecordTypeId = component.get("v.selectedRecordTypeId");
		let currentUrl = decodeURIComponent(window.location.search.substring(1));

        if(selectedRecordTypeId){
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": component.get("v.objName"),
				"recordTypeId": selectedRecordTypeId,
				"panelOnDestroyCallback":function(event) {
					var navEvt = $A.get("e.force:navigateToSObject");
					navEvt.setParams({
						"recordId": component.get("v.recordId"),
						"isredirect":true
					});
					// navigate back to account only if opportunity create was cancelled
					decodeURIComponent(window.location.search.substring(1)) == currentUrl ? navEvt.fire() : console.log('nav to opportunity');
				}
            });
            createRecordEvent.fire();
			component.find("overlayLib").notifyClose();
        }
    },

	handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        var appEvent = $A.get("e.c:DeleteConfirmationEvent");
        appEvent.setParams({
            "message" : "Cancel" });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
    },
    handleOK : function(component, event, helper) {
        //do something
        var appEvent = $A.get("e.c:DeleteConfirmationEvent");
        var rowId = component.get("v.selectedRecordTypeId");
        appEvent.setParams({
            "message" : "Ok",
            "rowId" : rowId
        });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
    }
})