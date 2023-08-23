({
    init: function (component, event, helper) {
        helper.getcolumns(component);
        helper.fetchData(component);
    },
	reloadData: function (component, event, helper) {
        helper.fetchData(component);
    },
    handleSaveEdition: function (component, event, helper) {
        var draftValues = event.getParam('draftValues');
      
		var action = component.get("c.updateSortSubSections");
        action.setParams({"odr" : draftValues,"objId" :component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            //$A.get('e.force:refreshView').fire();
            helper.fetchData(component);
        });
        $A.enqueueAction(action);
        
    },
})