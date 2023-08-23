({
	closeQA : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
        console.log('Hello from Aura');
	}
})