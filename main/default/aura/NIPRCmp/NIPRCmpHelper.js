({
	doInit : function(component) {
		// Create the action
		var action = component.get("c.niprAPI");
		action.setParams({ fein : component.get("v.fein") });
		action.setCallback(this, function(response) {
			var state = response.getState();
			var errMsg = '';
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
                component.set("v.data1", result);
				console.log('result:' + result);
			} else {
				errMsg = action.getError()[0].message;
				console.log("Failed with state: " + state +  ", error message: " + errMsg);
			}
            component.set("v.showSpinner", false);

			// Show toast
			$A.get("e.force:showToast").setParams({
				"type": (errMsg == '') ? "success" : "error",
	            "title": (errMsg == '') ? "Success" : "Error",
	            "message": (errMsg == '') ? "NIPR sucessfully!" : errMsg
	        }).fire();
	    });
		$A.enqueueAction(action);
	}
})