({
	init: function(component, event, helper) {
		helper.setColumnInfo(component);
		helper.fetchBoundQuotes(component);
		helper.doInit(component);
	},
	updateSelectedQuote : function(component, event, helper) {
        component.set('v.selectedQuoteId', event.getParam('selectedRows')[0].Id);
	},
	handleConfirmClick: function(component, event, helper) {
		if(component.get("v.docType") == component.get("v.changeEndorsementValue")){
			if(component.get('v.selectedQuoteId') && component.get('v.selectedQuoteId') != ''){
				helper.generateDocumentId(component);
			}else{
				$A.get("e.force:showToast").setParams({
					"type": "error",
		            "title": "Error",
		            "message": "Please select a quote from the table."
		        }).fire();
			}
		}else{
			helper.generateDocumentId(component);
		}
	},
	handleCancelClick: function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
})