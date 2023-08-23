@isTest
public class SearchAddressGoogleApiLwcControllerTest {
	 public class SearchAddressMockResponse implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "predictions":[ { "description":"Times Square, New York, Manhattan, NY, USA", "place_id":"ChIJmQJIxlVYwokRLgeuocVOGVU" } ], "status":"OK" }');
        res.setStatusCode(200);
        return res;
    	}
     }
    public class SearchPlaceIdMockResponse implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{  "result": { "address_components": [{ "long_name": "Asansol", "short_name": "Asansol", "types": [ "locality", "political" ] }, { "long_name": "Bardhaman", "short_name": "Bardhaman", "types": [ "administrative_area_level_2", "political" ] }, { "long_name": "West Bengal", "short_name": "WB", "types": [ "administrative_area_level_1", "political" ] }, { "long_name": "India", "short_name": "IN", "types": [ "country", "political" ] } ], "formatted_address": "Asansol, West Bengal, India", "geometry": { "location": { "lat": 23.68886359999999, "lng": 86.9660638 } } }, "status": "OK" }');
        res.setStatusCode(200);
        return res;
    	}
     }
       public class MockResponseForError implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{  "result":{ "address_components":[ { "long_name":"Asansol", "short_name":"Asansol", "types":[ "locality", "political" ] }, { "long_name":"Bardhaman", "short_name":"Bardhaman", "types":[ "administrative_area_level_2", "political" ] }, { "long_name":"West Bengal", "short_name":"WB", "types":[ "administrative_area_level_1", "political" ] }, { "long_name":"India", "short_name":"IN", "types":[ "country", "political" ] } ], "adr_address":"\u003cspan class=\"locality\"\u003eAsansol\u003c/span\u003e, \u003cspan class=\"region\"\u003eWest Bengal\u003c/span\u003e, \u003cspan class=\"country-name\"\u003eIndia\u003c/span\u003e", "formatted_address":"Asansol, West Bengal, India", "geometry":{ "location":{ "lat":23.68886359999999, "lng":86.9660638 }, "viewport":{ "northeast":{ "lat":23.7219596, "lng":87.09426019999999 }, "southwest":{ "lat":23.6450746, "lng":86.894291 } } } }, "status":"OK" }');
        res.setStatusCode(200);
        return res;
    	}
     }
    
    @isTest
    static void searchLocationTest(){
        Test.startTest();
        SearchAddressMockResponse mock = new SearchAddressMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        SearchAddressGoogleApiLwcController.searchLocation('Test');
        Test.stopTest();
    }
        @isTest
    static void searchPlaceTest(){
        Test.startTest();
        SearchPlaceIdMockResponse mock = new SearchPlaceIdMockResponse();
        Test.setMock(HttpCalloutMock.class, mock);
        SearchAddressGoogleApiLwcController.searchPlace('ChIJuUZZAz2uEmsRdcOSr8t2LJ8');
        Test.stopTest();
    }
    @isTest
    static void addNewLocationTest(){
        Test.startTest();
        SearchAddressGoogleApiLwcController.addNewLocation('parentId', 'objAPIName', 'parentAPIName', 'locationAPIName', 'usageType', True);
        Test.stopTest();
    }
     @isTest
    static void ExceptionTest(){
        Test.startTest();
         MockResponseForError mock = new MockResponseForError();
        Test.setMock(HttpCalloutMock.class, mock);
        SearchAddressGoogleApiLwcController.searchPlace('ChIJuUZZAz2uEmsRdcOSr8t2LJ8');
        SearchAddressGoogleApiLwcController.searchLocation('Test');
        new SearchAddressGoogleApiLwcController.OpptionWapper('argLabel',  'argValue');
       
        Test.stopTest();
    }
}