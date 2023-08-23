({
    changeStep : function(component, selectedStep) {
        var currentStep = component.get("v.currentStep");
        if(selectedStep > currentStep) {
            console.log("selectedStep > currentStep")
            for(var i = currentStep; i < selectedStep; i++) {
                var selectedProcess = document.getElementById(i).parentElement;
                $A.util.removeClass(selectedProcess, "slds-is-active");
                $A.util.removeClass(selectedProcess, "slds-is-incomplete");
                $A.util.removeClass(selectedProcess, "slds-is-current");
                $A.util.addClass(selectedProcess, "slds-is-complete");
            } 
        } else if(selectedStep < currentStep) {
            console.log("selectedStep < currentStep")
            for(var i = currentStep; i > selectedStep; i--) {
                var selectedProcess = document.getElementById(i).parentElement;
                $A.util.removeClass(selectedProcess, "slds-is-active");
                $A.util.removeClass(selectedProcess, "slds-is-complete");
                $A.util.removeClass(selectedProcess, "slds-is-current");
                $A.util.addClass(selectedProcess, "slds-is-incomplete");
           } 
        }
        var selectedProcess = document.getElementById(selectedStep).parentElement;
        $A.util.removeClass(selectedProcess, "slds-is-incomplete");
        $A.util.removeClass(selectedProcess, "slds-is-complete");
        $A.util.addClass(selectedProcess, "slds-is-current");
        $A.util.addClass(selectedProcess, "slds-is-active");
 
        currentStep = selectedStep;
        component.set("v.currentStep", selectedStep);
        
        var processStep = component.get("v.processStep");
        if(currentStep > 0) {
            var backTitle = "Back: " + processStep[currentStep - 1];
            component.set("v.backTitle", backTitle);
        }
        if(currentStep < component.get("v.processStep.length") - 1) {
            var nextTitle = "Next: " + processStep[currentStep + 1];
            component.set("v.nextTitle", nextTitle);
        }

        // var lwcName = "c:";
        // var divCmp = component.find("MainBody");
        // if(currentStep % 2 == 0)
        //     lwcName += "sampleLWC1";
        // else 
        //     lwcName += "sampleLWC2";    
        // $A.createComponent(lwcName, {},
        //         function(newLWC){
        //             console.log(lwcName);
        //             divCmp.set("v.body", newLWC);
        // });
        
    }
})