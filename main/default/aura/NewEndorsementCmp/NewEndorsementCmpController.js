({	
	init : function(component, event, helper){
    
	component.set('v.effectiveDate', helper.getDefaultDate());
	
	var action = component.get("c.initData");
	
	console.log('==Effective_Date__c==' + component.get("v.policyRecord.Effective_Date__c"));
	console.log('==Cancellation_Date__c==' + component.get("v.policyRecord.Cancellation_Date__c"));
	console.log('==Status==' + component.get("v.policyRecord.Policy_Status__c"));
	console.log('==recordId==' + component.get("v.policyRecord.Id"));
	var status = component.get("v.policyRecord.Policy_Status__c");
	var cancelDate = component.get("v.policyRecord.Cancellation_Date__c");
	var effectiveDate = component.get("v.policyRecord.Effective_Date__c");
	action.setParams({
		
		contractId : component.get("v.policyRecord.Id"),
		productName : component.get("v.policyRecord.Product_Name__c"),
		status : component.get("v.policyRecord.Policy_Status__c"),
		effectiveDate : component.get("v.policyRecord.Effective_Date__c"),
		cancelDate : component.get("v.policyRecord.Cancellation_Date__c")
	});
	action.setCallback(this, function(response) {
		if (response.getState() == 'SUCCESS') {
			var returnPicklist = [];
			var endorsmentOps = [];
			var result = response.getReturnValue();
			console.log('==result==' , result);
			for(var i = 0; i < result.length; i++){
				//Added by Vinayesh on 04/06/2021 for US: Cd :15 
				//if(result[i].value != 'Renewal' && result[i].value != 'Coverage Cancel & Replace' && result[i].value != 'Full Cancel & Replace') returnPicklist.push(result[i]);
				
				/*added by Jai start */
				endorsmentOps.push(result[i].value);
				if( status == 'Cancelled' || status == 'Expired' ){
					if( result[i].value == 'Extended Reporting Period (ERP)' ){
						returnPicklist.push(result[i]);
					}
					var cDate = new Date(cancelDate);
					var eDate = new Date(effectiveDate);
					if( status == 'Cancelled' && cDate != null && cDate > eDate){
						if( result[i].value == 'Reinstatement' ){
							returnPicklist.push(result[i]);
						}
					}
				}else{
					if( result[i].value == 'Extended Reporting Period (ERP)' || result[i].value == 'Reinstatement' ){
						continue;
					}
					/*added by Jai end */
					/* This is previous code */
					if(result[i].value != 'Renewal' && result[i].value != 'Full Cancel & Replace') {
						returnPicklist.push(result[i]);
					}
					/* This is previous code */
				}
			}
			console.log(returnPicklist);
			component.set("v.types",returnPicklist);
			component.set('v.endorsementType', component.get("v.types")[0].value);
			console.log('==selected==' + component.get('v.endorsementType'), returnPicklist );
			/*added by Jai */
			helper.getEndorsementOpHelpText(component, event, helper, endorsmentOps);
			
			/*added by Vinay */
			helper.fetchEndorsementChangeDetailsInfo(component);

			/*Added by Jai 04-Oct- 2021*/
			helper.getPolicyExistQuote(component, event, helper);

			/*Added by Jai 13-Oct- 2021*/
			var endorsementType = component.get('v.endorsementType');
			if(endorsementType =='Extended Reporting Period (ERP)'){
				helper.getErpDurationsAndRates(component, event, helper);
			}

			/*Added by Jai 20-Oct- 2021*/
			if(endorsementType=='Broker on Record Change'){
				component.set("v.showBrokerContact", true);
			}
		}
	});

	$A.enqueueAction(action);
	/* Quan Tran / 23-April-2019 / Endorsement cancellation reasons */		
	var actionGetPickList = component.get("c.getQuotesEdorsementCancelPicklist");
	actionGetPickList.setCallback(this, function(response) {			
		component.set("v.cancelReason", response.getReturnValue());	
		component.set("v.cancelEndorsement", response.getReturnValue()[0].value);				
	});
	$A.enqueueAction(actionGetPickList);
	/* end */
},
handleConfirmClick : function(component, event, helper) {
	/*Added by Jai on 20-Oct-2021 for BOR*/
	var endorsementType = component.get('v.endorsementType');
	if(endorsementType == 'Broker on Record Change'){
		var brokerContact = component.get('v.selectedBrokerContact');
		if($A.util.isUndefinedOrNull(brokerContact) || $A.util.isUndefined(brokerContact) || $A.util.isEmpty(brokerContact)){
			var brokerContactEle = component.find("brokerContact");
			if(!$A.util.hasClass(brokerContactEle, "slds-has-error")){
				$A.util.addClass(brokerContactEle, "slds-has-error");
			}
			return;
		}
	}
	helper.handleConfirmClick(component);
},

handleCancelClick : function(component, event, helper) {
	$A.get("e.force:closeQuickAction").fire();
},

handleChangeDesc : function(component, event, helper){
	var selectedType = component.find("EndorsementType").get("v.value");
	var selectedOptionValue = event.getParam("value");
	if(selectedType == 'Policy Duration Change'){
		var policy = component.get("v.policyRecord");
		if(selectedOptionValue == 'Policy Duration Change - Extension of Policy'){
			component.set('v.effectiveDate', policy.Expiration_Date__c);
		}
		else{
			component.set('v.effectiveDate', policy.Effective_Date__c);
		}
	}
},

handleChangeType : function(component, event, helper){
	var selected = component.find("EndorsementType").get("v.value");
	console.log('==selected='+selected);

	/* Added by Vinay */
	const defaultValueMap = component.get("v.changeDescriptionDefaultValueMap");
	if(defaultValueMap[selected])
		component.set("v.defaultChangeDescValues", Object.values(defaultValueMap[selected]));
	else
		component.set("v.defaultChangeDescValues", []);
	/* Added by Vinay */

	//For help text start by Jai
	helper.setEndorsementOpHelpText(component, event, helper, selected);
	//For help text end by jai
	component.set("v.showExpiryDate", false);

	/*Added by Jai 13-Oct- 2021 For ERP MTA*/
	component.set("v.showErpDuration",false);
	component.set("v.showErpRate",false);
	
	if(selected=='Extended Reporting Period (ERP)'){
		helper.getErpDurationsAndRates(component, event, helper);
	}
	/*Added by Jai 13-Oct- 2021 For ERP MTA*/

	/*Added by Jai 20-Oct- 2021 For BOR*/
	component.set("v.showBrokerContact",false);
	component.set('v.selectedBrokerContact','');
	
	//Added by Vinayesh on 07/6/2021 for CD: 17
	component.set("v.disableConfirmButton", false);
	if(selected == 'Coverage Cancel & Replace'){
		component.set("v.showEndorsementReason",false);
	}else{
		component.set("v.showEndorsementReason",true);
		component.set("v.showQuoteDatatable",false);
	}
	var productName = component.get("v.policyRecord.Product_Name__c");
	component.set("v.endorsementType", selected);
	console.log('==selected==' + component.get('v.endorsementType'));
	if(selected == 'Midterm Cancellation'){
		component.set("v.endorsementDateLabel", 'Cancellation Date');
		component.set("v.isDateReadOnly", false);
		component.set('v.effectiveDate', helper.getDefaultDate());
		component.set("v.showCancelDate", true);
	}
	else if(selected == 'Flat Cancellation'){
		component.set("v.endorsementDateLabel", 'Cancellation Date');
		component.set("v.isDateReadOnly", true);
		component.set("v.effectiveDate",component.get("v.policyRecord.Effective_Date__c"));
		component.set("v.showCancelDate", true);		
	}
	else if(selected == 'Extension'){
		if (productName == 'Builders Risk') {
			component.set("v.endorsementDateLabel", 'Endorsement Expiration Date');
		}
		component.set("v.isDateReadOnly", false);
		component.set('v.effectiveDate', helper.getDefaultDate());
		component.set("v.showCancelDate", false);
	}
	//Added by Vinayesh on 07/6/2021 for CD: 17
	else if(selected == 'Coverage Cancel & Replace'){
		component.set("v.IsSpinner", true);
		component.set("v.isFullCancelReplace", false);
		component.set("v.isDateReadOnly", false);
		component.set("v.showCancelDate", false);
		helper.getQuoteList(component, event, helper);
	}else if( selected == "Policy Duration Change"){
		var policy = component.get("v.policyRecord");
		component.set("v.endorsementDateLabel", 'Endorsement Effective Date');
		component.set("v.isDateReadOnly", true);
		component.set('v.effectiveDate', policy.Effective_Date__c);
		component.set("v.showCancelDate", false);
		component.set("v.showExpiryDate", true);
		component.set("v.expiryDate", policy.Expiration_Date__c );
	}else if(selected == "Extended Reporting Period (ERP)"){
		var policy = component.get("v.policyRecord");
		component.set("v.endorsementDateLabel", 'Endorsement Effective Date');
		component.set("v.isDateReadOnly", true);
		component.set('v.effectiveDate', policy.Expiration_Date__c);
		component.set("v.showCancelDate", false);
		component.set("v.showExpiryDate", false);
		component.set("v.showErpDuration",true);
        //Sunny Singh : commented below check  as discussed with Jai
		//if(productName != 'Private Company Combo'){
			component.set("v.showErpRate",true);
		//}
	}
	/*Added by Jai on 20-Oct-2021*/
	else if( selected == "Broker on Record Change"){
		component.set("v.endorsementDateLabel", 'Endorsement Effective Date');
		component.set("v.isDateReadOnly", false);
		component.set('v.effectiveDate', helper.getDefaultDate());
		component.set("v.showCancelDate", false);
		component.set("v.showBrokerContact", true);
		//component.set("v.showExpiryDate", false);
		//component.set("v.expiryDate", policy.Expiration_Date__c );
	}
	else {
		component.set("v.endorsementDateLabel", 'Endorsement Effective Date');
		component.set("v.isDateReadOnly", false);
		component.set('v.effectiveDate', helper.getDefaultDate());
		component.set("v.showCancelDate", false);
		component.set("v.showExpiryDate", false);
	}
},

//Added by Vinayesh on 07/6/2021 for CD: 17
quoteConfirm : function(component, event, helper) {
	console.log('quoteData-->'+component.get("v.quoteData").length);
	if(component.get("v.quoteData").length == 1){
	  component.set("v.selectedQuoteList",component.get("v.quoteData")[0]);  
	}
	
	var selectedQuote = component.get("v.selectedQuoteList")[0];
	console.log('selectedQuote-->',selectedQuote);
	var endorsementType = component.get("v.endorsementType");
	console.log('endorsementType-->'+endorsementType);
	if(endorsementType == 'Coverage Cancel & Replace'){
		component.set("v.IsSpinner", true);
		var action = component.get("c.coverageCancelProcess");
		action.setParams({
			selectedId : selectedQuote.Id,
			createdDate : selectedQuote.CreatedDate,
			effectiveDate: component.get("v.effectiveDate"),
			policyId : component.get("v.recordId"),
		});
		action.setCallback(this, function(response) {
			var result = response.getReturnValue();
			component.set("v.IsSpinner", false);
			console.log('result->'+JSON.stringify(result));
			if(response.getState() == 'SUCCESS'){    
				if(result.error){
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						"title": "Error!",
						"message": result.error,
						"type": "error"
					});
					toastEvent.fire();
				}else{
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						"title": "Success!",
						"message": "Coverage Cancel is successful.",
						"type": "success"
					});
					toastEvent.fire();
					var navEvt = $A.get("e.force:navigateToSObject");
					navEvt.setParams({
						"recordId": result.oppId,
						"slideDevName": "detail"
					});
					navEvt.fire();
				}            
				console.log("response-->"+JSON.stringify(response.getReturnValue()));
				$A.get("e.force:closeQuickAction").fire();
				$A.get('e.force:refreshView').fire();
			}else{
				component.set("v.IsSpinner", false);
				console.log("Error-->"+JSON.stringify(response.getError()));
				$A.get("e.force:closeQuickAction").fire();
				$A.get('e.force:refreshView').fire();
			}            
		});
		$A.enqueueAction(action);
	}
},

//Added by Vinayesh on 07/6/2021 for CD: 17
quoteCancel : function(component, event, helper) {
	component.set("v.confirmationPopup",false);
},

//Added by Vinayesh on 07/6/2021 for CD: 17
selectedQuoteRow : function(component, event, helper) {
	component.set("v.showQuoteDatatable",true);
	var selectedRows = event.getParam('selectedRows');
	component.set("v.selectedQuoteList",selectedRows);
	//console.log(selectedRows[0].Id);
	//console.log("Row-->"+JSON.stringify(component.get("v.selectedQuoteList")));
},

handleCancelDropdownChange : function (component, event, helper) {
	var selected = component.find("cancelEndorsement").get("v.value");			
	component.set("v.cancelEndorsement", selected);
},
handleError : function (component, event, helper) {
	var toastEvent = $A.get("e.force:showToast");
	toastEvent.setParams({
		"title": "Error!",
		"message": 'Dates are required',
		"type": "error"
	});
	toastEvent.fire();
},

/*Added by Jai on 20-Oct-2021*/
handleBrokerContact : function (component, event, helper) {
	var contact = event.getSource().get('v.value');
	console.log('broker contact : ',contact);
	if(contact instanceof Array){
		component.set('v.selectedBrokerContact',contact[0]);
	}else{
		component.set('v.selectedBrokerContact',contact);
    }
},
    handleChangeERPDuration: function (component, event, helper) {
        helper.handleChangeERPDuration(component, event.getSource().get('v.value'));
    },

})