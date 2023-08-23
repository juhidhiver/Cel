/**
 * @File Name          : GenerateElementLwcController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 3/30/2020, 10:23:29 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    3/30/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class GenerateElementLwcController {
    @AuraEnabled(cacheable=true)
    public static ResultResponse getCountryStateMap() {

        

        Long startTime = Datetime.now().getTime();
        System.debug('Start Execution '+startTime  );
        ResultResponse result = new ResultResponse();
        try{
            MetadataService.MetadataPort service = MetadataUtil.createService1();
            MetadataService.AddressSettings addressSetting =
                        (MetadataService.AddressSettings) service.readMetadata('AddressSettings',
                            new String[] { 'Address' }).getRecords()[0];
            List<CountryWrapper> countryWrappers = new List<CountryWrapper>();
            List<String> countryList = new List<String>();
            Map<String,List<String>> countryStateMap = new Map<String,List<String>>();
            for(MetadataService.Country country : addressSetting.countriesAndStates.countries){
                CountryWrapper countryWrapper = new CountryWrapper(country.label, country.isoCode);

                if(country.states != null && !country.states.isEmpty()){
                    List<StateWrapper> states = new List<StateWrapper>();
                    for(MetadataService.State state : country.states){
                        StateWrapper stateWrap = new StateWrapper(state.label, state.isoCode);
                        states.add(stateWrap);

                    }
                    countryWrapper.states = states;
                }
                countryWrappers.add(countryWrapper);
            }

            result.data = countryWrappers;
            result.isSuccess = true;
        }catch(Exception ex){
            System.debug(ex.getMessage());
            result.errors.add('Fail to get main sections, Please contact your administrator.');
            result.data = null;
        }
        Long endTime = Datetime.now().getTime() ;
        System.debug('End Time  ' + endTime);
        Long totalTime = endTime - startTime;
        System.debug('Total' + totalTime);
        return result;
    }

    @AuraEnabled
    public static ResultResponse getCountryStateMapLwc() {
        ResultResponse result = new ResultResponse();
        try{
            MetadataService.MetadataPort service = MetadataUtil.createService1();
            MetadataService.AddressSettings addressSetting =
                        (MetadataService.AddressSettings) service.readMetadata('AddressSettings',
                            new String[] { 'Address' }).getRecords()[0];
            List<CountryWrapper> countryWrappers = new List<CountryWrapper>();
            List<String> countryList = new List<String>();
            Map<String,List<String>> countryStateMap = new Map<String,List<String>>();
            for(MetadataService.Country country : addressSetting.countriesAndStates.countries){
                CountryWrapper countryWrapper = new CountryWrapper(country.label, country.isoCode);
                
                if(country.states != null && !country.states.isEmpty()){
                    List<StateWrapper> states = new List<StateWrapper>();
                    for(MetadataService.State state : country.states){
                        StateWrapper stateWrap = new StateWrapper(state.label, state.isoCode);
                        states.add(stateWrap);
                        
                    }
                    countryWrapper.states = states;
                }
                countryWrappers.add(countryWrapper);
            }
            System.debug('@@@countryWrappers: ' + countryWrappers);
            result.data = countryWrappers;
            result.isSuccess = true;
        }catch(Exception ex){
            System.debug(ex.getMessage());
            result.errors.add('Fail to get main sections, Please contact your administrator.');
            result.data = null;
        }
        return result;
    }

    @AuraEnabled
    public static string readJSON(){
        StaticResource sr= [SELECT Id, body FROM StaticResource WHERE Name = 'countryJsonState' Limit 1];
        String allcontents = sr.body.toString();
        return allcontents;
    }

    public class CountryWrapper {
        @AuraEnabled public String      label                   {get; set;}
        @AuraEnabled public String      isoCode                 {get; set;}
        @AuraEnabled public List<StateWrapper>      states      {get; set;}
        public CountryWrapper(String label, String isoCode){
            this.label = label;
            this.isoCode = isoCode;
        }
    }
    public class StateWrapper {
        @AuraEnabled public String      label       {get; set;}
        @AuraEnabled public String      isoCode     {get; set;}
        public StateWrapper(String label, String isoCode){
            this.label = label;
            this.isoCode = isoCode;
        }
    }
}