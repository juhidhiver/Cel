({
	  doInit : function(component, event, helper){
       var recordId = component.get("v.recordId");
       component.set("v.spinner", true);
      console.log(component.get("v.recordId"));
             
       var action = component.get("c.getObjectType"); 
        action.setParams({
            recordId : recordId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
					var result = response.getReturnValue();
                if(result == 'Celerity'){
                   	helper.getUWStatusPicklist(component, event);
                  component.set("v.title",'UW Status');
                  component.set("v.isCelerity",true);  
                } 
                else if(result == 'Aqueous') {
                 helper.getSubmissionStatusPicklist(component, event);
                component.set("v.title",'Submission Status');
                }
                console.log('celerity: '+component.get("v.isCelerity"));
            }
            else {
                console.log("error" + JSON.stringify(response.getError()));
            }
            
        });
        $A.enqueueAction(action);
             
                    
    },
    
    
    closePopup : function(component, event, helper){
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
    
    doSaveSubmission: function(component, event, helper) {
         var recordId = component.get("v.recordId"); 
         var submissionStatus = component.find("submissionstatus").get("v.value");			
        
        console.log("recordId:" + recordId);
        console.log("status:" + submissionStatus);
      	     
        var action = component.get("c.UpdateSubmissisonStatus"); 
        action.setParams({
            recordId : recordId, 
            subStatus : submissionStatus
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The Submisison Status has been Updated successfully.",
                    "type": "success"
                    
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else {
                console.log("Error during calling server action:" + response.getError());
            }
            
        });
        $A.enqueueAction(action);
       
    },
    
    doSave : function(component, event, helper) {
        var recordId = component.get("v.recordId"); 
         var UWStatus = component.get("v.SelectedPickListValue"); 
      
        console.log("recordId:" + recordId);
        console.log("declineReason:" + UWStatus);
      	     
        var action = component.get("c.UpdateStatus"); 
        action.setParams({
            recordId : recordId, 
            UwStatus : UWStatus
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                // Close the action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The UW Status has been Updated successfully.",
                    "type": "success"
                    
                });
                toastEvent.fire();
                
                // Refresh view
                $A.get('e.force:refreshView').fire();
            }
            else {
                console.log("Error during calling server action:" + response.getError());
            }
            
        });
        $A.enqueueAction(action);
       
    }
})