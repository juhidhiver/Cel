({
	doInit: function(component, event, helper) {    
		console.log('##ConfirmationCmp Init'); 
		if(component.get('v.FormType')=='Validation')   
			component.find('btnDefault').set('v.label','Close' );
    },
	handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        var appEvent = $A.get("e.c:DeleteConfirmationEvent");
        appEvent.setParams({
            "message" : "Cancel" });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
    },
    handleOK : function(component, event, helper) {
        //do something
        var appEvent = $A.get("e.c:DeleteConfirmationEvent");
        var rowId = component.get("v.rowId");
		var smg = component.get("v.message");
        appEvent.setParams({
			"rowId" : rowId,
            "message" : "Ok"
        });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
    }
})