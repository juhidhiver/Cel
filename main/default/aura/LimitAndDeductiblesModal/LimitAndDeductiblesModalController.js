({
    doInit : function(component, event, helper) {
        //helper.showModal(component);
    },
	openLimitAndDeductiblesModal : function(component, event, helper) {
		var params = event.getParam('arguments');
        if (params) {
	  		//helper.initData(component, params);
        }
	},
	
	hideCurrentModal : function(component, event, helper) {
		helper.hideModal(component);
	},
    save : function(component, event, helper) {
        component.destroy();
    },
    cancel : function(component, event, helper) {
		// when a component is dynamically created in lightning, we use destroy() method to destroy it.
		component.destroy();
	},
})