/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 10-06-2022
 * @last modified by  : Juhi
**/
public class FinalizeServiceHandler_Common {
    private static final String PCC_PRODUCT_NAME = Label.Product_Name_for_PCC;

    public static List<ReferralReasonWrapper> getReferralReasons(String quoteId){
        List<ReferralReasonWrapper> referralReasonQuoWrapper = new List<ReferralReasonWrapper>();
        List<Referral_Reason__c> referralReasonQuo = new List<Referral_Reason__c>();
        try{
            referralReasonQuo = [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,Approval_Rejected_Date__c,Approver_Level__c,Approved_By__c,
                                 Quote_Option__c,Entity_Path__c,Reason__c,Reason_Type__c,Status__c,Approved_By__r.Name,Is_Auto_Approved__c,Option_Type__c,
                                 Option_Limit__c,Quote_Option__r.Limit__c,Option_Id__c,Quote_Option__r.Selected__c,Quote_Option_Limit__c,Quote__r.Product_Name__c From Referral_Reason__c 
                                 Where Is_Auto_Approved__c = false AND
                                 //Quote_Option__r.Selected__c = true AND//Approval_Status__c != 'Approved' AND 
                                 Quote__c=:quoteId];   
            for(Referral_Reason__c referralReason : referralReasonQuo) {
                ReferralReasonWrapper objWrapper = new ReferralReasonWrapper(referralReason);
                if(referralReason.Quote__r.Product_Name__c == 'Professional Indemnity'){
                    objWrapper.QuoteOptionLimit = referralReason.Quote_Option_Limit__c;
                }
                referralReasonQuoWrapper.add(objWrapper);
            }
        }catch(Exception ex){
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));
        }
        return referralReasonQuoWrapper;     
    }

    public static ResultResponse finalizeQuote(String quoteId) {
        ResultResponse result = new ResultResponse();
        List<API_Log__c> lstApiLogs = new List<API_Log__c>();
        Boolean isQuoteUpdated = false;
        try {            
            Quote currentQuote = [SELECT Id,Product_Name__c, Status,Rating_Status__c,Opportunity.Source__c, Opportunity.OwnerId, Opportunity.LeadSource,
                                  Opportunity.RecordType.Name,Azure_Id__c, Account.AQ_Sanction_Status__c,Account.KYC_Status__c,Quote_Type__c
                                  FROM Quote WHERE Id = :quoteId][0];  
                                  
            String quoteOppRecordType = currentQuote.Opportunity.RecordType.Name;
            system.debug('==debug==' + currentQuote);
            // Can't finalize a quote that doesn't have rating status
            if (String.isBlank(currentQuote.Rating_Status__c)) {
                result.errors.add('Rating status is not available');
                result.data = currentQuote;
                return result;
            }
            // Can't finalize a quote that has already finalized
            if (currentQuote.Status == 'Quoted' || currentQuote.Status == 'Closed' ||
                currentQuote.Status == 'Referred' || currentQuote.Status == 'Bound' ||  
                currentQuote.Status == 'Bound Pending') {
                    
                    result.errors.add(Label.QUOTE_EXIST_RATED_TO_FINALIZE_MSG);
                    result.data = currentQuote;
                    
                    return result;
                }
            
            // Can't finalize a quote not yet Rated
            if (currentQuote.Status != 'Rated') {
                result.errors.add(Label.QUOTE_REQUIRES_RATED_TO_FINALIZE_MSG);
                result.data = currentQuote;
                return result;
            }
            
            if(quoteOppRecordType == 'Aqueous'){
                Integer referralsCount = 0;
                List<Referral_Reason__c> referralReasonQuo = [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,
                                                              Approval_Rejected_Date__c,Approver_Level__c,Approved_By__c,Option_Id__c,
                                                              Entity_Path__c,Reason__c,Reason_Type__c,Status__c,Approved_By__r.Name,
                                                              Quote_Option__c,Quote_Option__r.Selected__c,Option_Type__c,Option_Limit__c 
                                                              From Referral_Reason__c 
                                                              Where Approval_Status__c != 'Approved' 
                                                              AND Approval_Status__c != 'Rejected' 
                                                              //AND Quote_Option__r.Selected__c = true
                                                              AND Quote__c=:quoteId Order By Approval_Level_Required__c ASC];                
                
                if(!referralReasonQuo.isEmpty()){
                    String commentsWithReasons =  'REFERRAL REASONS :-' + '\n';   
                    for(Referral_Reason__c reason : referralReasonQuo){
                        if(reason.Quote_Option__r.Selected__c || String.isBlank(reason.Quote_Option__c)){
                            if(reason.Reason__c != null){
                                referralsCount++;
                                commentsWithReasons = commentsWithReasons + '◼ ' + reason.Reason__c +  '\n';
                                commentsWithReasons = commentsWithReasons + '◆ APPROVAL LEVEL REQUIRED : ' + reason.Approval_Level_Required__c +  '\n';
                                commentsWithReasons = commentsWithReasons + '-----------------------------------------------------'+'\n';
                            }
                        }                        
                    }
                    if(referralsCount > 0){
                        String lowestApprover = getLowestApprover(referralReasonQuo); 
                        if(String.isNotBlank(lowestApprover)){
                            Approval.ProcessSubmitRequest appReq = new Approval.ProcessSubmitRequest();                    
                            appReq.setObjectId(quoteId); 
                            
                            Switch on lowestApprover{
                                When '3' {
                                    String comments = 'Underwriting Referral AQ Level 3 '+ '\n' + '\n' + commentsWithReasons;
                                    appReq.setComments(comments);
                                    //appReq.setComments('Underwriting Referral AQ Level 3');
                                    appReq.setProcessDefinitionNameOrId('Level_3_Approval_process_AQ');
                                }
                                When '2' {
                                    String comments = 'Underwriting Referral AQ Level 2 '+ '\n' + '\n' + commentsWithReasons;
                                    appReq.setComments(comments);
                                    //appReq.setComments('Underwriting Referral AQ Level 2');
                                    appReq.setProcessDefinitionNameOrId('Level_2_Approval_process_AQ');
                                }
                                When '1' {
                                    String comments = 'Underwriting Referral AQ Level 1 '+ '\n' + '\n' + commentsWithReasons;
                                    //51079
                                    if(comments.length() < 4000){
                                        System.debug('comments.length()--->'+comments.length());
                                        appReq.setComments(comments);
                                    }
                                    //appReq.setComments(comments);
                                    //appReq.setComments('Underwriting Referral AQ Level 1 '+ '\n' + '\n' + 'By approving/rejecting this quote you concurred this approval/rejection with the Company');
                                    appReq.setProcessDefinitionNameOrId('Level_1_Approval_process_AQ');
                                }
                            }
                            Approval.process(appReq);
                            System.debug('In Approval process AQ-- '+referralReasonQuo);
                            
                            result.errors.add('Quote sent for Referral');
                            result.data = currentQuote;
                            return result;
                        }
                        result.errors.add('Error during Referral Process, check ' +'\'approval level required\''+ ' in the reasons');
                        result.data = currentQuote;
                        return result;    
                    }else{
                        currentQuote.Rating_Status__c = 'Clear';
                        isQuoteUpdated = true;
                    }                    
                }else{
                    currentQuote.Rating_Status__c = 'Clear';
                    isQuoteUpdated = true;
                }
            }
            if(quoteOppRecordType == 'Aqueous'){
                List<Broker_Account__c> brokerAccount = [select Id,Broker_Contact__r.AccountId from Broker_Account__c where Opportunity__c =:currentQuote.OpportunityId LIMIT 1];
                if(!brokerAccount.isEmpty()){
                List<Account> accList = [select Id,Appointed__c,Name from Account where Id =:brokerAccount[0].Broker_Contact__r.AccountId LIMIT 1];
                if(!accList.isEmpty()){
                    if(accList[0].Appointed__c == False) {
                        result.errors.add('Broker Agency is not Appointed');
                        result.data = currentQuote;
                        return result;
                    }
                }
            }
            }
            
            // Logic to finalize a quote:
            // - If rating status = 'Refer' --> call approval process "Quote Referral Process"
            // - If rating status = 'Ineligible' --> update quote status to 'Closed'
            // - If rating status = 'Clear' --> update quote status to 'Quoted'
            system.debug('RATING STATUS-->'+currentQuote.Rating_Status__c);
            if (currentQuote.Rating_Status__c == 'Refer' && quoteOppRecordType != 'Aqueous') {
                // Call approval process
                // This approval process will update quote status to 'Referred'
                String oppRecordType = currentQuote.Opportunity.RecordType.Name; 
                List<Approval.ProcessSubmitRequest> requestList = new List<Approval.ProcessSubmitRequest>();
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Underwriting Referral');
                req1.setObjectId(currentQuote.Id);
                List<Product_Setting__mdt> prodSettings = [Select Label, DeveloperName, MasterLabel, Approval_Processes__c
                                                           From Product_Setting__mdt
                                                           Where Record_Type__c = :oppRecordType And Active__c = true];
                
                
                string approvalProcessName = '';                                                                                                       
                for(Product_Setting__mdt prodConfig : prodSettings){
                if(currentQuote.Product_Name__c.contains(prodConfig.Label.removeEnd('Standalone')) && prodConfig.Approval_Processes__c != null && prodConfig.Approval_Processes__c != ''){
                        approvalProcessName = prodConfig.Approval_Processes__c;
                    }
                }
                req1.setProcessDefinitionNameOrId(approvalProcessName);
                requestList.add(req1);
                Approval.process(req1);
                
            } 
            else if (currentQuote.Rating_Status__c == 'Ineligible') {
                currentQuote.Status = 'Closed';
                currentQuote.Closed_Reason__c = 'Declination UW Reasons';
                isQuoteUpdated = true;
                
            } 
            else if (currentQuote.Rating_Status__c == 'Clear'){
                system.debug('Source->'+currentQuote.Opportunity.Source__c  );
                if(currentQuote.Product_Name__c != 'Professional Indemnity'){
                   if(currentQuote.Opportunity.Source__c !='SME'){
                        if(quoteOppRecordType != 'Aqueous'){
                            API_Log__c objApiLog = new API_Log__c();
                           // objApiLog = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', currentQuote, 'FinalizeQuote'); // Added by Maeran for US:51810 as part of PreSync before Finalize  
                            if(objApiLog != null){
                                lstApiLogs.add(objApiLog);        
                            }       
                        }
                        ResultResponseWrapper returnStatus = generateFinalizeDocument(currentQuote.Azure_ID__c,currentQuote.Id);
                        system.debug('returnStatus-->'+returnStatus);

                        if(returnStatus.errors.isEmpty() && returnStatus.status == 'Quoted'){
                            currentQuote.Status = 'Quoted';
                            isQuoteUpdated = true;
                        }
                        else{
                            //Gonna Edit on 12-08-21!!! AZ!!!
                            result.errors.add('Finalized and Document generation Failed');
                            return result;
                        }
                    }
                   }
            }
            else if(currentQuote.Rating_Status__c == 'Refer' && quoteOppRecordType == 'Aqueous'){
                result.errors.add('Quote Rating Status must be clear to Finalize.');
                result.data = currentQuote;
                return result;
            }
            
            if( currentQuote.Opportunity.Source__c =='SME' && currentQuote.Rating_Status__c == 'Clear'){
                //GenerateQuoteDocumentController.generateDocId(currentQuote.Id,'quote');
                if(currentQuote.Opportunity.LeadSource != 'Shopping X'){
                    GenerateQuoteDocumentController.generateDocId(currentQuote.Id,'quote');
                }
                system.debug('In finalize --> ');
                //Update Account Clearance on Submission - BUG  57415 (JUHI)
                 List<Opportunity> oplist = [Select id, Account_Clearance__c from Opportunity where Id=: currentQuote.OpportunityId ];
                 List<Opportunity> updatedOpp = new List<Opportunity>();
                        if(!oplist.isEmpty()){
                           for(Opportunity op : oplist){
                            if(op.Account_Clearance__c != 'Cleared') {
                                op.Account_Clearance__c = 'Cleared';
                                updatedOpp.add(op);
                          } 
                        } 
                            if(!updatedOpp.isEmpty())  update updatedOpp;
                 }
                currentQuote.Status = 'Quoted';
                isQuoteUpdated = true;
            } 
            //System.debug(currentQuote);
            if(isQuoteUpdated) update currentQuote;
            if(!lstApiLogs.isEmpty()){
                insert lstApiLogs;
            }
            
            if(currentQuote.Rating_Status__c != 'Ineligible' && quoteOppRecordType != 'Aqueous' && currentQuote.Product_Name__c != PCC_PRODUCT_NAME){
                QuoteEndorsementChangeSummaryCtrl.getQuoteEndorsementChangeSummary(currentQuote.Id,true);
            }            
            
            result.data = currentQuote;
            result.isSuccess = true;
        }catch (NullPointerException ex){            
            System.debug('NullException-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add(ex.getMessage());
        } catch (Exception ex) {
            System.debug('Exception-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add(ex.getMessage());
            result.data = null;
        }
        system.debug('RESULT 264--> '+result);
        return result;        
    }

    public static String getLowestApprover(List<Referral_Reason__c> referralReasonList){
        List<Referral_Reason__c> nu = referralReasonList;
        
        List<String> approverLevelList = new List<String>{'3','2','1','0'}; //Since these are the only approvers that can approve
            String lowestApprover = '';       
        for(String approverLevel : approverLevelList ){
            Integer i=0;
            for(Referral_Reason__c refReason : referralReasonList){
                String approvalLevelReq = refReason.Approval_Level_Required__c;                
                i++;
                if(approvalLevelReq.contains('0')){
                    approvalLevelReq = approvalLevelReq.replace('0','1');
                }
                System.debug('hiii-- '+ approvalLevelReq );           
                
                if( approvalLevelReq.contains(approverLevel) ) {
                    System.debug('hiii--ss '+ approvalLevelReq );               
                }else{
                    break;
                }
                if(i == referralReasonList.size()){
                    if(lowestApprover != ''){
                        if(Integer.valueOf(approverLevel) > Integer.valueOf(lowestApprover)){
                            lowestApprover = approverLevel;  
                            System.debug('lowestApprover--'+lowestApprover);
                        }  
                    }else{
                        lowestApprover = approverLevel;
                    }
                }
            }            
            System.debug('x--'+ approverLevel);            
        }
        System.debug('lowestApprover--'+ lowestApprover );
        return lowestApprover;
    }

    Public static ResultResponseWrapper generateFinalizeDocument(string quoteAzureId,string quoteId){
        ResultResponseWrapper result = new ResultResponseWrapper();
        API_Configuration__mdt apiSettingFinalizeQuote = CommonUtil.getAPIconfiguration('Finalize_Quote_Document_V2');
        system.debug('api --'+apiSettingFinalizeQuote);
        HttpRequest request = new HttpRequest();
        HttpResponse returnResponse = new HttpResponse();
        if (apiSettingFinalizeQuote == null){
            result.errors.add('API Configuration Finalize quote is missing');
        }
        try{
            request = getHttpRequest(apiSettingFinalizeQuote, quoteAzureId, 'Finalize_Quote_Document_V2');
            Http http = new Http();
            request.setHeader('Content-Length', '4096');
            request.setBody('{}');
            returnResponse = http.send(request);
            string resp =  returnResponse.getBody();  
            system.debug('RES--'+resp);  
            if (returnResponse.getStatusCode() == 200) {
                IncomingFinaliseQuoteResponse finaliseQuoteResponse = (IncomingFinaliseQuoteResponse) JSON.deserialize(resp, IncomingFinaliseQuoteResponse.class);
                
                List<Document_Revision__c> docRevisionList = new List<Document_Revision__c>();
                string recordType =  [SELECT Id, Name, SobjectType FROM RecordType where SobjectType = 'Document_Revision__c' And Name ='Quote'].Id;
                
                DateTime dt = DateTime.now();
                String GenerateDate = dt.format('yyyy/MM/dd hh:mm:ss');
                Quote quote = [Select Id, Product_Name__c, Status,Rating_Status__c,Quote_Type__c,Master_Binder__r.Name
                FROM Quote WHERE Id = :quoteId][0]; 
                if(quote != null){
                    if(quote.Product_Name__c == 'Professional Indemnity'){
                        if(quote.Quote_Type__c == 'New Business' || quote.Quote_Type__c == 'Renewal'
                        || quote.Quote_Type__c == 'Full Amendment' || quote.Quote_Type__c == 'Coverage Amendment'
                        || quote.Quote_Type__c == 'Policy Duration Change'){
                            for(Documents doc : finaliseQuoteResponse.data.Documents){
                                Document_Revision__c newDoc = new Document_Revision__c();
                                if(string.isNotBlank(doc.Id) && String.isNotBlank(doc.GeneratedDate)){
                                    newDoc.Document_Azure_Id__c = doc.Id;
                                    newDoc.RecordTypeId  = recordType;
                                    newDoc.Quote_Id__c = quoteId;  
                                    newDoc.Document_Type__c = doc.Type;
                                    newDoc.Name = doc.Type + '_'+ String.valueOf(Datetime.now());
                                    if(quote.Master_Binder__r.Name != null){
                                        newDoc.Binder__c = quote.Master_Binder__r.Name;
                                    }
                                    docRevisionList.add(newDoc);
                                }
                            }
                        }
                    }
                    else{
                        if(quote.Quote_Type__c =='New Business' || quote.Quote_Type__c == 'Renewal'){
                            for(Documents doc : finaliseQuoteResponse.data.Documents){
                                Document_Revision__c newDoc = new Document_Revision__c();
                                if(string.isNotBlank(doc.Id) && String.isnotBlank(doc.GeneratedDate)){
                                    newDoc.Document_Azure_Id__c = doc.Id;
                                    newDoc.RecordTypeId  = recordType;
                                    newDoc.Quote_Id__c = quoteId;  
                                    newDoc.Document_Type__c = 'QuoteProposal';
                                    newDoc.Name = 'QuoteProposal'+' '+GenerateDate ;
                                    docRevisionList.add(newDoc);
                                }
                            }
                        }
                    }
                }

                if(!docRevisionList.isEmpty())
                {
                    insert docRevisionList;  
                }
                result.status = finaliseQuoteResponse.data.status;
                result.isSuccess = true;   
            }             
            else { 
                result.errors.add('Finalized and Document generation Failed');                 
            }
        }
        catch (NullPointerException ex){            
            System.debug('NullException-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add('Finalized and Document generation Failed');
            result.errors.add(CommonUtil.getExceptionMessage(ex));
        }
        catch(Exception ex){
            System.debug('Exception-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add('Finalized and Document generation Failed');
            result.errors.add(CommonUtil.getExceptionMessage(ex));
        }
        
        ApiUtil.logAPICall(request,returnResponse,'Finalize Quote Document V2 Callout','Finalize_Quote_Document_V2', apiSettingFinalizeQuote.HeaderParams__c, 'Outbound');
        system.debug('RESULT 391--> '+result);
        return result;
    }

    // This method is called in Queuable class when the celrity Quote is referred and approved
    // BUG 50158
    public static Quote finalizeAndGenerateDoc(Quote quote){
        System.debug('####InsideSyncMethod');
        API_Log__c objApiLog = new API_Log__c();
        //objApiLog = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', quote, 'PreFinalizeSync'); // PreSync before Finalize  
        Quote q = [Select id,Status from Quote where id=:quote.id];

        FinalizeServiceHandler_Common.ResultResponseWrapper returnStatus = generateFinalizeDocument(quote.Azure_ID__c,quote.Id);
        if(returnStatus.errors.isEmpty() && returnStatus.status == 'Quoted'){
            q.Status = 'Quoted';
            update q;
        }
        system.debug('Finalized --> '+quote);
        if(objApiLog != null){
            insert objApiLog;
        }
        return q;
    }

    public static Boolean getQuoteDetails(Id quoteId){
        System.debug('>>>quoteId>>>'+quoteId);
        Quote lstOfQuote = [Select Id, Name, Approval_Status__c from Quote where Id =: quoteId];
        
        if(lstOfQuote.Approval_Status__c == 'Approved' || lstOfQuote.Approval_Status__c == 'Rejected'){
            return false;
        }
        else if (lstOfQuote.Approval_Status__c == 'Approval Pending') {
            ProcessInstance processInst = [SELECT Id,TargetObjectid, Status,(select id,actor.name,actor.id from Workitems),(SELECT Id, StepStatus, Comments,Actor.Name FROM Steps) FROM ProcessInstance where TargetObjectId =: quoteId AND Status='Pending' Limit 1];
            for(ProcessInstanceWorkitem item : processInst.workItems) {
                System.debug('>>>ActorId>>>'+item.ActorId);
                if(UserInfo.getUserId() == item.ActorId) {
                    return false;
                }
                else {
                    return true;
                }
            }
        }
        return false;
    }

    public static string quoteDetails(string quoteId){
        PreFinalizeChecks preCheckWrapper = new PreFinalizeChecks();
        Quote quote = [SELECT Id,OpportunityId,Product_Name__c,Commission_percentage__c,MGA_Commission__c,Binder__c,Policy_Wording__c,
                       Territorial_Limits__c,Jurisdiction_Limits__c,Limit_Basis__c,Excess_Basis__c,AccountId, Account.Kyc_Status__c, 
                       Account.AQ_Sanction_Status__c,Layer__c, (Select Insurer__c, Insurer_Policy_Number__c from Insurer_Layer_Limit__r),Effective_Date__c,Effective_Date_45__c
                       FROM Quote WHERE Id = :quoteId][0];
        
        if(quote != null){
            Boolean isSanctionNotPass = False;
            set<string> accountIds = new set<string>();
            List<Additional_Insured__c> addInsured = [select Id,Additional_Insured_Account__c,Submission__c 
                                                      from Additional_Insured__c where Submission__c =: quote.OpportunityId];  
            
            for(Additional_Insured__c addIn: addInsured)  {
                accountIds.add(addIn.Additional_Insured_Account__c);
            }  
            
            List<Account> accList = [select Id,AQ_Sanction_Status__c from Account where Id IN:accountIds];  
            for(Account acc: acclist){
                if(acc.AQ_Sanction_Status__c != 'Pass' && acc.AQ_Sanction_Status__c != 'Cleared'){
                    isSanctionNotPass = true;
                }
            }
            
            preCheckWrapper.Layer = string.isNotBlank(quote.Layer__c) ? quote.Layer__c : '';
            preCheckWrapper.MGA_Commission = quote.MGA_Commission__c != null ? quote.MGA_Commission__c : null;
            preCheckWrapper.Binder = string.isNotBlank(quote.Binder__c) ? quote.Binder__c : '';
            preCheckWrapper.Territorial_Limits = string.isNotBlank(quote.Territorial_Limits__c) ? quote.Territorial_Limits__c : '';
            preCheckWrapper.Excess_Basis = string.isNotBlank(quote.Excess_Basis__c) ? quote.Excess_Basis__c: '';
            preCheckWrapper.Policy_Wording = string.isNotBlank(quote.Policy_Wording__c) ? quote.Policy_Wording__c : '';
            preCheckWrapper.Jurisdiction_Limits = string.isNotBlank(quote.Policy_Wording__c) ? quote.Policy_Wording__c: '';
            preCheckWrapper.Commission_percentage = quote.Commission_percentage__c != null ? quote.Commission_percentage__c: null;
            preCheckWrapper.Limit_Basis = string.isNotBlank(quote.Limit_Basis__c) ? quote.Limit_Basis__c : '';
            preCheckWrapper.Insurer_Layer_Limit = quote.Insurer_Layer_Limit__r; 
            preCheckWrapper.InsurerAccountSanction = isSanctionNotPass;
            preCheckWrapper.Effective_Date = quote.Effective_Date__c;//mary
            preCheckWrapper.EffectiveDate_45 = quote.Effective_Date_45__c;//mary
            
            AccountFields accountWrapper = new AccountFields();
            accountWrapper.KYC_Status = string.isNotBlank(quote.Account.KYC_Status__c) ? quote.Account.KYC_Status__c: '';
            accountWrapper.Sanction_Status = string.isNotBlank(quote.Account.AQ_Sanction_Status__c) ? quote.Account.AQ_Sanction_Status__c: '';
            
            preCheckWrapper.Account = accountWrapper;
            system.debug('preCheckWrapper-->'+JSON.serialize(preCheckWrapper));
        }
        
        return JSON.serialize(preCheckWrapper);
    }

    public static Boolean checkPartFixedEndorsement(ID quoteId){
        try {
            List<CoveragesLineItem__c> quoteCLIList = [SELECT Id, Name, CoverageLineItemType__c, Type__c, Option_Value_Default__c,
                                                       Form_Number__c, Limits_Deductibles__r.Name, Coverage__r.Name, Quote__c 
                                                       FROM CoveragesLineItem__c 
                                                       WHERE Quote__c=:quoteId
                                                       AND (CoverageLineItemType__c='Deductible Option' OR CoverageLineItemType__c='Limit Option') 
                                                       AND Type__c='Endorsement Option'
                                                       AND Limits_Deductibles__c != null 
                                                       AND Coverage__c != null];
            for(CoveragesLineItem__c cli:quoteCLIList){
                if(String.isBlank(cli.Option_Value_Default__c)){
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<PicklistOption> handleCloseReasons(string quoteId){
        List<PicklistOption> lstResult = CommonUtil.getPicklistValueFromObjectField('Quote', 'Closed_Reason__c');
        List<PicklistOption> returnPicklist = new List<PicklistOption>();
        Quote quote = [select Id,Product_Name__c,Opportunity.RecordType.Name from Quote where Id =: quoteId];
        
        if(quote != null){
            for(Integer i = 0; i < lstResult.size(); i++){
                if(quote.Opportunity.RecordType.Name == 'Celerity'){
                    if(lstResult[i].value != 'Did Not Quote' && lstResult[i].value != 'Not Taken Up' && lstResult[i].value != 'Rejected'&& lstResult[i].value != 'Expired' && lstResult[i].value != 'Approval Rejected'){
                        returnPicklist.add(new PicklistOption(lstResult[i].value, lstResult[i].Label)); 
                    }
                }else{
                    if(lstResult[i].value != 'Declination Attachment Point'   && lstResult[i].value != 'Declination Class of Business' && lstResult[i].value != 'Declination Capacity Committed' && lstResult[i].value != 'Declination CAT Exposure' &&
                       lstResult[i].value != 'Declination Financial Condition' && lstResult[i].value != 'Declination Inadequate U/W Info' && lstResult[i].value != 'Declination Lack of Time before X-Date' &&
                       lstResult[i].value != 'Declination Location of Insured' && lstResult[i].value != 'Declination Loss Experience' && lstResult[i].value != 'Declination New Venture' && lstResult[i].value != 'Declination Not Cleared' &&
                       lstResult[i].value != 'Declination Broker Not Licensed' && lstResult[i].value != 'Declination Other Broker' && lstResult[i].value != 'Declination Pending US IPO' && lstResult[i].value != 'Declination Risk Mgmt Rating' &&
                       lstResult[i].value != 'Declination Treaty Exclusion' && lstResult[i].value != 'Approval Rejected'){
                           returnPicklist.add(new PicklistOption(lstResult[i].value, lstResult[i].Label)); 
                       }
                }
                
            }            
        }
        
        return returnPicklist;
    }

    public static HttpRequest getHttpRequest(API_Configuration__mdt apiSetting, String quoteAzureId, String nameApi) {
        string baseUri;
        String urlString = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
        List<String> stringlist = urlString.split('quoteAzureId');
        if(nameApi == 'Finalize_Quote_Document_V2') baseUri = stringlist[0] + quoteAzureId + stringlist[1];
        
        Map<String, String> headerParamMap = new Map<String, String>();
        for (String headerParam : apiSetting.HeaderParams__c.split(';')) {
            List<String> headerKeyValue = headerParam.split(':');
            headerParamMap.put(headerKeyValue[0], headerKeyValue[1]);
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUri);
        req.setMethod(apiSetting.Method__c);
        req.setTimeout(Integer.valueOf(Label.ApiTimeOut));
        for (String headerParamKey : headerParamMap.keySet()) {
            req.setHeader(headerParamKey, headerParamMap.get(headerParamKey));
        }
        return req;
    }

    public class ReferralReasonWrapper{
        @AuraEnabled public String Id {get; set;}
        @AuraEnabled public String Name {get; set;}
        @AuraEnabled public String ApprovalLevelRequired {get; set;}
        @AuraEnabled public String ApprovalStatus {get; set;}
        @AuraEnabled public Date ApprovalRejectedDate {get; set;}
        @AuraEnabled public String ApproverLevel {get; set;}
        @AuraEnabled public String ApprovedBy {get; set;}
        @AuraEnabled public String Reason {get; set;}
        @AuraEnabled public String EntityPath {get; set;}
        @AuraEnabled public String ReasonType {get; set;}
        @AuraEnabled public Decimal QuoteOptionLimit {get; set;}
        @AuraEnabled public String Status {get; set;}
        public ReferralReasonWrapper() {
        }
        public ReferralReasonWrapper(Referral_Reason__c referralReasonObj) {
            this.Id = referralReasonObj.Id;
            this.Name = referralReasonObj.Name;
            this.ApprovalLevelRequired = referralReasonObj.Approval_Level_Required__c;
            this.ApprovalStatus = referralReasonObj.Approval_Status__c;
            this.ReasonType = referralReasonObj.Reason_Type__c;
            this.ApprovalRejectedDate = referralReasonObj.Approval_Rejected_Date__c;
            this.EntityPath = referralReasonObj.Entity_Path__c;
            this.ApproverLevel = referralReasonObj.Status__c;
            this.ApprovedBy = referralReasonObj.Approved_By__r.Name;
            this.QuoteOptionLimit = referralReasonObj.Quote_Option__r.Limit__c;
            this.Reason = referralReasonObj.Reason__c;
            this.Status = referralReasonObj.Status__c;
        } 
    }

    public class ResultResponseWrapper {
        public Boolean isSuccess;
        public List<String> errors;
        public string status;
        public ResultResponseWrapper(){
            this.errors = new List<String>();
        }
    }

    public class PreFinalizeChecks{
        @AuraEnabled public string Layer  { get; set; }
        @AuraEnabled public Decimal MGA_Commission  { get; set; }
        @AuraEnabled public string Binder { get; set; }
        @AuraEnabled public string Territorial_Limits { get; set; }
        @AuraEnabled public string Excess_Basis  { get; set; }
        @AuraEnabled public AccountFields Account  { get; set; }
        @AuraEnabled public List<Insurer_Layer_Limit__c> Insurer_Layer_Limit  { get; set; }
        @AuraEnabled public string Policy_Wording  { get; set; }
        @AuraEnabled public string Jurisdiction_Limits  { get; set; }
        @AuraEnabled public Decimal Commission_percentage { get; set; }
        @AuraEnabled public string Limit_Basis { get; set; }
        @AuraEnabled public Boolean InsurerAccountSanction { get; set; }
        @AuraEnabled public Date Effective_Date { get; set; }//mary
        @AuraEnabled public Date EffectiveDate_45 { get; set; }//mary
        
    }

    public class AccountFields{
        @AuraEnabled public string KYC_Status  { get; set; }
        @AuraEnabled public string Sanction_Status  { get; set; }
    }

    public class IncomingFinaliseQuoteResponse {
        public String status {get;set;}
        public String message {get;set;}
        public Data data {get;set;}
    }

    public class Data {
        public String quoteId {get;set;}
        public String status {get;set;}
        public List<Documents> Documents {get;set;}
    }

    public class Documents {
        public String Id {get;set;}
        public String Type {get;set;}
        public String GeneratedDate {get;set;}
    }

}