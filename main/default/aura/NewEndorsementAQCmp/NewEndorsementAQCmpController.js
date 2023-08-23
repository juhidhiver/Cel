({	
    init : function(component, event, helper){
        component.set('v.effectiveDate', helper.getDefaultDate());
        
        //console.log('countryOptions::'+JSON.stringify(countryOptions));
        component.set("v.countryOptions", helper.getCountryOptions());
        if(component.get("v.policyRecord.Policy_Status__c") == 'Cancelled'){
            let today = new Date();
            let month = today.getMonth() < 10 ? '0'+(today.getMonth()+1) : today.getMonth()+1;
            let dt = today.getDate() < 10 ? '0'+today.getDate() : today.getDate();
            let currentDate = (today.getFullYear() + "-" + month + "-" + dt );
            var cancelDate = component.get("v.policyRecord.Cancellation_Date__c");
            var effectiveDate = component.get("v.policyRecord.Effective_Date__c");
            var expirationDate = component.get("v.policyRecord.Expiration_Date__c")
            
            if(cancelDate == null){
                helper.showErrorMsg('Error', 'Policy cannot be reinstated as Prior cancel date is not available');
                $A.get("e.force:closeQuickAction").fire();
            }
            if(expirationDate < currentDate || cancelDate <effectiveDate ){
                helper.showErrorMsg('Error', 'This Policy cannot be reinstated as it is outside Policy period');
            $A.get("e.force:closeQuickAction").fire();
            }
            
            
            var action = component.get("c.checkActiveSubmission");
            action.setParams({
                contractId : component.get("v.policyRecord.Id")
            });
            action.setCallback(this, function(response) {
                if (response.getState() == 'SUCCESS') {
                    var result = response.getReturnValue();
                    console.log('result-->',result);
                    if(result){
                        helper.showErrorMsg('Error', 'Reinstatement is not possible on this Policy as other linked Policies have changed, Please Create a new Quote');
                        $A.get("e.force:closeQuickAction").fire();
                    }
                }
            });
            $A.enqueueAction(action);
        }
        
        var action = component.get("c.checkOpenQuotes");
        action.setParams({
            contractId : component.get("v.policyRecord.Id")
        });
        action.setCallback(this, function(response) {
            if (response.getState() == 'SUCCESS') {
                var result = response.getReturnValue();
                console.log('result-->',result);
                if(result != ''){
                    if(result == 'Declined') helper.showErrorMsg('Error', 'Cannot initiate Policy Change on Declined Submission');
                    else if(result == 'Open Quotes') helper.showErrorMsg('Error', 'All open Quotes on related Submission must be bind or closed before initiating another policy Change');
                    else if(result == 'inactive') helper.showErrorMsg('Error', 'Change Policy not allowed on Inactive Submission');
                    else if(result == 'noBoundQuotes') helper.showErrorMsg('Error', 'No Bound Quotes on Active Submission Quote');                    
                    $A.get("e.force:closeQuickAction").fire();
                }
                else{
                    /*var action = component.get("c.isPolicyExpired");
                    action.setParams({contractId : component.get("v.policyRecord.Id")});
                    action.setCallback(this, function(response){
                        if (response.getState() == 'SUCCESS') {
                            var result = response.getReturnValue();
                            console.log('is expired result-->',result);
                            if(result == true) {
                            helper.showErrorMsg('Error', 'Please note: Change Policy cannot be initiated on an expired policy');
                            $A.get("e.force:closeQuickAction").fire();  
                            }
                        }    
                    });
                    $A.enqueueAction(action);*/

                    var action = component.get("c.getAccountDetails");
                    action.setParams({
                        policyId : component.get("v.recordId")
                    });
                    action.setCallback(this, function(response) {
                        if (response.getState() == 'SUCCESS') {
                            var returnedResult = response.getReturnValue();
                            console.log('response',returnedResult);
                            if(returnedResult.sanctionStatus != 'Pass' && returnedResult.sanctionStatus != 'Cleared'){
                                helper.showErrorMsg('Error', 'Account\'s Sanction Status must be Pass or Cleared.');
                                $A.get("e.force:closeQuickAction").fire();
                            }
                            else{
                                var action = component.get("c.initData");
                                action.setParams({
                                    contractId : component.get("v.policyRecord.Id"),
                                    productName : component.get("v.policyRecord.Product_Name__c"),
                                    status : component.get("v.policyRecord.Policy_Status__c"),
                                    effectiveDate : component.get("v.policyRecord.Effective_Date__c"),
                                    cancelDate : component.get("v.policyRecord.Cancellation_Date__c")
                                });
                                action.setCallback(this, function(response) {
                                    if (response.getState() == 'SUCCESS') {
                                        var result = response.getReturnValue();
                                        console.log('result-->',JSON.stringify(result));
                                        component.set("v.types",result);
                                        component.set('v.endorsementType', component.get("v.types")[0].value);
                                        if(result[0].value == 'Reinstatement'){
                                            component.set('v.isReinstatement',true);
                                            component.set('v.effectiveDate', component.get("v.policyRecord.Cancellation_Date__c"));
                                            component.set("v.isDateReadOnly", true);
                                        }
                                    }
                                });
                                $A.enqueueAction(action);
                                
                                var endorsementReasonPicklist = component.get("c.getEndorsementReasons");
                                endorsementReasonPicklist.setParams({
                                    endorsementType : 'Full Amendment',
                                });
                                endorsementReasonPicklist.setCallback(this, function(response) {
                                    console.log('result-->',JSON.stringify(response.getReturnValue()));
                                    component.set("v.endorsementReasons", response.getReturnValue());	
                                    component.set("v.endorsementReason", response.getReturnValue()[0].value);				
                                });
                                $A.enqueueAction(endorsementReasonPicklist);
                                
                                var sanctionStatusGetPickList = component.get("c.getSanctionStatusPicklist");
                                sanctionStatusGetPickList.setCallback(this, function(response) {
                                    component.set("v.sanctionStatus", response.getReturnValue());	
                                    component.set("v.sanctionStatusValue", response.getReturnValue()[0].value);				
                                });
                                $A.enqueueAction(sanctionStatusGetPickList);
                                
                                var kycStatusGetPickList = component.get("c.getKYCStatusPicklist");
                                kycStatusGetPickList.setCallback(this, function(response) {
                                    console.log('kyc values::'+JSON.stringify(response.getReturnValue()));
                                    component.set("v.kycStatus", response.getReturnValue());	
                                    console.log('response.getReturnValue()'+response.getReturnValue()[0].value);
                                    component.set("v.kycStatusValue", response.getReturnValue()[0].value);				
                                });
                                $A.enqueueAction(kycStatusGetPickList);
                            }
                        }
                        else{
                            helper.showErrorMsg('Error', 'Error in checking the existing Account\'s Sanction Status, please try again.');
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });
                    $A.enqueueAction(action);
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    handleCancelClick : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
    getEndorsementReason : function(component, event, helper) {
        var endorsementReasonPicklist = component.get("c.getEndorsementReasons");
        console.log('Inside endo');
        endorsementReasonPicklist.setParams({
            endorsementType : component.get("v.endorsementType"),
        });
        endorsementReasonPicklist.setCallback(this, function(response) {			
            component.set("v.endorsementReasons", response.getReturnValue());	
            component.set("v.endorsementReason", response.getReturnValue()[0].value);				
        });
        $A.enqueueAction(endorsementReasonPicklist);
    },
    
    handleChangeType : function(component, event, helper){
        var selected = component.find("EndorsementType").get("v.value");
        if(selected == 'Coverage Cancel & Replace' || selected == 'Full Cancel & Replace' ){
            component.set("v.showEndorsementReason",true);
            component.set("v.showEndorsementEffectiveDate",false);
        }else{
            component.set("v.showEndorsementReason",true);
            component.set("v.showEndorsementEffectiveDate",true);
            
        }
        var productName = component.get("v.policyRecord.Product_Name__c");
        component.set("v.endorsementType", selected);
        component.set("v.showOtherField", false);
        component.set('v.error', "");
        
        if(selected == 'Midterm Cancellation'){ 
            helper.getEndorsementReasons(component);  
            component.set("v.endorsementDateLabel", 'Cancellation Date');
            component.set("v.isDateReadOnly", false);
            component.set('v.effectiveDate', helper.getDefaultDate());
            component.set("v.showCancelDate", true);
            component.set("v.showQuoteDatatable",false);
        }
        else if(selected == 'Flat Cancellation'){
           
            helper.getEndorsementReasons(component);  
            component.set("v.endorsementDateLabel", 'Cancellation Date');
            component.set("v.isDateReadOnly", true);
            component.set("v.effectiveDate",component.get("v.policyRecord.Effective_Date__c"));
            component.set("v.showCancelDate", true);
            component.set("v.showQuoteDatatable",false); 
        }
        else if(selected == 'Coverage Cancel & Replace'){
            helper.getEndorsementReasons(component);
            component.set("v.IsSpinner", true);
            component.set("v.isFullCancelReplace", false);
            helper.getQuoteList(component, event, helper);
        }
        else if(selected == 'Full Cancel & Replace'){
            helper.getEndorsementReasons(component);
            component.set("v.IsSpinner", true);
            component.set("v.isFullCancelReplace", true);
            helper.getQuoteList(component, event, helper);
        }
        else if(selected == 'Insured Account Update'){
            //$A.util.addClass(component.find("hideReasons"), "slds-hide");
            //$A.util.addClass(component.find("endorsementReasonOther"), "slds-hide");
            helper.getEndorsementReasons(component); 
            helper.getAccountDetails(component);
            component.set("v.showInsuredAccountUpdateSection", true);
            component.set("v.endorsementDateLabel", 'Endorsement Effective Date');
            component.set("v.isDateReadOnly", false);
            component.set('v.effectiveDate', helper.getDefaultDate());
            component.set("v.showCancelDate", false);
            component.set("v.showQuoteDatatable",false);
        }else{
            helper.getEndorsementReasons(component);  
            component.set("v.endorsementDateLabel", 'Endorsement Effective Date');
            component.set("v.isDateReadOnly", false);
            component.set('v.effectiveDate', helper.getDefaultDate());
            component.set("v.showCancelDate", false);
            component.set("v.showQuoteDatatable",false);
        }
    },
    
    handleChangeReason : function(component, event, helper){
        var selected = component.find("endorsementReason").get("v.value");			
        component.set("v.endorsementReason", selected); 
        
        if(selected == 'Other'){
            component.set("v.showOtherField", true);
        }else{
            component.set("v.showOtherField", false);
            component.set('v.error', "");
        }
    },
    
    handleCancelDropdownChange : function (component, event, helper) {
        var selected = component.find("cancelEndorsement").get("v.value");			
        component.set("v.cancelEndorsement", selected);
    },
    handleSanctionStatusChange : function (component, event, helper) {
        var selected = component.find("sanctionPicklist").get("v.value");			
        component.set("v.sanctionStatusValue", selected);
    },/*
    handleKYCStatusChange : function (component, event, helper) {
        var selected = component.find("kycPicklist").get("v.value");			
        component.set("v.kycStatusValue", selected);
    },*/
    getAddress : function(component, event, helper) {
        console.log('isChangeOnAccount==>');
        const params = event.getParams();
        console.log('params::'+JSON.stringify(params));
        var billingStreet = params.address;
        component.set("v.billingStreet", billingStreet);
        component.set("v.billingCity", params.city);
        var postalCode = params.postalCode;
        component.set("v.postalCode", postalCode);
        var stateCode = params.stateCode;
        component.set("v.stateCode", stateCode);
        var countryCode = params.countryCode;
        component.set("v.countryCode",countryCode);
    },
    handleChangeOther: function (component, event, helper) {
        var selected = component.find("endorsementReasonOther").get("v.value");
        console.log('selected: ',selected);
        if(selected == '' || selected == undefined){
            component.set('v.error', "Please add Other Reason");
        }else{
            component.set('v.error', "");
        }
    },
    
    closeModel: function(component, event, helper) {
        component.set("v.isShowAccounts", false);
    },
    chooseAccount: function (component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.selectedAccId',selectedRows[0].accId);
        console.log('selectedAccId 4-->'+selectedRows[0].accId); 
        
    },
    
    clickUpdateAccount: function(component, event, helper) {
        console.log('selected: ');
        console.log('selectedAccId: ',component.get("v.selectedAccId"));
        if(component.get("v.selectedAccId") == null || component.get("v.selectedAccId") == '' || component.get("v.selectedAccId") == undefined){
            console.log('inside undefined: ');
            helper.showErrorMsg('Error', 'Please select a Account');
        }else{
            helper.handleSelectedAccount(component);  
        }
    },
    onChangeName: function(component, event, helper) {
        var selected = component.find("updatedName").get("v.value");
        component.set("v.accName",selected);
        console.log('updated name::',selected);
        console.log('updated name1::',component.get("v.accName"));
        component.set('v.isChangedNameOrAddress',true);  
        var isNameAddressChanged = component.get("v.isChangedNameOrAddress");
        if(isNameAddressChanged == true){
            helper.setKYCSanctionValues(component); 
        }
    },
    onChangeAddress: function(component, event, helper) {
        console.log('inside address chnage');
        console.log('event.source street-->'+event.getSource().get("v.street"));
        component.set("v.billingStreet", event.getSource().get("v.street"));
        console.log('get street-->'+component.get("v.billingStreet"));
        component.set("v.billingCity", event.getSource().get("v.city"));
        component.set("v.postalCode", event.getSource().get("v.postalCode"));  
        component.set("v.countryCode", event.getSource().get("v.country"));
        component.set("v.stateCode", event.getSource().get("v.province"));
        component.set('v.isChangedNameOrAddress',true); 
        var isNameAddressChanged = component.get("v.isChangedNameOrAddress");
        if(isNameAddressChanged == true){
            helper.setKYCSanctionValues(component);
        }
    },
    quoteCancel : function(component, event, helper) {
        component.set("v.confirmationPopup",false);
    },

    handleConfirmClick : function(component, event, helper) {
        
        var allowEndorsement = true;
        var effDate = component.get("v.effectiveDate");
        var endorsementType = component.get("v.endorsementType");
        console.log('selectedQuoteList:'+component.get("v.selectedQuoteList"));
        console.log('endorsementType:'+endorsementType);
        if(endorsementType == 'Coverage Cancel & Replace' || endorsementType == 'Full Cancel & Replace'){            
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
            component.set("v.confirmationPopup",true);
            return;
        }
        if(endorsementType != 'Reinstatement' && endorsementType != 'Insured Account Update'){
            console.log('inside not IA');
            if(component.find("endorsementReason").get("v.value") == 'Other'){
                if(component.find("endorsementReasonOther").get("v.value") == '' || component.find("endorsementReasonOther").get("v.value") == null) {
                    component.set('v.error', "Please add Other Reason");
                    allowEndorsement = false;
                }
            }
        }
        
        if(endorsementType == 'Insured Account Update'){
            console.log('inside  IA');
            if(component.find("updatedName").get("v.value")==''){
                console.log('inside account validation...');
                component.set('v.error', "Account name cannot be blank");
                allowEndorsement = false;  
            }
            if(component.get("v.billingStreet")==''){
                console.log('inside billing validation...');
                component.set('v.error', "Billing street cannot be blank");
                allowEndorsement = false;  
            }
            if(component.get("v.postalCode")==''){
                console.log('inside postalCode validation...');
                component.set('v.error', "Postal code cannot be blank");
                allowEndorsement = false;  
            }
            if(component.get("v.countryCode")==''){
                console.log('inside countryCode validation...');
                component.set('v.error', "Country cannot be blank");
                allowEndorsement = false;  
            }
            if(component.get("v.billingCity")==''){
                console.log('inside billing validation...');
                component.set('v.error', "Billing city cannot be blank");
                allowEndorsement = false;  
            }
            /*if(component.get("v.stateCode")==''){
                console.log('inside stateCode validation...');
                component.set('v.error', "Province cannot be blank");
                allowEndorsement = false;  
            }*/
            /*if(component.find("sanctionPicklist").get("v.value") != 'Pass'){
                console.log('inside sanction...');
                component.set('v.error', "Sanction status should be Pass");
                allowEndorsement = false;
            }*/
            /*if(component.find("kycPicklist").get("v.value") != 'Approved'){
                console.log('inside kyc...');
                component.set('v.error', "KYC status should be Approved");
                allowEndorsement = false;
            }*/
        }  
        
        
        if(!effDate) {
            component.set('v.error', "Please input Date");
            allowEndorsement = false;           
        }
        
        if(component.get("v.endorsementDateLabel") == 'Endorsement Effective Date'){
            var action = component.get("c.checkEndorsementDate");
            action.setParams({
                contractId : component.get("v.policyRecord.Id"),
                effectiveDate : component.get("v.effectiveDate")
            });
            action.setCallback(this, function(response) {
                if (response.getState() == 'SUCCESS') {
                    var result = response.getReturnValue();
                    console.log('response',result);
                    if(result) {
                        allowEndorsement = false;
                        helper.showErrorMsg('Error', 'The Endorsement Effective date must be within the Effective and Expiry date of Quote.');
                        $A.get("e.force:closeQuickAction").fire();
                    }else{
                        if(allowEndorsement){
                            console.log ('allow ok2');
                            helper.handleConfirmClick(component);
                        }
                    }
                }
            });
            $A.enqueueAction(action);      
        }else if(component.get("v.endorsementDateLabel") == 'Cancellation Date'){
            var newAction = component.get("c.checkCancellationDate");
            newAction.setParams({
                contractId : component.get("v.policyRecord.Id"),
                effectiveDate : component.get("v.effectiveDate")
            });
            newAction.setCallback(this, function(response) {
                if (response.getState() == 'SUCCESS') {
                    var result = response.getReturnValue();
                    console.log('response',result);
                    if(result) {
                        allowEndorsement = false;
                        helper.showErrorMsg('Error', 'The Cancellation Date must be within the Effective and Expiry date of Policy.');
                        $A.get("e.force:closeQuickAction").fire();
                    }else{
                        if(allowEndorsement){
                            console.log ('allow ok');
                            helper.handleConfirmClick(component);
                        }
                    }
                }
            });
            $A.enqueueAction(newAction);   
        }
        
        console.log(':handleConfirmClick:END');
    },
    
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
                //component.set("v.IsSpinner", false);
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
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }else{
                        helper.preRateNbOrRenewalQuote(component, helper, result, endorsementType);
                        /*var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Coverage Cancel is successfull.",
                            "type": "success"
                        });
                        toastEvent.fire();
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": result.oppId,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();*/
                    }            
                    /*console.log("response-->"+JSON.stringify(response.getReturnValue()));
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();*/
                }else{
                    component.set("v.IsSpinner", false);
                    console.log("Error-->"+JSON.stringify(response.getError()));
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }            
            });
            $A.enqueueAction(action);
        }
        else{ 
            console.log('inside full cancel');
            component.set("v.IsSpinner", true);
            var action = component.get("c.FullAmendmentCancelProcess");
            action.setParams({
                selectedId : selectedQuote.Id,
                createdDate : selectedQuote.CreatedDate,
                effectiveDate: component.get("v.effectiveDate"),
                policyId : component.get("v.recordId"),
            });
            action.setCallback(this, function(response) {
                var result = response.getReturnValue();
                //component.set("v.IsSpinner", false);
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
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }else{
                        helper.preRateNbOrRenewalQuote(component, helper, result, endorsementType);
                        /*var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Full Cancel & Replace is successfull.",
                            "type": "success"
                        });
                        toastEvent.fire();
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": result.oppId,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();*/
                    }            
                    /*console.log("response-->"+JSON.stringify(response.getReturnValue()));
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();*/
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
    
    selectedQuoteRow : function(component, event, helper) {
        component.set("v.showQuoteDatatable",true);
        var selectedRows = event.getParam('selectedRows');
        component.set("v.selectedQuoteList",selectedRows);
        console.log("Row-->"+JSON.stringify(component.get("v.selectedQuoteList")));
    },
    createAccount : function(component, event, helper) {
        helper.createAccount(component);
    }
    
    
})