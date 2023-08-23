/**************************************************************************************************
 * Class Name: AccountLocationTriggerHandler
 * Author:Quan Tran 
 * Date: 19-August-2019
 * Description: Handler for AccountTrigger
 **************************************************************************************************/
public with sharing class  AccountTriggerHandler extends TriggerHandler{
    private List<Account> oldDataList;
	private List<Account> newDataList;
	private Map<Id, Account> newDataMap;
	private Map<Id, Account> oldDataMap;
    public static String Operation;
    
    public AccountTriggerHandler (){  
		this.oldDataList = (List<Account>) Trigger.old;
		this.newDataList = (List<Account>) Trigger.new;
		this.newDataMap = (Map<Id, Account>) Trigger.newMap;
		this.oldDataMap = (Map<Id, Account>) Trigger.oldMap;
    }

	public override void beforeInsert()	{
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);
        copyBillingAddressToMailingAddress(newDataList); 
        insertKYCSanctionDate(newDataList);
        
        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        List<Account> brokerAccount = new List<Account>();
        for(Account account : newDataList) {
            if(account.RecordTypeId == recordTypeBrokerAgency)
                brokerAccount.add(account);
        }
        if(!brokerAccount.isEmpty())
            checkAppointedbyAQ(brokerAccount,oldDataMap);
    }

	public override void beforeUpdate() {
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);
        copyBillingAddressToMailingAddress(newDataList);
        updateKYCSanctionDate(oldDataList, newDataList);
        
        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        List<Account> brokerAccount = new List<Account>();
        for(Account account : newDataList) {
            if(account.RecordTypeId == recordTypeBrokerAgency)
                brokerAccount.add(account);
        }
        if(!brokerAccount.isEmpty())
            checkAppointedbyAQ(brokerAccount,oldDataMap);
    }

	public override void afterInsert(){        
		addLocation(newDataMap, null, 'Insert');
        //updateNIPRFlafByCallOut(newDataList, null);
        Map<Id, String> accMap = new Map<Id, String>();
        for(Id accId : newDataMap.keySet()){
            accMap.put(accId, 'C');
        }
        
        if(accMap.size()>0){        
        ID jobID = System.enqueueJob(new SyncAccountQueueable(accMap));
        }
        
        Id recordTypeBrokerAgency = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        List<Account> brokerAccount = new List<Account>();
         for(Account account : newDataList) {
                if(account.RecordTypeId == recordTypeBrokerAgency)
                    brokerAccount.add(account);
            }
        if(!brokerAccount.isEmpty())
      	createBrokerAccountProduct(brokerAccount);
	}

    public override void afterUpdate() {        
        //updateNIPRFlafByCallOut(newDataList, oldDataMap);
        //if (UserInfo.getName() != Label.IntegrationAPI){ //To run this change the label value to correct user name
            Map<Id,String> accMap = accountsToSync(oldDataList, newDataList);
            if(accMap.size()>0){
                ID jobID = System.enqueueJob(new SyncAccountQueueable(accMap));
            }
        //}    
    }

    /*************************************************
    * Method Name: addLocation
    * Author:Long Ly
    * Date: 16-May-2019 / adding the Location creation from Account
    * Params: Map<Id, Account> newAccMap, Map<Id, Account> oldAccMap, String triggerContext 
    * Return: 
    * Exceptions:
    * Revision: 
     *************************************************/ 
    public static void addLocation(Map<Id, Account> newAccMap, Map<Id, Account> oldAccMap, String triggerContext) {
        /* Long Ly - 05/14/2019 - 1) Update the Location creation from Account 
        to not create a location automatically 
        if the Billing_PO_Box__c is true - Check Billing_PO_Box__c first
        */
        Map<Id, Account> newAccMapTemp = newAccMap;
        newAccMap = new Map<Id, Account>();
        for (Account newAcc : newAccMapTemp.values()) {
           if(!newAcc.Billing_PO_Box__c) newAccMap.put(newAcc.Id, newAcc);
        }
  
        // Case insert
        if (triggerContext == 'Insert') addMailingAddressIntoLocationObj(newAccMap.values());
    }
    
    /*************************************************
    * Method Name: addMailingAddressIntoLocationObj
    * Author:Long Ly
    * Date: 16-May-2019 /
    * Params: List<Account> newAccs 
    * Return: 
    * Exceptions:
    * Revision: 
     *************************************************/
    private static void addMailingAddressIntoLocationObj(List<Account> newAccs) {
        Set<String> streets = new Set<String>();
        Set<String> cities = new Set<String>();
        Set<String> states = new Set<String>();
        Set<String> zipCodes = new Set<String>();
        Set<String> countries = new Set<String>();
		
        Map<Id, Account> newAccsMap = new Map<Id, Account>(newAccs);
                
        for (Account newAcc : newAccs) {
            if (String.isNotBlank(newAcc.BillingStreet)) streets.add(newAcc.BillingStreet);
            if (String.isNotBlank(newAcc.BillingCity)) cities.add(newAcc.BillingCity);
            if (String.isNotBlank(newAcc.BillingState)) states.add(newAcc.BillingState);
            if (String.isNotBlank(newAcc.BillingPostalCode)) zipCodes.add(newAcc.BillingPostalCode);
            if (String.isNotBlank(newAcc.BillingCountry)) countries.add(newAcc.BillingCountry);
        }
                
        List<Location__c> allLocations = [Select Id, Name, Address__c, City__c, State_Province__c,
											Postal_Code__c, Country__c, County__c //Ly Long 06/21/2019
											From Location__c Where Address__c IN :streets
											And City__c IN :cities
											And State_Province__c IN :states
											And Postal_Code__c IN :zipCodes
											And Country__c IN :countries
											Limit 50000	];

        Set<String> accountLocationsKeyInDb = new Set<String>();
        for (Account_Location__c accLoc : [Select Id, Account__c, Location__c From Account_Location__c
											Where Account__c In :newAccsMap.keySet()]) 
		{
            String key = accLoc.Account__c + '' + accLoc.Location__c;
            accountLocationsKeyInDb.add(key);
        }
            
        List<Account_Location__c> accLocationsToCreate = new List<Account_Location__c>();
        Map<Id, Location__c> accountIdAndLocationMap = new Map<Id, Location__c>();
        for (Account newAcc : newAccs) {
            // Check if location is existed
            Location__c existedLocation = isLocationExisted(newAcc, allLocations);            
            if(existedLocation != null) 
			{            
                // If location is existed, continue to check account location
                Account_Location__c accLocation = new Account_Location__c(Account__c = newAcc.Id,Location__c = existedLocation.Id);

                //4-16-2019 : modified by Tran Quan
                Location__c updateLocation = [SELECT Id FROM Location__c WHERE Id = :existedLocation.Id LIMIT 1];
                updateLocation.Geolocation__Longitude__s = newAcc.BillingLongitude;
                updateLocation.Geolocation__Latitude__s = newAcc.BillingLatitude;
                update updateLocation;
                // end modified by Tran Quan on 4-16-2019

                String accLocationKey = accLocation.Account__c + '' + accLocation.Location__c;
                if (!accountLocationsKeyInDb.contains(accLocationKey)) accLocationsToCreate.add(accLocation);
                // If location isn't existed, create new location then new account location
            }else 
			{                       
                if(String.isNotBlank(newAcc.BillingStreet)
                    && String.isNotBlank(newAcc.BillingCity)
                    && String.isNotBlank(newAcc.BillingPostalCode)) {
                        Location__c newLocation = new Location__c(
                            Address__c = newAcc.BillingStreet,          // Required
                            City__c = newAcc.BillingCity,               // Required
                            State_Province__c = newAcc.BillingState,
                            //State_Code__c = newAcc.BillingStateCode,
                            Postal_Code__c = newAcc.BillingPostalCode,  // Required
                            Country__c = newAcc.BillingCountry,
                            County__c = newAcc.Billing_County__c        
                            //Country_Code__c = newAcc.BillingCountryCode
                        ); 

                        //4-16-2019 : modified by Tran Quan                        
                        if(newAcc.BillingLongitude != null) 
                            newLocation.Geolocation__Longitude__s = newAcc.BillingLongitude;
                        
                        if(newAcc.BillingLatitude != null) 
                            newLocation.Geolocation__Latitude__s  = newAcc.BillingLatitude;
                          
                        // end modified by Tran Quan on 4-16-2019    
                        accountIdAndLocationMap.put(newAcc.Id, newLocation);
                    }                    
            }
        }
       
        // Create account location
        if(!accLocationsToCreate.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(accLocationsToCreate, false);   
            createAccountLocation(srList, newAccsMap, accLocationsToCreate);         
        }
        
        // Create location then account location
        if(accountIdAndLocationMap.isEmpty()) return;
        
        List<Location__c> locationsToInsert = accountIdAndLocationMap.values();
        List<Location__c> locationsError = new List<Location__c>();
        
        // Create location
        Database.SaveResult[] srList2 = Database.insert(locationsToInsert, false);
        createLocation(srList2, locationsToInsert, locationsError, newAccs);
       
        List<Account_Location__c> accLocations2ToCreate = new List<Account_Location__c>();
        for (Account newAcc : newAccs) {
            if (accountIdAndLocationMap.get(newAcc.Id) != null) {
                Location__c currentLocation = accountIdAndLocationMap.get(newAcc.Id);
                if (!isLocationError(currentLocation, locationsError)) {
                    Account_Location__c accLocation = new Account_Location__c(Account__c = newAcc.Id,Location__c = currentLocation.Id);
                    accLocations2ToCreate.add(accLocation);
                }
            }
        }
                
        if (!accLocations2ToCreate.isEmpty()) 
            Database.SaveResult[] srList3 = Database.insert(accLocations2ToCreate, false); // Create account location
    }
    
    /*************************************************
    * Method Name: isLocationExisted
    * Author:Long Ly
    * Date: 16-May-2019 / Check if List of allLocations is existed in the current Account
    * Params: Account acc, List<Location__c> allLocations 
    * Return: True if Location is existed
    * Exceptions:
    * Revision: 
     *************************************************/
    public static Location__c isLocationExisted(Account acc, List<Location__c> allLocations) {
        if (!allLocations.isEmpty()) {
            for (Location__c location : allLocations) {
                if (location.Address__c == acc.BillingStreet
                    && location.City__c == acc.BillingCity
                    && location.State_Province__c == acc.BillingState
                    && location.Postal_Code__c == acc.BillingPostalCode
                    && location.Country__c == acc.BillingCountry )   
					return location;
                    
            }
        }
        return null;
    }
    
    private static Boolean isLocationError(Location__c loc, List<Location__c> allLocations) {
        if (!allLocations.isEmpty()) {
            for (Location__c location : allLocations) {
                if (location.Address__c == loc.Address__c
                    && location.City__c == loc.City__c
                    && location.State_Province__c == loc.State_Province__c
                    && location.Postal_Code__c == loc.Postal_Code__c
                    && location.Country__c == loc.Country__c ) 
		            return true;
                    
            }
        }
        return false;
    }
    
    public static void copyBillingAddressToMailingAddress(List<Account> newAccs) {
        for (Account newAcc : newAccs) {
            if (newAcc.IsMailingSameWithBillingAddress__c) {
                newAcc.ShippingStreet = newAcc.BillingStreet;
                newAcc.ShippingCity = newAcc.BillingCity;
                newAcc.ShippingState = newAcc.BillingState;
                //newAcc.ShippingStateCode = newAcc.BillingStateCode;
                newAcc.ShippingPostalCode = newAcc.BillingPostalCode;
                newAcc.ShippingCountry = newAcc.BillingCountry;
                newACc.Shipping_County__c = newAcc.Billing_County__c;	//Ly Long 06/21/2019
                //newAcc.ShippingCountryCode = newAcc.BillingCountryCode;
            }
        }
    }

    /*************************************************
    * Method Name: createAccountLocation
    * Author: Quan Tran
    * Date: 7-June-2019
    * Params:
    * Return:
    * Exceptions:    
     *************************************************/
    public static void createAccountLocation(Database.SaveResult[] srList, Map<Id, Account> newAccsMap, List<Account_Location__c> accLocationsToCreate){            
                // Iterate through each returned result
                for (Integer i = 0; i < srList.size(); i++) {
                    Database.SaveResult sr = srList[i];
                    if (!sr.isSuccess()) {
                        String error = CommonUtil.getDatabaseErrorMessage(sr.getErrors());
                        Id idAccountError = Id.valueOf(accLocationsToCreate[i].Account__c);
                        if (newAccsMap.get(idAccountError) != null) {
                            newAccsMap.get(idAccountError).addError(error);
                        }
                    }
                }            
    }

    /*************************************************
    * Method Name: createLocation
    * Author: Quan Tran
    * Date: 7-June-2019
    * Params:
    * Return:
    * Exceptions:    
     *************************************************/
    public static void createLocation (Database.SaveResult[] srList, List<Location__c> locationsToInsert,
										List<Location__c> locationsError, List<Account> newAccs)
	{
        // Iterate through each returned result
        for (Integer i = 0; i < srList.size(); i++) 
		{
            Database.SaveResult sr = srList[i];
            if (!sr.isSuccess()) {
                String error = CommonUtil.getDatabaseErrorMessage(sr.getErrors());
                Location__c locationError = locationsToInsert[i];
                locationsError.add(locationError);
                // From location error, find account that generate this location
                for (Account newAcc : newAccs) {
                    if (locationError.Address__c == newAcc.BillingStreet
                        && locationError.City__c == newAcc.BillingCity
                        && locationError.State_Province__c == newAcc.BillingState
                        && locationError.Postal_Code__c == newAcc.BillingPostalCode
                        && locationError.Country__c == newAcc.BillingCountry
						//&& locationError.County__c == newAcc.Billing_County__c  //Ly Long 06/21/2019
                        ) { 
                            newAcc.addError(error);
                        }
                }
            }
        }
    }


    /*----------------------------------------------------------------------
    * Method Name: addLocation
    * Description: Update NIPR Flaf In Account By CallOut
    * Params: List<Account> listNewAccount, Map<Id, Account> oldDataMap
    * Author: Khanh TRAN
    * Date: 12-Nov-2019
    *----------------------------------------------------------------------
    */
    /*private static void updateNIPRFlafByCallOut(List<Account> listNewAccount, Map<Id, Account> oldDataMap) {
        Id recordTypeBrokerAgency = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();

        List<Id> accountIds = new List<Id>();
        if(oldDataMap == null) {//Insert case
            for(Account account : listNewAccount) {
                if(account.RecordTypeId == recordTypeBrokerAgency  && account.FEIN__c != null) 
                {
                    accountIds.add(account.Id);
                }
            }
        } else {//Update case
            for(Account account : listNewAccount) {
				Decimal newFein = account.FEIN__c;
                Decimal oldFein = oldDataMap.get(account.Id).FEIN__c;
                if(account.RecordTypeId == recordTypeBrokerAgency && 
					newFein != null && newFein != oldFein) {
                    accountIds.add(account.Id);
                }
            }           
        }
        
        if(!accountIds.isEmpty()) Invsk_Callout.getNIPRCallOut(accountIds);
    }*/
    
     /*************************************************
    * Method Name: accountsToSync
    * Author:Sarthak 
    * Date: 29-Oct-2020 
    * Params: List<Account> oldAccounts, List<Account> newAccounts 
    * Return: Set<id> accountIds
    * Description: Checks whether to Reverse Sync and then returns set of Account IDs to reverse sync to MW 
     *************************************************/ 
    private static Map<Id,String> accountsToSync(List<Account> oldAccounts, List<Account> newAccounts){
        Map<Id,Account> oldAccountMap = new Map<Id,Account>(oldAccounts);
        Map<Id,String> accountMap = new Map<Id,String>();
        
        for(Account acc:newAccounts ){
            if(oldAccountMap.get(acc.id).Name !=acc.Name ||oldAccountMap.get(acc.id).Type !=acc.Type||
			   oldAccountMap.get(acc.id).BillingStreet !=acc.BillingStreet||
               oldAccountMap.get(acc.id).BillingCity !=acc.BillingCity||
               oldAccountMap.get(acc.id).BillingState !=acc.BillingState||
               oldAccountMap.get(acc.id).BillingStateCode !=acc.BillingStateCode||
               oldAccountMap.get(acc.id).BillingPostalCode !=acc.BillingPostalCode||
               oldAccountMap.get(acc.id).BillingCountry !=acc.BillingCountry||
               oldAccountMap.get(acc.id).BillingCountryCode !=acc.BillingCountryCode||
               oldAccountMap.get(acc.id).Billing_County__c!=acc.Billing_County__c){
                accountMap.put(acc.Id, 'U');
            }
        }
        return accountMap;       
    }
    
    private static void updateKYCSanctionDate(List<Account> oldAccounts, List<Account> newAccounts){
        Map<Id,Account> oldAccountMap = new Map<Id,Account>(oldAccounts);
        List<Account> accountList = new List<Account>();
        
        for(Account acc:newAccounts){
            boolean addAcc = false;
            /*
            if(oldAccountMap.get(acc.id).KYC_Status__c != acc.KYC_Status__c){
                acc.KYC_Date__c = date.today();
                addAcc = true;
            }*/
            //if(oldAccountMap.get(acc.id).Sanction_Status__c  != acc.Sanction_Status__c){
            if(oldAccountMap.get(acc.id).AQ_Sanction_Status__c  != acc.AQ_Sanction_Status__c){
                acc.Sanction_Date__c = date.today();
                addAcc = true;
            }
            if(addAcc) accountList.add(acc);            
        }
        //if(!accountList.isEmpty()) //update accountList;
    }
    
    
    private static void insertKYCSanctionDate(List<Account> newAccounts){
        //Map<Id,Account> oldAccountMap = new Map<Id,Account>(oldAccounts);
        List<Account> accountList = new List<Account>();
        system.debug('new'+newAccounts);
        for(Account acc:newAccounts){
            /*
            if(acc.KYC_Status__c != null){
                system.debug('inside if'+acc.KYC_Status__c );
                acc.KYC_Date__c = date.today();                
            }*/
            //if(acc.Sanction_Status__c  != null){
            if(acc.AQ_Sanction_Status__c  != null){
                acc.Sanction_Date__c = date.today();                
            }          
        }
    }
       private void createBrokerAccountProduct(List<Account> brokerAccounts)
   {
       List<Account_Product__c> accountPrdList = new List<Account_Product__c>();
       
       List<Product2> prdList= [Select Id, Name, RecordType.Id, RecordType.Name From Product2 WHERE
                                IsActive = true AND RecordType.Name ='Celerity'];
       for(Account brokerAcc : brokerAccounts)
       {
           for(Product2 prd : prdList){
           Account_Product__c accPrd = new Account_Product__c();
           accPrd.Account_Id__c = brokerAcc.Id;
           accPrd.Product_Id__c = prd.Id;
           accPrd.Commission_percentage__c = 15; 
               system.debug('accPrd--'+accPrd);
           accountPrdList.add(accPrd);
           }
       }
       if(!accountPrdList.isEmpty())
       insert accountPrdList;
     
   }
    
    private static void checkAppointedbyAQ(List<Account> newBrokerAccounts,  Map<Id, Account> oldAccsMap){
        Id profileId = userinfo.getProfileId();       
        String profileName = [Select Id, Name from Profile where Id =: profileId].Name;   
        system.debug('ProfileName' + profileName);
        
        for(Account acc : newBrokerAccounts){
            if(Trigger.isInsert){
                if(profileName == 'Aqueous Underwriter'){
                    acc.Pending_By_Aqueous__c = true;
                }
            }else{
                if(acc.Appointed__c == true && oldAccsMap.get(acc.Id).Appointed__c != true && 
                   oldAccsMap.get(acc.Id).Pending_By_Aqueous__c == true){
                       acc.Pending_By_Aqueous__c = false;
                 }
            } 
        }
    }
}