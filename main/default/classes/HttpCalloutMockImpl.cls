@isTest
public with sharing class HttpCalloutMockImpl implements HttpCalloutMock {
	protected Integer code;
	protected String status;
	protected String bodyAsString;
	protected Blob bodyAsBlob;
	protected Map<String, String> responseHeaders;
	
	protected Set<String> uriList;
	public HttpCalloutMockImpl() {
		this.code = 0;
		this.status = '';
		this.bodyAsString = null;
		this.bodyAsBlob = null;
		this.responseHeaders = new Map<String,String>();
		this.uriList = getListURI();
	}

	public HttpCalloutMockImpl(Integer code, String status, String bodyAsString, 
							Blob bodyAsBlob, Map<String, String> responseHeaders) {
		this.code = code;
		this.status = status;
		this.bodyAsString = bodyAsString;
		this.bodyAsBlob = bodyAsBlob;
		this.responseHeaders = responseHeaders;
		this.uriList = getListURI();
	}

	public HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
		String baseUri = '';

		// set response for add locations
		API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Google_API_Nearby');
		baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
		if(req.getEndPoint().contains(baseUri) ) {
			res.setHeader('Content-Type', 'application/json');
			
			AddLocationController.LocationResult locResult1 = new AddLocationController.LocationResult();
			locResult1.description = '123 Main Street, Anytown CA 12345, USA';
			locResult1.place_id = '123456789';

			AddLocationController.LocationResult locResult2 = new AddLocationController.LocationResult();
			locResult2.description = '123 Main Street, Anytown CA 12345, USA';
			locResult2.place_id = '123456789';

			AddLocationController.LocationResponse locResponse = new AddLocationController.LocationResponse();
			locResponse.predictions = new List<AddLocationController.LocationResult>();
			locResponse.predictions.add(locResult1);
			locResponse.predictions.add(locResult2);
			locResponse.status = 'OK';

			res.setBody(JSON.serialize(locResponse));
			res.setStatusCode(200);

			return res;
		}

		// set response for add Place
		API_Configuration__mdt apiSettingPlace = CommonUtil.getAPIconfiguration('Google_API_Place');
		baseUri = apiSettingPlace.Base_Url__c + apiSettingPlace.Endpoint__c;
		if(req.getEndPoint().contains(baseUri) ) {
			res.setHeader('Content-Type', 'application/json');
			
			AddLocationController.AddressElement addElement = new AddLocationController.AddressElement();
			addElement.long_name = 'New Street';
			addElement.short_name = 'New St';
			addElement.types = new Set<String>();
			addElement.types.add('(route)');

			AddLocationController.LocationElement locElm = new AddLocationController.LocationElement();
			locElm.lat = 20;
			locElm.lng = 20;

			AddLocationController.GeometryElement geo = new AddLocationController.GeometryElement();
			geo.location = locElm;

			AddLocationController.AddressResult addressRes = new AddLocationController.AddressResult();
			addressRes.address_components = new List<AddLocationController.AddressElement>();
			addressRes.address_components.add(addElement);
			addressRes.formatted_address = 'Test';
			addressRes.geometry = geo;

			AddLocationController.AddressResponse addressRep = new AddLocationController.AddressResponse();
			addressRep.result = addressRes;
			addressRep.status = 'OK';

			res.setBody(JSON.serialize(addressRep));
			res.setStatusCode(200);
			return res;
		}

		// set response for generate document
		API_Configuration__mdt apiSettingGenerateDoc = CommonUtil.getAPIconfiguration('Generate_Document');
		baseUri = apiSettingGenerateDoc.Base_Url__c + apiSettingGenerateDoc.Endpoint__c;

		if(req.getEndPoint().contains(baseUri) ) {
			System.debug('==Generate_Document==');
			res.setHeader('Content-Type', 'application/json');
			Map<String, Object> mapData = new Map<String, Object>();
			mapData.put('documentId','id-document');
			res.setBody(JSON.serialize(mapData));
			res.setStatusCode(200);

			return res;
		}

		// set response for get document
		API_Configuration__mdt apiSettingGetDoc = CommonUtil.getAPIconfiguration('Get_Document');
		baseUri = apiSettingGetDoc.Base_Url__c + apiSettingGetDoc.Endpoint__c;
		System.debug('==baseUri in Testclass==' + baseUri);
		System.debug('==req.getEndPoint() of baseUri in Testclass==' + req.getEndPoint());
		if(req.getEndPoint().contains(baseUri) ) {
			System.debug('==Generate_Document==');
			res.setHeader('Content-Type', 'application/json');
			res.setBody('test blob');
			res.setStatusCode(200);

			return res;
		}
		
		// set response for google api
		baseUri = 'https://maps.googleapis.com/maps/api/place/autocomplete';
		if(req.getEndPoint().contains(baseUri) ) {
			System.debug('==google api==');
			res.setHeader('Content-Type', 'application/json');
			res.setBody('test google api');
			res.setStatusCode(200);
			return res;
		}

		// Set Response for send message from Azure SerivceBus
		API_Configuration__mdt apiSendMes = CommonUtil.getAPIconfiguration('Azure_Service_Bus');
		baseUri = apiSendMes.Base_Url__c + apiSendMes.Endpoint__c;
		if(req.getEndPoint().contains(baseUri) ) {
			res.setHeader('Content-Type', 'application/json');
			res.setBody('Send Message Successful!');
			res.setStatusCode(200);
			return res;
		}

		// Set Response for OFAC
		API_Configuration__mdt apiSettingOFAC = CommonUtil.getAPIconfiguration('API_OFAC');
		baseUri = apiSettingOFAC.Base_Url__c + apiSettingOFAC.Endpoint__c;
		if(req.getEndPoint().contains(baseUri) ) {
			res.setHeader('Content-Type', 'application/json');

			Map<String, Object> mapData = new Map<String, Object>();
			mapData.put('isValidOFAC','true');

			res.setBody(JSON.serialize(mapData));
			res.setStatusCode(200);
			return res;
		}
		
        // Set Response for Rate Quote
		API_Configuration__mdt apiSettingRateQuote = CommonUtil.getAPIconfiguration('Rate_Quote');
		baseUri = apiSettingRateQuote.Base_Url__c + apiSettingRateQuote.Endpoint__c;
		if(req.getEndPoint().contains(baseUri) ) {
			res.setHeader('Content-Type', 'application/json');

			String resResult = '{"Quote_ID":null,"Surcharge":"0","overallUWCodes":[],"overallUWDescriptions":[],"QuotePremium__c":"39967","Master_Set_ID__c":"1","Status":"Clear","commissionAmount":"0","nonCAT_Premium":null,"caT_Premium":null,"Effective_Date__c":"2019-08-27","ExpirationDate":"2020-08-20","AcceptedTerrorism_Premium":"5995","RejectedTerrorism_Premium":"0.0","SelectedTerrorism_Premium":"0.0","CoveragePremium__c":"39967.0","Accounts":[],"Locations":[],"CoverageLineItems":[]}}';

			res.setBody(resResult);
			res.setStatusCode(200);
			return res;
		}
		return res;
	}

	private Set<String> getListURI() {
		Set<String> result = new Set<String>();
		String uri = '';
		List<API_Configuration__mdt> items = CommonUtil.getAPIconfigurations();

		for(API_Configuration__mdt item : items) {
			uri =  item.Base_Url__c + item.Endpoint__c;
			result.add(uri);
		}

		return result;
	}
}