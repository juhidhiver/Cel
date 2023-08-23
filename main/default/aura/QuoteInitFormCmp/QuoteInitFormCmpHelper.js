({
	doInit : function(component) {
		// Create the action
		var action = component.get("c.initialize");
        action.setParams({
            id : component.get('v.recordId')           
        });
		// Add callback behavior for when response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			var msg = '';

			if (state === "SUCCESS") {
                var result = response.getReturnValue();
                // custom errors
				if (!result.isSuccess) {
                    msg = result.errors[0];
                    this.showErrorMsg('Error', msg);

                    // Close the action panel
	                $A.get("e.force:closeQuickAction").fire();
				} else {
                    component.set('v.showSpinner', false);
                }

            // system errors
			} else {
				msg = action.getError()[0].message;
                this.showErrorMsg('Error', msg);

                // Close the action panel
	            $A.get("e.force:closeQuickAction").fire();
			}
	    });
		$A.enqueueAction(action);
    },
    
    handleLoad : function(component){
        var action = component.get("c.getOpportunityInfo");
        action.setParams({
            id : component.get('v.recordId')           
        });

        action.setCallback(this, function(response){            
            if(response.getState() === "SUCCESS"){              
                var returnValue = response.getReturnValue();
                console.log(returnValue);
                if (returnValue !=null) {

                    var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
                    var closeDatePlus30days = this.addDate(today, 30); 
					console.log(closeDatePlus30days);
                    console.log(returnValue.CloseDate__c);
                    component.find('opptId').set('v.value', returnValue.Id);
                    component.find('qName').set('v.value', returnValue.Name);                  
                    component.find('qAccount').set('v.value', returnValue.AccountId);
                    component.find('qProduct').set('v.value', returnValue.Product_Name__c);
                    
                    component.find('qEffDate').set('v.value', returnValue.Effective_Date__c);
                    component.find('qExpDate').set('v.value', returnValue.Expiration_Date__c);
                    component.find('qCloseDate').set('v.value', closeDatePlus30days); 
                    component.find('qStatus').set('v.value', 'In Progress');
                    
                    if(returnValue.StageName =='Closed Won'){// if submission is closed won
                        component.find('qType').set('v.value', 'Amendment');
                    }
                    if(returnValue.Policy__c){
                        component.find('qPolicy').set('v.value', returnValue.Policy__c);
                    }
                    
                    
                }                
            } else {
                msg = response.getError()[0].message;
                this.showErrorMsg('Error', msg);
            }
        });
        $A.enqueueAction(action);    
    },

	addDate : function(closeDate, days) {
		var newDate = new Date();
        newDate.setDate(newDate.getDate() + days);
        
        var result = $A.localizationService.formatDate(newDate, "YYYY-MM-DD");
        return result;
    },
    showErrorMsg : function(title, msg) {
		$A.get("e.force:showToast").setParams({
			"type": "error",
			"title": title,
			"message": msg 
		}).fire();
	},
  
})