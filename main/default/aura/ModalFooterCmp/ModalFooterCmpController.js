({
	handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        var appEvent = $A.get("e.c:ConfirmationEvent");
        appEvent.setParams({
            "message" : "Cancel" });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
    },
    handleOK : function(component, event, helper) {
        //do something
        var appEvent = $A.get("e.c:ConfirmationEvent");
        var obj = component.get("v.obj");
        appEvent.setParams({
            "message" : "Ok",
            "obj" : obj
        });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
    }
})