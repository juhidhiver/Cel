({
    getcolumns: function (component) {
        component.set('v.columns', [
            { label: 'Rating Factor', fieldName: 'Name', type: 'text', editable: false },
            { label: 'Value', fieldName: 'Rating_Modifier_Value__c', type: 'text', editable: false },
            {
                label: 'Suggestion', fieldName: 'Eligibility_Status__c', type: 'text', editable: false, cellAttributes: {
                    class: { fieldName: 'textColor' } // textColor is a class for each record
                }
            },
        ]);
    },
    fetchData: function (component) {
        var action = component.get("c.getRatingModifiersForRiskHealth");
        action.setParams({
            "productName": component.get("v.prodName"),
            "opportunityId": component.get("v.oppId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                // add fieldColor to each obj
                data.map(record => {
                    var textColor = "";
                    switch (record.Eligibility_Status__c) {
                        case "Proceed": textColor = "Proceed"; break;
                        case "Proceed with Caution": textColor = "Caution"; break;
                        case "Stop!Decline!	": textColor = "Stop"; break;
                        default: textColor = ""; break;
                    }
                    return Object.assign(record, { textColor: textColor });
                })
                component.set('v.data', data);
                console.log('v.data:', data);
            }
            // error handling when state is "INCOMPLETE" or "ERROR"
        });
        $A.enqueueAction(action);
    }
})