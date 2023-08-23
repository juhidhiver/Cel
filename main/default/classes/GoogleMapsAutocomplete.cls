global with sharing class GoogleMapsAutocomplete {

    /*@AuraEnabled
    public static string getAddressAutoComplete(String input, String types) {
        String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input='
                + EncodingUtil.urlEncode(input, 'UTF-8')
                + '&types=' + types
                + '&key=' + GoogleMapsController.getGoogleMapsAPIKey();
        return GoogleMapsController.getHttp(url);
    }*/
    @AuraEnabled
	public static string getAddressAutoComplete(String input) {
	    String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
                + 'input=' + EncodingUtil.urlEncode(input, 'UTF-8')
                + '' + getKey();
	            //+ '&types=(cities)' + getKey();
        String response = getResponse(url);
        System.debug('getAddressAutoComplete:' + response);
	    return response;
    }
    
    /*@AuraEnabled
	public static string getPlaceDetails(String placeId) {
     	String url = 'https://maps.googleapis.com/maps/api/place/details/json?'
	            + 'placeid=' + EncodingUtil.urlEncode(placeId, 'UTF-8')
	            + getKey(); 
	    String response = getResponse(url);
	    return response;
	}*/
	
	@AuraEnabled
	public static DisplayResult getPlaceDetails(String placeId) {
		String url = 'https://maps.googleapis.com/maps/api/place/details/json?'
			   + 'placeid=' + EncodingUtil.urlEncode(placeId, 'UTF-8')
			   + getKey(); 
	    String res = getResponse(url);
	    AddressResponse addressResponse = (AddressResponse) JSON.deserialize(res, AddressResponse.class);
	    system.debug('@@@ addressResponse=' + addressResponse);
		DisplayResult displayResult = new DisplayResult();
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
		system.debug('displayResult:' + displayResult);
	   return displayResult;
   }


   private static DisplayResult getLocationDetailedInformation(List<AddressElement> addElements, DisplayResult result) {
		List<String> returnAddress = new List<String>();

		// Added by Vinayesh on 31/5/2021 for US:46481
		Google_Unique_Country_Code__mdt USVICode;
		Google_Unique_Country_Code__mdt	[] uniqueCountryCodes = [SELECT Unique_Country_Code__c, Actual_Country_Code__c	, 
											Actual_Country_Name__c, Actual_State_Code__c,
											Actual_State_Name__c 
											FROM Google_Unique_Country_Code__mdt];

		/**** End Vinayesh Add */


		if (!addElements.isEmpty()) {
		for (AddressElement addElement : addElements) {
			
			if (addElement.types == null || addElement.types.isEmpty()) continue;
			String longName = String.isBlank(addElement.long_name) ? null : addElement.long_name;
			String shortName = String.isBlank(addElement.short_name) ? null : addElement.short_name;

			if (addElement.types.contains('country')) {
				// Added by Vinayesh on 31/5/2021 for US:46481 
				for (Google_Unique_Country_Code__mdt uc : uniqueCountryCodes) {
					if(shortName.deleteWhitespace() == uc.Unique_Country_Code__c){
						USVICode = uc;
						break;
					}
				}

				if(USVICode != null && shortName.deleteWhitespace() == USVICode.Unique_Country_Code__c){
					result.country = USVICode.Actual_Country_Name__c;
					result.countryCode = USVICode.Actual_Country_Code__c;
					result.state = USVICode.Actual_State_Name__c;
					result.stateCode = USVICode.Actual_State_Code__c;
				}
				else{
					result.country = longName;
					result.countryCode = shortName;
				}
				/**** End Vinayesh Add */

				//Added by Vinayesh on 31/5/2021 for US:46481 
				//result.country = longName;
				//result.countryCode = shortName;

				/**** End Vinayesh Add */

				System.debug('Short Name****' + shortName);
				System.debug('Long Name****' + longName);
			
			} else if (addElement.types.contains('postal_code')) {
				result.postalCode = longName;

			} else if (addElement.types.contains('administrative_area_level_1')) {

				// Added by Vinayesh on 31/5/2021 for US:46481 
				if(USVICode == null || (USVICode != null && result.stateCode != USVICode.Unique_Country_Code__c)){
					result.state = longName;
					result.stateCode = shortName;
				}
				/**** End Vinayesh Add */

				//Added by Vinayesh on 31/5/2021 for US:46481 
				//result.state = longName;
				//result.stateCode = shortName;

				/**** End Vinayesh Add */
				
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
 
	public static string getResponse(string strURL){
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		HttpResponse res = new HttpResponse();
		req.setMethod('GET');
		req.setEndpoint(strURL);
		req.setTimeout(120000);
		res = h.send(req); 
		String responseBody = res.getBody(); 
		return responseBody;
	}
 
	public static string getKey(){
		string key = 'AIzaSyBVVho8_KfyX4dU-h9ikoLzLbKDI6lVV4g';
		string output = '&key=' + key;	 
		return output;
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
		@AuraEnabled
		public AddressResult result			{get; set;}
		@AuraEnabled
		public String status 				{get; set;}
	}

	public class AddressResult {
		@AuraEnabled
		public List<AddressElement> address_components	{get; set;}
		@AuraEnabled
		public String formatted_address 				{get; set;}
		@AuraEnabled
		public GeometryElement geometry 				{get; set;}
	}

	public class AddressElement {
		@AuraEnabled
		public String long_name 		{get; set;}
		@AuraEnabled
		public String short_name 		{get; set;}
		@AuraEnabled
		public Set<String> types 		{get; set;}
	}

	public class GeometryElement {
		@AuraEnabled
		public LocationElement location {get; set;}
	}

	public class LocationElement {
		@AuraEnabled
		public Double lat 	{get; set;}
		@AuraEnabled
		public Double lng 	{get; set;}
	}
}