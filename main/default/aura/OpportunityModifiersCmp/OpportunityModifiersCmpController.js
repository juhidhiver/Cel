({
    doInit : function(component, event, helper) {
    	var recordId = component.get("v.recordId");
    	console.log('init produc--');
        var action = component.get("c.getProductNameTabs");
        action.setParams({
            opportunityId : recordId
        });
		action.setCallback(this, function(response){
            let state = response.getState(); 
            if(state === "SUCCESS"){
                console.log(response.getReturnValue());
                if(response.getReturnValue()) {
                    component.set('v.prodNameList', response.getReturnValue());
                }
            } else if(state = "ERROR"){
                var errorMsg = response.getError()[0].message;
                let toastParams = {
                    title: "Error",
                    message: errorMsg, // Default error message
                    type: "error"
                };
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams(toastParams);
                toastEvent.fire();
            }
        });
    	$A.enqueueAction(action);
    }
})