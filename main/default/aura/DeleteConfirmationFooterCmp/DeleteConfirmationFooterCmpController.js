({
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
        appEvent.setParams({
            "message" : "Ok",
            "rowId" : rowId
        });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
    }
})