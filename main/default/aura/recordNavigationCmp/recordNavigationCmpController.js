({
	doInit : function(component, event, helper) {
        var action = component.get("c.fetchDetails");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var returnedResponse = response.getReturnValue();
                console.log('$$$returnedResponse=', returnedResponse);
                if(returnedResponse.Status != 'Bound'){
                    helper.navigateToRecord(component,returnedResponse.OpportunityId);
                }
            }
        });
        $A.enqueueAction(action);
	}
})