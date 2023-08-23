({
	doInit : function(component, event, helper) {
		var actionInit = component.get("c.checkSanctionStatus");              
        actionInit.setParams({
            recordId: component.get('v.recordId')
        });
        actionInit.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var ContReturnVal = response.getReturnValue();
                if(ContReturnVal){
                    if(ContReturnVal.hasSanctionFail){
                        //alert('true');
                        //alert(ContReturnVal.names);
                        component.set('v.name', ContReturnVal.names);
                        component.set('v.isSanctionFail', true);
                    }else{
                        //alert('false');
                        component.set('v.isSanctionFail', false);
                    }
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                component.set('v.isSanctionFail', false);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            
        });
		$A.enqueueAction(actionInit);
    }
})