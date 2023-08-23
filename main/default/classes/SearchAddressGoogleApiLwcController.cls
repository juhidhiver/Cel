public with sharing class SearchAddressGoogleApiLwcController {
	@AuraEnabled
	public static String addNewLocation( String parentId, String objAPIName,String parentAPIName, String locationAPIName, String usageType, Boolean isPrimaryLoc) {
		/*
        String result = '';
        //Location__c argLocation
		String strSQL = buildLocationSQL(argLocation);
		List<Location__c> existLocation = Database.query(strSQL);
		String locationId = '';
        try{
			if(!existLocation.isEmpty()){
				locationId = existLocation[0].Id;
			}else{
				//insert argLocation;
				//locationId = argLocation.Id;
			}
			if(!String.isBlank(parentId)){
				// create opportunity Location
				sObject sObj = Schema.getGlobalDescribe().get(objAPIName).newSObject();
				sObj.put(parentAPIName, parentId);
				sObj.put(locationAPIName, locationId);
				sObj.put('Usage_Type__c', usageType);
				//Long Ly - 06/12/2019 - Add the Primary flag on the Quote Location new record form
				sObj.put('Primary_Location__c', isPrimaryLoc);
				//End
				insert sObj;
			}
        }catch(Exception ex){
			return null;
		}
		return locationId;
	*/
		return null;
	}

	/*private static String buildLocationSQL(Location__c argLocation){
		String selectQuery = 'SELECT Id, Address__c, City__c, State_Province__c, Postal_Code__c, Country__c, Geolocation__latitude__s, Geolocation__longitude__s FROM Location__c';

		List<String> condition1QueryList = new List<String>();
		condition1QueryList.add('Address__c = \'' + String.escapeSingleQuotes(argLocation.Address__c) + '\'');
		condition1QueryList.add('City__c = \'' + String.escapeSingleQuotes(argLocation.City__c) + '\'');
		condition1QueryList.add('State_Province__c = \'' + String.escapeSingleQuotes(argLocation.State_Province__c) + '\'');
		condition1QueryList.add('Postal_Code__c = \'' + String.escapeSingleQuotes(argLocation.Postal_Code__c) + '\'');
		condition1QueryList.add('Country__c = \'' + String.escapeSingleQuotes(argLocation.Country__c) + '\'');
		condition1QueryList.add('County__c = \'' + String.escapeSingleQuotes(argLocation.County__c) + '\'');

		String resultStr = selectQuery + ' WHERE ' + String.join(condition1QueryList, ' AND ');
		resultStr += ' LIMIT 1';
		system.debug(resultStr);
		return resultStr;
	}

	@AuraEnabled
	public static List<OpptionWapper> getCountryPickList(){
		List<OpptionWapper> options = getPicklistValues(new Location__c(), 'Country__c');
		return options;
	}

	// Quan Tran on 6/21/2019
	@AuraEnabled
	public static List<OpptionWapper> getUsageTypePickList(){
		//List<OpptionWapper> options = getPicklistValues(new Quote_Location__c(), 'Usage_Type__c');
		//return options;
		return null;
	}
	// End

	private static List<OpptionWapper> getPicklistValues(SObject obj, String fld){
		List<OpptionWapper> options = new list<OpptionWapper>();
		// Get the object type of the SObject.
		Schema.sObjectType objType = obj.getSObjectType();
		// Describe the SObject using its object type.
		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
		// Get a map of fields for the SObject
		map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
		// Get the list of picklist values for this field.
		list<Schema.PicklistEntry> values =
	    fieldMap.get(fld).getDescribe().getPickListValues();
		// Add these values to the selectoption list.
		for (Schema.PicklistEntry a : values)
		{
			OpptionWapper option = new OpptionWapper(a.getLabel(), a.getValue());
			if(a.isDefaultValue()){
				option.isSelected = true;
			}
			options.add(option);
		}
		return options;

	}
	*/
	@AuraEnabled
	public static LocationResponse searchLocation(String searchTerm) {
		try {
			System.debug('Search Term ' + searchTerm);
			LocationResponse locationResponse = new LocationResponse();

			//API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Google_API_Nearby');
			//if(apiSetting == null) return null;
			String baseUri = ('https://maps.googleapis.com/' + 'maps/api/place/autocomplete/json?');
			//String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
			String baseUriParams = '';
			baseUriParams += 'input=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8');
			baseUriParams += '&key=' + 'AIzaSyBVVho8_KfyX4dU-h9ikoLzLbKDI6lVV4g';
			String baseUriFull = baseUri + baseUriParams;

			HttpRequest req = new HttpRequest();
			req.setEndpoint(baseUriFull);
			req.setMethod('GET');
			Http h = new Http();
			HttpResponse res = h.send(req);
			if(res.getStatusCode() == 200) {
				locationResponse = (LocationResponse) JSON.deserialize(res.getBody(), LocationResponse.class);
			}else{
				System.debug( 'Status Code ' +  res.getStatusCode());
				System.debug( 'Status Code ' +  res.getBody());

			}
		
			return locationResponse;

		} catch (Exception ex) {
			return null;
		}
	}

	@AuraEnabled
	public static DisplayResult searchPlace(String placeId) {

		try {
			DisplayResult displayResult = new DisplayResult();

			//API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Google_API_Place');
			//if(apiSetting == null) return null;
			String apiSetting = 'AIzaSyBVVho8_KfyX4dU-h9ikoLzLbKDI6lVV4g';
			String baseUri = ('https://maps.googleapis.com/' + 'maps/api/place/details/json?');
			String baseUriParams = '';
			baseUriParams += 'placeid=' + EncodingUtil.urlEncode(placeId, 'UTF-8');
			baseUriParams += '&key=' + apiSetting;

			String baseUriFull = baseUri + baseUriParams;

			HttpRequest req = new HttpRequest();
			req.setEndpoint(baseUriFull);
			req.setMethod('GET');
			//req.setTimeout(Integer.valueOf('Google_API'));
			req.setTimeout(2000);

			Http h = new Http();
			HttpResponse res = h.send(req);
 System.debug('Res Body'+res.getBody());
			System.debug(JSON.deserializeUntyped(res.getBody()) );
			   
			if(res.getStatusCode() == 200) {
				AddressResponse addressResponse = (AddressResponse) JSON.deserialize(res.getBody(), AddressResponse.class);

				if (addressResponse.status == 'OK' && addressResponse.result != null) {
					// Fill address, city, state, postal code, country
					displayResult = getLocationDetailedInformation(addressResponse.result.address_components, displayResult);
					// Fill full formatted address (show in second line when displaying search result)
					displayResult.addressFull = addressResponse.result.formatted_address;
					// Fill latitude and longitude and uniqueKey
					displayResult.latitude = (addressResponse.result.geometry.location.lat != null) ? Double.valueOf(addressResponse.result.geometry.location.lat) : null;
					displayResult.longitude = (addressResponse.result.geometry.location.lng != null) ? Double.valueOf(addressResponse.result.geometry.location.lng) : null;
					displayResult.uniqueKey = displayResult.latitude + ':' + displayResult.longitude;
				}
			}

			return displayResult;

		} catch (Exception ex) {
        
            System.debug('Error Message'+ex.getMessage());
			return null;
		}
	}

	private static DisplayResult getLocationDetailedInformation(List<AddressElement> addElements, DisplayResult result) {
		List<String> returnAddress = new List<String>();
		if (!addElements.isEmpty()) {
			for (AddressElement addElement : addElements) {

				if (addElement.types == null || addElement.types.isEmpty()) continue;
				String longName = String.isBlank(addElement.long_name) ? null : addElement.long_name;
				String shortName = String.isBlank(addElement.short_name) ? null : addElement.short_name;

				if (addElement.types.contains('country')) {
					result.country = longName;
					result.countryCode = shortName;
				} else if (addElement.types.contains('postal_code')) {
					result.postalCode = longName;

				} else if (addElement.types.contains('administrative_area_level_1')) {
					result.state = longName;
					result.stateCode = shortName;

				} else if (addElement.types.contains('administrative_area_level_2')) {
					if(String.isNotBlank(shortName)) {
						shortName = shortName.replace(' County', '');
						result.county = shortName;
					}
				} else if (addElement.types.contains('locality')) {
					result.city = longName;

				} else if (addElement.types.contains('street_number')
						|| addElement.types.contains('route')
						|| addElement.types.contains('premise')) {
					returnAddress.add(longName);
				}
			}
		}
		if (String.isBlank(result.city)) result.city = result.state;
		if (!returnAddress.isEmpty()) result.address = String.join(returnAddress, ' ');
		return result;
	}

	public class OpptionWapper {
		@AuraEnabled public String label 		{get; set;}
		@AuraEnabled public String value 		{get; set;}
		@AuraEnabled public Boolean isSelected 	{get; set;}
		public OpptionWapper(String argLabel, String argValue) {
			label = argLabel;
			value = argValue;
			isSelected = false;
		}
	}

	public class DisplayResult {
		@AuraEnabled
		public String addressFull 	{get; set;}
		@AuraEnabled
		public String address 		{get; set;}
		@AuraEnabled
		public String city 			{get; set;}
		@AuraEnabled
		public String state 		{get; set;}
		@AuraEnabled
		public String stateCode		{get; set;}
		@AuraEnabled
		public String postalCode 	{get; set;}
		@AuraEnabled
		public String country 		{get; set;}
		@AuraEnabled
		public String countryCode	{get; set;}
		@AuraEnabled
		public Double longitude 	{get; set;}
		@AuraEnabled
		public Double latitude 		{get; set;}
		@AuraEnabled
		public String uniqueKey 	{get; set;}
		@AuraEnabled
		public String county		{get; set;}
	}

	// ------------------------------ Google API wrapper class ----------------------------------- //
	public class LocationResponse {
		@AuraEnabled
		public List<LocationResult> predictions	{get; set;}
		@AuraEnabled
		public String status 					{get; set;}
	}

	public class LocationResult {
		@AuraEnabled
		public String description 				{get; set;}
		@AuraEnabled
		public String place_id 					{get; set;}
	}

	public class AddressResponse {
		public AddressResult result			{get; set;}
		public String status 				{get; set;}
	}

	public class AddressResult {
		public List<AddressElement> address_components	{get; set;}
		public String formatted_address 				{get; set;}
		public GeometryElement geometry 				{get; set;}
	}

	public class AddressElement {
		public String long_name 		{get; set;}
		public String short_name 		{get; set;}
		public Set<String> types 		{get; set;}
	}

	public class GeometryElement {
		public LocationElement location {get; set;}
	}

	public class LocationElement {
		public Double lat 	{get; set;}
		public Double lng 	{get; set;}
	}
}