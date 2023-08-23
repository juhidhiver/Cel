/*************************************************
* Class Name: AddLocationController
* Author: Binh Dang
* Created: 
* Description: Handle add lcoation from SF       
** Revision: Long Ly / 20 June 2019 / Add county field in creating form  
*************************************************/
public with sharing class AddLocationController {
	/*************************************************
    * Method Name: addNewLocation
    * Author: Long Ly
    * Decription: Adding new location
    * Params: Location__c argLocation, String parentId, String objAPIName,String parentAPIName, String locationAPIName, String usageType, Boolean isPrimaryLoc
    * Return: New Location ID
    * Exceptions:
    * Revision: 
     *************************************************/ 
	@AuraEnabled
	public static String addNewLocation(Location__c argLocation, String parentId, String objAPIName,String parentAPIName, String locationAPIName, String usageType, Boolean isPrimaryLoc) {
		String result = '';
		String strSQL = buildLocationSQL(argLocation);
		List<Location__c> existLocation = Database.query(strSQL);
		String locationId = '';
		
		try {
			if(!existLocation.isEmpty()){
				locationId = existLocation[0].Id;
			}else{
				insert argLocation;
				locationId = argLocation.Id;
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
			
		} catch(Exception ex){
			throw new AuraHandledException(CommonUtil.getExceptionMessage(ex) + '' + ex.getLineNumber());
		}
		return locationId;
	}

	/*************************************************
    * Method Name: buildLocationSQL
    * Author: Long Ly
    * Decription: Build query to select Location object
    * Params: 
    * Return: String of Query 
    * Exceptions:
    * Revision: 
     *************************************************/
	private static String buildLocationSQL(Location__c argLocation){
		String selectQuery = 'SELECT Id, Address__c, City__c, State_Province__c, Postal_Code__c, Country__c, Geolocation__latitude__s, Geolocation__longitude__s FROM Location__c';
		
		List<String> condition1QueryList = new List<String>();
		condition1QueryList.add('Address__c = \'' + String.escapeSingleQuotes(argLocation.Address__c) + '\'');
		condition1QueryList.add('City__c = \'' + String.escapeSingleQuotes(argLocation.City__c) + '\'');
		condition1QueryList.add('State_Province__c = \'' + String.escapeSingleQuotes(argLocation.State_Province__c) + '\'');
		condition1QueryList.add('Postal_Code__c = \'' + String.escapeSingleQuotes(argLocation.Postal_Code__c) + '\'');
		condition1QueryList.add('Country__c = \'' + String.escapeSingleQuotes(argLocation.Country__c) + '\'');

		// 07-17-2019 Duy Tran fix 1820-1822 Jefferson Place LLC  APP19193128 - Query
		if(String.isNotBlank(argLocation.County__c)) {
			condition1QueryList.add('County__c = \'' + String.escapeSingleQuotes(argLocation.County__c) + '\'');
		}

		String resultStr = selectQuery + ' WHERE ' + String.join(condition1QueryList, ' AND ');
		resultStr += ' LIMIT 1';
		//system.debug(resultStr);
		return resultStr;
	}

	/*************************************************
    * Method Name: getCountryPickList
    * Author: Long Ly
    * Decription: Generate a location picklist
    * Params: 
    * Return: Location picklist 
    * Exceptions:
    * Revision: 
     *************************************************/
	@AuraEnabled
	public static List<OpptionWapper> getCountryPickList(){
		List<OpptionWapper> options = getPicklistValues(new Location__c(), 'Country__c');
		return options;
	}

	/*************************************************
    * Method Name: getUsageTypePickList
    * Author: Quan Tran
    * Decription: Generate a UseType picklist
	* Date: 6/21/2019
    * Params: 
    * Return: UseType picklist 
    * Exceptions:
    * Revision: 
     *************************************************/
	@AuraEnabled
	public static List<OpptionWapper> getUsageTypePickList(){
		List<OpptionWapper> options = getPicklistValues(new Quote_Location__c(), 'Usage_Type__c');
		return options;
	}	
	// End 

	/*************************************************
    * Method Name: getPicklistValues
    * Author: Long Ly
    * Decription: Generate a picklist value
    * Params: SObject obj, String fld 
    * Return: a picklist of an object
    * Exceptions:
    * Revision: 
     *************************************************/
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
	
	/*************************************************
    * Method Name: searchLocation
    * Author: Binh Dang
    * Decription: Search a location from Google Map
    * Params: searchTerm 
    * Return: LocationResponse
    * Exceptions:
    * Revision: 
     *************************************************/
	public static LocationResponse searchLocation(String searchTerm) {
		try {
            LocationResponse locationResponse = new LocationResponse();

			API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Google_API_Nearby');
			if(apiSetting == null) return null;

			String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
			String baseUriParams = '';  
            
			baseUriParams += 'input=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8');
			baseUriParams += '&key=' + apiSetting.API_Key__c;

	        String baseUriFull = baseUri + baseUriParams;
	        
			HttpRequest req = new HttpRequest();
	        req.setEndpoint(baseUriFull);
	        req.setMethod(apiSetting.Method__c);
	        req.setTimeout(Integer.valueOf(Label.ApiTimeOut));

	        Http h = new Http();
	        HttpResponse res = h.send(req);
	       
	        if(res.getStatusCode() == 200) {
	        	locationResponse = (LocationResponse) JSON.deserialize(res.getBody(), LocationResponse.class);
	        }
        
            return locationResponse;
            
        } catch (Exception ex) {
           	return null;
        }
	}

	/*************************************************
    * Method Name: searchPlace
    * Author: Binh Dang
    * Decription: Get  a location detail from Google Map base on PlaceId
    * Params: PlaceId 
    * Return: full location String
    * Exceptions:
    * Revision: 
     *************************************************/
	@AuraEnabled
	public static String searchPlace(String placeId) {
		
		try {
            DisplayResult displayResult = new DisplayResult();
               
			API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Google_API_Place');
			if(apiSetting == null) return null;

			String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
			String baseUriParams = '';  
      		baseUriParams += 'placeid=' + EncodingUtil.urlEncode(placeId, 'UTF-8');
			baseUriParams += '&key=' + apiSetting.API_Key__c;

	        String baseUriFull = baseUri + baseUriParams;
	                    
			HttpRequest req = new HttpRequest();
	        req.setEndpoint(baseUriFull);
	        req.setMethod(apiSetting.Method__c);
	        req.setTimeout(Integer.valueOf(Label.ApiTimeOut));

	        Http h = new Http();
	        HttpResponse res = h.send(req);
	     
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

            return JSON.serialize(displayResult);
            
        } catch (Exception ex) {
           	return '';
        }
	}

	/*************************************************
    * Method Name: getLocationDetailedInformation
    * Author: Binh Dang
    * Decription: Generate full information of location from Google Map 
    * Params: List<AddressElement> addElements, DisplayResult result
    * Return: DisplayResult
    * Exceptions:
    * Revision: 
     *************************************************/
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
		public String addressFull 	{get; set;}
		public String address 		{get; set;}
		public String city 			{get; set;}
		public String state 		{get; set;}
		public String stateCode		{get; set;}
		public String postalCode 	{get; set;}
		public String country 		{get; set;}
		public String countryCode	{get; set;}
		public Double longitude 	{get; set;}
		public Double latitude 		{get; set;}
		public String uniqueKey 	{get; set;}
		public String county		{get; set;}
	}

	// ------------------------------ Google API wrapper class ----------------------------------- //
	public class LocationResponse {
		public List<LocationResult> predictions	{get; set;}
		public String status 					{get; set;}
	}

	public class LocationResult {
		public String description 				{get; set;}
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