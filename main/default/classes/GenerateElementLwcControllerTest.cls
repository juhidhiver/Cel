@isTest
public class GenerateElementLwcControllerTest {
	private class MetadataImplAddressServiceMock implements WebServiceMock {
		public void doInvoke(Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName, String responseNS,
			String responseName, String responseType) {   
            
            MetadataService.State state = new MetadataService.State();
            state.label = 'California';
            state.isoCode =  'CA';
                
            MetadataService.Country country = new MetadataService.Country();
            country.label = 'United States';
            country.isoCode = 'US';
            country.states = new List<MetadataService.State>{state};
                
            MetadataService.CountriesAndStates conAndStates = new MetadataService.CountriesAndStates();
            conAndStates.countries = new List<MetadataService.Country>{country};
                
            MetadataService.AddressSettings addrSetting = new MetadataService.AddressSettings();
            addrSetting.countriesAndStates = conAndStates;
                
            MetadataService.ReadAddressSettingsResult addrResult = new MetadataService.ReadAddressSettingsResult();
            addrResult.records = new List<MetadataService.AddressSettings>{addrSetting};
                
            MetadataService.readAddressSettingsResponse_element addrResponse = new MetadataService.readAddressSettingsResponse_element();
            addrResponse.result = addrResult;    
			//System.assertEquals(true,request instanceof MetadataService.readMetadata_element);
            /*MetadataService.GlobalValueSet gblValSet = new MetadataService.GlobalValueSet();
            gblValSet.customValue = new List<MetadataService.CustomValue>{new MetadataService.CustomValue()};
            gblValSet.description = 'For testing';
            gblValSet.masterLabel = 'Test';
            gblValSet.sorted = true;
                
            MetadataService.ReadGlobalValueSetResult readResult = new MetadataService.ReadGlobalValueSetResult();
            readResult.records = new List<MetadataService.GlobalValueSet>{gblValSet};    
                
            MetadataService.readGlobalValueSetResponse_element readResponse = new MetadataService.readGlobalValueSetResponse_element();
            readResponse.result = readResult;*/
            if(request instanceof MetadataService.updateMetadata_element) {
	            response.put('response_x', new MetadataService.updateMetadataResponse_element());
			} else if(request instanceof  MetadataService.deleteMetadata_element) {
	            response.put('response_x', new MetadataService.deleteMetadataResponse_element());
            } else if(request instanceof MetadataService.readMetadata_element) {
                //System.assertEquals(false,request instanceof MetadataService.readMetadata_element);
                response.put('response_x', addrResponse);
            }
                
                
            
		}
	}
    
    @isTest
    public static void testgetCountryStateMap() {
        Test.startTest();
        System.Test.setMock(WebServiceMock.class, new MetadataImplAddressServiceMock());
        GenerateElementLwcController.getCountryStateMap();
        GenerateElementLwcController.getCountryStateMapLwc();
        GenerateElementLwcController.readJSON();
        Test.stopTest();
    }
}