/**
 * @description       : 
 * @author            : Altaf
 * @group             : 
 * @last modified on  : 07-27-2022
 * @last modified by  : Vinayesh
**/
public with sharing class QuoteTriggerHandler_Common {

    private static Map<String, List<String>> oppComboProductsMap = new Map<String, List<String>>();
    private static Map<String,Set<String>> quoteCoverageProdsMap = new Map<String,Set<String>>();
    private static Map<String,Set<String>> quoteRmFactorsProdMap = new Map<String,Set<String>>();

    public QuoteTriggerHandler_Common() {

    }

     // Missed in transition
    
     public static void processPoliCleanup(List<Quote> quotes){
        //delete existing clis and rmfs
        //cleanupRMFAndCLI(quotes);
        //generate opp combro product map
        generateSubmissionPoliMap(quotes);
        //generate coverage line items
        AddCoverageLineItems(quotes);
        //generate rating modifier factors
        AddRatingModifierFactor(quotes);
    }

    public static void cleanupRMFAndCLI(List<Quote> quotes){
        Set<id> quoteIds = new Set<id>();
        for(Quote qt: quotes){
            quoteIds.add(qt.id);
        }
        //clear existing rating modifier factor
        List<Rating_Modifier_Factor__c> rmFactors = [SELECT id from Rating_Modifier_Factor__c where Quote__c in: quoteIds];
        if(!rmFactors.isEmpty())
            delete rmFactors;
        
        //clear existing clis
        List<CoveragesLineItem__c> clis = [SELECT id from CoveragesLineItem__c where Quote__c in: quoteIds];
        if(!clis.isEmpty())
            delete clis;
    }


    /*************************************************
    * Author: 
    * Date: 
    * Params: quotelistNew - List of New Quotes
    * Return: none
    * Description: Method to generate opp combro product map used later in after context for adding coverage line item and rating modifier factors
    * Revision:
    *************************************************/
    public static void generateSubmissionPoliMap(List<Quote> quotelistNew) {
        Set<Id> oppIds = new Set<Id>();
        for(Quote quote : quotelistNew) {
            oppIds.add(quote.OpportunityId);
        }
        List<Product_Option_Line_Item__c> poliList = [Select Product__r.Name, Submission__c from Product_Option_Line_Item__c
                                                      Where Submission__c in :oppIds And Clearance_Status__c = 'Cleared'];
        oppComboProductsMap = new Map<String, List<String>>();
        for(Product_Option_Line_Item__c poli : poliList){
            if(!oppComboProductsMap.containsKey(poli.Submission__c)){
                oppComboProductsMap.put(poli.Submission__c, new List<String>());
            }
            oppComboProductsMap.get(poli.Submission__c).add(poli.Product__r.Name);
        }

        generateQuoteCliProdMap(quotelistNew);
        generateRmFactorProdMap(quotelistNew);
    }

    //Create map of quote vs existing rmFactors products for quote.
    private static void generateQuoteCliProdMap(List<Quote> quotelistNew) {
        quoteCoverageProdsMap = new Map<String,Set<String>>();
        Set<String> quoteIds = new Set<String>();
        for(Quote qt: quotelistNew){
            if(qt.id != null){
                quoteIds.add(qt.id);
            }
        }
        if(quoteIds.size() == 0) return;
        List<CoveragesLineItem__c> clis = [SELECT Id,Quote__c,Coverage_Product_Combo__c from 
                                           CoveragesLineItem__c where Quote__c in: quoteIds];

        for(CoveragesLineItem__c cli : clis) {
            if(cli.Coverage_Product_Combo__c == null) continue;
            if(!quoteCoverageProdsMap.containsKey(cli.Quote__c)){
                quoteCoverageProdsMap.put(cli.Quote__c, new Set<String>());
            }
            quoteCoverageProdsMap.get(cli.Quote__c).add(cli.Coverage_Product_Combo__c);
        }                                   
    }

     //Create map of quote vs existing cli coverage products for quote.
     private static void generateRmFactorProdMap(List<Quote> quotelistNew) {
        quoteRmFactorsProdMap = new Map<String,Set<String>>();
        Set<String> quoteIds = new Set<String>();
        for(Quote qt: quotelistNew){
            if(qt.id != null){
                quoteIds.add(qt.id);
            }
        }
        if(quoteIds.size() == 0) return;
        List<Rating_Modifier_Factor__c> rmfs = [SELECT Id,Quote__c,Rating_Modifier__r.Product__c from 
                                                Rating_Modifier_Factor__c where Quote__c in: quoteIds];

        for(Rating_Modifier_Factor__c rmf : rmfs) {
            if(rmf.Rating_Modifier__r.Product__c == null) continue;
            if(!quoteRmFactorsProdMap.containsKey(rmf.Quote__c)){
                quoteRmFactorsProdMap.put(rmf.Quote__c, new Set<String>());
            }
            quoteRmFactorsProdMap.get(rmf.Quote__c).add(rmf.Rating_Modifier__r.Product__c);
        }                                   
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: quotelistNew - List of New Quotes
    * Return: none
    * Description: Method to validate if Quote Coverage Product Options matched the ones selected on Submission Console.
    * Revision:
    *************************************************/
    public static void checkValidQuoteComboCoverageOptions(List<Quote> quotelistNew) {
        Set<Id> oppIds = new Set<Id>();
        for(Quote quote : quotelistNew) {
            oppIds.add(quote.OpportunityId);
        }
        
        Map<Id,String> mapOppCoverageProductOptions = new Map<Id,String>();
        List<Opportunity> listOpportunity = [SELECT Id,Coverage_Product_Options__c FROM Opportunity WHERE Id IN :oppIds];
        for(Opportunity opp : listOpportunity) {
            mapOppCoverageProductOptions.put(opp.Id,opp.Coverage_Product_Options__c);
        }
        
        for(Quote quote : quotelistNew) {
            String coverageProductOptionsOfOpp = mapOppCoverageProductOptions.get(quote.OpportunityId);
            System.debug('coverageProductOptionsOfOpp-->'+coverageProductOptionsOfOpp);
            if(String.isNotBlank(coverageProductOptionsOfOpp) && String.isNotBlank(quote.Coverage_Product_Options__c)) {
                List<String> quoteCoverageProductOptions = quote.Coverage_Product_Options__c.split(';');
                System.debug('quoteCoverageProductOptions-->'+quoteCoverageProductOptions);
                for(String s : quoteCoverageProductOptions) {
                    if(!coverageProductOptionsOfOpp.contains(s)) {
                        quote.addError(Label.QUOTE_COVERAGE_PRODUCT_OPTIONS_CONTAIN_VALUES_SELECTED_IN_THE_SUBMISSION);
                        break;
                    }
                }
            }
        }
    }

    /*************************************************
    * Author: Khanh TRAN
    * Date: 27-Sep-2019
    * Params:  newQuotes - List of new Quote
    * Return: 
    * Description: Update Broker Name and Broker Email
    * Revision: 
    *************************************************/ 
    public static void updateQuoteWithBrokerName(List<Quote> newQuotes){
            
        //Get ID of the opportunity
        Set<Id> oppIds = new Set<Id>();
        
        for (Quote newQuote : newQuotes) {
            oppIds.add(newQuote.OpportunityId);
        }
        
        Map<String, Broker_Account__c> opptId_BrokerAccMap = new Map<String, Broker_Account__c>();
        
        for(Broker_Account__c ba : [Select 
                                    Id,
                                    Broker_Contact__c,
                                    Broker_Contact__r.Email,
                                    Opportunity__c 
                                    From Broker_Account__c 
                                    Where Opportunity__c In: oppIds And IsPrimaryBroker__c = true]) {
                                        opptId_BrokerAccMap.put(ba.Opportunity__c, ba);
                                    }
        
        for(Quote quote : newQuotes) {             
            if(opptId_BrokerAccMap.containskey(quote.OpportunityId))  {
                quote.Broker__c = opptId_BrokerAccMap.get(quote.OpportunityId).Broker_Contact__c;
                quote.Broker_Email__c = opptId_BrokerAccMap.get(quote.OpportunityId).Broker_Contact__r.Email;
            }
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params:  items - List of new Quote
    * Return: 
    * Description: Method to update Commission Percentage(Broker Commission) on Quote
    * Revision: 
    *************************************************/ 
    public static void updateCommission(List<Quote> items) {
        List<Quote> quoteToUpdate = new List<Quote>();
        Map<String, String> quoteOpp = new Map<String, String>();
        for(Quote quote : items){
            quoteOpp.put(quote.Id, quote.OpportunityId);
        }
        
        // added by RINKU SAINI In Query Util 3rd Jan 2022
        Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(OpportunityQueryUtil.fetchSubmissionsFromIds(quoteOpp.values()));
        List<Broker_Account__c> brokerAccList= [SELECT Broker_Contact__c, Id, IsPrimaryBroker__c, Broker_Contact__r.AccountId ,Opportunity__c
                                                FROM Broker_Account__c
                                                WHERE Opportunity__c IN: quoteOpp.values()
                                                AND IsPrimaryBroker__c = true];
        Map<String, String> oppAccMap = new Map<String, String>();
        for(Broker_Account__c brokerAcc : brokerAccList){
            oppAccMap.put(brokerAcc.Opportunity__c, brokerAcc.Broker_Contact__r.AccountId);
        }
        
        // added by RINKU SAINI In Query Util 3rd Jan 2022
        List<Account_Product__c> accProds = AccountProductQueryUtil.fetchAccountProductsByAccountIds(oppAccMap.values());
        Map<String, List<Account_Product__c>> accAccProd = new Map<String, List<Account_Product__c>>();
        for(Account_Product__c accProd : accProds){
            if(!accAccProd.containsKey(accProd.Account_Id__c)){
                accAccProd.put(accProd.Account_Id__c, new List<Account_Product__c>{accProd});
            }else{
                List<Account_Product__c> accProdList = accAccProd.get(accProd.Account_Id__c);
                accProdList.add(accProd);
                accAccProd.put(accProd.Account_Id__c, accProdList);
            }
        }             
        
        for(Quote quoteObj : items){
            String oppId = quoteObj.OpportunityId;
            String accId = oppAccMap.get(oppId);
            List<Account_Product__c> accProdList = accAccProd.get(accId);
            if(accProdList != null && accProdList.size() > 0 ){
                for(Account_Product__c accProd : accProdList){
                    if(accProd.Product_Id__r.Name == oppMap.get(oppId).Product_Name__c){
                        quoteObj.Commission_percentage__c = accProd.Commission_percentage__c;
                        break;
                    }
                }
            }
        }        
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params:  newQuoteList - List of new Quote
    * Params:  oldQuoteMap - Map of old Quote
    * Return: 
    * Description: Method to add error on Quote if status = 'Quoted\' or \'Presented\' or \'Bound\'
    * Revision: 
    *************************************************/ 
    public static void lockEditOnQuote(List<Quote> newQuoteList, Map<Id, Quote> oldQuoteMap){
        Boolean skip = NewEndorsementController.skip_Val;
        if(!skip){
            
        try{
            Map<String, Schema.SObjectField> quoteFieldsMap = Schema.SObjectType.Quote.fields.getMap();
            Boolean showErr = false; 
            Set<String> bypassFields= new Set<String>{'invoice_status__c'}; // Added for 55459
            Set<String> bypassFieldsAqueous = new Set<String>{'notes__c'}; // Added by Vivek on 25-08-2022 for 59419 
            for(Quote q: newQuoteList){ 
                    
                if(((oldQuoteMap.get(q.Id).Status == 'Bound') ||
                    (oldQuoteMap.get(q.Id).Status == 'Presented' && q.Status != 'Bound' && q.Status != 'Closed')||
                    (oldQuoteMap.get(q.Id).Status == 'Bound Pending' && q.Status != 'Bound' && q.Status != 'Closed')  ||
                    (oldQuoteMap.get(q.Id).Status == 'Quoted' && q.Status != 'Bound' && q.Status != 'Bound Pending' && q.Status != 'Closed' &&
                     (oldQuoteMap.get(q.Id).Status == 'Presented' || oldQuoteMap.get(q.Id).Status == 'Bound Pending'))) &&
                   SubjectivityTriggerHandler.checkProfile && oldQuoteMap.get(q.Id).Status != 'Bound Pending' &&
                   q.Quote_Action__c != 'InsuredAccountUpdate')
                {
                    Id profileId = userinfo.getProfileId();
                    String profileName = [Select Id, Name from Profile where Id =: profileId].Name;   
                    system.debug('ProfileName' + profileName);
                    if(profileName == 'System Administrator'){
                        return;            
                    }
                    else if(profileName.contains('Celerity Senior')){ // Added for 55459
                        // Bypass this trigger if Status is changed
                        for(String fieldName :quoteFieldsMap.keySet() ){
                            if(q.get(fieldName) != oldQuoteMap.get(q.Id).get(fieldName) && !bypassFields.contains(fieldName)){
                                showErr = true;
                                return;
                            }
                        }
                        
                    }
                    // Added by Vivek on 25-08-2022 for 59419
                    else if(profileName.contains('Aqueous')){
                        for(String fieldName :quoteFieldsMap.keySet() ){
                            if(q.get(fieldName) != oldQuoteMap.get(q.Id).get(fieldName) && !bypassFieldsAqueous.contains(fieldName)){
                                q.addError('This Quote is locked for editing when status is \'Quoted\' or \'Presented\' or \'Bound\'');
                                break;                             
                            }
                        }
                    }
                    else{
                        q.addError('This Quote is locked for editing when status is \'Quoted\' or \'Presented\' or \'Bound\'');
                    }
                }

                if(showErr){
                    q.addError('This Quote is locked for editing when status is \'Quoted\' or \'Presented\' or \'Bound\'');
                }
            }
        }
        catch(Exception ex){
            
        }
    }  
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params:  quotelistNew - List of new Quote
    * Params:  oldQuoteMap - Map of old Quote
    * Return: 
    * Description: Method to send email to Submitter on Approval/Rejection
    * Revision: 
    *************************************************/ 
    public static void sendEmailToApprovalSubmitter(List<Quote> quotelistNew, Map<Id, Quote> oldQuoteMap){
        List <String> submitters = new List <String>();
        String templateName;
        String submitterName;
        for(Quote quote : quotelistNew) {
            if(quote.Product_Name__c == 'Professional Indemnity'){       
                if(quote.Status == 'In Progress' && quote.Is_Quote_Approved_AQ__c == 'Approved' && oldQuoteMap.get(quote.Id).Status == 'Referred') {
                    for(ProcessInstance p : [SELECT TargetObjectId, SubmittedBy.Email, SubmittedBy.Name FROM ProcessInstance 
                                             WHERE TargetObjectId =: quote.Id and Status = 'Approved' ORDER BY LastModifiedDate DESC Limit 1]){
                                                 submitterName = p.SubmittedBy.Name;
                                                 submitters.add(p.SubmittedBy.Email);
                                                 system.debug('SubmittedBy.Email::'+p.SubmittedBy.Email);
                                                 templateName = 'Quote_Approved';
                                                 EmailTemplate template = [SELECT Id,HtmlValue,Subject FROM EmailTemplate WHERE DeveloperName =:templateName LIMIT 1];
                                                 CommonUtil.sendEmail(template, quote , submitters, submitterName);  
                                             }    
                } 
                if(quote.Status == 'Rejected' && quote.Is_Quote_Approved_AQ__c == 'Rejected' && oldQuoteMap.get(quote.Id).Status == 'Referred') {
                    for(ProcessInstance p : [SELECT TargetObjectId, SubmittedBy.Email, SubmittedBy.Name FROM ProcessInstance 
                                             WHERE TargetObjectId =: quote.Id and Status = 'Rejected' ORDER BY LastModifiedDate DESC Limit 1]){
                                                 submitterName = p.SubmittedBy.Name;
                                                 submitters.add(p.SubmittedBy.Email);
                                                 templateName = 'Quote_Rejected';
                                                 EmailTemplate template = [SELECT Id,HtmlValue,Subject FROM EmailTemplate WHERE DeveloperName =:templateName LIMIT 1];
                                                 CommonUtil.sendEmail(template, quote , submitters, submitterName);  
                                             }   
                }
            }else{
                if(quote.Status == 'Rated' && quote.Approval_Status__c == 'Approved' && oldQuoteMap.get(quote.Id).Status == 'In Approval') {
                    for(ProcessInstance p : [SELECT TargetObjectId, SubmittedBy.Email, SubmittedBy.Name FROM ProcessInstance WHERE TargetObjectId =: quote.Id and Status = 'Approved' ORDER BY LastModifiedDate DESC Limit 1])
                    {
                        submitterName = p.SubmittedBy.Name;
                        submitters.add(p.SubmittedBy.Email);
                        system.debug('SubmittedBy.Email::'+p.SubmittedBy.Email);
                        templateName = 'Quote_Approved';
                        EmailTemplate template = [SELECT Id,HtmlValue,Subject FROM EmailTemplate WHERE DeveloperName =:templateName LIMIT 1];
                        CommonUtil.sendEmail(template, quote , submitters, submitterName);  
                    }    
                } 
                if(quote.Status == 'Rejected' && quote.Approval_Status__c == 'Rejected' && ReferralApprovalController.EmailFlag) {
                    for(ProcessInstance p : [SELECT TargetObjectId, SubmittedBy.Email, SubmittedBy.Name FROM ProcessInstance WHERE TargetObjectId =: quote.Id and Status = 'Rejected' ORDER BY LastModifiedDate DESC Limit 1])
                    {
                        submitterName = p.SubmittedBy.Name;
                        submitters.add(p.SubmittedBy.Email);
                        templateName = 'Quote_Rejected';
                        EmailTemplate template = [SELECT Id,HtmlValue,Subject FROM EmailTemplate WHERE DeveloperName =:templateName LIMIT 1];
                        CommonUtil.sendEmail(template, quote , submitters, submitterName);  
                    }   
                } 
            }                        
        }
    }

    /*************************************************
    * Author: Adheesh Gupta
    * Date: 
    * Params:  quotelistNew - List of new Quote
    * Params:  oldQuoteMap - Map of old Quote
    * Return: 
    * Description: Method to set Force_Rating__c whici is sent to and used by M/W.
    * Revision: 
    *************************************************/ 
    public static void checkForceRating(List<Quote> quotelistNew, Map<Id, Quote> oldQuoteMap){
        
        for(Quote objQuote : quotelistNew){
            
            if((objQuote.Status == 'In Progress' || objQuote.Status == 'Rated') && oldQuoteMap.get(objQuote.Id).Status == 'Quoted'){
                objQuote.Force_Rating__c = true;
            }
            else if(((objQuote.Status == 'Rated' && oldQuoteMap.get(objQuote.Id).Status == 'In Progress') || (objQuote.Status == 'Bound' && oldQuoteMap.get(objQuote.Id).Status != 'Bound')) && objQuote.Force_Rating__c == true){
                objQuote.Force_Rating__c = false;
            }
            
        }
        
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: quotes - List of quotes
    * Return: none
    * Description: Method to Create CoverageLineItems from Coverage for each Quote
    * Revision: 
    *************************************************/
    public static void AddCoverageLineItems(List<Quote> quotes) {
        system.debug(quotes);
        List<Coverage__c> templates = new List<Coverage__c>();
        Map<String, List<Coverage__c>> templateMap = new Map<String, List<Coverage__c>>();
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            //Method to get list products from a list of CoverageLineItems
            List<String> products = getAllProductOptions(quotes);
            System.debug('products'+products);
            //there is no products
            if(products.isEmpty()) return; 
            
            //Method to get list of coverages from list of products
            templates = getCoverageByProducts(products);
            System.debug('templates size -->'+templates.size());
            // no templates is found
            if (templates.isEmpty()) return;
            
            // Method to generate a map to store all template in map to reduce soql query
            templateMap = generateTemplateMap(templates);
            System.debug('templateMap size -->'+templateMap.size());
            //Method to delete old rating modifiers and add new ones based on coverage product options
            result = generateCoverageForInsert(templateMap, quotes);
            //GlobalStaticVar.byPassQuoteTrigger = true;
            System.debug('Result size -->'+result.size());
            insert result;
            system.debug('*********');
            system.debug(result);
        } catch (Exception ex) {
            system.debug(ex.getMessage());
            /*String errorMsg = 'Failed to create Coverage Line Item.<br/>Please contact your administators.';
            for(Quote item : (List<Quote>)Trigger.new ){
                item.addError(errorMsg);
            }*/
        }
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: item - List of Quotes
    * Description: Method to get list products from a list of Quotes
    * Revision: 
    *************************************************/
    private static List<String> getAllProductOptions(List<Quote> items) {
        Set<String> productOptions = new Set<String>();
        try {
            for (Quote item : items){
                List<String> products = getProductOptions(item);
                if(!products.isEmpty()){
                    productOptions.addAll(products);
                }      
            }
        } catch (Exception ex){

            productOptions.clear();
        }
        return new List<String>(productOptions);    
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: item - List of Quotes
    * Description: Method to get list productIds from a list of Quotes
    * Revision: 
    *************************************************/
    private static List<String> getProductOptions(Quote item) {
        List<String> result = new List<String>();
        try {
            if (item == null || String.isBlank(item.Product_Name__c)) 
                return result;
            
            String productName = item.Product_Name__c;
            system.debug(productName);
            if (productName.contains('Standalone')) {
                result.add(productName.split(' ')[0]); 
                
                if(item.Layer__c=='Excess'){
                    result.add('Excess');
                }
                system.debug('result'+result);
                
            } else if(productName == 'Professional Indemnity'){
                result.add(productName);
            } else if(productName == 'Private Company Combo'){
                //List<String> comboProds = item.Coverage_Product_Options__c.split(';');
                result.add(productName);
                if(item.Layer__c=='Excess'){
                    result.add('PCC Excess');
                }
            } else {
                result = item.Coverage_Product_Options__c.split(';');
            }
            system.debug(result);
            
        } catch (Exception ex) {
            result.clear();
        }
        return result;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: products - List of ProductIds
    * Description: Method to get list of coverages from list of products
    * Revision: 
    *************************************************/
    public static List<Coverage__c> getCoverageByProducts(List<String> products) {
        system.debug('products  '+products);
        List<Coverage__c> result = new List<Coverage__c>();
        try {
            //Get both Endorsements & Coverages
            //-->for Endorsements, adding a condition Additional_Requirements = 'Load by Default' 
            // added by RINKU SAINI In Query Util 3rd Jan 2022
            result = CoverageQueryUtil.fetchCoveragesByProductName(products); //Khanh-29Sept20
        } catch (Exception ex) {
            result = new List<Coverage__c>();
        }
        System.debug('getCoverageByProducts '+result);
        return result;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: templates - List of Rating template
    * Return: Map of Rating_Modifier_Template__c
    * Description: Method to generate a map to store all rating template by product name
    * Revision: 
    *************************************************/
    private static Map<String, List<Coverage__c>> generateTemplateMap(List<Coverage__c> items) {
        Map<String, List<Coverage__c>> result = new Map<String, List<Coverage__c>>();
        try {
            for (Coverage__c item : items) {
                // if map already contained product
                if (result.containsKey(item.Coverage_Product__c)) {
                    List<Coverage__c> templates = result.get(item.Coverage_Product__c);
                    templates.add(item);
                    result.put(item.Coverage_Product__c, templates);
                } else {
                    result.put(item.Coverage_Product__c, new List<Coverage__c> {item});
                }
            }
        } catch (Exception ex) {
            result.clear();
        }
        return result;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: templateMap - Map of rating templates
    * Params: items - List of Opportunity
    * Return: none
    * Description: Method to delete old rating modifiers and add new ones based on coverage product options
    * Revision: 
    *************************************************/ 
    private static List<CoveragesLineItem__c> generateCoverageForInsert(Map<String, List<Coverage__c>> templateMap,
    List<Quote> items) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();

        Map<String,String> accStateMap = generateAccountStateMap(items);
        List<String> productsList = getAllProductOptions(items);
        List<Coverage__c> allProductCoverages = CoverageQueryUtil.fetchAllCoveragesByProductName(productsList);
        
        
        for (Quote item : items) {
            List<Coverage__c> newTemplates = new List<Coverage__c>();
            //Method to Get all Coverage from input map by Quote
            newTemplates = getTemplateByQuote(templateMap, item);
            System.debug('newTemplates'+newTemplates);
            newTemplates = filterCoveragesForQuote(newTemplates, item, accStateMap, allProductCoverages);
            // Method to generate rating modifiers based on rating template
            List<CoveragesLineItem__c> coverages = generateCoverageLineItems(newTemplates, item);
            // skip if no rating is generated
            if (coverages.isEmpty()) continue;
            
            result.addAll(coverages);
        }
        
        return result;                                                            
    }

     /*************************************************
    * Author: Vinayesh
    * Date: 
    * Params: List<Coverage__c> templates, Quote quoteItem, Map<String,String> accStateMap
    * Return: List<Coverage__c>
    * Description: filter coverages by state and replacement coverage codes
    * Revision: 
    *************************************************/ 
    public static List<Coverage__c> filterCoveragesForQuote(List<Coverage__c> templates, Quote quoteItem, Map<String,String> accStateMap, List<Coverage__c> allCoverages){
        String stateCode = accStateMap.get(quoteItem.AccountId);
        Set<String> replaceFormCodes = new Set<String>();
        List<Coverage__c> tempFilteredCovs = new List<Coverage__c>();
        List<Coverage__c> filteredCovs = new List<Coverage__c>();
        List<Quote> qtList = new List<Quote>{quoteItem};
        if(oppComboProductsMap.size() == 0) generateSubmissionPoliMap(qtList);
        Map<String, List<Coverage__c>> allCovsMap = generateTemplateMap(allCoverages);
        List<Coverage__c> allCovs = getTemplateByQuote(allCovsMap, quoteItem);
        if(stateCode != null){
            for(Coverage__c cov: templates){
                if(cov.State__c == null || cov.State__c == '' || (cov.State__c.contains(stateCode))){
                    tempFilteredCovs.add(cov);
                    // if(cov.Coverage_to_replace__c != 'N/A' && cov.Coverage_to_replace__c != '' && cov.Coverage_to_replace__c != null){
                    //     replaceFormCodes.add(cov.Coverage_to_replace__c);
                    // }
                }
            }
            for(Coverage__c cov: allCovs){
                System.debug('vinay state ' + cov.State__c);
                if(cov.State__c == null || cov.State__c == '' || (cov.State__c.contains(stateCode))){
                    if(cov.Coverage_to_replace__c != 'N/A' && cov.Coverage_to_replace__c != '' && cov.Coverage_to_replace__c != null){
                        replaceFormCodes.addAll(cov.Coverage_to_replace__c.split(';'));
                    }
                }
            }
            if(replaceFormCodes.size() > 0){
                for(Coverage__c cov: tempFilteredCovs){
                    if(!replaceFormCodes.contains(cov.Form_Number__c)){
                        filteredCovs.add(cov);
                    }
                }
            }
            
            else filteredCovs = tempFilteredCovs;
            return filteredCovs;
        }
        else return templates;
    }


     /*************************************************
    * Author: Vinayesh
    * Date: 
    * Params: List<Quote> items
    * Return: Map<String,String>
    * Description: generate map of account and account billing state
    * Revision: 
    *************************************************/ 
    public static Map<String,String> generateAccountStateMap(List<Quote> items){
        Set<String> accIds = new Set<String>();
        for (Quote item : items){
            system.debug('vinay account state');
            system.debug(item.AccountId);
            if(item.AccountId != null){
                accIds.add(item.AccountId);
            }
        }
        List<Account> quoteAccs = AccountQueryUtil.fetchAccountsById(accIds);

        Map<String,String> accStateMap = new Map<String,String>();
        for(Account acc: quoteAccs){
            if(acc.BillingStateCode != null){
                if(!accStateMap.containsKey(acc.Id)){
                    accStateMap.put(acc.Id, acc.BillingStateCode);
                }
            }          
        }

        return accStateMap;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: templates - map of Coverage template
    * Params: q - Quote  
    * Return: List of Coverage__c
    * Description: Method to Get all Coverage from input map by Quote
    * Revision: 
    *************************************************/
    private static List<Coverage__c> getTemplateByQuote(Map<String, List<Coverage__c>> templates, Quote q) {
        List<Coverage__c> result = new List<Coverage__c>();
        List<String> productNames = getProductOptions(q); // get product options by quote
        String quoteLayer  = q.Layer__c;
        System.debug('quoteLayer::'+quoteLayer);
        try {
            if (q == null || templates.size() == 0) return result;
            
            for (String item : productNames) {
                // get templates by product name
                List<Coverage__c> coverageTemplates = templates.get(item);
                System.debug('coverageTemplates::'+coverageTemplates);
                // skip if no template is found
                if (coverageTemplates == null || coverageTemplates.isEmpty()) continue;

                if(item == 'Private Company Combo'){
                    List<Coverage__c> comboCoverages = new List<Coverage__c>();
                    if(q.OpportunityId != null){
                        if(oppComboProductsMap.containsKey(q.OpportunityId)){
                            List<String> oppProducts  = oppComboProductsMap.get(q.OpportunityId);
                            for(Coverage__c cov : coverageTemplates){
                                for(String oppProd : oppComboProductsMap.get(q.OpportunityId)){
                                    if(checkExistsCliDataForCoverageProduct(oppProd, q)) continue;
                                    if(cov.Coverage_Product_Combo__c != null && cov.Coverage_Product_Combo__c.contains(oppProd)){
                                        comboCoverages.add(cov);
                                        break;
                                    }
                                }                               
                            }
                        }
                    }

                    if(comboCoverages.size() == 0) continue;
                    List<Coverage__c> comboCoveragesFiltered = new List<Coverage__c>();
                    for(Coverage__c cov : comboCoverages){
                        if(cov.Apply_to_Quote__c == null || cov.Apply_to_Quote__c == '' || cov.Apply_to_Quote__c.contains(quoteLayer)){
                            comboCoveragesFiltered.add(cov);
                        }                             
                    }
                    coverageTemplates = comboCoveragesFiltered;
                }
            
                //if PI product - add coverages based on quote layer
                for(Coverage__c cov : coverageTemplates){
                    //system.debug('apply to quote:'+cov.Apply_to_Quote__c.contains(quoteLayer));
                    //Changes to not add Endorsement coverages when source is ShopX. US:57157
                    if(item != 'Professional Indemnity'){
                        if(cov.Coverage_Type__c == 'Endorsement' && q.Opportunity.LeadSource == 'Shopping X'
                           && !(cov.Coverage_Code__c == 'AcceleratorCyberInsuredPolicy')){
                            continue;
                        }
                        result.add(cov);  
                    }
                    system.debug('item:'+item);
                    if(item == 'Professional Indemnity' && cov.Apply_to_Quote__c.contains(quoteLayer)){
                        System.debug('condition OK!');
                        result.add(cov);
                    }
                }
                  
            }
        } catch (Exception ex) {
            system.debug('Ex '+ex.getMessage());
            result.clear(); 
        }
        System.debug('Cov added:'+result);
        return result;                         
    }

    private static Boolean checkExistsCliDataForCoverageProduct(String coverageProduct, Quote quoteItem) {
        if(quoteItem.Id == null || coverageProduct == null) return false;
        if(!quoteCoverageProdsMap.containsKey(quoteItem.Id)) return false;
        List<String> coverageProds = new List<String>();
        if(coverageProduct.contains(';')){
            coverageProds = coverageProduct.split(';');
        }
        else{
            coverageProds.add(coverageProduct);
        }
        Set<String> quoteCoverageProds = quoteCoverageProdsMap.get(quoteItem.Id);
        for(String covProd : coverageProds){
            if(quoteCoverageProds.contains(covProd)) return true;
        }
        return false;
    }

    private static Boolean checkExistsRmDataForCoverageProduct(String coverageProduct, Quote quoteItem) {
        if(quoteItem.Id == null || coverageProduct == null) return false;
        if(!quoteRmFactorsProdMap.containsKey(quoteItem.Id)) return false;
        List<String> coverageProds = new List<String>();
        if(coverageProduct.contains(';')){
            coverageProds = coverageProduct.split(';');
        }
        else{
            coverageProds.add(coverageProduct);
        }
        Set<String> quoteCoverageProds = quoteRmFactorsProdMap.get(quoteItem.Id);
        for(String covProd : coverageProds){
            if(quoteCoverageProds.contains(covProd)) return true;
        }
        return false;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: templates - List of Coverage__c
    * Params: quoteItem - Quote
    * Return: List of CoveragesLineItem__c
    * Description: Method to generate CoveragesLineItem__c based on Coverage__c
    * Revision: 
    *************************************************/
    private static List<CoveragesLineItem__c> generateCoverageLineItems(List<Coverage__c> templates, Quote quoteItem) {
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

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: obj - Coverage__c
    * Params: quoteItem - Quote
    * Return: List of Coverage Line Item
    * Description: Method to generate CoveragesLineItem__c based on Coverage__c
    * Revision: 
    *************************************************/
    private static List<CoveragesLineItem__c> GenerateCLIByCoverage(Coverage__c obj, Quote quoteItem) {
        System.debug('------GenerateCLIByCoverage-----');
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> limitItems = new List<CoveragesLineItem__c>();
        CoveragesLineItem__c cov = new CoveragesLineItem__c();
        Date effectiveDate; // add effective date to coverage line item
        if(quoteItem != null){
            //Assign Record type based on product of code of quote (added by Jai)
            if( quoteItem.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_CYBER ) ||
                quoteItem.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_MPL ) ||
                quoteItem.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PCC )
            ){
                cov.RecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
            }else if(quoteItem.Product_Name__c.equalsIgnoreCase( GlobalVariables.PROD_NAME_FOR_PI ) ){
                cov.RecordTypeId = CoveragesLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
            }

            if(quoteItem.Quote_Type__c == Label.Quote_Type_New_Business || quoteItem.Quote_Type__c == 'Renewal')
                effectiveDate = quoteItem.Effective_Date__c;
            else if(quoteItem.Quote_Type__c == Label.Quote_Type_Amendment)
                effectiveDate = quoteItem.Endorsement_Effective_Date__c;
            try {
                // create main coverage and sub coverage        
                cov.Quote__c = quoteItem.Id;
                cov.Coverage_Product__c = obj.Coverage_Product__c;
                if(obj.Coverage_Product__c == 'Private Company Combo' && obj.Coverage_Product_Combo__c != null && obj.Coverage_Product_Combo__c != ''){
                    cov.Coverage_Product_Combo__c = obj.Coverage_Product_Combo__c;
                    cov.Optional_Coverage_Name__c = obj.Optional_Coverage_Name__c;
                    cov.Optional_Factor_Label__c = obj.Optional_Factor_Label__c;
                }
                cov.Page_Section__c = obj.Page_Section__c;
                cov.Form_Number__c = obj.Form_Number__c; //Added 5/Oct/2020
                if(obj.Coverage_Type__c == 'Endorsement') //tuan.d.nguyen 3-Dec-2020 added
                    cov.Coverage_Effective_Date__c = effectiveDate;
                
                
                switch on obj.RecordType.Name {
                    when 'Main Coverage' {
                        cov.Coverage__c = obj.Id;
                        cov.Notes__c = obj.Default_Notes__c;//added by Jai
                    }
                    when 'Sub Coverage' {
                        cov.Coverage__c = obj.Coverage_or_Sub__c;
                        cov.Sub_Coverage__c = obj.Id;
                    }
                }
                System.debug('obj.FeaturesProductOptions__r'+obj.FeaturesProductOptions__r);
                // create limit and deductibles
                for (Coverage_Limits_Deductibles__c item : obj.FeaturesProductOptions__r) {
                    CoveragesLineItem__c cli = cov.clone(false, true, false, false);
                    cli.Limits_Deductibles__c = item.Id;
                    cli.Page_Section__c = item.Page_Section__c;
                    cli.Option_Type__c = item.Endorsement_Data_Type__c; // Added by Maeran Shaikh US:54202
                    
                    if(item.Option_Picklist__c != null ){
                        cli.Option_Picklist__c = item.Option_Picklist__c; // Added by Maeran for US: 54322 to add Picklist as an option for Limits and Deduc
                    }

                    if(String.isNotEmpty(item.Default_Value__c)){
                        cli.Option_Value_Default__c = item.Default_Value__c; // Added by Maeran on 28-1-22 for US:54292 
                    }
                    
                    if(obj.Coverage_Type__c == 'Endorsement') //tuan.d.nguyen 3-Dec-2020 added
                        cli.Coverage_Effective_Date__c = effectiveDate;
                    limitItems.add(cli);
                }
                
                result.add(cov);
                System.debug('covcount'+result.size());
                result.addAll(limitItems);
                System.debug('covcount'+result.size());
                
                System.debug('limitItems'+limitItems);
                System.debug('cov'+cov);
            } catch (Exception ex) {
                System.debug(ex.getMessage());
                result.clear();
            }
        }
        return result;  
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: items - List of Quotes
    * Return: void
    * Description: Method to add Quote Locations 
    * Revision: 
    *************************************************/
    public static void createPrimaryLocation(List<Quote> items) {
        Set<String> oppIds = new Set<String>();
        
        Savepoint sp = Database.setSavepoint();
        try {
            // get opportunity ids
            for (Quote item : items) {
                oppIds.add(item.OpportunityId);
            }
            
            //Method to get Opportunities
            List<Opportunity> opps = getOpportunities(oppIds);
            
            //Method to get List of Location__c records from Opportunities
            List<Location__c> locations = getLocationByOpportunity(opps);
            
            // generate locations map by opportunity
            Map<String, Location__c> locMap = generateLocationMap(opps, locations);
            
            upsert locMap.values();
            
            // generate new quote locations
            List<Quote_Location__c> quoteLocations = generateQuoteLocations(items, locMap);
            //GlobalStaticVar.byPassQuoteTrigger = true;
            insert quoteLocations;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            Database.rollback(sp);
            
            String errorMsg = 'Failed to create Primary Location.<br/>Please contact your administators.';
            for(Quote item : (List<Quote>)Trigger.new ){
                item.addError(errorMsg);
            }
        }
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: ids - List of Opportunity Ids
    * Return: List of Opportunity
    * Description: Method to get Opportunities
    * Revision: 
    *************************************************/
    private static List<Opportunity> getOpportunities(Set<String> ids) {
        List<Opportunity> result = new List<Opportunity>();
        // added by RINKU SAINI In Query Util 3rd Jan 2022
        result = OpportunityQueryUtil.fetchOpportunityByIdsSet(ids);
        return result;
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: items - List of Opportunities
    * Return: List of Location__c
    * Description: Method to get List of Location__c records from Opportunities
    * Revision: 
    *************************************************/
    private static List<Location__c> getLocationByOpportunity(List<Opportunity> items) {
        List<Location__c> result = new List<Location__c>();
        Set<String> streets = new Set<String>();
        Set<String> cities = new Set<String>();
        Set<String> states = new Set<String>();
        Set<String> zipCodes = new Set<String>();
        Set<String> countries = new Set<String>();
        
        try {
            // get conditions for locations
            for (Opportunity item : items) {
                if (String.isNotBlank(item.Account.BillingStreet)) {
                    streets.add(item.Account.BillingStreet);
                }      
                if (String.isNotBlank(item.Account.BillingCity)) {
                    cities.add(item.Account.BillingCity);
                }       
                if (String.isNotBlank(item.Account.BillingState)) {
                    states.add(item.Account.BillingState);
                }     
                if (String.isNotBlank(item.Account.BillingPostalCode)) {
                    zipCodes.add(item.Account.BillingPostalCode);
                }   
                if (String.isNotBlank(item.Account.BillingCountry)) {
                    countries.add(item.Account.BillingCountry);
                }
            }
            
            // get all locations
            // added by RINKU SAINI In Query Util 3rd Jan 2022
            result = LocationQueryUtil.fetchAllLocations(streets, cities, states, zipCodes, countries);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            result.clear();
        }
        
        return result;
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: opps - List of Opportunities
    * Params: locations - List of Locations
    * Return: Map of Location__c
    * Description: Method to get List of Location__c records from Opportunities
    * Revision: 
    *************************************************/
    public static Map<String, Location__c> generateLocationMap(List<Opportunity> opps, List<Location__c> locations) {
        Map<String, Location__c> result = new Map<String, Location__c>();
        for (Opportunity item : opps) {
            //Method to get Location__c records from account
            Location__c loc = getAccountLocation(item.Account, locations);
            
            // new location
            if (loc == null) {
                //Method to generate Location__c record from account
                loc = generateLocation(item.Account);
            }
            
            result.put(item.id, loc);
        }
        return result;
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: acc - Account
    * Params: allLocations - List of Locations
    * Return: Location__c
    * Description: Method to get Location__c records from account
    * Revision: 
    *************************************************/
    public static Location__c getAccountLocation(Account acc, List<Location__c> allLocations) {
        if (allLocations.isEmpty())
            return null;
        
        for (Location__c item : allLocations) {
            if (item.Address__c == acc.BillingStreet && 
                item.City__c == acc.BillingCity && 
                item.State_Province__c == acc.BillingState && 
                item.Postal_Code__c == acc.BillingPostalCode && 
                item.Country__c == acc.BillingCountry) {  
                    return item;
                }
        }
        
        return null;
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: acc - Account
    * Return: Location__c
    * Description: Method to generate Location__c record from account
    * Revision: 
    *************************************************/
    private static Location__c generateLocation(Account obj) {
        Location__c result = new Location__c();
        
        result.Address__c = obj.BillingStreet;
        result.City__c = obj.BillingCity;
        result.State_Province__c = obj.BillingState;
        if(obj.BillingStateCode == 'England'){
            result.State_Code__c = 'GB';
        }
        else{
            result.State_Code__c = obj.BillingStateCode;
        }
        result.Postal_Code__c = obj.BillingPostalCode;
        result.Country__c = obj.BillingCountry;
        result.County__c = obj.Billing_County__c;
        result.Country_Code__c = obj.BillingCountryCode;
        result.Geolocation__Longitude__s = obj.BillingLongitude;
        result.Geolocation__Latitude__s  = obj.BillingLatitude;
        
        return result;
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: items - List of Quotes
    * Params: obj - Map of Locations
    * Return: List of Quote_Location__c
    * Description: Method to generate Location__c record from account
    * Revision: 
    *************************************************/
    private static List<Quote_Location__c> generateQuoteLocations(List<Quote> items, Map<String, Location__c> obj) {
        List<Quote_Location__c> result = new List<Quote_Location__c>();
        for (Quote item : items) {
            // get location
            Location__c loc = obj.get(item.OpportunityId);
            
            // create new quote location
            Quote_Location__c temp = new Quote_Location__c();
            temp.Quote__c = item.Id;
            temp.Locations__c = loc.Id;
            temp.Primary_Location__c = true;
            
            result.add(temp);
        }
        return result;
    }

    /*************************************************
    * Author: Tuan.d.Nguyen
    * Date: 17-Mar-2020
    * Params: opps - List of Quote
    * Return: none
    * Description: Method to create rating modifier factor from template for each quote
    * Revision: 
    *************************************************/
    public static void AddRatingModifierFactor(List<Quote> quotes) {
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        Map<Id, Rating_Modifier_Template__c> templateMapWithModifiers = 
            new Map<Id, Rating_Modifier_Template__c>();
        List<Rating_Modifier_Factor__c> result = new List<Rating_Modifier_Factor__c>();
        List<Id> oppIds = new List<Id>();

        try {
            for (Quote q : quotes) {
                oppIds.add(q.OpportunityId);
            }
            //Method to get all Rating Modifiers from Opportunity Ids
            List<Rating_Modifiers__c> modifiers = getAllRatingModifiers(oppIds);

            /*system.debug('*************');
            for(Rating_Modifiers__c RM : modifiers){
                system.debug(RM.Controlling_Picklist_API_Name__c);
                system.debug(RM.Dependent_Picklist_API_Name__c);
            }
            system.debug('*************');*/

            //there is no rating modifier
            if (modifiers.isEmpty()) return;
            System.debug('Modifier length: ' + modifiers.size());
            
            //Method to get all Rating Modifier Templates from Rating Modifiers
            templates = getRatingTemplatesByModifier(modifiers);

            /*system.debug('#############');
            for(Rating_Modifier_Template__c RMT : templates){
                system.debug(RMT.Controlling_Picklist_API_Name__c);
                system.debug(RMT.Dependent_Picklist_API_Name__c);
            }
            system.debug('#############');*/

            // no templates is found
            if (templates.isEmpty()) return;
            System.debug('Template length: ' + templates.size());
            
            // map Rating_Modifier_Template__c with its Rating_Modifier_Code__c
            Map<String, Rating_Modifier_Template__c> templateMap = 
                new Map<String, Rating_Modifier_Template__c>();
            
            //Method to get Map of Rating Modifier Templates from Rating Modifier Templates
            templateMap = generateTemplateMap(templates);
            System.debug('TemplateMap length: ' + templateMap.size());
            
            // Method to get map Rating_Modifier_Template__c with Rating_Modifiers__c by Rating_Modifiers__c's Id
            templateMapWithModifiers = generateTemplateMapWithModifiers(templateMap, modifiers);
            System.debug('TemplateMapModifiers length: ' + templateMapWithModifiers.size());
            
            //Method to generate rating modifiers factor based on rating template
            result = generateModifiersFactorForInsert(templateMapWithModifiers, quotes);
            System.debug('Factor length: ' + result.size()); 
            //GlobalStaticVar.byPassQuoteTrigger = true;
            insert result;
            system.debug('*********');
            system.debug(result);
        } catch (Exception ex) {
            String errorMsg = 'Failed to create Rating Modifier Factor.<br/>Please contact your administators.';
            /*for(Quote item : newDataList ){
                item.addError(errorMsg);
            }*/
            System.debug('****####'+ex.getMessage());
        }
    }

    /*************************************************
    * Author: Tuan.d.Nguyen
    * Date: 17-Mar-2020
    * Params: opps - List of OppIds
    * Return: List of Rating Modifiers
    * Description: Method to get all Rating Modifiers from Opportunity Ids
    * Revision: 
    *************************************************/
    private static List<Rating_Modifiers__c> getAllRatingModifiers(List<Id> items) {
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        List<String> displayFormatList = new List<String>{'Clearance', 'Primary Modifiers', 'Secondary Modifiers', 'Factor Values Only','Default Only'};
            // added by RINKU SAINI In Query Util 3rd Jan 2022
            result = RatingModifierQueryUtil.fetchRatingModifiersByDisplayFormate(items,displayFormatList);        
                      
            List<Rating_Modifiers__c> availableRatingMods = new List<Rating_Modifiers__c>();
            for(Rating_Modifiers__c rMod : result){
                if(rMod.Opportunity__r.Product_Name__c != 'Private Company Combo') availableRatingMods.add(rMod);
                List<String> oppProducts = oppComboProductsMap.get(rMod.Opportunity__c);
                if(oppProducts!=null){
                    if(oppProducts.contains(rMod.Product__c)){
                        availableRatingMods.add(rMod);
                    }
                }
            }
            return availableRatingMods;
    }

    /*************************************************
    * Author: Tuan.d.Nguyen
    * Date: 17-Mar-2020
    * Params: items - List of Rating Modifiers
    * Return: List of Rating Modifier Templates
    * Description: Method to get all Rating Modifier Templates from Rating Modifiers
    * Revision: 
    *************************************************/
    private static List<Rating_Modifier_Template__c> getRatingTemplatesByModifier(List<Rating_Modifiers__c> items) {
        List<Rating_Modifier_Template__c> result = new List<Rating_Modifier_Template__c>();
        List<String> codes = new List<String>();
        
        for (Rating_Modifiers__c item : items) {
            if (String.isBlank(item.Rating_Modifier_Code__c )) 
                continue;
            
            codes.add(item.Rating_Modifier_Code__c);
        }
        system.debug('codes '+codes);
        result = [SELECT Id, name, Rating_Modifier_Code__c, Product__c,
                  Factor_Default_Value__c, Factor_Max__c, Factor_Min__c
                  FROM Rating_Modifier_Template__c 
                  WHERE Rating_Modifier_Code__c IN :codes and Display_Format__c != 'Clearance'];
        system.debug('result  '+result);
        return result;
    }

    /*************************************************
    * Author: Tuan.d.Nguyen
    * Date: 17-Mar-2020
    * Params: templates - List of Rating Modifier Templates
    * Return: Map of Rating Modifier Templates
    * Description: Method to get Map of Rating Modifier Templates from Rating Modifier Templates
    * Revision: 
    *************************************************/
    private static Map<String, Rating_Modifier_Template__c> generateTemplateMap(List<Rating_Modifier_Template__c> templates) {
        Map<String, Rating_Modifier_Template__c> result = new Map<String, Rating_Modifier_Template__c>();
        for(Rating_Modifier_Template__c template : templates) {
            result.put(template.Rating_Modifier_Code__c, template);
        }
        return result;
    }

    /*************************************************
    * Author: Tuan.d.Nguyen
    * Date: 17-Mar-2020
    * Params: templatesMap - Map of Rating Modifier template
    * Params: items - Map of Rating Modifiers
    * Return: Map of Rating_Modifier_Template__c
    * Description: Method to get map Rating_Modifier_Template__c with Rating_Modifiers__c by Rating_Modifiers__c's Id
    * Revision: 
    *************************************************/
    private static Map<Id, Rating_Modifier_Template__c> generateTemplateMapWithModifiers(Map<String, Rating_Modifier_Template__c> templatesMap,
    List<Rating_Modifiers__c> items) {
        Map<Id, Rating_Modifier_Template__c> result = new Map<Id, Rating_Modifier_Template__c>();
        try {
            for(Rating_Modifiers__c item : items) {
                Rating_Modifier_Template__c obj = templatesMap.get(item.Rating_Modifier_Code__c);
                if(item != null && item.Display_Format__c != 'Clearance') {
                    result.put(item.Id, obj);
                }
            }
        } catch (Exception ex) {
            result.clear();
        }
        return result;
    }

    /*************************************************
    * Author: Tuan.d.Nguyen
    * Date: 17-Mar-2020
    * Params: Map of Rating Modifier Templates with Rating Modifiers Id, List of Quotes
    * Return: Map of Rating Modifier Template with Id of Rating Modifier
    * Description: Method to generate rating modifiers factor based on rating template
    * Revision: 
    *************************************************/
    private static List<Rating_Modifier_Factor__c> generateModifiersFactorForInsert(Map<Id, Rating_Modifier_Template__c> templateMapWithModifiers, List<Quote> quotes) {
        List<Rating_Modifier_Factor__c> result = new List<Rating_Modifier_Factor__c>();
        try{
            //generate Factor for each quote
            for(Quote q : quotes) {
                for (Id modifierId : templateMapWithModifiers.keySet()) {
                    Rating_Modifier_Template__c item = templateMapWithModifiers.get(modifierId);
                    if(checkExistsRmDataForCoverageProduct(item.Product__c, q)) continue;
                    if(item != null) {
                        Rating_Modifier_Factor__c factor = new Rating_Modifier_Factor__c();
                        
                        factor.Factor_Default_Value__c = item.Factor_Default_Value__c;
                        factor.Factor_Max__c = item.Factor_Max__c;
                        factor.Factor_Min__c = item.Factor_Min__c;
                        //factor.Factor_Value__c = item.Factor_Value__c;
                        factor.Quote__c = q.Id;
                        factor.Rating_Modifier__c = modifierId;
                        result.add(factor);
                    }
                    
                }
            }
        } catch(Exception ex) {
            System.debug('Exception: ' + ex.getMessage() + ex.getLineNumber());
        }
        return result;                                                            
    }

    /*************************************************
    * Author: Hoang Bui
    * Date: 22-Oct-19
    * Params: Map<Id,Quote> oldDataMap, Map<Id,Quote> oldDataMap
    * Return: Void
    * Description: Method to generate Quote Documanet for each quote
    **************************************************/
    public static void generatedQuoteDocument(Map<Id,Quote> oldDataMap, Map<Id,Quote> newDataMap){

        Set<Id> idQuotes = getApprovedQuoteIds(oldDataMap, newDataMap);
        if (!idQuotes.isEmpty()){
            generatedQuoteDocument(idQuotes);
        } 

    }

    /*************************************************
    * Method Name: getApprovedQuoteIds
    * Author: Hoang Bui
    * Date: 22-Oct-19
    * Params: Map<Id,Quote> oldDataMap, Map<Id,Quote> oldDataMap
    * Return: Set of Quote Id
    * Description: Mathod to get Approved Quote Ids
    * Exceptions:
    * Revision: 
    **************************************************/
    public static Set<Id> getApprovedQuoteIds(Map<Id,Quote> oldDataMap, Map<Id,Quote> newDataMap){
        Set<Id> ids = new Set<Id>();
        for(Id key : oldDataMap.Keyset()){
            if(oldDataMap.get(key) != null && newDataMap.get(key) != null) {
                if(!oldDataMap.get(key).Generate_Quote_Document__c && newDataMap.get(key).Generate_Quote_Document__c && newDataMap.get(key).Quote_Type__c == 'New Business')
                    ids.add(key);            
            }
        }
        return ids;
    }

    /*************************************************
    * Method Name: generatedQuoteDocument
    * Author: Hoang Bui
    * Date: 22-Oct-19
    * Params: Set<Id> quoteIds
    * Return: 
    * Description: Method to generate Quote Documanet from Quote Ids
    * Exceptions:
    * Revision: 
    **************************************************/
    @future (callout = true)
    public static void generatedQuoteDocument(Set<Id> quoteIds){
        List<Quote> quotes = new List<Quote>();
        for(Quote quote : [Select Id,Generate_Quote_Document__c From Quote where id in :quoteIds]){
            //Call out GenerateQuoteDocumentController
            GenerateQuoteDocumentController.generateDocId(quote.Id,'QuoteProposal');
            quote.Generate_Quote_Document__c = false;//reset value
            quotes.add(quote);           
        }
        if(!quotes.isEmpty()){
            TriggerHandler.bypass('QuoteTriggerBaseHandler');
            update quotes;
            TriggerHandler.clearBypass('QuoteTriggerBaseHandler');          
        }
    }

    /*************************************************
    * Author: Hoang Bui
    * Date: 22-Oct-19
    * Params: List<Quote> items, Map<Id,Quote> oldDataMap
    * Return: List of Quotes
    * Description: Method to get List of chamged Quote
    **************************************************/
    public static List<Quote> getChangedQuotes(List<Quote> items,Map<Id,Quote> oldDataMap) {
        List<Quote> result = new List<Quote>();
        for (Quote item : items) {
            //Method to get true if Coverage_Product_Options__c is changes on quote
            if (isProductChanged(item,oldDataMap.get(item.Id))) result.add(item);
        }
        
        return result;
    }
    
    /*************************************************
    * Author: Hoang Bui
    * Date: 22-Oct-19
    * Params: Quote newItem, Quote oldItem
    * Return: Void
    * Description: Method to get true if Coverage_Product_Options__c is changes on quote
    **************************************************/
    public static boolean isProductChanged(Quote newItem, Quote oldItem) {
        
        if (oldItem == null || newItem == null) 
            return false;
        if (oldItem.Coverage_Product_Options__c != newItem.Coverage_Product_Options__c)
            return true;
        
        return false;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: items - List of Quotes
    * Params: oldDataMap - map of oldQuotes
    * Return: none
    * Description: Method to create Coverage Line Items from Coverage for each Quote
    * Revision: 
    *************************************************/
    public static void updateCoverageLineItems(List<Quote> items,Map<Id,Quote> oldDataMap) {
        List<Coverage__c> templates = new List<Coverage__c>();
        Map<String, List<Coverage__c>> templateMap = new Map<String, List<Coverage__c>>();
        List<CoveragesLineItem__c> existedCoverages = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> newCoverages = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> deleteCoverages = new List<CoveragesLineItem__c>();
        List<Quote> quotes = new List<Quote>();
        
        Savepoint sp = Database.setSavepoint();
        try {
            //Method to get List of chamged Quote
            quotes = getChangedQuotes(items,oldDataMap);
            if (quotes == null || quotes.isEmpty()) 
                return;
            
            List<String> products = getAllProductOptions(quotes);
            
            // no product is found
            if (products.isEmpty()) return;
            
            templates = getCoverageByProducts(products);
            
            // no templates is found
            if (templates.isEmpty()) return;
            
            // store all template in map to reduce soql query
            templateMap = generateTemplateMap(templates);
            // put quote into map to get its id set
            Map<String, Quote> quoteMap = generateQuoteMap(quotes);
            List<String> quoteIds = new List<String>();
            quoteIds.addAll(quoteMap.keySet());
            
            existedCoverages = CommonUtil.getCoveragesLineItemsByQuotes(quoteIds);
            
            //Method to get list products from a list of Rating Modifier
            List<String> existedProducts = getAllProductOptions(existedCoverages);
            
            //Method to get the items from old list which doesn't existed in the new list
            List<String> removedProducts = getRemovedItems(existedProducts, products);
            
            // get Coverage line item for deleting
            deleteCoverages = generateCoverageForDelete(existedCoverages, removedProducts);
            
            // get template for inserting
            Map<String, List<Coverage__c>> insertTemplateMap = 
                getTemplateForInsert(templateMap, existedProducts);
            
            // generate coverage line item for inserting
            newCoverages = generateCoverageForInsert(insertTemplateMap, quotes);
            
            insert newCoverages;
            delete deleteCoverages;
        } catch (Exception ex) {
            // rollback data 
            Database.rollback(sp);
            String errorMsg = 'Failed to update Coverage Line Item.<br/>Please contact your administators.';
            for(Quote item : (List<Quote>)Trigger.new ){
                item.addError(errorMsg);
            }
        }
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: item - List of Opportunity
    * Description: Method to get list products from a list of Rating Modifier
    * Revision: 
    *************************************************/
    private static List<String> getAllProductOptions(List<CoveragesLineItem__c> items) {
        Set<String> productOptions = new Set<String>();
        try {
            for (CoveragesLineItem__c item : items){
                if (String.isBlank(item.Coverage_Product__c))
                    continue;
                
                productOptions.add(item.Coverage_Product__c);    
            }
        } catch (Exception ex){
            productOptions.clear();
        }
        return new List<String>(productOptions);    
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: oldItems - old items 
    * Params: newItems - new items
    * returns: Lst of string
    * Description: Method to get the items from old list which doesn't existed in the new list
    * Revision: 
    *************************************************/
    private static List<String> getRemovedItems(List<String> oldItems, List<String> newItems) {
        List<String> result = new List<String>();
        try {
            Set<String> oldSet = new Set<String>(oldItems);
            oldSet.removeAll(newItems);
            
            result = new List<String>(oldSet);
        } catch (Exception ex) {
            
        }
        return result;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: items - List of existing Coverage Line Item
    * Params: products - products need to be removed
    * Returns: List of CoveragesLineItem__c
    * Description: Generate list CoveragesLineItem__c for insert
    * Revision: 
    *************************************************/ 
    private static List<CoveragesLineItem__c> generateCoverageForDelete(List<CoveragesLineItem__c> items,
    List<String> products) {
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            for (CoveragesLineItem__c item : items) {
                if (!products.contains(item.Coverage_Product__c))
                    continue;
                
                result.add(item);
            }
        } catch (Exception ex) {
            result.clear();
        }
        
        return result;                                                            
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: items - List of Quote
    * Returns: Map of Quote
    * Description: Method to generate quote map
    * Revision: 
    *************************************************/ 
    private static Map<String, Quote> generateQuoteMap(List<Quote> items) {
        Map<String, Quote> result = new Map<String, Quote>();
        if (items.isEmpty()) return result;
        
        for(Quote item : items) {
            result.put(item.Id, item);
        }
        return result;
    }

    /*************************************************
    * Author: Tuan Nguyen
    * Date: 23-Aug-2019
    * Params: obj - Coverage map
    * Params: products - list of removed products
    * Description: remove template from certain products
    * Revision: 
    *************************************************/
    private static Map<String, List<Coverage__c>> getTemplateForInsert(Map<String, List<Coverage__c>> obj, 
        List<String> products) {
        Map<String, List<Coverage__c>> result = new Map<String, List<Coverage__c>>();
        result = obj.clone();
        
        for (String item : products) {
            result.remove(item);
        }
        return result;                                                                    
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: newList - List Quote
    * Returns: Void
    * Description: Method to Count open Subjectivities on quote and update on Policy
    * Revision: 
    *************************************************/
    public static void countOpenSubjectivityOnBoundQuote(List<Quote> newList) {
        Set<String> policyIds = new Set<String>();
        for(Quote quote : newList) {
            if(quote.Status == 'Bound' && quote.Policy__c != null) {
                policyIds.add(quote.Policy__c);
            }
        }
         List<Policy__c> lstPolicy = new List<Policy__c>();
        if(!policyIds.isEmpty()){
        lstPolicy = new List<Policy__c>([SELECT Id,Number_Open_Subjectivity_Bound_Quote__c,
                                                         (SELECT Id,Number_Subjectivity__c FROM Quotes__r WHERE Status = 'Bound')
                                                         FROM Policy__c where Id IN: policyIds]);
        }
        if(!lstPolicy.isEmpty()) {
            for(Policy__c policy : lstPolicy) {
                Decimal sum = 0;
                for(Quote quote : policy.Quotes__r) {
                    sum += quote.Number_Subjectivity__c;
                }
                policy.Number_Open_Subjectivity_Bound_Quote__c = sum;
            }
            
            
            TriggerHandler.bypass('PolicyTriggerBaseHandler');
            update lstPolicy;
            TriggerHandler.clearBypass('PolicyTriggerBaseHandler');
            
        }
        
    }

    /*************************************************
    * Method Name: updateCliEffectiveDate
    * Author: tuan.d.nguyen
    * Date: 11-Dec-2020
    * Params: Map<String, Quote> oldQuoteMap, List<Quote> newQuoteList
    * Return: 
    * Description: Method to update Coverage_Effective_Date__c of CoveragesLineItem__c when quote is update
    *************************************************/
    public static void updateCliEffectiveDate(List<Quote> newQuoteList, Map<Id, Quote> oldQuoteMap) { 
        try {
            Map<Id, Quote> updateEffectiveDateQuoteMap = new Map<Id, Quote>();
            //get the changed effective date quote and put it in the map
            for(Quote q : newQuoteList) {
                if(oldQuoteMap.get(q.Id) != null) {
                    if((q.Quote_Type__c == Label.Quote_Type_New_Business && oldQuoteMap.get(q.Id).Effective_Date__c != q.Effective_Date__c)
                    || (q.Quote_Type__c == Label.Quote_Type_Amendment && oldQuoteMap.get(q.Id).Endorsement_Effective_Date__c != q.Endorsement_Effective_Date__c)
                       //added by Yogesh Mandlik for 58840
                    || ((q.Quote_Type__c == Label.Quote_Type_Renewal && oldQuoteMap.get(q.Id).Effective_Date__c != q.Effective_Date__c) && (q.Product_Name__c =='Cyber Standalone'||q.Product_Name__c =='Private Company Combo'||q.Product_Name__c =='MPL Standalone')))
                        updateEffectiveDateQuoteMap.put(q.Id, q); //get all the quote that change effective date
                }
            }
            
            Map<Id, List<CoveragesLineItem__c>> mapCLI = new Map<Id, List<CoveragesLineItem__c>>();
            
            List<CoveragesLineItem__c> listUpdateCLI = new List<CoveragesLineItem__c>();
            if(!updateEffectiveDateQuoteMap.keySet().isEmpty()){
                // added by RINKU SAINI In Query Util 3rd Jan 2022
                system.debug('test>>'+CoverageLineItemQueryUtil.fetchCLIsByCoverageTypeAndQuotes(updateEffectiveDateQuoteMap.keySet()));
                for(CoveragesLineItem__c cli: CoverageLineItemQueryUtil.fetchCLIsByCoverageTypeAndQuotes(updateEffectiveDateQuoteMap.keySet()) ){
                    system.debug('test1>>'+cli.Quote__r.Product_Name__c);
                    //query the coverage line item base on the quote map and put it in the map with format map<QuoteId, List CoveragesLineItem of that quote>
                    if(mapCLI.get(cli.Quote__c) == null) {
                        mapCLI.put(cli.Quote__c, new List<CoveragesLineItem__c>{cli});
                    } else {
                        List<CoveragesLineItem__c> items = mapCLI.get(cli.Quote__c);
                        items.add(cli);
                        mapCLI.put(cli.Quote__c, items);
                    }
                }
            
            
            for(Id quoteId : updateEffectiveDateQuoteMap.keySet()) {
                Quote q = updateEffectiveDateQuoteMap.get(quoteId);
                if(mapCLI.get(q.Id) != null) {
                    for(CoveragesLineItem__c cli : mapCLI.get(q.Id)) {
                        //For all Coverage Line Items of type = Endorsement, this Coverage_Effective_Date__c should be set to
                        // equal the Quote Effective Date for New Business Quotes and the Endorsement Effective Date for Amendment Quotes. 
                        if(q.Quote_Type__c == Label.Quote_Type_New_Business) {
                            cli.Coverage_Effective_Date__c = q.Effective_Date__c;
                        } else if(q.Quote_Type__c == Label.Quote_Type_Amendment) {
                            cli.Coverage_Effective_Date__c = q.Endorsement_Effective_Date__c;
                        } else if(q.Quote_Type__c == Label.Quote_Type_Renewal) {//added by Yogesh Mandlik for 58840
                            cli.Coverage_Effective_Date__c = q.Effective_Date__c;
                        }
                        listUpdateCLI.add(cli);
                    }
                }
            } 
        }   
            if(!listUpdateCLI.isEmpty())
                update listUpdateCLI;
        } catch(Exception ex) {
            System.debug('Update coveragesLineItem effective date failed: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
        }
    }

    /*************************************************
    * Author: Altaf Pawaskar
    * Date: 
    * Params: Map<String, Quote> oldQuoteMap, List<Quote> newDataList
    * Return:  Void
    * Description: Method to make sync Callout
    *************************************************/
    public static void syncCallout(List<Quote> newDataList,Map<Id, Quote> oldDataMap) { 

        List<Quote> syncQuotes = new List<Quote>();
        List<Quote> finalQuotes1 = new List<Quote>();
        for(Quote newQuote : newDataList){
            System.debug('newQuote>>' + newQuote);
            if(newQuote.Status != 'In Progress' && newQuote.Status != oldDataMap.get(newQuote.Id).Status
            && (newQuote.Product_Name__c != 'Professional Indemnity' || (newQuote.Product_Name__c == 'Professional Indemnity' && newQuote.Status != 'Quoted' && newQuote.Status != 'Bound' && newQuote.Status != 'Rated')))
            {   
                System.debug('syncQuotes for PCC -->'+syncQuotes);
                syncQuotes.add(newQuote);
            }
            //Condition for Approval
            if(newQuote.Status == 'Rated' && newQuote.Rating_Status__c != oldDataMap.get(newQuote.Id).Rating_Status__c 
            && oldDataMap.get(newQuote.Id).Rating_Status__c == 'Refer' && newQuote.Product_Name__c != 'Professional Indemnity'){
                finalQuotes1.add(newQuote);
                system.debug('Final Quotes-->'+finalQuotes1);
             }
        }
        //if (UserInfo.getName() != Label.IntegrationAPI){ //To run this change the label value to correct user name  
        
      try{
        if(!syncQuotes.isEmpty() && finalQuotes1.isEmpty()) {
            System.debug('SyncQuoteBatch Run from TriggerHandler'+syncQuotes);
            system.debug('Limits -->'+Limits.getQueueableJobs());
            if(Limits.getQueueableJobs() == 0 )
            ID jobID = System.enqueueJob(new SyncQuoteQueueable(syncQuotes));
         }
             //Finalize call to make in case if the quote is approved for binding in ShopX
             //This will generate the document from ShopX directly, so no need to make document call
        if(!finalQuotes1.isEmpty() && Limits.getQueueableJobs() == 0 ){
                system.debug('Limits 2-->'+Limits.getQueueableJobs());
                System.debug('Finalizing the quote on Approved');
                ID jobID = System.enqueueJob(new FinalizeQueuable(finalQuotes1));
         }
        }catch(Exception e){
               system.debug('Error-->'+e);
        
        }
 
    }

}