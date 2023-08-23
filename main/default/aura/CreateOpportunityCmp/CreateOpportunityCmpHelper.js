({
    getRecordTypes : function(component,event){
        var action = component.get("c.GetAvailableRecordType");
		action.setParams({
			"objName": "Opportunity"
		});
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var returning = [];
                var recordTypes = response.getReturnValue();
                console.log('recordTypes -> ' + JSON.stringify(recordTypes));
                for(var key in recordTypes){
                   returning.push({value:recordTypes[key], name:key});
                }
                console.log('returning -> ' + JSON.stringify(returning));

                component.set("v.availableRecordTypes",returning);
                component.set("v.retrievedTypes",true);
            }
            else{
                alert("Temporary Error: There is a problem getting the Record Types.");
            }
        });
        $A.enqueueAction(action); 
    }   
})