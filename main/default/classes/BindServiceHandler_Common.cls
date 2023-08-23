/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 08-02-2022
 * @last modified by  : Vinayesh
**/
public with sharing class BindServiceHandler_Common {

    private static Boolean isIncomingBind = false;
    /*************************************************
    * Method Name: checkSurplusLinesLicense
    * Author: Giang Phan
    * Date: 
    * Params: String quoteId
    **************************************************/
    @AuraEnabled
    public static ResultResponse checkSurplusLinesLicense(String quoteId){
        ResultResponse result = new ResultResponse();
        List<Quote> quotes = QuoteQueryUtil.fetchQuoteById(quoteId);
        if (quotes.isEmpty()) {
            result.errors.add(Label.Error_NoQuoteIsFound);
            return result;
        }
        List<Broker_Account__c> brokerAcc = BrokerAccountQueryUtil.fetchPrimaryBrokerAccountsForOpp(quotes[0].OpportunityId);

        List<Broker_License__c> brokerLCList = BrokerLicenseQueryUtil.fetchLicencesForBroker(brokerAcc[0].Broker_Contact__c);

            if(brokerLCList.isEmpty()){
                result.errors.add(Label.Error_NoSurplusLinesLicense);
                return result;
            }

        List<Account> lstAcct = AccountQueryUtil.fetchAccountById(quotes[0].AccountId);
            if(lstAcct.isEmpty()){
                result.errors.add(Label.Error_NoAccountIsFound);
                return result;
            }else if(String.isBlank(lstAcct[0].BillingStateCode)){
                result.errors.add('Billing state code of SurplusLines is empty');
                return result;
            }

        Map<String, Broker_License__c> mapBrokerLicense = new Map<String, Broker_License__c>();
            for(Broker_License__c brokerLicense : brokerLCList){
                String key = brokerLicense.License_State__c;
                mapBrokerLicense.put(key,brokerLicense);
            }
            if(!mapBrokerLicense.containsKey(lstAcct[0].BillingStateCode)){
                result.errors.add(Label.Error_NoLicenseIsNotMatchAccount);
                return result;
            }

        result.isSuccess = true;
        return result;
    }

    public static void bindQuoteIncoming(String quoteId, String payPlan, Boolean isBoundPending){
        isIncomingBind = true;
        bindQuote(quoteId, payPlan, isBoundPending);
        isIncomingBind = false;
    }

    @AuraEnabled
    public static ResultResponse bindQuote(String quoteId, String payPlan, Boolean isBoundPending){
        ResultResponse result = new ResultResponse();
        
        List<Quote> quoteList = QuoteQueryUtil.fetchQuoteById(quoteId);
        if (quoteList.isEmpty()) {
            result.errors.add('No quote is found');
            return result;
        }
        
        string productName = quoteList[0].Product_Name__c;
        
        if(productName == GlobalVariables.PROD_NAME_FOR_PI){
            for(Quote quoteObj : quoteList){
                if(quoteObj.Status == 'Referred'){
                    result.errors.add('One of the Quotes is in Referred state. Please clear the Referrals to Proceed.');
            		return result;
                }
            }
            result = BindService.bindQuoteAqueous(quoteId,payPlan,isBoundPending,'');
        }else{
            if(isIncomingBind){
                result = BindService.bindQuoteCelerityIncoming(quoteId,payPlan,isBoundPending);
            }
            else{
                result = BindService.bindQuoteCelerity(quoteId,payPlan,isBoundPending);
            }
            system.debug('celerity Jai' + result );
        }
        /* Update Policy info on bind success for MTA (ERP and Policy duration Change) by Jai */
        if( result.isSuccess && productName != GlobalVariables.PROD_NAME_FOR_PI){
            if( quoteList[0].Quote_Type__c == 'Policy Duration Change' ||  quoteList[0].Quote_Type__c == 'Reinstatement' ){
                update new Policy__c (Id = (Id)result.data, Expiration_Date__c = quoteList[0].ExpirationDate );
            }
            if( quoteList[0].Quote_Type__c == 'Extended Reporting Period (ERP)'  ){
                update new Policy__c (Id = (Id)result.data, Policy_Status__c = 'ERP' );
            }
        }
        /* Update Policy info on bind success for MTA (ERP and Policy duration Change) by Jai */
        return result;
    }

    @AuraEnabled
    public static ResultResponse bindQuoteQC(String quoteId, String payPlan, Boolean isBoundPending, String binder, String blInfo){
        ResultResponse result = new ResultResponse();
        
        List<Quote> quoteList = QuoteQueryUtil.fetchQuoteById(quoteId);
        if (quoteList.isEmpty()) {
            result.errors.add('No quote is found');
            return result;
        }
        
        string productName = quoteList[0].Product_Name__c;
        
        if(productName == GlobalVariables.PROD_NAME_FOR_PI){
            for(Quote quoteObj : quoteList){
                if(quoteObj.Status == 'Referred'){
                    result.errors.add('One of the Quotes is in Referred state. Please clear the Referrals to Proceed.');
            		return result;
                }
            }
            result = BindService.bindQuoteAqueous(quoteId,payPlan,isBoundPending,binder);
        }else{
            result = BindService.bindQuoteWithBLInfo(quoteId,payPlan,isBoundPending, blInfo);
        }
        /* Update Policy info on bind success for MTA (ERP and Policy duration Change) by Jai */
        if( result.isSuccess && productName != GlobalVariables.PROD_NAME_FOR_PI){
            if( quoteList[0].Quote_Type__c == 'Policy Duration Change' ||  quoteList[0].Quote_Type__c == 'Reinstatement' ){
                update new Policy__c (Id = (Id)result.data, Expiration_Date__c = quoteList[0].ExpirationDate );
            }
            if( quoteList[0].Quote_Type__c == 'Extended Reporting Period (ERP)'  ){
                update new Policy__c (Id = (Id)result.data, Policy_Status__c = 'ERP' );
            }
        }
        /* Update Policy info on bind success for MTA (ERP and Policy duration Change) by Jai */
        return result;
    }
    
    /*************************************************
    * Method Name: checkBoundPendingFromOFACApi
    * Author: 
    * Description : Call out to update status Bound for Quote
    * Date: 04-Nov-2019
    * Params: Quote currentQuote
    * Return: Bool isBoundPending
    * Exceptions:
    * Revision: 
    **************************************************/
  /*  @TestVisible
    private static Boolean checkBoundPendingFromCallOutApi(Quote currentQuote) {
        Boolean isBoundPending = false;                
        
        // only for Celerity
        System.debug('>>>currentQuote.Opportunity.RecordType.Name>>>'+currentQuote.Opportunity.RecordType.Name);     
        if(currentQuote.Opportunity.RecordType.Name != GlobalVariables.CELERITY) return isBoundPending;

        List<InComingRequestOFAC> listInComingRequestOFAC = new List<InComingRequestOFAC>();
        Map<String, Account> mapUpdateAccount = new  Map<String, Account>();
        List<Account> accountAlls = new List<Account>();
        List<Contact> contactAlls = new List<Contact>();
    
        // Process for Busicess Account
        if(currentQuote.Opportunity.Account.RecordType.Name == 'Business')
        {
            List<Account> accOnOppts = AccountQueryUtil.fetchAccountWithContacts(currentQuote.Opportunity.AccountId);
            
            accountAlls.add(accOnOppts[0]);
            if(!accOnOppts[0].contacts.isEmpty()) contactAlls.addAll(accOnOppts[0].contacts);

           /////////////////Primary Broker Contact////////////////////
            List<Broker_account__c> brokerAccounts = BrokerAccountQueryUtil.fetchPrimaryBrokerAccountsForOpp(currentQuote.OpportunityId);

            if(!brokerAccounts.isEmpty() && brokerAccounts[0].Broker_Contact__r != null) {
                List<Account> accOnBrokers = AccountQueryUtil.fetchAccountWithSpecificContact(brokerAccounts[0].Broker_Contact__r.AccountId, brokerAccounts[0].Broker_Contact__c);
                
                if(!accOnBrokers.isEmpty()) {
                    accountAlls.add(accOnBrokers[0]);
                    if(!accOnBrokers[0].contacts.isEmpty()) contactAlls.addAll(accOnBrokers[0].contacts);
                }
               
            }
            ///////////////End Primary Broker Contact////////////////////

            for(Account acc : accountAlls) {
                InComingRequestOFAC inComingRequestOFAC = new InComingRequestOFAC(acc);
                listInComingRequestOFAC.add(inComingRequestOFAC);
                mapUpdateAccount.put(acc.Id,acc);
            }

            for(Contact con : contactAlls) {
                InComingRequestOFAC inComingRequestOFAC = new InComingRequestOFAC(con);
                listInComingRequestOFAC.add(inComingRequestOFAC);
            }
            //End
        } 

        //call out
        return Invsk_Callout.checkBoundPending(currentQuote, listInComingRequestOFAC, mapUpdateAccount);
    }*/

    /*************************************************
    * Method Name: getInitData
    * Author: 
    * Date: 
    * Params: String quoteId
    * Return: object
    * Exceptions:
    * Revision: 
    **********************************************/
    @AuraEnabled
    public static InitObject getInitData(String quoteId) {
        InitObject initObject = new InitObject();
        try {        
            // Get current quote
            Quote currentQuote = QuoteQueryUtil.fetchQuoteById(quoteId)[0];
            // Get product name
            String productName = currentQuote.Product_Name__c;
            // Get payplan picklist values base on product name from metadata type

            if (!String.isBlank(currentQuote.Opportunity.Product__r.Pay_Plan__c)) {
                String picklistValuesString = currentQuote.Opportunity.Product__r.Pay_Plan__c;
                initObject.payplanPicklist = picklistValuesString.split(';');
                //initObject.currentPayplan = currentQuote.Payplan__c;
                initObject.brokerName = getBrokerName(String.valueOf(currentQuote.OpportunityId));
             
            //show bind pending US-35795
            if((currentQuote.Quote_Type__c == 'New Business' || currentQuote.Quote_Type__c == 'Renewal') 
                    && String.isBlank(currentQuote.Policy__c)){
                    initObject.showBindOptions = true;
            }
                
            }
            return initObject;

        } catch (Exception ex) {
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));
        }
    }

    public static Policy__c generatePolicyFromQuote(Quote currentQuote, Boolean isBoundPending, String nIPRResult, String licenseNumber) {
        Policy__c policy = new Policy__c();
        try {
            // new policy
            if (String.isBlank(currentQuote.Policy__c)) {
                policy.RecordTypeId = Schema.SObjectType.Policy__c.getRecordTypeInfosByName().get(currentQuote.Opportunity.RecordType.Name).getRecordTypeId();
                policy.Account__c = currentQuote.AccountId;
                policy.Effective_Date__c = currentQuote.Effective_Date__c;
                policy.Expiration_Date__c = currentQuote.ExpirationDate;
                policy.Master_Binder__c = currentQuote.Master_Binder__c;
                policy.Layer__c = currentQuote.Layer__c;
                if(currentQuote.Quote_Type__c == 'New Business'){
                    policy.Pending_or_Prior_Proceedings_Date__c = policy.Effective_Date__c;
                }
  
   
            } else {
                policy.Id = currentQuote.Policy__c;
            }
                 //long ly - 08/Jul/2020 - Check the condition before updating the Policy Number
               Policy_Incremental_Setting__c mdtSetting = (Policy_Incremental_Setting__c)CommonUtil.getSettingByField('Policy_Incremental_Setting__c',
                                                            'Renewal__c', 'Name', currentQuote.Product_Name__c);
                if(currentQuote.Opportunity.Type == 'Renewal' && mdtSetting != null && mdtSetting.Renewal__c && 
                   currentQuote.Quote_Type__c == 'Renewal' && String.isBlank(currentQuote.Opportunity.Policy__r.Policy_Number__c)) {
                policy.Policy_Number__c = currentQuote.Opportunity.Prior_Policy__r.Policy_Number__c + '__' + currentQuote.Id;
                if(currentQuote.Opportunity.Prior_Policy__r.Pending_or_Prior_Proceedings_Date__c != null){
                   policy.Pending_or_Prior_Proceedings_Date__c = currentQuote.Opportunity.Prior_Policy__r.Pending_or_Prior_Proceedings_Date__c;
                }       
                }
                
            if(currentQuote.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                policy.Total_Premium__c = currentQuote.Total_Cost_To_Client__c;
                policy.Effective_Date__c = currentQuote.Effective_Date__c;
                policy.Master_Binder__c = currentQuote.Master_Binder__c;
            }else{
                policy.Total_Premium__c = currentQuote.Total_Premium__c;
            }
            policy.Product_Name__c = currentQuote.Product_Name__c;//28-May-2020 Hoang add product name field
            //policy.Policy_Status__c = isBoundPending ? 'Bound Pending' : 'Bound';
           
            String quoteType = currentQuote.Quote_Type__c;            
            if(quoteType == 'Midterm Cancellation' || quoteType == 'Flat Cancellation'){
                policy.Policy_Status__c = 'Cancelled';
                policy.Cancellation_Reason__c = currentQuote.Endorsement_Reason__c;
                policy.Cancellation_Date__c = currentQuote.Endorsement_Effective_Date__c;
            }
            else if(quoteType == 'Reinstatement' && policy.RecordType.Name == GlobalVariables.AQUEOUS){
                policy.Total_Premium__c = currentQuote.Total_Premium__c;
                policy.Cancellation_Date__c = null;
                policy.Cancellation_Reason__c = null;
                if (policy.Policy_Status__c == 'Cancelled') policy.Policy_Status__c = 'Bound';
            }
            else if(quoteType == 'Insured Account Update' && policy.RecordType.Name == GlobalVariables.AQUEOUS){
                /*policy.Total_Premium__c = currentQuote.Total_Premium__c;
                policy.Cancellation_Date__c = null;
                policy.Cancellation_Reason__c = null;*/
                policy.Policy_Status__c = 'Bound';
            }
            else{
                policy.Policy_Status__c = isBoundPending ? 'Bound Pending' : 'Bound';
            }

            //Update NIPR Result - Giang added 21/Jul/2020
            //When AgencyLicense & BrokerLicense is Fail
            String qType = currentQuote.Quote_Type__c;
            if( qType == 'New Business' || qType == 'Renewal' || qType == 'Broker on Record Change' ){ //added by Jai to prevent Binder Lisence info overwrite in case of MTA Quote
                policy.NIPR_Results__c = nIPRResult;
                policy.Binding_License_Number__c = licenseNumber;
            }
            
            //End Update NIPR Result
            
            system.debug('policy='+policy);
            upsert policy;
            policy = PolicyQueryUtil.fetchPolicyById(policy.Id)[0];
            system.debug('after upsert policy='+policy);
            // Update quote and link quote to the contract
            currentQuote.Policy__c = policy.Id;
            if (isBoundPending) currentQuote.Status = 'Bound Pending';
            else currentQuote.Status = 'Bound';
            System.debug('currentQuote Status-->'+currentQuote.Status);
            System.debug('Policy Cancellation date-->'+policy.Cancellation_Date__c);
            currentQuote.Endorsement_Quote_Bound_Date__c = Datetime.now();  
            // if(currentQuote.Product_Name__c == 'Professional Indemnity' && currentQuote.Retroactive_Date__c == 'Retro - Inception date'){
            //     currentQuote.RetroDate__c = currentQuote.Effective_Date__c;
            // }
            update currentQuote;
        } catch (Exception ex) {
            system.debug('exception : ' + ex.getMessage());
            policy = new Policy__c();
        }
        
        return policy;
    }

    public static Opportunity generateOpportunity(Policy__c item, String oppId) {
        Opportunity opp = OpportunityQueryUtil.fetchOpportunityById(oppId)[0];
        List<Quote> quoteList = QuoteQueryUtil.fetchQuotesByOpportunty(opp.Id);
        Opportunity result = new Opportunity();

        Boolean updateSubStage = false;
        //Boolean updateTransactionStatus = false;
        try {
            if (item == null || String.isBlank(oppId)) return result;
            result.Id = oppId;
            //result.Effective_Date__c = item.Effective_Date__c;
            //result.Expiration_Date__c = item.Expiration_Date__c;
            result.Amount = item.Total_Premium__c;
            result.Policy__c = item.Id;
            if(opp.Product__r.Name == GlobalVariables.PROD_NAME_FOR_PI){
                if(!quoteList.isEmpty()){
                    for(Quote quo : quoteList){
                        if(quo.Status == 'Bound'){          //To make the submission active even if 1 quote is Bound
                            updateSubStage = false;
                            break;
                        }
                        if(quo.Status != 'Bound' && quo.Status != 'Correction' && quo.Status != 'Cancelled' && quo.Status != 'Closed'){
                            updateSubStage = true;
                        }
                        /*else if(quo.Status == 'Bound' && (quo.Quote_Type__c == 'Full Amendment' || quo.Quote_Type__c == 'Renewal')){
                            updateTransactionStatus = true;
                        }*/
                    }
                }
                /*if(updateTransactionStatus && result.Transaction_Status__c != 'Active'){
                    result.Submission_Status__c = 'Bound';
                    result.StageName = 'Closed Won';
                    result.Transaction_Status__c = 'Active';
                }*/
                if(updateSubStage){
                    result.Submission_Status__c = 'Bound - In Waiting';
                    result.StageName = 'Qualified';
                }else{
                    result.Submission_Status__c = 'Bound';
                    result.StageName = 'Closed Won';
                    if(result.Transaction_Status__c != 'Active'){
                        result.Transaction_Status__c = 'Active';
                    }
                }
            }else{
            	result.StageName = 'Closed Won';                
            }
           
        } catch (Exception ex) {
            system.debug('exception : ' + ex.getMessage() + ex.getLineNumber());
            result = new Opportunity();
        }
        
        return result;
    }

    public static void updateQuoteListAfterBind(Quote currentQuote) {
        List<Quote> updateQuotes = new List<Quote>();
        try {
            // get existing quotes
            for (Quote qt : QuoteQueryUtil.fetchExistingQuotesByOpportunty(currentQuote.OpportunityId, currentQuote.id)) // Added by Maeran Shaikh on 14/6/2021 Status Correction check for Celerity as well
            { 
                                        
                if(currentQuote.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                    if(qt.Layer__c == currentQuote.Layer__c && qt.Layer__c == 'Primary'){
                        if(qt.Status != 'Correction' && qt.Status != 'Cancelled'){
                             qt.Closed_Reason__c = 'Another version bound'; 
                             qt.Status = 'Closed'; 
                        }   
                    }
                }else{
                      qt.Closed_Reason__c = 'Another version bound'; 
                      qt.Status = 'Closed'; 
                }            

                updateQuotes.add(qt);
            }
        } catch (Exception ex) {
            system.debug('exception : ' + ex.getMessage());
        }
        if(!updateQuotes.isEmpty()){
            update updateQuotes;
        }
        
    }

    private static String getBrokerName(String oppId) { 
        List<Broker_account__c> brokerAccounts = BrokerAccountQueryUtil.fetchPrimaryBrokerAccountsForOpp(oppId);
        return brokerAccounts.isEmpty() ? '' : brokerAccounts[0].Broker_Contact__r.Name;
    }

    public static String bindQuoteFromEndorsement(String quoteId, Date contractCancelDate, String contractCancellationReason) {
        String msgError  = '';
        try {
            List<API_Log__c> lstApiLogs = new List<API_Log__c>();
            List<Quote> currentQuotes = QuoteQueryUtil.fetchQuoteWithPolicy(quoteId);
            if (currentQuotes.isEmpty()) {
                msgError = 'Quote is not exist';
                return msgError;
            }
            Quote quoteUpdate = currentQuotes[0];
            system.debug('11 quoteUpdate -- '+quoteUpdate);
            List<Policy__c> policyUpdates = PolicyQueryUtil.fetchPolicyById(currentQuotes[0].Policy__c);
            if (policyUpdates.isEmpty()) {
                msgError = 'Policy is not exist';
                return msgError;
            }                                   
            Policy__c policyUpdate = policyUpdates[0];
            Opportunity oppty = new Opportunity(Id = quoteUpdate.OpportunityId);
            switch on quoteUpdate.Quote_Type__c {
                when 'Extension' {
                    policyUpdate.Total_Premium__c = quoteUpdate.Total_Premium__c;
                    policyUpdate.Expiration_Date__c = quoteUpdate.ExpirationDate;
                    policyUpdate.Policy_Status__c = 'Bound';
                    //oppty.Expiry_Date__c = policyUpdate.Expiration_Date__c; 
                }
                when 'Midterm Cancellation' {
                    // System.debug('Before update Contract ' +policyUpdate );
                    policyUpdate.Total_Premium__c = quoteUpdate.Total_Premium__c;
                    //policyUpdate.Cancellation_Date__c = quoteUpdate.Endorsement_Effective_Date__c;
                    /* 25/04/2019 - Long Ly - During the Cancellation process the Contract Cancellation date is being updated 
                    before the Quote is Bound. This should not happen and until everything is successful 
                     and the Quote is bound */
                    policyUpdate.Cancellation_Date__c = contractCancelDate;
                    policyUpdate.Cancellation_Reason__c = contractCancellationReason;
                    //End
                    policyUpdate.Policy_Status__c = 'Cancelled';
                    quoteUpdate.Status = 'Bound';
                }
                when 'Flat Cancellation' {
                    policyUpdate.Total_Premium__c = quoteUpdate.Total_Premium__c;
                    policyUpdate.Cancellation_Date__c = contractCancelDate;
                    policyUpdate.Cancellation_Reason__c = contractCancellationReason;
                    //Commented for US-46068 update quote status to Quoted for AQ
                    //policyUpdate.Policy_Status__c = 'Cancelled';
                    
                    if(policyUpdate.RecordType.Name != GlobalVariables.AQUEOUS){
                       quoteUpdate.Status = 'Bound';
                       policyUpdate.Policy_Status__c = 'Cancelled';                     
                    }else{
                        API_Log__c objApiLog = new API_Log__c();
                        objApiLog = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', quoteUpdate, 'PreFinalizeSync'); // PreSync before Finalize
                        if(objApiLog != null){
                            lstApiLogs.add(objApiLog);
                        }

                        FinalizeServiceHandler_Common.ResultResponseWrapper returnStatus = FinalizeService.generateFinalizeDocument(quoteUpdate.Azure_ID__c,quoteUpdate.Id);
                        if(returnStatus.errors.isEmpty() && returnStatus.status == 'Quoted'){
                            quoteUpdate.Status = 'Quoted';
                            quoteUpdate.Rating_Status__c = 'Clear';
                        }
                    }
                }
               /* when 'Flat Cancellation' {
                    policyUpdate.Total_Premium__c = quoteUpdate.Total_Premium__c;
                    // policyUpdate.Cancellation_Date__c = quoteUpdate.Endorsement_Effective_Date__c;
                    /* 25/04/2019 - Long Ly - During the Cancellation process the Contract Cancellation date is being updated 
                    before the Quote is Bound. This should not happen and until everything is successful 
                     and the Quote is bound 
                    policyUpdate.Cancellation_Date__c = contractCancelDate;
                    policyUpdate.Cancellation_Reason__c = contractCancellationReason;
                    //End
                    policyUpdate.Policy_Status__c = 'Cancelled';
                    quoteUpdate.Status = 'Bound';
                }*/
                when 'Reinstatement' {
                    policyUpdate.Total_Premium__c = quoteUpdate.Total_Premium__c;
                    // policyUpdate.Reinstatement_Date__c = quoteUpdate.Endorsement_Effective_Date__c;
                    quoteUpdate.Status = 'Bound';
                    if(policyUpdate.RecordType.Name == GlobalVariables.AQUEOUS){
                        policyUpdate.Cancellation_Date__c = null;
                        policyUpdate.Cancellation_Reason__c = null;
                    }
                    if( policyUpdate.RecordType.Name == GlobalVariables.CELERITY ){
                        policyUpdate.Expiration_Date__c = quoteUpdate.ExpirationDate;
                    }
                    if (policyUpdate.Policy_Status__c == 'Cancelled') policyUpdate.Policy_Status__c = 'Bound';
                }
                when 'Broker on Record Change'{
                    if( policyUpdate.RecordType.Name == GlobalVariables.CELERITY ){
                        quoteUpdate.Status = 'Bound';
                    }
                }
            }
            if(!lstApiLogs.isEmpty()){
                insert lstApiLogs;
            }
            System.debug('Before update Contract ' +policyUpdate );
            update policyUpdate;
            quoteUpdate.Endorsement_Quote_Bound_Date__c = Datetime.now();
            update quoteUpdate;
            system.debug('11 quoteUpdate UPD -- '+quoteUpdate);

            /* Long Ly - 06/28/2019 - During the Bind Process when we update the Total Premium on the Contract 
            we should also update the Opportunity Amount to the new Quote Total Premium as well. 
            This should be the same for both New Business Quotes and Endorsement Quotes
            */
            oppty.Policy__c = policyUpdate.Id;
            oppty.Amount = policyUpdate.Total_Premium__c;
            update oppty;
            //End

            // close all the Quotes belong to  that Opportunity which has Quote Status != 'Bound'
            //already moved to Quote trigger
            if (quoteUpdate.Status == 'Bound') {
                updateQuoteListAfterBind(quoteUpdate);
            }
        } catch (Exception ex) {
            msgError = CommonUtil.getExceptionMessage(ex);
            //system.debug('@@@ bindQuoteFromEndorsement.ex= ' + ex.getMessage() + ', location: ' + ex.getStackTraceString());
        }

        return msgError;
    }

    /*************************************************
    * Method Name: bindQuoteEndorsement
    * Author: Quang Pham
    * Date: 25-Apr-2019
    * Params: quoteId Quote Id
    * Params: contractCancelDate Cancellation Date
    * Params: contractCancellationReason Cancellation Reason
    * Return:  if error is return message error else return blank
    * Exceptions:
    * Revision:
    *************************************************/
    public static String bindQuoteForEndorsement(String quoteId, Date contractCancelDate, String contractCancellationReason) {
        String msgError = '';
        try{
            // Bind Quote           
            msgError = bindQuoteFromEndorsement(quoteId, contractCancelDate, contractCancellationReason);
            
            if(String.isNotBlank(msgError)) {
                Quote quoteUpdate = QuoteQueryUtil.fetchQuoteById(quoteId)[0];
                quoteUpdate.Status = 'Closed';
                update quoteUpdate;
                return msgError;
            }

            compareQuoteEndorsment(quoteId);
        } catch(Exception ex){
            ErrorLogsUtilityHelper.logError(ex, 'BindServiceHandler_Common.bindQuoteForEndorsement', CommonUtil.getExceptionMessage(ex), '', 'AQ_Exceptions', '', String.valueOf(ex.getLineNumber()));
            msgError = CommonUtil.getExceptionMessage(ex);
        }

        return msgError;
    }

    /*************************************************
    * Method Name: compareQuoteEndorsment
    * Author: Quang Pham
    * Date: 25-Apr-2019
    * Params: quoteId Quote Id
    * Return:
    * Exceptions:
    * Revision:
    *************************************************/
    @future(callout=true)
    private static void compareQuoteEndorsment(String quoteId) {
        QuoteEndorsementChangeSummaryCtrl.getQuoteEndorsementChangeSummary(quoteId, true);
    }
    
    @AuraEnabled
    public static string getPreBindDetails(String quoteId) {
        PreBindChecks preBindChecks = new PreBindChecks();
        List<Quote> quoteList = QuoteQueryUtil.fetchQuoteById(quoteId);
        List<Rating_Modifiers__c> ratingMod = new List<Rating_Modifiers__c>(); 
        List<Subjectivity__c> subjectivity = SubjectivityQueryUtil.fetchSubjectivitiesForQuote(quoteId);
       
        if(!quoteList.isEmpty()){
            Quote quote = quoteList[0];
            //List<Broker_Account__c> brokerAccount = [select Id,Broker_Contact__r.AccountId from Broker_Account__c where Opportunity__c =:quote.OpportunityId LIMIT 1];
            ratingMod = RatingModifierQueryUtil.fetchRatingModifiersByOpportunity(quote.OpportunityId);
            /*
            if(!brokerAccount.isEmpty()){
                List<Account> accList = [select Id,Appointed__c,Name from Account where Id =:brokerAccount[0].Broker_Contact__r.AccountId LIMIT 1];
                if(!accList.isEmpty()){
                    if(accList[0].Appointed__c == False) preBindChecks.brokerAgencyAppointed = true;
                }
            }*/
            if(!subjectivity.isEmpty()){
                for(Subjectivity__c sub :subjectivity){
                    if(sub.Cleared__c != true){
                        preBindChecks.subjectivities = true;
                    }
                }
            }
            
            if(!ratingMod.isEmpty()){
                for(Rating_Modifiers__c rtm : ratingMod){
                    if(rtm.Name == 'Proposal Form Date' && string.isBlank(rtm.Rating_Modifier_Value__c)){
                        preBindChecks.proposalDate = true;
                    }
                }
            }
            
            //For 40578  preBindChecks.sanctionStatus = string.isNotBlank(quote.Account.AQ_Sanction_Status__c) ? quote.Account.AQ_Sanction_Status__c : '';
            //For 40578  preBindChecks.kycStatus = string.isNotBlank(quote.Account.KYC_Status__c) ? quote.Account.KYC_Status__c : '';
            preBindChecks.isSuccess = true;
            system.debug('preBindChecks-->'+preBindChecks);
            return JSON.serialize(preBindChecks);
        }
        preBindChecks.isSuccess = false;
        preBindChecks.errMsg = 'Account does not exist';
        return JSON.serialize(preBindChecks);
    }

    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, String quoteAzureId, String nameApi) {
        string baseUri;
        String urlString = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
        List<String> stringlist = urlString.split('quoteAzureId');
        if(nameApi == 'Bind_Quote_V2') baseUri = stringlist[0] + quoteAzureId + stringlist[1];
        system.debug('baseUrl= ' + baseUri);
        
        Map<String, String> headerParamMap = new Map<String, String>();
        for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
            List<String> headerKeyValue = headerParam.split(':');
            headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
        }
        system.debug('@@@ headerParamMap= ' + headerParamMap);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUri);
        req.setMethod(apiSetting.Method__c);
        req.setTimeout(Integer.valueOf(Label.ApiTimeOut));
        for (String headerParamKey : headerParamMap.keySet()) {
            req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
        }
        system.debug('req-->'+req);
        return req;
    }

    public static Quote quoteDetails(String quoteId){

        return [ select id, Account.CEL_Sanction_Status__c from quote where id=:quoteId];
        
    }

    public class PreBindChecks{
      @AuraEnabled public Boolean brokerAgencyAppointed  { get; set; }
      //@AuraEnabled string sanctionStatus   { get; set; }
      //@AuraEnabled string kycStatus  { get; set; }
      @AuraEnabled public Boolean subjectivities  { get; set; }
      @AuraEnabled public Boolean proposalDate { get; set; }
      @AuraEnabled public Account brokerAgency { get; set; }
      @AuraEnabled public Boolean isSuccess  { get; set; }
      @AuraEnabled public string errMsg  { get; set; }
        public PreBindChecks(){
            this.brokerAgencyAppointed = false;
            //this.sanctionStatus = '';
            this.brokerAgency = new Account();
            //this.kycStatus = '';
            this.subjectivities = false;
            this.proposalDate = false;
            this.isSuccess = false;
            this.errMsg = '';
        }
    }

    public class InitObject {
        @AuraEnabled public List<String> payplanPicklist { get; set; }
        @AuraEnabled public String currentPayplan { get; set; }
        @AuraEnabled public Opportunity opptRec { get; set; }
        @AuraEnabled public String brokerName { get; set; }
        @AuraEnabled public Boolean showBindOptions {get; set;}
        public InitObject() {
            this.payplanPicklist = null;
            this.currentPayplan = null;
            this.opptRec = new Opportunity();
            this.brokerName = null;
            this.showBindOptions = false;
        }
    }

    public class InComingRequestOFAC {
        public String name {get;set;}
        public String street {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String postalCode {get;set;}
        public String countryCode {get;set;}
        public String county {get;set;} 
        public String accountId {get;set;}
        public Boolean isAccount {get;set;}
        public String LicenseId {get;set;}
        public Decimal FEINNumber {get;set;}         
        
        public InComingRequestOFAC() {            
            name = '';
            street = '';
            city = '';
            state = '';
            postalCode = '';
            countryCode = '';
            county = ''; 
            accountId = '';
            isAccount = false;  
            FEINNumber = 0;
            LicenseId = '';          
        }

        //Contact
        public InComingRequestOFAC(Contact con) {            
            this.name           = con.Name;
            this.street         = con.MailingStreet;
            this.city           = con.MailingCity;
            this.state          = con.MailingState;
            this.postalCode     = con.MailingPostalCode;
            this.countryCode    = con.MailingCountryCode;
            this.county         = con.Mailing_County__c;
            this.accountId      = con.AccountId;
            this.isAccount      = false;            
            this.LicenseId      = con.Home_License_no__c;
        }

        //Account
        public InComingRequestOFAC(Account acc) {            
            this.name           = acc.Name;
            this.street         = acc.BillingStreet;
            this.city           = acc.BillingCity;
            this.state          = acc.BillingState;
            this.postalCode     = acc.BillingPostalCode;
            this.countryCode    = acc.BillingCountryCode;
            this.county         = acc.Billing_County__c;
            this.accountId      = acc.Id;
            this.isAccount      = true;                        
            this.FEINNumber     = acc.FEIN__c;
        }
    }
    
    public class ResponseWrapper {
        public String status {get;set;}
        public String message {get;set;}
        public String data {get;set;}
    }
        
}