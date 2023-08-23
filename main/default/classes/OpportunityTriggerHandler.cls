/**
* @File Name          : OpportunityTriggerHandler.cls
* @Description        : 
* @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
* @Group              : 
* @Last Modified By   : Maeran Shaikh
* @Last Modified On   : 11-15-2021
* @Modification Log   : 
* Ver       Date            Author      		    Modification
* 1.0    6/2/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class OpportunityTriggerHandler extends TriggerHandler{
    List<Opportunity> oldDataList;
    List<Opportunity> newDataList;
    Map<Id, Opportunity> newDataMap;
    Map<Id, Opportunity> oldDataMap;
    public static final String DEFAULT_SUBMISSION_NAME_FOR_PCC = System.Label.DEFAULT_SUBMISSION_NAME_PCC;

    
    public OpportunityTriggerHandler(){
        this.oldDataList = (List<Opportunity>)Trigger.old;		
        this.oldDataMap = (Map<Id, Opportunity>)Trigger.oldMap;
       
        if(Trigger.new != null){ //For ignoring case of fire event beforeDelete or afterDelete -10Dec20-Khanh
            this.newDataList = (List<Opportunity>)Trigger.new;
            this.newDataMap = new Map<Id, Opportunity>([SELECT Id, Policy__c, Industry__c, Service_Classification__c, Coverage_Product_Options__c,
                                                        Product__r.Name, Total_Revenues__c,Innovisk_Entity_ID__c,Type, AccountId,
                                                        Account.SIC_Code__c, Main_Profession__c,Product_Name__c,
                                                        Account.SIC_Code__r.SIC_Description__c, Parent_Opportunity__c,
                                                        Account.SIC_Code__r.Crime_Eligibility_Status__c, 
                                                        Account.SIC_Code__r.Cyber_Eligibility_Status__c, 
                                                        Account.SIC_Code__r.D_O_Eligibility_Status__c, 
                                                        Account.SIC_Code__r.EPL_Eligibility_Status__c, 
                                                        Account.SIC_Code__r.Fiduciary_Eligibility_Status__c, 
                                                        Account.SIC_Code__r.MPL_Eligibility_Status__c
                                                        FROM Opportunity WHERE Id IN :Trigger.new]);
        }
        
    }
    
    public override void beforeInsert(){
        CommonUtil.generateExternalID('Azure_Id__c', newDataList);
        updateDnbInfoFromAccount(newDataList);
        generateOpportunityName(newDataList);
        
        List<Opportunity> AQPIOpp = new List<Opportunity>();
        for(Opportunity op: newDataList){
            if(op.Innovisk_Entity_ID__c == 'Aqueous'){
                AQPIOpp.add(op);
            }
        }
        if(!AQPIOpp.isEmpty()) updateAQTaxCountry(AQPIOpp);
        system.debug('InsidebeforInsert');
    }
    
    public override void beforeUpdate(){
        /*-------------------7757 : Update the Opportunity Name:= Account Name + Product Name--------------------------*/
        List<Opportunity> updateList = new List<Opportunity>();
        List<String> deleteExistingUWOppIds = new List<String>();

        List<Opportunity> celOpps = new List<Opportunity>();

        for (Opportunity obj : newDataList){
               system.debug('newDataList'+newDataList);

            if(obj.Innovisk_Entity_ID__c == 'Celerity'){
                celOpps.add(obj);
            }

            if (obj.Product__c != oldDataMap.get(obj.Id).Product__c) updateList.add(obj);
            if (obj.Main_Profession__c != oldDataMap.get(obj.Id).Main_Profession__c){
                deleteExistingUWOppIds.add(obj.Id);                
            }
        }
        // Added for US:52315  
        if(!celOpps.isEmpty()){
            resetClosedReason(newDataList, oldDataMap);
        }      
    
        deleteExistingUWAnalysis(deleteExistingUWOppIds);
        //Modified by Vinayesh. Generate new name always.
        generateOpportunityName(newDataList);
        /*--------------------End 7757-------------------------*/
        CommonUtil.generateExternalID('Azure_Id__c', newDataList);
        updateExpirationDate(newDataList, oldDataMap);
        
        //When value of object AccountClearance is Closed Market, StageName change is New
        accountClearancetoStagechange(newDataList);
        
        validateQuotedOpportunity(newDataList,oldDataMap);
        system.debug('Insidebeforupdate');
    }
    
    public override void afterInsert(){
        System.debug('this.newDataMap.values()'+this.newDataMap.values());
        AddRatingModifier(this.newDataMap.values());
        createQuoteProcess(newDataList);
        addSubmissionLostDetail(newDataMap);
        createUWAnalysis(this.newDataMap.values(), false);
        //Added by Vinayesh- update rating modifiers for PCC
        CommonUtil.updateRatingModifiersForOpps(this.newDataMap);
    }
    
    public override void afterUpdate(){
        List<Opportunity> AQPIOpp = new List<Opportunity>();
        List<Opportunity> celeritOpp = new List<Opportunity>();
        List<Opportunity> aqueousOpps = new List<Opportunity>();
        
        List<Opportunity> allCelerityOpps = new List<Opportunity>();
        for(Opportunity eachOpp : newDataList){
            System.debug('Celerity Check-->'+eachOpp.Innovisk_Entity_ID__c);
            if(eachOpp.Innovisk_Entity_ID__c == 'Celerity'){
                allCelerityOpps.add(eachOpp);
            }
            if(eachOpp.Innovisk_Entity_ID__c == 'Aqueous'){
                aqueousOpps.add(eachOpp);
            }
        }
        
        List<Opportunity> items = getChangedOpportunities(this.newDataMap.values());
        for(Opportunity op: items){
            if(op.Innovisk_Entity_ID__c == 'Aqueous'){
                AQPIOpp.add(op);
            }else{
                celeritOpp.add(op);
            }
        }
        updateRatingModifier(celeritOpp);
        if(!AQPIOpp.isEmpty()) updateRatingModifierForAQPI(AQPIOpp);
        if(!AQPIOpp.isEmpty())	updatePolicyWordingDocs(this.newDataMap.values(), oldDataMap);	//Opp Ids used to update related quote's Policy Wording
        //createEndorsementProcess(newDataMap, oldDataMap);
        updateServiceClassificationRattingModifiers((Map<Id, Opportunity>)Trigger.newMap,oldDataMap);
        
        updateQuotesToInProgress((Map<Id, Opportunity>)Trigger.newMap,oldDataMap);
        //When StageName is Unqualified to Close all the Quote associated with the Submission
        stageUnqualifiedCloseAllQuote(newDataList, oldDataMap);
        createUWAnalysisAfterUpdate(this.newDataMap.values(), oldDataMap);
        updateClosedWonSubmissions(newDataList, oldDataMap);
        //When Stage is decline then update related quote status to rejected
        
        // Added Celerity Check for Update related List
        if(!allCelerityOpps.isEmpty()){
           UpdateRelatedQuoteStatus(newDataList); 
        }

         //Added by Vinayesh- update rating modifiers for PCC
         CommonUtil.updateRatingModifiersForOpps(this.newDataMap);
         updateProductOptionLines();
         if(!aqueousOpps.isEmpty()){
            UpdateRelatedQuoteStatusAQ(newDataList, oldDataMap);
         }
    }
    
    
    public override void beforeDelete(){
        deleteQuoteProcess(this.oldDataMap);
    }
    
    /********************************************************************************
* Description: 
* 1. To delete the Quote Process when delete the the Submission that it lookup to
* 2. To fix bug #35042
* Khanh-10Dec20
********************************************************************************/
    private void deleteQuoteProcess(Map<Id, Opportunity> oldDataMap){
        List<Quote_Process__c> qp = [SELECT Id FROM Quote_Process__c WHERE Submission__c IN :oldDataMap.keySet()];
        if(!qp.isEmpty()) {
            delete qp;
        }
    }
    /*************************************
     * Description: Reselt closed reason when stage moved from Declient to any other status.
     */
    public static void resetClosedReason(List<Opportunity> newList, Map<Id, Opportunity> oldMap){ 
        for(Opportunity opp : newList){
            if(oldMap.get(opp.id).StageName != opp.StageName && oldMap.get(opp.id).StageName == 'Declined'){
                opp.Loss_Reason__c = null;
            }
        }
    }
    
    public static void updateQuotesToInProgress(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){ 
        System.debug('inprogress newMap'+newMap);
        try { 
            Map<Id, Opportunity> opportunityIdsToUpdateQuotes = new Map<Id, Opportunity>();
            for(Id recordId : newMap.keyset()){
                Opportunity newOpp = newMap.get(recordId);
                Opportunity oldOpp = oldMap.get(recordId);
                if(newOpp.Innovisk_Entity_ID__c == 'Celerity' && newOpp.StageName == 'Bound Pending'){
                    List<SectionSetting__c> sourceFieldAPIs = [SELECT Id,Source_Field_API__c FROM SectionSetting__c 
                                                               WHERE Component__c = 'Submission Info' AND Main_Section__c != 'Broker Account'
                                                               AND Record_Type__c = 'Celerity' And Source_Object__c = 'Opportunity'
                                                               And Profile_Name_for_Read_Only__c =null/* ORDER BY Order__c ASC*/];
                    
                    for (SectionSetting__c section : sourceFieldAPIs) {
                        String str = section.Source_Field_API__c;
                        if(str != 'Retroactive_Date__c' && str != 'Retroactive_Date_Docs__c' && str != 'Effective_Date_Docs__c' && str != 'StageName'){
                            if(newOpp.get(str) != oldOpp.get(str)){
                                opportunityIdsToUpdateQuotes.put(newOpp.Id, newOpp);
                            } 
                        }                   
                    }
                }
            }
            if(opportunityIdsToUpdateQuotes.size()>0 ){
                Set<String> statusQts = new Set<String>{'Rated', 'Referred', 'Quoted', 'Presented', 'Bound Pending'};
                    List<Quote> quotes = [Select Id,Status, Product_Name__c, OpportunityId From Quote Where OpportunityId IN :opportunityIdsToUpdateQuotes.keySet() And Status IN: statusQts]; 
                List<Quote> updateQuotes = new List<Quote>();
                for(Opportunity opp : opportunityIdsToUpdateQuotes.values()){
                    for(Quote q: quotes) {
                        if(q.OpportunityId == opp.Id && q.Status == 'Bound Pending') {
                            q.Status = 'In Progress';
                            updateQuotes.add(q);
                        }
                    }
                }       
                if(!updateQuotes.isEmpty())	 update updateQuotes;
            }
        } catch (Exception e) { 
            System.debug('Error: ' + e); 
        } 
    }
    
    public static void updateServiceClassificationRattingModifiers(Map<Id,Opportunity> newMap,Map<Id,Opportunity> oldMap ){
        List<Rating_Modifiers__c> updateItems = new List<Rating_Modifiers__c>();
        System.debug('ratingModifiersList');
        List<Rating_Modifiers__c> ratingModifiersList = [select Id,Rating_Modifier_Value__c,Opportunity__c,Eligibility_Status__c From Rating_Modifiers__c where Opportunity__c in:newMap.keySet() And Name ='Service Classification'];
        System.debug('ratingModifiersList'+ratingModifiersList);
        //Giang added 21/Jul/2020
        Map<String, String> eligibilityStatusMap = new Map<String,String>();
        for(Eligibility_Status__c eliStatus:  [SELECT Id,Eligibility_Status__c,Rating_Modifier_Value__c,Modifier_Product__c 
                                               FROM Eligibility_Status__c WHERE Rating_Modifier_Name__c = 'Service Classification']) 
        {
            eligibilityStatusMap.put(eliStatus.Rating_Modifier_Value__c + ':'+ eliStatus.Modifier_Product__c,  eliStatus.Eligibility_Status__c);
        }	
        System.debug('eligibilityStatusMap'+eligibilityStatusMap);
        for(Rating_Modifiers__c rt :ratingModifiersList ){
            if(newMap.get(rt.Opportunity__c).Service_Classification__c != oldMap.get(rt.Opportunity__c).Service_Classification__c){
                rt.Rating_Modifier_Value__c = newMap.get(rt.Opportunity__c).Service_Classification__c;
                //Giang added 21/Jul/2020
                String product = '';
                if(newMap.get(rt.Opportunity__c).Product_Name__c.contains('MPL'))   product = 'MPL';
                if(newMap.get(rt.Opportunity__c).Product_Name__c.contains('Cyber'))	product = 'Cyber';
                rt.Eligibility_Status__c = eligibilityStatusMap.get(rt.Rating_Modifier_Value__c +  ':' + product); 
                updateItems.add(rt);
                System.debug('updateItems' + updateItems);
            }
        }
        if(!updateItems.isEmpty()) update updateItems;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: opps - List of Opportunity
* Return: none
* Description: Create rating modifier from template for each opportunity
* Revision:
*************************************************/
    private void AddRatingModifier(List<Opportunity> opps){
        System.debug('opps'+opps);
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        Map<String, List<Rating_Modifier_Template__c>> templateMap = new Map<String, List<Rating_Modifier_Template__c>>();
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        try{
            List<String> products = getAllProductOptions(opps);
            //there is no products
            if (products.isEmpty())
                return;
            templates = CommonUtil.getRatingTemplatesByProducts(products);
            // no templates is found
            if (templates.isEmpty())
                return;
            // store all template in map to reduce soql query
            templateMap = generateTemplateMap(templates);
            result = generateModifiersForInsert(templateMap, opps);
            insert result;
        } catch (Exception ex){
            String errorMsg = 'Failed to create Rating Modifier.<br/>Please contact your administators.';
            System.debug('@@Error '+ex.getMessage());
            for (Opportunity opp : (List<Opportunity>)Trigger.new){
                opp.addError(errorMsg);
            }
        }
    }
    
    private List<Opportunity> getChangedOpportunities(List<Opportunity> items){
        List<Opportunity> result = new List<Opportunity>();
        for (Opportunity item : items){
            if (isProductChanged(item.Id))
                result.add(item);
        }
        return result;
    }
    
    private boolean isProductChanged(String id){
        Opportunity oldItem = this.oldDataMap.get(id);
        Opportunity newItem = this.newDataMap.get(id);
        if (oldItem == null || newItem == null) return false;
        if(oldItem.Innovisk_Entity_ID__c == 'Aqueous'){
            if(oldItem.Main_Profession__c != newItem.Main_Profession__c){
                return true;
            }
        }else if (oldItem.Product__c != newItem.Product__c || oldItem.Coverage_Product_Options__c != newItem.Coverage_Product_Options__c){
            return true;
        }			
        return false;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: opps - List of Opportunity
* Return: none
* Description: Delete old rating modifiers and add new ones based on coverage product options
* Revision:
*************************************************/
    private void updateRatingModifier(List<Opportunity> opps){
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        Map<String, List<Rating_Modifier_Template__c>> templateMap = new Map<String, List<Rating_Modifier_Template__c>>();
        List<Rating_Modifiers__c> existedModifiers = new List<Rating_Modifiers__c>();
        List<Rating_Modifiers__c> newModifiers = new List<Rating_Modifiers__c>();
        List<Rating_Modifiers__c> deleteModifiers = new List<Rating_Modifiers__c>();
        // create a save point in case something is wrong during DML process
        Savepoint sp = Database.setSavepoint();
        try{
            if (opps == null || opps.isEmpty())
                return;
            List<String> products = getAllProductOptions(opps);
            //there is no products
            if (products.isEmpty())
                return;
            templates = CommonUtil.getRatingTemplatesByProducts(products);
            // no templates is found
            if (templates.isEmpty())
                return;
            // store all template in map to reduce soql query
            templateMap = generateTemplateMap(templates);
            List<Rating_Modifier_Template__c> newTemplates = new List<Rating_Modifier_Template__c>();
            // put opportunities into map to get its id set
            Map<String, Opportunity> oppMap = generateOppMap(opps);           
            // get existed rating modifiers
            existedModifiers = CommonUtil.getRatingModifiersByOppIds(oppMap.keySet());
            // get existed products
            List<String> existedProducts = getAllProductOptions(existedModifiers);
            // get removed products
            List<String> removedProducts = getRemovedItems(existedProducts, products);
            // get ratings modifiers for deleting
            deleteModifiers = generateModifiersForDelete(existedModifiers, removedProducts);
            // get template for inserting
            Map<String, List<Rating_Modifier_Template__c>> insertTemplateMap = getTemplateForInsert(templateMap, existedProducts);
            // generate new rating modifiers
            newModifiers = generateModifiersForInsert(insertTemplateMap, opps);
            system.debug('newModifiers'+newModifiers);
            insert newModifiers;
            delete deleteModifiers;
        } catch (Exception ex){
            // rollback data
            Database.rollback(sp);
            String errorMsg = 'Failed to update Rating Modifiers.<br/>Please contact your administators.';
            for (Opportunity opp : (List<Opportunity>)Trigger.new){
                opp.addError(errorMsg);
            }
        }
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: templateMap - Map of rating templates
* Params: items - List of Opportunity
* Return: none
* Description: Generate list rating modiers for insert
* Revision:
*************************************************/
    private List<Rating_Modifiers__c> generateModifiersForInsert(Map<String, List<Rating_Modifier_Template__c>> templateMap, List<Opportunity> items){
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        for (Opportunity item : items){
            List<Rating_Modifier_Template__c> newTemplates = new List<Rating_Modifier_Template__c>();
            newTemplates = getTemplateByOpportunity(templateMap, item);
            
            if(item.Product_Name__c == 'Professional Indemnity'){
                List<Rating_Modifier_Template__c> newAQPITemplates = new List<Rating_Modifier_Template__c>();                
                for(Rating_Modifier_Template__c AQPITemp: newTemplates){
                    List<String> criteria = AQPITemp.Create_Criteria__c.split(';');
                    if(criteria.contains(item.Main_Profession__c)){
                        newAQPITemplates.add(AQPITemp);
                    }
                }
                newTemplates = newAQPITemplates;
            }
            // generate rating modifier from template
            List<Rating_Modifiers__c> ratings = generateRatingModifier(newTemplates, item);
            // skip if no rating is generated
            if (ratings.isEmpty())
                continue;
            result.addAll(ratings);
        }
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: items - List of rating modifier
* Params: products - product need to be remove
* Return: none
* Description: Generate list rating modiers for insert
* Revision:
*************************************************/
    private List<Rating_Modifiers__c> generateModifiersForDelete(List<Rating_Modifiers__c> items, List<String> products){
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        try{
            for (Rating_Modifiers__c item : items){
                if (!products.contains(item.Product__c))
                    continue;
                result.add(item);
            }
        } catch (Exception ex){
            result.clear();
        }
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: templates - List of Rating template
* Return: Map of Rating_Modifier_Template__c
* Description: generate a map to store all rating template by product name
* Revision:
*************************************************/
    private Map<String, List<Rating_Modifier_Template__c>> generateTemplateMap(List<Rating_Modifier_Template__c> items){
        Map<String, List<Rating_Modifier_Template__c>> result = new Map<String, List<Rating_Modifier_Template__c>>();
        try{
            for (Rating_Modifier_Template__c item : items){
                if(!String.isBlank(item.Product__c)){
                    List<String> productList = item.Product__c.split(';');
                    for(String prodName : productList){
                        // if map already contained product
                        if (result.containsKey(prodName)){
                            List<Rating_Modifier_Template__c> templates = result.get(prodName);
                            templates.add(item);
                            result.put(prodName, templates);
                        } else
                            result.put(prodName, new List<Rating_Modifier_Template__c>{item});
                    }					
                }
            }
        } catch (Exception ex){
            result.clear();
        }
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: templates - map of Rating template
* Params: opp - Opportunity
* Return: List of Rating_Modifier_Template__c
* Description: Get all rating template from input map by Opportunity
* Revision:
*************************************************/
    private List<Rating_Modifier_Template__c> getTemplateByOpportunity(Map<String, List<Rating_Modifier_Template__c>> templates, Opportunity opp){
        List<Rating_Modifier_Template__c> result = new List<Rating_Modifier_Template__c>();
        List<String> productNames = getProductOptions(opp); // get product options by opportunity
        try{
            if (opp == null || templates.size() == 0)
                return result;
            for (String item : productNames){
                // get templates by product name
                List<Rating_Modifier_Template__c> ratingTemplates = templates.get(item);
                // skip if no template is found
                if (ratingTemplates == null || ratingTemplates.isEmpty())
                    continue;
                result.addAll(ratingTemplates);
            }
        } catch (Exception ex){
            result.clear();
        }
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
    private List<Rating_Modifiers__c> generateRatingModifier(List<Rating_Modifier_Template__c> templates, Opportunity oppt){
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        // fetch product setting metadata
        Map<String, Product_Setting__mdt> productSettingMap = CommonUtil.getProductSettingMap();
        // SIC Industry Details
        SIC_Industry_Details__c sicIndustryRecord = new SIC_Industry_Details__c();
        if (String.isNotBlank(oppt.Account.SIC_Code__c)) sicIndustryRecord = oppt.Account.SIC_Code__r;
        String productName = '';
        // Standalone products can not have any Product Coverage Options Selected
        if(String.isNotBlank(oppt.Product__r.Name) && oppt.Product__r.Name.contains('Standalone')){
            productName = oppt.Product__r.Name.split(' ')[0];
        }else if(oppt.Innovisk_Entity_ID__c == 'Aqueous'){
            productName = oppt.Product__r.Name;
        }
        for (Rating_Modifier_Template__c item : templates){
            if(item.Page_Section__c !='SME Eligibility'){
                Rating_Modifiers__c rating = new Rating_Modifiers__c();
                if(item.Name == 'Service Classification'){
                    rating.Rating_Modifier_Value__c = oppt.Service_Classification__c;
                }else{
                    rating.Rating_Modifier_Value__c = item.Picklist_Default_Value__c;
                }
                rating.Opportunity__c = oppt.Id;
                rating.Page_Section__c = item.Page_Section__c;
                rating.Picklist_Values__c = item.Picklist_Values__c;
                rating.Product__c = productName;
                rating.Name = item.Name;
                rating.Sort_Order__c = item.Sort_Order__c;
                rating.Sort_Sub_Section__c = item.Sort_Sub_Section__c;
                rating.Sub_Section__c = item.Sub_Section__c;
                rating.Format__c = item.Modifier_Format__c;
                rating.Eligibility_Weighting_Factor__c = item.Eligibility_Weighting_Factor__c;
                rating.Rating_Modifier_Code__c = item.Rating_Modifier_Code__c;
                rating.Display_Format__c = item.Display_Format__c;
                rating.Factor_Min__c = item.Factor_Min__c;
                rating.Factor_Max__c = item.Factor_Max__c;
                rating.Profile_Name_for_Read_Only__c = item.Profile_Name_for_Read_Only__c;
                rating.Is_Required__c = item.Is_Required__c; //Giangphan 13/jul/2020 
                rating.Order_of_Page_Section__c = item.Order_of_Page_Section__c;               
                if (item.Page_Section__c.contains(Label.ELIGIBILITY_SECTION_HEADER) && (item.Name == Label.NATURE_OF_INDUSTRY_OR_SECTOR))
                {
                    if(String.isNotBlank(item.Product__c)){
                        List<String> prodList = item.Product__c.split(';');
                        for(String prodName : prodList){
                            // Populate the Eligibility Status field
                            if (productSettingMap.containsKey(prodName) && String.isNotBlank(sicIndustryRecord.Id)){
                                String apiEliStatus = productSettingMap.get(prodName).Eligibility_Status_API__c;
                                rating.Eligibility_Status__c = (String)sicIndustryRecord.get(apiEliStatus);
                            }
                        }
                    }
                }                
                result.add(rating);
            }			
        }
        system.debug('AQPI result BEFOre--'+result);
        if(oppt.Product_Name__c == 'Professional Indemnity' && oppt.Parent_Opportunity__c != null && oppt.Type == 'Renewal'){
            List<Rating_Modifiers__c> newRatingMods = new List<Rating_Modifiers__c>();
            String oldRateableExp = '';
            String oldAnnualGrossFees = '';
            for(Rating_Modifiers__c ratingMod: [Select Id,Name,Opportunity__c,Rating_Modifier_Value__c 
                                                From Rating_Modifiers__c
                                                Where Opportunity__c =: oppt.Parent_Opportunity__c]){
                                                    if(ratingMod.Name == 'Rateable Exposure'){
                                                        oldRateableExp = ratingMod.Rating_Modifier_Value__c;
                                                    }else if(ratingMod.Name == 'Annual gross fees / turnover'){
                                                        oldAnnualGrossFees = ratingMod.Rating_Modifier_Value__c;
                                                    }  
                                                }
            for(Rating_Modifiers__c ratM: result){
                if(ratM.Name == 'Rateable Exposure - Previous Year'){
                    ratM.Rating_Modifier_Value__c = oldRateableExp;
                }else if(ratM.Name == 'Annual gross fees / turnover - Previous Year'){
                    ratM.Rating_Modifier_Value__c = oldAnnualGrossFees;
                }  
            }
            system.debug('AQPI result rateMods--'+result);
        }
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: items - List of Opportunity
* Description: group Opportunity by Id
* Revision:
*************************************************/
    private Map<String, Opportunity> generateOppMap(List<Opportunity> items){
        Map<String, Opportunity> result = new Map<String, Opportunity>();
        if (items.isEmpty())
            return result;
        for (Opportunity item : items){
            result.put(item.Id, item);
        }
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: item - Opportunity
* Description: get list products of an opportunity
* Revision:
*************************************************/
    private List<String> getProductOptions(Opportunity item){
        List<String> result = new List<String>();
        try{
            if (item == null || item.Product__r == null)
                return result;
            String productName = item.Product__r.Name;
            /*if (productName.contains('Standalone'))
result.add(productName.split(' ')[0]);
else
result = item.Coverage_Product_Options__c.split(';');*/
            
            if(productName.contains('Standalone')){
                result.add(productName.split(' ')[0]);
            }else if(item.Innovisk_Entity_ID__c == 'Aqueous'){
                result.add(productName);
             //Added by Vinayesh. Need to remove this condition when we are able to
             //save Rating Modifiers for Pcc. Throwing error right now on save.
            }else if(productName == 'Private Company Combo'){
                return result;
            }else{
                result = item.Coverage_Product_Options__c.split(';');
            }
        } catch (Exception ex){
            result.clear();
        }
        return result;
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: item - List of Opportunity
* Description: get list products from a list of opportunity
* Revision:
*************************************************/
    private List<String> getAllProductOptions(List<Opportunity> items){
        Set<String> productOptions = new Set<String>();
        try{
            for (Opportunity item : items){
                List<String> products = getProductOptions(item);
                if (!products.isEmpty()) productOptions.addAll(products);
            }
        } catch (Exception ex){
            productOptions.clear();
        }
        return new List<String>(productOptions);
    }
    
    /*************************************************
* Author: Tuan Nguyen
* Date: 23-Aug-2019
* Params: item - List of Opportunity
* Description: get list products from a list of Rating Modifier
* Revision:
*************************************************/
    private List<String> getAllProductOptions(List<Rating_Modifiers__c> items){
        Set<String> productOptions = new Set<String>();
        try{
            for (Rating_Modifiers__c item : items){
                if (String.isBlank(item.Product__c)) continue;
                productOptions.add(item.Product__c);
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
    private List<String> getRemovedItems(List<String> oldItems, List<String> newItems){
        List<String> result = new List<String>();
        try{
            Set<String> oldSet = new Set<String>(oldItems);
            oldSet.removeAll(newItems);
            result = new List<String>(oldSet);
        } catch (Exception ex){
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
    private Map<String, List<Rating_Modifier_Template__c>> getTemplateForInsert(Map<String, List<Rating_Modifier_Template__c>> obj, List<String> products){
        Map<String, List<Rating_Modifier_Template__c>> result = new Map<String, List<Rating_Modifier_Template__c>>();
        result = obj.clone();
        for (String item : products){
            result.remove(item);
        }
        return result;
    }
    
    /*************************************************
* Author: Hoang Bui
* Date: 23-Oct-2019
* Description : update the expirationDate = effectiveDate+1day+1year
* Params: List<Opportunity> newDataList, Map<Id,Opportunity> oldDataMap
* Description:
* Revision:
*************************************************/
    private void updateExpirationDate(List<Opportunity> newDataList, Map<Id, Opportunity> oldDataMap){
        for (Opportunity opp : newDataList){
            if(opp.Product_Name__c != 'Professional Indemnity'){
                if (opp.Effective_Date__c != null && opp.Effective_Date__c != oldDataMap.get(opp.Id).Effective_Date__c){
                    opp.Expiration_Date__c = opp.Effective_Date__c.addYears(1);     
                }
            }
            else{
                if (opp.Effective_Date__c != null && opp.Effective_Date__c != oldDataMap.get(opp.Id).Effective_Date__c){
                    /*if(Math.mod(opp.Effective_Date__c.Year(),4) == 0)	opp.Expiration_Date__c = opp.Effective_Date__c.addDays(365);*//*----Commented by Gaurish CD-94------*/
                    if(Math.mod(opp.Effective_Date__c.Year(),4) == 0){
                        Date febDate = Date.newInstance(opp.Effective_Date__c.Year(),2,28);//-----CD-94-----START
                        if(opp.Effective_Date__c < febDate){
                            opp.Expiration_Date__c = opp.Effective_Date__c.addDays(365);
                        }
                        else{
                            opp.Expiration_Date__c = opp.Effective_Date__c.addDays(364);
                        }//-----CD-94-----END
                    }
                    else opp.Expiration_Date__c = opp.Effective_Date__c.addDays(364);
                }    
            }
        }
    }
    
    /*************************************************
* Author: Khanh
* Date: 1-Nov-2019
* Description : 7757 : Update the Opportunity Name:= Account Name + Product Name
* Params: List<Opportunity> newDataList, Map<Id,Opportunity> oldDataMap
* Description:
* Revision:
*************************************************/
    public static void generateOpportunityName(List<Opportunity> opportunitiesNew){
        Map<Id, Id> accountIdbyOpptMaps = new Map<Id, Id>();
        Map<Id, Id> productIdbyOpptMaps = new Map<Id, Id>();
        String productName = '';
        for (Opportunity oppt : opportunitiesNew){
            accountIdbyOpptMaps.put(oppt.Id, oppt.AccountId);
            productIdbyOpptMaps.put(oppt.Id, oppt.Product__c);
        }
        // get Map of Account
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id, Name FROM Account
                                                            WHERE Id IN :accountIdbyOpptMaps.values()]);
        // get Map of Product
        Map<Id, Product2> mapProduct = new Map<Id, Product2>([SELECT Id, Name FROM Product2
                                                              WHERE Id IN :productIdbyOpptMaps.values()]);
        for (Opportunity oppt : opportunitiesNew){
            Id accountId = accountIdbyOpptMaps.get(Oppt.Id);
            Id productId = productIdbyOpptMaps.get(Oppt.Id);
            
            if(mapAccount.get(accountId) != null) {
                
                if(mapAccount.get(accountId).Name.length() >= 100)
                    oppt.Name =  mapAccount.get(accountId).Name.substring(0, 100);
                else
                    oppt.Name =  mapAccount.get(accountId).Name;
                
            }
            if(mapProduct.get(productId) != null) {
                productName = mapProduct.get(productId).Name;
                if(oppt.Name != DEFAULT_SUBMISSION_NAME_FOR_PCC){
                    if(productName == 'Professional Indemnity'){
                        oppt.Name += ' ' + 'PI';
                    }else{
                        oppt.Name += ' ' + mapProduct.get(productId).Name;   
                    }
                }               
            }
            if(productName == 'Professional Indemnity'){
                oppt.Name += ' ' + Date.today().format();
            }
            
        }
    }
    
    /*************************************************
* Author: Hai Bui
* Date: 26-March-2020
* Params:	Map<Id, Opportunity> newMap
* Return:
* Description: Create Quote Process for opportunity
* Revision:
*************************************************/
    public static void createQuoteProcess(List<Opportunity> newList)
    {
        Set<String> filterIdsSet = new Set<String>();
        List<Opportunity> filterOppList = new List<Opportunity>();
        for (Opportunity opp : newList){
            if (!opp.Create_From_Quote_Process__c)
            {
                filterIdsSet.add(opp.Id);
                filterOppList.add(opp);
            }
        }
        
        List<Quote_Process__c> newQuoteProcessList = new List<Quote_Process__c>();
        for (Opportunity opp : filterOppList){
            newQuoteProcessList.add(new Quote_Process__c(Submission__c = opp.Id,Product__c = opp.Product_Name__c, Account__c = opp.AccountId, Status__c = 'Submission Info', Record_Type__c = opp.Innovisk_Entity_ID__c ));
        }
        insert newQuoteProcessList;
    }
    
    /*************************************************
* Author: Hai Bui
* Date: 05-June-2020
* Params:	List<Opportunity> newOpportunityList)
* Return:
* Description: update opp info consistent with account's D&B Info
* Revision:
*************************************************/
    public static void updateDnbInfoFromAccount(List<Opportunity> newOpportunityList){
        Map<Id,Account> mapAccount = new Map<Id, Account>();
        Set<String> accIds = new Set<String>();
        for(Opportunity opp: newOpportunityList){
            accIds.add(opp.AccountId);
        }
        for(Account acc : [Select Id,Current_Assets__c,Current_Liabilities__c,Total_Revenues__c,Total_Liabilities__c,
                           Total_Assets__c,Long_Term_Debt__c,Retained_Earnings__c,Net_Income__c from Account where Id in :accIds])
        {
            mapAccount.put(acc.Id,acc);
        }
        for(Opportunity opp: newOpportunityList){
            if(mapAccount.get(opp.AccountId) != null) {
                opp.Current_Assets__c = mapAccount.get(opp.AccountId).Current_Assets__c;
                opp.Current_Liabilities__c = mapAccount.get(opp.AccountId).Current_Liabilities__c;
                opp.Total_Revenues__c = mapAccount.get(opp.AccountId).Total_Revenues__c;
                opp.Total_Liabilities__c =  mapAccount.get(opp.AccountId).Total_Liabilities__c;
                opp.Total_Assets__c =  mapAccount.get(opp.AccountId).Total_Assets__c;
                opp.Long_Term_Debt__c =  mapAccount.get(opp.AccountId).Long_Term_Debt__c;
                opp.Retained_Earnings__c =  mapAccount.get(opp.AccountId).Retained_Earnings__c;
                opp.Net_Income__c =  mapAccount.get(opp.AccountId).Net_Income__c;
            }
            
        }
        
    }
    /*************************************************
* Author: tuan.d.nguyen
* Date: 16-Jun-2020
* Description :
* Params: List<Opportunity> newDataList, Map<Id,Opportunity> oldDataMap
* Description:
* Revision:
*************************************************/
    public static void addSubmissionLostDetail(Map<Id, Opportunity> newDataMap){
        List<Opportunity> listOpps = [SELECT Id, AccountId, Product_Name__c FROM Opportunity WHERE Id IN :newDataMap.keySet()];
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : listOpps)
            accountIds.add(opp.AccountId);
        
        List<Submission_Loss_Detail__c> listSubmissionLoss = new List<Submission_Loss_Detail__c>();
        for(Account_Loss_Detail__c accLoss : [SELECT Id, Name, Account__c, Loss_Amount__c,
                                              Number_of_Losses__c, OwnerId,Product__c, Status__c, Year__c
                                              FROM Account_Loss_Detail__c WHERE Account__c IN :accountIds]) 
        {
            for(Opportunity opp : listOpps) {
                if(opp.AccountId == accLoss.Account__c) {
                    Submission_Loss_Detail__c subLoss = new Submission_Loss_Detail__c();
                    subLoss.Loss_Amount__c = accLoss.Loss_Amount__c;
                    subLoss.Number_of_Losses__c = accLoss.Number_of_Losses__c;
                    subLoss.Product__c = accLoss.Product__c;
                    subLoss.Status__c = accLoss.Status__c;
                    subLoss.Year__c	 = accLoss.Year__c;
                    subLoss.Submission__c = opp.Id;
                    subLoss.Account_Loss_Detail__c = accLoss.Id;
                    listSubmissionLoss.add(subLoss);
                }
            } 
        }
        if(!listSubmissionLoss.isEmpty())
            insert listSubmissionLoss;
    }
    
    /*************************************************
* Author: Giang Phan
* Date: 19/June/2020
* Params: item - List of Submission
* Description:	If the Submission is changed to Unqualified after Quotes have been created,
Close all Quotes associated with the Submission.
* Revision: 
*************************************************/
    public static void stageUnqualifiedCloseAllQuote(List<Opportunity> oppListNew, Map<Id,Opportunity> oppMapOld){
        List<Quote> quotes = [SELECT Id, Name,OpportunityId FROM QUOTE WHERE OpportunityId IN :oppMapOld.keySet()]; 
        List<Quote_Process__c> quoteProcesses = [SELECT Id, Name, Submission__c FROM Quote_Process__c WHERE Submission__c IN :oppMapOld.keySet()];
        List<Quote> updateQuotes = new List<Quote>();
        List<Quote_Process__c> updateProcess = new List<Quote_Process__c>();
        for(Opportunity opp : oppListNew){
            if(opp.StageName =='Unqualified'){
                for(Quote q: quotes) {
                    if(q.OpportunityId == opp.Id) {
                        q.Status = 'Closed';
                        updateQuotes.add(q);
                    }
                }
                for(Quote_Process__c qp: quoteProcesses){
                    if(qp.Submission__c == opp.Id){
                        qp.Status__c = 'Submission Info';
                        updateProcess.add(qp);
                    }
                }
            }
        }
        if(!updateQuotes.isEmpty())	 update updateQuotes;
        if(!updateProcess.isEmpty()) update updateProcess;
    }
    
    /*************************************************
* Author: Giang Phan
* Date: 19/June/2020
* Params: item - List of Submission
* Description:	If the Account Clearance to the Submission = Closed Market, the StageName of Submission should be set to New
* Revision: 
*************************************************/
    public static void accountClearancetoStagechange(List<Opportunity> oppsListNew){
        for(Opportunity opp : oppsListNew){
            if(opp.Account_Clearance__c == 'Closed Market' && opp.StageName != 'Declined'){
                opp.StageName = 'New';
            }
        }
    }
    
    private static void createUWAnalysis(List<Opportunity> opps, Boolean isUpdate){
        List<String> oppMainProfession = new List<String>{'Territory','D&C Turnover Split'};
            if(isUpdate) oppMainProfession.remove(0);
        
        List<UW_Analysis_Template__c> uwTempTerritory = new List<UW_Analysis_Template__c>();
        List<UW_Analysis_Template__c> uwTempTerritoryAndDC = new List<UW_Analysis_Template__c>();
        List<UW_Analysis__c> uwAnalysisListToInsert= new List<UW_Analysis__c>();
        for(UW_Analysis_Template__c uwTemp : [SELECT Id, Name, UW_Analysis_Name__c, Criteria__c, 
                                              UW_Analysis_Code__c,Default_Split_Percentage__c, Rating_Factor__c, Sort_Order__c 
                                              FROM UW_Analysis_Template__c 
                                              Where Criteria__c IN: oppMainProfession]){
                                                  if(uwTemp.Criteria__c == 'Territory'){
                                                      uwTempTerritory.add(uwTemp);
                                                  }
                                                  uwTempTerritoryAndDC.add(uwTemp);
                                              }
        
        system.debug('uwTempTerritory== '+uwTempTerritory);
        system.debug('uwTempTerritoryAndDC== '+uwTempTerritoryAndDC);
        for(Opportunity opp : opps){
            if(opp.Product_Name__c == 'Professional Indemnity' && opp.Main_Profession__c != null){
                if(opp.Main_Profession__c == 'Design & Construct' && !uwTempTerritoryAndDC.isEmpty()){
                    for(UW_Analysis_Template__c uwTemp:uwTempTerritoryAndDC){
                        UW_Analysis__c uwAnalysis = new UW_Analysis__c ();
                        uwAnalysis.UW_Analysis_Name__c = uwTemp.UW_Analysis_Name__c;
                        uwAnalysis.Criteria__c = uwTemp.Criteria__c;
                        uwAnalysis.UW_Analysis_Code__c = uwTemp.UW_Analysis_Code__c;
                        uwAnalysis.Rating_Factor__c = uwTemp.Rating_Factor__c;
                        uwAnalysis.Sort_Order__c = uwTemp.Sort_Order__c;
                        uwAnalysis.Submission__c = opp.Id;
                        uwAnalysis.UW_Analysis_Template__c = uwTemp.Id;
                        uwAnalysis.Split_Percentage__c = uwTemp.Default_Split_Percentage__c;
                        uwAnalysis.Amount__c = 0;
                        uwAnalysisListToInsert.add(uwAnalysis);
                    }
                }else{
                    if(!uwTempTerritory.isEmpty()){
                        for(UW_Analysis_Template__c uwTemp:uwTempTerritory){
                            UW_Analysis__c uwAnalysis = new UW_Analysis__c ();
                            uwAnalysis.UW_Analysis_Name__c = uwTemp.UW_Analysis_Name__c;
                            uwAnalysis.Criteria__c = uwTemp.Criteria__c;
                            uwAnalysis.UW_Analysis_Code__c = uwTemp.UW_Analysis_Code__c;
                            uwAnalysis.Rating_Factor__c = uwTemp.Rating_Factor__c;
                            uwAnalysis.Sort_Order__c = uwTemp.Sort_Order__c;
                            uwAnalysis.Submission__c = opp.Id;
                            uwAnalysis.UW_Analysis_Template__c = uwTemp.Id;
                            uwAnalysis.Split_Percentage__c = uwTemp.Default_Split_Percentage__c;
                            uwAnalysisListToInsert.add(uwAnalysis);
                        }
                    }                    
                }                
                system.debug('uwAnalysisListToInsert== '+uwAnalysisListToInsert);
            }
        }
        if(!uwAnalysisListToInsert.isEmpty()){
            insert uwAnalysisListToInsert;
        }
    }
    
    private static void createUWAnalysisAfterUpdate(List<Opportunity> opps, Map<Id, Opportunity> oldDataMap){
        List<String> oppMainProfession = new List<String>{'D&C Turnover Split'};
            
            List<UW_Analysis_Template__c> uwTempTerritoryAndDC = new List<UW_Analysis_Template__c>();
        List<UW_Analysis__c> uwAnalysisListToInsert= new List<UW_Analysis__c>();
        for(UW_Analysis_Template__c uwTemp : [SELECT Id, Name, UW_Analysis_Name__c, Criteria__c, 
                                              UW_Analysis_Code__c,Default_Split_Percentage__c, Rating_Factor__c, Sort_Order__c 
                                              FROM UW_Analysis_Template__c 
                                              Where Criteria__c IN: oppMainProfession
                                              ORDER BY Sort_Order__c ASC]){
                                                  uwTempTerritoryAndDC.add(uwTemp);
                                              }
        
        system.debug('uwTempTerritoryAndDC== '+uwTempTerritoryAndDC);
        for(Opportunity opp : opps){
            if(opp.Product_Name__c == 'Professional Indemnity' && opp.Main_Profession__c != null 
               && opp.Main_Profession__c != oldDataMap.get(opp.Id).Main_Profession__c){                
                   if(opp.Main_Profession__c == 'Design & Construct' && !uwTempTerritoryAndDC.isEmpty()){
                       for(UW_Analysis_Template__c uwTemp:uwTempTerritoryAndDC){
                           UW_Analysis__c uwAnalysis = new UW_Analysis__c ();
                           uwAnalysis.UW_Analysis_Name__c = uwTemp.UW_Analysis_Name__c;
                           uwAnalysis.Criteria__c = uwTemp.Criteria__c;
                           uwAnalysis.UW_Analysis_Code__c = uwTemp.UW_Analysis_Code__c;
                           uwAnalysis.Rating_Factor__c = uwTemp.Rating_Factor__c;
                           uwAnalysis.Sort_Order__c = uwTemp.Sort_Order__c;
                           uwAnalysis.Submission__c = opp.Id;
                           uwAnalysis.UW_Analysis_Template__c = uwTemp.Id;
                           uwAnalysis.Split_Percentage__c = uwTemp.Default_Split_Percentage__c;
                           uwAnalysis.Amount__c = 0;
                           uwAnalysisListToInsert.add(uwAnalysis);
                       }
                   }                
                   system.debug('uwAnalysisListToInsert== '+uwAnalysisListToInsert);
               }
        }
        if(!uwAnalysisListToInsert.isEmpty()){
            insert uwAnalysisListToInsert;
        }
    }
    private static void updatePolicyWordingDocs(List<Opportunity> opps, Map<Id, Opportunity> oldDataMap){
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : opps){
            if(opp.Product_Name__c == 'Professional Indemnity' && opp.Main_Profession__c != null 
               && opp.Main_Profession__c != oldDataMap.get(opp.Id).Main_Profession__c){      
                   oppIds.add(opp.Id);
               }
        }
        if(oppIds.size() > 0){
            List<Quote> quoteList = [Select Id,Status,Name,IPID_Document__c,Policy_Wording_Document__c,Master_Binder__c,Policy_Wording__c,Layer__c,Opportunity.Main_Profession__c from Quote where OpportunityId IN :oppIds 
                                    AND (Status != 'Closed' AND Status != 'Rejected')];
            for(Quote newQuote : quoteList){
                if(newQuote.Status != 'In Progress'){newQuote.Status = 'In Progress';}
                String mainProfession = newQuote.Opportunity.Main_Profession__c;
                if(newQuote.Layer__c == 'Primary'){
                    if(mainProfession=='Accountants') newQuote.Policy_Wording__c = System.Label.PW_Accountants;//'AQUW/AC/04.19 Accountants';
                    if(mainProfession=='Architects') newQuote.Policy_Wording__c = System.Label.PW_Architects_Engineers;//'AQUW/AE/04.19 Architects & Engineers';
                    if(mainProfession=='Design & Construct') newQuote.Policy_Wording__c = System.Label.PW_Design_Construction;//'AQUW/DC/04.19 Design & Construction';
                    if(mainProfession=='Engineers') newQuote.Policy_Wording__c = System.Label.PW_Architects_Engineers;//'AQUW/AE/04.19 Architects & Engineers';
                    if(mainProfession=='Insurance Brokers') newQuote.Policy_Wording__c = System.Label.PW_Insurance_Brokers;//'AQUW/IB/04.19 Insurance Brokers';
                    if(mainProfession=='IT Consultants') newQuote.Policy_Wording__c = System.Label.PW_Technology_IT;//'AQUW/IT/04.19 Technology & IT';
                    if(mainProfession=='Miscellaneous') newQuote.Policy_Wording__c = System.Label.PW_Miscellaneous_Professions;//'AQUW/MP/04.19 Miscellaneous Professions';
                    if(mainProfession=='Property Professionals') newQuote.Policy_Wording__c = System.Label.PW_Property_Professionals;//'AQUW/PP/04.19 Property Professionals';
                    if(mainProfession=='Media Professionals') newQuote.Policy_Wording__c = System.Label.PW_Media_Marketing_Communication;//'AQUW/AD/04.19 Media, Marketing & Communication';
                }else{
                    newQuote.Policy_Wording__c = System.Label.PW_Excess_Layer;//'AQUW/EX/04.19 Excess Layer';
                }
                Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(newQuote);
                newQuote.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                if(newQuote.Layer__c != 'Excess')	newQuote.IPID_Document__c = quoteDoc.IPID_Document__c;  
            }
            if(quoteList.size() > 0)	update quoteList;    
        }        
    }
    private static void deleteExistingUWAnalysis(List<String> oppIds){
        system.debug('oppIds'+oppIds);
        List<UW_Analysis__c> uwToDelete = new List<UW_Analysis__c>();
        for(UW_Analysis__c uw:[SELECT Id, UW_Analysis_Name__c, Criteria__c
                               FROM UW_Analysis__c 
                               Where Submission__c IN:oppIds]){
                                   if(uw.Criteria__c != 'Territory'){
                                       uwToDelete.add(uw);
                                   }  
                               }
        if(!uwToDelete.isEmpty()){
            GlobalStaticVar.byPassUWAnalysisTrigger = true;
            delete uwToDelete;            
        }
    }
    
    private void updateRatingModifierForAQPI(List<Opportunity> opps){
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        Map<String, Map<String,Rating_Modifiers__c>> oppToRatingModMap = new Map<String, Map<String,Rating_Modifiers__c>>();       
        List<Rating_Modifiers__c> newModifiers = new List<Rating_Modifiers__c>();
        List<Rating_Modifiers__c> deleteModifiers = new List<Rating_Modifiers__c>();
        Set<Rating_Modifiers__c> rateModSetToDelete = new Set<Rating_Modifiers__c>();
        
        // create a save point in case something is wrong during DML process
        Savepoint sp = Database.setSavepoint();
        try{
            system.debug('## opps -- >'+opps);
            if (opps == null || opps.isEmpty())	return;
            List<String> products = getAllProductOptions(opps);
            if (products.isEmpty()) return;
            system.debug('## products -- >'+products);
            templates = [SELECT Factor_Default_Value__c,Factor_Max__c,Factor_Min__c,Modifier_Format__c,Product__c,Name,Page_Section__c,
                         Picklist_Default_Value__c,Picklist_Range__c,Picklist_Values__c,Sort_Order__c,Sort_Sub_Section__c,Comment__c,
                         Sub_Section__c,Eligibility_Weighting_Factor__c,Rating_Modifier_Code__c,Display_Format__c,
                         Profile_Name_for_Read_Only__c, Is_Required__c,Create_Criteria__c, Order_of_Page_Section__c 
                         FROM Rating_Modifier_Template__c 
                         WHERE Product__c IN: products
                         AND Page_Section__c =: 'Risk Capture'];
            
            if (templates.isEmpty()) return;
            system.debug('## templates -- >'+templates);
            // put opportunities into map to get its id set
            Map<String, Opportunity> oppMap = generateOppMap(opps);
            system.debug('## oppMap -- >'+oppMap);
            // get existed rating modifiers
            for(Rating_Modifiers__c rateMod: [SELECT Id, Rating_Modifier_Code__c, Opportunity__c, Page_Section__c               
                                              FROM Rating_Modifiers__c
                                              WHERE Opportunity__c IN :oppMap.keySet()
                                              AND Page_Section__c =: 'Risk Capture']){
                                                  rateModSetToDelete.add(rateMod);
                                                  if(oppToRatingModMap.containsKey(rateMod.Opportunity__c)) {
                                                      Map<String,Rating_Modifiers__c> rateModMap = oppToRatingModMap.get(rateMod.Opportunity__c);
                                                      rateModMap.put(rateMod.Rating_Modifier_Code__c,rateMod);
                                                      oppToRatingModMap.put(rateMod.Opportunity__c, rateModMap);
                                                  } else {
                                                      //oppToRatingModMap.put(rateMod.Opportunity__c, new List<Rating_Modifiers__c>{rateMod});
                                                      oppToRatingModMap.put(rateMod.Opportunity__c, new Map<String,Rating_Modifiers__c>());
                                                      system.debug('## oppToRatingModMap IN FOR-- >'+oppToRatingModMap);
                                                      oppToRatingModMap.get(rateMod.Opportunity__c).put(rateMod.Rating_Modifier_Code__c,rateMod);
                                                  }
                                                  
                                                  //deleteModifiers.add(rateMod);  
                                                  // oppToRatingModMap.put(rateMod.Opportunity__c,new List<Rating_Modifiers__c>{rateMod});
                                                  system.debug('## oppToRatingModMap IN -- >'+oppToRatingModMap);
                                              }            
            system.debug('## oppToRatingModMap -- >'+oppToRatingModMap);
            system.debug('## rateModSetToDelete BEFORE -- >'+rateModSetToDelete);
            for(Opportunity opp: opps){
                List<Rating_Modifier_Template__c> templateNew = new List<Rating_Modifier_Template__c>();
                List<Rating_Modifiers__c> rateModsNotToDeleteList = new List<Rating_Modifiers__c>();
                List<Rating_Modifier_Template__c> rateModTemplateToCreate = new List<Rating_Modifier_Template__c>();
                Map<String,Rating_Modifiers__c> exsitingModifierCodeToRateModMap = oppToRatingModMap.get(opp.Id);
                List<Rating_Modifier_Template__c> newAQPITemplates = new List<Rating_Modifier_Template__c>();  
                system.debug('## exsitingModifierCodeToRateModMap -- >'+exsitingModifierCodeToRateModMap);
                for(Rating_Modifier_Template__c AQPITemp: templates){
                    List<String> criteria = AQPITemp.Create_Criteria__c.split(';');
                    if(criteria.contains(opp.Main_Profession__c)){
                        templateNew.add(AQPITemp);
                    }
                }
                for(Rating_Modifier_Template__c rateTemp: templateNew){
                    if(exsitingModifierCodeToRateModMap.containsKey(rateTemp.Rating_Modifier_Code__c)){
                        rateModsNotToDeleteList.add(exsitingModifierCodeToRateModMap.get(rateTemp.Rating_Modifier_Code__c));
                        system.debug('## rateModsNotToDeleteList IN-- >'+rateModsNotToDeleteList);
                    }else{
                        rateModTemplateToCreate.add(rateTemp);
                    }
                }
                rateModSetToDelete.removeAll(rateModsNotToDeleteList);
                newModifiers = generateRatingModifier(rateModTemplateToCreate,opp);
                system.debug('## rateModSetToDelete -- >'+rateModSetToDelete);
                system.debug('## rateModsNotToDeleteList -- >'+rateModsNotToDeleteList);
            }
            
            List<Rating_Modifiers__c> listFromRateModSetToDelete = new List<Rating_Modifiers__c>(rateModSetToDelete);
            deleteModifiers.addAll(listFromRateModSetToDelete);
            system.debug('## newModifiers -- >'+newModifiers);
            system.debug('## deleteModifiers -- >'+deleteModifiers);
            if(!newModifiers.isEmpty()) insert newModifiers;
            if(!deleteModifiers.isEmpty()) delete deleteModifiers;
            UpdateRatingModifierFactor(newModifiers,opps);
        } catch (Exception ex){
            // rollback data
            Database.rollback(sp);
            system.debug('## ex.getLineNumber() -- >'+ex.getLineNumber());
            system.debug('## ex.getStackTraceString() -- >'+ex.getStackTraceString());
            system.debug('## ex.getMessage() -- >'+  ex.getMessage());  
            String errorMsg = 'Failed to update AQ PI Rating Modifiers.<br/>Please contact your administators.';
            for (Opportunity opp : (List<Opportunity>)Trigger.new){
                opp.addError(errorMsg);
            }
        }
    }
    
    private static void updateAQTaxCountry(List<Opportunity> newAQopp){
        Map<Id,Account> mapAccount = new Map<Id, Account>();
        Set<String> accIds = new Set<String>();
        Set<String> pickListValuesSet = new Set<String>();
        
        for(Opportunity opp: newAQopp){
            accIds.add(opp.AccountId);
        }
        
        for(Account acc : [Select Id, BillingCountry from Account where Id in :accIds]){
            mapAccount.put(acc.Id,acc);
        }
        
        for(Opportunity opp: newAQopp){
            if(mapAccount.get(opp.AccountId) != null) {
                if(mapAccount.get(opp.AccountId).BillingCountry != null){
                    String billingCountry = mapAccount.get(opp.AccountId).BillingCountry;
                    opp.Tax_Country__c = billingCountry;
                }
            }
        }
    }
    private static void updateClosedWonSubmissions(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap){
        List<String> closeQuoteStatus = new List<String>{'Bound', 'Bound Pending', 'Closed'};
            Set<Id> closedWonIds = new Set<Id>();
        Set<Id> boundOppsIds = new Set<Id>();
        Set<Id> boundInWaitOppsIds = new Set<Id>();
        for(Opportunity opp: newOpps){
            if(opp.StageName == 'Closed Won' && oldMap.get(opp.Id).StageName != 'Closed Won' && opp.Product_Name__c == 'Professional Indemnity'){
                closedWonIds.add(opp.Id);
            }
        }
        Map<Id, List<Quote>> quoteOppMap = new Map<Id, List<Quote>>();
        for(ID oppID: closedWonIds){
            quoteOppMap.put(oppID, [SELECT Id, Status,OpportunityId FROM Quote where OpportunityId =: oppID AND Status NOT IN: closeQuoteStatus]);
        }
        System.debug('quoteOppMap -->'+quoteOppMap);
        for(ID oppId: quoteOppMap.keyset()){
            if(quoteOppMap.get(oppId).size() == 0){
                boundOppsIds.add(oppId);
            }
            else{
                boundInWaitOppsIds.add(oppId);
            }
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        //Update Opportunities To Bound
        if(!boundOppsIds.isEmpty())
            for(Opportunity opp: [Select Id, Submission_Status__c from Opportunity where ID IN:boundOppsIds]){
                if(opp.Submission_Status__c != 'Bound'){
                    opp.Submission_Status__c = 'Bound';
                }
                oppsToUpdate.add(opp);
            }
        //Update Opportunities To Bound - In Waiting
        if(!boundInWaitOppsIds.isEmpty())
            for(Opportunity opp: [Select Id, Submission_Status__c from Opportunity where ID IN:boundInWaitOppsIds]){
                if(opp.Submission_Status__c != 'Bound - In Waiting'){
                    opp.Submission_Status__c = 'Bound - In Waiting';
                }
                oppsToUpdate.add(opp);
            }
        
        if(oppsToUpdate.size() > 0){
            update oppsToUpdate;
        }
    }
    
    private static void validateQuotedOpportunity(List<Opportunity> newOpps,Map<id,Opportunity> oldMap){
        for(Opportunity opp:newOpps){
            if((opp.Submission_Status__c == 'Hold Cover' || opp.Submission_Status__c == 'Information Requested' || opp.Submission_Status__c == 'VRI') && oldMap.get(opp.Id).Submission_Status__c == 'Quoted' && opp.Product_Name__c == 'Professional Indemnity'){
                opp.addError('Cannot update the Submission Status of a Quoted Opportunity');
            }
        }
    }
    
    public static void UpdateRelatedQuoteStatus(List<Opportunity> OppListNew ){
        Set<Id> ValidId = new Set<Id>();
        List<Quote> QuoteUpdate = new List<Quote>();
        for(Opportunity op : OppListNew){
            if(op.StageName =='Declined'){
                ValidId.add(op.Id);
            }
        }
        list<Opportunity> Opplist = [select id,(select id,Status from Quotes) from Opportunity where Id IN : validId];
        for(Opportunity opp : Opplist){
            for(Quote q : opp.Quotes){
                q.Status='Rejected';
                QuoteUpdate.add(q);
            }
        }
        if(!QuoteUpdate.isEmpty()){
            //Added by Ashik on 27-July-2021
            GlobalStaticVar.byPassQuoteTrigger = true;
            update QuoteUpdate;
            GlobalStaticVar.byPassQuoteTrigger = false;
            ID jobID = System.enqueueJob(new SyncQuoteQueueable(QuoteUpdate));
        }
        
    }
    
     public static void UpdateRatingModifierFactor(List<Rating_Modifiers__c> newModifiers, List<Opportunity> opps){
         set<Id> oppIds = new set<Id>();
         List<string> quoteStatus = new List<String>{'In Progress','Rated','Quoted'};
         Map<String,List<Quote>> oppQuoteListMap = new Map<String,List<Quote>>();
         List<Rating_Modifier_Factor__c> newRMFList = new List<Rating_Modifier_Factor__c>();
         Map<String,List<Rating_Modifier_Factor__c>> quoteRMFMap = new Map<String,List<Rating_Modifier_Factor__c>>();
         for(Opportunity opp: opps){
             oppIds.add(opp.Id);
         }
         List<Quote> quoteList = [select Id,Name,Status,OpportunityId from Quote where OpportunityId IN:oppIds AND Status IN: quoteStatus];
         if(!quoteList.isEmpty()){
             for(Quote quote :quoteList){
                 if(oppQuoteListMap.containsKey(quote.OpportunityId)){
                     oppQuoteListMap.get(quote.OpportunityId).add(quote);
                 }else{
                     oppQuoteListMap.put(quote.OpportunityId,new List<Quote> {quote});
                 }
             }  
         }
        
         for(Opportunity opp: opps){
             if(oppQuoteListMap.containsKey(opp.Id)){
                 if(oppQuoteListMap.get(opp.Id).Size() >0){
                     for(Quote quote: oppQuoteListMap.get(opp.Id)){
                         for(Rating_Modifiers__c ratMod: newModifiers){
                             Rating_Modifier_Factor__c factor = new Rating_Modifier_Factor__c();
                             factor.Factor_Default_Value__c = ratMod.Factor_Default_Value__c;
                             factor.Factor_Max__c = ratMod.Factor_Max__c;
                             factor.Factor_Min__c = ratMod.Factor_Min__c;
                             factor.Quote__c = quote.Id;
                             factor.Rating_Modifier__c = ratMod.Id;
                             newRMFList.add(factor); 
                         } 
                     }
                 }
             }
             
         }
         
         if(!newRMFList.isEmpty()){
             insert newRMFList;
         }
         
    }

    /**
    * @description : Delete POLI for opportunities where account is updated.
    * @author Vinayesh | 07-22-2021 
    **/
    private void updateProductOptionLines(){
    /* Currently not deleting POLI for account change on submission. */
    
        // Set<Id> changedOpps = new Set<Id>();
        // for(Opportunity opp: newDataMap.values()){
        //     if(oldDataMap.get(opp.Id).AccountId != opp.AccountId){
        //         changedOpps.add(opp.Id);
        //     }
        // }

        // if(changedOpps.size() > 0){
        //     List<Product_Option_Line_Item__c> poliRecList =  [SELECT Id From Product_Option_Line_Item__c
        //                                                       Where Submission__c In :changedOpps];
        //     if(poliRecList.size() > 0){
        //         delete poliRecList;
        //     }
        // }
       
    }

    public static void UpdateRelatedQuoteStatusAQ(List<Opportunity> OppListNew, Map<Id, Opportunity> oldDataMap){
        Map<Id, String> mapOfOppIdVsStatus = new Map<Id, String>();
        List<Quote> lstQuotesToBeUpdated = new List<Quote>();
        for(Opportunity opp : OppListNew){
            if(opp.StageName != oldDataMap.get(opp.Id).StageName && opp.StageName =='Declined'){
                mapOfOppIdVsStatus.put(opp.Id, 'Declined');
            }
            else if(opp.StageName != oldDataMap.get(opp.Id).StageName && oldDataMap.get(opp.Id).StageName =='Declined'){
                mapOfOppIdVsStatus.put(opp.Id, 'Undeclined');
            }
        }

        List<Opportunity> Opplist = [select id,(select id,Status from Quotes) from Opportunity where Id IN : mapOfOppIdVsStatus.keySet()];
        for(Opportunity opp : Opplist){
            if(mapOfOppIdVsStatus.get(opp.Id) == 'Declined'){
                for(Quote objQuote : opp.Quotes){
                    objQuote.Status='Rejected';
                    lstQuotesToBeUpdated.add(objQuote);
                }
            }
            else if(mapOfOppIdVsStatus.get(opp.Id) == 'Undeclined'){
                for(Quote objQuote : opp.Quotes){
                    objQuote.Status='In Progress';
                    lstQuotesToBeUpdated.add(objQuote);
                }
            }
        }
        
        if(!lstQuotesToBeUpdated.isEmpty()){
            GlobalStaticVar.byPassQuoteTrigger = true;
            update lstQuotesToBeUpdated;
            GlobalStaticVar.byPassQuoteTrigger = false;
            ID jobID = System.enqueueJob(new SyncQuoteQueueable(lstQuotesToBeUpdated));
        }
    }

}