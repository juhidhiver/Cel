({
	closeModal : function(component, event, helper) {
        component.set("v.loading", false);
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    }
})