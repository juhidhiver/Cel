({
	doInit : function(component) {
		console.log('@@@ ------------- BindQuoteCmpHelper.doInit -------------');
		// Create the action
		var action = component.get("c.getInitData");
		action.setParams({ quoteId : component.get("v.recordId") });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
				console.log('@@@ result= ' + JSON.stringify(result));
				component.set('v.payPlans', result.payplanPicklist);
				component.set('v.payPlan', result.currentPayplan);
				component.set('v.brokerName', result.brokerName);
                //US-35795
				component.set('v.showBindOptions',result.showBindOptions);
                console.log('result.showBindOptions::'+result.showBindOptions)
				component.set('v.bindValue', result.showBindOptions ? 'Bound Pending' : 'Bind');
				component.set('v.isBoundPendingOption', component.get("v.bindValue") == 'Bound Pending' ? true : false);

			} else {
				$A.get("e.force:showToast").setParams({
					"type": "error",
		            "title": "Error",
		            "message": action.getError()[0].message
		        }).fire();
			}
	    });
		$A.enqueueAction(action);
	},

	confirmBindQuote : function(component) {
		var action = component.get("c.bindQuote");
		action.setParams({ 
			quoteId : component.get("v.recordId"),
			payPlan : component.find('PayPlan').get('v.value'),
            isBoundPending : component.get("v.bindValue") == 'Bound Pending' ? true : false
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
					this.showSuccessMsg('Success!', 'Bind Quote Successful');
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