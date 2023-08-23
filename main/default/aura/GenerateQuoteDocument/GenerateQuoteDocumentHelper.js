({
	doInit : function(component) {

		console.log('@@@ ------------- GenrateDoc.getDocTypeId -------------');
		// Create the action
		component.set("v.isLoading", true);

		var action = component.get("c.generateDocId");
		action.setParams({ 
			quoteId : component.get("v.recordId")
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
				component.set("v.isLoading", false);
				$A.get("e.force:closeQuickAction").fire();
				$A.get("e.force:showToast").setParams({
					"type": (!result.errMsg) ? "success" : "error",
		            "title": (!result.errMsg) ? "Success" : "Error",
		            "message": (!result.errMsg) ? "Document has been generated sucessfully!" : result.errMsg
		        }).fire();
		        $A.get('e.force:refreshView').fire();
			}
	    });
		$A.enqueueAction(action);

	},
})