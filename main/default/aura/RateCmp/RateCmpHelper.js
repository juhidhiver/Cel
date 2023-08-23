({
	doInit : function(component) {
		// Create the action
		var action = component.get("c.getRatingFromCallOut");
		action.setParams({ objId : component.get("v.recordId") });
		action.setCallback(this, function(response) {
			var state = response.getState();
			var errMsg = '';
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
				console.log(result);
				if (!result.isSuccess) {
					//errMsg = 'not rated successfully';
					errMsg = result.errors[0];
				}else {
					//check rate result
					console.log('result:' + JSON.stringify(result.data));
					//var currentQuote = result.data;
					//if (currentQuote.Rating_Status__c == 'System Error') {
						//errMsg = 'Quote is not rated successfully';
						//errMsg = currentQuote.Declined_Reason__c;
					//} else {
						//component.set("v.data1", JSON.stringify(result.data));
						//console.log('result:' + result.data);
					//}					
				}
			} else {
				errMsg = action.getError()[0].message;
				console.log("Failed with state: " + state +  ", error message: " + errMsg);
			}
            component.set("v.showSpinner", false);
			console.log(errMsg);
			// Show toast
			$A.get("e.force:showToast").setParams({
				"type": (errMsg == '') ? "success" : "error",
	            "title": (errMsg == '') ? "Success" : "Error",
	            "message": (errMsg == '') ? "Rating sucessfully!" : errMsg
			}).fire();
			
			// Close the action panel and refresh view
			$A.get("e.force:closeQuickAction").fire();
			$A.get('e.force:refreshView').fire();
		});
		

		$A.enqueueAction(action);
	}
})