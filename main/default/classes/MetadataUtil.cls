/*************************************************
* Class Name: MetadataUtil
* Author: Binh Dang
* Updated: 17-Jul-2019
* Description: Handle requests to change metadata via SOAP API
* 
* This class require MetadataService.cls in order to run
*               
*************************************************/
public class MetadataUtil {
	/*************************************************
    * @author: Binh Dang
    * Date: 17-Jul-2019
    * Description: Add new value to value set of picklist
    * Do not work on dependent picklist
    * @param apiName apiName name. Must include Object API Name (e.g.: Contract.Product_Name__c) 
	* @param newValue value to be added to picklist
    * @return: List of errors
    * Exceptions:
    * Revision: 
    *************************************************/
	public static List<String> addPicklistValues(String apiName, List<String> newValues)
    {
    	List<String> errors = new List<String>();

    	try {
	    	// Initialize service to call API
	        MetadataService.MetadataPort service = createService1();//28-may-20 Hoang replace createService by createService1

	        // Get picklist field need to be updated
	        MetadataService.CustomField customField = 
	        	(MetadataService.CustomField) service.readMetadata('CustomField', 
	            new String[] { apiName }).getRecords()[0];

	       	if (customField.type_x != 'Picklist') {
	       		errors.add('Custom Fields is not a picklist.');
	       		return errors;
	       	}
	        //customField.fullName = 'Contract.ContractProperty__c';
	        //customField.label = 'ContractProperty';
	        //customField.type_x = 'Picklist';

	        // Get existing value set from picklist
	        Metadataservice.ValueSet valueSet = new metadataservice.ValueSet();
	        Metadataservice.ValueSetValuesDefinition values = 
	        						new Metadataservice.ValueSetValuesDefinition();

	        valueSet = customField.valueSet;
	        values = valueSet.valueSetDefinition;

	        // Create new value for value set
	        List<Metadataservice.CustomValue> valueList = new List<MetadataService.CustomValue>();
	        valueList = generateCustomValueList(newValues);

	        values.value.addAll(valueList);

	        valueSet.valueSetDefinition = values;
	        customField.valueSet = valueSet ;

	        // send soap request to update custom field
	        List<MetadataService.SaveResult> results =
	            service.updateMetadata(
	                new MetadataService.Metadata[] { customField });

	        // handle SaveResults if need    
	        errors = handleSaveResults(results[0]);
	    } catch (Exception ex) {
	    	errors.add(ex.getMessage());
	    }

	    return errors;
    }

	/*************************************************
    * @author: Binh Dang
    * Date: 17-Jul-2019
    * Description: Remove existed values from picklist
	* Metadata api doesn't support deleting picklist value
	* Deleted values can only be deactivated 
	* Do not work on dependent picklist
    * @param apiName apiName name. Must include Object API Name (e.g.: Contract.Product_Name__c) 
	* @param existedValues value to be added to picklist
    * @return: List of errors
    * Revision: 
    *************************************************/
	public static List<String> removePicklistValues(String apiName, List<String> existedValues)
    {
    	List<String> errors = new List<String>();

    	try {
	    	// Initialize service to call API
	        MetadataService.MetadataPort service = createService1();

	        // Get picklist field need to be updated
	        MetadataService.CustomField customField = 
	        	(MetadataService.CustomField) service.readMetadata('CustomField', 
	            new String[] { apiName }).getRecords()[0];

	       	if (customField.type_x != 'Picklist') {
	       		errors.add('Custom Fields is not a picklist.');
	       		return errors;
	       	}

	        // Get existing value set from picklist
	        Metadataservice.ValueSet valueSet = new metadataservice.ValueSet();
	        Metadataservice.ValueSetValuesDefinition values = 
	        						new Metadataservice.ValueSetValuesDefinition();

	        valueSet = customField.valueSet;
	        values = valueSet.valueSetDefinition;

	        // Create new value for value set
	        List<Metadataservice.CustomValue> valueList = new List<MetadataService.CustomValue>();
	        valueList = values.value;

	        // Loop backward to avoid out of bound index exception
	        for(Integer i = valueList.size() - 1; i >=0; i--) {
	        	if (existedValues.contains(valueList[i].fullName)) {
	        		valueList.remove(i);
	        	}
	        }

	        values.value = valueList;
	        valueSet.valueSetDefinition = values;
	        customField.valueSet = valueSet;

	        // send soap request to update custom field
	        List<MetadataService.SaveResult> results =
	            service.updateMetadata(
	                new MetadataService.Metadata[] { customField });

	        // handle SaveResults if need    
	        errors = handleSaveResults(results[0]);
	    } catch (Exception ex) {
	    	errors.add(ex.getMessage());
	    }

	    return errors;
    }

	/*************************************************
    * @author: Binh Dang
    * Date: 17-Jul-2019
    * Description: Update existed values from picklist
	* Metadata api doesn't support deleting picklist value
	* Old values will be deactivated and new value will be added
	* Do not work on dependent picklist
    * @param apiName apiName name. Must include Object API Name (e.g.: Contract.Product_Name__c) 
	* @param newValues value to be added to picklist
	* @param existedValues value to be removed from picklist
    * Return: List of errors
    * Revision: 
    *************************************************/
	public static List<String> updatePicklistValues(String apiName, List<String> existedValues, List<String> newValues)
    {
    	List<String> errors = new List<String>();

    	try {
	    	// Initialize service to call API
	        MetadataService.MetadataPort service = createService1();

	        // Get picklist field need to be updated
	        MetadataService.CustomField customField = 
	        	(MetadataService.CustomField) service.readMetadata('CustomField', 
	            new String[] { apiName }).getRecords()[0];
			system.debug('customField='+customField);
			system.debug('customField.type_x='+customField.type_x);
			
	       	if (customField.type_x != 'Picklist') {
	       		errors.add('Custom Fields is not a picklist.');
	       		return errors;
	       	}			
			
	        // Get existing value set from picklist
	        Metadataservice.ValueSet valueSet = new Metadataservice.ValueSet();
	        Metadataservice.ValueSetValuesDefinition values = 
	        						new Metadataservice.ValueSetValuesDefinition();

			valueSet = customField.valueSet;
			
			system.debug('valueSet='+valueSet);
			values = valueSet.valueSetDefinition;
			system.debug('values='+values);
			
	        // Create new value for value set
	        List<Metadataservice.CustomValue> valueList = 
	        					new List<MetadataService.CustomValue>();
	        valueList = values.value;
			system.debug('valueList='+valueList);
	        // Delete old values
	        // Loop backward to avoid out of bound index exception
	        for(Integer i = valueList.size() - 1; i >=0; i--) {
	        	if (existedValues.contains(valueList[i].fullName)) {
	        		valueList.remove(i);
	        	}
	        }

	        // Add new value
	        List<Metadataservice.CustomValue> newValueList = 
	        					generateCustomValueList(newValues);
	       	valueList.addAll(newValueList);

	       	// Push value set back to picklist
	        values.value = valueList;
	        valueSet.valueSetDefinition = values;
			customField.valueSet = valueSet;			

	        // send soap request to update custom field
	        List<MetadataService.SaveResult> results =
	            service.updateMetadata(
	                new MetadataService.Metadata[] { customField });//customField

	        // handle SaveResults if need    
	        errors = handleSaveResults(results[0]);
	    } catch (Exception ex) {
	    	errors.add(ex.getMessage());
	    }

	    return errors;
	}
	
	/*************************************************
    * @author: Binh Dang
    * Date: 17-Jul-2019
    * Description: Update existed values from picklist
	* Metadata api doesn't support deleting picklist value
	* Old values will be deactivated and new value will be added
	* Do not work on dependent picklist
    * @param apiName apiName name. Must include Object API Name (e.g.: Contract.Product_Name__c) 
	* @param newValues value to be added to picklist
	* @param existedValues value to be removed from picklist
    * Return: List of errors
    * Revision: 
    *************************************************/
	public static List<String> updatePicklistValues1(String apiName, List<String> existedValues, List<String> newValues)
    {
    	List<String> errors = new List<String>();

    	try {
	    	// Initialize service to call API
	        MetadataService.MetadataPort service = createService1();

			MetadataService.GlobalValueSet gPicklist = 
			(MetadataService.GlobalValueSet) service.readMetadata('GlobalValueSet', 
			new String[] { apiName }).getRecords()[0];
			system.debug('gPicklist='+gPicklist);
			system.debug('gPicklist.customValue='+gPicklist.customValue);   
			
/*
	        // Get picklist field need to be updated
	        MetadataService.CustomField customField = 
	        	(MetadataService.CustomField) service.readMetadata('CustomField', 
	            new String[] { apiName }).getRecords()[0];
			system.debug('customField='+customField);
			system.debug('customField.type_x='+customField.type_x);
			
	       	if (customField.type_x != 'Picklist') {
	       		errors.add('Custom Fields is not a picklist.');
	       		return errors;
	       	}
			
			
	        // Get existing value set from picklist
	        Metadataservice.ValueSet valueSet = new Metadataservice.ValueSet();
	        Metadataservice.ValueSetValuesDefinition values = 
	        						new Metadataservice.ValueSetValuesDefinition();

			valueSet = customField.valueSet;
			
			system.debug('valueSet='+valueSet);
			values = valueSet.valueSetDefinition;
			system.debug('values='+values);
			   */
	        // Create new value for value set
	        List<Metadataservice.CustomValue> valueList = 
	        					new List<MetadataService.CustomValue>();
	        valueList = gPicklist.customValue;
			system.debug('valueList='+valueList);
	        // Delete old values
	        // Loop backward to avoid out of bound index exception
	        for(Integer i = valueList.size() - 1; i >=0; i--) {
	        	if (existedValues.contains(valueList[i].fullName)) {
	        		valueList.remove(i);
	        	}
	        }

	        // Add new value
	        List<Metadataservice.CustomValue> newValueList = 
	        					generateCustomValueList(newValues);
	       	valueList.addAll(newValueList);

	       	// Push value set back to picklist
	        /*values.value = valueList;
	        valueSet.valueSetDefinition = values;
			customField.valueSet = valueSet;
			*/
			gPicklist.customValue = valueList;

	        // send soap request to update custom field
	        List<MetadataService.SaveResult> results =
	            service.updateMetadata(
	                new MetadataService.Metadata[] { gPicklist });//customField

	        // handle SaveResults if need    
	        errors = handleSaveResults(results[0]);
	    } catch (Exception ex) {
	    	errors.add(ex.getMessage());
	    }

	    return errors;
    }

	/*************************************************
    * @author: Binh Dang
    * Date: 17-Jul-2019
    * Description: Generate List of custom values from list of values
    * @param values apiName name. Must include Object API Name (e.g.: Contract.Product_Name__c) 
    * @return List of Custom Values
    * Revision: 
    *************************************************/
    private static List<MetadataService.CustomValue> generateCustomValueList(List<String> values) {
    	List<MetadataService.CustomValue> result = new List<MetadataService.CustomValue>();
    	for (String item : values) {
    		Metadataservice.CustomValue value = new MetadataService.CustomValue();
	        value.fullName = item;
	        value.default_x = false;
	        result.add(value);
    	}
    	return result;
	}
	
	/*************************************************
    * @author: Tuan Nguyen 
    * Date: 17-Jul-2019
    * Description: Get picklist values by record type
	* @param objName Object API Name (e.g.: Contract) 
	* @param fieldName Field API name. Does not include Object API Name (e.g.: Product_Name__c) 
	* @param recordTypeName Record Type API Name. (e.g.: LawyerGuard) 
    * @return List of Custom Values
    * Revision: 
    *************************************************/
	public static List<String> getPicklistValuesByRecordType(String objName, String fieldName, String recordTypeName) {
		List<String> result = new List<String>();
		List<String> errors = new List<String>();
		try {
			// Initialize service to call API
	        MetadataService.MetadataPort service = createService2();

			String apiName = objName + '.' + recordTypeName;

	        // Get Record Type info
	        MetadataService.RecordType recordType = 
	        	(MetadataService.RecordType) service.readMetadata('RecordType', 
				new String[] { apiName }).getRecords()[0];
			
			// loop through picklist values for this record type	
			for (MetadataService.RecordTypePicklistValue rpk : recordType.picklistValues) {
				// get specific picklist in the list
				if (rpk.picklist == fieldName) {
					for (MetadataService.PicklistValue pk : rpk.values) {
						result.add(String.valueof(pk.fullName));
					}
				}
			}

			System.debug(result);

		} catch (Exception ex) {
	    	errors.add(ex.getMessage());
	    }
		return result;
	}

	/*************************************************
    * @author: Binh Dang
    * Date: 17-Jul-2019
    * Description: Initialize service to call SOAP API
    * @return MetadataPort 
    * Revision: 
    *************************************************/
	public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
		//service.SessionHeader.sessionId = UserInfo.getSessionId();
		service.SessionHeader.sessionId = '{!$Credential.OAuthToken}';
        return service;
    }
    
    public static MetadataService.MetadataPort createService1() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = UserInfo.getSessionId();
        system.debug('service.SessionHeader.sessionId-----'+service.SessionHeader.sessionId);
        //String a = SessionIdController.getSessionId();
        //System.debug(a);
		//service.SessionHeader.sessionId = a;
        return service;
    }
	public static MetadataService.MetadataPort createService2() {
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		String sessionId = SessionIdController.getSessionId();
		service.SessionHeader.sessionId = sessionId;
		//System.debug(a);
		//System.debug(EncodingUtil.base64Encode(Blob.valueOf(a)));
		//string paramvalue = EncodingUtil.base64Encode(Blob.valueOf(userinfo.getSessionId()));
		//System.debug('paramvalue'+ paramvalue);
		//service.SessionHeader.sessionId = Userinfo.getSessionId();
		return service;
	}

	/*************************************************
    * @author: Binh Dang
    * Date: 17-Jul-2019
    * Description: Handling SaveResults
    * @return List of error messages
    * Revision: 
    *************************************************/
    public static List<String> handleSaveResults(MetadataService.SaveResult saveResult) {
        List<String> messages = new List<String>();
        // No error
        if (saveResult == null || saveResult.success)
            return messages;

        // Construct error message and throw an exception
        if (saveResult.errors != null) {
            messages.add(
                (saveResult.errors.size()==1 ? 'Error ' : 'Errors ') +
                    'occured processing component ' + saveResult.fullName + '.');
            for(MetadataService.Error error : saveResult.errors) {
                messages.add(
                    error.message + ' (' + error.statusCode + ').' +
                    ( error.fields!=null && error.fields.size()>0 ?
                        ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            }
        }
        if(!saveResult.success)
            messages.add('Request failed with no specified error.');

        return messages;
    }

    public class MetadataServiceExamplesException extends Exception { }
}