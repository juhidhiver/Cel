@isTest
private class MetadataUtilTest {
	static final String PICKLIST_FIELD_APINAME = 'Contract.Product_Name__c';
	private class MetadataImplServiceMock implements WebServiceMock {
		public void doInvoke(Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName, String responseNS,
			String responseName, String responseType) {   
              
			//System.assertEquals(true,request instanceof MetadataService.readMetadata_element);
            MetadataService.GlobalValueSet gblValSet = new MetadataService.GlobalValueSet();
            gblValSet.customValue = new List<MetadataService.CustomValue>{new MetadataService.CustomValue()};
            gblValSet.description = 'For testing';
            gblValSet.masterLabel = 'Test';
            gblValSet.sorted = true;
                
            MetadataService.ReadGlobalValueSetResult readResult = new MetadataService.ReadGlobalValueSetResult();
            readResult.records = new List<MetadataService.GlobalValueSet>{gblValSet};    
                
            MetadataService.readGlobalValueSetResponse_element readResponse = new MetadataService.readGlobalValueSetResponse_element();
            readResponse.result = readResult;
            if(request instanceof MetadataService.updateMetadata_element) {
	            response.put('response_x', new MetadataService.updateMetadataResponse_element());
			} else if(request instanceof  MetadataService.deleteMetadata_element) {
	            response.put('response_x', new MetadataService.deleteMetadataResponse_element());
            } else if(request instanceof MetadataService.readMetadata_element) {
                //System.assertEquals(false,request instanceof MetadataService.readMetadata_element);
                response.put('response_x', readResponse);
            }
                
                
            
		}
	}
   
    
	@isTest
	static void testAddPicklistValues1() {
		List<String> values = new List<String>();
		values.add('test');

		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
		MetadataUtil.addPicklistValues(PICKLIST_FIELD_APINAME, values);
	}

	@isTest
	static void testAddPicklistValues2() {
		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
		MetadataUtil.addPicklistValues(null, null);
	}

	@isTest
	static void testDeletePicklistValues1() {
		List<String> values = new List<String>();
		values.add('test');

		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
		MetadataUtil.addPicklistValues(PICKLIST_FIELD_APINAME, values);
		MetadataUtil.removePicklistValues(PICKLIST_FIELD_APINAME, values);
	}

	@isTest
	static void testDeletePicklistValues2() {
		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
		MetadataUtil.removePicklistValues(null, null);
	}

	@isTest
	static void testUpdatePicklistValues() {
		List<String> oldValues = new List<String>();
		List<String> newValues = new List<String>();

		oldValues.add('Old Value');
		newValues.add('New Value');

		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
		MetadataUtil.addPicklistValues(PICKLIST_FIELD_APINAME, oldValues);
		MetadataUtil.updatePicklistValues(PICKLIST_FIELD_APINAME, oldValues, newValues);
	}

	@isTest
	static void testUpdatePicklistValues2() {
		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
		MetadataUtil.updatePicklistValues(null, null, null);
	}

	@isTest 
	static void testHandleSaveResults() {
		MetadataService.SaveResult result = new MetadataService.SaveResult();
		result.fullName = 'TestApp';
	    result.success = false;

	    List<MetadataService.Error> errors = new List<MetadataService.Error>();
	    MetadataService.Error error = new MetadataService.Error();
	    error.fields = new List<String>();
	    error.fields.add(PICKLIST_FIELD_APINAME);
	    error.message = 'This is a mock error msg';
	    error.statusCode = '201';

	    errors.add(error);
	    result.errors = errors;

		MetadataUtil.handleSaveResults(result);
	}
    
    @isTest
    public static void testUpdatePicklistValues1() {
        List<String> oldValues = new List<String>();
		List<String> newValues = new List<String>();

		oldValues.add('Old Value');
		newValues.add('New Value');
        
        System.Test.setMock(WebServiceMock.class, new MetadataImplServiceMock());
		
		MetadataUtil.updatePicklistValues1(PICKLIST_FIELD_APINAME, oldValues, newValues);
    }

}