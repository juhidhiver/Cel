({	
    handleConfirmClick : function(component) {   
        this.updateAccountMap(component);
        console.log('accountData new value',component.get("v.accountData"));
        console.log('effective date',component.get("v.effectiveDate"));
        if(component.get("v.endorsementType") == 'Flat Cancellation' || 
           component.get("v.endorsementType") == 'Midterm Cancellation'){
            component.set("v.cancelEndorsement",component.get("v.endorsementReason"));
        }
        var action = component.get("c.createNewEndorsement");
        var spinner = component.find("spinner");
        $A.util.toggleClass(spinner, "slds-show");
        this.showSpinner(component);
        
        action.setParams({   
            cancelEndorsement : component.get("v.cancelEndorsement"),
            policyId : component.get("v.recordId"),
            effDate: component.get("v.effectiveDate"),
            endorsementType: component.get("v.endorsementType"),
            endorsementReason: component.get("v.endorsementReason"),
            endoresementReasonOther: component.get("v.endorsementReasonOther"),
            accountData: component.get("v.accountData")
        });
        
        action.setCallback(this, function(response) {
            var result = '';
            var state = response.getState();
            if (state === "SUCCESS") {
                result = response.getReturnValue();
                console.log(result);
                
                if(result.showAccounts){
                    component.set("v.acctList",result.accList);
                    console.log('count: ',result.accList.length);
                    this.fetchAccDetails(component);
                    this.hideSpinner(component);
                }else{
                    if(result.error) {
                        component.set('v.error', result.error);
                        this.hideSpinner(component);
                        
                    }else {
                        // When the user selects Amendment, redirected to the new Endorsement Quote. 
                        var endorsementType = component.get("v.endorsementType");
                        if(endorsementType == 'Amendment' || endorsementType == 'Coverage Amendment'
                           || endorsementType == 'Midterm Cancellation' || endorsementType == 'Policy Duration Change') {

                            var returnId = result.oppId;
                            var slideDevName = 'related';
                            
                            /*if(endorsementType == 'Insured Account Update' && result.showAccounts == false){
                                console.log('inside toast..')
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title": "Success!",
                                    "message": "The account has been updated successfully.",
                                    "type": "success"
                                });
                                toastEvent.fire();
                            }*/
                            
                            var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": returnId,
                                "slideDevName": slideDevName
                            });
                            navEvt.fire();

                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Success!",
                                "message": endorsementType + " successful!",
                                "type": "success"
                            });
                            toastEvent.fire();
                        }
                        else if(endorsementType == 'Insured Account Update'){
                            console.log('Insured Account');
                           var returnId = result.resultAccId; 
                           var slideDevName ='detail';
                           if(result.showAccounts == false){
                                console.log('inside toast..')
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title": "Success!",
                                    "message": "The account has been updated successfully.",
                                    "type": "success"
                                });
                                toastEvent.fire();
                            }
                            
                            //check Sanction on Account before generating the documents
                            this.performSanctionSearchOnAccount(component,returnId,slideDevName);
                            /**** New Line Added by Navdeep ****/
                            //this.handleQuoteSyncAndGenDoc(component,returnId,slideDevName);
                            
                            /**** Commented by Navdeep ***/
                             /*  var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": returnId,
                                "slideDevName": slideDevName
                            });
                            navEvt.fire();*/
                            
                         
                        }
                        else if(endorsementType == 'Full Amendment'){
                            var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": result.oppId,
                                "slideDevName": 'detail'
                            });
                            navEvt.fire();
                            
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Success!",
                                "message": "Full Amendment successful!",
                                "type": "success"
                                
                            });
                            toastEvent.fire();
                        } 
                        else if(endorsementType == 'Flat Cancellation'){
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
                                                    /* Close the action panel and refresh view
                                                    $A.get("e.force:closeQuickAction").fire();
                                                    $A.get('e.force:refreshView').fire();*/
                                                    var navEvt = $A.get("e.force:navigateToSObject");
                                                    navEvt.setParams({
                                                        "recordId": result.oppId,
                                                        "slideDevName": 'detail'
                                                    });
                                                    navEvt.fire(); 
                                                    
                                                    var toastEvent = $A.get("e.force:showToast");
                                                    toastEvent.setParams({
                                                        "title": "Success!",
                                                        "message": endorsementType + " successful!",
                                                        "type": "success"
                                                    });
                                                    toastEvent.fire();
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
                            else if(endorsementType == 'Reinstatement'){
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
                                            
                                            /******* New Lines Added by Navdeep *******/
                                            
                                            var actionPopulateField = component.get("c.populateQuoteOption");
                                            actionPopulateField.setParams({
                                                quoteId :   result.cloneQuoteId
                                            });
                                            actionPopulateField.setCallback(this, function(responsePopulateField) {
                                                
                                                if(responsePopulateField.getState() == 'SUCCESS'){
                                                    
                                                    var actionSyncCallout = component.get("c.syncQuoteToMiddleware");
                                                    actionSyncCallout.setParams({
                                                         quoteId :   result.cloneQuoteId  
                                                    });
                                                    actionSyncCallout.setCallback(this, function(responseSyncallout) {
                                                        if(responseSyncallout.getState() == 'SUCCESS'){
                                                            
                                                            var actionBind = component.get("c.bindQuoteEndorsement");
                                                            actionBind.setParams({
                                                                quoteId : result.cloneQuoteId,
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
                                                                        var toastEvent = $A.get("e.force:showToast");
                                                                        toastEvent.setParams({
                                                                            "title": "Success!",
                                                                            "message": "Reinstatement Successfull!",
                                                                            "type": "success"
                                                                        });
                                                                        toastEvent.fire();
                                                                        // Close the action panel and refresh view
                                                                        var navEvt = $A.get("e.force:navigateToSObject");
                                                                        navEvt.setParams({
                                                                            "recordId": result.oppId,
                                                                            "slideDevName": 'detail'
                                                                        });
                                                                        navEvt.fire();
                                                                    }
                                                                }								
                                                            });
                                                            
                                                            $A.enqueueAction(actionBind);
                                                            
                                                            
                                                        }
                                                    });
                                                    $A.enqueueAction(actionSyncCallout);
                                                }
                                                
                                            });
                                            $A.enqueueAction(actionPopulateField);
                                       
                                        } else {
                                            component.set('v.error', msgError);
                                            this.hideSpinner(component);
                                        }
                                    }
                                });
                                $A.enqueueAction(actionRate);
                                
                            } 
                    }
                }
            } else {
                component.set('v.error', action.getError()[0].message);
                this.hideSpinner(component);
            }
        });
        
        $A.enqueueAction(action);
    },

    performSanctionSearchOnAccount : function(component,returnId,slideDevName){
        var action = component.get("c.validateSanctionCheckOnAccount");
        action.setParams({
            accountId : returnId,
            policyId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                if(result){
                    //proceed to Doc Generation
                    this.handleQuoteSyncAndGenDoc(component,returnId,slideDevName);
                }
                else{
                    //show toast msg and navigate to Account
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "Sanction on the Account needs to be Pass or Cleared.",
                        "type": "error"
                    });
                    toastEvent.fire();

                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": returnId,
                        "slideDevName": slideDevName
                    });
                    navEvt.fire();
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    /**** New Method Added by Navdeep ****/
    handleQuoteSyncAndGenDoc : function(component,returnId,slideDevName){
        console.log('handleQuoteSync')
        console.log('rec'+component.get("v.recordId"));
        var action = component.get("c.syncQuoteFunc");
        action.setParams({   
            policyId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //show success toast msg
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Insured Account Update Document has been generated successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
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
    
    
    getEndorsementReasons:function(component){
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
    
    getDefaultDate:function(){
        let today = new Date();
        return (today.getFullYear() + "-" + (today.getMonth()+1) + "-" + today.getDate());
    },
    getQuoteList : function(component, event, helper){
        component.set('v.quoteCloumns', [
            {label: 'Name', fieldName: 'Name', type: 'text'},
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
                    component.set("v.quoteData", response.getReturnValue().quoteList);
                    if(component.get("v.quoteData").length == 1){
                    	component.set("v.selectedQuoteList",component.get("v.quoteData")[0].Id);
                    }
                }else{
                	console.log("Error-->"+JSON.stringify(response.getError()));
                }            
            });
            $A.enqueueAction(action);
            },
            getAccountDetails : function(component, event, helper) {
                var action = component.get("c.getAccountDetails");
                action.setParams({
                    policyId : component.get("v.recordId")
                });
                action.setCallback(this, function(response) {
                    if (response.getState() == 'SUCCESS') {
                        var result = response.getReturnValue();
                        console.log('response',result);
                        component.set("v.accountData", result); 
                        var accountData = component.get("v.accountData");
                        console.log('accountData::'+accountData);
                        console.log('accountData::'+JSON.stringify(accountData));
                        component.set("v.accName", result.accName); 
                        component.set("v.accId", result.accId); 
                        component.set("v.kycStatusValue", result.kycStatus);
                        component.set("v.sanctionStatusValue", result.sanctionStatus);
                        component.set("v.billingStreet", result.billingStreet);
                        component.set("v.billingCity", result.billingCity);
                        component.set("v.postalCode", result.postalCode); 
                        component.set("v.stateCode", result.stateCode); 
                        component.set("v.countryCode", result.countryCode); 
                        component.set("v.sanctionDate", result.sanctionDate);
                        component.set("v.kycDate", result.kycDate);
                    }
                    else{
                        console.log('Error fetch account details');
                        component.set("v.billingStreet", ''); 
                        component.set("v.postalCode", ''); 
                        component.set("v.stateCode", ''); 
                        component.set("v.countryCode", ''); 
                    }
                });
                $A.enqueueAction(action);         
            },
            
            fetchAccDetails : function(component) {
                    component.set('v.mycolumns', [
                    {label: 'Name', fieldName: 'name', type: 'text'},
                    {label: 'Duns Number', fieldName: 'dunsNumber', type: 'text'},
                    {label: 'Address', fieldName: 'billingStreet', type: 'text'},
                    {label: 'Type', fieldName: 'type', type: 'text '}
                ]);
                component.set("v.isShowAccounts", true); 
            },
    
    handleSelectedAccount:function(component) {
        console.log('Helper: ');
        var action = component.get("c.updateAccount");
        action.setParams({
            accId : component.get("v.selectedAccId"),
            policyId : component.get("v.recordId"),
            accountData: component.get("v.accountData")
        });
        action.setCallback(this, function(response) {
            if (response.getState() == 'SUCCESS') {
                var result = response.getReturnValue();
                var returnId = result.resultAccId;
                var slideDevName ='detail';
                console.log('response',result);
                component.set('v.newAccId', result.resultAccId);  
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The account has been updated successfully.",
                    "type": "success"
                });
                toastEvent.fire();

                //check Sanction on Account before generating the documents
                this.performSanctionSearchOnAccount(component,returnId,slideDevName);
            }
            else{
                console.log('Error fetch account details');
            }
        });
        $A.enqueueAction(action);    
    },
    
    createAccount:function(component) {
        console.log('Helper: createNewAccount');
        this.showSpinner(component);
        this.updateAccountMap(component);
        var action = component.get("c.createNewAccount");
        action.setParams({
            accountData: component.get("v.accountData"),
            policyId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            if (response.getState() == 'SUCCESS') {
                var result = response.getReturnValue();
                var returnId = result.resultAccId;
                var slideDevName ='detail';
                console.log('response:: new Account::', result.resultAccId);
                component.set('v.newAccId', result.resultAccId);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "New account has been created successfully.",
                    "type": "success"
                });
                toastEvent.fire();

                //check Sanction on Account before generating the documents
                this.performSanctionSearchOnAccount(component,returnId,slideDevName);
            }
            else{
                console.log('Error creating new account...');
                this.hideSpinner(component);
                //result.error
            }
        });
        $A.enqueueAction(action); 
    },
    
    showErrorMsg : function(title, msg) {
        $A.get("e.force:showToast").setParams({
            "type": "error",
            "title": title,
            "message": msg 
        }).fire();
    },
        
        
    updateAccountMap:function(component) {
        var map = component.get("v.accountData");
        map['billingStreet'] = component.get("v.billingStreet");
        map['billingCity'] = component.get("v.billingCity");
        map['countryCode'] = component.get("v.countryCode");
        map['stateCode'] = component.get("v.stateCode");
        map['postalCode'] = component.get("v.postalCode");
        map['kycStatus'] = component.get("v.kycStatusValue");
        map['sanctionStatus'] = component.get("v.sanctionStatusValue");
        map['accName'] = component.get("v.accName");
        map['policyId'] = component.get("v.recordId");
        map['effDate'] = component.get("v.effectiveDate");
        map['endorsementReason'] = component.get("v.endorsementReason");
    },
    setKYCSanctionValues : function(component, event, helper) {
        component.set('v.sanctionStatusValue', "None");
        //component.set('v.kycStatusValue', "Not Required");
    },
    countryOptions : [
        { "value": "GG" ,"label": "Guernsey"},                                        
        { "value": "IM" ,"label": "Isle of Man"},                    
        { "value": "JE" ,"label": "Jersey"},
        { "value": "IE" , "label": "Northern Ireland"},
        { "value": "GB" , "label": "United Kingdom"},
    ],

    getCountryOptions: function() {       
        //get country options for insured account update
        console.log('countryOptions 323::'+JSON.stringify(this.countryOptions));
        return this.countryOptions;
    },

    preRateNbOrRenewalQuote : function(component, helper, resultObj, endorsementType) {
        //For Pre-Rating NB & Renewal Quote on Coverage/Full Cancel & Replace
        /*var clonedQuoteId = component.get("v.clonedQuoteId");
        var oppIdForNavigation = component.get("v.oppIdForNavigation");*/
        var successToastMsg = (endorsementType == 'Coverage Cancel & Replace') ? 'Coverage Cancel is successful.' : 'Full Cancel & Replace is successful.';
        var action = component.get("c.ratingQuoteRenewalOrNb");
        action.setParams({
            quoteId : resultObj.cloneQuoteId
        });
        action.setCallback(this, function(response){
            component.set("v.IsSpinner", false);
            var state = response.getState();
            console.log('state'+state);
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                console.log('result'+result);
                if(result.errors.length > 0){
                    var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "message": result.errors[0],
                            "type": "error"
                        });
                        toastEvent.fire();
                }
                else{
                    if(result.isSuccess){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": successToastMsg,
                            "type": "success"
                        });
                        toastEvent.fire();
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": resultObj.oppId,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();
                    }
                }
                
                
            }else{
                error = action.getError()[0].message;
                console.log("Failed with state: " + state +  ", error message: " + error);
            }
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
    }
        
})