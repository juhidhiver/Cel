({	
	initial : function(component, event) {
		// Set header
        var headers = ['Quote Location Id', 'Primary Location?', 'Usage Type', 'Location Id', 'Address', 'City', 'State/Province', 'Postal Code', 'Country'];
		component.set('v.columnHeaders', headers);

		// Call apex to get init data object
		var action = component.get("c.initData");
		action.setParams({
			"quoteId" : component.get("v.recordId")
		});
		action.setCallback(this, function(response){
			var state = response.getState();
            if(state === "SUCCESS"){
            	var initObject = response.getReturnValue();
            	//console.log('@@@ QuoteLocationAssetTreeViewHelper.initial.initObject= ' + JSON.stringify(initObject));
            	component.set("v.iconName", initObject.iconName);
            	component.set("v.listLocationAsset", initObject.listLocationAsset);
            	component.set("v.listSize", initObject.listLocationAsset.length);
            	component.set("v.accountId", initObject.accountId);
        		component.set("v.productId", initObject.productId);
        		component.set("v.opportunityId", initObject.opportunityId);
        		component.set("v.assetRecordTypeId", initObject.recordTypeId);

            } else {
            	$A.get("e.force:showToast").setParams({
            		"type": "error",
                    "title": "Error!",
                    "message": action.getError()[0].message
                }).fire();
            }
        });
        $A.enqueueAction(action);
	},

	deleteRecord: function(component, event, recordId){
        component.find("recordHandler").deleteRecord($A.getCallback(function(deleteResult) {
            // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
            // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
            if (deleteResult.state === "SUCCESS" || deleteResult.state === "DRAFT") {
                // record is deleted
                console.log("Record is deleted.");
                component.find("recordHandler").reloadRecord();
                $A.get('e.force:refreshView').fire();
            
            } else if (deleteResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            
            } else if (deleteResult.state === "ERROR") {
                console.log('Problem deleting record, error: ' + JSON.stringify(deleteResult.error));
            	var errors = deleteResult.error;
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        $A.get("e.force:showToast").setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": errors[0].message
                        }).fire();
                    }
                } 
            } else {
                console.log('Unknown problem, state: ' + deleteResult.state + ', error: ' + JSON.stringify(deleteResult.error));
            }
        }));
        this.initial(component,event);
        component.set("v.isOpenConfirmDelele", false);
    },
})