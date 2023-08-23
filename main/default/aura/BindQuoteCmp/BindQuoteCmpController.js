({
	init : function(component, event, helper) {
		helper.doInit(component);
	},

	handleConfirmClick : function(component, event, helper) {
		event.getSource().set("v.disabled", true);
		helper.confirmBindQuote(component);
	},

	handleCancelClick : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
})