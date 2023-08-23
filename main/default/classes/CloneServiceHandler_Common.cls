/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 06-27-2022
 * @last modified by  : Vinayesh
**/
public class CloneServiceHandler_Common {

    public static List<Quote> cloneQuote(List<Quote> quotes){
        List<Quote> clonedQuoteList = new List<Quote>();
        
        if(quotes.isEmpty()){
            return clonedQuoteList;
        }
        
        for(Quote quo: quotes){
            Quote quoteClone = quo.clone(false, true, false, false);
            quoteClone.Parent_Quote__c = quo.Id;
            clonedQuoteList.add(quoteClone);
        }
        return clonedQuoteList;
    }

    public static List<Quote_Option__c> createQuoteOptions(Integer count, Id quoteId, String type){
        List<Quote_Option__c> lstQuoteOptions = new List<Quote_Option__c>();
        for(Integer i = 0 ; i < count ; i++){
            Quote_Option__c objQuoteOption = new Quote_Option__c(Quote__c = quoteId, Option_Type__c = type);
            lstQuoteOptions.add(objQuoteOption);
        }
        
        return lstQuoteOptions;
    }

    public static ResultResponse cloneQuoteWithChildren(String quoteId, Map<String,Object> fieldUpdateMap) {
        Savepoint sp;
        ResultResponse response = new ResultResponse();
        Map<String,Id> azureIdToQuoteOptionIdMap = new Map<String,Id>();
        Map<String,String> oldAzureToNewIdMap = new Map<String,String>();
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
                                  Primary_Premium_Actual__c, Underlying_Excess_Attachment__c, Underlying_Excess_Premium__c,
                                  Pending_or_Prior_Proceedings_Date__c, ERP_Duration__c, Rate_Charged__c, 
                                  RatesEffectiveDate__c, // Added by Maeran for US:52235
                                  QuotePremium__c,Surcharges__c, Non_Prorated_Quote_Premium__c, Non_prorated_Total_Premium__c, Override_Premium_Percentage__c, Quote_Action__c,// Added by Jai for US:52956
                                  Endorsement_Reason__c, // Added for #54272
                                  Collection_Fee__c,Combined_Max_Agg_Limit_of_Liability__c,Municipal_Tax__c
                                  FROM Quote
                                   
                                  WHERE Id =: quoteId LIMIT 1]; //Technical_Premium__c, QuotePremium__c, Override_Premium__c, //comment by Hai 23 Jun 2020
            if(quotes.isEmpty()) {
                return null;
            }
  
            Quote quoteClone = quotes[0].clone(false, true, false, false);
            /****** CD-163 ******/
            if(quotes[0].Product_Name__c == 'Professional Indemnity'){
                quoteClone.Quote_Action__c = '';
            }
            /****** CD-163 End ******/
            quoteClone.Status = 'In Progress';
            quoteClone.Rating_Status__c = '';
            quoteClone.UW_Reason__c = '';
            quoteClone.Overall_UW_Codes__c = '';
            quoteClone.OpportunityId = quotes[0].OpportunityId;            
            quoteClone.Parent_Quote__c = quotes[0].Id;
			quoteClone.Endorsement_Effective_Date__c = null;//-----Added by Gaurish CD-104 20th Sept
            if(fieldUpdateMap != null && !fieldUpdateMap.isEmpty() 
                && fieldUpdateMap.containsKey('Layer__c') && fieldUpdateMap.get('Layer__c') == 'Excess'){
                    quoteClone.Layer__c = 'Excess';
                    //Added by Maeran for US:53078 on 2/11/2021
                    quoteClone.Technical_Premium__c = null;
                    quoteClone.Celerity_Technical_Premium__c = quotes[0].Technical_Premium__c;
            }
            List<Opportunity> opps = new List<Opportunity>();
            if(quotes[0].Product_Name__c.contains('MPL') || quotes[0].Product_Name__c.contains('Cyber') || quotes[0].Product_Name__c == Label.Product_Name_for_PCC){
                if(quotes[0].OpportunityId != null){
                    opps = [SELECT Id, Name, StageName, Policy__c,Main_Profession__c,Largest_Work_Type__c,Product_Name__c,
                                (Select Id, Layer__c,Limit_Basis__c From Quotes Where Layer__c =: quoteClone.Layer__c ),
                                // AND  Status != 'Bound' AND Status != 'Closed' AND Status != 'Rejected'
                                Expiration_Date__c,Effective_Date__c, Type FROM Opportunity WHERE Id =: quotes[0].OpportunityId LIMIT 1];
                }
                if(!opps.isEmpty()){
                    Integer quoteCount = opps[0].Quotes.size();
                    if(fieldUpdateMap != null && !fieldUpdateMap.isEmpty() 
                        && fieldUpdateMap.containsKey('Quote_Type__c') && fieldUpdateMap.get('Quote_Type__c') == 'Renewal'){
                            quoteCount = 0;
                    }
                    quoteClone.name = (quoteClone.Layer__c == 'Primary')? opps[0].Name + ' Primary ' + (quoteCount + 1): opps[0].Name + ' Excess ' + (quoteCount + 1);   
                }
            }            

            if(quotes[0].Product_Name__c == 'Professional Indemnity'){
                quoteClone.Master_Binder__c = quotes[0].Master_Binder__c;
                if(String.isNotBlank(quoteClone.Master_Binder__c) && quoteClone.Product_Name__c == 'Professional Indemnity'){ 
                    Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(quoteClone);
                    quoteClone.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                    if(quoteClone.Layer__c != 'Excess')	quoteClone.IPID_Document__c = quoteDoc.IPID_Document__c;  	                    
                }
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
                                //quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;//-----Commented by Gaurish CD-104 17th Sept
                            }
                        }
                        when 'Flat Cancellation' { //un-commented by jai MTA-4 Sep 21
                            if(effectiveDtScreen != null) {
                                quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                                quoteClone.Effective_Date__c = effectiveDtScreen; 
                            }
                        }
                        
                        when 'Extended Reporting Period (ERP)' { 
                            if(effectiveDtScreen != null) {
                                quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                            }
                        }
                        when 'Update Insured Name or Address'{
                            quoteClone.BypassRating__c = true;
                        }
                        //commented by Jai
                        /*when 'Midterm Cancellation' {//-----Commented by Gaurish CD-104 17th Sept---START
                            if(effectiveDtScreen != null) quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                        }
                        when 'Flat Cancellation' {
                            if(effectiveDtScreen != null) quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                        }*///-----Commented by Gaurish CD-104 17th Sept----END
                        /*when 'Flat Cancellation (Ab - Initio)'{
                            if(effectiveDtScreen != null) quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                        }*/
                        /*when 'Reinstatement' {//-----Commented by Gaurish CD-104 17th Sept----START
                            if(effectiveDtScreen != null) quoteClone.Endorsement_Effective_Date__c = effectiveDtScreen;
                        }
                        when else {

                        }*///-----Commented by Gaurish CD-104 17th Sept----END
                    }
                }

                // populate Quote_Action__c
                if(fieldUpdateMap.containsKey('Quote_Action__c')) {
                    quoteClone.Quote_Action__c = (String)fieldUpdateMap.get('Quote_Action__c');
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
            
            //Quote Options cloning
            List<Quote_Option__c> lstQuoteOptions = new List<Quote_Option__c>();
            for(Quote_Option__c obj : [SELECT Quote__c,Azure_ID__c, Actual_Premium_Annual__c, Actual_Premium_Final__c, 
                                        Book_Premium__c, Broker_Netted_Down_Premium_Annual__c,Quote__r.Status, 
                                        Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c, 
                                        Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c,
                                        Broker_Netted_Down_Premium_Final__c, Fee_Annual__c, Fee_Final__c, 
                                        Final_Discretion__c, Limit__c, Minimum_Premium__c, Price_Adequacy__c, 
                                        Technical_Premium__c, Technical_Premium_Discretion__c, Quote__r.Layer__c,
                                        Selected__c, Bound__c, Option_Type__c, Final_Technical_Premium__c,
                                        Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c,
                                        Technical_Fee__c,IPT__c,Total_Cost_To_Client__c, Actual_Premium__c,
                                        Broker_Netted_Down_Premium__c, Fee__c, IPT_on_Broker_Netted_Down_Premium__c,
                                        NonProrated_Actual_Premium__c, NonProRated_BNDP__c, quote__r.Quote_Type__c
                                        FROM Quote_Option__c  WHERE Quote__c =: quotes[0].Id]) {
				String oldAzureId = obj.Azure_ID__c;    
				System.debug('obj.Quote__c->'+obj.Quote__c);
                if((quoteClone.Quote_Type__c == 'New Business' || quoteClone.Quote_Type__c == 'Renewal') && obj.Quote__r.Status == 'Bound'){
                    if(obj.Bound__c){
                        String newQuoteId = quoteClone.Id;
                        Integer count;
                        if(obj.Quote__r.Layer__c == 'Primary'){
                            count = 10;
                            lstQuoteOptions.addAll(createQuoteOptions(count,newQuoteId,'Fixed Limit'));
                            Quote_Option__c objQO = obj.clone(false, true, false, false);
                            objQO.Quote__c = newQuoteId;
                            objQO.Option_Type__c = 'Free Form';
                            objQO.Azure_ID__c = new GuidUtil().NewGuid();
                            oldAzureToNewIdMap.put(oldAzureId,objQO.Azure_ID__c);
                            lstQuoteOptions.add(objQO);
                        }
                        else{
                            count = 6;
                            lstQuoteOptions.addAll(createQuoteOptions(count,newQuoteId,'Fixed Limit'));
                            Quote_Option__c objQO = obj.clone(false, true, false, false);
                            objQO.Quote__c = newQuoteId;
                            objQO.Option_Type__c = 'Free Form';
                            objQO.Azure_ID__c = new GuidUtil().NewGuid();
                            oldAzureToNewIdMap.put(oldAzureId,objQO.Azure_ID__c);
                            lstQuoteOptions.add(objQO);
                        }
                    }
                }
                else if(quoteClone.Quote_Type__c == 'Coverage Amendment' || quoteClone.Quote_Type__c == 'Midterm Cancellation'
                    || quoteClone.Quote_Type__c == 'Flat Cancellation' || quoteClone.Quote_Type__c == 'Reinstatement'
                    || quoteClone.Quote_Type__c == 'Policy Duration Change'
                    || (obj.quote__r.Quote_Type__c == 'New Business' && obj.Quote__r.Status == 'Bound')){
                    if(obj.Bound__c){
                        Quote_Option__c clonedQO = obj.clone(false, true, false, false);
                        clonedQO.Quote__c = quoteClone.Id;
                        clonedQO.Azure_ID__c = new GuidUtil().NewGuid();
                    	oldAzureToNewIdMap.put(oldAzureId,clonedQO.Azure_ID__c);
                        lstQuoteOptions.add(clonedQO);
                    }
                }
                else{
                    Quote_Option__c clonedQO = obj.clone(false, true, false, false);
                    clonedQO.Quote__c = quoteClone.Id;
                    clonedQO.Azure_ID__c = new GuidUtil().NewGuid();
                    oldAzureToNewIdMap.put(oldAzureId,clonedQO.Azure_ID__c);
                    lstQuoteOptions.add(clonedQO);
                }
            }
            if(!lstQuoteOptions.isEmpty()) insert lstQuoteOptions;
            
            for(Quote_Option__c option : lstQuoteOptions){
                azureIdToQuoteOptionIdMap.put(option.Azure_ID__c,option.Id);
            }
            //Clone Referral Reasons only for Aqueous
            if(quotes[0].Product_Name__c == 'Professional Indemnity'){
                List<Referral_Reason__c> referralReasonsList = new List<Referral_Reason__c>();
                for(Referral_Reason__c reason : [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,Approval_Rejected_Date__c,Approver_Level__c,Approved_By__c,
                                                 Entity_Path__c,Reason__c,Reason_Type__c,Status__c,Approved_By__r.Name,Is_Auto_Approved__c,Quote_Option__r.Bound__c,
                                                 Quote_Option__c,Option_Type__c,Option_Limit__c,Option_Id__c,Quote_Option__r.Selected__c,Quote__c,Quote__r.Quote_Type__c, 
                                                 Quote__r.Status,Quote_Option_Limit__c From Referral_Reason__c 
                                                 WHERE Quote__c =: quotes[0].Id]) {
                   if(quoteClone.Quote_Type__c == 'Coverage Amendment' || quoteClone.Quote_Type__c == 'Policy Duration Change' || quoteClone.Quote_Type__c == 'Midterm Cancellation' || quoteClone.Quote_Type__c == 'Flat Cancellation' || quoteClone.Quote_Type__c == 'Reinstatement' || (reason.Quote__r.Quote_Type__c == 'New Business' && reason.Quote__r.Status == 'Bound')){
                         if((reason.Quote_Option__r.Bound__c || reason.Quote_Option__c == null) && reason.Approval_Status__c == 'Approved'){
                             Referral_Reason__c reasonClone = reason.clone(false, true, false, false);
                            reasonClone.Quote__c = quoteClone.Id;
                            reasonClone.Quote_Option__c = azureIdToQuoteOptionIdMap.get(oldAzureToNewIdMap.get(reason.Option_Id__c));
                            reasonClone.Option_Id__c = oldAzureToNewIdMap.get(reason.Option_Id__c);
                            referralReasonsList.add(reasonClone);
                        }
                    }else if(!reason.Quote_Option__r.Bound__c && reason.Approval_Status__c != 'Approved' && reason.Quote__r.Quote_Type__c != 'New Business' && reason.Quote__r.Status != 'Bound'){
                        Referral_Reason__c reasonClone = reason.clone(false, true, false, false);
                        reasonClone.Quote__c = quoteClone.Id;
                        reasonClone.Quote_Option__c = azureIdToQuoteOptionIdMap.get(oldAzureToNewIdMap.get(reason.Option_Id__c));
                        reasonClone.Option_Id__c = oldAzureToNewIdMap.get(reason.Option_Id__c);
                        referralReasonsList.add(reasonClone);
                    }                   
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
            if(fieldUpdateMap != null && !fieldUpdateMap.isEmpty() && fieldUpdateMap.containsKey('Layer__c')
                && (quotes[0].Product_Name__c.contains('MPL') || quotes[0].Product_Name__c.contains('Cyber') || quotes[0].Product_Name__c == Label.Product_Name_for_PCC )
                && quotes[0].Layer__c != (String)fieldUpdateMap.get('Layer__c')){
                for(CoveragesLineItem__c cli : [SELECT Id, Coverage__c, Sub_Coverage__c, Limits_Deductibles__c, Coverage_product__c,
                                                    Coverage_Premium__c,Deductible_Frequency__c, Options_Value_Percent__c,
                                                    Increment_Step__c, IsIncluded__c, Max_amt__c, Min_amt__c, Page_Section__c,
                                                    Option_Picklist__c,Option_Type__c,Option_Value__c,Override_Premium__c,
                                                    Option_Value_Default__c,Optional_Coverage_Name__c,
                                                    Notes__c, Form_Number__c, Coverage_Product_Combo__c,Default_Coverage_Value__c,
                                                    Coverage_Effective_Date__c, Group__c 
                                                FROM CoveragesLineItem__c 
                                                WHERE Quote__c =: quotes[0].Id AND 
                                                ((Coverage__r.Coverage_Type__c = 'Endorsement' AND Coverage__r.Additional_Requirements__c INCLUDES ('Load by Default')) 
                                                OR Coverage__r.Coverage_Type__c != 'Endorsement') ]) {
                    CoveragesLineItem__c cliClone = cli.clone(false, true, false, false);
                    cliClone.Parent_Coverages_Line_Item__c = cli.Id;
                    cliClone.Quote__c = quoteClone.Id;
                    covLineItemClones.add(cliClone);
                }
                List<Coverage__c> excessCoverages = [SELECT Id,Coverage_Product__c,Coverage_Product_Combo__c,RecordType.Name,Coverage_or_Sub__c,Coverage_Type__c,Page_Section__c,Form_Number__c,Apply_to_Quote__c,
                    (Select Id,RecordTypeId,RecordType.Name,Page_Section__c,Option_Picklist__c,Default_Value__c From FeaturesProductOptions__r)
                    From Coverage__c 
                    Where ((Coverage_Type__c = 'Endorsement' AND Additional_Requirements__c INCLUDES ('Load by Default')) 
                    OR Coverage_Type__c != 'Endorsement') 
                    AND Coverage_Product__c =: (String)fieldUpdateMap.get('Layer__c')];
                List<CoveragesLineItem__c> excessClis = new List<CoveragesLineItem__c>();
                for(Coverage__c coverage: excessCoverages){
                    excessClis = GenerateCLIByCoverage(coverage, quoteClone);
                    if(!excessClis.isEmpty()) covLineItemClones.addAll(excessClis);
                }
            }else{
                for(CoveragesLineItem__c cli : [SELECT Id, Coverage__c, Sub_Coverage__c, Limits_Deductibles__c, Coverage_product__c,
                                                    Coverage_Premium__c,Deductible_Frequency__c, Options_Value_Percent__c,
                                                    Increment_Step__c, IsIncluded__c, Max_amt__c, Min_amt__c, Page_Section__c,
                                                    Option_Picklist__c,Option_Type__c,Option_Value__c,Override_Premium__c,
                                                    Option_Value_Default__c,Coverage_Product_Combo__c,Default_Coverage_Value__c,Optional_Coverage_Name__c,
                                                    Notes__c, Form_Number__c, //#34914-04Dec20-Khanh
                                                    Coverage_Effective_Date__c, Group__c, Coverage__r.Coverage_Type__c //tuan.d.nguyen added 9-Dec-2020
                        //Dwelling_Home_Value__c //long ly - 29/05 - remove unsued field
                                                FROM CoveragesLineItem__c 
                                                WHERE Quote__c =: quotes[0].Id]) {
                    CoveragesLineItem__c cliClone = cli.clone(false, true, false, false);
                    cliClone.Parent_Coverages_Line_Item__c = cli.Id;
                    cliClone.Quote__c = quoteClone.Id;
                    //US:58001 Effective date should be cloned quote effective date for renewal.
                    if(quoteClone.Quote_Type__c == 'Renewal'){
                        if(cli.Coverage__r.Coverage_Type__c == 'Endorsement'){
                            cliClone.Coverage_Effective_Date__c = quoteClone.Effective_Date__c;
                        }
                    }
                    covLineItemClones.add(cliClone);
                }
            }
 
            if(!covLineItemClones.isEmpty()) insert covLineItemClones;
            system.debug('covLineItemClones@@@' + covLineItemClones);
            system.debug('quoteClone@@@' + quoteClone);
            
            //Clone Free form endorsements
            List<Free_Form_Endorsements__c> ffClones = new List<Free_Form_Endorsements__c>();
            for(Free_Form_Endorsements__c ff : [SELECT Id, Name, Quote__c, Form_Number__c, Endorsement_Name__c, Endorsement_Wording__c, 
                                                Coverage_Effective_Date__c,Notes__c FROM Free_Form_Endorsements__c 
                                            WHERE Quote__c =: quotes[0].Id]) {
			    Free_Form_Endorsements__c ffClone = ff.clone(false, true, false, false);
                //ffClone.Parent_Coverages_Line_Item__c = cli.Id;
                ffClone.Quote__c = quoteClone.Id;
                ffClones.add(ffClone);
            }
 
            if(!ffClones.isEmpty()) insert ffClones;
            system.debug('ffClones@@@' +ffClones);
            system.debug('quoteClone@@@' +quoteClone);
            
            // Clone Quote premium
           
            List<Quote_Premium__c> qpCloneLst = new List<Quote_Premium__c>();
            for(Quote_Premium__c qp: [Select Id,Name,Product_Name__c,Quote_Premium__c from Quote_Premium__c WHERE Quote__c =:quotes[0].Id]){
                Quote_Premium__c quoteCn = qp.clone(false, true, false, false);
                quoteCn.Quote__c= quoteClone.Id;
                qpCloneLst.add(quoteCn);
            }
            if(!qpCloneLst.isEmpty()){
                insert qpCloneLst;
            }
            
            //Clone Rating Modifier Factor
            List<Rating_Modifier_Factor__c> cloneRatingModifierFactors = new List<Rating_Modifier_Factor__c>();
            
            Map<String, Rating_Modifiers__c> newRateModCodeToObjMap = new Map<String, Rating_Modifiers__c>();
            List<Rating_Modifiers__c> ratingModOnClonedOppList = [SELECT Id, Opportunity__c, Rating_Modifier_Code__c
                                                                  FROM Rating_Modifiers__c 
                                                                  WHERE Opportunity__c =: quoteClone.OpportunityId];
            
            for(Rating_Modifiers__c newRatM : ratingModOnClonedOppList){
                newRateModCodeToObjMap.put(newRatM.Rating_Modifier_Code__c, newRatM);
            }
            
            for(Rating_Modifier_Factor__c rati : [SELECT CreatedById, Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                                                  Factor_Value__c, LastModifiedById, Rating_Modifier__c,Rating_Modifier__r.Opportunity__c,
                                                  Rating_Modifier__r.Rating_Modifier_Code__c FROM Rating_Modifier_Factor__c 
                                                  WHERE Quote__c =: quoteId]) 
            {
                
                Rating_Modifier_Factor__c cloneRMF = rati.clone(false, true, false, false);
                cloneRMF.Quote__c = quoteClone.Id;
                if(quoteClone.OpportunityId != rati.Rating_Modifier__r.Opportunity__c && newRateModCodeToObjMap.containsKey(rati.Rating_Modifier__r.Rating_Modifier_Code__c) ){
                    cloneRMF.Rating_Modifier__c = newRateModCodeToObjMap.get(rati.Rating_Modifier__r.Rating_Modifier_Code__c).Id;
                }                                    
                cloneRatingModifierFactors.add(cloneRMF); 
            }
            
            List<Rating_Modifier_Factor__c> deleteRMFs = [SELECT Id, Name FROM Rating_Modifier_Factor__c WHERE Quote__c =: quoteClone.Id];
            delete deleteRMFs; 
            if(!cloneRatingModifierFactors.isEmpty()) insert cloneRatingModifierFactors;
            
            response.isSuccess = true;
            response.data = quoteClone;
            return response;
            
        } catch(Exception ex){
            ErrorLogsUtilityHelper.logError(ex, 'CloneServiceHandler_Common.cloneQuoteWithChildren', CommonUtil.getExceptionMessage(ex), '', 'AQ_Exceptions', '', String.valueOf(ex.getLineNumber()));
            System.debug('Clone error: ' + ex.getMessage() + ex.getLineNumber());
            Database.rollback(sp);
            response.isSuccess = false;
            response.errors.add(ex.getMessage());
            return response;
            // throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));
        }
    }

    public static List<CoveragesLineItem__c> GenerateCLIByCoverage(Coverage__c obj, Quote quoteItem) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> limitItems = new List<CoveragesLineItem__c>();
        CoveragesLineItem__c cov = new CoveragesLineItem__c();
        Date effectiveDate;
        if(quoteItem != null)
            if(quoteItem.Quote_Type__c == Label.Quote_Type_New_Business)
            effectiveDate = quoteItem.Effective_Date__c;
        else if(quoteItem.Quote_Type__c == Label.Quote_Type_Amendment)
            effectiveDate = quoteItem.Endorsement_Effective_Date__c;
        try {
       
            cov.Quote__c = quoteItem.Id;
            cov.Coverage_Product__c = obj.Coverage_Product__c;
            cov.Page_Section__c = obj.Page_Section__c;
            cov.Form_Number__c = obj.Form_Number__c;
            if(obj.Coverage_Type__c == 'Endorsement') 
                cov.Coverage_Effective_Date__c = effectiveDate;
            
            
            switch on obj.RecordType.Name {
                when 'Main Coverage' {
                    cov.Coverage__c = obj.Id;
                }
                when 'Sub Coverage' {
                    cov.Coverage__c = obj.Coverage_or_Sub__c;
                    cov.Sub_Coverage__c = obj.Id;
                }
            }
            for (Coverage_Limits_Deductibles__c item : obj.FeaturesProductOptions__r) {
                CoveragesLineItem__c cli = cov.clone(false, true, false, false);
                cli.Limits_Deductibles__c = item.Id;
                cli.Page_Section__c = item.Page_Section__c;
                if(obj.Coverage_Type__c == 'Endorsement') 
                    cli.Coverage_Effective_Date__c = effectiveDate;
                limitItems.add(cli);
            }
            
            result.add(cov);
            result.addAll(limitItems);
        } catch (Exception ex) {
            result.clear();
        }
        return result;  
    }

}