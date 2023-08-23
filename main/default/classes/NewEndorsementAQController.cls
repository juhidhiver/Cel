public class NewEndorsementAQController {
    
    @AuraEnabled
    public static List<PicklistOption> initData(String contractId, String productName, String status, Date effectiveDate, Date cancelDate){
        List<PicklistOption> lstResult = CommonUtil.getPicklistEndorsementOperations(productName);
        if(status == 'Cancelled'  && cancelDate != null) 
        lstResult = new List<PicklistOption>{new PicklistOption('Reinstatement','Reinstatement')};
                
        lstResult[0].isSelected = true;
        return lstResult;
    }
    
    @AuraEnabled
    public static List<PicklistOption> getQuotesEndorsementCancelPicklist(){
        return CommonUtil.getPicklistValueFromObjectField('Policy__c', 'Cancellation_Reason__c');
    }    
    @AuraEnabled
    public static List<PicklistOption> getKYCStatusPicklist(){
        List <PicklistOption> kycList = CommonUtil.getPicklistValueFromObjectField('Account', 'KYC_Status__c');
        kycList.add(new PicklistOption('None','None'));
        System.debug('kycList:'+kycList);
        return kycList;
    }
    @AuraEnabled
    public static List<PicklistOption> getSanctionStatusPicklist(){
        List <PicklistOption> sanctionList = CommonUtil.getPicklistValueFromObjectField('Account', 'AQ_Sanction_Status__c');
        sanctionList.add(new PicklistOption('None','None'));
        return sanctionList;
    }

    @AuraEnabled
    public static string checkOpenQuotes(String contractId){
        string isError = '';
		System.debug('@@@ contractId '+contractId);
        List<Transactions__c> lstActiveTransaction = new List<Transactions__c>();
        List<Transactions__c> lstAllRelatedTransactions = [SELECT Name, Id, Policy__c, Submission__c,Submission__r.StageName, Submission__r.Transaction_Status__c
                                          FROM Transactions__c
                                          WHERE Policy__c =:contractId];
        Set<Id> setOfRelatedOpps = new Set<Id>();
        for(Transactions__c objTransaction: lstAllRelatedTransactions){
            setOfRelatedOpps.add(objTransaction.Submission__c);
            if(objTransaction.Submission__r.Transaction_Status__c == 'Active'){
                lstActiveTransaction.add(objTransaction);
            }
        }
        if(!lstActiveTransaction.isEmpty()){
            List<Quote> quoteList = [select Id, status from Quote where OpportunityId IN: setOfRelatedOpps
                                     AND Status NOT IN ('Bound','Closed','Rejected','Correction','Cancelled')];
            if(lstActiveTransaction[0].Submission__r.StageName == 'Declined'){
                isError = 'Declined';
            }else if(quoteList.size() > 0){
                    isError = 'Open Quotes';
            }
            List<Quote> boundQuote = [select Id, status from Quote where OpportunityId =: lstActiveTransaction[0].Submission__c
                                      AND Status IN ('Bound')];
            if(boundQuote.isEmpty()) isError = 'noBoundQuotes';
            
        }else{
            isError = 'inactive';
        }
        return isError;
    }
    
   /*  @AuraEnabled
    public static boolean isPolicyExpired(String contractId){
        Boolean isExpired = false;
        Date polExpiryDate = [Select Id,Expiration_Date__c from Policy__c where Id=:contractId].Expiration_Date__c;
        System.debug('polExpiryDate:'+polExpiryDate);
        isExpired = (polExpiryDate < System.today()) ? true : false;
        return isExpired;
    }*/
    
    @AuraEnabled
    public static Boolean checkActiveSubmission(String contractId){
        Boolean isNotActive = false;
        
        List<Transactions__c> tranList = [SELECT Name, Id, Policy__c, Submission__c,Submission__r.StageName
                                          FROM Transactions__c
                                          WHERE Policy__c =:contractId
                                          AND Submission__r.Transaction_Status__c = 'Active' LIMIT 1];    
        if(tranList.isEmpty()){
			isNotActive = true;
        }
        return isNotActive;
    }
    
    @AuraEnabled
    public static List<PicklistOption> getEndorsementReasons(string endorsementType){
        List<PicklistOption> lstResult = CommonUtil.getPicklistEndorsementOperationsAQ(endorsementType);
        return lstResult;
    }
    
    @AuraEnabled
    public static Boolean checkEndorsementDate(string contractId,string effectiveDate){
        Date effectDate = CommonUtil.parseDateFromString(effectiveDate);
        Boolean isNotInLimit = false;
        List<Quote> quoteList = [select Id, status,Effective_Date__c,Policy__c,ExpirationDate from Quote where Policy__c =: contractId
                                 AND Status IN ('Bound') ORDER By CreatedDate DESC limit 1];
        if(!quoteList.isEmpty()){
            if(effectDate > quoteList[0].ExpirationDate || effectDate < quoteList[0].Effective_Date__c)
                isNotInLimit = true;
        } 
        return isNotInLimit;
    }
    @AuraEnabled
    public static Boolean checkCancellationDate(string contractId,string effectiveDate){
        Date effectDate = CommonUtil.parseDateFromString(effectiveDate);
        Boolean isNotInLimit = false;
        List<Policy__c> policyList = [select Id, Effective_Date__c,Expiration_Date__c from Policy__c where Id =: contractId];
        if(!policyList.isEmpty()){
            if(effectDate > policyList[0].Expiration_Date__c || effectDate < policyList[0].Effective_Date__c)
                isNotInLimit = true;
        } 
        return isNotInLimit;
    }
	
    @AuraEnabled
    public static String getActiveSubmission(String policyId){
        List<Transactions__c> submissionPoilcyTransaction = [SELECT Name, Id, Policy__c, Submission__c 
                                  FROM Transactions__c 
                                  WHERE Policy__c =:policyId 
                                  AND Submission__r.Transaction_Status__c = 'Active' LIMIT 1]; 
        String oppId   = '';                       
        if(!submissionPoilcyTransaction.isEmpty()){                            
            oppId = submissionPoilcyTransaction[0].Submission__c;  
        }
        return oppId;
    }

    private static Set<String> picklistValueApis(List<PicklistOption> picklistValues){
        Set<String> picklistApis = new Set<String>();
        for(PicklistOption po : picklistValues){
            picklistApis.add(po.value);
        }
        return picklistApis;
    }
    
    @AuraEnabled
    public static AddressWrapper getAccountDetails(String policyId){
        AddressWrapper accountDetails = new AddressWrapper();
        List<Transactions__c> submissionPoilcyTransaction = [SELECT Name, Id, Policy__c, Submission__c 
                                  FROM Transactions__c 
                                  WHERE Policy__c =:policyId 
                                  AND Submission__r.Transaction_Status__c = 'Active' LIMIT 1]; 
        String oppId   = '';                       
        if(!submissionPoilcyTransaction.isEmpty()){                            
            oppId = submissionPoilcyTransaction[0].Submission__c;  
        }
        Opportunity opp = [select Id,Account.Id,Account.Name,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,Account.BillingCountry,
                            Account.BillingStateCode,Account.BillingCountryCode,Account.AQ_Sanction_Status__c,Account.KYC_Status__c,
                            Account.KYC_Date__c, Account.Sanction_Date__c from Opportunity where Id=:oppId];                                              
        if(opp!=null){
             accountDetails.accName = string.isNotBlank(opp.Account.Name) ? opp.Account.Name: '';
            accountDetails.accId = string.isNotBlank(opp.Account.Id) ? opp.Account.Id: '';
            accountDetails.billingStreet = string.isNotBlank(opp.Account.BillingStreet) ? opp.Account.BillingStreet: '';
            accountDetails.billingCity = string.isNotBlank(opp.Account.BillingCity) ? opp.Account.BillingCity: '';
            accountDetails.postalCode = string.isNotBlank(opp.Account.BillingPostalCode) ? opp.Account.BillingPostalCode: '';
            accountDetails.billingCountry = string.isNotBlank(opp.Account.BillingCountry) ? opp.Account.BillingCountry : '';
            accountDetails.countryCode = string.isNotBlank(opp.Account.BillingCountryCode) ? opp.Account.BillingCountryCode: '';
            accountDetails.stateCode = string.isNotBlank(opp.Account.BillingStateCode) ? opp.Account.BillingStateCode : '';
            accountDetails.kycStatus = string.isNotBlank(opp.Account.KYC_Status__c) ? opp.Account.KYC_Status__c: '';
            accountDetails.sanctionStatus = string.isNotBlank(opp.Account.AQ_Sanction_Status__c) ? opp.Account.AQ_Sanction_Status__c : '';
            /*if(opp.Account.KYC_Date__c!=null){
                accountDetails.kycDate = opp.Account.KYC_Date__c;
            }*/
            if(opp.Account.Sanction_Date__c!=null){
                accountDetails.sanctionDate = opp.Account.Sanction_Date__c;
            }
            
        }
        system.debug('accountDetails-->'+accountDetails);
        return accountDetails;
    }

    @AuraEnabled
    public static String ratingQuoteEndorsement(String quoteId) {
        ResultResponse result = RateController.getRatingFromCallOut(quoteId);
        return result.errors.isEmpty() ? '' : result.errors[0];
    }
    
    /******** Populate Quote fields from Quote Option *********/
    @AuraEnabled
    public static void populateQuoteOption(String quoteId) {
        
         Map<String,Quote_Option__c> mapQO = new Map<String,Quote_Option__c>();
        
        for(Quote_Option__c objQO : [Select Id, Bound__c, Quote__c, Actual_Premium__c, Broker_Netted_Down_Premium__c
                                     , Fee__c, Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c
                                     , Override_Fee_Percent__c, IPT_on_Broker_Netted_Down_Premium__c
                                     , Total_Cost_to_Client__c, Technical_Fee__c, Technical_Premium__c
                                     , NonProrated_Actual_Premium__c, NonProRated_BNDP__c
                                     from Quote_Option__c where Quote__c =: quoteId and Bound__c = true]){
              mapQO.put(objQO.Quote__c,objQO);   
                                         
         }
        
        if(mapQO.containskey(quoteId)){
            Quote objQuote = new Quote();
            objQuote.Id = quoteId;
            Quote_Option__c boundQuoteOption = mapQO.get(quoteId);
            objQuote.Actual_Premium__c = boundQuoteOption.Actual_Premium__c;
            objQuote.Broker_Netted_Down_Premium__c = boundQuoteOption.Broker_Netted_Down_Premium__c;
            objQuote.Fee__c = boundQuoteOption.Fee__c;
            objQuote.IPT_on_Broker_Netted_Down_Premium__c = boundQuoteOption.IPT_on_Broker_Netted_Down_Premium__c;
            objQuote.Total_Cost_to_Client__c = boundQuoteOption.Total_Cost_to_Client__c;
            objQuote.Technical_Fee__c = boundQuoteOption.Technical_Fee__c;
            objQuote.Technical_Premium__c = boundQuoteOption.Technical_Premium__c;
            objQuote.NonProrated_Actual_Premium__c = boundQuoteOption.NonProrated_Actual_Premium__c;
            objQuote.NonProRated_BNDP__c = boundQuoteOption.NonProRated_BNDP__c;
            
            update objQuote;
        }
        
    }
    
    @AuraEnabled
    public static String bindQuoteEndorsement(String quoteId, String strCancelDate, String contractCancellationReason) {
        String result;
        Date contractCancelDate = null;
        if(String.isNotBlank(strCancelDate)) contractCancelDate = Date.valueOf(strCancelDate);
        result = BindQuoteController.bindQuoteForEndorsement(quoteId, contractCancelDate, contractCancellationReason);
        system.debug('result='+result);
        return result;
    }
    public static ResultWrapper cloneAccountWithRelated(String resp){
                        //clone account and all related records
                        
                        ResultWrapper cloneResult = new ResultWrapper(); 
                        String endorsementType = 'Insured Account Update';
                        String clonedoppId = '';
                        System.debug('resp2::'+resp);
                        //string resp = JSON.serialize(accountData);
                        if(string.isNotBlank(resp)){
                            AddressWrapper accountDetails = (AddressWrapper) JSON.deserialize(resp, AddressWrapper.class);
                            System.debug('accountDetails::'+accountDetails);
                            String policyId = accountDetails.policyId;
                            String effDate = accountDetails.effDate;
                    		String endorsementReason = accountDetails.endorsementReason;
                            Set<String> countryPicklistSet = picklistValueApis(CommonUtil.getPicklistValueFromObjectField('Account', 'BillingCountryCode'));
                            Set<String> statePicklistSet = picklistValueApis(CommonUtil.getPicklistValueFromObjectField('Account', 'BillingStateCode'));
                            try{
                                Account newAcc = new Account();
                                newAcc.Name = accountDetails.accName;
                                Id recordTypeBusiness = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
                                newAcc.RecordTypeId = recordTypeBusiness;
                                newAcc.BillingStreet = accountDetails.billingStreet;
                                newAcc.BillingCity = accountDetails.billingCity ;
                                newAcc.BillingPostalCode = accountDetails.postalCode;
                                if(countryPicklistSet.contains(accountDetails.countryCode)){
                                    newAcc.BillingCountryCode =  accountDetails.countryCode;
                                    newAcc.BillingStateCode =  statePicklistSet.contains(accountDetails.stateCode) ? accountDetails.stateCode : '';
                                }
                                newAcc.AQ_Sanction_Status__c = accountDetails.sanctionStatus;
                                newAcc.KYC_Status__c = accountDetails.kycStatus;
                                newAcc.Action_Point__c = 'Endorsement';
                                insert newAcc;
                                System.debug('newAcc::'+newAcc.Id);
                                String endoresementReasonOther = '';
                                //get original Active Submission from Policy
                                String originalOppId = getActiveSubmission(policyId);
                                if(originalOppId!=null){
                                    String accId = newAcc.Id;
                                    insuredAccountUpdates(policyId, accId, endorsementType, effDate);
                                    cloneResult.resultAccId = newAcc.Id;
                                }
                                else{
                                    cloneResult.error = 'No Active Submission/Transaction record found on this Policy';
                                }    
                            }
                            catch (Exception ex) {
                                cloneResult.error = CommonUtil.getExceptionMessage(ex);
                                cloneResult.resultAccId = '';
                            }
                        }
                        return cloneResult; 
    }
    
    //No cloning of Opportunity/Quote, update the original records
    public static void insuredAccountUpdates(String policyId, String accId, String endorsementType, String effDate){
        String originalOppId = getActiveSubmission(policyId);
        if(originalOppId!=null){
        //update oppty with account  
        Opportunity oppRec = [Select Id, AccountId, StageName, Type FROM Opportunity WHERE Id=:originalOppId];
        oppRec.AccountId = accId;
        //oppRec.Type = endorsementType;
        update oppRec;
        //update quote process with account
        Quote_Process__c qp = [Select Id,Submission__c, Account__c from Quote_Process__c where Submission__c=:originalOppId];
        qp.Account__c = accId;
        update qp;
        
        /*Set<Id> policyIds = new Set<Id>();
        for(Transactions__c policyIdsOnSubmission:  [SELECT Name, Id, Policy__c, Submission__c FROM Transactions__c 
                                                     WHERE Submission__c =:originalOppId]){
          if(policyIdsOnSubmission.Policy__c != null){
                policyIds.add(policyIdsOnSubmission.Policy__c);
          	}
         }
         //Get all the quotes from the policies
        Map<String,List<Quote>> policyIdToQuoteListMap = new Map<String,List<Quote>>();
        List<Quote> quoteListFromPolicy = cloneRecords.queryQuote(policyIds);
        //Create a Map of Policy ID & related quotes
            for(Quote quote : quoteListFromPolicy){
                String polId = quote.Policy__c;
                if(policyIdToQuoteListMap.containsKey(polId)){
                    policyIdToQuoteListMap.get(polId).add(quote);
                }else{
                    policyIdToQuoteListMap.put(polID,new List<Quote>{quote});
                }
            }
       //From the policyIdToQuoteListMap, take the latest bound quote from each of the policy ID
        List<Quote> quoteListToUpdate = new List<Quote>();
            for(String polIdKey : policyIdToQuoteListMap.keySet()){
                List<Quote> quoteList = policyIdToQuoteListMap.get(polIdKey);
                if(quoteList.size() > 1){
                    quoteListToUpdate.add(quoteList[0]);
                }else{
                    quoteListToUpdate.addAll(quoteList);
                }
            }
        //update quotelist with account/other details
            for(Quote quo : quoteListToUpdate){
                quo.Quote_Type__c = endorsementType;
                quo.Endorsement_Reason__c = endorsementType;
                quo.Endorsement_Effective_Date__c = effDate != null ? Date.valueOf(effDate) : null;
                //quo.AccountId = accId;
            }
            if(!quoteListToUpdate.isEmpty()){
                GlobalStaticVar.byPassQuoteTrigger = true;
                GlobalStaticVar.byPassFreeFormEndorsementTrigger = true;
                GlobalStaticVar.byPassSubjectivityTrigger = true;
                update quoteListToUpdate;
        	}*/
            //update policy with new account
         	updatePolicyAccount(accId,policyId);
            //create change log for Insured account transaction
            insertChangeLog(policyId,endorsementType);
    	}
    }
    
    public static void updatePolicyAccount(String accId, String policyId){
        String oppId = getActiveSubmission(policyId);
        Set<Id> policyIds = new Set<Id>();
        for( Transactions__c transRec : [Select Id, Policy__r.Name, Policy__r.Id, Policy__r.Policy_Status__c from Transactions__c 
                                   		 WHERE Submission__c = :oppId AND Policy__r.Policy_Status__c = 'Bound']){
            policyIds.add(transRec.Policy__r.Id);
        }
        System.debug('policyIds::'+policyIds);
        List <Policy__c> policyListUpdate = [SELECT Id, Account__c FROM Policy__c where Id IN: policyIds ];
        for(Policy__c pol : policyListUpdate){
            pol.Account__c = accId;
        }
        if(!policyListUpdate.isEmpty()){
            update policyListUpdate;
        }
    }
    
    public static void insertChangeLog(String policyId, String endorsementType){
        Change_Log__c clRec = new Change_Log__c();
        clRec.Policy__c = policyId;
        clRec.Change_Date__c = System.today();
        clRec.Change_Type__c = endorsementType;
        if(clRec!=null){
            insert clRec;
        }
    }
    
    @AuraEnabled
    public static ResultWrapper showQuotes(String policyId, String effDate, String endorsementType){
        ResultWrapper result = new ResultWrapper();
        
        set<string> quoteTypes = new set<string>{'New Business','Full Amendment','Renewal'};

        if(endorsementType == 'Coverage Cancel & Replace'){
            quoteTypes.add('Coverage Amendment');
            quoteTypes.add('Policy Duration Change');
        }
        
        List<Quote> quoteList = [select Id,Name,Quote_Type__c,CreatedDate,Status,Effective_Date__c,ExpirationDate from Quote where Policy__c =:policyId 
                                 AND Status =: 'Bound' AND Quote_Type__c IN :quoteTypes
                                 ORDER BY Createddate];
        if(quoteList.isEmpty()){
            result.error = 'Cancel & Replace cannot be performed on this Policy';
            return result;
        }

        result.quoteList = quoteList;
        return result;
    }
    
    @AuraEnabled
    public static ResultWrapper coverageCancelProcess(string selectedId,Date createdDate,string effectiveDate,string policyId){
        ResultWrapper result = new ResultWrapper();
        List<Quote> quoteList = [select Id,Status,CreatedDate from Quote where Policy__c =: policyId AND CreatedDate >= :createdDate AND Status != 'Correction'];
        
        if(selectedId == null){
            result.error = 'Please select a Quote for Cancel and Replace';
            return result;
        }
        Set<Id> quoteIds = new Set<Id>();
      //  Set<Id> selectId = new Set<Id>{selectedId};
            
            if(!quoteList.isEmpty()){
                for(Quote quote: quoteList){ 
                    quote.status = 'Cancelled';
                    quoteIds.add(quote.Id);
                }
            }
        
        try{
            ResultWrapper returnValues = cloneRecords.coverageCancelProcess(quoteIds,selectedId,policyId);
            system.debug('returnValues-->'+returnValues);
            if(string.isNotBlank(returnValues.oppId)){
                Update quoteList;
                result.oppId = returnValues.oppId;
                result.cloneQuoteId = returnValues.cloneQuoteId;
            }else{
                 result.error = returnValues.error;
            }
            
        }catch(DMLException ex){
            result.error = ex.getDmlMessage(0);
            system.debug('exception 123'+ex.getLineNumber()+ex.getMessage());
            return result;
        }catch(exception ex){
            system.debug('exception 23'+ex.getLineNumber()+ex.getMessage());
            result.error = ex.getMessage();
        }

       return result;
    }
    
    @AuraEnabled
    public static ResultWrapper FullAmendmentCancelProcess(string selectedId,Date createdDate,string effectiveDate,string policyId){
        ResultWrapper result = fullCancellation.fullCancellation(selectedId, createdDate, effectiveDate, policyId);
        return result;
    }
    
    
    public static ResultWrapper checkDuplicateAccount(string resp){
        ResultWrapper result = new ResultWrapper();
        String dunsNumber;
        AddressWrapper accountDetails = (AddressWrapper) JSON.deserialize(resp, AddressWrapper.class);  
        List<Account> accList = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingCountry, 
                                 BillingStateCode, BillingCountryCode, BillingAddress, Duns_Number__c FROM Account Where Id =:accountDetails.accId AND
                                 Name=:accountDetails.accName];
        if(!accList.isEmpty()) {
            dunsNumber = string.isNotBlank(accList[0].Duns_Number__c) ? accList[0].Duns_Number__c : '';
        }
            List<Account> getOppCount = [select id,(select id,StageName from Opportunities where StageName = 'Closed Won') from Account where Id =:accountDetails.accId]; 
            if(!getOppCount.isEmpty() && getOppCount[0].Opportunities.size() >0){
                if(getOppCount[0].Opportunities.size() == 1){
                    //update
                    Account accRec = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingCountry, 
                                      BillingStateCode, BillingCountryCode, BillingAddress, AQ_Sanction_Status__c, KYC_Status__c,
                                      Duns_Number__c, Action_Point__c FROM Account Where Id =:accountDetails.accId Limit 1];
                    if(accRec!=null){
                        Set<String> countryPicklistSet = picklistValueApis(CommonUtil.getPicklistValueFromObjectField('Account', 'BillingCountryCode'));
                        Set<String> statePicklistSet = picklistValueApis(CommonUtil.getPicklistValueFromObjectField('Account', 'BillingStateCode'));
                        
                        accRec.Name = accountDetails.accName;
                        accRec.BillingStreet = accountDetails.billingStreet;
                        accRec.BillingCity = accountDetails.billingCity ;
                        if(countryPicklistSet.contains(accountDetails.countryCode)){
                            accRec.BillingCountryCode =  accountDetails.countryCode;
                            accRec.BillingStateCode =  statePicklistSet.contains(accountDetails.stateCode) ? accountDetails.stateCode : '';
                        }
                        accRec.BillingPostalCode = accountDetails.postalCode;
                        accRec.AQ_Sanction_Status__c = accountDetails.sanctionStatus;
                        accRec.KYC_Status__c = accountDetails.kycStatus;
                        accRec.Action_Point__c = 'Endorsement';
                    }
                    update accRec;
                    
                    //get Cloned Submission 
                    String clonedoppId = '';
                    String endorsementType = 'Insured Account Update';
                    String policyId = accountDetails.policyId;
                    String effDate = accountDetails.effDate;
                    String endorsementReason = accountDetails.endorsementReason;
                    String endoresementReasonOther = '';
                    //get original Active Submission from Policy
                                String originalOppId = getActiveSubmission(policyId);
                                if(originalOppId!=null){
                                    String accId = accRec.Id;
                                    insuredAccountUpdates(policyId, accId, endorsementType, effDate);
                                    result.resultAccId = accId;
                                }
                                else{
                                    result.error = 'No Active Submission/Transaction record found on this Policy';
                                }  
                    //result.resultAccId = accRec.Id;
                    return result;
                }
                else{
                    if(String.isBlank(dunsNumber)){
                        //need to handle //display list based on account name
                        List<AccountWrapper> accountList = new List<AccountWrapper>();
                        List<Account> accDupList = [SELECT Id,Name,BillingStreet, BillingCity, BillingPostalCode, BillingCountry, 
                                                    BillingStateCode, BillingCountryCode, BillingAddress, Duns_Number__c, RecordType.Name FROM Account 
                                                    Where Name=:accountDetails.accName AND Id!=:accountDetails.accId];
                         if(!accDupList.isEmpty()){
                            for(Account acc: accDupList){
                                AccountWrapper accWrap = new AccountWrapper();
                                accWrap.accId = acc.Id;
                                accWrap.name = acc.Name;
                                //accWrap.dunsNumber = acc.Duns_Number__c;
                                accWrap.billingStreet = acc.BillingStreet;
                                accWrap.type = acc.RecordType.Name;
                                accountList.add(accWrap);
                            }
                            result.accList = accountList;
                            result.showAccounts = true;
                            return result;
                        }
                        else{
                            ResultWrapper clonedAccountResult = NewEndorsementAQController.cloneAccountWithRelated(resp);
                            System.debug('clonedAccountResult::'+clonedAccountResult);
                            return clonedAccountResult;
                        }   
                    }
                    else{
                        //display existing account list based on acc name and duns number
                        List<AccountWrapper> accountList = new List<AccountWrapper>();
                        List<Account> accDupList = [SELECT Id,Name,BillingStreet, BillingCity, BillingPostalCode, BillingCountry, 
                                                    BillingStateCode, BillingCountryCode, BillingAddress, Duns_Number__c, RecordType.Name FROM Account 
                                                    Where Name=:accountDetails.accName AND Duns_Number__c =:dunsNumber
                                                    AND Id!=:accountDetails.accId];
                        if(!accDupList.isEmpty()){
                            for(Account acc: accDupList){
                                AccountWrapper accWrap = new AccountWrapper();
                                accWrap.accId = acc.Id;
                                accWrap.name = acc.Name;
                                accWrap.dunsNumber = acc.Duns_Number__c;
                                accWrap.billingStreet = acc.BillingStreet;
                                accWrap.type = acc.RecordType.Name;
                                accountList.add(accWrap);
                            }
                            result.accList = accountList;
                            result.showAccounts = true;
                            return result;
                        }
                        else{
                            ResultWrapper clonedAccountResult = NewEndorsementAQController.cloneAccountWithRelated(resp);
                            System.debug('clonedAccountResult::'+clonedAccountResult);
                            return clonedAccountResult;

                        }
                    }
                } 
            }
            return result;
        

    }
    

    @AuraEnabled
    public static ResultWrapper createNewEndorsement(String policyId, String effDate, String endorsementType, 
                                                     String cancelEndorsement,String endorsementReason,
                                                     String endoresementReasonOther,Map<String, Object> accountData) {
        ResultWrapper result = new ResultWrapper();
                                                         
        try {
            Date effectiveDate = CommonUtil.parseDateFromString(effDate);
            String clonedQuoteId = '';
            String clonedoppId = '';
            
            List<Quote> quotes = [Select Id,Quote_Type__c,Status,Endorsement_Effective_Date__c,OpportunityId
                                  From Quote Where Policy__c = :policyId And (Status = 'Bound' OR Status = 'Bound Pending') 
                                  //And (Endorsement_Effective_Date__c <= :effectiveDate OR Endorsement_Effective_Date__c = Null)   ***Commented due to bug #53383***
                                  Order By Endorsement_Effective_Date__c Desc NULLS LAST,
                                  Endorsement_Quote_Bound_Date__c Desc NULLS LAST, LastModifiedDate Desc NULLS LAST 
                                  Limit 1];
            
            if (quotes.isEmpty()){
                result.error = Label.EFFECTIVE_DATE_NOT_EXIST;
                return result;
            }
            else if(!quotes.isEmpty() && quotes[0].Status == 'Bound Pending'){
                result.error = Label.Amendment_on_Bound_Pending_Error;
                return result;
            }
     
            Map<String, Object> fieldUpdateMap = new Map<String, Object>();
            fieldUpdateMap.put('Contract_Cancellation_Reason__c', cancelEndorsement);            
            
            fieldUpdateMap.put('Quote_Type__c', endorsementType);
            fieldUpdateMap.put('Endorsement_Effective_Date__c', effectiveDate);
            
            ResultResponse response = new ResultResponse();
            if(endorsementType == 'Coverage Amendment' || endorsementType == 'Midterm Cancellation' ||
              endorsementType == 'Flat Cancellation' || endorsementType == 'Policy Duration Change'){
                  fieldUpdateMap.put('Endorsement_Reason__c', endorsementReason);
                  fieldUpdateMap.put('Endorsement_Reason_Other__c', endoresementReasonOther);
                  if(endorsementType == 'Coverage Amendment' || endorsementType == 'Policy Duration Change'){
                      fieldUpdateMap.put('Technical_Fee__c', 0);
                      fieldUpdateMap.put('Fee__c', 0);                      
                  }
                  if(endorsementType == 'Midterm Cancellation' || endorsementType == 'Flat Cancellation'){
                      fieldUpdateMap.put('Policy_Wording_Document__c',null);
                      fieldUpdateMap.put('IPID_Document__c',null);
                  }
                response = CloneQuoteHandler.cloneQuoteWithChildren(String.valueOf(quotes[0].Id),fieldUpdateMap);                
                Quote quoteClone = (Quote)response.data;
                if(quoteClone != null){
                    clonedQuoteId = quoteClone.Id;
                    clonedoppId = quoteClone.OpportunityId;                                        
                    /*quoteClone.Endorsement_Reason__c = endorsementReason;
                    quoteClone.Endorsement_Reason_Other__c = endoresementReasonOther;*/
                    result.error = '';
                    //GlobalStaticVar.byPassQuoteTrigger = true;
                    //update quoteClone;
                }    
            }else if(endorsementType == 'Insured Account Update'){                     
                string resp = JSON.serialize(accountData);
                ResultWrapper accDupList = new ResultWrapper();
                if(string.isNotBlank(resp)) accDupList = checkDuplicateAccount(resp); 
                
                if(accDupList.showAccounts){
                    result.showAccounts = accDupList.showAccounts;
                    result.accList = accDupList.accList;
                }else{
                    result.resultAccId = accDupList.resultAccId;
                }
                
                // New changes as per CD-132
                List<Quote> lstQuote = [Select Id,QuoteNumber,Quote_Type__c,Binder__c,Master_Binder__c,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, 
                                        Azure_Id__c,Rating_Status__c,Layer__c from Quote where Policy__c=:policyId And Status='Bound' 
                                        AND Opportunity.RecordType.Name ='Aqueous' And Rating_Status__c='Clear' And Binder__c!=null
                                        order by Endorsement_Quote_Bound_Date__c desc limit 1];
                
                if(!lstQuote.isEmpty()){
                    lstQuote[0].Quote_Action__c = 'InsuredAccountUpdate';
                    lstQuote[0].Name_Insured_Update_Effective_Date__c =  effectiveDate;
                    update lstQuote[0];
                }
                 // New changes End as per CD-132
                return result;            
            }else if(endorsementType == 'Full Amendment'){
                ResultWrapper fullAmendmentResult = cloneRecords.fullAmendment(policyId,endorsementType, effDate, endorsementReason, endoresementReasonOther);
                clonedoppId = fullAmendmentResult.oppId;
                result.error = fullAmendmentResult.error;
            }
            else if(endorsementType == 'Reinstatement'){
                Map<String, Object> QuotefieldMap = new Map<String, Object>();
                system.debug('endorsementType-->'+endorsementType);
                QuotefieldMap.put('Quote_Type__c', endorsementType);
                QuotefieldMap.put('Endorsement_Effective_Date__c', effectiveDate);
                response = CloneQuoteHandler.cloneQuoteWithChildren(String.valueOf(quotes[0].Id),QuotefieldMap);
                
                //update Quote
                Quote quoteClone = (Quote)response.data;
                if(quoteClone != null){
                    clonedQuoteId = quoteClone.Id;
                    clonedoppId = quoteClone.OpportunityId;
                    result.error = '';
                } else{
                    result.error = response.errors[0];
                }              
            } 
            
            
            result.oppId = clonedoppId;
            result.cloneQuoteId = clonedQuoteId;
            if( endorsementType == 'Coverage Amendment' || endorsementType == 'Midterm Cancellation' ||
            endorsementType == 'Flat Cancellation' || endorsementType == 'Policy Duration Change'){
            Change_Log__c changelog = CommonUtil.createChangeLog(policyId,endorsementType, null);
            if(changelog != null){
                insert changelog;
            }
        }
            return result;
            
        } catch (Exception ex) {
            ErrorLogsUtilityHelper.logError(ex, 'NewEndorsementAQController.createNewEndorsement', CommonUtil.getExceptionMessage(ex), '', 'AQ_Exceptions', '', String.valueOf(ex.getLineNumber()));
            result.error = CommonUtil.getExceptionMessage(ex);
            result.cloneQuoteId = '';
        }
        
        return result;
    }
    
    @AuraEnabled
    public static ResultWrapper updateAccount(String accId, String policyId, Map<String, Object> accountData){
       String endorsementType = 'Insured Account Update';
       String clonedoppId = '';
       ResultWrapper result = new ResultWrapper();
       string resp = JSON.serialize(accountData); 
         if(string.isNotBlank(resp)){
             AddressWrapper accountDetails = (AddressWrapper) JSON.deserialize(resp, AddressWrapper.class); 
             String endorsementReason = accountDetails.endorsementReason;
             String effDate = accountDetails.effDate; 
        try{
           String endoresementReasonOther = '';
           //get original Active Submission from Policy
           String originalOppId = getActiveSubmission(policyId);
           if(originalOppId!=null){
              insuredAccountUpdates(policyId, accId, endorsementType, effDate);
              result.resultAccId = accId;
           }else{
               result.error = 'No Active Submission/Transaction record found on this Policy';
           }                  
        }
        catch (Exception ex) {
            result.error = CommonUtil.getExceptionMessage(ex);
            result.resultAccId = '';
        }
       }
       return result; 
    }
    @AuraEnabled
    public static ResultWrapper createNewAccount(Map<String, Object> accountData, String policyId){
        ResultWrapper result = new ResultWrapper(); 
        String endorsementType = 'Insured Account Update';
        String clonedoppId = '';
        string resp = JSON.serialize(accountData);
        if(string.isNotBlank(resp)){
            AddressWrapper accountDetails = (AddressWrapper) JSON.deserialize(resp, AddressWrapper.class); 
            String endorsementReason = accountDetails.endorsementReason;
            String effDate = accountDetails.effDate; 
            Set<String> countryPicklistSet = picklistValueApis(CommonUtil.getPicklistValueFromObjectField('Account', 'BillingCountryCode'));
            Set<String> statePicklistSet = picklistValueApis(CommonUtil.getPicklistValueFromObjectField('Account', 'BillingStateCode'));
            try{
                Account newAcc = new Account();
                newAcc.Name = accountDetails.accName;
                Id recordTypeBusiness = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
                newAcc.RecordTypeId = recordTypeBusiness;
                newAcc.BillingStreet = accountDetails.billingStreet;
                newAcc.BillingCity = accountDetails.billingCity ;
                newAcc.BillingPostalCode = accountDetails.postalCode;
                if(countryPicklistSet.contains(accountDetails.countryCode)){
                    newAcc.BillingCountryCode =  accountDetails.countryCode;
                    newAcc.BillingStateCode =  statePicklistSet.contains(accountDetails.stateCode) ? accountDetails.stateCode : '';
                }
                newAcc.AQ_Sanction_Status__c = accountDetails.sanctionStatus;
                newAcc.KYC_Status__c = accountDetails.kycStatus;
                newAcc.Action_Point__c = 'Endorsement';
                insert newAcc;
                System.debug('newAcc::'+newAcc.Id);
                String endoresementReasonOther = '';
				//get original Active Submission from Policy
                 String originalOppId = getActiveSubmission(policyId);
                 if(originalOppId!=null){
                    String accId = newAcc.Id;
                    insuredAccountUpdates(policyId, accId, endorsementType, effDate);
                    result.resultAccId = newAcc.Id;
                 }else{
                    result.error = 'No Active Submission/Transaction record found on this Policy';
                 }                           
                //result.resultAccId = newAcc.Id; 
            }
            catch (Exception ex) {
                result.error = CommonUtil.getExceptionMessage(ex);
                result.resultAccId = '';
            }
        }
        return result; 
    }
    
    @AuraEnabled
	public static ResultResponse ratingQuoteRenewalOrNb(String quoteId) {
        ResultResponse result = new ResultResponse();
        result = RateController.getRatingFromCallOut(quoteId);
        System.debug('result'+result);
		//return result.errors.isEmpty() ? '' : result.errors[0];
        return result;
	}

    @AuraEnabled
	public static API_Log__c syncQuoteToMiddleware(String quoteId) {
        return FinalizeService.syncQuoteToMiddleware(quoteId);
    }
    
    /******** New Method for SyncCallToQuote ***/
    @AuraEnabled
    public static API_Log__c syncQuoteFunc(String policyId){
        
        List<Quote> lstQuote = [Select Id,QuoteNumber,Quote_Type__c,Binder__c,Master_Binder__c,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, 
                                Azure_Id__c,Rating_Status__c,Layer__c from Quote where Policy__c=:policyId And Status='Bound' 
                                AND Opportunity.RecordType.Name =: 'Aqueous' And Rating_Status__c='Clear' And Binder__c!=null
                                order by Endorsement_Quote_Bound_Date__c desc limit 1];
        
         API_Log__c objApiLog = new API_Log__c();

        if(!lstQuote.isEmpty()){
            
            
            objApiLog = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', lstQuote[0], 'PreDocGenerationSync_Synchronous'); // PreSync before Finalize  

            /*** Sync Call to generate Document***/
            GenerateDocumentApiHandler.GenerateResult genresult =  generateDocOnPolicy(lstQuote[0],policyId);
            
            /****** Async Queable call **/
            System.enqueueJob(new SyncQuoteQueueable(lstQuote));

            if(objApiLog != null){
                insert objApiLog;
            }
        }
        
        return objApiLog;
    }
    /******************** Created by Navdeep ***********************/
    public static GenerateDocumentApiHandler.GenerateResult generateDocOnPolicy(Quote quoteRecord,String policyId){
      
        try {
            List<Quote> quoteList = new List<Quote>();
            List<string> quoteAzureIdList = new  List<string>();                   
            quoteAzureIdList.add(quoteRecord.Azure_ID__c);
            
            String docType;
            if(quoteRecord.Layer__c == 'Primary'){
                docType = 'PrimaryPolicyAmendment'; 
            }
            else{
                docType = 'ExcessPolicyAmendment';   
            }
            
            string bodyreq;            
            string ProductClassCd = 'Aqueous_PI';
            string accountId = quoteRecord.AccountId;
            String fileName = 'Insured-Account-Update';
            string OutputFileName = docType+'-'+fileName+'.pdf';
            string RequestType = 'Quote';
            
            bodyreq = '{"DocumentType":"' +docType+ '","Quotes":'+JSON.serialize(quoteAzureIdList)+ ',"ProductClassCd":"'+ProductClassCd+'","OutputFileName" : "'+OutputFileName+'","RequestType" : "'+RequestType+'","AccountId": "'+accountId+'"}';
            
            GenerateDocumentApiHandler.GenerateResult genresult =  GenerateDocumentApiHandler.generateDocIdAQ('Policy__c',policyId, accountId, docType, bodyReq,quoteRecord.Binder__c);
            return genresult;
        } catch (Exception ex) {
            system.debug('Exception==>'+ex);
           // result.errMsg = CommonUtil.getExceptionMessage(ex);
           return null;
        }
        
    }

    @AuraEnabled
    public static Boolean validateSanctionCheckOnAccount(String accountId, String policyId){
        Boolean boolProceedToDocGeneration = false;
        List<Sanction_Status__c> lstUpdatedSanctions = new List<Sanction_Status__c>();
        lstUpdatedSanctions = SanctionSearchAPICallout.callAccountSanctionV2API(new Set<Id>{Id.valueOf(accountId)});
        if(!lstUpdatedSanctions.isEmpty()){
            if(lstUpdatedSanctions[0].Sanction_Status__c != 'Pass' && lstUpdatedSanctions[0].Sanction_Status__c != 'Cleared'){
                //update Account fields
                Account objFailedAccount = [SELECT Id, Action_Point__c, Insured_Account_Update_Policy_Id__c FROM Account WHERE Id =: accountId];
                objFailedAccount.Action_Point__c = 'Endorsement';
                objFailedAccount.Insured_Account_Update_Policy_Id__c = policyId;
                update objFailedAccount;
            }
            else{
                boolProceedToDocGeneration = true;
                //update Account fields
                Account objFailedAccount = [SELECT Id, Action_Point__c, Insured_Account_Update_Policy_Id__c FROM Account WHERE Id =: accountId];
                if(objFailedAccount.Action_Point__c != null || objFailedAccount.Insured_Account_Update_Policy_Id__c != null){
                    objFailedAccount.Action_Point__c = null;
                    objFailedAccount.Insured_Account_Update_Policy_Id__c = null;
                    update objFailedAccount;
                }
            }
        }
        return boolProceedToDocGeneration;
    }
    
    public class ResultWrapper {
        @AuraEnabled public String cloneQuoteId {get; set;}
        @AuraEnabled public String resultAccId {get; set;}
        @AuraEnabled public String oppId {get; set;}
        @AuraEnabled public String error {get; set;}
        @AuraEnabled public List<AccountWrapper> accList {get; set;}
        @AuraEnabled public List<Quote> quoteList {get; set;}
        @AuraEnabled public Boolean showAccounts {get; set;}
        public ResultWrapper() {
            cloneQuoteId = '';
            error = '';
            showAccounts = false;
            oppId = '';
            accList = new List <AccountWrapper>();
        }
    }
    
    Public class AddressWrapper {
        @AuraEnabled public String accId {get; set;}
        @AuraEnabled public String accName {get; set;}
        @AuraEnabled public String billingStreet {get; set;}
        @AuraEnabled public String billingCity {get; set;}
        @AuraEnabled public String stateCode {get; set;}
        @AuraEnabled public String billingCountry {get; set;}
        @AuraEnabled public String postalCode {get; set;}
        @AuraEnabled public String countryCode {get; set;}
        @AuraEnabled public String kycStatus {get; set;}
        @AuraEnabled public Date kycDate {get; set;}
        @AuraEnabled public String sanctionStatus {get; set;}
        @AuraEnabled public Date sanctionDate {get; set;}
        @AuraEnabled public String policyId {get; set;}
        @AuraEnabled public String effDate {get; set;}
        @AuraEnabled public String endorsementReason {get; set;}
    }
    
   Public class AccountWrapper {
        @AuraEnabled public String accId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String dunsNumber {get; set;}
        @AuraEnabled public String billingStreet {get; set;}
        @AuraEnabled public String type {get; set;}
    }
    
    
}