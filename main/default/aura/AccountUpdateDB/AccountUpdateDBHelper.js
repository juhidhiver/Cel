({
    doInit : function(component) {
    // Create the action
		var action = component.get("c.updateDBInfo");
		// Add callback behavior for when response is received
		action.setParams({ 
            recordId : component.get("v.recordId")
        });
		
		action.setCallback(this, function(response) {
			var state = response.getState();
			var errMsg = '';
            if (state === "SUCCESS") {
				var result = response.getReturnValue();
				console.log(result);
				if (!result.isSuccess) {
					this.showErrorMsg('Error', result.errors[0]);
				} else {
					this.showSuccessMsg('Success!', 'Update D&B Info successfully!');
				}

			} else {
				errMsg = action.getError()[0].message;
				this.showErrorMsg('Error!', errMsg);
			}

			// Close modal
			$A.get("e.force:closeQuickAction").fire();

	        // Refresh view
	        $A.get('e.force:refreshView').fire();
	    });
		
		$A.enqueueAction(action);
    },
    
    showErrorMsg : function(title, msg) {
		$A.get("e.force:showToast").setParams({
			"type": "error",
			"title": title,
			"message": msg 
		}).fire();
	},

	showSuccessMsg : function(title, msg) {
		$A.get("e.force:showToast").setParams({
			"type": "success",
			"title": title,
			"message": msg 
		}).fire();
	}
})