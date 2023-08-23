//Complete Class Added By Ravi
public with sharing class CloneQuoteHandlerCelerity {
    /**
     * Method name : cloneWithChildren
     * Arguments   : Id quoteId - the id of the record Quote whose name needs to be clone
     *              Map<String,Object> fieldUpdateMap
     * Return type : String
     * Description : Clones parent Quote and child records
     * Revisions: Hoang Bui - 28-May-20
    **/
    @AuraEnabled
    public static ResultResponse cloneQuoteWithChildren(String quoteId, Map<String,Object> fieldUpdateMap) {
        Savepoint sp;
        ResultResponse response = new ResultResponse();
		//String productName;
        //QuoteUtil.NewQuoteResponseWrapper resultWrap = new QuoteUtil.NewQuoteResponseWrapper();
        try{
            // Get Quote 
            List<Quote> quotes = [SELECT Id,Name,AccountId,Master_Binder__c,Opportunity.Product_Name__c,OpportunityId,Effective_Date__c,ExpirationDate,CloseDate__c,Product_Name__c,
                                  Quote_Type__c,Status,Declined_Reason__c,Policy__c,Celerity_Technical_Premium__c,Policy_Wording_ContentDoc_Id__c,
                                  Rating_Status__c,UW_Reason__c,Commission__c,Commission_percentage__c,Tax,Policy_Wording_Document__c,
                                  Total_Premium__c,Endorsement_Effective_Date__c,Coverage_Product_Options__c, Opportunity.StageName,
                                  Broker_Commission__c,MGA_Commission__c,Layer__c,Retroactive_Date__c,IPID_ContentDoc_Id__c,
                                  Territorial_Limits__c,Jurisdiction_Limits__c,Limit_Basis__c,Excess_Basis__c,Binder__c,IPID_Document__c,
                                  Book_Excess__c, Actual_Excess__c,PI_Limit_of_Indemnity__c,Book_Rated_Premium__c,Rate__c,
                                  Minimum_Premium__c,Book_Premium__c,Technical_Premium__c,Technical_Premium_Discretion__c,
                                  Actual_Premium__c, Final_Discretion__c, Price_Adequacy__c,Rate_Change__c,As_if_Book_Rated_Premium_rate_change__c,
                                  Fee__c,Broker_Netted_Down_Premium__c,RetroDate__c, Discretion__c, IPT_on_Broker_Netted_Down_Premium__c, 
                                  Netted_Down_Premium_Broker_Commission__c, Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c, 
                                  Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, Previous_Year_Final_Discretion__c, 
                                  Previous_Year_Exposure__c, Rateable_Exposure__c, Revised_Broker_Commission__c,Broker__c,
                                  Revised_MGA_Commission__c, Total_Underlying_Layer__c, 
                                  Primary_Premium_Actual__c, Underlying_Excess_Attachment__c, Underlying_Excess_Premium__c 
                                  FROM Quote 
                                  WHERE Id =: quoteId and Quote_Type__c !='Midterm Cancellation'  and Quote_Type__c !='Flat Cancellation'  LIMIT 1]; //Technical_Premium__c, QuotePremium__c, Override_Premium__c, //comment by Hai 23 Jun 2020
            if(quotes.isEmpty()) {
                return null;
            }
  
            System.debug('CloneQuoteHandlerClerity quotes ::'+quotes);
            Quote quoteClone = quotes[0].clone(false, true, false, false);
            quoteClone.Status = 'In Progress';
            quoteClone.Rating_Status__c = '';
            quoteClone.UW_Reason__c = '';
            quoteClone.Overall_UW_Codes__c = '';
            quoteClone.OpportunityId = quotes[0].OpportunityId;            
            quoteClone.Parent_Quote__c = quotes[0].Id;
            
            if(quotes[0].Product_Name__c == 'Professional Indemnity'){
                quoteClone.Master_Binder__c = quotes[0].Master_Binder__c;
            }

            // set value for field Quote
            if(fieldUpdateMap != null && !fieldUpdateMap.isEmpty()) {
                // set value for field Quote
                for(String key : fieldUpdateMap.keySet()) {
                    if(key == 'Contract_Cancellation_Reason__c') continue;  // 04-25-2019 Long Ly Endorsement updates required
                    quoteClone.put(key, fieldUpdateMap.get(key));
                }
            }

            if(fieldUpdateMap != null && !fieldUpdateMap.isEmpty()) {
                Date effectiveDtScreen = null;                
                if(fieldUpdateMap.containsKey('Endorsement_Effective_Date__c')) 
                    effectiveDtScreen = (Date)fieldUpdateMap.get('Endorsement_Effective_Date__c');
 
                // get Value Quote_Type
                if(fieldUpdateMap.containsKey('Quote_Type__c')) {
                    String quoteType = (String)fieldUpdateMap.get('Quote_Type__c');
                    switch on quoteType {
                        when 'Extension' {
                            if(effectiveDtScreen != null) {
                                quoteClone.ExpirationDate = effectiveDtScreen;
                                quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                            }
                        }
                        when 'Midterm Cancellation' {
                            if(effectiveDtScreen != null) quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                        }
                        when 'Flat Cancellation' {
                            if(effectiveDtScreen != null) quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                        }
                        /*when 'Flat Cancellation (Ab - Initio)'{
                            if(effectiveDtScreen != null) quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                        }*/
                        when 'Reinstatement' {
                            if(effectiveDtScreen != null) quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                        }
                        when else {

                        }
                    }
                }
            } else {//01-Jun-20 Hoang added to check for case click clone Quote only
                if (quoteClone.Opportunity.StageName == 'Closed Won'){
                    if(quoteClone.Opportunity.Product_Name__c == 'Professional Indemnity'){
                        quoteClone.Quote_Type__c = 'New Business';
                    }else{
                        quoteClone.Quote_Type__c = 'Amendment';
                    }
                    
                }
            }
            
            // Create a savepoint
            sp = Database.setSavepoint();
            insert quoteClone;
            
            // Clone Quote Location List
            // Create Map with key: quote location Id and value: Quote Location Cloned
            Map<Id, Quote_Location__c> quoLocCloneMap = new Map<Id, Quote_Location__c>();

			// Create Map with key: quote location Id and value: Quote Location Cloned
            Map<Id, Quote_Location__c> quoLocCloneforScheduledPropertyMap = new Map<Id, Quote_Location__c>();

            for(Quote_Location__c ql : [SELECT Id,Quote__c,Locations__c,Usage_Type__c,OriginCreation__c,Primary_Location__c,Nickname__c
                                        FROM Quote_Location__c 
                                        WHERE Quote__c =: quotes[0].Id]) {
                Quote_Location__c qlClone = ql.clone(false, true, false, false);
                qlClone.Quote__c = quoteClone.Id;
                quoLocCloneMap.put(ql.Id, qlClone);
            }
            if(!quoLocCloneMap.isEmpty()) insert quoLocCloneMap.values();
            
  
            // 04-25-2019 Quang Pham Endorsement updates required Add Start
            // Clone Additional Interest
            List<Additional_Interests__c> additionalInterests = new List<Additional_Interests__c>();
            for(Additional_Interests__c ai : [SELECT Id,Additional_Interest_Account__c,Quote__c,Relationship_Type__c,
                                                Entity_Type__c,Loan_Reference_number__c, Loss_Payee_Interest__c,Primary_Mortgage_Servicer__c //07-05-19 Duy Tran
                                            FROM Additional_Interests__c 
                                            WHERE Quote__c =: quotes[0].Id]) {
                Additional_Interests__c aiClone = ai.clone(false, true, false, false);
                aiClone.Quote__c = quoteClone.Id;
                aiClone.Parent_Additional_Interest__c = ai.Id;
                additionalInterests.add(aiClone);
            }
            if(!additionalInterests.isEmpty()) insert additionalInterests;
            system.debug('additionalInterests@@@' + additionalInterests);
            
            //Clone Referral Reasons only for Aqueous
            if(quotes[0].Product_Name__c == 'Professional Indemnity'){
                List<Referral_Reason__c> referralReasonsList = new List<Referral_Reason__c>();
                for(Referral_Reason__c reason : [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,Approval_Rejected_Date__c,Approver_Level__c,Approved_By__c,
                                                 Entity_Path__c,Reason__c,Reason_Type__c,Status__c,Approved_By__r.Name,Is_Auto_Approved__c,
                                                 Quote_Option__c,Option_Type__c,Option_Limit__c 
                                                 From Referral_Reason__c 
                                                 WHERE Quote__c =: quotes[0].Id]) {
                   Referral_Reason__c reasonClone = reason.clone(false, true, false, false);
                   reasonClone.Quote__c = quoteClone.Id;
                   referralReasonsList.add(reasonClone);
                }
                if(!referralReasonsList.isEmpty()) insert referralReasonsList;
            	system.debug('referralReasonsList@@@' + referralReasonsList);
            }
            
            // 16-Jun-2020 tuan.d.nguyen add clone subjectivity
            // Clone Subjectivity
            List<Subjectivity__c> subjectivities = new List<Subjectivity__c>();
            for(Subjectivity__c sub : [SELECT Id, Name, Due_Date__c, Quote__c, Stage__c,
                                            Subjectivity__c, Subjectivity_Status__c, Subjectivity_Type__c,
                                            Cleared__c,Subjectivity_Text__c, Subjectivity_Template__c,
                                       		Cleared_Date__c
                                        FROM Subjectivity__c 
                                        WHERE Quote__c =: quotes[0].Id]) {
                Subjectivity__c subClone = sub.clone(false, true, false, false);
                subClone.Quote__c = quoteClone.Id;
                subjectivities.add(subClone);
            }
            System.debug('List subjectivities: ' + subjectivities);
            if(!subjectivities.isEmpty()) insert subjectivities;
            
             // Clone Insurer Layer Limit 
            List<Insurer_Layer_Limit__c> InsurerList = new List<Insurer_Layer_Limit__c>();
            for(Insurer_Layer_Limit__c insurer : [SELECT Id, Name, Insurer__c, Insurer_Layer_Limit__c,
                                              Insurer_Policy_Number__c,Layer__c,Quote__c
                                        FROM Insurer_Layer_Limit__c 
                                        WHERE Quote__c =: quotes[0].Id]) {
                Insurer_Layer_Limit__c insurerClone = insurer.clone(false, true, false, false);
                insurerClone.Quote__c = quoteClone.Id;
                InsurerList.add(insurerClone);
            }
            System.debug('List InsurerList: ' + InsurerList);
            if(!InsurerList.isEmpty()) insert InsurerList;


            // Clone CoveragesLine Item List
            List<CoveragesLineItem__c> covLineItemClones = new List<CoveragesLineItem__c>();
            for(CoveragesLineItem__c cli : [SELECT Id, Coverage__c, Sub_Coverage__c, Limits_Deductibles__c, Coverage_product__c,
                                                Coverage_Premium__c,Deductible_Frequency__c, Options_Value_Percent__c,
                                                Increment_Step__c, IsIncluded__c, Max_amt__c, Min_amt__c, Page_Section__c,
                                                Option_Picklist__c,Option_Type__c,Option_Value__c,Override_Premium__c,
                                                 Option_Value_Default__c,
                                                 Notes__c, Form_Number__c, //#34914-04Dec20-Khanh
                                                Coverage_Effective_Date__c, Group__c //tuan.d.nguyen added 9-Dec-2020
                    //Dwelling_Home_Value__c //long ly - 29/05 - remove unsued field
                                            FROM CoveragesLineItem__c 
                                            WHERE Quote__c =: quotes[0].Id]) {
			    CoveragesLineItem__c cliClone = cli.clone(false, true, false, false);
                cliClone.Parent_Coverages_Line_Item__c = cli.Id;
                cliClone.Quote__c = quoteClone.Id;
                covLineItemClones.add(cliClone);
            }
 
            if(!covLineItemClones.isEmpty()) insert covLineItemClones;
            system.debug('covLineItemClones@@@' + covLineItemClones);
            system.debug('quoteClone@@@' + quoteClone);
            
            //Clone Free form endorsements
            List<Free_Form_Endorsements__c> ffClones = new List<Free_Form_Endorsements__c>();
            for(Free_Form_Endorsements__c ff : [SELECT Id, Name, Quote__c, Form_Number__c, Endorsement_Name__c, Endorsement_Wording__c, 
                                                Coverage_Effective_Date__c FROM Free_Form_Endorsements__c 
                                            WHERE Quote__c =: quotes[0].Id]) {
			    Free_Form_Endorsements__c ffClone = ff.clone(false, true, false, false);
                //ffClone.Parent_Coverages_Line_Item__c = cli.Id;
                ffClone.Quote__c = quoteClone.Id;
                ffClones.add(ffClone);
            }
 
            if(!ffClones.isEmpty()) insert ffClones;
            system.debug('ffClones@@@' +ffClones);
            system.debug('quoteClone@@@' +quoteClone);
            

            //Clone Rating Modifier Factor
            List<Rating_Modifier_Factor__c> cloneRatingModifierFactors = new List<Rating_Modifier_Factor__c>();
            for(Rating_Modifier_Factor__c rati : [SELECT CreatedById, Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                                                        Factor_Value__c, LastModifiedById, Rating_Modifier__c 
                                                FROM Rating_Modifier_Factor__c 
                                                WHERE Quote__c =: quoteId]) {
                Rating_Modifier_Factor__c cloneRMF = rati.clone(false, true, false, false);
                cloneRMF.Quote__c = quoteClone.Id;
                cloneRatingModifierFactors.add(cloneRMF); 
            }
            List<Rating_Modifier_Factor__c> deleteRMFs = [SELECT Id, Name FROM Rating_Modifier_Factor__c WHERE Quote__c =: quoteClone.Id];
            delete deleteRMFs; 
            if(!cloneRatingModifierFactors.isEmpty()) insert cloneRatingModifierFactors;

            //Quote Options cloning
            List<Quote_Option__c> lstQuoteOptions = new List<Quote_Option__c>();
            for(Quote_Option__c obj : [SELECT Quote__c, Actual_Premium_Annual__c, Actual_Premium_Final__c, 
                                        Book_Premium__c, Broker_Netted_Down_Premium_Annual__c, 
                                        Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c, 
                                        Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c,
                                        Broker_Netted_Down_Premium_Final__c, Fee_Annual__c, Fee_Final__c, 
                                        Final_Discretion__c, Limit__c, Minimum_Premium__c, Price_Adequacy__c, 
                                        Technical_Premium__c, Technical_Premium_Discretion__c, 
                                        Selected__c, Bound__c, Option_Type__c, Final_Technical_Premium__c,
                                        Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c,
                                        Technical_Fee__c,IPT__c,Total_Cost_To_Client__c, Actual_Premium__c,
                                        Broker_Netted_Down_Premium__c, Fee__c, IPT_on_Broker_Netted_Down_Premium__c
                                        FROM Quote_Option__c  WHERE Quote__c =: quotes[0].Id]) {
                Quote_Option__c clonedQO = obj.clone(false, true, false, false);
                clonedQO.Quote__c = quoteClone.Id;
                lstQuoteOptions.add(clonedQO);
            }
            if(!lstQuoteOptions.isEmpty()) insert lstQuoteOptions;
            response.isSuccess = true;
            response.data = quoteClone;
            return response;
            
        } catch(Exception ex){
            System.debug('Clone error: ' + ex.getMessage() + ex.getLineNumber());
            Database.rollback(sp);
            response.isSuccess = false;
            response.errors.add(ex.getMessage());
            return response;
            // throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));
        }
    }
}