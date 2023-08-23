({
    //NOT CALLED. FOR Account country
    fetchPickListVal: function(component, fieldName, elementId) {
        var action = component.get('c.getselectOptions');
        action.setParams({
            "objObject": component.get("v.objInfo"),
            "fld": fieldName
        });
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = response.getReturnValue();

                if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "--- None ---",
                        value: ""
                    });
                }
                for (var i = 0; i < allValues.length; i++) {
                    opts.push({
                        class: "optionClass",
                        label: allValues[i][0],
                        value: allValues[i][1]
                    });
                }
                component.find(elementId).set("v.options", opts);
            }
        });
        $A.enqueueAction(action);
    },

    openModal: function(component, event) {
        // set "isOpen" attribute to true to show model box
        component.set("v.isOpen", true); ///now called on doInit
    },
    initDefaultValues: function(component) {
        var objFieldValue = {};
       if(component.get('v.address')) {
           objFieldValue['Name'] = component.get("v.address").name;
       } else {
           if(component.get("v.inputValue")) {
               objFieldValue['Name'] = component.get("v.inputValue");
           }
       }
       
       if(component.get('v.address') && component.get("v.address").streetAddressLine1) {
           objFieldValue['BillingStreet'] = component.get("v.address").streetAddressLine1;
       }
       
       if(component.get('v.address') && component.get('v.address').addressLocality) {
           objFieldValue['BillingCity'] = component.get("v.address").addressLocality;
       }
       
       if(component.get('v.address') && component.get('v.address').addressRegion) {
           objFieldValue['BillingStateCode'] = component.get("v.address").addressRegion;
       }
       
       if(component.get('v.address') && component.get('v.address').postalCode) {
           objFieldValue['BillingPostalCode'] = component.get("v.address").postalCode;
       }
       
       if(component.get('v.address') && component.get('v.address').postalCode) {
           objFieldValue['BillingPostalCode'] = component.get("v.address").postalCode;
       }
       
       objFieldValue['BillingCountryCode'] = component.get("v.countryCode");
       
       if(component.get('v.DNBCurrentAssets')) {
           objFieldValue['Current_Assets__c'] = component.get('v.DNBCurrentAssets');
       }
       if(component.get('v.DNBCurrentLiabilities')) {
           objFieldValue['Current_Liabilities__c'] = component.get('v.DNBCurrentLiabilities');
       }
       
       if(component.get('v.DNBDBRatingClassification')) {
           objFieldValue['D_B_Rating_Classification__c'] = component.get('v.DNBDBRatingClassification');
       }
       
       if(component.get('v.DNBDunsNumber')) {
           objFieldValue['Duns_Number__c'] = component.get('v.DNBDunsNumber');
       }
       if(component.get('v.DNBNetWorth')) {
           objFieldValue['Net_Worth__c'] = component.get('v.DNBNetWorth');
       }
       
       if(component.get('v.DNBSICCode')) {
           objFieldValue['Sic'] = component.get('v.DNBSICCode')[0].code;
       }
       if(component.get('v.DNBSICDesc')) {
        objFieldValue['SicDesc'] = component.get('v.DNBSICDesc');
    }
       if(component.get('v.DNBTotalAssets')) {
           objFieldValue['Total_Assets__c'] = component.get('v.DNBTotalAssets');
       }
       if(component.get('v.DNBTotalLiabilities')) {
           objFieldValue['Total_Liabilities__c'] = component.get('v.DNBTotalLiabilities');
       }
       if(component.get('v.DNBTotalRevenues')) {
           objFieldValue['Total_Revenues__c'] = component.get('v.DNBTotalRevenues');
       }
       if(component.get('v.DNBWebsite')) {
           objFieldValue['Website'] = component.get('v.DNBWebsite');
       }
       if(component.get('v.DNBLongTermDebt')) {
           objFieldValue['Long_Term_Debt__c'] = component.get('v.DNBLongTermDebt');
       }
       if(component.get('v.DNBRetainedEarnings')) {
           objFieldValue['Retained_Earnings__c'] = component.get('v.DNBRetainedEarnings');
       }
       if(component.get('v.DNBNetIncome')) {
           objFieldValue['Net_Income__c'] = component.get('v.DNBNetIncome');
       }
        if(component.get('v.DNBCompositeCreditAppraisal')) {
            objFieldValue['Composite_Credit_Appraisal__c'] = component.get('v.DNBCompositeCreditAppraisal');
        }
        if (component.get('v.DNBDateEstablished') && component.get('v.DNBDateEstablished').length > 4) {
            console.log('Date Started -->' + component.get('v.DNBDateEstablished'));
            objFieldValue['Date_Started__c'] = component.get('v.DNBDateEstablished');
        }
       //if(component.get('v.DNBDateEstablished')) {
           //objFieldValue['Date_Established__c'] = component.get('v.DNBDateEstablished');
       //}
       if(component.get('v.DNBOwnership')) {
           objFieldValue['Ownership'] = component.get('v.DNBOwnership');
       }
       if(component.get('v.DNBEmployeeNumbers')) {
           objFieldValue['NumberOfEmployees'] = component.get('v.DNBEmployeeNumbers');
       }
       if(component.get('v.DNBReliabilityofEmployeeNumbers')) {
           objFieldValue['Number_of_Employees_Reliability__c'] = component.get('v.DNBReliabilityofEmployeeNumbers');
       }
       if(component.get('v.DNBNumberofEmployeescope')) {
           //objFieldValue['Number_of_employees_scope__c'] = component.get('v.DNBNumberofEmployeescope');
           objFieldValue['Number_of_Employees_Scope__c'] = component.get('v.DNBNumberofEmployeescope');
       }
       //if(component.get('v.DNBCurrencyIsoCode')) {
           //objFieldValue['CurrencyIsoCode'] = component.get('v.DNBCurrencyIsoCode');
       //}
       if(component.get('v.DNBLastUpdate')) {
           objFieldValue['Last_D_B_Refresh__c'] = component.get('v.DNBLastUpdate');
       }
        if (component.get('v.DNBNoOfDirectors')) {
            objFieldValue['Number_Of_Directors__c'] = component.get('v.DNBNoOfDirectors');
        }
        if (component.get('v.DNBRatingReason')) {
            objFieldValue['Rating_Reason__c'] = component.get('v.DNBRatingReason');
        }
        if (component.get('v.DNBCreditScore')) {
            objFieldValue['Credit_Score__c'] = component.get('v.DNBCreditScore');
        }
       return objFieldValue;
   }
})