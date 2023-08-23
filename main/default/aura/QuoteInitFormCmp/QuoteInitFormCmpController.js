({
    
    doInit : function(component, event, helper) {
        helper.doInit(component);
    },
    handleLoad : function(component, event, helper){
        helper.handleLoad(component);  
    },
    handleSubmit : function(component, event, helper){
        console.log('-handleSubmit-');
        component.set("v.isProcessing",true);
    },
    handleError : function(component, event, helper){
        console.log('-Error-');
        component.set("v.isProcessing",false);
    },
    navigate: function(component, event, helper) {        
    },
    handleSuccess : function(component, event, helper){
        var payload = event.getParams().response;		        
        console.log('-handleSuccess-');
        component.set("v.isProcessing",false);
        // Close modal
        $A.get("e.force:closeQuickAction").fire();
        
        // Show toast
        $A.get("e.force:showToast").setParams({
            "type":  "success",
            "title": "Success",
            "message": "New Quote is created in success!"
        }).fire();
        // Refresh view
        $A.get('e.force:refreshView').fire();
        
        // redirect to new quote created                                               
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": payload.id
        });
        navEvt.fire();        
    },
    cancelAction: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})