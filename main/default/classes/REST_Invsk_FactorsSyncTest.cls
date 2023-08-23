/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 08-16-2021
 * @last modified by  : Vinayesh
**/
@isTest
public class REST_Invsk_FactorsSyncTest {
@testSetup static void setup() {
   
	}

	@isTest
	static void testAddPostMethod_FactorsSync() {
	
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/Invsk_FactorsSync';
		request.httpMethod = 'POST';
		request.requestBody =  Blob.valueOf(
								 '{"blob" : "www.testUrl.com"}');
		RestResponse response  = new RestResponse();
		RestContext.request = request;
		RestContext.response = response; 
		
        REST_Invsk_FactorsSync.doPost();

        System.assert(RestContext.response.statusCode==200);
	
	}
}