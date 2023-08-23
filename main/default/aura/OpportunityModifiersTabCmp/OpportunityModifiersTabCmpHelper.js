({
    doInit : function(component, event) {
    	var oppId = component.get("v.opportunityId");
    	var prodName = component.get("v.productName");
        var action = component.get("c.getMainSectionFromProduct");
        action.setParams({
        	productName : prodName,
            opportunityId : oppId
        });
		action.setCallback(this, function(response){
            let state = response.getState(); 
            if(state === "SUCCESS"){
                console.log("@@@Main Section" + JSON.stringify(response.getReturnValue()));
                var result = response.getReturnValue();
				console.log(result);
                if (result == null) {
                	this.showToast("Error", 'No Eligibility item to show', "error");
                    component.set('v.errorMessage', 'No Eligibility item to show');
                    return;
                }
                if (!result.isSuccess) {
                	this.showToast("Error", result.errors[0], "error");
                    return;
                }
                var data = result.data;
                
                component.set("v.mainSectionWraps", data.mainSections);
                component.set("v.mainActiveSections", data.activeSections);
            } else if(state = "ERROR"){
                var errorMsg = response.getError()[0].message;
                this.showToast("Error", errorMsg, "error");
            }
        });
    	$A.enqueueAction(action);
    },
    clickCheckRiskHealth : function(component, event) {
        var oppId = component.get("v.opportunityId");
        var prodName = component.get("v.productName");
        var modalBody;
        var modalFooter;
        console.log(component);
        $A.createComponents( 
            [
            ["c:CheckRiskHealthCmp", 
            {
                "oppId" : oppId,
                "prodName" : prodName
            }],
            ["c:CheckRiskHealthFooterCmp", {
                "oppId": oppId
            }]
            ]
            ,
            function(components, status) {
                if (status === "SUCCESS") {
                    // modalBody = content;
                    modalBody = components[0];
                    modalFooter = components[1];
                    console.log(modalBody, modalFooter);
                    component.find('overlayLib').showCustomModal({
                        header: "Risk Health",
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: "slds-modal_medium",
                        footer: modalFooter,
                        closeCallback: function(){
                            // alert('You closed the alert!');
                        }
                    })
                    
                }else if (status === "INCOMPLETE") {
                    console.log('Server issue or client is offline.');
                }else if (status === "ERROR") {
                    console.log('error');
                }

            });
    },
    saveRecord : function(component, event) {
        this.showSpinner(component);
        var jsonData = JSON.stringify(component.get("v.mainSectionWraps"));
        var actionSave = component.get('c.saveRecordTabLwc');
            actionSave.setParams({
                jsonTabWrap : jsonData,
                opportunityId : component.get('v.opportunityId')
            });
            actionSave.setCallback(this, function(response){
                let state = response.getState(); 
                let errorMsg = '';

                if(state === "SUCCESS"){
                    var appEvent = $A.get("e.c:reload_app_evt");
                    appEvent.fire();
                } 
                else if(state = "ERROR")  errorMsg = response.getError()[0].message;
                
                if(errorMsg) this.showToast("Error", errorMsg, "error");
                else {
                    this.showToast("Success", "Update Records Success!", "success");
                }

                this.hideSpinner(component);
            });
            $A.enqueueAction(actionSave); 
    },

    showToast: function(title, message, type) {
        let toastParams = {
            title: title,
            message: message,
            type: type
        };
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },
    showSpinner: function(component) {
        component.set('v.showSpinner', true);
    },
    hideSpinner:  function(component) {
        component.set('v.showSpinner', false);
    }
})