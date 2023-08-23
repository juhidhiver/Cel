({
	doInit : function(component) {
		// Create the action
		var action = component.get("c.finalizeQuote");
		action.setParams({ quoteId : component.get("v.recordId") });
		// Add callback behavior for when response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			var errMsg = '';
			var fileName = '';
			var proposalBodyEncoded = '';
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
				console.log('@@@ finalize result= ' + JSON.stringify(result));
				if (!result.isSuccess) {
					errMsg = result.errors[0];
				}

			} else {
				errMsg = action.getError()[0].message;
				console.log("Failed with state: " + state +  ", error message: " + errMsg);
			}

	        // Close the action panel and refresh view
	        $A.get("e.force:closeQuickAction").fire();
	        $A.get('e.force:refreshView').fire();

	        // Show toast
			$A.get("e.force:showToast").setParams({
				"type": (errMsg == '') ? "success" : "error",
	            "title": (errMsg == '') ? "Success" : "Error",
	            "message": (errMsg == '') ? "Finalize quote sucessfully!" : errMsg
	        }).fire();
	    });
		$A.enqueueAction(action);
	}
})