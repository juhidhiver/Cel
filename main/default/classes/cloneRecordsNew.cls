/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 10-21-2021
 * @last modified by  : Maeran Shaikh
**/
//complete class Added by Ravi
public with sharing  class cloneRecordsNew {
	 public static NewEndorsementController.ResultWrapper coverageCancelProcess(set<Id> quoteId,string selectedId,string policyId){
        NewEndorsementController.ResultWrapper resResult = new NewEndorsementController.ResultWrapper();
        system.debug('quoteId-->'+quoteId+'selectedId-->'+selectedId);
        string oppId;
        Savepoint sp = Database.setSavepoint();
        try{
            List<Quote> quoteListToClone = queryCoverageCancelQuote(quoteId);//Correction
            List<Quote> clonedQuoteList = new List<Quote>();
            //List<Quote> clonedQuoteListInProgress = new List<Quote>();
            List<String> quoteIdList = new List<String>(); //Ids of orignal quotes which were cloned (Renewal)

            if(!quoteListToClone.isEmpty()){
                clonedQuoteList = cloneQuoteCancelCoverage(quoteListToClone);
            }
            
            if(!quoteListToClone.isEmpty()){
                oppId = quoteListToClone[0].OpportunityId;
            }
            
            for(Quote newQuote: clonedQuoteList){  
                newQuote.Quote_Type__c = 'Correction';
                newQuote.Status = 'Correction';
                newQuote.Endorsement_Effective_Date__c = date.today();
                if(newQuote.QuotePremium__c != null) newQuote.QuotePremium__c =  -1 * newQuote.QuotePremium__c;
                if(newQuote.Actual_Premium__c != null) newQuote.Actual_Premium__c =  -1 * newQuote.Actual_Premium__c;
                if(newQuote.Broker_Netted_Down_Premium__c != null) newQuote.Broker_Netted_Down_Premium__c =  -1 * newQuote.Broker_Netted_Down_Premium__c;
                if(newQuote.Total_Cost_to_Client__c != null) newQuote.Total_Cost_to_Client__c =  -1 * newQuote.Total_Cost_to_Client__c;
                if(newQuote.Fee__c != null) newQuote.Fee__c =  -1 * newQuote.Fee__c;  
                //Added by Ravi
                if(newQuote.Technical_Premium__c != null) newQuote.Technical_Premium__c =  -1 * newQuote.Technical_Premium__c;  
                // if(newQuote.Transaction_Premium__c != null) newQuote.Transaction_Premium__c =  -1 * newQuote.Transaction_Premium__c;  
                // if(newQuote.Total_Premium__c != null) newQuote.Total_Premium__c =  -1 * newQuote.Total_Premium__c; 
                if(newQuote.Non_prorated_Total_Premium__c != null) newQuote.Non_prorated_Total_Premium__c =  -1 * newQuote.Non_prorated_Total_Premium__c;
                if(newQuote.Non_Prorated_Quote_Premium__c != null) newQuote.Non_Prorated_Quote_Premium__c =  -1 * newQuote.Non_Prorated_Quote_Premium__c;
            }
            
            if(!clonedQuoteList.isEmpty()){
                GlobalStaticVar.byPassQuoteTrigger = true;
                GlobalStaticVar.byPassFreeFormEndorsementTrigger = true;
                GlobalStaticVar.byPassSubjectivityTrigger = true;
                insert clonedQuoteList;
            }
            system.debug('clonedQuoteList-->'+clonedQuoteList);
            
            //Containers with quote Ids for further use in quote related record cloning
            Map<String,String> parentQuoteIdToClonedQuoteIdMap = new Map<String,String>();
            for(Quote quo :clonedQuoteList){
                parentQuoteIdToClonedQuoteIdMap.put(quo.Parent_Quote__c,quo.Id);                
                quoteIdList.add(quo.Parent_Quote__c);
            }
            
            system.debug('quoteIdList-->'+quoteIdList);
            //clone quote related records
            // cloneQuoteRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap,null);
            cloneCoverageListForQuotes(quoteIdList, parentQuoteIdToClonedQuoteIdMap);
            
            ResultResponse response = new ResultResponse();
            Map<String, Object> QuotefieldMap = new Map<String, Object>();
            QuotefieldMap.put('Endorsement_Effective_Date__c', date.today());
            QuotefieldMap.put('Fee__c', 0);
            QuotefieldMap.put('Policy__c', string.valueOf(policyId));
            QuotefieldMap.put('Quote_Action__c', 'CancelAndReplace');// Added for US: 53646
            response = CloneQuoteHandlerCelerity.cloneQuoteWithChildren(String.valueOf(selectedId),QuotefieldMap);
            if(response!= null){
                Quote quoteClone = (Quote)response.data;
                
                if(quoteClone == null){
                    resResult.error = response.errors[0];
                    return resResult;
                } 
                
                //Delete Referrals
                List<Referral_Reason__c> referralReasonsList = [select Id From Referral_Reason__c  WHERE Quote__c =: quoteClone.Id];
                if(!referralReasonsList.isEmpty()) delete referralReasonsList;
                
            }
                        
            
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
    public static List<Quote> queryCoverageCancelQuote(Set<Id> quoteId){
        List<Quote> quoteList = [Select Id,Commission_percentage__c,OpportunityId, Effective_Date__c, QuoteNumber, ExpirationDate,
                                           AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                                           Quote_Type__c, Name, Status, Rating_Status__c,Tax,Commission__c, Override_Premium__c, 
                                           Override_Premium_Percentage__c,Parent_Quote__c, IPID_Document__c,Policy_Wording_Document__c,
                                           Technical_Premium__c,QuotePremium__c,Total_Premium__c,CloseDate__c,Accept_Terror_Premium__c,
                                           Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c, Special_Coverages__c,
                                           Parent_Quote__r.Non_Prorated_Quote_Premium__c,Parent_Quote__r.QuotePremium__c,
                                           Broker__r.Account.Azure_ID__c, Broker__r.Azure_ID__c,Broker__r.Id,
                                           Endorsement_Quote_Bound_Date__c,Broker__r.Name,Broker__r.Account.Name,                            
                                           Endorsement_Reason__c,Endorsement_Reason_Other__c, Override_Actual_Premium_Percent__c, 
                                           Override_Fee_Percent__c, Override_Actual_Excess_Percent__c, Technical_Fee__c,
                                           OverrideBrokerNettedDownPremiumPercent__c,As_if_Book_Rated_Premium_rate_change__c,
                                           Actual_Excess__c, Actual_Premium__c, Binder__c, Policy__c,Master_Binder__c,
                                           Book_Excess__c, Book_Premium__c, Book_Rated_Premium__c, Broker_Commission__c, 
                                           Broker_Netted_Down_Premium__c, Discretion__c, Excess_Basis__c, Fee__c, Final_Discretion__c, 
                                           IPT_on_Broker_Netted_Down_Premium__c, Jurisdiction_Limits__c, Layer__c, Limit_Basis__c, 
                                           MGA_Commission__c, Minimum_Premium__c, Netted_Down_Premium_Broker_Commission__c, 
                                           Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c,PI_Limit_of_Indemnity__c, 
                                           Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, 
                                           Previous_Year_Final_Discretion__c, Previous_Year_Exposure__c, Price_Adequacy__c, 
                                           Rate__c, Rateable_Exposure__c, RetroDate__c,Technical_Premium_Discretion__c, 
                                           Retroactive_Date__c, Revised_Broker_Commission__c, Revised_MGA_Commission__c, 
                                           Territorial_Limits__c, Total_Underlying_Layer__c,Rate_Change__c,Total_Cost_to_Client__c,Product_Name__c
                                           FROM Quote 
                                           WHERE Id IN: quoteId];
        return quoteList;
    }

    public static List<Quote> cloneQuoteCancelCoverage(List<Quote> quotes){
        List<Quote> clonedQuoteList = new List<Quote>();
        
        if(quotes.isEmpty()){
            return clonedQuoteList;
        }

        for(Quote quo: quotes){
           {
                Quote quoteClone = quo.clone(false, true, false, false);
                quoteClone.Quote_Type__c = quo.Quote_Type__c;
                quoteClone.Parent_Quote__c = quo.Id;
                quoteClone.OpportunityId = quo.OpportunityId;
                quoteClone.Policy__c = quo.Policy__c;
                clonedQuoteList.add(quoteClone);
            }
        }
        return clonedQuoteList;
    }
    
         public static void cloneCoverageListForQuotes(List<String> quoteIdList, Map<String,String> parentQuoteIdToClonedQuoteIdMap){
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

             
         }
    public static void cloneQuoteRelatedRecords(List<String> quoteIdList, Map<String,String> parentQuoteIdToClonedQuoteIdMap, Id clonedOppId){
        //Clone referral reasons
        List<Referral_Reason__c> clonedReferralReasonsList = new List<Referral_Reason__c>();
        List<Referral_Reason__c> referralReasonsList = [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,Approval_Rejected_Date__c,
                                                        Approver_Level__c,Approved_By__c, Entity_Path__c,Reason__c,Reason_Type__c,Status__c,
                                                        Approved_By__r.Name, Quote__c,Is_Auto_Approved__c
                                                        From Referral_Reason__c 
                                                        WHERE Quote__c IN: quoteIdList];
        for(Referral_Reason__c reason : referralReasonsList) {
            Referral_Reason__c reasonClone = reason.clone(false, true, false, false);
            reasonClone.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(reason.Quote__c);
            clonedReferralReasonsList.add(reasonClone);
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
            List<Rating_Modifier_Factor__c> deleteRMFs = [SELECT Id, Name FROM Rating_Modifier_Factor__c WHERE Quote__c IN: quoteIdList];
            delete deleteRMFs;
            insert cloneRatingModifierFactorsList;
        }

        //Clone Quote Options
        List<Quote_Option__c> lstClonedQuoteOptions = new List<Quote_Option__c>();
        List<Quote_Option__c> lstPreviousQuoteOptions = [SELECT Id, Quote__c, Actual_Premium_Annual__c, Actual_Premium_Final__c, 
                                                        Book_Premium__c, Broker_Netted_Down_Premium_Annual__c, 
                                                        Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c, 
                                                        Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c,
                                                        Broker_Netted_Down_Premium_Final__c, Fee_Annual__c, Fee_Final__c, 
                                                        Final_Discretion__c, Limit__c, Minimum_Premium__c, Price_Adequacy__c, 
                                                        Technical_Premium__c, Technical_Premium_Discretion__c, 
                                                        Selected__c, Bound__c, Option_Type__c, Final_Technical_Premium__c,
                                                        Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c,
                                                        Technical_Fee__c,IPT__c,Total_Cost_To_Client__c, Actual_Premium__c,
                                                        Broker_Netted_Down_Premium__c, Fee__c, IPT_on_Broker_Netted_Down_Premium__c FROM Quote_Option__c
                                                        WHERE Quote__c IN: quoteIdList];
        for(Quote_Option__c objQuoteOption : lstPreviousQuoteOptions) {
            Quote_Option__c objClonedQuoteOption = objQuoteOption.clone(false, true, false, false);
            objClonedQuoteOption.Quote__c = parentQuoteIdToClonedQuoteIdMap.get(objQuoteOption.Quote__c);
            lstClonedQuoteOptions.add(objClonedQuoteOption);
        }
        
        if(!lstClonedQuoteOptions.isEmpty()){
            insert lstClonedQuoteOptions;
        }
    } 
    public static Opportunity cloneOpportunityDetails(Opportunity opp) {
        Opportunity result = new Opportunity();
        result = opp.clone(false, true, false, false);
        return result;
    }
        public static void cloneOppRelatedRecords(String oldOppId, Opportunity clonedOpp){//(newOppId,OldOppId)
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
    Public static List<Quote> cloneQuote(List<Quote> quotes){
        List<Quote> clonedQuoteList = new List<Quote>();
        
        if(quotes.isEmpty()){
            return clonedQuoteList;
        }
        
        for(Quote quo: quotes){
            {
                    Quote quoteClone = quo.clone(false, true, false, false);
                    quoteClone.Parent_Quote__c = quo.Id;
                    clonedQuoteList.add(quoteClone);
               }
        }
        return clonedQuoteList;
    }
    
}