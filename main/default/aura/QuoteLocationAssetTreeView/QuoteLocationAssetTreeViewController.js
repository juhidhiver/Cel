({
	doInit : function(component, event, helper) {
        helper.initial(component, event);
	},

    handleSelect : function(component, event, helper) {
		var rowId = event.getSource().get('v.name');
		console.log('@@@ >> rowId (quoteLocationId)= ' + rowId);

    	switch (event.detail.menuItem.get("v.value")) {
	      	case "Delete_Location":
                component.set("v.isOpenConfirmDelele", true);
                // Set record Id to delete to force:recordData then reload this
                component.set("v.deleteRecord", rowId);
				component.find("recordHandler").reloadRecord();
	      		break;

	      	case "Edit_Location":
				component.set("v.quoteLocationId", rowId);
				component.find("editQuoteLocation").reloadRecord();
				// Call standard edit event
			    $A.get("e.force:editRecord").setParams({
			        "recordId": rowId
			   	}).fire();
	      		break;
	    }
	},
 
	cancelDelete: function(component, event, helper) {
        component.set("v.isOpenConfirmDelele", false);
    },

    confirmDelete: function(component, event, helper) {
        var recordIdTodelete = component.get("v.deleteRecord");
        helper.deleteRecord(component, event, recordIdTodelete);
    },

   	addNewLocation: function(component, event, helper) {
   		// Open popup add new location
        component.set("v.isAddLocation", true);
    },

    handleAddLocationEvent: function(component, event, helper) {
    	// Close popup add new location
        var isOpenAddLocationForm = event.getParam("isOpenAddLocationForm");
        component.set("v.isAddLocation", isOpenAddLocationForm);
        helper.initial(component, event);
        $A.get('e.force:refreshView').fire();
    },

    handleAfterEditQuoteLocation: function(component, event, helper) {
    	console.log('@@@ >> QuoteLocationAssetTreeViewController.handleAfterEditOpptyLocation');
        var eventParams = event.getParams();
        console.log('@@@ eventParams.changeType= ' + eventParams.changeType);
        if(eventParams.changeType === "LOADED") {
            // hanlde loaded event

        } else if(eventParams.changeType === "CHANGED") {
            // hanlde change event
            helper.initial(component, event);

        } else if(eventParams.changeType === "REMOVED") {
            // hanlde delete event

        } else if(eventParams.changeType === "ERROR") {
            // hanlde error
        }
    },
})