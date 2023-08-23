({
    
    /* On the component Load this function call the apex class method,
     * which is return the list of RecordTypes of object
     * and set it to the lstOfRecordType attribute to display record Type values
     * on ui:inputSelect component.*/



    /* In this "createRecord" function, first we have call apex class method
     * and pass the selected RecordType values[label] and this "getRecTypeId"
     * apex method return the selected recordType ID.
     * When RecordType ID comes, we have call  "e.force:createRecord"
     * event and pass object API Name and
     * set the record type ID in recordTypeId parameter. and fire this event
     * if response state is not equal = "SUCCESS" then display message on various situations.
     */
    createRecord: function(component, event, helper) {
        component.set("v.isOpen", true);        
        var recordTypeId;
        if (component.get("v.recordId") != undefined) {
            return;
        } else {
            recordTypeId = component.get("v.pageReference").state.c__recordTypeId; //When coming from ChoosingRecordType e.g. Submission
            if (recordTypeId==null || recordTypeId==undefined){
                recordTypeId = component.get("v.pageReference").state.recordTypeId; // When + New Account from Account tab
            }
            component.set("v.recordTypeId", recordTypeId);
        }

        //plug  out from server call for recordtype
        if(!$A.util.isEmpty(component.get("v.countryCode"))){
            component.set("v.errorMessage",[]);
            var createRecordEvent = $A.get("e.force:createRecord");
            var objFieldValue = helper.initDefaultValues(component);
            console.log("@@@:" + JSON.stringify(objFieldValue));
            createRecordEvent.setParams({
                "entityApiName": 'Account',
                "recordTypeId": component.get("v.recordTypeId"), /*recordTypeId is assigned based on source from where new account is created.*/
                // "navigationLocation":"LOOKUP",
                "defaultFieldValues": objFieldValue,
                // Hang Lam - 08/28/2020- Fix bug 27728
                "panelOnDestroyCallback": function(event) {
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
						"recordId": component.get("v.recordId"),
						"isredirect":true
                    });
                    navEvt.fire()
                }
                // End - Hang Lam - 08/28/2020- Fix bug 27728
            });
            createRecordEvent.fire();
            $A.get('e.force:refreshView').fire();
        }else{
            var errorsMessage = component.get("v.errorMessage");
            //errorsMessage = [];
            //errorsMessage.push('Please select Country');
            component.set("v.errorMessage",errorsMessage);
        }
    },
    closeModal: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        $A.get("e.force:closeQuickAction").fire();
        var homeEvent = $A.get("e.force:navigateToObjectHome");
        homeEvent.setParams({
            "scope": "Account"
        });
        homeEvent.fire();
    },

    ///openmodal was here

    handleComponentEvent: function(component, event, helper) {
        const returnedObj = event.getParam("recordByEvent"); // does not work
        const accName = event.getParam("accountName"); // does not work


        if(returnedObj.SICCode != null && returnedObj.SICCode.length > 0) {
            component.set('v.DNBSICCode', returnedObj.SICCode[0].code);
            component.set('v.DNBSICDesc', returnedObj.SICCode[0].typCodeDescription);
        }
        /*Populate DNB fields on the account layout*/
        console.log('Event DB' + JSON.stringify(returnedObj));
        component.set('v.DNBCurrentAssets', returnedObj.CurrentAssets);
        component.set('v.DNBCurrentLiabilities', returnedObj.CurrentLiabilities);
        component.set('v.DNBDBRatingClassification', returnedObj.DBRatingClassification);
        component.set('v.DNBDunsNumber', returnedObj.DunsNumber);
        component.set('v.DNBNAICCode', returnedObj.NAICCode);
        component.set('v.DNBNetWorth', returnedObj.NetWorth);
        component.set('v.DNBSICCode', returnedObj.SICCode);
        component.set('v.DNBTotalAssets', returnedObj.TotalAssets);
        component.set('v.DNBTotalLiabilities', returnedObj.TotalLiabilities);
        component.set('v.DNBTotalRevenues', returnedObj.TotalRevenue);
        component.set('v.DNBWebsite', returnedObj.Website);
        //Extra fields from API 1.11.19
        component.set('v.DNBTypeofPartnership', returnedObj.TypeofPartnership);
        component.set('v.DNBLongTermDebt', returnedObj.LongTermDebt);
        component.set('v.DNBRetainedEarnings', returnedObj.RetainedEarnings);
        component.set('v.DNBShareholderEquity', returnedObj.ShareholderEquity);
        component.set('v.DNBNetIncome', returnedObj.NetIncome);
        component.set('v.DNBDateEstablished', returnedObj.DateEstablished);
        component.set('v.DNBOwnership', returnedObj.Ownership);
        component.set('v.DNBEmployeeNumbers', returnedObj.EmployeeNumbers);
        component.set('v.DNBReliabilityofEmployeeNumbers', returnedObj.ReliabilityofEmployeeNumbers);
        component.set('v.DNBNumberofEmployeescope', returnedObj.NumberofEmployeescope);
        console.log('Employee Scope' + returnedObj.NumberofEmployeescope);
        component.set('v.DNBCurrencyIsoCode', returnedObj.CurrencyIsoCode);
		component.set('v.DNBLastUpdate', returnedObj.LastUpdate);
		component.set("v.DNBCompositeCreditAppraisal",returnedObj.CompositeCreditAppraisal);
        component.set('v.DNBNoOfDirectors',returnedObj.NoOfDirectors);
		component.set('v.DNBRatingReason',returnedObj.RatingReason);
		component.set('v.DNBCreditScore',returnedObj.CreditScore);
       	//component.set('v.DNBYearStarted',returnedObj.DateEstablished);
 
    },

    doInit: function(component, event, helper) {
        component.set("v.isOpen", true);
        helper.openModal(component, event);
        helper.fetchPickListVal(component, 'Country_Code__c', 'accCountryCode');

    },

    /* On country code selection set the value to component attribute and pass it to child component AutoComplete */
    /*  */
    onPicklistChange: function(component, event, helper) {
        // get the value of select option
        component.set('v.countryCode',event.getSource().get("v.value"));
    },

    /* On address search blur, set the value to component attribute that it can be passed to child component AutoComplete from where it will be sent to server controller */
    /* OBSOLETE */
    onAddressSearch: function (component, event, helper){
        var inputCmp = component.find("accAddressLine1");
        component.set('v.addressLine1',inputCmp.get('v.value'));
    },

    /* OBSOLETE */
    onChoosingAddress : function(component, event, helper) {
        console.log('@@@ -------------- AddLocationCmpController.onChoosingAddress --------------');
        var data = event.getParam("data");
        console.log('@@@ location choosen info= ' + JSON.stringify(data));

        var action = component.get("c.searchPlace");
        action.setParams({
            'placeId' : data.placeId
        });

        action.setCallback(this, function(response){
            var state = response.getState();

            if(state === "SUCCESS"){
                var result = response.getReturnValue();
                console.log(result);
                if(result){
                    var data = JSON.parse(result);

                    ///component.set('v.newLocationRec.Address__c', data.address);
                    component.set('v.address2', data.address); //this sets the selected address on UI strike lookup
                    component.set('v.addressLocality', data.city); // input for API
                    component.set('v.addressLine1', data.address);
                    component.set('v.stateCode', data.stateCode); // input for API
                    component.set('v.postalCode', data.postalCode); // input for API
                    component.set('v.countryCode', data.countryCode); // input for API
                }
            } else {
                var errorMsg = action.getError()[0].message;
                console.log('@@@ Add Location failed, errorMsg= ' + errorMsg);
                component.set("v.error", errorMsg);
            }
        });
        $A.enqueueAction(action);
    },

    /*OBSOLETE*/
    onRemovingAddress : function(component, event, helper) {
        console.log('@@@ -------------- AddLocationCmpController.onRemovingAddress --------------');
        // Set value
        ///component.set('v.address2', null); //this sets the selected address on UI strike lookup
        component.set('v.addressLine1', null);
        component.set('v.addressLocality', null); // input for API
        component.set('v.stateCode', null); // input for API
        component.set('v.postalCode', null); // input for API
        component.set('v.countryCode', null); // input for API
    },
    testonblur: function(component, event, helper) {
        console.log('111111111111111111111111');
    },
    handleSuccess: function(component, event, helper) { 
        console.log("@@@create success: " + event.getParam("id"));
    },
})