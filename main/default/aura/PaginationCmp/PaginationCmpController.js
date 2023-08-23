({
	doInit: function(component, event, helper) {
        helper.init(component);
		helper.navigateTo(component, helper, 1);
	},
    
    onPrev: function(component, event, helper) {        
        var currentPage = component.get("v.currentPage");
        var pageNumber = currentPage - 1;
        
        helper.navigateTo(component, helper, pageNumber);
    },
    
    onNext: function(component, event, helper) {        
        var currentPage = component.get("v.currentPage");
        var pageNumber = currentPage + 1;
        
        helper.navigateTo(component, helper, pageNumber);
    },
    
    onFirst: function(component, event, helper) {        
        helper.navigateTo(component, helper, 1);
    },
    
    onLast: function(component, event, helper) {    
        var pageNumber = component.get("v.totalPages");
        helper.navigateTo(component, helper, pageNumber);
    },
    
    onPage: function(component, event, helper) {   
        var pageNumber = parseInt(event.target.name);
        helper.navigateTo(component, helper, pageNumber);
    },
    
    pageChanged: function(component, helper) {
        helper.notifyPageChanged();
    }
})