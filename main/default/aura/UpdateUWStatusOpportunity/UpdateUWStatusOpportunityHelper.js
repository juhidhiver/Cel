({
	
  
    getUWStatusPicklist: function(component, event) {
        console.log('Helper');
        var action = component.get("c.getUWStatus");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var industryMap = [];
               
                for(var key in result){
                    industryMap.push({key: key, value: result[key]});
                }
                component.set("v.industryMap", industryMap);
               this.getSelectedPicklistvalue(component, event);
            }
        });
        $A.enqueueAction(action);
    },
    
    getSubmissionStatusPicklist: function(component, event) {
        console.log('Helper');
        var action = component.get("c.getSubmisisonStatus");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var submisisonPicklist = [];
               
                for(var key in result){
                    submisisonPicklist.push({key: key, value: result[key]});
                }
                component.set("v.submisisonPicklist", submisisonPicklist);
                this.getSubmissionStatusvalue(component, event);
            }
        });
        $A.enqueueAction(action);
    },
    
     getSelectedPicklistvalue: function(component, event) {
      
        var action = component.get("c.selectedValueUwStatus");
          action.setParams({
            recordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log(' response.getReturnValue()', response.getReturnValue());
                if( response.getReturnValue() =='Bound' || response.getReturnValue() =='Declined'){
                     var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "You can not change the UW Status.",
                    "type": "Error"
                    
                });
                toastEvent.fire();
                  //  component.set("v.SelectedPickListValue", response.getReturnValue());
                }
                else if(response.getReturnValue() =='OppNotCreated'){
                            var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Need Submission to change UW Status.",
                    "type": "Error"
                    
                });
                toastEvent.fire();   
                }
                else{
                       component.set("v.spinner", false);
                       component.set("v.SelectedPickListValue", response.getReturnValue());
                  
                }
            }
           /* else{
                component.set("v.spinner", false);
                component.set("v.SelectedPickListValue", "--None--");   
            }*/
        });
        $A.enqueueAction(action);
    },
    
     getSubmissionStatusvalue: function(component, event) {
      
        var action = component.get("c.selectedValueSubmissionStatus");
          action.setParams({
            recordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log(' response.getReturnValue()', response.getReturnValue());
                
                if(response.getReturnValue() =='OppNotCreated'){
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "Need Submission to change Submission Status.",
                        "type": "Error"
                        
                    });
                    toastEvent.fire();   
                }
                else if(response.getReturnValue() =='Bound' || response.getReturnValue() =='Bound - In Waiting' || response.getReturnValue() =='Quoted' || response.getReturnValue() == 'Invalid StageName'){
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "You can not change the Submission Status.",
                        "type": "Error"
                        
                    });
                toastEvent.fire();
                }
                else{
                    if(response.getReturnValue() != 'Quoted' || response.getReturnValue() != 'Information Requested' || response.getReturnValue() != 'VRI' || response.getReturnValue() != 'Hold Cover'){
                        result = 'Hold Cover';
                    }
                    component.set("v.spinner", false);
                    component.set("v.SelectedSubmissionStatus", result);
                }
            }
        });
        $A.enqueueAction(action);
    }
    
    
})