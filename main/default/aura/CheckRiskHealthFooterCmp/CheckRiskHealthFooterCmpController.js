({
    init : function(component, event, helper) {
    },
    closeModal: function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    },
    proceedToQuote: function(component,event,helper){
        helper.updateStageAndPopulateFields(component);
    }
})