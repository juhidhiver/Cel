/**************************************************************************************************
 * Class Name: CommonAccountUtil
 * Author: 
 * Date: 
 * Description: Class to keep account trigger related logic
 **************************************************************************************************/
public class CommonAccountUtil {
    public static void generateExternalID(String fieldAPI, List<Account> accountList){
        CommonUtil.generateExternalID('Azure_ID__c', accountList);
    }
    /*************************************************
    * Method Name: copyBillingAddressToMailingAddress
    * Author:Long Ly
    * Date: 
    * Params: List<Account> newAccs 
    * Return: 
    * Exceptions:
    * Description: Copy billing address to shipping address is checkbox IsMailingSameWithBillingAddress__c is checked.
    * Revision: 
    * Can be moved to Flows: Yes
     *************************************************/
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
    * Method Name: insertKYCSanctionDate
    * Author: 
    * Date: 
    * Params: List<Account> newAccounts 
    * Return: 
    * Description: Populate sanction date to today's date on account insertion
    * Can be moved to Flows: Yes
     *************************************************/
    public static void insertKYCSanctionDate(List<Account> newAccounts){
        //Map<Id,Account> oldAccountMap = new Map<Id,Account>(oldAccounts);
        List<Account> accountList = new List<Account>();
        for(Account acc:newAccounts){
            /*
            if(acc.KYC_Status__c != null){
                system.debug('inside if'+acc.KYC_Status__c );
                acc.KYC_Date__c = date.today();                
            }*/
            //if(acc.Sanction_Status__c  != null){
            if(acc.AQ_Sanction_Status__c  != null || acc.CEL_Sanction_Status__c != Null){
                acc.Sanction_Date__c = date.today();                
            }
          
        }
    }
     /*************************************************
    * Method Name: accountsToSync
    * Author: 
    * Date: 
    * Params: List<Account> oldAccounts, List<Account> newAccounts 
    * Return: 
    * Description: Update sanction date on account to today's date when sanction status gets changed
    * Can be moved to Flows: Yes
     *************************************************/
    public static void updateKYCSanctionDate(List<Account> oldAccounts, List<Account> newAccounts){
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
            if(oldAccountMap.get(acc.id).AQ_Sanction_Status__c  != acc.AQ_Sanction_Status__c || oldAccountMap.get(acc.id).Cel_Sanction_Status__c  != acc.Cel_Sanction_Status__c){
                acc.Sanction_Date__c = date.today();
                addAcc = true;
            }
            if(addAcc) accountList.add(acc);            
        }
        //if(!accountList.isEmpty()) //update accountList;
    }
    /*************************************************
    * Method Name: addLocation
    * Author:Long Ly
    * Date: 16-May-2019 / adding the Location creation from Account
    * Params: Map<Id, Account> newAccMap, Map<Id, Account> oldAccMap, String triggerContext 
    * Return: 
    * Exceptions:
    * Description:Update the Location creation from Account to not create a location automatically if the Billing_PO_Box__c is true - Check Billing_PO_Box__c first
    * Revision: 
    * Can be moved to Flows: No
     *************************************************/ 
    public static void addLocation(Map<Id, Account> newAccMap, Map<Id, Account> oldAccMap, String triggerContext) {
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
    * Description: create locations based on the accounts billing address details
    * Revision: 
    * Can be moved to Flows: No
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
                
        List<Location__c> allLocations = LocationQueryUtil.fetchAllLocations(streets, cities, states, zipCodes, countries);

        Set<String> accountLocationsKeyInDb = new Set<String>();
        for(Account_Location__c accLoc : AccountLocationQueryUtil.fetchAccountLocations(newAccsMap.keySet())){
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
    * Description: Check location by comparing billing address fields with location address fields.
    * Revision: 
    * Can be moved to Flows: No
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
    
    /*************************************************
    * Method Name: isLocationError
    * Author:Long Ly
    * Date: 16-May-2019 / Check if List of allLocations is existed in the current Account
    * Params: Account acc, List<Location__c> allLocations 
    * Return: True if Location is existed
    * Exceptions:
    * Description: Check location by comparing billing address fields with location address fields.
    * Revision: 
    * Can be moved to Flows: No
     *************************************************/
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


    /*************************************************
    * Method Name: createAccountLocation
    * Author: Quan Tran
    * Date: 7-June-2019
    * Params:
    * Return:
    * Exceptions: 
    * Description: Show error message on account record if any error occured.
    * Can be moved to Flows: No
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
    * Params:Database.SaveResult[] srList, List<Location__c> locationsToInsert, List<Location__c> locationsError, List<Account> newAccs
    * Return:
    * Exceptions:  
    * Description:  Show error on account id location address matches with billing address.
    * Can be moved to Flows: No
     *************************************************/
    public static void createLocation (Database.SaveResult[] srList, List<Location__c> locationsToInsert, List<Location__c> locationsError, List<Account> newAccs)
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

    /*************************************************
    * Method Name: syncAccounts
    * Author: 
    * Date: 
    * Params: Map<id, Account> newDataMap 
    * Return: 
    * Description: Sync account by making API callout
    * Can be moved to Flows: No
     *************************************************/ 
    public static void syncAccounts(Map<id, Account> newDataMap){
        Map<Id, String> accMap = new Map<Id, String>();
        for(Id accId : newDataMap.keySet()){
            accMap.put(accId, 'C');
        }
        
        if(accMap.size()>0){        
            ID jobID = System.enqueueJob(new SyncAccountQueueable(accMap));
        }
    }

     /*************************************************
    * Method Name: accountsToSync
    * Author:Sarthak 
    * Date: 29-Oct-2020 
    * Params: List<Account> oldAccounts, List<Account> newAccounts 
    * Return: Set<id> accountIds
    * Description: Checks whether to Reverse Sync and then returns set of Account IDs to reverse sync to MW 
    * Can be moved to Flows: No
     *************************************************/ 
    public static void accountsToSync(List<Account> oldAccounts, List<Account> newAccounts){
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
        if(accountMap.size()>0)
            ID jobID = System.enqueueJob(new SyncAccountQueueable(accountMap));   
    }

    /*************************************************
    * Method Name: validateSanctionCheckOnInsert
    * Author: 
    * Date: 
    * Params: Map<id, Account> newDataMap 
    * Return: 
    * Description: This method calls a sanction search check on account Insert
    * Can be moved to Flows: No
     *************************************************/ 
    public static List<Sanction_Status__c> validateSanctionCheckOnInsert(List<Account> newAccounts, Boolean boolIsSynchronous){

        Set<Id> setAccountIds = new Set<Id>();
        if(UserInfo.getUserRoleId() != null){
            User loggedInUser =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id =: UserInfo.getUserId()];
            String runningUserRoleName = loggedInUser.UserRole.Name;
            for(Account acc : newAccounts){
            try{
                if(acc.Action_Point__c != 'Endorsement' && runningUserRoleName != null
                    && ((runningUserRoleName.contains('Aqueous') && acc.AQ_Sanction_Status__c == null && acc.BillingCountryCode != 'US')
                        || (runningUserRoleName.contains('Celerity') && acc.CEL_Sanction_Status__c == null))){
                            setAccountIds.add(acc.Id);
                }
            }
            catch (Exception e) {
                acc.adderror(e.getMessage());
            }
            }
        }

        if(!setAccountIds.isEmpty()){
            if(!boolIsSynchronous){
                SanctionSearchAPICallout.callAccountSanctionV2API_async(setAccountIds);
                return null;
            }
            else{
                List<Sanction_Status__c> lstUpdatedSanctions = SanctionSearchAPICallout.callAccountSanctionV2API(setAccountIds);
                return lstUpdatedSanctions;
            }
        }
        return null;
        
    }

    /*************************************************
    * Method Name: validateSanctionCheckOnInsert
    * Author: 
    * Date: 
    * Params: Map<id, Account> newDataMap 
    * Return: 
    * Description: This method calls a sanction search check on selecting any Existing Account
    * Can be moved to Flows: No
     *************************************************/ 
    @AuraEnabled
    public static List<Sanction_Status__c> validateSanctionCheckOnExistingAccount(Id accountId){
        List<Sanction_Status__c> sanctionStatus = new List<Sanction_Status__c>();
        List<Account> lstAccount = [SELECT Id, OwnerId, AQ_Sanction_Status__c, CEL_Sanction_Status__c, BillingCountryCode, Action_Point__c FROM Account WHERE Id =: accountId];
        if(!lstAccount.isEmpty()){
           sanctionStatus = validateSanctionCheckOnInsert(lstAccount, true);
        }
        return sanctionStatus;
    }

    /*************************************************
    * Method Name: validateSanctionCheck
    * Author: 
    * Date: 
    * Params: Map<id, Account> newDataMap 
    * Return: 
    * Description: This method calla a sanction search check on account Update
    * Can be moved to Flows: No
     *************************************************/ 
    public static void validateSanctionCheckOnUpdate(List<Account> oldAccounts, List<Account> newAccounts){

        Map<Id,Account> oldAccountMap = new Map<Id,Account>(oldAccounts);
        Set<Id> setAccountIds = new Set<Id>();
        if(UserInfo.getUserRoleId() != null){
            User loggedInUser =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id =: UserInfo.getUserId()];
            String runningUserRoleName = loggedInUser.UserRole.Name;
            for(Account acc : newAccounts){
                if((oldAccountMap.get(acc.id).Name != acc.Name ||
                oldAccountMap.get(acc.id).BillingCountry != acc.BillingCountry ||
                oldAccountMap.get(acc.id).BillingCountryCode != acc.BillingCountryCode) && 
                runningUserRoleName != null && ((runningUserRoleName.contains('Aqueous') && acc.BillingCountryCode != 'US') || runningUserRoleName.contains('Celerity'))
                && acc.Action_Point__c != 'Endorsement'){
                    setAccountIds.add(acc.Id);
                }
            }
        }

        if(!setAccountIds.isEmpty()){
            SanctionSearchAPICallout.callAccountSanctionV2API_async(setAccountIds);
        }
        
    }


    public static String getAppName() {
        UserAppInfo userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
        AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition Where DurableId = :userAppInfo.AppDefinitionId LIMIT 1];
        return appDefinition.Label;
    }
    
    /***** for CD-167 ******/
    public static void generatePolicyDocuments(List<Account> oldAccounts, List<Account> newAccounts){
         Map<Id,Account> oldAccountMap = new Map<Id,Account>(oldAccounts);
   
        for(Account newAcc : [select id,recordtype.Name,AQ_Sanction_Status__c,Cel_Sanction_Status__c,Insured_Account_Update_Policy_Id__c,Action_Point__c from Account where id In:newAccounts]){
            if(oldAccountMap.get(newAcc.Id).AQ_Sanction_Status__c != 'Cleared' && newAcc.AQ_Sanction_Status__c == 'Cleared'
               && newAcc.Action_Point__c == 'Endorsement' && newAcc.Insured_Account_Update_Policy_Id__c != null && newAcc.recordtype.Name=='Business'){
                   system.debug('queueable call');
               System.enqueueJob(new QueuablePolicyDocumentGenerate(newAcc.Id,newAcc.Insured_Account_Update_Policy_Id__c));
           }
        }
    }

   /*************************************************
    * Method Name: SanctionNotificationOnRequestingClearance
    * Author:Mary Elizabeth 
    * Date: 12-04-2022 
    * Params: Map<Id, Account> oldDataMap,List<Account> newDataList
    * Description: Sends Bell notification to Level 1 user on requesting Clearance 
                    Sends Bell notification to Level 2,3,4 user on Declining or Clearing the Sanctions 
    * Can be moved to Flows: yes
     *************************************************/ 


     public static void SanctionNotificationOnRequestingClearance(Map<Id, Account> oldDataMap,List<Account> newDataList)
     {
 
         set<Id> targetId = new set<Id>();
         if(newDataList.size() > 0 )
         {
             for (Account newSanc : newDataList )
             {
                 
                 if(newSanc.Review_Requested__c == true && oldDataMap.get(newSanc.id).Review_Requested__c != true){
                    // targetId.add(newSanc.id);
                     CustomNotification.requestSanctionClearance(newSanc.id,newSanc.Name);
                 }
 
                 if(newSanc.AQ_Sanction_Status__c == 'Failed' && oldDataMap.get(newSanc.id).AQ_Sanction_Status__c == 'Potential Match')
                 {
                     CustomNotification.notificationDeclineSanction(newSanc.id,newSanc.Name);
                 }
                 
                 if(newSanc.AQ_Sanction_Status__c == 'Cleared' && oldDataMap.get(newSanc.id).AQ_Sanction_Status__c == 'Potential Match')
                 {
                     CustomNotification.notificationApprovingClearance(newSanc.id,newSanc.Name);
                 }

             }
         }
     }

      /*************************************************
    * Method Name: declineMainSubmission
    * Author:Mary Elizabeth 
    * Date: 30-05-2022 
    * Params: List<Account> newDataList , List<Account> oldDataList
    * Description: Declines the Main submission (Submissions in related
                 of Additional Insured Account) when the Additional Insured Account's Sanction 
                 is marked as declined from potential match
    * Can be moved to Flows: No
     *************************************************/ 
    public static void declineMainSubmission(List<Account> newDataList , List<Account> oldDataList)
    { 
        Set<Id> setAccIds = new Set<Id>();
        Set<Id> oppSetIds = new Set<Id>();
        List<Account> listAdditionalInsured = new List<Account>();
        List<Opportunity> additionalInsuredToUpdateOpps =  new List<Opportunity>();
        for(Account newAcc : newDataList){
            for(Account oldAcc : oldDataList){
            if(newAcc.AQ_Sanction_Status__c == 'Failed' 
                && oldAcc.AQ_Sanction_Status__c == 'Potential Match' 
                && newAcc.Decline_Reason__c == 'Sanctioned Entity' 
                && oldAcc.Decline_Reason__c == null ){
                setAccIds.add(newAcc.id);
                }
            }
        }
     if(!setAccIds.isEmpty()){
     listAdditionalInsured = [SELECT Id, (Select id, Submission__c from Additional_Insured__r) 
                                FROM Account WHERE Id in: setAccIds];}
    
     for(Account acc : listAdditionalInsured)
     {
         for(Additional_Insured__c addIns : acc.Additional_Insured__r)
          oppSetIds.add(addIns.Submission__c);
     }
     for(Opportunity opp : [Select id, AccountId,StageName from opportunity where id in: oppSetIds and StageName != 'Closed Won'] ){
        if(opp.StageName != 'Closed Lost'){
          opp.Submission_Status__c = 'Declined';
          opp.StageName = 'Closed Lost' ;
          opp.Loss_Reason__c = 'Sanctioned Entity';
          additionalInsuredToUpdateOpps.add(opp);
        }
    }
     if(!additionalInsuredToUpdateOpps.isEmpty()) update additionalInsuredToUpdateOpps;
    }

    /**************************** Update Renewals related to Account *********************/
    public static void updateRenewalRecord(List<Account> newDataList ,Map<Id, Account> oldDataMap){

        Map<Id,String> mapOfAccWarningMap = new  Map<Id,String>();

        List<Renewal__c> updateRenewals = new List<Renewal__c>();

        if(newDataList.size() > 0 ){
            for (Account newaccRec : newDataList ){
                if(newaccRec.Renewal_Warning_Reason__c != oldDataMap.get(newaccRec.id).Renewal_Warning_Reason__c){
                    mapOfAccWarningMap.put(newaccRec.Id,newaccRec.Renewal_Warning_Reason__c);
                }
            }

           for(Renewal__c renRecord  : [select id,Renewal_Warning_Reason__c,Insured_Account__c from Renewal__c where Insured_Account__c IN: mapOfAccWarningMap.keySet()]){
            updateRenewals.add(new Renewal__c(Id=renRecord.Id, Renewal_Warning_Reason__c = mapOfAccWarningMap.get(renRecord.Insured_Account__c)));
           }

           if(updateRenewals.size()>0){
            update updateRenewals;
           }


        }



    }

    
    

/*************************************************
    * Method Name: onUpdateAccName
    * Author:Mary Elizabeth 
    * Date: 2-2-2022 
    * Params: List<Account> oldAccounts, List<Account> newAccounts 
    * Description: Updates the Quote and Submission Name when Account Name is Updated 
    * Can be moved to Flows: No
     *************************************************/ 
/*
    public static void onUpdateAccName(list<Account> oldAccount, list<Account> newAccount)
    {
        map<String,String> accIdToNewMap = new map<String,String>();
        map<String,String> accIdtoOldMap = new map<String,String>();
        list<Opportunity> oppListRelatedQuote = new list<Opportunity>();
        list<Opportunity> oppR = new list<Opportunity>();
        list<Quote> quoteR  = new  list<Quote>();
        List<String> qStatus = new List<String>{'Bound','Rejected','Closed'};
        List<String> oppStage = new List<String>{'Closed Lost','Closed Won'};
        for(Account acc : newAccount)
        {
            accIdToNewMap.put(acc.Id,acc.Name);
        }
        for(Account acc : oldAccount)
        {
            accIdtoOldMap.put(acc.Id,acc.Name);
        }
        if(accIdToNewMap.size() > 0)
        {
            oppListRelatedQuote = [Select Name , id , AccountId, createdDate, StageName, Product_Name__c,
                                    (Select Name , id, Status 
                                        from Quotes 
                                        where Status NOT IN:qStatus) 
                                    from Opportunity 
                                    where AccountId =: accIdToNewMap.keyset() and Product_Name__c='Professional Indemnity'];
            System.debug('oppListRelatedQuote---'+oppListRelatedQuote);
        }

        if(oppListRelatedQuote.size() > 0){
            for(Opportunity opp: oppListRelatedQuote)
            {
                String oldName = accIdtoOldMap.get(opp.AccountId);
                String newName = accIdToNewMap.get(opp.AccountId);
                if(opp.StageName == 'New' || opp.StageName == 'Qualified' || opp.StageName == 'Declined' ){
                opp.Name = opp.Name.replace(oldName,newName);
                oppR.add(opp);
                }
                for(Quote q : opp.Quotes)
                {   q.Name = q.Name.replace(oldName, newName);
                    quoteR.add(q);   
                }
            }
        }
       // if(oppR.size()>0)update oppR;
       // if(quoteR.size()>0 && oppR.size()>0)update quoteR;
    }*/
}