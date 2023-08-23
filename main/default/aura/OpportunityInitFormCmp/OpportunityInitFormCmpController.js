({
    doInit : function(component, event, helper){  
        
        helper.setPagref(component, event);
        
        var action = component.get("c.getOpportunityRecordType");
        action.setCallback(this, function(response){            
            if(response.getState() === "SUCCESS"){
                var returning = [];
                var recordTypes = response.getReturnValue();
                console.log('recordTypes -> ' + JSON.stringify(recordTypes));
                for(var i in recordTypes){
                   returning.push({value:recordTypes[i].Id, label:recordTypes[i].Name});
                }
      
                component.set("v.recordTypeList",returning);
                component.set("v.recordTypeId",recordTypes[0].Id);//set default option
                
            }
        });
        $A.enqueueAction(action);       
    },

    closePopup : function(component, event, helper){
        helper.redirect(component, event);
		//component.set("v.showPopup",false);
    },

	toastInfo: function(component, event, helper) {
     	var str = event.getParams().message;
		//var mySubString = str.substring(str.indexOf('"') + 1, str.lastIndexOf('"'));
		var mySubString = str.substring(str.lastIndexOf('Account "') + 9,  str.lastIndexOf('" was created.'));
		console.log('Toast detected:='+mySubString);
		if (mySubString !== null && mySubString !== '')
		{		
			var action = component.get("c.getAccountIdFromToast");
			action.setParams({
				accName : mySubString 
			});
			action.setCallback(this, function(response){            
				if(response.getState() === "SUCCESS"){
					var accId = response.getReturnValue();
					component.set("v.accRecordId",accId);
				}
			});
			$A.enqueueAction(action);  
		} 
    },
	nextButtonClick : function(component, event, helper){
		var acc = component.find('AccountId').get('v.value');
		var pro = component.find('ProductName').get('v.value');
		console.log('acc:=' + acc);
		console.log('pro:=' + pro);
        if (helper.checkEmptyString(acc) || helper.checkEmptyString(pro)) {
			var msg = "Account and Product are mandatory fields";
			console.log('msg:=' + msg);
			component.set("v.errorMessage",msg);
			//helper.handleShowModal(component,msg);
        } else helper.openNewOpportunity(component, event, helper);
    },
	
   
})