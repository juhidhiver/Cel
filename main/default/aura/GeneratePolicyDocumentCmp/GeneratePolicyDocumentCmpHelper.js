({
	setColumnInfo : function(component){
		component.set('v.columns', [
            {label: 'Quote name', fieldName: 'Name', type: 'text'},
            {label: 'Quote Type', fieldName: 'Quote_Type__c', type: 'text'},
            {label: 'Endorsement Effective Date', fieldName: 'Endorsement_Effective_Date__c', type: 'date'},
			{label: 'Transaction Premium', fieldName: 'Transaction_Premium__c', type: 'currency'},
			{label: 'Quote Number', fieldName: 'QuoteNumber', type: 'text'}
        ]);
	},
	fetchBoundQuotes : function(component){
		var action = component.get("c.getBoundQuotes");
		action.setParams({ 
			policyId : component.get("v.recordId")
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				component.set("v.data", response.getReturnValue());
			} else {
				$A.get("e.force:showToast").setParams({
					"type": "error",
		            "title": "Error",
		            "message": action.getError()[0].message
		        }).fire();
			}
	    });
		$A.enqueueAction(action);
	},
	doInit : function(component) {
		console.log('@@@ ------------- GenrateDoc.doInit -------------');
		// Create the action
		var action = component.get("c.getListTypeDocument");
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var result = response.getReturnValue();
                var returnPicklist = [];
                for(var i = 0; i < result.length; i++){
                    if(result[i].value != 'PolicySchedulePrimary' && result[i].value != 'PolicyScheduleExcess') 
                        returnPicklist.push(result[i]);
                }
				component.set('v.docTypeOptions', returnPicklist);
			} else {
				$A.get("e.force:showToast").setParams({
					"type": "error",
		            "title": "Error",
		            "message": action.getError()[0].message
		        }).fire();
			}
	    });
		$A.enqueueAction(action);
	},

	generateDocumentId : function(component) {
		console.log('@@@ ------------- GenrateDoc.generateDocumentId -------------');
		component.set('v.isLoading', true);

		// Get document type from picklist
		var docType = component.find('docType').get("v.value");
		console.log('@@@ docType= ' + docType);
		console.log('@@@ contractId= ' + component.get("v.recordId"));
		var action = component.get("c.generateDocumentId");
		action.setParams({ 
			quoteId : docType == component.get("v.changeEndorsementValue") ? component.get("v.selectedQuoteId") : '',
			policyId : component.get("v.recordId"),
			docType : docType
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			console.log('@@@ state= ' + state);

			if (state === "SUCCESS") {
				var result = response.getReturnValue();
				console.log('@@@ result= ' + JSON.stringify(result));
				$A.get("e.force:closeQuickAction").fire();
				$A.get("e.force:showToast").setParams({
					"type": (!result.errMsg) ? "success" : "error",
		            "title": (!result.errMsg) ? "Success" : "Error",
		            "message": (!result.errMsg) ? "Document has been generated successfully!" : result.errMsg
		        }).fire();
			}
			component.set('v.isLoading', false);
			$A.get('e.force:refreshView').fire();
	    });
		$A.enqueueAction(action);
	}
})