({
	doInit : function(component, event, helper){
		if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(success);
            function success(position) {
                 var lat = position.coords.latitude;
                 //component.set("v.userLatitude",lat);
                 var long = position.coords.longitude;
                 //component.set("v.userLongitude",long);
				 var newLocationRec = component.get('v.newLocationRec'); 
				 newLocationRec.Geolocation__Latitude__s = lat;
				 newLocationRec.Geolocation__Longitude__s = long;
				 component.set("v.newLocationRec",newLocationRec);
				 console.log('@@@ newLocationRec= ' + JSON.stringify(newLocationRec));
		 }
		} else {
				  error('Geo Location is not supported');
		}

		console.log('@@@ location= ' + window.location.href);  		
  		//var sObjectName = component.get('v.sObjectName'); // Comment by Quan Tran - unused variable
  		// Quan Tran on 6/21/2019
  		var getUsageTypes = component.get("c.getUsageTypePickList");
		getUsageTypes.setCallback(this, function(response1){			
            if(response1.getState() === "SUCCESS"){
            	component.set("v.usageTypes", response1.getReturnValue());
				var getCountryPickList = component.get("c.getCountryPickList");
				getCountryPickList.setCallback(this, function(response2){			
					if(response2.getState() === "SUCCESS"){						
						component.set("v.countries", response2.getReturnValue());
					}
				});
				$A.enqueueAction(getCountryPickList);
            }
        });
    	$A.enqueueAction(getUsageTypes); 
    	// End 
	},

	cancelAddLocation : function(component, event, helper) {
		//var isFromNewButton = component.get('v.isFromNewButton');
		if (!component.get("v.parentId")) {
			var homeEvent = $A.get("e.force:navigateToObjectHome");
		    homeEvent.setParams({
		        "scope": 'Location__c'
		    });
		    homeEvent.fire();
		} else {
	        var addLocationEvent = component.getEvent("addLocationEvent");
	        addLocationEvent.setParams({ "isOpenAddLocationForm": false });
	        addLocationEvent.fire();
		}
	},

	saveLocation : function(component, event, helper){
		// check location
		var location = component.get("v.newLocationRec");
		var errorFields = [];

		var addressClicked = component.get('v.address');
		var addressInput = component.find("AddressLookup").find("lookupInput").getElement().value;
		console.log('@@@ addressClicked= ' + addressClicked);
		console.log('@@@ addressInput= ' + addressInput);
		console.log('@@@ location.Country__c= ' + location.Country__c);
		if(!addressClicked && !addressInput){
			errorFields.push("Address");
		} else if (!addressClicked && addressInput) {
			component.set('v.newLocationRec.Address__c', addressInput);
		}

		if(!location.City__c) errorFields.push("City");
		if(!location.Postal_Code__c) errorFields.push("Postal code");
		if(!location.Country__c) errorFields.push("Country");
		if (errorFields.length > 0) {
			component.set('v.error', 'Required fields are missing: ' + errorFields.join(', '));
			return;
		}

		console.log('@@@ Usage type= ' + component.get("v.usageType"));
		location.City__c = location.City__c;
		location.Address__c = location.Address__c;

		console.log('@@@ >> argLocation= ' + JSON.stringify(location));
		console.log('@@@ >> parentId= ' + component.get("v.parentId"));
		console.log('@@@ >> objAPIName= ' + component.get("v.objAPIName"));
		console.log('@@@ >> parentAPIName= ' + component.get("v.parentAPIName"));
		console.log('@@@ >> locationAPIName= ' + component.get("v.locationAPIName"));
		console.log('@@@ >> usageType= ' + component.get("v.usageType"));
		console.log('@@@ >> isPrimaryLoc= ' + component.get('v.isPrimaryLoc'));
		
		component.set('v.error', null);
		var action = component.get("c.addNewLocation");
        console.log(JSON.stringify(location));
		
		action.setParams({
			'argLocation' : location,
			'parentId' : !component.get("v.parentId") ? '' : component.get("v.parentId"),
			'objAPIName' : !component.get("v.objAPIName") ? '' : component.get("v.objAPIName"),
			'parentAPIName' : !component.get("v.parentAPIName") ? '' : component.get("v.parentAPIName"),
			'locationAPIName' : !component.get("v.locationAPIName") ? '' : component.get("v.locationAPIName"),
			'usageType' : component.get("v.usageType"),
			'isPrimaryLoc' : component.get('v.isPrimaryLoc'),
		});
		action.setCallback(this, function(response){
			var state = response.getState();
			console.log('@@@ state= ' + state);
            if(state === "SUCCESS"){
            	console.log("@@@ Add Location succesfully!");
            	var result = response.getReturnValue();
            	console.log("@@@ result= " + result);
            	
            	if (!component.get("v.parentId") && result) {
            		$A.get("e.force:navigateToSObject").setParams({
				      "recordId": result
				    }).fire();
            	} else if (component.get("v.parentId")) {
	            	var addLocationEvent = component.getEvent("addLocationEvent");
			        addLocationEvent.setParams({ "isOpenAddLocationForm": false});
			        addLocationEvent.fire();
            	}
            } else {
            	var errorMsg = action.getError()[0].message;
            	console.log('@@@ Add Location failed, errorMsg= ' + errorMsg);
            	component.set("v.error", errorMsg);
            }
            $A.get('e.force:refreshView').fire();
        });
    	$A.enqueueAction(action);
	},	
	keyCheck : function(component, event, helper){
		// check location
		var location = component.get("v.newLocationRec");
		console.log("location_keyCheck" + location);
	},
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

			        component.set('v.newLocationRec.Address__c', data.address);
			        component.set('v.address', data.address);
					component.set('v.newLocationRec.City__c', data.city);
					component.set('v.newLocationRec.State_Province__c', data.state);
					component.set('v.newLocationRec.State_Code__c', data.stateCode);
					component.set('v.newLocationRec.Postal_Code__c', data.postalCode);
					component.set('v.newLocationRec.Country__c', data.country);
					component.set('v.newLocationRec.Country_Code__c', data.countryCode);
					component.set('v.newLocationRec.Geolocation__Latitude__s', data.latitude);
					component.set('v.newLocationRec.Geolocation__Longitude__s', data.longitude);
					component.set('v.newLocationRec.County__c', data.county);
            	}
            } else {
            	var errorMsg = action.getError()[0].message;
            	console.log('@@@ Add Location failed, errorMsg= ' + errorMsg);
            	component.set("v.error", errorMsg);
            }
        });
    	$A.enqueueAction(action);
	},

	onRemovingAddress : function(component, event, helper) {
		console.log('@@@ -------------- AddLocationCmpController.onRemovingAddress --------------');
		// Set value
		component.set('v.newLocationRec.Address__c', null);
		component.set('v.newLocationRec.City__c', null);
		component.set('v.newLocationRec.State_Province__c', null);
		component.set('v.newLocationRec.State_Code__c', null);
		component.set('v.newLocationRec.Postal_Code__c', null);
		component.set('v.newLocationRec.Country__c', null);
		component.set('v.newLocationRec.Country_Code__c', null);
		component.set('v.newLocationRec.Geolocation__Latitude__s', null);
		component.set('v.newLocationRec.Geolocation__Longitude__s', null);
	},

})