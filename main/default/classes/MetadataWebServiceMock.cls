/*************************************************
* Author: Binh Dang
* Updated: 24-Jul-2019
* Description: Webservice mock for metadata api
* Revision: 
*               
*************************************************/
public class MetadataWebServiceMock implements WebServiceMock {
	static final String PICKLIST_FIELD_APINAME = 'Contract.Product_Name__c';

	public void doInvoke(Object stub, Object request, Map<String, Object> response,
		String endpoint, String soapAction, String requestName, String responseNS,
		String responseName, String responseType) {
		if(request instanceof MetadataService.updateMetadata_element) {
			MetadataService.updateMetadataResponse_element metadataResponse = 
							new MetadataService.updateMetadataResponse_element();

	        MetadataService.SaveResult saveResult = new MetadataService.SaveResult();
	        saveResult.errors = new List<MetadataService.Error>();
	        //saveResult.errors.add('eror');
	        saveResult.fullName = 'TestApp';
	        saveResult.success = true;
	        metadataResponse.result = new List<MetadataService.SaveResult>();
	        metadataResponse.result.add(saveResult);

	        response.put('response_x', metadataResponse); 
		} else if(request instanceof  MetadataService.deleteMetadata_element) {
			MetadataService.deleteMetadataResponse_element metadataResponse = 
							new MetadataService.deleteMetadataResponse_element();

	        MetadataService.DeleteResult deleteResult = new MetadataService.DeleteResult();
	        deleteResult.errors = new List<MetadataService.Error>();
	        //deleteResult.errors.add('eror');
	        deleteResult.fullName = 'TestApp';
	        deleteResult.success = true;
	        metadataResponse.result = new List<MetadataService.DeleteResult>();
	        metadataResponse.result.add(deleteResult);
		} else if(request instanceof  MetadataService.readMetadata_element) {
			MetadataService.readMetadata_element requestReadMetadata_element = 
							(MetadataService.readMetadata_element) request;
		
	        if (requestReadMetadata_element.type_x == 'CustomField') { 
		        MetadataService.readCustomFieldResponse_element  mockRes   = 
		              new MetadataService.readCustomFieldResponse_element ();
		        mockRes.result = new MetaDataService.ReadCustomFieldResult();
		        mockRes.result.records = createCustomFields();
		        response.put('response_x', mockRes);
		    }
		}
	}

	private List<MetadataService.CustomField> createCustomFields() {
		List<MetadataService.CustomField> result = new List<MetadataService.CustomField>();

		MetadataService.CustomField customField = new MetadataService.CustomField();
        customField.fullName = PICKLIST_FIELD_APINAME;
        customField.label = 'picklist';
        customField.type_x = 'Picklist';

        Metadataservice.ValueSet valueSet = new metadataservice.ValueSet();
	    Metadataservice.ValueSetValuesDefinition values;  

	    values = new Metadataservice.ValueSetValuesDefinition();						
	    values.value = new List<MetadataService.CustomValue>();

	    Metadataservice.CustomValue value = new MetadataService.CustomValue();
	    value.fullName = 'Picklist Value';
	    value.default_x = false;    						

	    values.value.add(value);

	    valueSet.valueSetDefinition = values;
	    customField.valueSet = valueSet;

        result.add(customField);
		return result;
	}
}