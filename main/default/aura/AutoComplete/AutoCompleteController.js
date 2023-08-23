({
    searchHandler : function (component, event, helper) {

        const searchString = event.target.value;

        if (searchString.length >= 3) {
            component.set("v.loaded",false);
            component.set("v.inputValue",searchString);
            //End
            //Ensure that not many function execution happens if user keeps typing
            if (component.get("v.inputSearchFunction")) {
                clearTimeout(component.get("v.inputSearchFunction"));
            }
            var inputTimer = setTimeout($A.getCallback(function () {
                console.log("@@@searchHandler");
                helper.searchRecords(component, searchString);
            }), 1000);
            component.set("v.inputSearchFunction", inputTimer);
        } else{
            component.set("v.results", []);
        }
    },

    optionClickHandler : function (component, event, helper) {
        const selectedId = event.target.closest('li').dataset.id;
        const selectedValue = event.target.closest('li').dataset.value;
        component.set("v.inputValue", selectedValue);
        component.set("v.inputValue", selectedValue);
        component.set("v.selectedOption", selectedId);
    },

    clearOption : function (component, event, helper) {
        component.set("v.results", []);
        component.set("v.inputValue", "");
        component.set("v.selectedOption", "");
        component.set("v.address", null);
    },
    
    handleComponentEvent : function (component, event, helper) {
        console.log("Fire Component Event");
        component.set("v.loaded",false);
        // End
        const returnedObj = event.getParam("recordByEvent");
        console.log('2222222:' + returnedObj.address.countryISOAlpha2Code);
        component.set("v.address", returnedObj.address);
        const selectedId = returnedObj.id;
        const selectedValue = returnedObj.primaryName;
        component.set("v.inputValue", selectedValue);

        component.set("v.openDropDown", false); ///error: "openDropDown' of component 'markup"
        component.set("v.selectedOption", returnedObj);
        //Call second api
        console.log('returnedObj.duns:' + returnedObj.duns);
        helper.getCorporateIntel(component,returnedObj.duns);
        //end
    }
    
})