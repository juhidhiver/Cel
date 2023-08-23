({	
	handleConfirmClick : function(component) {        
		// Create the action
		var action = component.get("c.createNewEndorsement");
		var effDate = component.get("v.effectiveDate");
		var endorsementType = component.get("v.endorsementType");
		var expDate = component.get("v.expiryDate");

		//Added by Vinayesh on 07/6/2021 for CD: 17
		if(endorsementType == 'Coverage Cancel & Replace'){            
            if(component.get("v.selectedQuoteList").length == 0){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please Select a Quote to proceed for Cancel and Replace.",
                    "type": "error"
                });
                toastEvent.fire();       
                return;
            }
			var selectedQuote = component.get("v.selectedQuoteList")[0];
			if(selectedQuote.Quote_Type__c == 'Midterm Cancellation'  ||  
				selectedQuote.Quote_Type__c == 'Flat Cancellation' ||
				selectedQuote.Quote_Type__c == 'Flat Cancellation (Ab - Initio)' ){
					component.set("v.isNotMidOrFullCancelled",false);
				}
				else{
					component.set("v.isNotMidOrFullCancelled",true);
				}

            component.set("v.confirmationPopup",true);
            return;
        }

		var spinner = component.find("spinner");
		console.log( 'effDate:' + effDate);
		console.log( 'endorsementType:' + endorsementType);
		//var spinner = component.find("spinner");
		$A.util.toggleClass(spinner, "slds-show");
		this.showSpinner(component);
		//component.set('v.isHidden', true);
        
		if(!effDate) {
			component.find('effectiveDateId').set("v.errors", [{message:"Please input Date" }]);
			this.hideSpinner(component);
			return false;
		}
		if(!expDate && endorsementType == "Policy Duration Change" ) {
			component.find('expiryDateId').set("v.errors", [{message:"Please input expiry Date" }]);
			this.hideSpinner(component);
			return false;
		}
		// 04-22-2020 Hang - fix defect No.15657 - The Expiration Date cannot be more than 2 years from the Effective date
		if(effDate && endorsementType == 'Extension'){
			var expireDate = new Date(effDate);
			var effectiveDate = new Date(component.get("v.contractRecord.Effective_Date__c"));
			var twoYearFromEff = this.addDate(effectiveDate, 0 , 0, 2);
			console.log("@@@expireDate: " + expireDate + ", effectiveDate" +effectiveDate + ", twoYearFromEff" +twoYearFromEff);
			if(expireDate > twoYearFromEff) {
				component.set("v.error", "The Expiration Date can not be more than 2 years from the Effective date");
				this.hideSpinner(component);
				return false;
			}
		}
		
		/**Added by Jai to check existing quote */
		var policyExistQuotes = component.get('v.policyExistQuotes');
		if(policyExistQuotes && policyExistQuotes.length>0){
			var types = component.get('v.types');
			var endorsementTypes = [];
			for(var i=0; i<types.length; i++){
				endorsementTypes.push(types[i].value);
			}
			for(var j=0; j<policyExistQuotes.length; j++){
				if( (policyExistQuotes[j].Status =='In Progress' || policyExistQuotes[j].Status =='Quoted' || policyExistQuotes[j].Status =='Rated' ) &&
					endorsementTypes.includes(policyExistQuotes[j].Quote_Type__c)
				){
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						"type": 'error',
						"title": 'Error!!',
						"message": $A.get("$Label.c.Existing_MTA_Error_Message")
					});
					toastEvent.fire();
					this.hideSpinner(component);
					return;
				}
			}
		}
		/**Added by Jai to check existing quote */

		if(effDate && endorsementType){
			var otherParams = {};
			otherParams.expDate = expDate;
			otherParams.ERP_Duration = component.get('v.selectedDuration');
			otherParams.rateCharged = component.get('v.selectedRate');
			otherParams.brokerContact = component.get('v.selectedBrokerContact');
			action.setParams({   
				cancelEndorsement : component.get("v.cancelEndorsement"),
				policyId : component.get("v.recordId"),
				effDate: component.get("v.effectiveDate"),
				endorsementType: component.get("v.endorsementType"),
				endorsementChangeDesc : component.get("v.defaultChangeDescValues").join(';') ,
				otherParams : JSON.stringify(otherParams)
			});
			// 04-25-2019 Quang Pham Endorsement updates required Delete End
			
			action.setCallback(this, function(response) {
				var state = response.getState();
				//var errMsg = '';
				
				if (state === "SUCCESS") {
					var result = response.getReturnValue();
					console.log(result);
					if(result.error) {
						component.set('v.error', result.error);
						this.hideSpinner(component);
						
					}else {
						// When the user selects Amendment, redirected to the new Endorsement Quote. 
						if(endorsementType == 'Amendment') {
							
							var navEvt = $A.get("e.force:navigateToSObject");
							navEvt.setParams({
							"recordId": result.oppId,//Phuc modified for ticket 19173
							"slideDevName": "related"
							});
							navEvt.fire();
						} else if(	endorsementType == 'Policy Duration Change' || 
									endorsementType == 'Update Insured Name or Address' || 
									endorsementType == 'Extended Reporting Period (ERP)' ||
									endorsementType == 'Midterm Cancellation' || //Jai modified for 53346
									endorsementType == 'Broker on Record Change'
								)
						{
							var navEvt = $A.get("e.force:navigateToSObject");
							navEvt.setParams({
								"recordId": result.oppId
							});
							navEvt.fire();
						}else {
							console.log('cloneQuoteId==' + result.cloneQuoteId);
							component.set('v.newQuoteId', result.cloneQuoteId);
							
							// For Rating Endorsement Quote
							var actionRate = component.get("c.ratingQuoteEndorsement");
							actionRate.setParams({
								quoteId : result.cloneQuoteId
							});
							
							actionRate.setCallback(this, function(responseRate){
								if (responseRate.getState() == 'SUCCESS') {
									var msgError = responseRate.getReturnValue();
									console.log('msgError==' + msgError);
									
									if(!msgError) {
										// For Bind Quote
										var actionBind = component.get("c.bindQuoteEndorsement");
										
										console.log('quoteId==' + component.get("v.newQuoteId"));
										console.log('contractCancelDate==' + component.get("v.effectiveDate"));
										console.log('contractCancellationReason==' + component.get("v.cancelEndorsement"));
										
										actionBind.setParams({
											quoteId : component.get("v.newQuoteId"),
											strCancelDate: component.get("v.effectiveDate"),
											contractCancellationReason : component.get("v.cancelEndorsement")
										});
										
										actionBind.setCallback(this, function(reponseBind) {
											if (reponseBind.getState() == 'SUCCESS') {
												var errBind = reponseBind.getReturnValue();
												console.log('Error Bind==' + errBind);
												
												if(errBind) {
													component.set('v.error', errBind);
													this.hideSpinner(component);
												} else {
													// Close the action panel and refresh view
													$A.get("e.force:closeQuickAction").fire();
													if( endorsementType == 'Midterm Cancellation' || endorsementType == 'Extended Reporting Period (ERP)' ){
														var navEvt = $A.get("e.force:navigateToSObject");
														navEvt.setParams({
															"recordId": result.oppId
														});
														navEvt.fire();
													}else{
														$A.get('e.force:refreshView').fire();
													}
														
												}
											}								
										});
									
										$A.enqueueAction(actionBind);
									} else {
										component.set('v.error', msgError);
										this.hideSpinner(component);
									}
								}
							});
						
							$A.enqueueAction(actionRate);
						}
					}
				} else {
					component.set('v.error', action.getError()[0].message);
					this.hideSpinner(component);
				}
			});
			
			$A.enqueueAction(action);
		}
	},

	//Added by Vinayesh on 07/6/2021 for CD: 17
	getQuoteList : function(component, event, helper){
        component.set('v.quoteCloumns', [
            {label: 'Name', fieldName: 'DummyUrl', type: 'url', initialwidth : 40, editable : false,
			typeAttributes: {
				label: {
					fieldName: 'Name',
				  },
				disabled: true,
				tooltip: {
					label: { fieldName: 'Name' },
					fieldName: 'Name'
				},
				target: '_self',
			},},
            {label: 'Status', fieldName: 'Status', type: 'text'},
            {label: 'Type', fieldName: 'Quote_Type__c', type: 'text'},
            {label: 'Inception Date', fieldName: 'Effective_Date__c', type: 'date '},
            {label: 'Expiry Date', fieldName: 'ExpirationDate', type: 'date '},
        ]);
            component.set("v.showQuoteDatatable",true);
            var action = component.get("c.showQuotes");
            action.setParams({
                policyId : component.get("v.recordId"),
                effDate: component.get("v.effectiveDate"),
                endorsementType: component.get("v.endorsementType"),
            });
            action.setCallback(this, function(response) {
                var result = response.getReturnValue();
                component.set("v.IsSpinner", false);
                if(response.getState() == 'SUCCESS'){    
                    if(result.error){
				 //Added by Vinayesh on 07/6/2021 for CD: 17
				 component.set("v.disableConfirmButton", true);
                 component.set("v.showQuoteDatatableText",true);
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        "title": "Error!",
                        "message": result.error,
                        "type": "error"
                        });
                        toastEvent.fire();
                    }            
                    console.log("list-->"+JSON.stringify(response.getReturnValue().quoteList));
					var quotes = response.getReturnValue().quoteList;
					quotes.forEach(function(item) {
						item['DummyUrl'] = '/' + item.Id;
					})
					component.set("v.quoteData", quotes);
                    //component.set("v.quoteData", response.getReturnValue().quoteList);
                    if(component.get("v.quoteData").length == 1){
                    	component.set("v.selectedQuoteList",component.get("v.quoteData")[0].Id);
                    }
                }else{
                	console.log("Error-->"+JSON.stringify(response.getError()));
                }            
            });
            $A.enqueueAction(action);
            },

	showSpinner:function(cmp){
		cmp.set("v.IsSpinner",true);
	},
	
	hideSpinner:function(cmp){
		cmp.set("v.IsSpinner",false);
	},

	getDefaultDate:function(){
		let tomorrow = new Date();
		tomorrow.setDate(tomorrow.getDate() + 1);
		return (tomorrow.getFullYear() + "-" + (tomorrow.getMonth()+1) + "-" + tomorrow.getDate());
	},

	addDate : function(fromDate, days, months, years) {
		var newDate = new Date(fromDate);
        newDate.setDate(newDate.getDate() + days);
        newDate.setMonth(newDate.getMonth() + months);
        newDate.setYear(newDate.getFullYear() + years);
        return newDate;
    },

	fetchEndorsementChangeDetailsInfo : function(component){
		var action = component.get("c.getEndorsementChangeDescription");
		action.setCallback(this, function(response) {
			if (response.getState() == 'SUCCESS') {
				var result = response.getReturnValue();
				component.set("v.changeDescripionValues", result.allValues);
				component.set("v.changeDescriptionDefaultValueMap", result.defaultValuesByType);
				console.log(JSON.stringify(result));
			}else{
				console.log( response.getError() );
			}
		});
		$A.enqueueAction(action);
	},

	getEndorsementOpHelpText : function(component, event, helper, endorsmentOps){

		var action = component.get("c.getEndorsementOperationsHelpText");
		action.setParams({
			endorsementOperations : endorsmentOps
		});
		action.setCallback(this, function(response) {
			if (response.getState() == 'SUCCESS') {
				var result = response.getReturnValue();
				console.log('Endors Help text', result);
				var helpTextObjList = [];
				for (var key in result) {
					if (result.hasOwnProperty(key)) {
						helpTextObjList.push({value: key, label: result[key]});
					}
				};
				component.set("v.endOpHelpTextList", helpTextObjList);
				helper.setEndorsementOpHelpText(component, event, helper, component.get('v.endorsementType'));
			}else{
				console.log( response.getError() );
			}
		});
		$A.enqueueAction(action);
	},
	setEndorsementOpHelpText : function(component, event, helper, endorsmentType){
		
		var endorsOpList = component.get("v.endOpHelpTextList");
		component.set("v.endOpHelpText", '' );
		for (var i=0; i < endorsOpList.length ;i++) {
			console.log(endorsOpList[i] );
			if( endorsOpList[i].value == endorsmentType){
				component.set("v.endOpHelpText", endorsOpList[i].label );
			}
		}
		
	},

	/*Added by Jai 04-Oct- 2021*/
	getPolicyExistQuote: function(component, event, helper){
		var action = component.get("c.fetchPolicyExistQuts");
		action.setParams({
			policyId : component.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			var result = response.getReturnValue();
			console.log('getPolicyExistQuote : ',result);
			if(state == 'SUCCESS'){ 
				component.set('v.policyExistQuotes',result.Quotes__r);
			}
			else{
				console.log('Error : ',response.getError() );
			}
		});
		$A.enqueueAction(action);
	},

	/*Added by Jai 13-Oct- 2021*/
        getErpDurationsAndRates: function(component, event, helper){
            var policy = component.get("v.policyRecord");
            var productName = policy.Product_Name__c;
            component.set("v.showErpRate",true);
            component.set("v.showErpDuration",true);
            var action = component.get("c.fetchErpProductInfo");
            action.setParams({
                productName: productName,
                effDate: policy.Expiration_Date__c,
                policyId: policy.Id
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                var result = response.getReturnValue();
                console.log('getErpDurationsAndRates : ',result);
                if(state == 'SUCCESS'){ 
                    console.log('productName : ',productName);
                    if(result && result != null && result.productInfo){
                        var productInfo=JSON.parse(result.productInfo);
                        component.set('v.effectiveDate', policy.Expiration_Date__c);
                        component.set("v.isDateReadOnly",true);
                        
                        if(productInfo.MasterLabel == productName)
                        {
                            component.set("v.productInfoMDTJson",productInfo);
                            if(productInfo.Applicable_ERP_Duration__c){
                                var durationList = productInfo.Applicable_ERP_Duration__c.split(',');
                                component.set('v.ERP_DurationList',durationList);
                                component.set('v.selectedDuration',durationList[0]);
                            }
                            
                            if(productInfo.Applicable_Rate_Charged__c /*&& productName != 'Private Company Combo'*/){
                                var rateList = productInfo.Applicable_Rate_Charged__c.split(',');
                                component.set('v.rateChargedList',rateList);
                                component.set('v.selectedRate',rateList[0]);
                            }
                        }
                        
                        if(result.selectedDuration && result.selectedDuration!=null)
                        {
                            component.set('v.selectedDuration',result.selectedDuration);
                        }
                        if(result.selectedRate && result.selectedRate!=null)
                        {
                            component.set('v.selectedRate',result.selectedRate);
                        }
                        if(!component.get('v.selectedDuration') || !component.get('v.selectedRate'))
                        {
                            this.handleChangeERPDuration(component, component.get('v.selectedDuration'));
                        }
                    }
                }
                else{
                    console.log('Error : ',response.getError() );
                }
            });
            $A.enqueueAction(action);
        },
        handleChangeERPDuration: function (component, erpDuration) {
            var productInfo=component.get("v.productInfoMDTJson");
            if(productInfo && productInfo.Applicable_ERP_Duration_Rate_Charged__c && productInfo.Applicable_ERP_Duration_Rate_Charged__c!=null)
            {
                var erpMappings=JSON.parse(productInfo.Applicable_ERP_Duration_Rate_Charged__c);
                if(erpMappings && erpMappings.length>0)
                {
                    if(erpDuration)
                    {
                        for(var i in erpMappings)
                        {
                            if(erpMappings[i].ERPDuration==erpDuration)
                            {
                                component.set('v.selectedRate',erpMappings[i].RateCharged); 
                            }
                        }
                    }else{
                        component.set('v.selectedDuration',erpMappings[0].ERPDuration);
                        component.set('v.selectedRate',erpMappings[0].RateCharged);
                    }
                }
            }
        },
})