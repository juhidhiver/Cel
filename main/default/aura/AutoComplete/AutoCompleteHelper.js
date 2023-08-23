({
    searchRecords : function(component, searchString) {
        var action = component.get("c.getRecords");
        action.setParams({
            "searchString" : searchString,
            "countryCode" : component.get("v.countryCodeFromParent"),
        });
        action.setCallback(this,function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                component.set("v.loaded",true);
                // End
                const serverResult = response.getReturnValue();
                console.log('serverResult:' + serverResult);
                const results = [];
                serverResult.forEach(element => {
                    results.push(element);
                });
            	console.log('results:' + results);
                component.set("v.results", results);
                if(serverResult.length>0){
                    component.set("v.openDropDown", true);
                }
            } else{
                component.set("v.loaded",true);
                var toastEvent = $A.get("e.force:showToast");
                if(toastEvent){
                    toastEvent.setParams({
                        "title": "ERROR",
                        "type": "error",
                        "message": "Something went wrong!! Check server logs!!"
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    },
    getCorporateIntel : function(component, dunsNumber, accountName) {
        var action = component.get("c.getCorporateIntel");
        var address = component.get("v.address");
        console.log('helper address:' + address);
        action.setParams({
            "dunsNumber" : dunsNumber
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                const serverResult = response.getReturnValue();
                console.log('@serverResult' + serverResult);
               	var compEvent = component.getEvent("oSelectedRecordEventParent");
                compEvent.setParams({"recordByEvent" : serverResult,accountName : accountName});
                component.set("v.loaded",true);
                // End
                compEvent.fire();
            } else{
                var toastEvent = $A.get("e.force:showToast");
                if(toastEvent){
                    toastEvent.setParams({
                        "title": "ERROR",
                        "type": "error",
                        "message": "Something went wrong!! Check server logs!!"
                    });
                    component.set("v.loaded",true);
                    //End
                }
            }
        });

        $A.enqueueAction(action);
    }
})