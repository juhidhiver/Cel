@isTest
private class MetadataServiceTest {
	private class MetadataServiceMock implements WebServiceMock {
		public void doInvoke(Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName, String responseNS,
			String responseName, String responseType) {
			if(request instanceof MetadataService.updateMetadata_element) {
	            response.put('response_x', new MetadataService.updateMetadataResponse_element());
			} else if(request instanceof  MetadataService.deleteMetadata_element) {
                System.debug('>>>inside Delete>>>');
	            response.put('response_x', new MetadataService.deleteMetadataResponse_element());
			}
		}
	}

	@isTest 
	static void testUpdateMetadata() {
		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
		MetadataService metaDataService = new MetadataService();
		Test.startTest();    
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        metaDataPort.updateMetadata(null);
        Test.stopTest();
	}

	 @isTest 
	 static void testDeleteMetadata() {
	 	System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
	 	MetadataService metaDataService = new MetadataService();
	 	Test.startTest();    
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        String type_x = 'CustomField';
        List<String> fields = new List<String>();
        fields.add('Contract.Product_Name__c');
         try{
            metaDataPort.deleteMetadata(type_x, fields); 
         } Catch(Exception ex) {
             
         }
        
        Test.stopTest();
	 }

	
	@isTest 
	static void testReadMetadata() {
		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
		MetadataService metaDataService = new MetadataService(); 
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        String type_x = 'CustomField';
        List<String> fields = new List<String>();
        fields.add('Contract.Product_Name__c');
       	metaDataPort.readMetadata(type_x, fields);
	}
	
	
	@isTest 
	static void testGenerateType() {
		new MetadataService.PicklistEntry();
		new MetadataService.Metadata();
		new MetadataService.SessionHeader_element();
		new MetadataService.DebuggingInfo_element();
		new MetadataService.DebuggingHeader_element();
		new MetadataService.CallOptions_element();
		new MetadataService.AllOrNoneHeader_element();
		new MetadataService.SaveResult();
		new MetadataService.DeleteResult();
		new MetadataService.deleteMetadata_element();
		new MetadataService.deleteMetadataResponse_element();
		new MetadataService.LogInfo();
		new MetadataService.Error();
		new MetadataService.ExtendedErrorDetails();
		new MetadataService.CustomField();
        new MetadataService.RecordType();
        new MetadataService.CompactLayout();
		new MetadataService.LookupFilter();
		new MetadataService.FilterItem();
		new MetadataService.ValueSet();
		new MetadataService.ValueSetValuesDefinition();
		new MetadataService.CustomValue();
		new MetadataService.ReadCustomFieldResult();
		new MetadataService.readCustomFieldResponse_element();
		new MetadataService.Picklist();
		new MetadataService.GlobalPicklistValue();
		new MetadataService.PicklistValue();
        new MetadataService.RecordTypePicklistValue();
        new MetadataService.readRecordTypeResponse_element();
        new MetadataService.ReadRecordTypeResult();
        new MetadataService.ReadCompactLayoutResult();
        new MetadataService.readCompactLayoutResponse_element();
        new MetadataService.Country();
        new MetadataService.State();
        new MetadataService.CountriesAndStates();
        new MetadataService.AddressSettings();
        new MetadataService.ReadAddressSettingsResult();
        new MetadataService.readAddressSettingsResponse_element();
		new MetadataService.updateMetadata_element();
		new MetadataService.ValueSettings();
	}
}