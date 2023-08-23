({
    doInit: function(component, event, helper) {
        helper.getData(component);
    },

    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
			case 'edit':
                helper.showRowEditDetails(row);
			    break;
			case 'delete':
                helper.handleDeleteAction(component,row);
		        break;
            default:
                helper.showRowDetails(row);
                break;
        }
    },
    
	handleDeleteEvent : function(component, event, helper) {
        var message = event.getParam("message");
        var rowId = event.getParam("rowId");

        if(message == 'Ok') {
        	// if the user clicked the OK button do your further Action here
        	helper.removeRow(component, rowId)
        } else if (message == 'Cancel') {
        	// if the user clicked the Cancel button do your further Action here for canceling
      		
        }
    },
    
    handleNewEvent : function(component, event, helper) {
        var message = event.getParam("message");
        var rowId = event.getParam("rowId");

        if(message == 'Success') {
        	// if the user clicked the OK button do your further Action here
        	helper.addRow(component, rowId)
        } else if (message == 'Cancel') {
        	// if the user clicked the Cancel button do your further Action here for canceling
      		
        }
    },
    
    newAction : function (component) {
 		var str = "{ \'"+ component.get("v.parentFieldName") + "\': \'" +component.get("v.recordId") +"\'}";
   		// JSON.parse doesn't work because single quote is not allowed
        var defValue = eval('('+str+')');

		var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.fire({
            "entityApiName": component.get("v.objectType"),
			"navigationLocation":"LOOKUP",
			"defaultFieldValues": defValue
        });
    },

    updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
	gotoRelatedList : function (component, event, helper) {
		var relatedListEvent = $A.get("e.force:navigateToRelatedList");
		relatedListEvent.setParams({
			//"relatedListId": component.get("v.relationshipName"),
			"relatedListId": "Opportunities",
			"parentRecordId": component.get("v.recordId")
		});
		relatedListEvent.fire();
	},
    
	handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        // Check event type to prevent event fire multiple times
        if (eventParams.changeType === "LOADED") {

            helper.handleDeleteRecord(component);
        } else if (eventParams.changeType === "REMOVED"){
        	helper.getData(component);
            
			var resultsToast = $A.get("e.force:showToast");
			resultsToast.setParams({
				"title": "Deleted",
                "type" : "Success",
				"message": "The record was deleted."
			});
			resultsToast.fire();
        } else if(eventParams.changeType === "ERROR") {

        }
		
    },
    
    handleNewRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();

        // Check event type to prevent event fire multiple times
        if (eventParams.changeType === "LOADED") {
        	helper.getData(component); 
            
			var resultsToast = $A.get("e.force:showToast");
			resultsToast.setParams({
				"title": "Added",
                "type" : "Success",
				"message": "The record was created."
			});
			resultsToast.fire();
        } else if (eventParams.changeType === "REMOVED"){
            
        } else if (eventParams.changeType === "CHANGED"){
           
        } else if(eventParams.changeType === "ERROR") {

        }
    },

    // update datatable
    handlePageChanged: function(component, event) {
        var message = event.getParam("message");
        var data = event.getParam("data");
        
        component.set("v.data", data);
    }
})