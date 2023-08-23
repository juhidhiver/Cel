/**************************************************************************************************
 * Class Name: CustomCompactLwcControllerTest
 * Modified By : Ashik Zahir
 * Modified Date: 15-Feb-2021
 * Description: Unit test for CustomCompactLwcController
 **************************************************************************************************/
@isTest
public class CustomCompactLwcControllerTest {
    
    @testSetup
    public static void setup() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc1 = TestUtil.createAccount('Test account 1', recordTypeId, 'Test account 1', 'Westminster',
                                              'California', 'California',  'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        acc1.FEIN__c = 651106324;
        acc1.Azure_ID__c = '8042ac98-ae5a-4692-9880-58d92d0eb9d9';
        insert acc1;
        
        Product2 product = TestUtil.createProduct('D&O Standalone');
		insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        opp.CloseDate = Date.today()+365;
        opp.StageName = 'New';
        opp.Azure_ID__c = 'f70e4c82-3378-41ce-870b-57f4df415874';
        insert opp;
        

    }
    
    private class MetadataCompImplServiceMock implements WebServiceMock {
		public void doInvoke(Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName, String responseNS,
			String responseName, String responseType) {   
            
            MetadataService.readMetadata_element readResult = (MetadataService.readMetadata_element) JSON.deserialize(JSON.serialize(request), MetadataService.readMetadata_element.class);
            //   
                    
                if(readResult.type_x == 'RecordType') {
                    System.assertEquals('RecordType',readResult.type_x); 
                    //System.assertEquals(true,request instanceof MetadataService.readMetadata_element);
            		MetadataService.RecordType gblRecTypeSet = new MetadataService.RecordType();
            		gblRecTypeSet.compactLayoutAssignment = 'testing';   
            
            		MetadataService.ReadRecordTypeResult result = new MetadataService.ReadRecordTypeResult();
            		result.records = new List<MetadataService.RecordType>{gblRecTypeSet};  
            
            		MetadataService.readRecordTypeResponse_element  readResponse = new MetadataService.readRecordTypeResponse_element();
            		readResponse.result = result;
                
            		if(request instanceof MetadataService.updateMetadata_element) {
	            		response.put('response_x', new MetadataService.updateMetadataResponse_element());
					} else if(request instanceof  MetadataService.deleteMetadata_element) {
	            		response.put('response_x', new MetadataService.deleteMetadataResponse_element());
            		} else if(request instanceof MetadataService.readMetadata_element) {
                		//System.assertEquals(false,request instanceof MetadataService.readMetadata_element);
                		response.put('response_x', readResponse);
            		}
                }     
			
                if(readResult.type_x == 'CompactLayout') {
                    System.assertEquals('CompactLayout',readResult.type_x); 
                    MetadataService.CompactLayout cmpValueSet = new MetadataService.CompactLayout();
                    cmpValueSet.fields = new List<String>{'Name'};
                    
                    MetadataService.ReadCompactLayoutResult result = new MetadataService.ReadCompactLayoutResult();
                    result.records = new List<MetadataService.CompactLayout>{cmpValueSet};
                        
                    MetadataService.readCompactLayoutResponse_element readResponse = new MetadataService.readCompactLayoutResponse_element();
                    readResponse.result = result;
                    
                    if(request instanceof MetadataService.readMetadata_element) {
                		//System.assertEquals(false,request instanceof MetadataService.readMetadata_element);
                		response.put('response_x', readResponse);
            		}
                }	                
                
            
		}
	}
    
	@isTest
    public static void testGetCompactLayoutFields() {
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account accBroker = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert accBroker;
        Test.startTest();
        try {
           System.Test.setMock(WebServiceMock.class, new MetadataCompImplServiceMock()); 
           ResultResponse response = CustomCompactLwcController.getCompactLayoutFields(String.valueOf(accBroker.Id)); 
            System.assert(response != null);
        }
        catch(Exception ex) {
            System.debug('Exception'+ex.getMessage());
        }
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testGetCompactTitle() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.startTest();
        String getacc = CustomCompactLwcController.getCompactTitle(acc.Id);
        Test.stopTest();
        System.assert(getacc != null);
    }
    
    @isTest
    public static void testGetCompactObjectName() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Test.startTest();
        String getacc = CustomCompactLwcController.getCompactObjectName(acc.Id);
        Test.stopTest();
        System.assert(getacc != null);
    }
    
    @isTest
    public static void testGetOpportunityRecordType() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        Test.startTest();
        String getOppId = CustomCompactLwcController.getOpportunityRecordType(opp.Id);
        //String getaccId = CustomCompactLwcController.getDefaultRecordType(opp.Id);
        Test.stopTest();
        System.assert(getOppId != null);
    }
    

}