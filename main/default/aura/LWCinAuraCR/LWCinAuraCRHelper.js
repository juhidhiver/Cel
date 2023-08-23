({
    doInit : function(component, event, helper) {
        helper.getMasterBinders(component, event, helper);
	},
    
    getMasterBinders : function(component, event, helper) {
    	var action = component.get("c.getMasterBinders"); 
        action.setParams({
            opportunityId : component.get("v.recordId")
        })
        action.setCallback(this, function(response){
            var state = response.getState(); 
            if(state == "SUCCESS"){    
                var result = response.getReturnValue();
                var selectBinder = result[0];
                //var myJSON = JSON.stringify(selectBinder);
                component.set("v.selectMasterBinder", selectBinder);
                component.set("v.showLWC",true);
            }
        });
        $A.enqueueAction(action);
	},
    
})