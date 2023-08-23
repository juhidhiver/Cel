({
    init : function(component, event, helper) {
        helper.getcolumns(component);
        helper.fetchData(component);
    },
    closeModal: function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})