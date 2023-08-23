({
    doInit: function(component, event, helper)  {
        var processStep = component.get("v.processStep");
        var backTitle = "Back: " + processStep[0];
        var nextTitle = "Next: " + processStep[1];
        component.set("v.backTitle", backTitle);
        component.set("v.nextTitle", nextTitle);
    },

    // handleSelect : function(component, event, helper) {
    //     // var stepName = event.getParam("detail").value;
    //     // var toastEvent = $A.get("e.force:showToast");
    //     // toastEvent.setParams({
    //     //   "title": "Success!",
    //     //    "message": "Toast from " + stepName
    //     //    });
    //     // toastEvent.fire();
    //     var selectStatus = event.getParam("detail").value;
    //     //set selected Status value
    //     component.set("v.picklistField.Quote_Process__c", selectStatus);
         
    //     component.find("record").saveRecord($A.getCallback(function(response) {
    //         if (response.state === "SUCCESS") {
    //             $A.get('e.force:refreshView').fire();
    //             component.find('notifLib').showToast({
    //                 "variant": "success",
    //                 "message": "Record was updated sucessfully",
    //                 "mode" : "sticky"
    //             });
    //         } else {
    //             component.find('notifLib').showToast({
    //                 "variant": "error",
    //                 "message": "There was a problem updating the record.",
    //                 "mode" : "sticky"
    //             });
    //         }
    //     }));
    //     console.log(selectStatus);
    // },

    selectProcess: function (component, event, helper) {
        if(event.currentTarget.id !== undefined && parseInt(event.currentTarget.id) >= 0)  
            helper.changeStep(component, parseInt(event.currentTarget.id));
    },

    handleBack : function(component, event, helper) {
        var backStep = component.get("v.currentStep") - 1;
        if(backStep >= 0) 
            helper.changeStep(component, backStep);
    },

    handleNext : function(component, event, helper) {
        var nextStep = component.get("v.currentStep") + 1;
        if(nextStep < component.get("v.processStep.length")) 
            helper.changeStep(component, nextStep);
    }
    

})