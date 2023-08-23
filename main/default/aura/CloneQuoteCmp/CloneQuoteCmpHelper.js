({
	doInit : function(component) {
		// Create the action
		var action = component.get("c.cloneQuoteWithChildren");
		action.setParams({ quoteId : component.get("v.recordId"),
							fieldUpdateMap : null
						});
        
		// Add callback behavior for when response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			var errMsg = '';

			if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                var result = response.getReturnValue();

				if(result){
                    var navEvt = $A.get("e.force:navigateToSObject");
				    navEvt.setParams({
				      "recordId": result.Id,
				      "slideDevName": "detail"
				    });
				    navEvt.fire();
                }
			} else {
				errMsg = action.getError()[0].message;
				console.log("Failed with state: " + state +  ", error message: " + errMsg);// Show toast
				$A.get("e.force:showToast").setParams({
					"type": "error",
	            	"title": "Error",
	            	"message": errMsg
	        	}).fire();
	
           }
	    });
        
		$A.enqueueAction(action);
	}
})