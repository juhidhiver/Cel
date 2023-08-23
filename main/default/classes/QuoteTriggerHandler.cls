/**************************************************************************************************
* Class Name: QuoteTriggerHandler
* Author: Binh Dang
* Date: 04-May-2019
* Description: Handler for QuoteTrigger
**************************************************************************************************/
public with sharing class QuoteTriggerHandler extends TriggerHandler{
    private List<Quote> oldDataList;
    private List<Quote> newDataList;
    private Map<Id, Quote> newDataMap;
    private Map<Id, Quote> oldDataMap;
    private static Map<String, List<String>> oppComboProductsMap = new Map<String, List<String>>();

    public QuoteTriggerHandler(List<Quote> quotes){
        this.newDataList = quotes;
        //delete existing clis and rmfs
        this.cleanupRMFAndCLI(this.newDataList);
        //generate opp combro product map
        QuoteTriggerHandler.generateSubmissionPoliMap(this.newDataList);
        //generate coverage line items
        this.AddCoverageLineItems(this.newDataList);
        //generate rating modifier factors
        this.AddRatingModifierFactor(this.newDataList);
    }
    
    public QuoteTriggerHandler (){  
        this.oldDataList = (List<Quote>) Trigger.old;
        this.oldDataMap = (Map<Id, Quote>) Trigger.oldMap;
        // this.newDataList = (List<Quote>) Trigger.new;
        // this.newDataMap = (Map<Id, Quote>) Trigger.newMap;
        List<Quote> tempDataList = (List<Quote>) Trigger.new;
        Map<Id, Quote> tempDataMap = (Map<Id, Quote>) Trigger.newMap;
        
        // skip record copy
        this.newDataList = new List<Quote>();
        this.newDataMap = new Map<Id, Quote>();
        if(tempDataMap == null) {
            tempDataMap = new Map<Id, Quote>();
        }
        
        for(Quote qt : tempDataList) {
            if(!qt.isClone()) {
                this.newDataList.add(qt);
                
                if(tempDataMap.containsKey(qt.Id)) {
                    this.newDataMap.put(qt.Id, tempDataMap.get(qt.Id));
                }
            }
        }
    }
    
    public override void beforeInsert() {
        //CommonUtil.generateExternalID('Azure_Id__c', newDataList); //Commented as a part of #33240
        
        //for update the Broker Name/Broker email
        updateQuoteWithBrokerName(newDataList);
        updateCommission(newDataList);
        
        List<Quote> aqueousQuote = new List<Quote>();
        List<Quote> celerityQuote = new List<Quote>();
        boolean isPccQuote = false;
        for(Quote newQuote : this.newDataList){
            if(newQuote.Product_Name__c == 'Professional Indemnity'){
                aqueousQuote.add(newQuote);
            }else{
             if(newQuote.Product_Name__c == 'MPL Standalone' || newQuote.Product_Name__c == 'Cyber Standalone' || newQuote.Product_Name__c == System.label.Product_Name_for_PCC)  
                celerityQuote.add(newQuote);
            }
            if(newQuote.Product_Name__c == System.label.Product_Name_for_PCC){
                isPccQuote = true;
            }
        }
        if(isPccQuote){
            generateSubmissionPoliMap(newDataList);
            checkValidQuoteComboCoverageOptions(newDataList);
        }
        if(!celerityQuote.isEmpty()){
              pendingOrPriorProceedingsDate(celerityQuote);
        }
        if(!aqueousQuote.isEmpty()){
            setRetroactiveDate(aqueousQuote);
        }
       
    }
    
    public override void beforeUpdate() {
        List<Quote> aqueousQuote = new List<Quote>();
        List<Quote> celerityQuote = new List<Quote>();
        //List<Quote> celerityRenewalQuote = new List<Quote>();
        boolean isPccQuote = false;
        for(Quote newQuote : this.newDataList){
            if(newQuote.Product_Name__c == 'Professional Indemnity'){
                aqueousQuote.add(newQuote);
            }else{
             if(newQuote.Product_Name__c == 'MPL Standalone' || newQuote.Product_Name__c == 'Cyber Standalone' || newQuote.Product_Name__c == System.label.Product_Name_for_PCC)  
                celerityQuote.add(newQuote);
        }
        if(newQuote.Product_Name__c == System.label.Product_Name_for_PCC){
            isPccQuote = true;
        }
        }

        if(isPccQuote){
            generateSubmissionPoliMap(newDataList);
            checkValidQuoteComboCoverageOptions(newDataList);
        }
        
        //for update the Broker Name/Broker email
        updateQuoteWithBrokerName(newDataList);        
        //Change the status to In Progress
        //updateQuoteStatusToInProgress(newDataList, oldDataMap);
        lockEditOnQuote(newDataList, oldDataMap);
        //Prachi added
        sendEmailToApprovalSubmitter(this.newDataList,this.oldDataMap);
        if(!aqueousQuote.isEmpty()){
            checkBinderAssignForQuote(this.newDataList,this.oldDataMap);
        	checkQuoteDocLinksAssign(this.newDataList,this.oldDataMap);
            approveRejectReferralReasons(aqueousQuote);
            populatePremiumFields();
        }
        checkForceRating();
        updateQuoteBoundDate(this.newDataList,this.oldDataMap);
         //Added by Ashik on 27-July-2021
        if(!celerityQuote.isEmpty()){
            declinedsubmissionQuote(celerityQuote);
           //pendingOrPriorProceedingsDate(celerityQuote);
        }
    }
    
    public override void afterInsert(){
        List<Quote> aqueousQuote = new List<Quote>();
        List<Quote> celerityQuote = new List<Quote>();
        for(Quote newQuote : this.newDataList){
            if(newQuote.Product_Name__c == 'Professional Indemnity'){
                aqueousQuote.add(newQuote);
            }else{
                celerityQuote.add(newQuote);
            }
            
        }
        if(!aqueousQuote.isEmpty()) createInsurerExcess(aqueousQuote);
        if(!celerityQuote.isEmpty())createSubjectivityByDefaultCelerity(celerityQuote);
        AddCoverageLineItems(this.newDataList); 
        createPrimaryLocation(this.newDataList);
        AddRatingModifierFactor(this.newDataList);
        createSubjectivityIfProposalFormDateEmpty(this.newDataList);
        if(!aqueousQuote.isEmpty()){
            //Update the Status to Bound - In Waiting on insertion of a new Quote
            updateBoundSubmissionStatus(aqueousQuote);
            addQuoteOptions(this.newDataList);
            addDefaultCoverages(aqueousQuote);
        }
    }
    
    public override void afterUpdate() { 
        List<Quote> aqueousQuote = new List<Quote>();
        List<Quote> syncQuotes = new List<Quote>();
        for(Quote newQuote : newDataList){
            if(newQuote.Product_Name__c == 'Professional Indemnity'){
                aqueousQuote.add(newQuote);
            }
            if(newQuote.Status != 'In Progress' && newQuote.Status != oldDataMap.get(newQuote.Id).Status
            && (newQuote.Product_Name__c != 'Professional Indemnity' || (newQuote.Product_Name__c == 'Professional Indemnity' && newQuote.Status != 'Quoted' && newQuote.Status != 'Bound')))
            {
                syncQuotes.add(newQuote);
            }
        }
        if(!aqueousQuote.isEmpty()) handleExcessInsurerUnderlying(aqueousQuote,oldDataMap);
        
        Set<Id> idQuotes = getApprovedQuoteIds(oldDataMap, newDataMap);
        if (!idQuotes.isEmpty()){
            generatedQuoteDocument(idQuotes);
        }  
        
        List<Quote> items = getChangedQuotes(this.newDataList);
        UpdateCoverageLineItems(items);
        
        //UpdateRatingModifierFactor(newDataList);
        countOpenSubjectivityOnBoundQuote(this.newDataList);
        
        //if (UserInfo.getName() != Label.IntegrationAPI){ //To run this change the label value to correct user name  
        if(!syncQuotes.isEmpty())   
        {
            ID jobID = System.enqueueJob(new SyncQuoteQueueable(syncQuotes));
        }
        //update coveragelineItem effective date
        updateCliEffectiveDate(this.newDataList, this.oldDataMap);
        
        //update submission status to Bound if quote is bound
        if(!aqueousQuote.isEmpty()){
            updateSubmissionStatusToBound(aqueousQuote);
            updateQuoteStatusToQuoted(aqueousQuote,oldDataMap);
            updateQuoteStatusToReferred(aqueousQuote,oldDataMap);
            updateSubmissionStatus(aqueousQuote,oldDataMap);   
            calculatePremiumFields();
            removeDuplicateQuoteOption();
            CommonUtilAQ.removeApprovalRequestsFromQuote(aqueousQuote,oldDataMap);
        }
    }

    public void cleanupRMFAndCLI(List<Quote> quotes){
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
    }
    
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
    
    
    
    private List<Quote> getChangedQuotes(List<Quote> items) {
        List<Quote> result = new List<Quote>();
        for (Quote item : items) {
            if (isProductChanged(item.Id)) result.add(item);
        }
        
        return result;
    }
    
    private boolean isProductChanged(String id) {
        Quote oldItem = this.oldDataMap.get(id);
        Quote newItem = this.newDataMap.get(id);
        
        if (oldItem == null || newItem == null) 
            return false;
        
        if (oldItem.Coverage_Product_Options__c != newItem.Coverage_Product_Options__c)
            return true;
        
        return false;
    }
    
    private List<String> getProductOptions(Quote item) {
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
                    result.add('Excess');
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
    
    //Get all products from Quote list
    private List<String> getAllProductOptions(List<Quote> items) {
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
* Params: opps - List of Opportunity
* Return: none
* Description: Create rating modifier from template for each opportunity
* Revision: 
*************************************************/
    private void AddCoverageLineItems(List<Quote> quotes) {
        system.debug(quotes);
        List<Coverage__c> templates = new List<Coverage__c>();
        Map<String, List<Coverage__c>> templateMap = new Map<String, List<Coverage__c>>();
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        try {
            List<String> products = getAllProductOptions(quotes);
            System.debug('products'+products);
            //there is no products
            if(products.isEmpty()) return; 
            
            templates = getCoverageByProducts(products);
            
            // no templates is found
            if (templates.isEmpty()) return;
            
            // store all template in map to reduce soql query
            templateMap = generateTemplateMap(templates);
            result = generateCoverageForInsert(templateMap, quotes);
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
* Params: opps - List of Opportunity
* Return: none
* Description: Create rating modifier from template for each opportunity
* Revision: 
*************************************************/
    private void UpdateCoverageLineItems(List<Quote> quotes) {
        List<Coverage__c> templates = new List<Coverage__c>();
        Map<String, List<Coverage__c>> templateMap = new Map<String, List<Coverage__c>>();
        List<CoveragesLineItem__c> existedCoverages = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> newCoverages = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> deleteCoverages = new List<CoveragesLineItem__c>();
        
        Savepoint sp = Database.setSavepoint();
        try {
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
            
            // get existed products  
            List<String> existedProducts = getAllProductOptions(existedCoverages);
            
            // get removed products
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
* Params: templates - List of Rating template
* Return: Map of Rating_Modifier_Template__c
* Description: generate a map to store all rating template by product name
* Revision: 
*************************************************/
    private Map<String, List<Coverage__c>> generateTemplateMap(List<Coverage__c> items) {
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
    
    /***********************************************************************
* Author: Tuan Nguyen
* Date: 22-Aug-2019
* Params: Coverage Products  
* Return: List of Coverages with both of Endorsements and Coverages in Coverage Types
* Description: These Load by Default Endorsements are currently Coverages that we will move back to 
*              Coverage Type = Endorsement and mark as Load by Default
* Revision: 
************************************************************************/
    public static List<Coverage__c> getCoverageByProducts(List<String> products) {
        List<Coverage__c> result = new List<Coverage__c>();
        try {
            //Get both Endorsements & Coverages
            //-->for Endorsements, adding a condition Additional_Requirements = 'Load by Default' 
            result = [Select Id,Coverage_Product__c,Coverage_Product_Combo__c,RecordType.Name,Coverage_or_Sub__c,Coverage_Type__c,Page_Section__c,Form_Number__c,Apply_to_Quote__c,
                      (Select Id,RecordTypeId,RecordType.Name,Page_Section__c From FeaturesProductOptions__r)
                      From Coverage__c 
                      Where ((Coverage_Type__c = 'Endorsement' AND Additional_Requirements__c INCLUDES ('Load by Default')) 
                             OR Coverage_Type__c != 'Endorsement') 
                      AND Coverage_Product__c In: products]; //Khanh-29Sept20
        } catch (Exception ex) {
            result = new List<Coverage__c>();
        }
        System.debug('getCoverageByProducts '+result);
        return result;
    }
    
    private Map<String, Quote> generateQuoteMap(List<Quote> items) {
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
* Params: templateMap - Map of rating templates
* Params: items - List of Opportunity
* Return: none
* Description: Delete old rating modifiers and add new ones based on coverage product options
* Revision: 
*************************************************/ 
    private List<CoveragesLineItem__c> generateCoverageForInsert(Map<String, List<Coverage__c>> templateMap,
                                                                 List<Quote> items) {
                                                                     List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
                                                                     for (Quote item : items) {
                                                                         List<Coverage__c> newTemplates = new List<Coverage__c>();
                                                                         newTemplates = getTemplateByQuote(templateMap, item);
                                                                         System.debug('newTemplates'+newTemplates);
                                                                         // generate rating modifier from template
                                                                         List<CoveragesLineItem__c> coverages = generateCoverageLineItems(newTemplates, item);
                                                                         // skip if no rating is generated
                                                                         if (coverages.isEmpty()) continue;
                                                                         
                                                                         result.addAll(coverages);
                                                                     }
                                                                     
                                                                     return result;                                                            
                                                                 }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: items - List of existing Coverage Line Item
* Params: products - products need to be removed
* Description: Generate list rating modiers for insert
* Revision: 
*************************************************/ 
    private List<CoveragesLineItem__c> generateCoverageForDelete(List<CoveragesLineItem__c> items,
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
* Params: templates - map of Coverage template
* Params: opp - Opportunity  
* Return: List of Coverage__c
* Description: Get all Coverage from input map by Quote
* Revision: 
*************************************************/
    private List<Coverage__c> getTemplateByQuote(Map<String, List<Coverage__c>> templates, Quote q) {
        List<Coverage__c> result = new List<Coverage__c>();
        List<String> productNames = getProductOptions(q); // get product options by quote
        String quoteLayer  = [Select Id, Layer__c from Quote where Id=:q.Id].Layer__c;
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
                        system.debug('vinay oppPrdmap: ' + oppComboProductsMap.values());
                        if(oppComboProductsMap.containsKey(q.OpportunityId)){
                            List<String> oppProducts  = oppComboProductsMap.get(q.OpportunityId);
                            for(Coverage__c cov : coverageTemplates){
                                for(String oppProd : oppComboProductsMap.get(q.OpportunityId)){
                                    if(cov.Coverage_Product_Combo__c != null && cov.Coverage_Product_Combo__c.contains(oppProd)){
                                        comboCoverages.add(cov);
                                        break;
                                    }
                                }                               
                            }
                        }
                    }
                    else{
                        continue;
                    }

                    if(comboCoverages.size() == 0) continue;
                    coverageTemplates = comboCoverages;
                }
              
                //if PI product - add coverages based on quote layer
                for(Coverage__c cov : coverageTemplates){
                    //system.debug('apply to quote:'+cov.Apply_to_Quote__c.contains(quoteLayer));
                    system.debug('item:'+item);
                    if(item == 'Professional Indemnity' && cov.Apply_to_Quote__c.contains(quoteLayer)){
                        System.debug('condition OK!');
                        result.add(cov);
                    }
                }
                if(item != 'Professional Indemnity'){
                    result.addAll(coverageTemplates);  
                }  
            }
        } catch (Exception ex) {
            result.clear(); 
        }
        System.debug('Cov added:'+result);
        return result;                         
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: templates - List of Rating template
* Return: List of Rating_Modifiers__c
* Description: generate rating modifiers based on rating template
* Revision: 
*************************************************/
    private List<CoveragesLineItem__c> generateCoverageLineItems(List<Coverage__c> templates, Quote quoteItem) {
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
    
    private static List<CoveragesLineItem__c> GenerateCLIByCoverage(Coverage__c obj, Quote quoteItem) {
        System.debug('------GenerateCLIByCoverage-----');
        List<CoveragesLineItem__c> result = new List<CoveragesLineItem__c>();
        List<CoveragesLineItem__c> limitItems = new List<CoveragesLineItem__c>();
        CoveragesLineItem__c cov = new CoveragesLineItem__c();
        Date effectiveDate; // add effective date to coverage line item
        if(quoteItem != null)
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
            }
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
            System.debug('obj.FeaturesProductOptions__r'+obj.FeaturesProductOptions__r);
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
            System.debug('covcount'+result.size());
            result.addAll(limitItems);
            System.debug('covcount'+result.size());
            
            System.debug('limitItems'+limitItems);
            System.debug('cov'+cov);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            result.clear();
        }
        return result;  
    }
    
    /*************************************************
* Author: Khanh TRAN
* Date: 27-Sep-2019
* Params:  newQuotes - List of new Quote
* Return: 
* Description: Update Broker Name and Broker Email
* Revision: 
*************************************************/ 
    private static void updateQuoteWithBrokerName(List<Quote> newQuotes){
        
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
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: item - List of Opportunity
* Description: get list products from a list of Rating Modifier
* Revision: 
*************************************************/
    private List<String> getAllProductOptions(List<CoveragesLineItem__c> items) {
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
* Description: return the items from old list which doesn't existed in the new list
* Revision: 
*************************************************/
    private List<String> getRemovedItems(List<String> oldItems, List<String> newItems) {
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
* Params: obj - template map
* Params: products - list of removed products
* Description: remove template from certain products
* Revision: 
*************************************************/
    private Map<String, List<Coverage__c>> getTemplateForInsert(Map<String, List<Coverage__c>> obj, 
                                                                List<String> products) {
                                                                    Map<String, List<Coverage__c>> result = new Map<String, List<Coverage__c>>();
                                                                    result = obj.clone();
                                                                    
                                                                    for (String item : products) {
                                                                        result.remove(item);
                                                                    }
                                                                    return result;                                                                    
                                                                }
    
    /*************************************************
* Method Name: getApprovedQuoteIds
* Author: Hoang Bui
* Date: 22-Oct-19
* Params: Map<Id,Quote> oldDataMap, Map<Id,Quote> oldDataMap
* Return: Set of Quote Id
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
            TriggerHandler.bypass('QuoteTriggerHandler');
            update quotes;
            TriggerHandler.clearBypass('QuoteTriggerHandler');          
        }
    }
    
    private void createPrimaryLocation(List<Quote> items) {
        Set<String> oppIds = new Set<String>();
        
        Savepoint sp = Database.setSavepoint();
        try {
            // get opportunity ids
            for (Quote item : items) {
                oppIds.add(item.OpportunityId);
            }
            
            // get opportunities
            List<Opportunity> opps = getOpportunities(oppIds);
            
            // get all locations
            List<Location__c> locations = getLocationByOpportunity(opps);
            
            // generate locations map by opportunity
            Map<String, Location__c> locMap = generateLocationMap(opps, locations);
            
            upsert locMap.values();
            
            // generate new quote locations
            List<Quote_Location__c> quoteLocations = generateQuoteLocations(items, locMap);
            
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
    
    // update commission value
    private void updateCommission(List<Quote> items) {
        List<Quote> quoteToUpdate = new List<Quote>();
        Map<String, String> quoteOpp = new Map<String, String>();
        for(Quote quote : items){
            quoteOpp.put(quote.Id, quote.OpportunityId);
        }
        Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Product__r.Name, Product_Name__c  FROM Opportunity WHERE Id IN: quoteOpp.values()]);
        List<Broker_Account__c> brokerAccList= [SELECT Broker_Contact__c, Id, IsPrimaryBroker__c, Broker_Contact__r.AccountId ,Opportunity__c
                                                FROM Broker_Account__c
                                                WHERE Opportunity__c IN: quoteOpp.values()
                                                AND IsPrimaryBroker__c = true];
        Map<String, String> oppAccMap = new Map<String, String>();
        for(Broker_Account__c brokerAcc : brokerAccList){
            oppAccMap.put(brokerAcc.Opportunity__c, brokerAcc.Broker_Contact__r.AccountId);
        }
        
        List<Account_Product__c> accProds = [Select Id, Commission_percentage__c, Product_Id__c, Product_Id__r.Name, Account_Id__c
                                             From Account_Product__c 
                                             Where Account_Id__c =: oppAccMap.values()];
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
    
    private List<Opportunity> getOpportunities(Set<String> ids) {
        List<Opportunity> result = new List<Opportunity>();
        
        result = [SELECT Id,AccountId, Account.BillingStreet, Account.BillingCity, 
                  Account.BillingPostalCode,
                  Account.BillingState, Account.BillingStateCode,Account.BillingCountry,
                  Account.Billing_County__c,Account.BillingCountryCode,
                  Account.BillingLongitude, Account.BillingLatitude
                  FROM Opportunity WHERE Id IN :ids];
        
        return result;
    }
    
    private List<Location__c> getLocationByOpportunity(List<Opportunity> items) {
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
            result = [SELECT Id, Name, Address__c, City__c, Country__c,
                      County__c, Postal_Code__c, State_Province__c
                      FROM Location__c 
                      WHERE Address__c IN :streets 
                      AND City__c IN :cities
                      AND State_Province__c IN :states
                      AND Postal_Code__c IN :zipCodes 
                      AND Country__c IN :countries 
                      LIMIT 50000];
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            result.clear();
        }
        
        return result;
    }
    
    public Location__c getAccountLocation(Account acc, List<Location__c> allLocations) {
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
    
    public Map<String, Location__c> generateLocationMap(List<Opportunity> opps, List<Location__c> locations) {
        Map<String, Location__c> result = new Map<String, Location__c>();
        for (Opportunity item : opps) {
            // get account location
            Location__c loc = getAccountLocation(item.Account, locations);
            
            // new location
            if (loc == null) {
                loc = generateLocation(item.Account);
            }
            
            result.put(item.id, loc);
        }
        return result;
    }
    
    private Location__c generateLocation(Account obj) {
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
    
    private List<Quote_Location__c> generateQuoteLocations(List<Quote> items, Map<String, Location__c> obj) {
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
* Description: Create rating modifier factor from template for each quote
* Revision: 
*************************************************/
    private void AddRatingModifierFactor(List<Quote> quotes) {
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        Map<Id, Rating_Modifier_Template__c> templateMapWithModifiers = 
            new Map<Id, Rating_Modifier_Template__c>();
        List<Rating_Modifier_Factor__c> result = new List<Rating_Modifier_Factor__c>();
        List<Id> oppIds = new List<Id>();
        
        try {
            for (Quote q : quotes) {
                oppIds.add(q.OpportunityId);
            }

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
            
            templateMap = generateTemplateMap(templates);
            System.debug('TemplateMap length: ' + templateMap.size());
            
            // map Rating_Modifier_Template__c with Rating_Modifiers__c by Rating_Modifiers__c's Id
            templateMapWithModifiers = generateTemplateMapWithModifiers(templateMap, modifiers);
            System.debug('TemplateMapModifiers length: ' + templateMapWithModifiers.size());
            
            result = generateModifiersFactorForInsert(templateMapWithModifiers, quotes);
            System.debug('Factor length: ' + result.size()); 
            
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
    
    //get Rating Modifiers
    private List<Rating_Modifiers__c> getAllRatingModifiers(List<Id> items) {
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        List<String> displayFormatList = new List<String>{'Clearance', 'Primary Modifiers', 'Secondary Modifiers', 'Factor Values Only','Default Only'};
            result = [SELECT Id, Name, Rating_Modifier_Code__c, Product__c, Display_Format__c, Page_Section__c, Opportunity__r.Product_Name__c
                      FROM Rating_Modifiers__c 
                      WHERE Opportunity__c IN :items
                      AND Display_Format__c IN: displayFormatList AND Page_Section__c!='SME Eligibility'];
        
        
                      
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
    
    //get Rating Modifier Template
    private List<Rating_Modifier_Template__c> getRatingTemplatesByModifier(List<Rating_Modifiers__c> items) {
        List<Rating_Modifier_Template__c> result = new List<Rating_Modifier_Template__c>();
        List<String> codes = new List<String>();
        
        for (Rating_Modifiers__c item : items) {
            if (String.isBlank(item.Rating_Modifier_Code__c )) 
                continue;
            
            codes.add(item.Rating_Modifier_Code__c);
        }
        
        result = [SELECT Id, name, Rating_Modifier_Code__c,
                  Factor_Default_Value__c, Factor_Max__c, Factor_Min__c
                  FROM Rating_Modifier_Template__c 
                  WHERE Rating_Modifier_Code__c IN :codes and Display_Format__c != 'Clearance'];
        return result;
    }
    
    //generate map of Rating Modifier Template
    private Map<String, Rating_Modifier_Template__c> generateTemplateMap(List<Rating_Modifier_Template__c> templates) {
        Map<String, Rating_Modifier_Template__c> result = new Map<String, Rating_Modifier_Template__c>();
        for(Rating_Modifier_Template__c template : templates) {
            result.put(template.Rating_Modifier_Code__c, template);
        }
        return result;
    }
    
    /*************************************************
* Author: Tuan.d.Nguyen
* Date: 17-Mar-2020
* Params: templates - List of Rating template
* Return: Map of Rating_Modifier_Template__c
* Description: generate a map to store all rating template
* Revision: 
*************************************************/
    private Map<Id, Rating_Modifier_Template__c> generateTemplateMapWithModifiers(Map<String, Rating_Modifier_Template__c> templatesMap,
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
* Description: generate rating modifiers factor based on rating template
* Revision: 
*************************************************/
    private List<Rating_Modifier_Factor__c> generateModifiersFactorForInsert(Map<Id, Rating_Modifier_Template__c> templateMapWithModifiers, List<Quote> quotes) {
        List<Rating_Modifier_Factor__c> result = new List<Rating_Modifier_Factor__c>();
        try{
            //generate Factor for each quote
            for(Quote q : quotes) {
                for (Id modifierId : templateMapWithModifiers.keySet()) {
                    Rating_Modifier_Template__c item = templateMapWithModifiers.get(modifierId);
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
* Author: Tuan.d.Nguyen
* Date: 18-Mar-2020
* Params: quotes - List of Quote
* Return: none
* Description: Update rating modifier factor from template for each quote
* Revision: 
*************************************************/
    /* private void UpdateRatingModifierFactor(List<Quote> quotes) {
List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
Map<Id, Rating_Modifier_Template__c> templateMapWithModifiers = new Map<Id, Rating_Modifier_Template__c>();
List<Rating_Modifier_Factor__c> result = new List<Rating_Modifier_Factor__c>();
List<Rating_Modifier_Factor__c> oldFactors = new List<Rating_Modifier_Factor__c>();
List<Id> oppIds = new List<Id>();

try {   
for(Quote q : quotes) {
oppIds.add(q.OpportunityId);
}

List<Rating_Modifiers__c> modifiers = getAllRatingModifiers(oppIds);
//there is no rating modifier
if(modifiers.isEmpty()) return;
System.debug('Modifier length: ' + modifiers.size());

oldFactors = getRatingModifierFactors(modifiers, quotes);
//there is no rating factor
// if(oldFactors.isEmpty()) return;
System.debug('Old Factor length: ' + oldFactors.size());

templates = getRatingTemplatesByModifier(modifiers);
// no templates is found
if (templates.isEmpty()) return;
System.debug('Template length: ' + templates.size());

// map Rating_Modifier_Template__c with its Rating_Modifier_Code__c
Map<String, Rating_Modifier_Template__c> templateMap = new Map<String, Rating_Modifier_Template__c>();
templateMap = generateTemplateMap(templates);
System.debug('TemplateMap length: ' + templateMap.size());

// map Rating_Modifier_Template__c with Rating_Modifiers__c by Rating_Modifiers__c's Id
templateMapWithModifiers = generateTemplateMapWithModifiers(templateMap, modifiers);
System.debug('TemplateMapModifiers length: ' + templateMapWithModifiers.size());

//Map<Id, List<Rating_Modifier_Factor__c>> factorMap = generateFactorMap(oldFactors, quotes);
result = generateModifiersFactorForInsert(templateMapWithModifiers, quotes);
System.debug('New Factor length: ' + result.size());

if(oldFactors.size() > 0)
delete oldFactors;
insert result;
} catch (Exception ex) {
String errorMsg = 'Failed to update Rating Modifier Factor.<br/>Please contact your administators.';
for(Quote item : (List<Quote>)Trigger.new ){
item.addError(errorMsg);
}
}
}*/
    
    //Commented by Pooja on 06-May-2021-- these methods are not used anywhere in class
    //get Rating Modifier Factor
    /* private List<Rating_Modifier_Factor__c> getRatingModifierFactors(List<Rating_Modifiers__c> modifiers, List<Quote> quotes) {
List<Id> modifierIds = new List<Id>();
List<Rating_Modifier_Factor__c> result = new List<Rating_Modifier_Factor__c>();
List<Id> quoteIds = new List<Id>();
for(Rating_Modifiers__c item : modifiers) {
modifierIds.add(item.Id);
}
for(Quote item : quotes) {
quoteIds.add(item.id);
}
try {
result = [SELECT Id, name, Factor_Default_Value__c, Factor_Max__c,
Factor_Min__c, Factor_Value__c, Quote__c, Rating_Modifier__c
FROM Rating_Modifier_Factor__c WHERE Rating_Modifier__c IN :modifierIds AND Quote__c IN :quoteIds];

} catch(Exception ex) {
System.debug('Exception: ' + ex.getMessage() + ex.getLineNumber());
}
return result;

}*/
    
    //Commented by Pooja on 06-May-2021-- these methods are not used anywhere in class
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: opps - List of Opportunity
* Return: none
* Description: Create rating modifier from template for each opportunity
* Revision: 
*************************************************/
    /* private void AddRatingModifier(List<Quote> items) {
List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
Map<String, List<Rating_Modifier_Template__c>> templateMap = new Map<String, List<Rating_Modifier_Template__c>>();
List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
List<Opportunity> opps = new List<Opportunity>();

try {
List<String> products = getAllProductOptions(opps);
//there is no products
if(products.isEmpty()) return;
templates = CommonUtil.getRatingTemplatesByProducts(products);
// no templates is found
if (templates.isEmpty()) return;

// store all template in map to reduce soql query
//templateMap = generateRatingTemplateMap(templates);
//result = generateModifiersForInsert(templateMap, opps);

insert result;
} catch (Exception ex) {
String errorMsg = 'Failed to create Rating Modifier.<br/>Please contact your administators.';
for(Opportunity opp : (List<Opportunity>)Trigger.new ){
opp.addError(errorMsg);
}
}
}*/
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: item - Opportunity
* Description: get list products of an opportunity
* Revision: 
*************************************************/
    //Commented by Pooja on 06-May-2021-- these methods are not used anywhere in class
    /* private List<String> getProductOptions(Opportunity item) {
List<String> result = new List<String>();
try {
if (item == null || item.Product__r == null) return result;

String productName = item.Product__r.Name;

if(productName.contains('Standalone')) result.add(productName.split(' ')[0]);
else result = item.Coverage_Product_Options__c.split(';');
} catch (Exception ex) {
result.clear();
}
return result;
}*/
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: item - List of Opportunity
* Description: get list products from a list of opportunity
* Revision: 
*************************************************/
    /* private List<String> getAllProductOptions(List<Opportunity> items) {
Set<String> productOptions = new Set<String>();
try {
for (Opportunity item : items){
List<String> products = getProductOptions(item);
if(!products.isEmpty()){
productOptions.addAll(products);
}      
}
} catch (Exception ex){
productOptions.clear();
}
return new List<String>(productOptions);    
}*/
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: item - List of Opportunity
* Description: get list products from a list of Rating Modifier
* Revision: 
*************************************************/
    private List<String> getAllProductOptions(List<Rating_Modifiers__c> items) {
        Set<String> productOptions = new Set<String>();
        try {
            for (Rating_Modifiers__c item : items){
                if (String.isBlank(item.Product__c))
                    continue;
                
                productOptions.add(item.Product__c);    
            }
        } catch (Exception ex){
            productOptions.clear();
        }
        return new List<String>(productOptions);    
    }
    
    //Commented by Pooja on 06-May-2021-- these methods are not used anywhere in class
    /*  private List<Opportunity> getOpportunitiesByQuote(List<Quote> items) {
List<Opportunity> result = new List<Opportunity>();
List<String> oppIds = new List<String>();
for(Quote q : items) {
oppIds.add(q.OpportunityId);
}

result = [SELECT Id, Coverage_Product_Options__c, Product__r.Name 
FROM Opportunity
WHERE Id IN :oppIds];

return result;
}*/
    
    /*************************************************
* Author: Giang Phan
* Date: 19/June/2020
* Params: item - List of Quote
* Description: when ever Quote getting updated, need to update quote's status to 'In Progress'
* Revision: 
*************************************************/
    public static void updateQuoteStatusToInProgress(List<Quote> quotelistNew, Map<Id, Quote> quoteMapOld) {
        for(Quote quo : quotelistNew){
            if(quoteMapOld.get(quo.Id).Status == quo.Status && quoteMapOld.get(quo.Id).Status != 'In Progress'
               && quoteMapOld.get(quo.Id).Status != 'Bound' && quoteMapOld.get(quo.Id).Status != 'Rated'){
                   //quoteMapOld.get(quo.Id).Status == 'Rated' || quoteMapOld.get(quo.Id).Status == 'Quoted'){
                   quo.Status = 'In Progress';
               }
        }
    }
    
    /*************************************************
* Author: Long Ly
* Date: 16/Oct/2020
* Params: item - List of Quote
* Description: Sum of count number of open subjsectivities on Bound Quote
* Revision: 
*************************************************/
    private void countOpenSubjectivityOnBoundQuote(List<Quote> newList) {
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
            
            
            TriggerHandler.bypass('PolicyTriggerHandler');
            update lstPolicy;
            TriggerHandler.clearBypass('PolicyTriggerHandler');
            
        }
        
    }
    
    /*************************************************
* Method Name: updateCliEffectiveDate
* Author: tuan.d.nguyen
* Date: 11-Dec-2020
* Params: Map<String, Quote> oldQuoteMap, List<Quote> newQuoteList
* Return: 
* Description: use to update Coverage_Effective_Date__c of CoveragesLineItem__c when quote is update
*************************************************/
    public static void updateCliEffectiveDate(List<Quote> newQuoteList, Map<Id, Quote> oldQuoteMap) { 
        try {
            Map<Id, Quote> updateEffectiveDateQuoteMap = new Map<Id, Quote>();
            //get the changed effective date quote and put it in the map
            for(Quote q : newQuoteList) {
                if(oldQuoteMap.get(q.Id) != null) {
                    if((q.Quote_Type__c == Label.Quote_Type_New_Business && oldQuoteMap.get(q.Id).Effective_Date__c != q.Effective_Date__c)
                       || (q.Quote_Type__c == Label.Quote_Type_Amendment && oldQuoteMap.get(q.Id).Endorsement_Effective_Date__c != q.Endorsement_Effective_Date__c))
                        updateEffectiveDateQuoteMap.put(q.Id, q); //get all the quote that change effective date
                }
            }
            
            Map<Id, List<CoveragesLineItem__c>> mapCLI = new Map<Id, List<CoveragesLineItem__c>>();

            List<CoveragesLineItem__c> listUpdateCLI = new List<CoveragesLineItem__c>();
            if(!updateEffectiveDateQuoteMap.keySet().isEmpty()){
            for(CoveragesLineItem__c cli: [SELECT Quote__c FROM CoveragesLineItem__c 
                                           WHERE Quote__c IN: updateEffectiveDateQuoteMap.keySet()
                                           AND Coverage__r.Coverage_Type__c = 'Endorsement'
                                           AND Parent_Coverages_Line_Item__c = null]){
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
    private static void lockEditOnQuote(List<Quote> newQuoteList, Map<Id, Quote> oldQuoteMap){
        try{
            Id profileId = userinfo.getProfileId();
            String profileName = [Select Id, Name from Profile where Id =: profileId].Name;   
            system.debug('ProfileName' + profileName);
            if(profileName == 'System Administrator'){
                return;            
            }
            else{
                for(Quote q: newQuoteList){ 
                    
                    if(((oldQuoteMap.get(q.Id).Status == 'Bound') ||
                        (oldQuoteMap.get(q.Id).Status == 'Presented' && q.Status != 'Bound' && q.Status != 'Closed')||
                        (oldQuoteMap.get(q.Id).Status == 'Bound Pending' && q.Status != 'Bound' && q.Status != 'Closed')  ||
                        (oldQuoteMap.get(q.Id).Status == 'Quoted' && q.Status != 'Bound' && q.Status != 'Bound Pending' && q.Status != 'Closed' &&
                         (oldQuoteMap.get(q.Id).Status == 'Presented' || oldQuoteMap.get(q.Id).Status == 'Bound Pending'))) &&
                       SubjectivityTriggerHandler.checkProfile && oldQuoteMap.get(q.Id).Status != 'Bound Pending' )
                    {
                        q.addError('This Quote is locked for editing when status is \'Quoted\' or \'Presented\' or \'Bound\'');
                    }
                }
            }
        }
        catch(Exception ex){
            
        }
    }
    private static void sendEmailToApprovalSubmitter(List<Quote> quotelistNew, Map<Id, Quote> oldQuoteMap){
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
    
    private void createSubjectivityIfProposalFormDateEmpty(List<Quote> quotes) {
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        List<Subjectivity__c> subjectivityListToCreate = new List<Subjectivity__c>(); 
        List<Id> quoteIdsList = new List<Id>();
        Map<Id,Id> oppIdsMap = new Map<Id,Id>();
        
        try {
            for (Quote q : quotes) {
                oppIdsMap.put(q.OpportunityId,q.Id);
            }
            
            for(Rating_Modifiers__c rateMod: [SELECT Rating_Modifier_Code__c, Opportunity__c,Rating_Modifier_Value__c, Name, Id 
                                              FROM Rating_Modifiers__c 
                                              WHERE Name='Proposal Form Date' AND Opportunity__c IN: oppIdsMap.keySet()]){
                                                  if(rateMod.Rating_Modifier_Value__c == null || rateMod.Rating_Modifier_Value__c == ''){
                                                      quoteIdsList.add(oppIdsMap.get(rateMod.Opportunity__c));
                                                  }
                                              }
            
            List<Subjectivity_Template__c> subjTemp = [SELECT Id, Name, Profession_Criteria__c, Subjectivity_Name__c, Subjectivity_Text__c 
                                                       FROM Subjectivity_Template__c 
                                                       WHERE Subjectivity_Name__c ='Signed / Dated Proposal'];
            if(subjTemp != null && subjTemp.size() > 0){
                for(Id qId: quoteIdsList){
                    Subjectivity__c subRec = new Subjectivity__c(); 
                    subRec.Quote__c = qId;
                    subRec.Subjectivity__c = subjTemp[0].Subjectivity_Name__c;
                    subRec.Subjectivity_Text__c = subjTemp[0].Subjectivity_Text__c;
                    subRec.Stage__c = 'Pre-Bind';
                    subRec.Cleared__c = false;
                    subRec.Cleared_Date__c = null;
                    subRec.Subjectivity_Template__c = subjTemp[0].Id;
                    subjectivityListToCreate.add(subRec);
                } 
            }
            
            if(!subjectivityListToCreate.isEmpty()) insert subjectivityListToCreate;
            
        } catch (Exception ex) {
            system.debug('## ex'+ ex.getLineNumber());
            system.debug('## ex'+ ex.getStackTraceString());
            system.debug('## ex'+ ex.getMessage());
            String errorMsg = 'Failed to create Subjectivity.<br/>Please contact your administators.';
            for(Quote item : (List<Quote>)Trigger.new ){
                item.addError(errorMsg);
            }
        }   
    }
    private void createSubjectivityByDefaultCelerity(List<Quote> quotes) {
        List<Subjectivity__c> subjectivityListByDefault = new List<Subjectivity__c>(); 
        
        List<Subjectivity_Template__c> subjTemplate = [SELECT Id, Name, Subjectivity_Name__c,Product__c,Subjectivity_Text__c,Stage__c 
                                                       FROM Subjectivity_Template__c 
                                                       WHERE Subjectivity_Name__c ='Completed Surplus Lines Tax Form' limit 1];
        if(!subjTemplate.isEmpty()){
            for(Quote quote: quotes){
                Subjectivity__c subRecord = new Subjectivity__c(); 
                subRecord.Quote__c = quote.Id;
                subRecord.Subjectivity__c = subjTemplate[0].Subjectivity_Name__c;
                subRecord.Subjectivity_Text__c = subjTemplate[0].Subjectivity_Text__c;
                subRecord.Stage__c =subjTemplate[0].Stage__c ;
                subRecord.Cleared__c = false;
                subRecord.Cleared_Date__c = null;
                subRecord.Subjectivity_Template__c = subjTemplate[0].Id;
                subjectivityListByDefault.add(subRecord);
            } 
        }
        
        if(!subjectivityListByDefault.isEmpty()) insert subjectivityListByDefault;
        
    }
    
    private static void checkQuoteDocLinksAssign(List<Quote> newList,Map<Id, Quote> oldQuoteMap){
        for(Quote quote : newList) {     
            if((oldQuoteMap.get(quote.Id).Policy_Wording__c != quote.Policy_Wording__c || (quote.Status != oldQuoteMap.get(quote.Id).Status && quote.Status == 'Rated' && quote.Policy_Wording_Document__c == null)) && quote.Product_Name__c == 'Professional Indemnity'){
                if(String.isNotBlank(quote.Master_Binder__c)){
                    Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(quote);
                    quote.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;
                    quote.Policy_Wording_ContentDoc_Id__c = quoteDoc.Policy_Wording_ContentDoc_Id__c;
                    if(quote.Layer__c != 'Excess')	{
                        quote.IPID_Document__c = quoteDoc.IPID_Document__c; 
                        quote.IPID_ContentDoc_Id__c = quoteDoc.IPID_ContentDoc_Id__c;
                    }
                }
            }
        }   
    }        
    private static void checkBinderAssignForQuote(List<Quote> newList,Map<Id, Quote> oldQuoteMap){        
        System.debug('Inside Method for Before Update');
        List<Master_Binder__c> binderList = [Select Id,Name,Inception_Date__c,Expiry_Date__c,MGA_Commission__c,Layer__c,
                                             Coverholder_Name__c,Coverholder_Pin__c from Master_Binder__c];
        List<Id> binderIdList = new List<Id>();
        List<Decimal> mgaCommissionValueList = new List<Decimal>();
        for(Quote quote : newList) {     
            if(oldQuoteMap.get(quote.Id).Effective_Date__c != quote.Effective_Date__c && quote.Product_Name__c == 'Professional Indemnity'){
                Integer binderCount = 0;     
                binderIdList = new List<Id>();
                for(Master_Binder__c binder : binderList){
                    if(binder.Inception_Date__c <= quote.Effective_Date__c && binder.Layer__c.contains(quote.Layer__c)
                       && binder.Expiry_Date__c >= quote.Effective_Date__c){
                           binderCount++;	    
                           binderIdList.add(binder.Id);
                           mgaCommissionValueList.add(binder.MGA_Commission__c);
                       }
                }
                if(binderCount == 1 && binderIdList.size() == 1){
                    quote.Master_Binder__c = binderIdList[0];
                    quote.Policy_Wording_Document__c = null;
                    quote.IPID_Document__c = null;
                    Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(quote);
                    quote.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                    if(quote.Layer__c != 'Excess')	quote.IPID_Document__c = quoteDoc.IPID_Document__c;  	                    
                }	                
                if(binderCount == 1 && mgaCommissionValueList.size() == 1)	quote.MGA_Commission__c = mgaCommissionValueList[0];
                if(binderCount > 1){
                    if(quote.Status == 'In Progress'){
                        quote.Is_Inception_Date_Edited__c = true;
                    }
                    quote.Master_Binder__c = null;
                    quote.Policy_Wording_Document__c = null;
                    quote.IPID_Document__c = null;
                    //quote.MGA_Commission__c = null;   //Commented as per #51580
                }	
                //if(binderCount > 1)	quote.MGA_Commission__c = null;
            }
            if(quote.Product_Name__c == 'Professional Indemnity' && oldQuoteMap.get(quote.Id).Status != quote.Status
                && oldQuoteMap.get(quote.Id).Status == 'In Progress' && quote.Status == 'Rated'){
                    quote.Is_Inception_Date_Edited__c = false;
            }
            if(quote.Product_Name__c == 'Professional Indemnity' && oldQuoteMap.get(quote.Id).Status != quote.Status && quote.Status == 'Quoted'){
                if(quote.Retroactive_Date__c == 'Retro - Inception date'){
                    quote.RetroDate__c = quote.Effective_Date__c;
                }
                else if(quote.Retroactive_Date__c == 'None'){
                    quote.RetroDate__c = null;
                }
            }
        }
    }
    private static void handleExcessInsurerUnderlying(List<Quote> newList,Map<Id, Quote> olddataMap){
        List<Insurer_Layer_Limit__c> createInsurerLimit = new List<Insurer_Layer_Limit__c>();
        set<string> insurerDelete = new set<string>();
        
        for(Quote quote : newList) {
            if(olddataMap.get(quote.Id).Layer__c != quote.Layer__c && quote.Layer__c == 'Excess'){
                if (quote.Insurer_Layer_Limit__r.size() == 0) {
                    Insurer_Layer_Limit__c insurerLayer = new Insurer_Layer_Limit__c();
                    insurerLayer.Layer__c = 'Primary Insurer';
                    insurerLayer.Insurer_Layer_Limit__c = 5000000;
                    insurerLayer.Quote__c = quote.Id;
                    createInsurerLimit.add(insurerLayer);
                }
                
            }
            if(olddataMap.get(quote.Id).Layer__c != quote.Layer__c && quote.Layer__c == 'Primary'){
                insurerDelete.add(quote.Id);
            } 
        }
        
        if(!createInsurerLimit.isEmpty()){
            insert createInsurerLimit;
        }
        
        if(!insurerDelete.isEmpty()){
            List<Insurer_Layer_Limit__c> removeInsurerList = [select Id,Insurer__c,Quote__c from Insurer_Layer_Limit__c where Quote__c IN: insurerDelete];  
            if(!removeInsurerList.isEmpty()){
                delete removeInsurerList;
            }
        }
    }
    
    private static void createInsurerExcess(List<Quote> newList){
        List<Insurer_Layer_Limit__c> createInsurerLimit = new List<Insurer_Layer_Limit__c>();
        
        for(Quote quote : newList) {
            if(quote.Layer__c == 'Excess'){
                if (quote.Insurer_Layer_Limit__r.size() == 0) {
                    Insurer_Layer_Limit__c insurerLayer = new Insurer_Layer_Limit__c();
                    insurerLayer.Layer__c = 'Primary Insurer';
                    insurerLayer.Insurer_Layer_Limit__c = 5000000;
                    insurerLayer.Quote__c = quote.Id;
                    createInsurerLimit.add(insurerLayer);
                }
                
            }
        }
        
        if(!createInsurerLimit.isEmpty()){
            insert createInsurerLimit;
        }
    }
    
    
    private static void updateSubmissionStatusToBound(List<Quote> newQuotes){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Quote quote: newQuotes){
            if(quote.Status == 'Bound'){
                oppIds.add(quote.OpportunityId);
            }
        }
        if(!oppIds.isEmpty())
            for(Opportunity opp : [Select Id, Submission_Status__c from Opportunity where ID IN:oppIds]){
                opp.Submission_Status__c = 'Bound';
                oppsToUpdate.add(opp);
            }
        if(oppsToUpdate.size() > 0){
            update oppsToUpdate;
        }
    }
    private static void updateSubmissionStatus(List<Quote> newQuotes, Map<Id,Quote> quoteOldMap){
        Set<Id> oppIds = new Set<Id>();
        Boolean isOpenQuotes = false;
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for(Quote quote:newQuotes){
            oppIds.add(quote.OpportunityId);
        }
        
        List<Quote> quoteList = [Select Id,Status from Quote where OpportunityId IN: oppIds];
        if(!quoteList.isEmpty()){
            for(Quote quote:  quoteList){
                if(quote.Status != 'Bound' && quote.Status != 'Closed'){
                    isOpenQuotes = true;
                    break;
                }
            } 
        }
        
        for(Opportunity opp : [Select Id, Submission_Status__c,StageName,Loss_Reason__c,
                               (SELECT Id,Status,Closed_Reason__c FROM Quotes ORDER BY LastModifiedDate DESC) from Opportunity where ID IN:oppIds])//---CD-103 - Gaurish Goel 14th Sep 2021 -- Added inner query on Quote
        {
            String strSubStatus = opp.Submission_Status__c;
            if(!isOpenQuotes && opp.StageName == 'Qualified'){
                opp.StageName = 'Closed Won';
                opp.Submission_Status__c = 'Bound';
            }
            if(opp.Quotes != null && opp.Quotes.size() > 0){//---CD-103 - Gaurish Goel 14th Sep 2021 -- If all quotes are closed then Opp's Stage is set to "Closed Lost"
                Boolean allClosed = true;
                String closedReason = '';
                for(Quote q: opp.Quotes){
                    if(q.Status != 'Closed'){
                        allClosed = false;
                        break;
                    }
                }
                if(allClosed){
                    for(Quote q: opp.Quotes){
                        if(q.Status == 'Closed' && quoteOldMap.containsKey(q.Id) && quoteOldMap.get(q.Id).Status != q.Status){
                            closedReason = q.Closed_Reason__c;
                            break;
                        }
                    }
                    opp.StageName = 'Closed Lost';
                    opp.Loss_Reason__c = closedReason;
                    opp.Submission_Status__c = strSubStatus;
                }
            }
            oppsToUpdate.add(opp);
        }
        
        if(oppsToUpdate.size() > 0){
            GlobalStaticVar.byPassOpportunityTrigger = true;
            update oppsToUpdate;
        }
    } 
    
    private static void updateBoundSubmissionStatus(List<Quote> newQuotes){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Quote quote:newQuotes){
            oppIds.add(quote.OpportunityId);
        }
        if(!oppIds.isEmpty())
            for(Opportunity opp : [Select Id, Submission_Status__c from Opportunity where ID IN:oppIds]){
                if(opp.Submission_Status__c == 'Bound'){
                    opp.Submission_Status__c = 'Bound - In Waiting';
                }      
                oppsToUpdate.add(opp);
            }
        if(oppsToUpdate.size() > 0){
            update oppsToUpdate;
        }
    }  
    
    private static void approveRejectReferralReasons(List<Quote> newList){       
        System.debug('(((((((-->start');
        List<Quote> aprrovalFieldsQuoteList = new List<Quote>();
        Map<Id, List<Referral_Reason__c>> quoteIdToReferralReasonMap = new Map<Id, List<Referral_Reason__c>>();
        List<Referral_Reason__c> referralReasonsToUpdateList = new List<Referral_Reason__c>();
        Set<Id> quoteIds = new Set<Id>();
        
        for(Quote quote:newList){
            if(String.isNotBlank(quote.Is_Quote_Approved_AQ__c)){
                quoteIds.add(quote.Id);
            }            
        }
        
        if(quoteIds.size() > 0){
            User currentUserObj = [Select Id,Name,Level__c from User where Id =: UserInfo.getUserId()];
            List<Referral_Reason__c> referralReasonList = [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,Quote__c,
                                                           Approval_Rejected_Date__c, Approver_Level__c,Approved_By__c, Entity_Path__c,
                                                           Reason__c,Reason_Type__c, Status__c,Approved_By__r.Name,
                                                           Quote_Option__c,Option_Type__c,Option_Limit__c,Option_Id__c,Quote_Option__r.Selected__c  
                                                           FROM Referral_Reason__c 
                                                           WHERE Approval_Status__c != 'Approved' 
                                                           //AND Quote_Option__c = null
                                                           //AND Quote_Option__r.Selected__c = true
                                                           AND Approval_Status__c != 'Rejected' 
                                                           AND Quote__c IN:quoteIds];
            
            for(Referral_Reason__c referralReasonQuo : referralReasonList){  
                if(referralReasonQuo.Quote_Option__r.Selected__c || String.isBlank(referralReasonQuo.Quote_Option__c)){
                    if(quoteIdToReferralReasonMap.containsKey(referralReasonQuo.Quote__c)){
                        quoteIdToReferralReasonMap.get(referralReasonQuo.Quote__c).add(referralReasonQuo);
                    }else{
                        quoteIdToReferralReasonMap.put(referralReasonQuo.Quote__c, new List<Referral_Reason__c>{referralReasonQuo});
                    }    
                }                
            }
            system.debug('((((((quoteIdToReferralReasonMap -- '+quoteIdToReferralReasonMap);
            for(Quote quote : newList) {
                system.debug('((((((quoteIdToReferralReasonMap -- '+quoteIdToReferralReasonMap.get(quote.Id));
                if(quote.Is_Quote_Approved_AQ__c == 'Approved'){ 
                    system.debug('((((((quoteIdToReferralReasonMap --Approved ');
                    List<Referral_Reason__c> referralReasonsToUpdate = updateReferralReasons(quoteIdToReferralReasonMap.get(quote.Id),quote.Is_Quote_Approved_AQ__c,currentUserObj);
                    referralReasonsToUpdateList.addAll(referralReasonsToUpdate);                    
                    quote.Is_Quote_Approved_AQ__c = null;
                }else if(quote.Is_Quote_Approved_AQ__c == 'Rejected'){
                    system.debug('((((((quoteIdToReferralReasonMap --Rejected ');
                    List<Referral_Reason__c> referralReasonsToUpdate = updateReferralReasons(quoteIdToReferralReasonMap.get(quote.Id),quote.Is_Quote_Approved_AQ__c,currentUserObj);
                    referralReasonsToUpdateList.addAll(referralReasonsToUpdate);
                    quote.Is_Quote_Approved_AQ__c = null;
                }     
                aprrovalFieldsQuoteList.add(quote);
            } 
            if(!referralReasonsToUpdateList.isEmpty()){
                system.debug('((((((referralReasonsToUpdateList-- '+referralReasonsToUpdateList);
                GlobalStaticVar.byPassQuoteTrigger = true;
                update referralReasonsToUpdateList;
            }
            //if(!aprrovalFieldsQuoteList.isEmpty())	update aprrovalFieldsQuoteList;
        }              
    }
    
    private static List<Referral_Reason__c> updateReferralReasons(List<Referral_Reason__c> refReasonList, String quoteApprovedRejected,User currentUser){
        System.debug('refReasonList-->'+refReasonList);
        for(Referral_Reason__c refReason: refReasonList){
            refReason.Approval_Rejected_Date__c = System.Date.today();
            refReason.Approved_By__c = currentUser.Id;
            refReason.Approval_Status__c = quoteApprovedRejected;
            refReason.Approver_Level__c = currentUser.Level__c;
        }
        return refReasonList;
    }
    
    private static void updateQuoteStatusToQuoted(List<Quote> newQuote, Map<ID,Quote> oldQuoteMap){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> updateOpp = new List<Opportunity>();
        for(Quote quote: newQuote){
            if(quote.Status == 'Quoted' && oldQuoteMap.get(quote.Id).Status != 'Quoted' && quote.Product_Name__c == 'Professional Indemnity'){
                oppIds.add(quote.OpportunityId);
            }
        }
        if(!oppIds.isEmpty())
            for(Opportunity opp: [Select Id, Submission_Status__c from Opportunity where ID IN:oppIds]){
                if(opp.Submission_Status__c != 'Quoted'){
                    opp.Submission_Status__c = 'Quoted';
                }
                updateOpp.add(opp);
            }
        if(updateOpp.size() > 0){
            update updateOpp;
        }
    }
    
    private static void updateQuoteStatusToReferred(List<Quote> newQuote, Map<ID,Quote> oldQuoteMap){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> updateOpp = new List<Opportunity>();
        for(Quote quote: newQuote){
            if(quote.Status == 'Referred' && oldQuoteMap.get(quote.Id).Status != 'Referred' && quote.Product_Name__c == 'Professional Indemnity'){
                oppIds.add(quote.OpportunityId);
            }
        }
        if(!oppIds.isEmpty())
            for(Opportunity opp: [Select Id, Submission_Status__c from Opportunity where ID IN:oppIds]){
                if(opp.Submission_Status__c != 'Referred'){
                    opp.Submission_Status__c = 'Referred';
                }
                updateOpp.add(opp);
            }
        if(updateOpp.size() > 0){
            update updateOpp;
        }
    }
    
    private static void updateQuoteBoundDate(List<Quote> newQuoteList, Map<ID,Quote> oldQuoteMap){
        for(Quote quote: newQuoteList){
            if(quote.Status == 'Bound' && oldQuoteMap.get(quote.Id).Status != 'Bound' && quote.Product_Name__c == 'Professional Indemnity'){
                quote.Endorsement_Quote_Bound_Date__c = Datetime.now();
            }
        }
    }
    
    
    public static void addQuoteOptions(List<Quote> newQuoteList){
        
        List<Quote_Option__c> listQuoteOptions = new List<Quote_Option__c>();
        for(Quote newQuote : newQuoteList){
            Integer count;
            if(newQuote.Product_Name__c == 'Professional Indemnity'){
                if(newQuote.Layer__c == 'Primary'){
                    count = 10;
                    listQuoteOptions.addAll(createQuoteOptions(count,newQuote.Id,'Fixed Limit'));
                    listQuoteOptions.addAll(createQuoteOptions(1,newQuote.Id,'Free Form'));
                    
                }else{
                    count = 6;
                    listQuoteOptions.addAll(createQuoteOptions(count,newQuote.Id,'Fixed Limit'));
                    listQuoteOptions.addAll(createQuoteOptions(1,newQuote.Id,'Free Form'));
                }
            }
        }
        
        if(!listQuoteOptions.isEmpty()){
            insert listQuoteOptions;
        }
        
    }
    
    public static List<Quote_Option__c> createQuoteOptions(Integer count, Id quoteId, String type){
        List<Quote_Option__c> lstQuoteOptions = new List<Quote_Option__c>();
        for(Integer i = 0 ; i < count ; i++){
            Quote_Option__c objQuoteOption = new Quote_Option__c(Quote__c = quoteId, Option_Type__c = type);
            lstQuoteOptions.add(objQuoteOption);
        }
        
        return lstQuoteOptions;
    }
    
    public static void calculatePremiumFields(){
        
        List<Quote> listNewQuote = (List<Quote>)Trigger.new;
        Map<Id,Quote> mapOldQuote = (Map<Id,Quote>)Trigger.oldMap;
        Set<String> setQuoteId = new Set<String>();
        Set<String> setOppId = new Set<String>();
        Map<String,Decimal> mapAnnualGrossFee = new Map<String,Decimal>();
        List<Quote_Option__c> listQuoteOptiontoUpdate = new List<Quote_Option__c>();
        Map<String,Integer> termLengthforQuote = new Map<String,Integer>();
        Map<String,List<Quote_Option__c>> mapQuoteOption = new Map<String,List<Quote_Option__c>>();
        for(Quote objQuote : [Select Id, OpportunityId, layer__c,Status, ExpirationDate, Effective_Date__c, Quote_Type__c, (Select Id from Quote_Options__r) from Quote where Id in : listNewQuote]){
            if(objQuote.Status == 'Rated' && mapOldQuote.get(objQuote.Id).Status == 'In Progress'){
                setQuoteId.add(objQuote.Id);
                setOppId.add(objQuote.OpportunityId);
                Integer termLength;
                if(objQuote.Effective_Date__c != null && objQuote.ExpirationDate != null){
                    termLength = objQuote.Effective_Date__c.daysBetween(objQuote.ExpirationDate) + 1;
                    termLengthforQuote.put(objQuote.Id,termLength);
                }
            }
            
        }
        for(Rating_Modifiers__c objRM : [Select Id,Rating_Modifier_Code__c,Rating_Modifier_Value__c,Opportunity__c from Rating_Modifiers__c where Opportunity__c = :setOppId AND Rating_Modifier_Code__c = 'PI0000015']){
            if(objRM.Rating_Modifier_Value__c != null){
                mapAnnualGrossFee.put(objRM.Opportunity__c, Decimal.valueOf(objRM.Rating_Modifier_Value__c));
            }
        }
        if(!setQuoteId.isEmpty())
        for(Quote_Option__c objQuoteOption : [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                              , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c,Quote__r.layer__c
                                              , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                              , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                              , Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c
                                              , Bound__c, Selected__c, Option_Type__c, Final_Technical_Premium__c
                                              , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c
                                              , Technical_Fee__c, IPT__c, Total_Cost_To_Client__c ,Tax_Percent__c
                                              , Actual_Premium__c, Broker_Netted_Down_Premium__c, Fee__c
                                              , Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c
                                              , Change_in_IPT__c, Change_in_Total_Cost_to_Client__c
                                              , Netted_Down_Commission_Percent__c, Netted_Down_Commission_Amount__c, Netted_Down_MGA_Commission_Percent__c, Netted_Down_MGA_Commission_Amount__c
                                              , IPT_on_Broker_Netted_Down_Premium__c, Quote__c, Quote__r.Parent_Quote__c, Quote__r.Parent_Quote__r.Actual_Premium__c
                                              , Quote__r.Parent_Quote__r.Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Fee__c,Quote__r.Parent_Quote__r.Rate__c
                                              , Quote__r.Parent_Quote__r.IPT_on_Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Total_Cost_To_Client__c
                                              , Quote__r.Parent_Quote__r.MGA_Commission__c, Quote__r.Quote_Type__c, Quote__r.Commission_percentage__c, Quote__r.MGA_Commission__c 
                                              , NonProrated_Actual_Premium__c, NonProRated_BNDP__c, Increased_Limit_Factor__c, Rate__c, Rate_Change__c
                                              , (Select Id,Code__c,Value__c,Quote__c from Factor_Summary_Items__r where Code__c = 'Tax Percent')  from Quote_Option__c  
                                              where Quote__c in :setQuoteId Order By Option_Type__c Asc, Limit__c Asc]){
                                                  
                                                  List<Quote_Option__c> listQuoteOption = new List<Quote_Option__c>();
                                                  if(mapQuoteOption.containsKey(objQuoteOption.Quote__c)){
                                                      listQuoteOption = (mapQuoteOption.get(objQuoteOption.Quote__c));
                                                      listQuoteOption.add(objQuoteOption);
                                                      mapQuoteOption.put(objQuoteOption.Quote__c,listQuoteOption);
                                                  }
                                                  else{
                                                      listQuoteOption.add(objQuoteOption);
                                                      mapQuoteOption.put(objQuoteOption.Quote__c,listQuoteOption);
                                                  }
                                                  
                                              }
        
        Map<String,Integer> mapSelectedQO = new Map<String,Integer>();
        
        for(String quoteId : mapQuoteOption.keySet()){
            
            for(Quote_Option__c objQO : mapQuoteOption.get(quoteId)){
                
                if(objQO.Selected__c){
                    
                    if(mapSelectedQO.containsKey(objQO.Quote__c)){
                        Integer selectedCount = mapSelectedQO.get(objQO.Quote__c);
                        selectedCount += 1;
                        mapSelectedQO.put(objQO.Quote__c, selectedCount);
                    }
                    else{
                        mapSelectedQO.put(objQO.Quote__c, 1);
                    }
                    
                }
                else{
                    
                    if(!mapSelectedQO.containsKey(objQO.Quote__c)){
                        mapSelectedQO.put(objQO.Quote__c, 0);
                    }
                    
                }
                
            }
        }
        
        if(!mapSelectedQO.isEmpty()){
            
            for(String quoteId : mapSelectedQO.keySet()){
                
                if(mapSelectedQO.get(quoteId) == 0){
                    for(Quote_Option__c objQO : mapQuoteOption.get(quoteId)){
                        
                        if(objQO.Quote__r.layer__c == 'Primary'){
                            if(objQO.Limit__c == 1000000){
                                objQO.Selected__c = true;
                            }
                        }
                        else{
                            if(objQO.Limit__c == 5000000){
                                objQO.Selected__c = true;
                            }
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        if(!mapQuoteOption.isEmpty()){
            
            for(Quote objQuote : listNewQuote){
                
                if(mapQuoteOption.containsKey(objQuote.Id)){
                    List<Quote_Option__c> listQuoteOption = new List<Quote_Option__c>();
                    listQuoteOption = QuoteOptionsTableController.calculatePremiumFields(mapQuoteOption.get(objQuote.Id),termLengthforQuote.get(objQuote.Id),mapAnnualGrossFee.get(objQuote.OpportunityId));
                    listQuoteOptiontoUpdate.addAll(listQuoteOption);
                }
                
            }
            
        }
        
        if(!listQuoteOptiontoUpdate.isEmpty()){
            update listQuoteOptiontoUpdate;
        }
        
    }
    
    public static void checkForceRating(){
        
        List<Quote> listNewQuote = (List<Quote>)Trigger.new;
        Map<Id,Quote> mapOldQuote = (Map<Id,Quote>)Trigger.oldMap;
        
        for(Quote objQuote : (List<Quote>)Trigger.new){
            
            if(objQuote.Status == 'In Progress' && mapOldQuote.get(objQuote.Id).Status == 'Quoted'){
                objQuote.Force_Rating__c = true;
            }
            else if(objQuote.Status == 'Rated' && mapOldQuote.get(objQuote.Id).Status == 'In Progress' && objQuote.Force_Rating__c == true){
                objQuote.Force_Rating__c = false;
            }
            
        }
        
    }
    
    public static void populatePremiumFields(){
        
        List<Quote> listNewQuote = (List<Quote>)Trigger.new;
        Map<Id,Quote> mapOldQuote = (Map<Id,Quote>)Trigger.oldMap;
        Set<String> setQuoteId = new Set<String>();
        Map<String,Quote_Option__c> mapQO = new Map<String,Quote_Option__c>();
        
        for(Quote objQuote : (List<Quote>)Trigger.new){
            if(objQuote.Status == 'Quoted' && mapOldQuote.get(objQuote.Id).Status != 'Quoted' 
               && (objQuote.Quote_Type__c == 'Full Amendment' || objQuote.Quote_Type__c == 'Coverage Amendment'
                   || objQuote.Quote_Type__c == 'Midterm Cancellation' || objQuote.Quote_Type__c == 'Flat Cancellation'
                   || objQuote.Quote_Type__c == 'Reinstatement')
              ){
                  
                  setQuoteId.add(objQuote.Id);
                  
              }
            
        }
        if(!setQuoteId.isEmpty())
        for(Quote_Option__c objQO : [Select Id, Bound__c, Quote__c, Actual_Premium__c, Broker_Netted_Down_Premium__c
                                     , Fee__c, Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c
                                     , Override_Fee_Percent__c, IPT_on_Broker_Netted_Down_Premium__c
                                     , Total_Cost_to_Client__c, Technical_Fee__c, Technical_Premium__c
                                     , NonProrated_Actual_Premium__c, NonProRated_BNDP__c
                                     from Quote_Option__c where Quote__c in :setQuoteId and Bound__c = true]){
                                         
                                         mapQO.put(objQO.Quote__c,objQO);
                                         
                                     }
        
        if(!mapQO.isEmpty()){
            
            for(Quote objQuote : (List<Quote>)Trigger.new){
                
                if(mapQO.containsKey(objQuote.Id)){
                    Quote_Option__c boundQuoteOption = mapQO.get(objQuote.Id);
                    objQuote.Actual_Premium__c = boundQuoteOption.Actual_Premium__c;
                    objQuote.Broker_Netted_Down_Premium__c = boundQuoteOption.Broker_Netted_Down_Premium__c;
                    objQuote.Fee__c = boundQuoteOption.Fee__c;
                    objQuote.IPT_on_Broker_Netted_Down_Premium__c = boundQuoteOption.IPT_on_Broker_Netted_Down_Premium__c;
                    objQuote.Total_Cost_to_Client__c = boundQuoteOption.Total_Cost_to_Client__c;
                    objQuote.Technical_Fee__c = boundQuoteOption.Technical_Fee__c;
                    objQuote.Technical_Premium__c = boundQuoteOption.Technical_Premium__c;
                    objQuote.NonProrated_Actual_Premium__c = boundQuoteOption.NonProrated_Actual_Premium__c;
                    objQuote.NonProRated_BNDP__c = boundQuoteOption.NonProRated_BNDP__c;
                }
                
            }
            
        }
        
    }

    public static void removeDuplicateQuoteOption(){

        List<Quote> listNewQuote = (List<Quote>)Trigger.new;
        Map<Id,Quote> mapOldQuote = (Map<Id,Quote>)Trigger.oldMap;
        Set<String> setQuoteId = new Set<String>();
        Map<String,List<Quote_Option__c>> mapQO = new Map<String,List<Quote_Option__c>>();
        Map<String,Quote_Option__c> mapFreeFormQO = new Map<String,Quote_Option__c>();
        List<Quote_Option__c> listQOtoUpdate = new List<Quote_Option__c>();
        List<String> listQOIdsforReferrals = new List<String>();
        List<Referral_Reason__c> listReferralReasonstoDelete = new List<Referral_Reason__c>();
        
        for(Quote objQuote : (List<Quote>)Trigger.new){
            
            if(objQuote.Status == 'Rated' && mapOldQuote.get(objQuote.Id).Status != 'Rated' 
               && (objQuote.Quote_Type__c == 'Renewal' || objQuote.Quote_Type__c == 'New Business')
              ){
                  
                  setQuoteId.add(objQuote.Id);
                  
              }
            
        }

        for(Quote_Option__c objQO : [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                    , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c,Quote__r.layer__c
                                    , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                    , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                    , Book_Premium_Annual__c, Minimum_Premium_Annual__c, Technical_Premium_Annual__c
                                    , Bound__c, Selected__c, Option_Type__c, Final_Technical_Premium__c
                                    , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c
                                    , Technical_Fee__c, IPT__c, Total_Cost_To_Client__c ,Tax_Percent__c
                                    , Actual_Premium__c, Broker_Netted_Down_Premium__c, Fee__c
                                    , Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c, Change_In_Fee__c
                                    , Change_in_IPT__c, Change_in_Total_Cost_to_Client__c, NonProrated_Actual_Premium__c, NonProRated_BNDP__c
                                    , IPT_on_Broker_Netted_Down_Premium__c, Quote__c, Quote__r.Parent_Quote__c, Quote__r.Parent_Quote__r.Actual_Premium__c
                                    , Quote__r.Parent_Quote__r.Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Fee__c
                                    , Quote__r.Parent_Quote__r.IPT_on_Broker_Netted_Down_Premium__c, Quote__r.Parent_Quote__r.Total_Cost_To_Client__c
                                    , Quote__r.Quote_Type__c  from Quote_Option__c  where Quote__c in :setQuoteId ]){
                                         
                                        if(objQO.Limit__c != null){
                                            if(mapQO.containsKey(objQO.Quote__c)){
                                                List<Quote_Option__c> listQO = new List<Quote_Option__c>();
                                                listQO = mapQO.get(objQO.Quote__c);
                                                listQO.add(objQO);
                                                mapQO.put(objQO.Quote__c,listQO);
                                                if(objQO.Option_Type__c == 'Free Form'){
                                                    mapFreeFormQO.put(objQO.Quote__c,objQO);
                                                }
                                            }
                                            else{
                                                List<Quote_Option__c> listQO = new List<Quote_Option__c>();
                                                listQO.add(objQO);
                                                mapQO.put(objQO.Quote__c,listQO);
                                                if(objQO.Option_Type__c == 'Free Form'){
                                                    mapFreeFormQO.put(objQO.Quote__c,objQO);
                                                }
                                            }
                                        }
                                     }
        
        if(!mapQO.isEmpty()){

            for(String quoteId : mapQO.keySet()){

                if(mapFreeFormQO.containsKey(quoteId)){
                    
                    List<Quote_Option__c> listQO = mapQO.get(quoteId);
                    Quote_Option__c objFreeFromQO = mapFreeFormQO.get(quoteId);
                    for(Quote_Option__c objQO : listQO){
                        if(objQO.Option_Type__c == 'Fixed Limit' && objQO.Limit__c == objFreeFromQO.Limit__c){
                            listQOIdsforReferrals.add(objFreeFromQO.Id);
                            SObject currentRecord = (SObject)objFreeFromQO;
                            Set<String> fieldsToExcludeForClearOut = new Set<String>{'Azure_ID__c', 'Option_Type__c',
                            'Quote__c'};
                            SObjectType objToken = Schema.getGlobalDescribe().get('Quote_Option__c');
                            DescribeSObjectResult objDef = objToken.getDescribe();
                            Map<String, SObjectField> fieldsSobject = objDef.fields.getMap();
                            Map<String, Object> fields = currentRecord.getPopulatedFieldsAsMap();
                            System.debug('fields--->'+fields);
                            Type classType = Type.forName('Quote_Option__c');
                            SObject freeFormQO = (SObject)JSON.deserialize('{}', classType);
                            SObject fixedLimitQO = (SObject)JSON.deserialize('{}', classType);
                            for (String field : fields.keySet()){
                                if (!fieldsToExcludeForClearOut.contains(field) && !field.contains('__r')){
                                    if (currentRecord.get(field)!=null && fieldsSobject.get(field).getDescribe().isUpdateable()){
                                        if ('Bound__c'.equals(field)){
                                            freeFormQO.put(field, false);
                                            fixedLimitQO.put(field, true);
                                        }else if ('Selected__c'.equals(field)){
                                            freeFormQO.put(field, false);
                                            fixedLimitQO.put(field, true);
                                        }else {
                                            freeFormQO.put(field, null);
                                            fixedLimitQO.put(field, currentRecord.get(field));
                                        }
                                    } 
                                    else if ('Id'.equals(field)){
                                        freeFormQO.put(field, currentRecord.get(field));
                                        fixedLimitQO.put(field, objQO.Id);
                                    }
                                }
                            }
                            Quote_Option__c tempFreeFormQO = new Quote_Option__c();
                            tempFreeFormQO = (Quote_Option__c)freeFormQO;
                            //listQOtoUpdate.add(tempFreeFormQO);
                            Quote_Option__c tempFixedLimitQO = new Quote_Option__c();
                            tempFixedLimitQO = (Quote_Option__c)fixedLimitQO;
                            System.debug('tempFixedLimitQO'+tempFixedLimitQO);
                            listQOtoUpdate.add(tempFixedLimitQO);
                            listQOtoUpdate.add(tempFreeFormQO);
                        }
                    }
                    
                }

            }

            if(!listQOIdsforReferrals.isEmpty()){
                listReferralReasonstoDelete = [Select Id from Referral_Reason__c where Quote_Option__c in :listQOIdsforReferrals];
            }

        }

        if(!listQOtoUpdate.isEmpty()){
            update listQOtoUpdate;
        }

        if(!listReferralReasonstoDelete.isEmpty()){
            delete listReferralReasonstoDelete;
        }

    }

    public static void pendingOrPriorProceedingsDate(List<Quote> celerityQuotes){
        
         
            for(Quote quote : celerityQuotes){
            
            if(quote.Quote_Type__c == 'New Business' && quote.Effective_Date__c != null && quote.Pending_or_Prior_Proceedings_Date__c == null)
                quote.Pending_or_Prior_Proceedings_Date__c = quote.Effective_Date__c;
          
        }
        
    }
/**************************************************************************
* Method Name: declinedsubmissionQuote
* Author: Ashik Zahir
* Date: 27-July-2021
* Params: List<Quote> celerityQuotes
* Description:  when StageName in Declined state, Quote should be Readonly 
***************************************************************************/
    public static void declinedsubmissionQuote(List<Quote> celerityQuotes){
        try{
            Map<Id, Quote> newQuotesMap = (Map<Id, Quote>) Trigger.newMap;
        	for(Quote q : [Select Id, Opportunity.StageName from Quote where ID IN :celerityQuotes]){
                if(q.Opportunity.StageName == 'Declined'){
                        newQuotesMap.get(q.Id).addError('Cannot Modify the Rejected Quote');
                }
        	}            
        }catch (Exception ex) {
            System.debug('@@@Exception'+ ex.getMessage());
            String errorMsg = 'Failed to edit Quote! <br/>Please contact your administators.';
            for(Quote item : (List<Quote>)Trigger.new ){
                item.addError(errorMsg);
            }
        }             
    }

    public static void setRetroactiveDate(List<Quote> aqueousQuote){
        
        Map<String,Master_Binder__c> mapMasterBinder = getMasterBinderName();

        for(Quote objQuote : aqueousQuote){
            if(!mapMasterBinder.isEmpty() && mapMasterBinder.containsKey(objQuote.Master_Binder__c) && mapMasterBinder.get(objQuote.Master_Binder__c).Name.contains('GAIC') && objQuote.Quote_Type__c == 'New Business'){
                objQuote.Retroactive_Date__c = 'Retro - Inception date';
                objQuote.RetroDate__c = objQuote.Effective_Date__c;
            }
        }

    }

    public static Map<String,Master_Binder__c> getMasterBinderName(){

        Map<String,Master_Binder__c> mapMasterBinder = new Map<String,Master_Binder__c>([Select Id, Name from Master_Binder__c] );

        return mapMasterBinder;

    }

    public static void addDefaultCoverages(List<Quote> lstAqQuotes){
        Map<Id, Set<String>> mapOfQuoteIdVsSetOfCoverageIds = new Map<Id, Set<String>>();

        for(Quote objQuote: lstAqQuotes){
            Set<String> setOfDefaultCoverageIds = new Set<String>();
            setOfDefaultCoverageIds.addAll(DefaultCoveragesUtil_AQ.GetDefaultCoveragesForQuote(objQuote.Id));
            if(!setOfDefaultCoverageIds.isEmpty()){
                mapOfQuoteIdVsSetOfCoverageIds.put(objQuote.Id,setOfDefaultCoverageIds);
            }
        }

        if(!mapOfQuoteIdVsSetOfCoverageIds.isEmpty()){
            DefaultCoveragesUtil_AQ.addEndorsementCLI(mapOfQuoteIdVsSetOfCoverageIds);
        }
    }
    
}