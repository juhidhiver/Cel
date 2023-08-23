@isTest
public class GoogleMapsAutocompleteTest {
	@isTest
    public static void testGetAddressAutoComplete() {
        GoogleMapsAutocomplete.AddressElement addEle = new GoogleMapsAutocomplete.AddressElement();
        addEle.long_name = 'United States';
        addEle.short_name = 'US';
        addEle.types = new Set<String>{'country','postal_code'};
            
        GoogleMapsAutocomplete.LocationElement locEle = new GoogleMapsAutocomplete.LocationElement();
        locEle.lat = 22.4;
        locEle.lng = 24.4;
        
        GoogleMapsAutocomplete.GeometryElement googleEle = new GoogleMapsAutocomplete.GeometryElement();
        googleEle.location = locEle;
            
        GoogleMapsAutocomplete.AddressResult addrRes = new  GoogleMapsAutocomplete.AddressResult();
        addrRes.address_components = new List<GoogleMapsAutocomplete.AddressElement>{addEle};
        addrRes.formatted_address = 'Test Street';
        addrRes.geometry = googleEle;
        
        GoogleMapsAutocomplete.AddressResponse addrResponse = new GoogleMapsAutocomplete.AddressResponse();
        addrResponse.result = addrRes;
        addrResponse.status = 'OK';

		String jsonString = JSON.serialize(addrResponse);

		Test.startTest();
		WebServiceAddrMockImpl mock = new WebServiceAddrMockImpl();
		mock.body = jsonString;
        Test.setMock(HttpCalloutMock.class, mock);
        GoogleMapsAutocomplete.getAddressAutoComplete('Testing');
        GoogleMapsAutocomplete.getPlaceDetails('Testing');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetPlaceDetailsPostalCode() {
         GoogleMapsAutocomplete.AddressElement addEle = new GoogleMapsAutocomplete.AddressElement();
        addEle.long_name = 'United States';
        addEle.short_name = 'US';
        addEle.types = new Set<String>{'postal_code'};
            
        GoogleMapsAutocomplete.LocationElement locEle = new GoogleMapsAutocomplete.LocationElement();
        locEle.lat = 22.4;
        locEle.lng = 24.4;
        
        GoogleMapsAutocomplete.GeometryElement googleEle = new GoogleMapsAutocomplete.GeometryElement();
        googleEle.location = locEle;
            
        GoogleMapsAutocomplete.AddressResult addrRes = new  GoogleMapsAutocomplete.AddressResult();
        addrRes.address_components = new List<GoogleMapsAutocomplete.AddressElement>{addEle};
        addrRes.formatted_address = 'Test Street';
        addrRes.geometry = googleEle;
        
        GoogleMapsAutocomplete.AddressResponse addrResponse = new GoogleMapsAutocomplete.AddressResponse();
        addrResponse.result = addrRes;
        addrResponse.status = 'OK';

		String jsonString = JSON.serialize(addrResponse);

		Test.startTest();
		WebServiceAddrMockImpl mock = new WebServiceAddrMockImpl();
		mock.body = jsonString;
        Test.setMock(HttpCalloutMock.class, mock);
        GoogleMapsAutocomplete.getPlaceDetails('Testing');
        Test.stopTest();
    }
    
     @isTest
    public static void testGetPlaceDetailsAdminArea() {
         GoogleMapsAutocomplete.AddressElement addEle = new GoogleMapsAutocomplete.AddressElement();
        addEle.long_name = 'United States';
        addEle.short_name = 'US';
        addEle.types = new Set<String>{'administrative_area_level_1'};
            
        GoogleMapsAutocomplete.LocationElement locEle = new GoogleMapsAutocomplete.LocationElement();
        locEle.lat = 22.4;
        locEle.lng = 24.4;
        
        GoogleMapsAutocomplete.GeometryElement googleEle = new GoogleMapsAutocomplete.GeometryElement();
        googleEle.location = locEle;
            
        GoogleMapsAutocomplete.AddressResult addrRes = new  GoogleMapsAutocomplete.AddressResult();
        addrRes.address_components = new List<GoogleMapsAutocomplete.AddressElement>{addEle};
        addrRes.formatted_address = 'Test Street';
        addrRes.geometry = googleEle;
        
        GoogleMapsAutocomplete.AddressResponse addrResponse = new GoogleMapsAutocomplete.AddressResponse();
        addrResponse.result = addrRes;
        addrResponse.status = 'OK';

		String jsonString = JSON.serialize(addrResponse);

		Test.startTest();
		WebServiceAddrMockImpl mock = new WebServiceAddrMockImpl();
		mock.body = jsonString;
        Test.setMock(HttpCalloutMock.class, mock);
        GoogleMapsAutocomplete.getPlaceDetails('Testing');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetPlaceDetailslocality() {
         GoogleMapsAutocomplete.AddressElement addEle = new GoogleMapsAutocomplete.AddressElement();
        addEle.long_name = 'United States';
        addEle.short_name = 'US';
        addEle.types = new Set<String>{'locality'};
            
        GoogleMapsAutocomplete.LocationElement locEle = new GoogleMapsAutocomplete.LocationElement();
        locEle.lat = 22.4;
        locEle.lng = 24.4;
        
        GoogleMapsAutocomplete.GeometryElement googleEle = new GoogleMapsAutocomplete.GeometryElement();
        googleEle.location = locEle;
            
        GoogleMapsAutocomplete.AddressResult addrRes = new  GoogleMapsAutocomplete.AddressResult();
        addrRes.address_components = new List<GoogleMapsAutocomplete.AddressElement>{addEle};
        addrRes.formatted_address = 'Test Street';
        addrRes.geometry = googleEle;
        
        GoogleMapsAutocomplete.AddressResponse addrResponse = new GoogleMapsAutocomplete.AddressResponse();
        addrResponse.result = addrRes;
        addrResponse.status = 'OK';

		String jsonString = JSON.serialize(addrResponse);

		Test.startTest();
		WebServiceAddrMockImpl mock = new WebServiceAddrMockImpl();
		mock.body = jsonString;
        Test.setMock(HttpCalloutMock.class, mock);
        GoogleMapsAutocomplete.getPlaceDetails('Testing');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetPlaceDetailsPremise() {
        GoogleMapsAutocomplete.LocationResult  locRes = new GoogleMapsAutocomplete.LocationResult();
        locRes.description = 'Test Location';
        locRes.place_id = 'TestLoc';
        
        GoogleMapsAutocomplete.LocationResponse locResponse = new GoogleMapsAutocomplete.LocationResponse();
        locResponse.predictions = new List<GoogleMapsAutocomplete.LocationResult>{locRes};
        locResponse.status = 'OK';    
        
        GoogleMapsAutocomplete.AddressElement addEle = new GoogleMapsAutocomplete.AddressElement();
        addEle.long_name = 'United States';
        addEle.short_name = 'US';
        addEle.types = new Set<String>{'premise'};
            
        GoogleMapsAutocomplete.LocationElement locEle = new GoogleMapsAutocomplete.LocationElement();
        locEle.lat = 22.4;
        locEle.lng = 24.4;
        
        GoogleMapsAutocomplete.GeometryElement googleEle = new GoogleMapsAutocomplete.GeometryElement();
        googleEle.location = locEle;
            
        GoogleMapsAutocomplete.AddressResult addrRes = new  GoogleMapsAutocomplete.AddressResult();
        addrRes.address_components = new List<GoogleMapsAutocomplete.AddressElement>{addEle};
        addrRes.formatted_address = 'Test Street';
        addrRes.geometry = googleEle;
        
        GoogleMapsAutocomplete.AddressResponse addrResponse = new GoogleMapsAutocomplete.AddressResponse();
        addrResponse.result = addrRes;
        addrResponse.status = 'OK';

		String jsonString = JSON.serialize(addrResponse);

		Test.startTest();
		WebServiceAddrMockImpl mock = new WebServiceAddrMockImpl();
		mock.body = jsonString;
        Test.setMock(HttpCalloutMock.class, mock);
        GoogleMapsAutocomplete.getPlaceDetails('Testing');
        Test.stopTest();
    }
    
     public class WebServiceAddrMockImpl implements HttpCalloutMock {
         public String body          {get; set;}
     	 public Integer statusCode   {get; set;} 
        public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    	}
    }
}