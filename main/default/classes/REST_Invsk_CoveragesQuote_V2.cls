/*************************************************
* Class Name: REST_Invsk_CoveragesQuote_V2
* Author: Saumyak Pandey
* Date: 03-November-2020
* Requirement/Project Description: Coverages API to update Coverages Info
*************************************************/
@RestResource(urlMapping='/Invsk_CoveragesQuote_v2/*')
global with sharing class REST_Invsk_CoveragesQuote_V2 {
    
    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        OutGoingResponse outResponse = new OutGoingResponse();
        Savepoint sp;
        //try{
            String reqString = req.requestBody.toString();
            InComingRequest request = (InComingRequest)JSON.deserialize(reqString, InComingRequest.Class);
            List<Quote> existingQuoteList = getQuotesFromId(request.quote.Azure_Id__c);
           // system.debug('reqString-->'+reqString);
            
            if(existingQuoteList.isEmpty()){
                outResponse.status = 'Failed';
                outResponse.errors.add('Quote Azure ID does not exist');
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                RestResponse res = RestContext.response;
                ApiUtil.logAPICallIn(req, res, 'REST_Invsk_CoveragesQuote_V2', 'REST_Invsk_CoveragesQuote_V2.doPost');
                return;
            }
            
            Quote currentQuote = existingQuoteList[0];
            Quote requestQuoteNode = request.quote;
            List<CoveragesLineItem__c> requestCLINode = request.coverageLineItem;
            //List<CoveragesLineItem__c> requestCLINodeTemp = request.coverageLineItem;
            // List<CoveragesLineItem__c> requestCLINode = new List<CoveragesLineItem__c>();
            // //Map<String, List<CoveragesLineItem__c>> reqCliMap = new Map<String, List<CoveragesLineItem__c>>();
            // Set<String> covCodes = new Set<String>();
            // //US:57667 Adding only those coverages that have IsSelected = true.
            // for(CoveragesLineItem__c cli: requestCLINodeTemp){
            //     // if((cli.Name == null || cli.Name == '')){
            //     //     continue;
            //     // }
            //     if(cli.Limits_Deductibles__c == null && (cli.IsSelected__c == null || cli.IsSelected__c == false)){
            //         continue;
            //     }
            //     else if(cli.Limits_Deductibles__c == null){
            //         // if(!reqCliMap.containsKey(cli.Coverage__c)){
            //         //     reqCliMap.put(cli.Coverage__c, new List<CoveragesLineItem__c>());
            //         // }
            //         // reqCliMap.get(cli.Coverage__c).add(cli);
            //         covCodes.add(cli.Coverage__c);
            //     }
                // }

            // for(CoveragesLineItem__c cli: requestCLINodeTemp){
            //     if(covCodes.contains(cli.Coverage__c)){
            //         requestCLINode.add(cli);
            //     }
                    // }
          
            //Add UW Code and Reasons to quote
            if(!request.reasons.isEmpty()){
                List<String> UWCode = new List<String>();
                List<String> UWReason = new List<String>();
                for(UWReason description : request.reasons){
                    UWCode.add(description.OverallUWCodes);
                    UWReason.add(description.UWReason);
                }
                currentQuote.Overall_UW_Codes__c = String.join(UWCode, ',');
                currentQuote.UW_Reason__c = String.join(UWReason, '\n');
            }
            
            //Add Quote node fields from request to existing quote
            if(String.isNotBlank(requestQuoteNode.Status)) currentQuote.Status = requestQuoteNode.Status;
            if(requestQuoteNode.Tax != NULL) currentQuote.Tax = requestQuoteNode.Tax;
            if(String.isNotBlank(requestQuoteNode.Name)) currentQuote.Name = requestQuoteNode.Name; 
            if(String.isNotBlank(requestQuoteNode.Rating_Status__c)) currentQuote.Rating_Status__c = requestQuoteNode.Rating_Status__c;            
            if(requestQuoteNode.Commission__c != NULL) currentQuote.Commission__c = requestQuoteNode.Commission__c;
            if(requestQuoteNode.Effective_Date__c != NULL) currentQuote.Effective_Date__c = requestQuoteNode.Effective_Date__c;            
            if(requestQuoteNode.ExpirationDate != NULL) currentQuote.ExpirationDate = requestQuoteNode.ExpirationDate;
            if(String.isNotBlank(requestQuoteNode.Master_Set_ID__c)) currentQuote.Master_Set_ID__c = requestQuoteNode.Master_Set_ID__c;                       
            if(requestQuoteNode.QuotePremium__c != NULL) currentQuote.QuotePremium__c = requestQuoteNode.QuotePremium__c;
            if(requestQuoteNode.Non_Prorated_Quote_Premium__c != NULL) currentQuote.Non_Prorated_Quote_Premium__c = requestQuoteNode.Non_Prorated_Quote_Premium__c;
            if(requestQuoteNode.Commission_percentage__c != NULL) currentQuote.Commission_percentage__c = requestQuoteNode.Commission_percentage__c;
            if(requestQuoteNode.Endorsement_Effective_Date__c != NULL) currentQuote.Endorsement_Effective_Date__c = requestQuoteNode.Endorsement_Effective_Date__c;
            if(requestQuoteNode.Technical_Premium__c != NULL) currentQuote.Technical_Premium__c = requestQuoteNode.Technical_Premium__c;
            // Added by Maeran for US:52235
            if(requestQuoteNode.RatesEffectiveDate__c != NULL) currentQuote.RatesEffectiveDate__c  = requestQuoteNode.RatesEffectiveDate__c ;
            if(requestQuoteNode.Special_Coverage_Text__c != NULL) currentQuote.Special_Coverage_Text__c  = requestQuoteNode.Special_Coverage_Text__c ;
            if(requestQuoteNode.Special_Coverage_Selected__c != NULL) currentQuote.Special_Coverage_Selected__c  = requestQuoteNode.Special_Coverage_Selected__c ;

            sp = Database.setSavepoint();
        
            insertCLIFromRequest(getQuoteCLIs(currentQuote.Id), requestCLINode, currentQuote); 
            //Get parent quote's CLIs
            Map<String, CoveragesLineItem__c> covCodeLimDedCodeToParentCLIMap = new Map<String, CoveragesLineItem__c>();
            system.debug('Parent'+currentQuote.Parent_Quote__c);
            if(currentQuote.Parent_Quote__c != null){
                List<CoveragesLineItem__c> parentQuoteCLIList = getQuoteCLIs(currentQuote.Parent_Quote__c);
                if(!parentQuoteCLIList.isEmpty()){                    
                    for(CoveragesLineItem__c cli: parentQuoteCLIList){
                        List<String> codeKey = new List<String>{cli.Coverage__r.Coverage_Code__c, cli.Limits_Deductibles__r.LmtDedCode__c};
                            covCodeLimDedCodeToParentCLIMap.put(String.join(codeKey, ''), cli);
                    }
                }
            }
            
            //Get current quote's CLIs
            Map<String, CoveragesLineItem__c> covCodeLimDedCodeToCLIMap = new Map<String, CoveragesLineItem__c>();
            List<CoveragesLineItem__c> currentQuoteCLIList = getQuoteCLIs(currentQuote.Id);
            if(!currentQuoteCLIList.isEmpty()){                
                for(CoveragesLineItem__c cli: currentQuoteCLIList){
                    List<String> codeKey = new List<String>{cli.Coverage__r.Coverage_Code__c, cli.Limits_Deductibles__r.LmtDedCode__c};
                        covCodeLimDedCodeToCLIMap.put(String.join(codeKey, ''), cli);
                }
            } else {
                outResponse.status = 'Failed';
                outResponse.errors.add('No Coverages Line Item to Update');
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                RestResponse res = RestContext.response;
                ApiUtil.logAPICallIn(req, res, 'REST_Invsk_CoveragesQuote_V2', 'REST_Invsk_CoveragesQuote_V2.doPost');
                return;
            }
            
            //Get Id from Coverage code and Limit Ded Code 
            Set<String> covCode = new Set<String>();
            Set<String> limDedCode = new Set<String>();
            Map<String,Coverage__c> covCodeToCovMap = new Map<String,Coverage__c>();
            Map<String,Coverage_Limits_Deductibles__c> limDedCodeToObjMap = new Map<String,Coverage_Limits_Deductibles__c>();
            
            for(CoveragesLineItem__c reqCLI: requestCLINode){
                covCode.add(reqCLI.Coverage__c);
                limDedCode.add(reqCLI.Limits_Deductibles__c);
            }
           
            
            List<Coverage__c> covList = [SELECT Id, Name, Coverage_Code__c FROM Coverage__c WHERE Coverage_Code__c IN:covCode];
          
            List<Coverage_Limits_Deductibles__c> limDedList = [SELECT id, Name, LmtDedCode__c FROM Coverage_Limits_Deductibles__c 
                                                               WHERE LmtDedCode__c IN:limDedCode];
            for(Coverage__c cov: covList){
                covCodeToCovMap.put(cov.Coverage_Code__c, cov);
            }
            
            for(Coverage_Limits_Deductibles__c limDed: limDedList){
                limDedCodeToObjMap.put(limDed.LmtDedCode__c, limDed);
            }
            
            //Update CLIs from request to quote and add parent CLI ID if present
            List<CoveragesLineItem__c> CLIToUpdate = new List<CoveragesLineItem__c>();
            for(CoveragesLineItem__c reqCLI: requestCLINode){
                //Create key to check through Parent and current quote Maps
                List<String> keyForMapList = new List<String>{reqCLI.Coverage__c, reqCLI.Limits_Deductibles__c};
                    String key = String.join(keyForMapList, '');
                
                CoveragesLineItem__c currentCLI = covCodeLimDedCodeToCLIMap.get(key);
                if(currentCLI != Null){
                currentCLI.Coverage__c = covCodeToCovMap.get(reqCLI.Coverage__c) != null ? covCodeToCovMap.get(reqCLI.Coverage__c).Id : null; 
                currentCLI.Limits_Deductibles__c = limDedCodeToObjMap.get(reqCLI.Limits_Deductibles__c) != null ? limDedCodeToObjMap.get(reqCLI.Limits_Deductibles__c).Id : null;
                currentCLI.Increment_Step__c = reqCLI.Increment_Step__c != null ? reqCLI.Increment_Step__c : null;
                currentCLI.Max_amt__c = reqCLI.Max_amt__c != null ? reqCLI.Max_amt__c : null;
                currentCLI.Min_amt__c = reqCLI.Min_amt__c != null ? reqCLI.Min_amt__c : null;
                currentCLI.Option_Value__c = reqCLI.Option_Value__c != null ? reqCLI.Option_Value__c : null;
                currentCLI.Option_Value_Default__c  = reqCLI.Option_Value_Default__c  != null ? reqCLI.Option_Value_Default__c  : null;
                currentCLI.Override_Premium__c = reqCLI.Override_Premium__c != null ? reqCLI.Override_Premium__c : null;                
                if(String.isNotBlank(reqCLI.Coverage_Premium__c)) currentCLI.Coverage_Premium__c = reqCLI.Coverage_Premium__c;                
                if(String.isNotBlank(reqCLI.Option_Picklist__c)) currentCLI.Option_Picklist__c = reqCLI.Option_Picklist__c;
                if(String.isNotBlank(reqCLI.Option_Type__c)) currentCLI.Option_Type__c = reqCLI.Option_Type__c;
                if(String.isNotBlank(reqCLI.Non_Prorated_Coverage_Premium__c)) currentCLI.Non_Prorated_Coverage_Premium__c = reqCLI.Non_Prorated_Coverage_Premium__c;
                currentCLI.IsSelected__c = reqCLI.IsSelected__c; // Added as part of bug 59750
                if(currentQuote.Opportunity.LeadSource == 'Shopping X' ){
                   if(String.isNotBlank(reqCLI.Notes__c)) currentCLI.Notes__c = reqCLI.Notes__c; // Added as a fix for a BUG 57125 - JUHI
                 }
                if(covCodeLimDedCodeToParentCLIMap.get(key) != null){
                    currentCLI.Parent_Coverages_Line_Item__c = covCodeLimDedCodeToParentCLIMap.get(key).Id;
                }
                CLIToUpdate.add(currentCLI);
            }
            }

            Opportunity oppObj = new Opportunity();
           if(request.submission!=null)
           {
               oppObj.Id=currentQuote.OpportunityId;
               //Added by Vinayesh to update Lastsource. Needs to be changed and run flow.
               oppObj.LastSource__c = 'ShopX';
               oppObj.LeadSource = 'Shopping X';
               oppObj.Industry__c =request.submission.Industry__c;
               oppObj.Service_Classification__c =request.submission.Service_Classification__c;
               // Added by Maeran on 20/9/2021 for US:51819 as suggested by Spyros
               if(request.submission.Retroactive_Date__c != null ){
                oppObj.Retroactive_Date__c = request.submission.Retroactive_Date__c ;
               }
              
               oppObj.Retroactive_Date_Docs__c = String.isNotBlank(request.submission.Retroactive_Date_Docs__c) ? (request.submission.Retroactive_Date_Docs__c) : '' ;
           }
        
            TriggerHandler.bypass('SubmissionTriggerBaseHandler');
            if(oppObj.Id != null) update oppObj;
            if(currentQuote != null) update currentQuote;
            TriggerHandler.bypass('SubmissionTriggerBaseHandler');
        
            System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            
            TriggerHandler.bypass('CoverageLineItemTriggerBaseHandler');
            GlobalStaticVar.byPassQuoteTrigger = true;
            if(!CLIToUpdate.isEmpty()) {
                update CLIToUpdate;
                //CoverageLineItemTriggerHandler_CEL.filterEndorsement(CLIToUpdate);
            }
            GlobalStaticVar.byPassQuoteTrigger = false;
            TriggerHandler.clearBypass('CoverageLineItemTriggerBaseHandler');
            
            outResponse.status = 'Success';
            outResponse.errors.clear();
            RestContext.response.statusCode = 200;
            
        /*}catch(Exception ex){
            system.debug('Exception:' + ex.getLineNumber() + ' ' + ex.getMessage());
            Database.rollback(sp);
            outResponse.status = 'Failed';           
            outResponse.errors.add(CommonUtil.getExceptionMessage(ex));
            RestContext.response.statusCode = 500;
        } */
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
        ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_CoveragesQuote_V2', 'REST_Invsk_CoveragesQuote_V2.doPost');
    }
    
    public static void insertCLIFromRequest(List<CoveragesLineItem__c> currentQuoteCLIList, List<CoveragesLineItem__c> requestCLINode, Quote quoteItem){
        List<CoveragesLineItem__c> clisToInsert = new List<CoveragesLineItem__c>();
        Set<String> currentCoveragesCodes = new Set<String>();
        Set<String> requestCoveragesCodes = new Set<String>();
        Set<String> requestLimitsAndDeductablesCodes = new Set<String>();
        if(!requestCLINode.isEmpty()){                
            for(CoveragesLineItem__c cli: currentQuoteCLIList){
                currentCoveragesCodes.add(cli.Coverage__r.Coverage_Code__c);
            }
            for(CoveragesLineItem__c cli: requestCLINode){
                if(cli.Coverage__c != null && !currentCoveragesCodes.contains(cli.Coverage__c)){
                    requestCoveragesCodes.add(cli.Coverage__c);
                    requestLimitsAndDeductablesCodes.add(cli.Limits_Deductibles__c);
                }
            }
        }
        // if(requestCoveragesCodes.size() > currentCoveragesCodes.size()){
        //     requestCoveragesCodes.removeAll(currentCoveragesCodes);
        //     List<Coverage__c> covList = [Select Id,Coverage_Product__c,RecordType.Name,Coverage_or_Sub__c,Coverage_Type__c,Page_Section__c,Form_Number__c,
        //     (Select Id,RecordTypeId,RecordType.Name,Page_Section__c From FeaturesProductOptions__r Where LmtDedCode__c IN :requestLimitsAndDeductablesCodes)
        //     From Coverage__c  WHERE Coverage_Code__c IN:requestCoveragesCodes And Coverage_Product__c = :quoteItem.Product_Name__c.split(' ')[0]];
        //     clisToInsert = generateCoverageLineItems(covList, quoteItem);
        //     if(!clisToInsert.isEmpty()) insert clisToInsert;
        // }
        
        List<Coverage__c> covList = [Select Id,Coverage_Product__c,RecordType.Name,Coverage_or_Sub__c,
                                     Coverage_Type__c,Page_Section__c,Form_Number__c, (Select Id,RecordTypeId,
                                     RecordType.Name,Page_Section__c From FeaturesProductOptions__r 
                                     Where LmtDedCode__c IN :requestLimitsAndDeductablesCodes)
                                     From Coverage__c  WHERE Coverage_Code__c IN:requestCoveragesCodes And Coverage_Product__c = :quoteItem.Product_Name__c.split(' ')[0]];
        clisToInsert = generateCoverageLineItems(covList, quoteItem);
        system.debug('clisToInsert-->'+clisToInsert);
        if(!clisToInsert.isEmpty()) upsert clisToInsert;
    }

    public static List<CoveragesLineItem__c> generateCoverageLineItems(List<Coverage__c> templates, Quote quoteItem) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            for (Coverage__c cov : templates) {
                List<CoveragesLineItem__c> items = GenerateCLIByCoverage(cov, quoteItem);
                result.addAll(items);
            }
        } catch (Exception ex) {
            result = new List<CoveragesLineItem__c>();
        }
        return result;
    }
    
    public static List<CoveragesLineItem__c> GenerateCLIByCoverage(Coverage__c obj, Quote quoteItem) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> limitItems = new List<CoveragesLineItem__c>();
        CoveragesLineItem__c cov = new CoveragesLineItem__c();
        Date effectiveDate; // add effective date to coverage line item
        if(quoteItem != null)
            if(quoteItem.Quote_Type__c == Label.Quote_Type_New_Business)
            effectiveDate = quoteItem.Effective_Date__c;
        else if(quoteItem.Quote_Type__c == Label.Quote_Type_Amendment)
            effectiveDate = quoteItem.Endorsement_Effective_Date__c;
        try {
            // create main coverage and sub coverage        
            cov.Quote__c = quoteItem.Id;
            cov.Coverage_Product__c = obj.Coverage_Product__c;
            cov.Page_Section__c = obj.Page_Section__c;
            cov.Form_Number__c = obj.Form_Number__c; //Added 5/Oct/2020
            if(obj.Coverage_Type__c == 'Endorsement') //tuan.d.nguyen 3-Dec-2020 added
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
            // create limit and deductibles
            for (Coverage_Limits_Deductibles__c item : obj.FeaturesProductOptions__r) {
                CoveragesLineItem__c cli = cov.clone(false, true, false, false);
                cli.Limits_Deductibles__c = item.Id;
                cli.Page_Section__c = item.Page_Section__c;
                if(obj.Coverage_Type__c == 'Endorsement') //tuan.d.nguyen 3-Dec-2020 added
                    cli.Coverage_Effective_Date__c = effectiveDate;
                limitItems.add(cli);
            }
            
            result.add(cov);
            
            result.addAll(limitItems);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            result.clear();
        }
        return result;  
    }
    
    public static List<Quote> getQuotesFromId(String quoteAzureId) {
        List<Quote> quoteList = [SELECT Id, Name, Azure_Id__c, Effective_Date__c, Endorsement_Effective_Date__c, Parent_Quote__c,
                                 ExpirationDate, CloseDate__c, QuoteNumber, Status, Declined_Reason__c, UW_Reason__c, 
                                 Rating_Status__c, Tax, Total_Premium__c, Commission__c, Commission_percentage__c, 
                                 QuotePremium__c, Accept_Terror_Premium__c, Overall_UW_Codes__c, Quote_Type__c, Special_Coverages__c,
                                 OpportunityId, Account.Name, Account.Azure_Id__c, Contract.ContractNumber, Contract.Status, 
                                 Opportunity.Name, Opportunity.Product__c, Opportunity.Azure_ID__c, Opportunity.AccountId,
                                 Opportunity.Account.Name, Opportunity.Account.BillingStreet, Opportunity.Account.BillingCity, 
                                 Opportunity.Account.BillingState, Opportunity.Account.BillingStateCode, Opportunity.Account.BillingPostalCode, 
                                 Opportunity.Account.BillingCountry, Opportunity.Account.BillingCountryCode, 
                                 Opportunity.Account.Azure_ID__c, Opportunity.Account.Billing_County__c, 
                                 Product_Name__c, Opportunity.Product__r.Azure_Id__c, Opportunity.LeadSource
                                 FROM Quote  WHERE Azure_Id__c = :quoteAzureId];
        return quoteList;
    }
    
    public static List<CoveragesLineItem__c> getQuoteCLIs (String quoteId){
        List<CoveragesLineItem__c> CLIList = [Select Id, Parent_Coverages_Line_Item__c, Coverage_Premium__c, Override_Premium__c, Option_Type__c, 
                                              Option_Value_Default__c, Option_Value__c, Increment_Step__c, Max_amt__c, Min_amt__c, Azure_ID__c, 
                                              Option_Picklist__c, Quote__c, Coverage_Sort_Order__c, Coverage__r.Name, Coverage__r.Coverage_Code__c, 
                                              Coverage__r.Azure_ID__c, Sub_Coverage__r.Name, Sub_Coverage__r.Coverage_Code__c, Sub_Coverage__r.Azure_ID__c, 
                                              Limits_Deductibles__r.Name, Limits_Deductibles__r.LmtDedCode__c, Limits_Deductibles__r.RecordType.Name, Notes__c
                                              From CoveragesLineItem__c WHERE Quote__c=: quoteId];
        return CLIList;
    }
    
    public class InComingRequest {
        public Quote quote 										{get; set;}
        public Opportunity submission 							{get; set;}
        public List<UWReason> reasons        					{get; set;}
        public List<CoveragesLineItem__c> coverageLineItem 		{get; set;}
    }
    
    public class OutGoingResponse {        
        public String status                       		 		{get; set;}
        public List<String> errors                  			{get; set;}
        public OutGoingResponse() {
            this.status = null;
            this.errors = new List<String>();
        }
    }
    
    public class UWReason {
        public String OverallUWCodes   							{get; set;}
        public String UWReason									{get; set;}
    }
    
}