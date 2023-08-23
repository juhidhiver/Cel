({
    init : function(component, event, helper) {
        component.set('v.mycolumns', [
            { label: 'Master Binder Name', fieldName: 'Name', type: "text" },
            { label: "Inception Date", fieldName: 'Inception_Date__c', type: "text" },
            { label: "Expiration Date", fieldName: 'Expiry_Date__c', type: "text" }
        ]);
        helper.doInit(component);
    },
 
    closeModel: function(component, event, helper) {
        component.set("v.isShowSpinner",true);
        component.set("v.isShowBindersPopup",false);
        helper.deleteClonedOpp(component);
    },    

    handleConfirm: function(component, event, helper) {
        var isProceed = false;
        var error;
        if(component.get("v.selectedBinderPrimary") == true && component.get("v.selectedBinderExcess") == true){
            if(component.get("v.rowSelectPrimary") != undefined && component.get("v.rowSelectExcess") != undefined){
              isProceed = true;
            }else {
                if(component.get("v.rowSelectPrimary") == undefined && component.get("v.rowSelectExcess") == undefined){
                    error = 'Please select Binders';
                }else if(component.get("v.rowSelectPrimary") == undefined && component.get("v.rowSelectExcess") != undefined){
                    error = 'Please select Primary Binder';
                }else if(component.get("v.rowSelectPrimary") != undefined && component.get("v.rowSelectExcess") == undefined){
                    error = 'Please select Excess Binder';
                }
            }
        }else if(component.get("v.selectedBinderPrimary") == true && component.get("v.selectedBinderExcess") != true){
            if(component.get("v.rowSelectPrimary") != undefined){
              isProceed = true;
            }else{
                error = 'Please select Primary Binder';
            }
            
        }else if(component.get("v.selectedBinderExcess") == true && component.get("v.selectedBinderPrimary") != true){
            if(component.get("v.rowSelectExcess") != undefined){ 
              isProceed = true;
            }else{
                 error = 'Please select Excess Binder';
            }
        }
        
        if(isProceed){
            console.log('move to helper');
            helper.handleRenewal(component);  
        }else{
            $A.get("e.force:showToast").setParams({
                "type": "error",
                "title":"Error",
                "message":error
            }).fire();
        }
 
    }, 

    
    chooseBinderPrimary: function (component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.rowSelectPrimary',selectedRows[0].Id);
        console.log('rowSelectPrimary -->'+selectedRows[0].Id); 
    },
    chooseBinderExcess: function (component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.rowSelectExcess',selectedRows[0].Id);
        console.log('rowSelectExcess -->'+selectedRows[0].Id); 
    },
})