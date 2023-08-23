({
	doInit : function(component) {
		// Create the action
		var action = component.get("c.renewalController");
		// Add callback behavior for when response is received
		action.setParams({ policyId : component.get("v.recordId") });
		
		action.setCallback(this, function(response) {
			var state = response.getState();
			var errMsg = '';
			if (state === "SUCCESS") {
				var resResult =  response.getReturnValue();
				if(resResult) {
					if(!resResult.isSuccess && resResult.msgError) {
						errMsg = resResult.msgError;
					}
					else if(resResult.isSuccess) {
						var navEvent = $A.get("e.force:navigateToSObject");
                        navEvent.setParams({
                        recordId: resResult.opptClonedId,
                        slideDevName: "detail"
         });
         navEvent.fire(); 
					}
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
	            "message": (errMsg == '') ? "Renewal Opportunity is created successfully!" : errMsg
	        }).fire();
	    });
		
		$A.enqueueAction(action);
	}
})