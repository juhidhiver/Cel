public class CloneServiceHandler_AQ {

    public static boolean updateBrokerCommissionOnQuote = false;

    public static NewEndorsementAQController.ResultWrapper fullAmendment(String policyId, String endorsementType, String effDate, String endorsementReason, String endoresementReasonOther){
        NewEndorsementAQController.ResultWrapper resResult = new NewEndorsementAQController.ResultWrapper();
        List<Transactions__c> submissionPoilcyTransaction = [SELECT Name, Id, Policy__c, Submission__c 
                                                             FROM Transactions__c 
                                                             WHERE Policy__c =:policyId 
                                                             AND Submission__r.Transaction_Status__c = 'Active' LIMIT 1];
        if(submissionPoilcyTransaction.isEmpty()){
            resResult.error = 'No Active Submission/Transaction record found on this Policy';
            return resResult;
        }
        
        String oppId = submissionPoilcyTransaction[0].Submission__c;
        Savepoint sp;
        //Clone opportunity
        List<Opportunity> opportunity = CloneQueryUtil.queryOpportunityAQ(oppId);
        system.debug('##  opp -- '+opportunity);
        
        if(opportunity.isEmpty()){
            resResult.oppId = oppId;
            resResult.error = 'No Opportunity found for the current policy';
            return resResult;
        }
        
        Opportunity opp = opportunity[0];
        
        Opportunity clonedOpp = cloneOpportunityDetails(opp);
        clonedOpp.AccountId = opp.AccountId;
        clonedOpp.Parent_Opportunity__c = opp.Id;
        clonedOpp.Transaction_Status__c = 'Inactive';
        clonedOpp.Type = endorsementType; 
        clonedOpp.StageName = 'Qualified';                                                             
        clonedOpp.Azure_ID__c = new GuidUtil().NewGuid();
        clonedOpp.Received_Date__c = opp.Received_Date__c;
        system.debug('## cloned opp -- '+clonedOpp);
        GlobalStaticVar.byPassOpportunityTrigger = true;
        insert clonedOpp;                        
        
        if(clonedOpp.Id == null){
            Database.rollback(sp);
            resResult.oppId = oppId;
            resResult.error = 'Error during cloning opportunity';
            return resResult;
        }
        
        //Clone related objects
        cloneOppRelatedRecords(oppId,clonedOpp);

        //Clone Notes #58474
        List<ContentDocumentLink> newNotes = new List<ContentDocumentLink>();
        List<ContentDocumentLink> items = [select ContentDocument.title , ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: oppId];
        
        if(!items.isEmpty()){
            for(ContentDocumentLink note : items){
                ContentDocumentLink newNote = note.clone(false,true,false,false);
                newNote.LinkedEntityId = clonedOpp.Id;
                newNotes.add(newNote);
            }
        }
        if(!newNotes.isEmpty()){
            insert newNotes;
        }
        
        //Get all the related policies from the parent opp
        Set<Id> policyIds = new Set<Id>();
        for(Transactions__c policyIdsOnSubmission:  [SELECT Name, Id, Policy__c, Submission__c 
                                                     FROM Transactions__c 
                                                     WHERE Submission__c =:oppId]){
                                                         if(policyIdsOnSubmission.Policy__c != null){
                                                             policyIds.add(policyIdsOnSubmission.Policy__c);
                                                         }
                                                     }
            
        //Create transaction object records for the new cloned opp and all policy
        List<Transactions__c> clonedOppTransactionRecords = new List<Transactions__c>();
        for(Id polId: policyIds){
            Transactions__c transRec = new Transactions__c();
            transRec.Submission__c = clonedOpp.Id;
            transRec.Policy__c = polId;
            clonedOppTransactionRecords.add(transRec);
        }
        
        if(!clonedOppTransactionRecords.isEmpty()){
            insert clonedOppTransactionRecords;
        }
        
        //Get all the quotes from the policies
        Map<String,List<Quote>> policyIdToQuoteListMap = new Map<String,List<Quote>>();
        List<Quote> quoteListFromPolicy = CloneQueryUtil.queryQuoteAQ(policyIds);
        
        //Create a Map of Policy ID & related quotes
        for(Quote quo: quoteListFromPolicy){
            String polID = quo.Policy__c;
            if(policyIdToQuoteListMap.containsKey(polID)){
                policyIdToQuoteListMap.get(polID).add(quo);
            }else{
                policyIdToQuoteListMap.put(polID,new List<Quote> {quo});
            }
        }
        
        //From the policyIdToQuoteListMap, take the latest bound quote from each of the policy ID
        List<Quote> quoteListToClone = new List<Quote>();
        for(String key: policyIdToQuoteListMap.keySet()){
            List<Quote> quoteList = policyIdToQuoteListMap.get(key);
            if(quoteList.size() > 1){
                quoteListToClone.add(quoteList[0]);
            }else{
                quoteListToClone.addAll(quoteList);
            }
        }
        
        List<Quote> clonedQuoteList = new List<Quote>();
        List<String> quoteIdList = new List<String>(); //Ids of orignal quotes which were cloned
        if(!quoteListToClone.isEmpty()){
            clonedQuoteList = CloneServiceHandler_Common.cloneQuote(quoteListToClone);
        }
        
        for(Quote quoteClone: clonedQuoteList){
            system.debug('clonedQuoteList size::'+clonedQuoteList.size());
                quoteClone.Status = 'In Progress';
                quoteClone.Quote_Type__c = endorsementType;
                quoteClone.Rating_Status__c = '';
                quoteClone.Endorsement_Reason__c = endorsementReason != null ? endorsementReason : null;
                quoteClone.Endorsement_Reason_Other__c = endoresementReasonOther;
                quoteClone.Endorsement_Effective_Date__c = effDate != null ? Date.valueOf(effDate) : null;
                quoteClone.UW_Reason__c = '';
                quoteClone.Overall_UW_Codes__c = '';
                quoteClone.OpportunityId = clonedOpp.Id;
                quoteClone.Technical_Fee__c = 0;
                quoteCLone.Fee__c = 0;
                if(String.isNotBlank(quoteClone.Master_Binder__c)){ 
                    Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(quoteClone);
                    quoteClone.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                    if(quoteClone.Layer__c != 'Excess')	quoteClone.IPID_Document__c = quoteDoc.IPID_Document__c;  	                    
                }
        }
        
        if(!clonedQuoteList.isEmpty()){
            GlobalStaticVar.byPassQuoteTrigger = true;
            GlobalStaticVar.byPassFreeFormEndorsementTrigger = true;
            GlobalStaticVar.byPassSubjectivityTrigger = true;
            insert clonedQuoteList;
        }
        
        //Creat empty Quote Option Records
        //addQuoteOptions(clonedQuoteList);
        //Containers with quote Ids for further use in quote related record cloning
        Map<String,String> parentQuoteIdToClonedQuoteIdMap = new Map<String,String>();
        List<Change_Log__c> chnageLogInsertList = new List<Change_Log__c>();
        for(Quote quo :clonedQuoteList){
            parentQuoteIdToClonedQuoteIdMap.put(quo.Parent_Quote__c,quo.Id);                
            quoteIdList.add(quo.Parent_Quote__c);
            
            //create changelog for all created quotes
            Change_Log__c changelog = CommonUtil.createChangeLog(quo.Policy__c, endorsementType, quo.OpportunityId);
            chnageLogInsertList.add(changelog);
        }
        
        if(!chnageLogInsertList.isEmpty()){
            insert chnageLogInsertList;
        }
        
        //clone quote related records
        cloneQuoteRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap,clonedOpp.Id);
        
        resResult.oppId = clonedOpp.Id; 
        
        System.debug('resResult: ' + resResult);
        return resResult;
    }

    public static Opportunity cloneOpportunityDetails(Opportunity opp) {
        Opportunity result = new Opportunity();
        result = opp.clone(false, true, false, false);
        return result;
    }

    public static void cloneOppRelatedRecords(String oldOppId, Opportunity clonedOpp){
        //Quote Process Clone
        List<Quote_Process__c> quoteProcessClone = new List<Quote_Process__c>();        
        List<Quote_Process__c> oldQuoteProcess = [SELECT Id,Account__c,Status__c,Submission_Product__c,Submission_Stage__c,
                                                  Submission__c,Record_Type__c,Product__c FROM Quote_Process__c 
                                                  WHERE Submission__c =:oldOppId LIMIT 1];
        if(!oldQuoteProcess.isEmpty()){
            Quote_Process__c qp = oldQuoteProcess[0].clone(false, true, false, false);            
            qp.Submission__c = clonedOpp.Id;
            qp.Account__c = clonedOpp.AccountId;
            quoteProcessClone.add(qp);
        }
        if(!quoteProcessClone.isEmpty()){
            insert quoteProcessClone;   
        }

        //Clone Notes QuoteProcess #58474
        List<ContentDocumentLink> newNotesQP = new List<ContentDocumentLink>();
        List<ContentDocumentLink> itemsQP = new   List<ContentDocumentLink>();
        Quote_Process__c quotePro = [select Id, Submission__c from Quote_Process__c where Submission__c =:oldOppId];
        if(quotePro != null){
            itemsQP = [select ContentDocument.title , ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: quotePro.Id];
        }
        
        if(!itemsQP.isEmpty()){
            for(ContentDocumentLink note : itemsQP){
                ContentDocumentLink newNote = note.clone(false,true,false,false);
                newNote.LinkedEntityId = quoteProcessClone[0].Id;
                newNotesQP.add(newNote);
            }
        }
        if(!newNotesQP.isEmpty()){
            insert newNotesQP;
        }
        
        //Clone Additional Insured
        List<Additional_Insured__c> addInsured = [select Id,Name,Additional_Insured_Account__c,Submission__c 
                                                  from Additional_Insured__c where Submission__c =: oldOppId];  
        List<Additional_Insured__c> additionalInsuredList = new List<Additional_Insured__c>();
        for(Additional_Insured__c addIn: addInsured)  {
            Additional_Insured__c addInsurer =  addIn.clone(false, true, false, false);
            addInsurer.Submission__c = clonedOpp.Id;
            additionalInsuredList.add(addInsurer);
        }   
        if(!additionalInsuredList.isEmpty()){
            insert additionalInsuredList;   
        }
        
        //Clone Rating Modifiers
        List<Rating_Modifiers__c> ratingModList = [SELECT Id, CurrencyIsoCode, Name, Product__c, Format__c, Picklist_Values__c, 
                                                   Is_Required__c, SME_Question__c, Factor_Max__c, Factor_Min__c, Order_of_Page_Section__c, 
                                                   Page_Section__c, Sort_Order__c, Opportunity__c, Sub_Section__c, Rating_Modifier_Value__c, 
                                                   Eligibility_Weighting_Factor__c, Eligibility_Status__c, Rating_Modifier_Code__c, 
                                                   Sort_Sub_Section__c, Profile_Name_for_Read_Only__c, Display_Format__c 
                                                   FROM Rating_Modifiers__c 
                                                   WHERE Opportunity__c =: oldOppId];
        List<Rating_Modifiers__c> insertRatingMod = new List<Rating_Modifiers__c>();
        
        for(Rating_Modifiers__c newRat : ratingModList){
            Rating_Modifiers__c rateModClone = newRat.clone(false, true, false, false);
            rateModClone.Opportunity__c = clonedOpp.Id;
            insertRatingMod.add(rateModClone);            
        }
        if(!insertRatingMod.isEmpty()){
            insert insertRatingMod;
        }
        
        //Clone UW Analysis
        List<UW_Analysis__c> oldUWAnalysisList = [SELECT Id, Name, CurrencyIsoCode, UW_Analysis_Name__c, Criteria__c, 
                                                  UW_Analysis_Code__c, Rating_Factor__c, Sort_Order__c, Split_Percentage__c, 
                                                  Amount__c, Notional_Income__c, Submission__c, UW_Analysis_Template__c 
                                                  FROM UW_Analysis__c
                                                  WHERE Submission__c =: oldOppId];
        
        List<UW_Analysis__c> newUWList = new List<UW_Analysis__c>();
        for(UW_Analysis__c oldUW : oldUWAnalysisList){
            UW_Analysis__c uwClone = oldUW.clone(false, true, false, false);
            uwClone.Submission__c = clonedOpp.Id;
            newUWList.add(uwClone);                            
        }
        if(!newUWList.isEmpty()){
            insert newUWList;
        }
        
        //Clone Submission Loss Detail
        List<Submission_Loss_Detail__c> subLoss = [SELECT Id, Loss_Amount__c,Number_of_Losses__c, Product__c, Status__c, Year__c, 
                                                   Submission__c, Account_Loss_Detail__c
                                                   FROM Submission_Loss_Detail__c
                                                   WHERE Submission__c =:oldOppId];
        List<Submission_Loss_Detail__c> cloneSubLoss = new List<Submission_Loss_Detail__c>();
        for(Submission_Loss_Detail__c subj: subLoss){
            Submission_Loss_Detail__c cloneSubj = subj.clone(false, true, false, false);
            cloneSubj.Submission__c = clonedOpp.Id;
            cloneSubLoss.add(cloneSubj);
        }
        if(!cloneSubLoss.isEmpty()){
            insert cloneSubLoss;
        }
        
        //Clone Broker Account
        List<Broker_Account__c> brokerAcc = [SELECT Id, Name, CurrencyIsoCode, Opportunity__c, Broker_Contact__c, 
                                             IsPrimaryBroker__c, Relationship_Type__c, Broker_Block_Override__c, Broker_Name__c 
                                             FROM Broker_Account__c
                                             WHERE Opportunity__c=: oldOppId];
        List<Broker_Account__c> cloneBrokerAcc = new List<Broker_Account__c>();
        for(Broker_Account__c brokerAccount: brokerAcc){
            Broker_Account__c brkAcc = brokerAccount.clone(false, true, false, false);
            brkAcc.Opportunity__c = clonedOpp.Id;
            cloneBrokerAcc.add(brkAcc);
        }
        if(!cloneBrokerAcc.isEmpty()){
            insert cloneBrokerAcc;
        }        
    }

    public static void cloneQuoteRelatedRecords(List<String> quoteIdList, Map<String,String> parentQuoteIdToClonedQuoteIdMap, Id clonedOppId){
        Map<String,Id> azureIdToQuoteOptionIdMap = new Map<String,Id>();
        Map<String,String> oldAzureToNewIdMap = new Map<String,String>();

        Set<String> setOfClonedQuoteIds = new Set<String>();
        for(String strOldQuoteId: parentQuoteIdToClonedQuoteIdMap.keySet()){
            setOfClonedQuoteIds.add(parentQuoteIdToClonedQuoteIdMap.get(strOldQuoteId));
        }
        Map<Id,Quote> mapOfClonedQuoteIdToRecord = new Map<Id,Quote>([SELECT Id, Quote_Type__c FROM Quote WHERE Id IN: setOfClonedQuoteIds]);
		System.debug('quoteIdList-->'+quoteIdList);
        //Clone Quote Options
        List<Quote_Option__c> lstClonedQuoteOptions = new List<Quote_Option__c>();
        List<Quote_Option__c> lstPreviousQuoteOptions = [SELECT Id,Azure_ID__c, Quote__c, Actual_Premium_Annual__c, Actual_Premium_Final__c, 
                                                        Book_Premium__c, Broker_Netted_Down_Premium_Annual__c, Quote__r.Status,
                                                        Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c, 
                                                        Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c,
                                                        Broker_Netted_Down_Premium_Final__c, Fee_Annual__c, Fee_Final__c, 
                                                        Final_Discretion__c, Limit__c, Minimum_Premium__c, Price_Adequacy__c, 
                                                        Technical_Premium__c, Technical_Premium_Discretion__c, Quote__r.Layer__c,
                                                        Selected__c, Bound__c, Option_Type__c, Final_Technical_Premium__c,
                                                        Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c,
                                                        Technical_Fee__c,IPT__c,Total_Cost_To_Client__c, Actual_Premium__c,
                                                        Broker_Netted_Down_Premium__c, Fee__c, IPT_on_Broker_Netted_Down_Premium__c,
                                                        NonProrated_Actual_Premium__c, NonProRated_BNDP__c, quote__r.Quote_Type__c FROM Quote_Option__c
                                                        WHERE Quote__c IN: quoteIdList];
        System.debug('lstPreviousQuoteOptions--'+lstPreviousQuoteOptions);
        for(Quote_Option__c objQuoteOption : lstPreviousQuoteOptions) {
            String oldAzureId = objQuoteOption.Azure_ID__c;
            System.debug('objQuoteOption.quote__r.Quote_Type__c--'+objQuoteOption.quote__r.Quote_Type__c);
            if(mapOfClonedQuoteIdToRecord.get(parentQuoteIdToClonedQuoteIdMap.get(objQuoteOption.Quote__c)).Quote_Type__c == 'New Business'
                || mapOfClonedQuoteIdToRecord.get(parentQuoteIdToClonedQuoteIdMap.get(objQuoteOption.Quote__c)).Quote_Type__c == 'Renewal'){
                    if(objQuoteOption.Bound__c){
                        String newQuoteId = parentQuoteIdToClonedQuoteIdMap.get(objQuoteOption.Quote__c);
                        Integer count;
                        if(objQuoteOption.Quote__r.Layer__c == 'Primary'){
                            count = 10;
                            lstClonedQuoteOptions.addAll(CloneServiceHandler_Common.createQuoteOptions(count,newQuoteId,'Fixed Limit'));
                            Quote_Option__c objQO = objQuoteOption.clone(false, true, false, false);
                            objQO.Quote__c = newQuoteId;
                            objQO.Option_Type__c = 'Free Form';
                            objQO.Azure_ID__c = new GuidUtil().NewGuid();
                            oldAzureToNewIdMap.put(oldAzureId,objQO.Azure_ID__c);
                            lstClonedQuoteOptions.add(objQO);
                        }
                        else{
                            count = 6;
                            lstClonedQuoteOptions.addAll(CloneServiceHandler_Common.createQuoteOptions(count,newQuoteId,'Fixed Limit'));
                            Quote_Option__c objQO = objQuoteOption.clone(false, true, false, false);
                            objQO.Quote__c = newQuoteId;
                            objQO.Option_Type__c = 'Free Form';
                            objQO.Azure_ID__c = new GuidUtil().NewGuid();
                            oldAzureToNewIdMap.put(oldAzureId,objQO.Azure_ID__c);
                            lstClonedQuoteOptions.add(objQO);
                        }
                    }
            }
            else if(mapOfClonedQuoteIdToRecord.get(parentQuoteIdToClonedQuoteIdMap.get(objQuoteOption.Quote__c)).Quote_Type__c == 'Full Amendment' || 
              (objQuoteOption.quote__r.Quote_Type__c == 'New Business' && objQuoteOption.Quote__r.Status == 'Bound')){
                  System.debug('objQuoteOption.quote__r.Quote_Type__c--'+objQuoteOption.quote__r.Quote_Type__c);
                if(objQuoteOption.Bound__c){
                    System.debug('sdhfvdsjf');
                    Quote_Option__c objClonedQuoteOption = objQuoteOption.clone(false, true, false, false);
                    objClonedQuoteOption.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(objQuoteOption.Quote__c);
                    objClonedQuoteOption.Azure_ID__c = new GuidUtil().NewGuid();
                    oldAzureToNewIdMap.put(oldAzureId,objClonedQuoteOption.Azure_ID__c);
                    lstClonedQuoteOptions.add(objClonedQuoteOption);
                }
            }
            else{
                Quote_Option__c objClonedQuoteOption = objQuoteOption.clone(false, true, false, false);
                objClonedQuoteOption.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(objQuoteOption.Quote__c);
                objClonedQuoteOption.Azure_ID__c = new GuidUtil().NewGuid();
                oldAzureToNewIdMap.put(oldAzureId,objClonedQuoteOption.Azure_ID__c);
                lstClonedQuoteOptions.add(objClonedQuoteOption);
            }
        }
        
        if(!lstClonedQuoteOptions.isEmpty()){
            insert lstClonedQuoteOptions;
        }        
        for(Quote_Option__c option : lstClonedQuoteOptions){
            azureIdToQuoteOptionIdMap.put(option.Azure_ID__c,option.Id);
        }
        //Clone referral reasons
        List<Referral_Reason__c> clonedReferralReasonsList = new List<Referral_Reason__c>();
        List<Referral_Reason__c> referralReasonsList = [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,Approval_Rejected_Date__c,
                                                        Approver_Level__c,Approved_By__c, Entity_Path__c,Reason__c,Reason_Type__c,Status__c,Quote_Option__r.Bound__c,
                                                        Approved_By__r.Name, Quote__c,Is_Auto_Approved__c,Option_Id__c,Quote_Option__c,Quote_Option__r.Selected__c,Option_Type__c,
                                                        Option_Limit__c,Quote__r.Quote_Type__c,Quote__r.Status,Quote_Option_Limit__c From Referral_Reason__c 
                                                        WHERE Quote__c IN: quoteIdList];
        for(Referral_Reason__c reason : referralReasonsList) {
            if(mapOfClonedQuoteIdToRecord.get(parentQuoteIdToClonedQuoteIdMap.get(reason.Quote__c)).Quote_Type__c == 'Full Amendment' || 
              (reason.Quote__r.Quote_Type__c == 'New Business' && reason.Quote__r.Status == 'Bound')){
                  System.debug('reason.Quote__r.Quote_Type__c--'+reason.Quote__r.Quote_Type__c);
                  if((reason.Quote_Option__r.Bound__c || reason.Quote_Option__c == null) && reason.Approval_Status__c == 'Approved'){	// for post bind transaction
                    System.debug('sdhfvfsdkjfskddsjf');
                    Referral_Reason__c reasonClone = reason.clone(false, true, false, false);
                    reasonClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(reason.Quote__c);
                    reasonClone.Quote_Option__c = azureIdToQuoteOptionIdMap.get(oldAzureToNewIdMap.get(reason.Option_Id__c));
                    reasonClone.Option_Id__c = oldAzureToNewIdMap.get(reason.Option_Id__c);
                    clonedReferralReasonsList.add(reasonClone);
                }
            }else if(!reason.Quote_Option__r.Bound__c && reason.Approval_Status__c != 'Approved' && (reason.Quote__r.Quote_Type__c != 'New Business' && reason.Quote__r.Status != 'Bound')){
                Referral_Reason__c reasonClone = reason.clone(false, true, false, false);
                reasonClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(reason.Quote__c);
                reasonClone.Quote_Option__c = azureIdToQuoteOptionIdMap.get(oldAzureToNewIdMap.get(reason.Option_Id__c));
                reasonClone.Option_Id__c = oldAzureToNewIdMap.get(reason.Option_Id__c);
                clonedReferralReasonsList.add(reasonClone);
            }            
        }
        system.debug('## cloned Referral resons -- ' + clonedReferralReasonsList);
        if(!clonedReferralReasonsList.isEmpty()){
            insert clonedReferralReasonsList;
        }
        
        // Clone Subjectivity
        List<Subjectivity__c> clonedSubjectivitiesList = new List<Subjectivity__c>();
        List<Subjectivity__c> subjectivityList = [SELECT Id, Name, Due_Date__c, Quote__c, Stage__c,
                                                  Subjectivity__c, Subjectivity_Status__c, Subjectivity_Type__c,
                                                  Cleared__c,Subjectivity_Text__c, Subjectivity_Template__c,
                                                  Cleared_Date__c
                                                  FROM Subjectivity__c 
                                                  WHERE Quote__c IN: quoteIdList];
        for(Subjectivity__c sub : subjectivityList) {
            Subjectivity__c subClone = sub.clone(false, true, false, false);
            subClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(sub.Quote__c);
            clonedSubjectivitiesList.add(subClone);
        }
        System.debug('## cloned subjectivities -- ' + clonedSubjectivitiesList);
        if(!clonedSubjectivitiesList.isEmpty()){
            insert clonedSubjectivitiesList;
        }
        
        // Clone Insurer Layer Limit 
        List<Insurer_Layer_Limit__c> clonedInsurerList = new List<Insurer_Layer_Limit__c>();
        List<Insurer_Layer_Limit__c> insurerList = [SELECT Id, Name, Insurer__c, Insurer_Layer_Limit__c,
                                                    Insurer_Policy_Number__c,Layer__c,Quote__c
                                                    FROM Insurer_Layer_Limit__c 
                                                    WHERE Quote__c IN: quoteIdList];
        for(Insurer_Layer_Limit__c insurer : insurerList) {
            Insurer_Layer_Limit__c insurerClone = insurer.clone(false, true, false, false);
            insurerClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(insurer.Quote__c);
            clonedInsurerList.add(insurerClone);
        }
        System.debug('## cloned InsurerList-- ' + clonedInsurerList);
        if(!clonedInsurerList.isEmpty()){
            insert clonedInsurerList;
        }
        
        // Clone CoveragesLine Item List
        List<CoveragesLineItem__c> clonedCovLineItemList = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> covLineItem = [SELECT Id, Coverage__c, Sub_Coverage__c, Limits_Deductibles__c, Coverage_product__c,
                                                  Coverage_Premium__c,Deductible_Frequency__c, Options_Value_Percent__c,
                                                  Increment_Step__c, IsIncluded__c, Max_amt__c, Min_amt__c, Page_Section__c,
                                                  Option_Picklist__c,Option_Type__c,Option_Value__c,Override_Premium__c,
                                                  Option_Value_Default__c, Notes__c, Form_Number__c,Quote__c,
                                                  Coverage_Effective_Date__c, Group__c                                                   
                                                  FROM CoveragesLineItem__c 
                                                  WHERE Quote__c IN: quoteIdList];
        for(CoveragesLineItem__c cli : covLineItem) {
            CoveragesLineItem__c cliClone = cli.clone(false, true, false, false);
            cliClone.Parent_Coverages_Line_Item__c = cli.Id;
            cliClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(cli.Quote__c);
            clonedCovLineItemList.add(cliClone);
        }
        system.debug('## cloned CLIs' + clonedCovLineItemList);
        if(!clonedCovLineItemList.isEmpty()){
            insert clonedCovLineItemList;
        }
        
        //Clone Free form endorsements
        List<Free_Form_Endorsements__c> clonedFreeFormEndList = new List<Free_Form_Endorsements__c>();
        List<Free_Form_Endorsements__c> freeFormEnd = [SELECT Id, Name, Quote__c, Form_Number__c, Endorsement_Name__c, Endorsement_Wording__c, 
                                                       Coverage_Effective_Date__c FROM Free_Form_Endorsements__c 
                                                       WHERE Quote__c IN: quoteIdList];
        for(Free_Form_Endorsements__c ffe : freeFormEnd) {
            Free_Form_Endorsements__c ffClone = ffe.clone(false, true, false, false);
            //ffClone.Parent_Coverages_Line_Item__c = cli.Id;
            ffClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(ffe.Quote__c);
            clonedFreeFormEndList.add(ffClone);
        }
        system.debug('## cloned freeFormEnd' +clonedFreeFormEndList);
        
        if(!clonedFreeFormEndList.isEmpty()){
            insert clonedFreeFormEndList;
        }
        
        //Clone Rating Modifier Factor
        List<Rating_Modifier_Factor__c> cloneRatingModifierFactorsList = new List<Rating_Modifier_Factor__c>();
        List<Rating_Modifier_Factor__c> ratingModifierFactors = [SELECT CreatedById, Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                                                                 Factor_Value__c, LastModifiedById, Rating_Modifier__c, Quote__c, 
                                                                 Rating_Modifier__r.Rating_Modifier_Code__c
                                                                 FROM Rating_Modifier_Factor__c 
                                                                 WHERE Quote__c IN: quoteIdList];
        System.debug('$$$$quoteIdList='+quoteIdList);
        System.debug('$$$$RatingModifierFactor='+ratingModifierFactors);
        
        Map<String, Rating_Modifiers__c> newRateModCodeToObjMap = new Map<String, Rating_Modifiers__c>();
        List<Rating_Modifiers__c> ratingModOnClonedOppList = [SELECT Id, Opportunity__c, Rating_Modifier_Code__c
                                                   FROM Rating_Modifiers__c 
                                                   WHERE Opportunity__c =: clonedOppId];
        
        for(Rating_Modifiers__c newRatM : ratingModOnClonedOppList){
            newRateModCodeToObjMap.put(newRatM.Rating_Modifier_Code__c, newRatM);
        }
        
        for(Rating_Modifier_Factor__c rati : ratingModifierFactors) {
            Rating_Modifier_Factor__c cloneRMF = rati.clone(false, true, false, false);
            cloneRMF.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(rati.Quote__c);
            cloneRMF.Rating_Modifier__c = newRateModCodeToObjMap.get(rati.Rating_Modifier__r.Rating_Modifier_Code__c).Id;
            cloneRatingModifierFactorsList.add(cloneRMF); 
        }
        system.debug('## cloned Rating Modifier Factors' +cloneRatingModifierFactorsList);
        
        if(!cloneRatingModifierFactorsList.isEmpty()){
            List<Rating_Modifier_Factor__c> deleteRMFs = [SELECT Id, Name FROM Rating_Modifier_Factor__c WHERE Quote__c IN: setOfClonedQuoteIds];
            delete deleteRMFs;
            insert cloneRatingModifierFactorsList;
        }
        
    }

    public static RenewalPolicyAQController.ResultWrapper policyRenewal(String policyId){
        
        RenewalPolicyAQController.ResultWrapper resResult = new RenewalPolicyAQController.ResultWrapper();
        List<Transactions__c> submissionPoilcyTransaction = [SELECT Name, Id, Policy__c, Submission__c 
                                                             FROM Transactions__c 
                                                             WHERE Policy__c =:policyId 
                                                             AND Submission__r.Transaction_Status__c = 'Active' LIMIT 1];
        if(submissionPoilcyTransaction.isEmpty()){
            resResult.error = 'No Active Submission/Transaction record found on this Policy';
            return resResult;
        }
        //Policy details
        Policy__c policy = [select Id,Effective_Date__c,Expiration_Date__c from Policy__c where Id=:policyId limit 1];

        String oppId = submissionPoilcyTransaction[0].Submission__c;
        Savepoint sp;
        
        //Clone opportunity
        List<Opportunity> opportunity = CloneQueryUtil.queryOpportunityAQ(oppId);     
        system.debug('##  opp -- '+opportunity);
        
        if(opportunity.isEmpty()){
            resResult.oppId = oppId;
            resResult.error = 'No Opportunity found for the current policy';
            return resResult;
        }
        
        Opportunity opp = opportunity[0];
        
        Opportunity clonedOpp = cloneOpportunityDetails(opp);
        string oppCloneName = opp.Name.substringBefore(' PI ');
        if(oppCloneName.length() > 100){
            oppCloneName = oppCloneName.substring(0, 100);
        }
        clonedOpp.AccountId = opp.AccountId;
        clonedOpp.Parent_Opportunity__c = opp.Id;
        clonedOpp.Transaction_Status__c = 'Inactive';
        clonedOpp.Type = 'Renewal'; 
        clonedOpp.StageName = 'Qualified'; 
        clonedOpp.Submission_Status__c = '';
        clonedOpp.Policy__c = null;
        clonedOpp.Azure_ID__c = new GuidUtil().NewGuid();   
        clonedOpp.Received_Date__c = null;
        clonedOpp.CloseDate = Date.today() + 90;
        clonedOpp.Effective_Date__c = policy.Expiration_Date__c + 1;
        clonedOpp.Name = oppCloneName + ' PI ' + clonedOpp.Effective_Date__c.format();
        clonedOpp.Expiration_Date__c  = policy.Expiration_Date__c.addDays(365);   
       
        /*********** Commented due to 56890 */
       /* if(opp.Policy__c != null){
            clonedOpp.Prior_Policy__c = opp.Policy__c;
        }*/
        
        GlobalStaticVar.byPassOpportunityTrigger = true;
        insert clonedOpp;                        
        
        if(clonedOpp.Id == null){
            Database.rollback(sp);
            resResult.oppId = oppId;
            resResult.error = 'Error during cloning opportunity';
            return resResult;
        }

        //Get all the related policies from the parent opp (Renewal)
        Set<Id> policyIds = new Set<Id>();
        for(Transactions__c policyIdsOnSubmission:  [SELECT Name, Id, Policy__c, Submission__c 
                                                     FROM Transactions__c 
                                                     WHERE Submission__c =:oppId]){
                                                         if(policyIdsOnSubmission.Policy__c != null){
                                                             policyIds.add(policyIdsOnSubmission.Policy__c);
                                                         }
                                                     }
        
        List<Policy__c> polList = [Select Id, Expiration_Date__c from Policy__c where Id IN :policyIds];
        
        //Get all the quotes from the policies (Renewal)
        Map<String,List<Quote>> policyIdToQuoteListMap = new Map<String,List<Quote>>();
        List<Quote> quoteListFromPolicy = CloneQueryUtil.queryQuoteAQ(policyIds);
        //Create a Map of Policy ID & related quotes (Renewal)
        for(Quote quo: quoteListFromPolicy){
            String polID = quo.Policy__c;
            if(policyIdToQuoteListMap.containsKey(polID)){
                policyIdToQuoteListMap.get(polID).add(quo);
            }else{
                policyIdToQuoteListMap.put(polID,new List<Quote> {quo});
            }
        }
        //From the policyIdToQuoteListMap, take the latest bound quote from each of the policy ID (Renewal)
        List<Quote> quoteListToClone = new List<Quote>();
        List<Quote> filterQuoteList = new List<Quote>();
        for(String key: policyIdToQuoteListMap.keySet()){
            List<Quote> quoteList = policyIdToQuoteListMap.get(key);
            if(!quoteList.isEmpty()){
                filterQuoteList.add(quoteList[0]);//Quote to filter
            }
        }
        system.debug('quoteListFromPolicy-->'+quoteListFromPolicy[0].ExpirationDate);
        system.debug('filterQuoteList-->'+filterQuoteList[0].ExpirationDate);
        List<Quote> primaryQuotes = new List<Quote>();
        List<Quote> excessQuotes = new List<Quote>();
        string layer = 'Primary';
        for(Quote quote: filterQuoteList){
            if(quote.Layer__c == 'Primary'){
                primaryQuotes.add(quote);
            }
            if(quote.Layer__c == 'Excess'){
                excessQuotes.add(quote);
            }
        }
        set<Id> quoteId = new set<Id>();
        if(primaryQuotes.isEmpty() && !excessQuotes.isEmpty()) {
            quoteListToClone.addAll(excessQuotes); //only excess to clone
            layer = 'Excess';
        }
        else if(!primaryQuotes.isEmpty() && excessQuotes.isEmpty()) {
            quoteListToClone.addAll(primaryQuotes);//only primary to clone
            //layer = 'Primary';
        }
        else if(!primaryQuotes.isEmpty() && !excessQuotes.isEmpty()){
            for(Quote primary: primaryQuotes){
                for(Quote excess: excessQuotes){
                    if(primary.Effective_Date__c == excess.Effective_Date__c && primary.ExpirationDate == excess.ExpirationDate){
                        quoteId.add(excess.Id);
                        quoteId.add(primary.Id);
                        layer = layer+';Excess';
                    }
                    else if(primary.Effective_Date__c != excess.Effective_Date__c && primary.ExpirationDate == excess.ExpirationDate){
                        quoteId.add(excess.Id);
                        quoteId.add(primary.Id);
                        layer = layer+';Excess';
                    }else if(excess.ExpirationDate <= primary.ExpirationDate || excess.ExpirationDate > primary.ExpirationDate){
                        if(excess.ExpirationDate < primary.ExpirationDate || excess.ExpirationDate > primary.ExpirationDate){
                            quoteId.add(primary.Id);
                        }else if(excess.ExpirationDate == primary.ExpirationDate){
                            quoteId.add(excess.Id);
                            quoteId.add(primary.Id);
                            layer = layer+';Excess';
                        }
                    }
                }
            }
        }
        
        if(!quoteId.isEmpty()){
            quoteListToClone = CloneQueryUtil.queryRenewalQuoteAQ(quoteId);
        }

        resResult.oppId = clonedOpp.Id;
        resResult.quoteList = quoteListToClone;
        resResult.layer = layer;
     
        return resResult;
    }

    public static RenewalPolicyAQController.ResultWrapper createRenewalQuotes(string clonedOpp,String policyId,List<Quote> quoteListToClone,string binderPrimary,string binderExcess){
        RenewalPolicyAQController.ResultWrapper resResult = new RenewalPolicyAQController.ResultWrapper();
        List<String> clonedQuoteIdList = new List<String>(); //Ids of orignal quotes which were cloned (Renewal)
        
        try{
            List<Transactions__c> submissionPoilcyTransaction = [SELECT Name, Id, Policy__c, Submission__c 
                                                                 FROM Transactions__c 
                                                                 WHERE Policy__c =:policyId 
                                                                 AND Submission__r.Transaction_Status__c = 'Active' LIMIT 1];
            if(submissionPoilcyTransaction.isEmpty()){
                resResult.error = 'No Active Submission/Transaction record found on this Policy';
                return resResult;
            }
            
            String oppId = submissionPoilcyTransaction[0].Submission__c;

            //Clone related objects
            Opportunity clonedOppo = [select Id,Name,AccountId from Opportunity where Id =:clonedOpp limit 1];
            if(clonedOppo != null){
                cloneOppRelatedRecordsRenewal(oppId,clonedOppo);
            }

            clonedOppo = [select Id,Name,AccountId,Product_Name__c, (SELECT Id,Broker_Contact__r.AccountId from Opportunity_Accounts1__r where IsPrimaryBroker__c = true) from Opportunity where Id =:clonedOpp limit 1];


            //Clone Notes 
            List<ContentDocumentLink> newNotes = new List<ContentDocumentLink>();
            List<ContentDocumentLink> items = [select ContentDocument.title , ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: oppId];
            
            if(!items.isEmpty()){
                for(ContentDocumentLink note : items){
                    ContentDocumentLink newNote = note.clone(false,true,false,false);
                    newNote.LinkedEntityId = clonedOpp;
                    newNotes.add(newNote);
                }
            }
            if(!newNotes.isEmpty()){
                insert newNotes;
            }
            
            //Get all the related policies from the parent opp (Renewal)
            Set<Id> policyIds = new Set<Id>();
            for(Transactions__c policyIdsOnSubmission:  [SELECT Name, Id, Policy__c, Submission__c 
                                                         FROM Transactions__c 
                                                         WHERE Submission__c =:oppId]){
                                                             if(policyIdsOnSubmission.Policy__c != null){
                                                                 policyIds.add(policyIdsOnSubmission.Policy__c);
                                                             }
                                                         }
            
            List<Quote> clonedQuoteList = new List<Quote>();
            List<String> quoteIdList = new List<String>(); //Ids of orignal quotes which were cloned (Renewal)
             system.debug('quoteListToClone-->'+quoteListToClone);
            if(!quoteListToClone.isEmpty()){
                clonedQuoteList = cloneQuoteRenewal(quoteListToClone);
            }
            Map<string,string> mapParentQuotetoPolicy = new Map<string,string>();
            system.debug('clonedQuoteList-->'+clonedQuoteList);

            List<Account_Product__c> accProds = !clonedOppo.Opportunity_Accounts1__r.isEmpty() ? AccountProductQueryUtil.fetchAccountProductsByAccountAndProductName(clonedOppo.Opportunity_Accounts1__r[0].Broker_Contact__r.AccountId, clonedOppo.Product_Name__c) : new List<Account_Product__c>();

            if(!clonedQuoteList.isEmpty()){
                
                Set<string> effectiveBinders = new Set<String>();
                
                system.debug('binderPrimary'+binderPrimary);
                system.debug('binderExcess'+binderExcess);
                
                if(String.isNotBlank(binderPrimary))
                    effectiveBinders.add(binderPrimary);
                 if(String.isNotBlank(binderExcess))
                   effectiveBinders.add(binderExcess);
                   
                /**** 56719 ******/
                Map<Id,Master_Binder__c> masterBinderMap = new Map<Id,Master_Binder__c>([select id,MGA_Commission__c from Master_Binder__c where id IN: effectiveBinders]);
                system.debug('masterBinderMap'+masterBinderMap);
               // system.debug('masterBinder Commission'+masterBinder[0].MGA_Commission__c);
                
                Map<Id, Id> mapOfBrokerIdToQuoteId = new Map<Id, Id>();
                for(Quote newQuote: clonedQuoteList){
                    if(updateBrokerCommissionOnQuote && newQuote.Broker__c != null){
                        mapOfBrokerIdToQuoteId.put(newQuote.Broker__c, newQuote.Id);
                    }
                    mapParentQuotetoPolicy.put(newQuote.Parent_Quote__c,newQuote.Policy__c);
                    newQuote.Quote_Type__c = 'Renewal';
                    newQuote.Status = 'In Progress';
                    newQuote.Rating_Status__c = '';
                    newQuote.UW_Reason__c = '';
                    newQuote.Overall_UW_Codes__c = '';
                    
                    /****** Prior Policy for 56890 ***************/
                    newQuote.Prior_Policy__c = newQuote.Policy__c;
                    
                    newQuote.Policy__c = null; 
                    newQuote.OpportunityId = clonedOpp;
                    newQuote.Technical_Fee__c = 0;
                    newQuote.Fee__c = 0;
                    newQuote.Endorsement_Effective_Date__c = null; 
                    newQuote.Endorsement_Reason__c = '';
                    newQuote.Endorsement_Reason_Other__c = '';
                    if(newQuote.Layer__c == 'Primary') newQuote.Master_Binder__c = binderPrimary;
                    else newQuote.Master_Binder__c = binderExcess;  
                    if(String.isNotBlank(newQuote.Master_Binder__c)){ 
                          
                        /**** New Line for 56719 ******/
                        if(!masterBinderMap.isEmpty() && newQuote.Layer__c=='Primary' && masterBinderMap.containsKey(binderPrimary)){
                            system.debug('masterBinderMap.get(binderPrimary).MGA_Commission__c'+masterBinderMap.get(binderPrimary).MGA_Commission__c);
                             newQuote.MGA_Commission__c = masterBinderMap.get(binderPrimary).MGA_Commission__c;
                        }
                        else if(!masterBinderMap.isEmpty() && newQuote.Layer__c!='Primary' && masterBinderMap.containsKey(binderExcess)){
                            system.debug('masterBinderMap.get(binderExcess).MGA_Commission__c'+masterBinderMap.get(binderExcess).MGA_Commission__c);
                              newQuote.MGA_Commission__c = masterBinderMap.get(binderExcess).MGA_Commission__c; 
                        }
                        System.debug('Binder---->'+newQuote.Master_Binder__c);
                        Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(newQuote);
                        newQuote.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                        if(newQuote.Layer__c != 'Excess')	newQuote.IPID_Document__c = quoteDoc.IPID_Document__c;  	                    
                    }
                    if(newQuote.Retroactive_Date__c == 'Retro - Inception date'){
                        newQuote.Retroactive_Date__c = 'Date';
                    }

                    if(!accProds.isEmpty()){
                        newQuote.Commission_percentage__c = accProds[0].Commission_percentage__c;
                    }
                }

                if(updateBrokerCommissionOnQuote){
                    List<Account_Product__c> lstAccProduct = [SELECT Commission_percentage__c FROM Account_Product__c WHERE Account_Id__r.Name = 'Citynet Insurance Brokers Limited' LIMIT 1];
                    Map<Id, Contact> mapOfIdToContact = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE Id IN: mapOfBrokerIdToQuoteId.keySet()]);
                    for(Quote newQuote: clonedQuoteList){
                        if(mapOfIdToContact.containsKey(newQuote.Broker__c) && mapOfIdToContact.get(newQuote.Broker__c).Name == 'Citynet Insurance Brokers Limited t/as Cobra London Markets'){
                            newQuote.Commission_percentage__c = lstAccProduct[0].Commission_percentage__c;
                        }
                    }
                    updateBrokerCommissionOnQuote = false;
                }
            }
            
            if(!clonedQuoteList.isEmpty()){
                GlobalStaticVar.byPassQuoteTrigger = true;
                GlobalStaticVar.byPassFreeFormEndorsementTrigger = true;
                GlobalStaticVar.byPassSubjectivityTrigger = true;
                insert clonedQuoteList;
            }
            
            system.debug('clonedQuoteList-->'+clonedQuoteList);
            //Containers with quote Ids for further use in quote related record cloning (Renewal)
            Map<String,String> parentQuoteIdToClonedQuoteIdMap = new Map<String,String>();
            List<Change_Log__c> chnageLogInsertList = new List<Change_Log__c>();
            for(Quote quo :clonedQuoteList){
                parentQuoteIdToClonedQuoteIdMap.put(quo.Parent_Quote__c,quo.Id);                
                quoteIdList.add(quo.Parent_Quote__c);
                clonedQuoteIdList.add(quo.Id);
                
                //create changelog for all created quotes
                Change_Log__c changelog = CommonUtil.createChangeLog(mapParentQuotetoPolicy.get(quo.Parent_Quote__c), 'Renewal', quo.OpportunityId);
                chnageLogInsertList.add(changelog);
            }
            
			if(!chnageLogInsertList.isEmpty()){
                insert chnageLogInsertList;
            }            
            //clone quote related records (Renewal)
            cloneQuoteRenewalRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap, clonedOpp);
            
            //Update All cloned Quote Policy to Renewed
            set<Id> renewPolicyId = new set<Id>();
            List<Policy__c> policyList = new List<Policy__c>();
            if(!quoteListToClone.isEmpty()){
                for(Quote quote: quoteListToClone){
                    renewPolicyId.add(quote.Policy__c);
                }
            }
            if(!renewPolicyId.isEmpty()){
                policyList = [select Id,Renewal_Completed__c from Policy__c where Id IN: renewPolicyId];
            }
            
            
            if(!policyList.isEmpty()){
                for(Policy__c pol: policyList){
                    pol.Renewal_Completed__c = true;
                }
                update policyList;
            }
            
        }catch (DMLException ex){
            resResult.error = ex.getDmlMessage(0);
            resResult.isSuccess = false;
            return resResult;
        }catch(exception ex){
            system.debug('error: '+ex.getMessage()+' '+ex.getLineNumber());
            resResult.error = ex.getMessage();
            resResult.isSuccess = false;
            return resResult;
        }
      
        resResult.oppId = clonedOpp;
        resResult.listCloneQuoteId = clonedQuoteIdList;
        resResult.isSuccess = true;
        return resResult;
    }

    public static void cloneOppRelatedRecordsRenewal(String oldOppId, Opportunity clonedOpp){//(newOppId,OldOppId)
        //Quote Process Clone
        List<Quote_Process__c> quoteProcessClone = new List<Quote_Process__c>();        
        List<Quote_Process__c> oldQuoteProcess = [SELECT Id,Account__c,Status__c,Submission_Product__c,Submission_Stage__c,
                                                  Submission__c,Record_Type__c,Product__c FROM Quote_Process__c 
                                                  WHERE Submission__c =:oldOppId LIMIT 1];
        if(!oldQuoteProcess.isEmpty()){
            Quote_Process__c qp = oldQuoteProcess[0].clone(false, true, false, false);            
            qp.Submission__c = clonedOpp.Id;
            qp.Account__c = clonedOpp.AccountId;
            quoteProcessClone.add(qp);
        }
        if(!quoteProcessClone.isEmpty()){
            insert quoteProcessClone;   
        }
        
        //Clone Notes QuoteProcess
        List<ContentDocumentLink> newNotesQP = new List<ContentDocumentLink>();
        List<ContentDocumentLink> itemsQP = new   List<ContentDocumentLink>();
        Quote_Process__c quotePro = [select Id, Submission__c from Quote_Process__c where Submission__c =:oldOppId];
        if(quotePro != null){
            itemsQP = [select ContentDocument.title , ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: quotePro.Id];
        }
        
        if(!itemsQP.isEmpty()){
            for(ContentDocumentLink note : itemsQP){
                ContentDocumentLink newNote = note.clone(false,true,false,false);
                newNote.LinkedEntityId = quoteProcessClone[0].Id;
                newNotesQP.add(newNote);
            }
        }
        if(!newNotesQP.isEmpty()){
            insert newNotesQP;
        }
        
        //Clone Additional Insured
        List<Additional_Insured__c> addInsured = [select Id,Name,Additional_Insured_Account__c,Submission__c 
                                                  from Additional_Insured__c where Submission__c =: oldOppId];  
        List<Additional_Insured__c> additionalInsuredList = new List<Additional_Insured__c>();
        for(Additional_Insured__c addIn: addInsured)  {
            Additional_Insured__c addInsurer =  addIn.clone(false, true, false, false);
            addInsurer.Submission__c = clonedOpp.Id;
            additionalInsuredList.add(addInsurer);
        }   
        if(!additionalInsuredList.isEmpty()){
            insert additionalInsuredList;   
        }
        
        
        
        //Clone Rating Modifiers
        List<Rating_Modifiers__c> ratingModList = [SELECT Id, CurrencyIsoCode, Name, Product__c, Format__c, Picklist_Values__c, 
                                                   Is_Required__c, SME_Question__c, Factor_Max__c, Factor_Min__c, Order_of_Page_Section__c, 
                                                   Page_Section__c, Sort_Order__c, Opportunity__c, Sub_Section__c, Rating_Modifier_Value__c, 
                                                   Eligibility_Weighting_Factor__c, Eligibility_Status__c, Rating_Modifier_Code__c, 
                                                   Sort_Sub_Section__c, Profile_Name_for_Read_Only__c, Display_Format__c 
                                                   FROM Rating_Modifiers__c 
                                                   WHERE Opportunity__c =: oldOppId];
        List<Rating_Modifiers__c> insertRatingMod = new List<Rating_Modifiers__c>();
        Map<String, Rating_Modifiers__c> newRateModNameToObjMap = new Map<String, Rating_Modifiers__c>();
        system.debug('oldOppId---'+oldOppId);
        system.debug('clonedOpp---'+clonedOpp);
            
        for(Rating_Modifiers__c newRat : ratingModList){
            Rating_Modifiers__c rateModClone = newRat.clone(false, true, false, false);
            rateModClone.Opportunity__c = clonedOpp.Id;
            if(newRat.Name == 'Proposal Form Date'){
                rateModClone.Rating_Modifier_Value__c = '';
            }
            if(newRat.Name == 'Annual gross fees / turnover - change'){
                rateModClone.Rating_Modifier_Value__c = '0.00%';
            }
            if(newRat.Name == 'Rateable Exposure - Change'){
                rateModClone.Rating_Modifier_Value__c = '0.00%';
            }
            insertRatingMod.add(rateModClone);
        }
        
        for(Rating_Modifiers__c newRatM : insertRatingMod){
            newRateModNameToObjMap.put(newRatM.Name, newRatM);
        }
        
        for(Rating_Modifiers__c oldRat : ratingModList){
            if(oldRat.Name == 'Annual gross fees / turnover' && newRateModNameToObjMap.containsKey('Annual gross fees / turnover - Previous Year')){//----CD-100 - Gaurish Goel 9th Sep 2021 -- added null checks
                if(oldRat.Rating_Modifier_Value__c != null){//----CD-100 - Gaurish Goel 9th Sep 2021 -- added null checks
                    newRateModNameToObjMap.get('Annual gross fees / turnover - Previous Year').Rating_Modifier_Value__c = oldRat.Rating_Modifier_Value__c;
                }
            }
            else if(oldRat.Name == 'Rateable Exposure' && newRateModNameToObjMap.containsKey('Rateable Exposure - Previous Year')){//----CD-100 - Gaurish Goel 9th Sep 2021 -- added null checks
                if(oldRat.Rating_Modifier_Value__c != null){//----CD-100 - Gaurish Goel 9th Sep 2021 -- added null checks
                    newRateModNameToObjMap.get('Rateable Exposure - Previous Year').Rating_Modifier_Value__c = oldRat.Rating_Modifier_Value__c;
                }
            }
        }
        system.debug('## newRateModNameToObjMap values ----'+ newRateModNameToObjMap.values());
        system.debug('## newRateModNameToObjMap ----'+ newRateModNameToObjMap);
        if(!newRateModNameToObjMap.values().isEmpty()){
            insert newRateModNameToObjMap.values();
        }
        
        //Clone UW Analysis
        List<UW_Analysis__c> oldUWAnalysisList = [SELECT Id, Name, CurrencyIsoCode, UW_Analysis_Name__c, Criteria__c, 
                                                  UW_Analysis_Code__c, Rating_Factor__c, Sort_Order__c, Split_Percentage__c, 
                                                  Amount__c, Notional_Income__c, Submission__c, UW_Analysis_Template__c 
                                                  FROM UW_Analysis__c
                                                  WHERE Submission__c =: oldOppId];
        
        List<UW_Analysis__c> newUWList = new List<UW_Analysis__c>();
        for(UW_Analysis__c oldUW : oldUWAnalysisList){
            UW_Analysis__c uwClone = oldUW.clone(false, true, false, false);
            uwClone.Submission__c = clonedOpp.Id;
            newUWList.add(uwClone);                            
        }
        if(!newUWList.isEmpty()){
            insert newUWList;
        }
        
        //Clone Submission Loss Detail
        List<Submission_Loss_Detail__c> subLoss = [SELECT Id, Loss_Amount__c,Number_of_Losses__c, Product__c, Status__c, Year__c, 
                                                   Submission__c, Account_Loss_Detail__c
                                                   FROM Submission_Loss_Detail__c
                                                   WHERE Submission__c =:oldOppId];
        List<Submission_Loss_Detail__c> cloneSubLoss = new List<Submission_Loss_Detail__c>();
        for(Submission_Loss_Detail__c subj: subLoss){
            Submission_Loss_Detail__c cloneSubj = subj.clone(false, true, false, false);
            cloneSubj.Submission__c = clonedOpp.Id;
            cloneSubLoss.add(cloneSubj);
        }
        if(!cloneSubLoss.isEmpty()){
            insert cloneSubLoss;
        }
        
        //Clone Broker Account
        List<Broker_Account__c> brokerAcc = [SELECT Id, Name, CurrencyIsoCode, Opportunity__c, Broker_Contact__c, Broker_Contact__r.Account.Name,
                                             IsPrimaryBroker__c, Relationship_Type__c, Broker_Block_Override__c, Broker_Name__c 
                                             FROM Broker_Account__c
                                             WHERE Opportunity__c=: oldOppId];
        List<Broker_Account__c> cloneBrokerAcc = new List<Broker_Account__c>();
        Boolean boolIsBrokerContactToBeUpdated = false;
        for(Broker_Account__c brokerAccount: brokerAcc){
            if(brokerAccount.Broker_Contact__r.Account.Name == 'Citynet Insurance Brokers Limited t/as Cobra London Markets'){
                boolIsBrokerContactToBeUpdated = true;
            }
            Broker_Account__c brkAcc = brokerAccount.clone(false, true, false, false);
            brkAcc.Opportunity__c = clonedOpp.Id;
            cloneBrokerAcc.add(brkAcc);
        }

        if(boolIsBrokerContactToBeUpdated){
            List<Contact> lstBrokerContact = [SELECT Id FROM Contact WHERE Account.Name = 'Citynet Insurance Brokers Limited' AND RecordType.DeveloperName = 'Broker_Contact' LIMIT 1];
            if(!lstBrokerContact.isEmpty()){
                updateBrokerCommissionOnQuote = true;
                for(Broker_Account__c objBroker: cloneBrokerAcc){
                    if(objBroker.Broker_Contact__r.Account.Name == 'Citynet Insurance Brokers Limited t/as Cobra London Markets'){
                        objBroker.Broker_Contact__c = lstBrokerContact[0].Id;
                    }
                }
            }
        }

        if(!cloneBrokerAcc.isEmpty()){
            insert cloneBrokerAcc;
        }        
    }

    public static List<Quote> cloneQuoteRenewal(List<Quote> quotes){
        List<Quote> clonedQuoteList = new List<Quote>();
        
        if(quotes.isEmpty()){
            return clonedQuoteList;
        }
        
         for(Quote quo: quotes){
            Quote quoteClone = quo.clone(false, true, false, false);
            String quoteName = quo.Name;
            string quoteCloneName = quoteName.substringBefore(' PI ');
            String quoteLayerCountFromQuote = quoteName.right(1);            
            quoteClone.Parent_Quote__c = quo.Id;
            quoteClone.Effective_Date__c = quo.ExpirationDate + 1;
            quoteClone.Name = quoteCloneName + ' PI ' + quoteClone.Effective_Date__c.format() +' '+ quoteClone.Layer__c +' '+quoteLayerCountFromQuote;
            quoteClone.ExpirationDate = quo.ExpirationDate.addDays(365);
            clonedQuoteList.add(quoteClone);
        }
        return clonedQuoteList;
    }

    public static void cloneQuoteRenewalRelatedRecords(List<String> quoteIdList, Map<String,String> parentQuoteIdToClonedQuoteIdMap, String clonedOppId){
        
        // Clone Insurer Layer Limit 
        List<Insurer_Layer_Limit__c> clonedInsurerList = new List<Insurer_Layer_Limit__c>();
        List<Insurer_Layer_Limit__c> insurerList = [SELECT Id, Name, Insurer__c, Insurer_Layer_Limit__c,
                                                    Insurer_Policy_Number__c,Layer__c,Quote__c
                                                    FROM Insurer_Layer_Limit__c 
                                                    WHERE Quote__c IN: quoteIdList];
        for(Insurer_Layer_Limit__c insurer : insurerList) {
            Insurer_Layer_Limit__c insurerClone = insurer.clone(false, true, false, false);
            insurerClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(insurer.Quote__c);
            clonedInsurerList.add(insurerClone);
        }
        
        if(!clonedInsurerList.isEmpty()){
            insert clonedInsurerList;
        }
        
        // Clone CoveragesLine Item List
        List<CoveragesLineItem__c> clonedCovLineItemList = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> covLineItem = [SELECT Id, Coverage__c, Sub_Coverage__c, Limits_Deductibles__c, Coverage_product__c,
                                                  Coverage_Premium__c,Deductible_Frequency__c, Options_Value_Percent__c,
                                                  Increment_Step__c, IsIncluded__c, Max_amt__c, Min_amt__c, Page_Section__c,
                                                  Option_Picklist__c,Option_Type__c,Option_Value__c,Override_Premium__c,
                                                  Option_Value_Default__c, Notes__c, Form_Number__c,Quote__c,
                                                  Coverage_Effective_Date__c, Group__c                                                   
                                                  FROM CoveragesLineItem__c 
                                                  WHERE Quote__c IN: quoteIdList];
        for(CoveragesLineItem__c cli : covLineItem) {
            CoveragesLineItem__c cliClone = cli.clone(false, true, false, false);
            cliClone.Parent_Coverages_Line_Item__c = cli.Id;
            cliClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(cli.Quote__c);
            clonedCovLineItemList.add(cliClone);
        }
        
        if(!clonedCovLineItemList.isEmpty()){
            insert clonedCovLineItemList;
        }
        
        //Clone Location
        Map<Id, Quote_Location__c> quoLocCloneMap = new Map<Id, Quote_Location__c>();  
        for(Quote_Location__c ql : [SELECT Id,Quote__c,Locations__c,Usage_Type__c,OriginCreation__c,Primary_Location__c,Nickname__c
                                    FROM Quote_Location__c 
                                    WHERE Quote__c IN :quoteIdList]) {
                                        Quote_Location__c qlClone = ql.clone(false, true, false, false);
                                        qlClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(ql.Quote__c);
                                        quoLocCloneMap.put(ql.Id, qlClone);
                                    }
        if(!quoLocCloneMap.isEmpty()) insert quoLocCloneMap.values();
        
        
        
        //Clone Free form endorsements
        List<Free_Form_Endorsements__c> clonedFreeFormEndList = new List<Free_Form_Endorsements__c>();
        List<Free_Form_Endorsements__c> freeFormEnd = [SELECT Id, Name, Quote__c, Form_Number__c, Endorsement_Name__c, Endorsement_Wording__c, 
                                                       Coverage_Effective_Date__c FROM Free_Form_Endorsements__c 
                                                       WHERE Quote__c IN: quoteIdList];
        for(Free_Form_Endorsements__c ffe : freeFormEnd) {
            Free_Form_Endorsements__c ffClone = ffe.clone(false, true, false, false);
            ffClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(ffe.Quote__c);
            clonedFreeFormEndList.add(ffClone);
        }
        
        
        if(!clonedFreeFormEndList.isEmpty()){
            insert clonedFreeFormEndList;
        }
        
        //Clone Rating Modifier Factor
        List<Rating_Modifier_Factor__c> cloneRatingModifierFactorsList = new List<Rating_Modifier_Factor__c>();
        List<Rating_Modifier_Factor__c> ratingModifierFactors = [SELECT CreatedById, Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                                                                 Factor_Value__c, LastModifiedById, Rating_Modifier__c, Quote__c,
                                                                 Rating_Modifier__r.Rating_Modifier_Code__c
                                                                 FROM Rating_Modifier_Factor__c 
                                                                 WHERE Quote__c IN: quoteIdList];
        Map<String, Rating_Modifiers__c> newRateModCodeToObjMap = new Map<String, Rating_Modifiers__c>();
        List<Rating_Modifiers__c> ratingModOnClonedOppList = [SELECT Id, Opportunity__c, Rating_Modifier_Code__c
                                                              FROM Rating_Modifiers__c 
                                                              WHERE Opportunity__c =: clonedOppId];
        
        for(Rating_Modifiers__c newRatM : ratingModOnClonedOppList){
            newRateModCodeToObjMap.put(newRatM.Rating_Modifier_Code__c, newRatM);
        }
        
        for(Rating_Modifier_Factor__c rati : ratingModifierFactors) {
            Rating_Modifier_Factor__c cloneRMF = rati.clone(false, true, false, false);
            cloneRMF.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(rati.Quote__c);
            cloneRMF.Rating_Modifier__c = newRateModCodeToObjMap.get(rati.Rating_Modifier__r.Rating_Modifier_Code__c).Id;
            cloneRatingModifierFactorsList.add(cloneRMF); 
        }
        
        Set<String> setOfClonedQuoteIds = new Set<String>();
        for(String strOldQuoteId: parentQuoteIdToClonedQuoteIdMap.keySet()){
            setOfClonedQuoteIds.add(parentQuoteIdToClonedQuoteIdMap.get(strOldQuoteId));
        }
        
        if(!cloneRatingModifierFactorsList.isEmpty()){
            List<Rating_Modifier_Factor__c> deleteRMFs = [SELECT Id, Name FROM Rating_Modifier_Factor__c WHERE Quote__c IN: setOfClonedQuoteIds];
            delete deleteRMFs;
            insert cloneRatingModifierFactorsList;
        }

        //Clone Quote Options
        List<Quote_Option__c> lstClonedQuoteOptions = new List<Quote_Option__c>();
        Map<String,Quote_Option__c> mappreviousQO = new Map<String,Quote_Option__c>();
        for(Quote_Option__c objQO : [SELECT Id, Quote__c, Quote__r.Layer__c, Actual_Premium_Annual__c, Actual_Premium_Final__c, 
                                        Book_Premium__c, Broker_Netted_Down_Premium_Annual__c, 
                                        Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c, 
                                        Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c,
                                        Broker_Netted_Down_Premium_Final__c, Fee_Annual__c, Fee_Final__c, 
                                        Final_Discretion__c, Limit__c, Minimum_Premium__c, Price_Adequacy__c, 
                                        Technical_Premium__c, Technical_Premium_Discretion__c, 
                                        Selected__c, Bound__c, Option_Type__c, Final_Technical_Premium__c,
                                        Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c,
                                        Technical_Fee__c,IPT__c,Total_Cost_To_Client__c, Actual_Premium__c,
                                        Broker_Netted_Down_Premium__c, Fee__c, IPT_on_Broker_Netted_Down_Premium__c,
                                        NonProrated_Actual_Premium__c, NonProRated_BNDP__c FROM Quote_Option__c
                                        WHERE Quote__c IN: quoteIdList AND Bound__c = true]){
                                            System.debug('objQO'+objQO);
                                            mappreviousQO.put(objQO.Quote__c,objQO);

        }

        if(!mappreviousQO.isEmpty()){

            for(String quoteId : mappreviousQO.KeySet()){

                Quote_Option__c objQO = mappreviousQO.get(quoteId);
                String newQuoteId = parentQuoteIdToClonedQuoteIdMap.get(quoteId);
                Integer count;
                if(objQO.Quote__r.Layer__c == 'Primary'){
                    count = 10;
                    lstClonedQuoteOptions.addAll(CloneServiceHandler_Common.createQuoteOptions(count,newQuoteId,'Fixed Limit'));
                    Quote_Option__c objQuoteOption = objQO.clone(false, true, false, false);
                    objQuoteOption.Quote__c = newQuoteId;
                    objQuoteOption.Option_Type__c = 'Free Form';
                    lstClonedQuoteOptions.add(objQuoteOption);
                }
                else{
                    count = 6;
                    lstClonedQuoteOptions.addAll(CloneServiceHandler_Common.createQuoteOptions(count,newQuoteId,'Fixed Limit'));
                    Quote_Option__c objQuoteOption = objQO.clone(false, true, false, false);
                    objQuoteOption.Quote__c = newQuoteId;
                    objQuoteOption.Option_Type__c = 'Free Form';
                    lstClonedQuoteOptions.add(objQuoteOption);
                }
            }
        }
        
        if(!lstClonedQuoteOptions.isEmpty()){
            insert lstClonedQuoteOptions;
        }
    }

    public static NewEndorsementAQController.ResultWrapper coverageCancelProcess(set<Id> quoteId,string selectedId,string policyId){
        NewEndorsementAQController.ResultWrapper resResult = new NewEndorsementAQController.ResultWrapper();
        system.debug('quoteId-->'+quoteId+'selectedId-->'+selectedId);
        string oppId;
        Savepoint sp = Database.setSavepoint();
        try{
            List<Quote> quoteListToClone = CloneQueryUtil.queryCoverageCancelQuoteAQ(quoteId);//Correction
            List<Quote> clonedQuoteList = new List<Quote>();
            //List<Quote> clonedQuoteListInProgress = new List<Quote>();
            List<String> quoteIdList = new List<String>(); //Ids of orignal quotes which were cloned (Renewal)

            if(!quoteListToClone.isEmpty()){
                clonedQuoteList = cloneQuoteCancelCoverage(quoteListToClone);
            }
            
            if(!quoteListToClone.isEmpty()){
                oppId = quoteListToClone[0].OpportunityId;
            }
            List<Quote> lstQuote = [Select Id,QuoteNumber,Quote_Type__c,Binder__c,Master_Binder__c,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, 
                                    Azure_Id__c,Rating_Status__c,Layer__c from Quote where Policy__c=:policyId And Status='Bound' 
                                    AND Opportunity.RecordType.Name =: 'Aqueous' And Rating_Status__c='Clear' And Binder__c!=null
                                    order by Endorsement_Quote_Bound_Date__c desc limit 1];
            List<Master_Binder__c> masterBinder = new List<Master_Binder__c>();
            if(lstQuote.size()>0 && lstQuote[0].Quote_Type__c=='Renewal'){
                  masterBinder = [select id,MGA_Commission__c from Master_Binder__c where id=:lstQuote[0].Master_Binder__c];

            }
            for(Quote newQuote: clonedQuoteList){  
                newQuote.Quote_Type__c = 'Correction';
                newQuote.Status = 'Correction';
                newQuote.Endorsement_Effective_Date__c = date.today();
                newQuote.Endorsement_Quote_Bound_Date__c = date.today();
                newQuote.MGA_Commission__c = masterBinder.size() > 0 ?  masterBinder[0].MGA_Commission__c : newQuote.MGA_Commission__c ;
                if(newQuote.QuotePremium__c != null) newQuote.QuotePremium__c =  -1 * newQuote.QuotePremium__c;
                if(newQuote.Actual_Premium__c != null) newQuote.Actual_Premium__c =  -1 * newQuote.Actual_Premium__c;
                if(newQuote.Broker_Netted_Down_Premium__c != null) newQuote.Broker_Netted_Down_Premium__c =  -1 * newQuote.Broker_Netted_Down_Premium__c;
                if(newQuote.Total_Cost_to_Client__c != null) newQuote.Total_Cost_to_Client__c =  -1 * newQuote.Total_Cost_to_Client__c;
                if(newQuote.Fee__c != null) newQuote.Fee__c =  -1 * newQuote.Fee__c;   
                if(newQuote.IPT_on_Broker_Netted_Down_Premium__c != null) newQuote.IPT_on_Broker_Netted_Down_Premium__c =  -1 * newQuote.IPT_on_Broker_Netted_Down_Premium__c;   
            }
            
            if(!clonedQuoteList.isEmpty()){
                GlobalStaticVar.byPassQuoteTrigger = true;
                GlobalStaticVar.byPassFreeFormEndorsementTrigger = true;
                GlobalStaticVar.byPassSubjectivityTrigger = true;
                insert clonedQuoteList;
            }
            system.debug('clonedQuoteList-->'+clonedQuoteList);
            
            ResultResponse response = new ResultResponse();
            Map<String, Object> QuotefieldMap = new Map<String, Object>();
            QuotefieldMap.put('Endorsement_Effective_Date__c', date.today());
            QuotefieldMap.put('Fee__c', 0);
            QuotefieldMap.put('Policy__c', string.valueOf(policyId));
            QuotefieldMap.put('Quote_Action__c', 'CancelAndReplace');
            response = CloneServiceHandler_Common.cloneQuoteWithChildren(String.valueOf(selectedId),QuotefieldMap);
            
            Quote quoteClone = (Quote)response.data;
            resResult.cloneQuoteId = quoteClone.Id;

            if(quoteClone == null){
      			resResult.error = response.errors[0];
                return resResult;
            } 
            Change_Log__c changelog = CommonUtil.createChangeLog(policyId,'Coverage Cancel & Replace', null);
            if(changelog != null){
                insert changelog;
            }
            //Delete Referrals
            List<Referral_Reason__c> referralReasonsList = [select Id From Referral_Reason__c  WHERE Quote__c =: quoteClone.Id];
            if(!referralReasonsList.isEmpty()) delete referralReasonsList;
            
            
            //Create Quote Option
           // QuoteTriggerHandler.addQuoteOptions(clonedQuoteListInProgress);
            
        }catch (DMLException ex){
            Database.rollback(sp);
            resResult.error = ex.getDmlMessage(0);
            return resResult;
        }catch(exception ex){
            Database.rollback(sp);
            system.debug('error: '+ex.getMessage()+' '+ex.getLineNumber());
            resResult.error = ex.getMessage();
            return resResult;
        }
        
        resResult.oppId = oppId;
        return resResult;
    }

    public static List<Quote> cloneQuoteCancelCoverage(List<Quote> quotes){
        List<Quote> clonedQuoteList = new List<Quote>();
        
        if(quotes.isEmpty()){
            return clonedQuoteList;
        }

        for(Quote quo: quotes){
            Quote quoteClone = quo.clone(false, true, false, false);
            quoteClone.Quote_Type__c = quo.Quote_Type__c;
            quoteClone.Parent_Quote__c = quo.Id;
            quoteClone.OpportunityId = quo.OpportunityId;
            quoteClone.Policy__c = quo.Policy__c;
            clonedQuoteList.add(quoteClone);
        }
        return clonedQuoteList;
    }

}