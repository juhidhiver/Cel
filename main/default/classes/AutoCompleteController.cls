public with sharing class AutoCompleteController {
    @AuraEnabled
    public static List<OrganizationWrapper> getRecords(String searchString, String countryCode){
      if(searchString.length() < 3){
           return null;
       }
        RequestData request = new RequestData();
        List<OrganizationWrapper> listOrganization = new List<OrganizationWrapper>();
        ResponseData returnData = new ResponseData();
        ResponseDataWrapper returnDataWrapper = new ResponseDataWrapper();

        request.name = searchString;
        request.countryISOAlpha2Code = countryCode;
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        API_Configuration__mdt apiSetting = new API_Configuration__mdt();
        try {
            http = new Http();
            apiSetting = CommonUtil.getAPIconfiguration('API_DUNS_NUMBER');
            req = getHttpRequest(apiSetting, null);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(request));
            system.debug('REQUEST===' + request);
            res = http.send(req);

            if(res.getStatusCode() == 200){
                
                // Parse JSON response to get all the totalPrice field values.
                List<Organization> liOrg = new List<Organization>();
                Map<String,Object> map1 = (Map<String,Object>)JSON.deserializeUntyped(String.valueOf(res.getBody()));
                List<Object> liTopLevel = (List<Object>)map1.get('matchedCandidates');
                //TILL HERE EACH LIST IS MADE UP OF A MAP<STRING, OBJECT>
                for (Object obj: liTopLevel){
                    Map<String, Object> mapEachBlock = (Map<String, Object>)obj;
                    Map<String, Object> mapOrg = (Map<String, Object>) mapEachBlock.get('organization');
                    //Fetch the DUNS and Company name from organization map
                    String duns = (String)mapOrg.get('duns');
                    String companyName = (String)mapOrg.get('primaryName');
                    //Create a map of all main blocks directly inside the matchedcandidates
                    Map<String, Object> mapPrimaryAddress = (Map<String, Object>)mapEachBlock.get('primaryAddress');
                     System.debug('Primary address' + mapPrimaryAddress);
                    //Instantiate the address class with values
                    Address pAddress = new Address();
                    pAddress.name = (String)mapPrimaryAddress.get('name');
                    pAddress.addressLocality = (String)mapPrimaryAddress.get('City');
                    pAddress.addressRegion = (String)mapPrimaryAddress.get('State');
                    pAddress.postalCode = (String)mapPrimaryAddress.get('postalCode');
                    pAddress.countryISOAlpha2Code = (String)mapPrimaryAddress.get('countryISOAlpha2Code');
                    pAddress.streetAddressLine1 = (String)mapPrimaryAddress.get('streetAddressLine1');
                    pAddress.country = (String)mapPrimaryAddress.get('Country');

                    listOrganization.add(new OrganizationWrapper(paddress, duns, companyName));
                }
            }
            ApiUtil.logAPICall(req,res,'API_DUNS_NUMBER','AutoCompleteController.getRecords', apiSetting.HeaderParams__c, 'Outbound');
            return listOrganization;
        }
        catch(Exception ex) {
            system.debug('exception' + ex.getStackTraceString());
            ApiUtil.logAPICall(req,res,'API_DUNS_NUMBER','AutoCompleteController.getRecords', apiSetting.HeaderParams__c, 'Outbound');
            listOrganization.clear();
            return listOrganization;
        }
    }

    @AuraEnabled
    public static List<OrganizationWrapper> getDbBForQuoteProcess(String searchString, String countryCode){
        if(searchString.length() < 3){
            return null;
        }
        RequestData request = new RequestData();
        List<OrganizationWrapper> listOrganization = new List<OrganizationWrapper>();
        ResponseData returnData = new ResponseData();
        ResponseDataWrapper returnDataWrapper = new ResponseDataWrapper();

        request.name = searchString;
        request.countryISOAlpha2Code = countryCode;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        API_Configuration__mdt apiSetting = new API_Configuration__mdt();
        try {
            http = new Http();
            apiSetting = CommonUtil.getAPIconfiguration('API_DUNS_NUMBER');
            req = getHttpRequest(apiSetting, null);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(request));
            system.debug('REQUEST===' + request);
            res = http.send(req);
            //Map<String, Account> mapAccounts = getMapAccountSF();

            if(res.getStatusCode() == 200){
                // Parse JSON response to get all the totalPrice field values.
                List<Organization> liOrg = new List<Organization>();
                Map<String,Object> map1 = (Map<String,Object>)JSON.deserializeUntyped(String.valueOf(res.getBody()));
                List<Object> liTopLevel = (List<Object>)map1.get('matchedCandidates');
                //TILL HERE EACH LIST IS MADE UP OF A MAP<STRING, OBJECT>
                for (Object obj: liTopLevel){
                    Map<String, Object> mapEachBlock = (Map<String, Object>)obj;
                    Map<String, Object> mapOrg = (Map<String, Object>) mapEachBlock.get('organization');
                    //Fetch the DUNS and Company name from organization map
                    String duns = (String)mapOrg.get('duns');
                    String companyName = (String)mapOrg.get('primaryName');
                    //Create a map of all main blocks directly inside the matchedcandidates
                    Map<String, Object> mapPrimaryAddress = (Map<String, Object>)mapEachBlock.get('primaryAddress');
                    //Instantiate the address class with values
                    Address pAddress = new Address();
                    pAddress.name = (String)mapPrimaryAddress.get('name');
                    pAddress.addressLocality = (String)mapPrimaryAddress.get('City');
                    pAddress.addressRegion = (String)mapPrimaryAddress.get('State');
                    pAddress.postalCode = (String)mapPrimaryAddress.get('postalCode');
                    pAddress.countryISOAlpha2Code = (String)mapPrimaryAddress.get('countryISOAlpha2Code');
                    pAddress.streetAddressLine1 = (String)mapPrimaryAddress.get('streetAddressLine1');
                    pAddress.country = (String)mapPrimaryAddress.get('Country');

                   //if(!mapAccounts.containsKey(duns))
                        listOrganization.add(new OrganizationWrapper(paddress, duns, companyName));
                }
            }
            ApiUtil.logAPICall(req,res,'API_DUNS_NUMBER','AutoCompleteController.getRecords', apiSetting.HeaderParams__c, 'Outbound');
            return listOrganization;
        }
        catch(Exception ex) {
            system.debug('exception' + ex.getStackTraceString());
            ApiUtil.logAPICall(req,res,'API_DUNS_NUMBER','AutoCompleteController.getRecords', apiSetting.HeaderParams__c, 'Outbound');
            listOrganization.clear();
            return listOrganization;
        }
    }

    private static Map<String, Account> getMapAccountSF(){
        Map<String, Account> mapAccounts = new Map<String, Account>();
        for(Account acc : [SELECT Id, Name, Duns_Number__c FROM Account ]){
            mapAccounts.put(acc.Duns_Number__c,acc);
        }
        return mapAccounts;
    }


    @AuraEnabled
    public static Account insertDnBAccount(String jsonString){
        try {
            DBDetail dbDetailWrapper = new DBDetail ();
            OrganizationWrapper organWrapper = (OrganizationWrapper)JSON.deserialize(jsonString, OrganizationWrapper.class);
            System.debug('organWrapper'+organWrapper);
            if (organWrapper == null) return null;
            if(String.isNotBlank(organWrapper.duns))  dbDetailWrapper = getCorporateIntel(organWrapper.duns);
            //check account is exist on SF
            List<Account> lstAccount = [SELECT Id, Name
                                               FROM Account
                                               WHERE Duns_Number__c =: organWrapper.duns];
            if (!lstAccount.isEmpty()) return lstAccount[0];
            //Create New Account
            Account acct = generateDnBAccount(organWrapper,dbDetailWrapper);
            insert acct;
            return new Account(ID = acct.Id, Name = acct.name);
        }catch (Exception ex){
            System.debug('== Exception== ' + ex.getMessage() + ex.getLineNumber());
            return null;
        }

    }
    private static Account generateDnBAccount(OrganizationWrapper organWrapper, DBDetail obj){

        Account acct = new Account();
        acct.Name = String.isNotBlank(organWrapper.primaryName) ? organWrapper.primaryName : null;
        acct.Duns_Number__c = String.isNotBlank(organWrapper.duns) ? organWrapper.duns : null;
        acct.BillingStreet = String.isNotBlank(organWrapper.address.streetAddressLine1) ? organWrapper.address.streetAddressLine1 : null;
        acct.BillingCountry = String.isNotBlank(organWrapper.address.country) ? organWrapper.address.country : null;
        acct.BillingCountryCode = String.isNotBlank(organWrapper.address.countryISOAlpha2Code) ? organWrapper.address.countryISOAlpha2Code : null;
        if(acct.BillingCountryCode == 'IM'){
            acct.BillingCountry = 'Isle of Man';
        }
        if(acct.BillingCountryCode == 'GG'){
            acct.BillingCountry = 'Guernsey';
        }
        if(acct.BillingCountryCode == 'JE'){
            acct.BillingCountry = 'Jersey';
        }
        if(acct.BillingCountryCode == 'GB'){
            acct.BillingCountry = 'United Kingdom';
        }if(acct.BillingCountryCode == 'US' && acct.BillingCountry != 'United States'){ // Validating United States BUG 58354
            acct.BillingCountry = 'United States';
        }
        acct.BillingPostalCode = String.isNotBlank(organWrapper.address.postalCode) ? organWrapper.address.postalCode : null;
        if(String.isNotBlank(organWrapper.address.addressLocality)) acct.BillingCity =   organWrapper.address.addressLocality;
        if(String.isNotBlank(organWrapper.address.addressRegion)) acct.BillingStateCode =   organWrapper.address.addressRegion ;
        acct.Current_Assets__c = obj.CurrentAssets;
        acct.Current_Liabilities__c = obj.CurrentLiabilities;
        acct.D_B_Rating_Classification__c = obj.DBRatingClassification;
        acct.Total_Assets__c = obj.TotalAssets;
        acct.Total_Liabilities__c = obj.TotalLiabilities;
        acct.Total_Revenues__c = obj.TotalRevenue;
        acct.Long_Term_Debt__c = obj.LongTermDebt;
        acct.Retained_Earnings__c = obj.RetainedEarnings;
        acct.Net_Income__c = obj.NetIncome;
        acct.Ownership = obj.Ownership;
        acct.Credit_Score__c = obj.CreditScore;
        acct.Number_Of_Directors__c = obj.NoOfDirectors;
        acct.Net_Worth__c = obj.NetWorth;
		acct.Rating_Reason__c = obj.RatingReason;
        if(checkValueExistOnPickList('Composite_Credit_Appraisal__c','Account',obj.CompositeCreditAppraisal)) acct.Composite_Credit_Appraisal__c = obj.CompositeCreditAppraisal;
        if(checkValueExistOnPickList('Number_of_Employees_Scope__c','Account',obj.NumberofEmployeescope)) acct.Number_of_Employees_Scope__c = obj.NumberofEmployeescope;
        if(checkValueExistOnPickList('Number_of_Employees_Reliability__c','Account',obj.ReliabilityofEmployeeNumbers)) acct.Number_of_Employees_Reliability__c = obj.ReliabilityofEmployeeNumbers;
       //if(String.isNotBlank(obj.DateEstablished)) acct.Date_Started__c = Date.valueOf(obj.DateEstablished);
        Id profileId=userinfo.getProfileId();
		String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName == 'Aqueous Underwriter'){
            if(String.isNotBlank(obj.DateEstablished)) acct.Date_Started__c = Date.valueOf(obj.DateEstablished);
        }
        acct.NumberOfEmployees = obj.EmployeeNumbers;
        //
        acct.Sic = obj.SICCode[0].code;
        acct.SicDesc = obj.SICCode[0].typCodeDescription;
        return acct;
    }

    private static Boolean checkValueExistOnPickList(String plAPi,String sObjectName, String valueCheck){
        if(String.isBlank(valueCheck)) return false;
        List<PicklistOption> sfPickList = CommonUtil.getPicklistValueFromObjectField(sObjectName, plAPi);
        for(PicklistOption pl : sfPickList){
            if(pl.value == valueCheck) return true;
        }
        return false;
    }

    @AuraEnabled
    public static DBDetail getCorporateIntel(String dunsNumber){
        system.debug('dunsNumber newest:' + dunsNumber);
        String queryParam = 'dunsNumber='+dunsNumber;
        API_Configuration__mdt apiSetting = new API_Configuration__mdt();
        //API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('API_DUNS_NUMBER1');
        Http https = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        DBDetail detail;
        Id profileId=userinfo.getProfileId();
		String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
		system.debug('ProfileName'+profileName);
        if(profileName == 'Aqueous Underwriter'){
        	 try{
            apiSetting = CommonUtil.getAPIconfiguration('API_CORPORATE_INTEL');
            req = getHttpRequest(apiSetting, queryParam);
            res = https.send(req);
            if(res.getStatusCode() == 200){
                CorporateIntelWrapper.corporateWrapper obj = (CorporateIntelWrapper.corporateWrapper)Json.deserialize(res.getBody(), CorporateIntelWrapper.corporateWrapper.class);
            	System.debug('Values -->'+obj);
            	List<String> ratingReasonDesc = new List <String>();
                String industryCodesTypeDesc = '';
                String industryCodesCode = '';
                Integer noOfDirectorsCount = 0;
            	detail = new DBDetail();
                if(obj.organization.latestFinancials.overview!=null){
                    if(obj.organization.latestFinancials.overview.totalCurrentAssets !=null) detail.CurrentAssets = obj.organization.latestFinancials.overview.totalCurrentAssets;
                    if(obj.organization.latestFinancials.overview.totalAssets!=null) detail.TotalAssets = obj.organization.latestFinancials.overview.totalAssets;   
                    if(obj.organization.latestFinancials.overview.totalCurrentLiabilities !=null) detail.CurrentLiabilities = obj.organization.latestFinancials.overview.totalCurrentLiabilities;	
                    if(obj.organization.latestFinancials.overview.totalLiabilities !=null) detail.TotalLiabilities = obj.organization.latestFinancials.overview.totalLiabilities;                		
                    if(obj.organization.latestFinancials.overview.netIncome!=null) detail.NetIncome = obj.organization.latestFinancials.overview.netIncome;	
                    if(obj.organization.latestFinancials.overview.netWorth!=null) detail.NetWorth = obj.organization.latestFinancials.overview.netWorth;	
                    if(obj.organization.latestFinancials.overview.salesRevenue!=null) detail.TotalRevenue = obj.organization.latestFinancials.overview.salesRevenue;	
                }
                if(obj.organization.incorporatedDate!=null) detail.DateEstablished = obj.organization.incorporatedDate;	
                	
                	//String yearEstablished = obj.organization.incorporatedDate;
                    //detail.DateEstablished = yearEstablished.substring(0,3);
                    if(obj.organization.dnbassessment.standardRating.ratingReason!=null){
                        for(CorporateIntelWrapper.RatingReason ratingReason : obj.organization.dnbassessment.standardRating.ratingReason){
                            ratingReasonDesc.add(ratingReason.description);
                        }
                	    detail.RatingReason = String.join(ratingReasonDesc, ', ');
                    }
                    if(obj.organization.dnbassessment.standardRating.rating!=null) detail.CreditScore = obj.organization.dnbassessment.standardRating.rating;
                	
                	//detail.NoOfDirectors = obj.organization.MostSeniorPrincipals.size(); 
                if(obj.organization.mostSeniorPrincipals!=null){
                    for(CorporateIntelWrapper.MostSeniorPrincipals msp : obj.organization.mostSeniorPrincipals){
                        for(CorporateIntelWrapper.JobTitles jobTitle : msp.jobTitles){
                            if(jobTitle.title == 'Director'){
                                noOfDirectorsCount++;
                            }
                        }
                    }
                    detail.NoOfDirectors = noOfDirectorsCount;
                }	                   	
                SICCode sicCode =new SICCode();
                if(obj.organization.industryCodes!=null){
                for(CorporateIntelWrapper.IndustryCodes indCodes : obj.organization.industryCodes){
                    if(indCodes.typeDnBCode == Label.UK_TypeDnB_Code ){
                        sicCode.typCodeDescription = indCodes.typeDescription;
                        sicCode.code = indCodes.code;
                    }                    
                }
                //detail.SICCode = industryCodesCode;
                detail.SICCode = new List<SICCode>{sicCode};
                System.debug('@@@detail.SICCode::'+detail.SICCode);
                }               
            }
                ApiUtil.logAPICall(req,res,'API_CORPORATE_INTEL','AutoCompleteController.getCorporateIntel', apiSetting.HeaderParams__c, 'Outbound');
                return detail;
            }
            catch(Exception ex) {
                ApiUtil.logAPICall(req,res,'API_CORPORATE_INTEL','AutoCompleteController.getCorporateIntel', apiSetting.HeaderParams__c, 'Outbound');
                return null;
            }
        }else{
        try {
            apiSetting = CommonUtil.getAPIconfiguration('API_DUNS_NUMBER1');
            req = getHttpRequest(apiSetting, queryParam);
            res = https.send(req);
            
            if(res.getStatusCode() == 200){
                Map<String,Object> map1 = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                System.debug('@@@map1.keySet()::'+map1.keySet());
                detail = new DBDetail();
                for(String key : map1.keySet()) {
                    switch on key {
                        when 'CurrentAssets' {
                            if(map1.get(key) != null){
                                detail.CurrentAssets = (Decimal)map1.get(key);
                            }
                        }
                        When 'CurrentLiabilities' {
                            if(map1.get(key) != null) {
                                detail.CurrentLiabilities = (Decimal)map1.get(key);
                            }
                        }
                        when 'DnBRatingClassification' {
                            if(map1.get(key) != null) {
                                detail.DBRatingClassification = (String)map1.get(key);
                            }
                        }
                        when 'DunsNumber' {
                            if(map1.get(key) != null) {
                                detail.DunsNumber = (String)map1.get(key);
                            }
                        }
                        when 'NAICCode' {
                            if(map1.get(key) != null) {
                                List<Object> listObject = (List<Object>)map1.get(key);
                                List<NAICCode> listNAICCode = getNAICCode(listObject);
                                detail.NAICCode = listNAICCode;
                            }
                        }
                        when 'NetWorth' {
                            if(map1.get(key) != null) {
                                detail.NetWorth = (Long)map1.get(key);
                            }
                        }
                        when 'SICCode' {
                            if(map1.get(key) != null) {
                                List<Object> listObject = (List<Object>)map1.get(key);
                                List<SICCode> listSICCode = getSICCode(listObject);
                                detail.SICCode = listSICCode;
                            }
                        }
                        when 'TotalAssets' {
                            if(map1.get(key) != null){
                                detail.TotalAssets = (Decimal)map1.get(key);
                            }
                        }
                        when 'TotalLiabilities' {
                            if(map1.get(key) != null) {
                                detail.TotalLiabilities = (Decimal)map1.get(key);
                            }
                        }
                        when 'TotalRevenue' {
                            if(map1.get(key) != null){
                                detail.TotalRevenue = (Decimal)map1.get(key);
                            }
                        }
                        when 'Website' {
                            if(map1.get(key) != null){

                            }
                        }
                        when 'CompositeCreditAppraisal' {
                            if(map1.get(key) != null){
                                detail.CompositeCreditAppraisal = (String)map1.get(key);
                            }
                        }//CompositeCreditAppraisal
                        //extra fields become available on 1.11.2019
                        when 'TypeofPartnership' { //currently null
                            if(map1.get(key) != null){
                                detail.TypeofPartnership = (String)map1.get(key);
                            }
                        }
                        when 'LongTermDebt' { //currently null
                            if(map1.get(key) != null){
                                detail.LongTermDebt = (Long)map1.get(key);
                            }
                        }
                        when 'RetainedEarnings' { //currently populated
                            if(map1.get(key) != null){
                                detail.RetainedEarnings = (Long)map1.get(key);
                            }
                        }
                        when 'ShareholdersEquity' { //currently null
                            if(map1.get(key) != null){
                                detail.ShareholderEquity = (String)map1.get(key);
                            }
                        }
                        when 'NetIncome' { //currently populated
                            if(map1.get(key) != null){
                                detail.NetIncome = (Decimal)map1.get(key);
                            }
                        }
                        when 'Dateestablished' { //currently populated
                            if(map1.get(key) != null){
                                detail.DateEstablished = (String)map1.get(key);
                            }
                        }
                        when 'CurrencyIsoCode' {
                            if(map1.get(key) != null){
                                detail.CurrencyIsoCode= (String)map1.get(key);
                            }
                        }
                        when 'OwnershipControlTypeText' { //currently null
                            Map<String, Object> mapOwnerData = (Map<String, Object>)map1.get('OwnershipControlTypeText');
                            if(mapOwnerData != null){
                                detail.Ownership = (String) mapOwnerData.get('description');                   
                            }
                        }
                        when 'EmployeeData' { //currently populated & its a picklist
                            List<Object> listObject = (List<Object>) map1.get(key);
                            if (listObject != null && listObject.size() > 0) {

                                Map<String, Object> mapEmployeeData = (Map<String, Object>) listObject[0];
                                detail.EmployeeNumbers = (Integer) mapEmployeeData.get('EmployeeNumbers');
                                detail.ReliabilityofEmployeeNumbers = (String) mapEmployeeData.get('ReliabilityofEmployeeNumbers');
                                detail.NumberofEmployeescope = (String) mapEmployeeData.get('Numberofemployeesscope');
                            }
                        }
                    }
                }
                //Set current date & time on field Last_D_B_Refresh__c.
                detail.LastUpdate =  Datetime.Now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                System.debug(detail.LastUpdate);
            }
            //API Logs
            ApiUtil.logAPICall(req,res,'API_DUNS_NUMBER1','AutoCompleteController.getCorporateIntel', apiSetting.HeaderParams__c, 'Outbound');
            return detail;
        }
        catch(Exception ex) {
            ApiUtil.logAPICall(req,res,'API_DUNS_NUMBER1','AutoCompleteController.getCorporateIntel', apiSetting.HeaderParams__c, 'Outbound');
            return null;
        }
        }
    }

    /*************************************************
    * Method Name: getInitData
    * Author: Tuan  
    * Date: Feb 02 2020
    * Params: String recordId
    * Return: ResultResponse
    * Description: Update Account info with latest data from D&B
    * Revision: 
    **********************************************/
    @AuraEnabled
    public static ResultResponse updateDBInfo(String recordId) {
        ResultResponse result = new ResultResponse();
        
        try {
            List<Account> objs = [SELECT Id, Duns_Number__c FROM Account WHERE Id =: recordId];
            if (objs.isEmpty()) {
                String msg = 'Account is not existed';
                result.errors.add(msg);
                return result;
            }
            String dunsNumber = objs[0].Duns_Number__c;

            DBDetail data = getCorporateIntel(dunsNumber);
            // invalid duns number
            if (data == null) {
                String msg = 'Cannot find D&B Info for Duns Number: ' + dunsNumber;
                result.errors.add(msg);
                return result;
            }

            Account acc = generateAccount(data);
            acc.Id = objs[0].Id;
            acc.Last_D_B_Refresh__c = System.Now();

            update acc;

            String msg = 'Update D&B info successfully';
            result.errors.add(msg);
            result.isSuccess = true;

        } catch (Exception ex) {
            String msg = 'Failed to update D&B info for this account.';
            result.errors.add(msg);
            return result;
        }
        return result;
    }
    
    private static Account generateAccount(DBDetail obj) {
        Account result = new Account();
        if (obj == null) {
            return result;
        }

        result.Current_Assets__c = obj.CurrentAssets;
        result.Current_Liabilities__c = obj.CurrentLiabilities;
        result.D_B_Rating_Classification__c = obj.DBRatingClassification;
        result.Total_Assets__c = obj.TotalAssets;
        result.Total_Liabilities__c = obj.TotalLiabilities;
        result.Total_Revenues__c = obj.TotalRevenue;
        result.Long_Term_Debt__c = obj.LongTermDebt;
        result.Retained_Earnings__c = obj.RetainedEarnings;
        result.Net_Income__c = obj.NetIncome;
        result.Ownership = obj.Ownership;
        result.NumberOfEmployees = obj.EmployeeNumbers;

        return result;
    }

    private static List<NAICCode> getNAICCode(List<Object> listObject) {
        List<NAICCode> listNAICCode = new List<NAICCode>();
        for(Object objNaicCode : listObject) {
            NAICCode nAICCode = new NAICCode();
            Map<String,Object> mapNaicCode = (Map<String,Object>)objNaicCode;

            for(String keyNaicCode : mapNaicCode.keySet()) {
                switch on keyNaicCode {
                    when 'code' {
                        nAICCode.code = (String)mapNaicCode.get(keyNaicCode);
                    }
                    when 'typCodeDescription' {
                        nAICCode.typCodeDescription = (String)mapNaicCode.get(keyNaicCode);
                    }
                }
            }
            listNAICCode.add(nAICCode);
        }
        return listNAICCode;
    }

    private static List<SICCode> getSICCode(List<Object> listObject) {
        List<SICCode> listSICCode = new List<SICCode>();
        for(Object objNaicCode : listObject) {
            SICCode sICCode = new SICCode();
            Map<String,Object> mapSICCode = (Map<String,Object>)objNaicCode;

            for(String keySICCode : mapSICCode.keySet()) {
                switch on keySICCode {
                    when 'code' {
                        sICCode.code = (String)mapSICCode.get(keySICCode);
                    }
                    when 'typCodeDescription' {
                        sICCode.typCodeDescription = (String)mapSICCode.get(keySICCode);
                    }
                }
            }
            listSICCode.add(sICCode);
        }
        return listSICCode;
    }

    public class DBDetail {
        @AuraEnabled
        public Decimal CurrentAssets {get;set;}
        @AuraEnabled
        public Decimal CurrentLiabilities {get;set;}
        @AuraEnabled
        public String DBRatingClassification {get;set;}
        @AuraEnabled
        public String DunsNumber {get;set;}
        @AuraEnabled
        public List<NAICCode> NAICCode {get;set;}
        @AuraEnabled
        public Long NetWorth {get;set;}
        @AuraEnabled
        public List<SICCode> SICCode {get;set;}
        @AuraEnabled
        public Decimal TotalAssets {get;set;}
        @AuraEnabled
        public Decimal TotalLiabilities {get;set;}
        @AuraEnabled
        public List<TotalRevenues> TotalRevenues {get;set;}
        @AuraEnabled
        public Decimal TotalRevenue {get;set;}
        @AuraEnabled
        public List<Website> Website {get;set;}
        //Extra fields fixed on 1.11.19
        @AuraEnabled
        public String TypeofPartnership {get;set;}
        @AuraEnabled
        public String CompositeCreditAppraisal {get;set;}
        @AuraEnabled
        public Long LongTermDebt {get;set;}
        @AuraEnabled
        public Long RetainedEarnings {get;set;}
        @AuraEnabled
        public String ShareholderEquity {get;set;}
        @AuraEnabled
        public Decimal NetIncome {get;set;}
        @AuraEnabled
        public String DateEstablished {get;set;}
        @AuraEnabled
        public String Ownership {get;set;}
        @AuraEnabled
        public String CurrencyIsoCode{get;set;}      
        @AuraEnabled
        public Integer EmployeeNumbers {get;set;}
        @AuraEnabled
        public String ReliabilityofEmployeeNumbers {get;set;}
        @AuraEnabled
        public String NumberofEmployeescope {get;set;}
        @AuraEnabled
        public String LastUpdate {get;set;}
        @AuraEnabled
        public Integer NoOfDirectors {get;set;}
        @AuraEnabled
        public String RatingReason {get;set;}
        @AuraEnabled
        public String CreditScore {get;set;}
    }

    public class NAICCode {
        @AuraEnabled
        public String code;
        @AuraEnabled
        public String typCodeDescription;

        public NAICCode() {

        }
        public NAICCode(String code,String typCodeDescription) {
            this.code = code;
            this.typCodeDescription = typCodeDescription;
        }

    }

    public class SICCode {
        @AuraEnabled
        public String code;
        @AuraEnabled
        public String typCodeDescription;
    }

    public class TotalRevenues {
        @AuraEnabled
        public Integer value;
        @AuraEnabled
        public String currency1;
        @AuraEnabled
        public List<trend> trend;
    }

    public class trend {

    }

    public class Website {

    }


    public class RequestData {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String streetAddressLine1;
        @AuraEnabled
        public String countryISOAlpha2Code;
        @AuraEnabled
        public String addressLocality;
        @AuraEnabled
        public String addressRegion;
        @AuraEnabled
        public String postalCode;
        @AuraEnabled
        public String country;

        public RequestData() {

        }
    }

    public class RequestData1 {

        @AuraEnabled
        public Address Address {get; set;}

        @AuraEnabled
        public String dunsNumber {get; set;}

        public RequestData1() {

        }

        public RequestData1(String dunsNumber) {
            this.dunsNumber = dunsNumber;
        }
    }

    public class ResponseData {
        @AuraEnabled
        public Address address;

        @AuraEnabled
        public List<MatchedCandidate> matchedCandidates;

        public ResponseData() {

        }
    }

    public class ResponseDataWrapper {

        @AuraEnabled
        public Address address;
        @AuraEnabled
        public List<Organization> listOrganization;


        public ResponseDataWrapper() {

        }
    }

    public class MatchedCandidate {
        @AuraEnabled
        public Organization organization;
    }

    ///
    public class primaryAddress {

    }

    public class Address {
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String streetAddressLine1 {get; set;}
        @AuraEnabled
        public String countryISOAlpha2Code {get; set;}
        @AuraEnabled
        public String addressLocality {get; set;}
        @AuraEnabled
        public String addressRegion {get; set;}
        @AuraEnabled
        public String postalCode {get; set;}
        @AuraEnabled
        public String country {get; set;}
    }

    public class Organization {
        @AuraEnabled
        public String duns;
        @AuraEnabled
        public String primaryName;

        public Organization() {

        }

        public Organization(String duns, String primaryName) {
            this.duns = duns;
            this.primaryName = primaryName;
        }
    }

    public class OrganizationWrapper {

        @AuraEnabled
        public Address address;
        @AuraEnabled
        public String duns;
        @AuraEnabled
        public String primaryName;
        @AuraEnabled
        public String primaryAddressLin1;

        public OrganizationWrapper() {
        }

        public OrganizationWrapper(String duns, String primaryName) {
            this.duns = duns;
            this.primaryName = primaryName;
        }

        public OrganizationWrapper(Address address, String duns, String primaryName) {
            this.address = address;
            this.duns = duns;
            this.primaryName = primaryName;
        }
    }

    private static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, String queryParam) {
        
        HttpRequest req = new HttpRequest();

        if(apiSetting != null){
            queryParam = queryParam == null ? '' : '?'+queryParam;
            String serviceUrl = apiSetting.Base_Url__c + apiSetting.Endpoint__c + queryParam;
            Map<String, String> headerParamMap = new Map<String, String>();
            for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
                List<String> headerKeyValue = headerParam.split(':');
                headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
            }
            req.setEndpoint(serviceUrl);
            req.setMethod(apiSetting.Method__c);
            req.setTimeout(Integer.valueOf(Label.ApiTimeOut));
            for (String headerParamKey : headerParamMap.keySet()) {
                req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
            }
        }
        return req;
    }
    @AuraEnabled (cacheable=true)
    public static String checkAqueousProduct(Id sObjectId) {
        String sObjName = sObjectId.getSObjectType().getDescribe().getName();
        if(sObjName == 'Opportunity'){
            Id recordTypeId = [SELECT Id,RecordTypeId FROM Opportunity where Id =:sObjectId Limit 1].RecordTypeId;
            String recordTypeName = [select Id,Name from RecordType where SobjectType='Opportunity' And Id =: recordTypeId].Name;
            System.debug('recordTypeName -->'+recordTypeName);
            return recordTypeName;
        }
        else{
            String recordTypeName = [SELECT Id,Record_Type__c FROM Quote_Process__c WHERE Id  = :sObjectId Limit 1].Record_Type__c;
            System.debug('recordTypeName -->'+recordTypeName);
            return recordTypeName;
        }
    }
}