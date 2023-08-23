/**
 * @File Name          : OpportunityModifiersCmpController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Maeran Shaikh
 * @Last Modified On   : 08-31-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/13/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class OpportunityModifiersCmpController {
	private static final String PROCEED_SELECTED = 'Proceed';
    private static final String PROCEED_W_CAUTION_SELECTED = 'Proceed with Caution';
    private static final String STOP_DECLINE_SELECTED = 'Stop!Decline!';
    private static final String MODIFIER_AND_FACTOR_VALUES = 'Modifier and Factor Values';
    private static final String FACTOR_VALUES_ONLY = 'Factor Values Only';
    private static final String QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES = 'Compare & Rate Quotes';
    private static final String QUOTE_PROCESS_STATUS_QUOTE_VERSION_CONSOLE = 'Quote Console';
    private static final String QUOTE_STATUS_QUALIFIED = 'Qualified';
    private static final String PRODUCT_AQ = 'Aqueous';

    //long ly - 19/Aug/2020 - fix bug 23997 QA_SF Cyber - Two sections are displayed for the pros/cons on the UW Analysis screen
	//Curentlly, Only for this case, maybe we can config in CustomMetadata later
	private static Map<String,List<String>> mapProductPageSection = new Map<String,List<String>>{'Cyber'=> new List<String>{'Primary Modifiers', 'Secondary Modifiers'}};

    

    /*************************************************
    * Author: Hang Lam
    * Date: 07-April-2020
    * Params: opportunityId - Opportunity Id
    * Return: productNames -  List String
    * Description: get list product name by opportunity Id
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static List<String> getProductNameTabs(String opportunityId) {
        return getProductNameByTab(opportunityId);
    }

    @AuraEnabled(cacheable = true)
    public static List<String> getProductNameTabsLwc(String opportunityId) {
        return getProductNameByTab(opportunityId);
    }

    @AuraEnabled
    public static List<Quote> checkExistingQuote(String opportunityId, String layer){ 
        List<Quote> quoteList = new List<Quote>();
        try {
            quoteList = [SELECT Id, Name FROM Quote WHERE Layer__c=: layer AND OpportunityId=: opportunityId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return quoteList;
    }

	@AuraEnabled
    public static List<Master_Binder__c> getMasterBindersFromQuote(String quoteId,String effectiveDate) {
        Date inceptionDate;
        System.debug('effectiveDate-->'+effectiveDate);
        List<Master_Binder__c> binderList = new List<Master_Binder__c>();
        List<Quote> quoteList = [Select Id,Name,Effective_Date__c,Account.BillingCountry,OpportunityId from Quote where Id =: quoteId];
        String accountBillingCountry = quoteList[0].Account.BillingCountry;
        if(effectiveDate != null){
            inceptionDate = Date.valueOf(effectiveDate);
        }else inceptionDate = quoteList[0].Effective_Date__c;
        System.debug('inceptionDate-->'+inceptionDate);
        //return getMasterBinders(quoteList[0].OpportunityId);
        return [Select Id,Name,Inception_Date__c,Expiry_Date__c,MGA_Commission__c,Layer__c,Country__c,
                          Coverholder_Name__c,Coverholder_Pin__c from Master_Binder__c 
                          where Inception_Date__c <= :inceptionDate AND 
                Expiry_Date__c >= :inceptionDate AND Country__c includes (:accountBillingCountry)];
    }
    @AuraEnabled
    public static Opportunity getOpportunityDetails(String opportunityId) {
        Opportunity opp = new Opportunity();
        try{
             // StageName Added by Rinku Saini For CD-116
            opp = [Select Id,Account.BillingCountry,Effective_Date__c,Expiration_Date__c,StageName from Opportunity where 
                                         Id =: opportunityId];
        }catch (Exception ex) {
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex)); 
        }  
        return opp;
    }
    @AuraEnabled
    public static List<Master_Binder__c> getMasterBinders(String opportunityId) {
        List<Master_Binder__c> binderList = new List<Master_Binder__c>();
        try{
            List<Opportunity> oppList = [Select Id,Account.BillingCountry,Effective_Date__c,Expiration_Date__c from Opportunity where 
                                         Id =: opportunityId];
            Opportunity opp = oppList[0];
            String accountBillingCountry = opp.Account.BillingCountry;
            System.debug('accountCountry-->'+opp.Account.BillingCountry);
            Date inceptionDate = Date.valueOf(opp.Effective_Date__c);
            binderList = [Select Id,Name,Inception_Date__c,Expiry_Date__c,MGA_Commission__c,Layer__c,Country__c,
                          Coverholder_Name__c,Coverholder_Pin__c from Master_Binder__c 
                          where Inception_Date__c <= :inceptionDate AND 
                          Expiry_Date__c >= :inceptionDate AND Country__c includes (:accountBillingCountry)];   
        }catch (Exception ex) {
            system.debug(ex.getMessage() + 'Master Binder Error:' + ex.getLineNumber());
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex)); 
        }        
        return binderList;
    }
    private static List<String> getProductNameByTab(String opportunityId) {
        List<String> productNames = new List<String>();
        // fetch Opportunities based on OpportunityId
        List<Opportunity> opportunities = [Select Id,StageName,Innovisk_Entity_ID__c, Product__r.Name,Coverage_Product_Options__c From Opportunity Where Id =: opportunityId];
        if(opportunities.isEmpty()) {
            return productNames;
        }
      
        String productName = opportunities[0].Product__r.Name;        
        // Standalone products can not have any Product Coverage Options Selected
        if(productName.contains('Standalone')){
            productNames.add(productName.split(' ')[0]);
        }else if(opportunities[0].Innovisk_Entity_ID__c == 'Aqueous'){
            productNames.add(productName);
        }
        else if(productName.contains('Private Company Combo')){
            productNames.add(productName);
        }
        else if(String.isNotBlank(opportunities[0].Coverage_Product_Options__c)){
            productNames = opportunities[0].Coverage_Product_Options__c.split(';');
        }
        system.debug('productNames  ' + productNames);
        return productNames;
    }

    

    /*************************************************
    * Author: Hang Lam
    * Date: 07-April-2020
    * Params: jsonTabWrap - json data of tab from component
              opportunityId - Opportunity Id
    * Return: 
    * Description: save record, update data of opportunity and quote
    * Revision: 
    *************************************************/

    @AuraEnabled
    public static void saveRecordTabLwc(String jsonTabWrap, String opportunityId, Boolean checkRatVal){
        Boolean doQuoteUpdateIfBaseRateChange = false;
        try {
            List<Opportunity> opp = [SELECT Product_Name__c FROM Opportunity WHERE Id =: opportunityId];
            if(opp[0].Product_Name__c == 'Cyber Standalone') doQuoteUpdateIfBaseRateChange = true;
            system.debug('123 doQuoteUpdateIfBaseRateChange - '+doQuoteUpdateIfBaseRateChange);
            List<Quote> quoteUpdates = new List<Quote>();

            List<MainSection> mainSecList = (List<MainSection>)JSON.deserialize(jsonTabWrap, List<MainSection>.class);
            List<Rating_Modifiers__c> ratingModifierUpdates = new List<Rating_Modifiers__c>();
            List<ItemWrapper> ratingModifierWrapAlls = new  List<ItemWrapper>();
            for (MainSection mainSec : mainSecList) {
                if(!mainSec.items.isEmpty()) ratingModifierWrapAlls.addAll(mainSec.items);
                for(SubSection subSec : mainSec.subSections){
                    if(!subSec.items.isEmpty()) ratingModifierWrapAlls.addAll(subSec.items);
                }
            }

            Set<Id> ratingModFieldIdSet = new Set<Id>();
            Map<String, String> ratingModCodeMap = new Map<String, String>();
            List<Rating_Modifiers__c> newRatingModList = new List<Rating_Modifiers__c>();
            for(ItemWrapper ratingModfWrap : ratingModifierWrapAlls) {
                ratingModCodeMap.put(ratingModfWrap.item.Id, ratingModfWrap.item.Rating_Modifier_Code__c);
				newRatingModList.add(ratingModfWrap.item);                                
            }
            //check change in values
            Boolean isChanged = false;
			List<Rating_Modifiers__c> oldRatingModifiers = [select Id,Rating_Modifier_Code__c,Rating_Modifier_Value__c,Opportunity__c 
                                                            from Rating_Modifiers__c where Opportunity__c =:opportunityId];
            Map<String,Rating_Modifiers__c> oldValueMap = new Map<String,Rating_Modifiers__c>();
            
            if(!oldRatingModifiers.isEmpty()){
                for(Rating_Modifiers__c oldRatMod : oldRatingModifiers){
                    oldValueMap.put(oldRatMod.Id,oldRatMod);
                }
            }
            system.debug('oldValueMap->'+oldValueMap);
            if(!newRatingModList.isEmpty()){
                for(Rating_Modifiers__c newRatMod : newRatingModList) {
                    if(oldValueMap.get(newRatMod.Id).Rating_Modifier_Value__c != newRatMod.Rating_Modifier_Value__c){
                        isChanged = true;
                    }
                }
            }
            
            if(String.isNotBlank(opportunityId) && isChanged) {
                quoteUpdates =  getQuoteRelatedOppt(opportunityId);
                system.debug('quoteUpdates: '+quoteUpdates+' checkRatVal: '+checkRatVal);
                if(!quoteUpdates.isEmpty()){
                    for(Quote qt : quoteUpdates) {
                        if(qt.Product_Name__c  == 'Professional Indemnity' && qt.Status != 'Bound Pending'){
                            if(checkRatVal){
                                if(qt.Status == 'Quoted') qt.Status = 'Rated';
                            }else{
                                qt.Status = 'In Progress';
                            }
                        }
                        else{
                            if(qt.Status == 'Bound Pending') {doQuoteUpdateIfBaseRateChange = false;}
                            if(qt.Status != 'In Progress'){
                                qt.Status = 'In Progress';
                                qt.Rating_Status__c = '';
                            }
                        }
                    }
                }
            }
            
            Map<String, Rating_Modifier_Template__c> ratModTemMap = new Map<String, Rating_Modifier_Template__c> ([SELECT Id, Rating_Modifier_Code__c
                                                            FROM Rating_Modifier_Template__c
                                                            WHERE Rating_Modifier_Code__c IN: ratingModCodeMap.values()]);
            
            Map<String, String> ratingModValueStatusMap = new Map<String, String>();
            for(Eligibility_Status__c eliStatus : [SELECT Id, Rating_Modifier_Template__c, Eligibility_Status__c, Rating_Modifier_Value__c
                                                    FROM Eligibility_Status__c
                                                    WHERE Rating_Modifier_Template__c IN: ratModTemMap.keyset()
                                                    ]){
                ratingModValueStatusMap.put(eliStatus.Rating_Modifier_Value__c, eliStatus.Eligibility_Status__c);
            }

            for(ItemWrapper ratingModfWrap : ratingModifierWrapAlls) {
                Rating_Modifiers__c ratingModifierUpdate = ratingModfWrap.item;
                if(ratingModifierUpdate.Display_Format__c == 'Primary Modifiers'){
                    ratingModifierUpdate.Eligibility_Status__c = ratingModValueStatusMap.get(ratingModfWrap.item.Rating_Modifier_Value__c);
                }
                ratingModifierUpdates.add(ratingModifierUpdate);
            }
            if(doQuoteUpdateIfBaseRateChange){//chck product cyber
                if(isBaseRateValueChange(mainSecList, opportunityId)){
                    System.debug('123 Inside isBaseRateValueChange ' +isBaseRateValueChange(mainSecList, opportunityId));
                    doQuoteUpdateIfBaseRateChange = false; 
                }
            }
             
            system.debug('123 doQuoteUpdateIfBaseRateChange - '+doQuoteUpdateIfBaseRateChange);
            // Update quotes

            // Update Rating modifiers
            if(!ratingModifierUpdates.isEmpty()){
                update ratingModifierUpdates;
                //updateQuoteStatus(ratingModifierUpdates);
            }
            
            if(!quoteUpdates.isEmpty() && !doQuoteUpdateIfBaseRateChange){
                update quoteUpdates;
            }
            system.debug('quoteUpdates-->'+quoteUpdates);
            
        } catch (Exception ex) {
            system.debug(ex.getMessage() + ':444:' + ex.getLineNumber());
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex)); 
        }
    }
    
    private static Boolean isBaseRateValueChange(List<MainSection> mainSecList, String opportunityId){
        Boolean isBaseRateChanged = false;
        Set<String> RMfCode = new Set<String>();
        Map<String, String> RMfCodeToRMfValueMap = new Map<String, String>();
        List<ItemWrapper> ratingModifierWrapAlls = new  List<ItemWrapper>();
        
        for (MainSection mainSec : mainSecList) {
            system.debug('123 mainSec -'+mainSec.name);
            if(mainSec.name == 'Base Rate'){
                system.debug('123 INN -'+mainSec.name);
                if(!mainSec.items.isEmpty()) ratingModifierWrapAlls.addAll(mainSec.items);
                for(SubSection subSec : mainSec.subSections){
                    if(!subSec.items.isEmpty()) ratingModifierWrapAlls.addAll(subSec.items);
                }   
            }                
        }        
               
        for(ItemWrapper RMf :ratingModifierWrapAlls){
            RMfCode.add(RMf.item.Rating_Modifier_Code__c);
        }
        
        for(Rating_Modifiers__c RMf : [SELECT Opportunity__c, Rating_Modifier_Value__c, Rating_Modifier_Code__c 
                                       FROM Rating_Modifiers__c
                                      WHERE Opportunity__c=:opportunityId AND Rating_Modifier_Code__c IN:RMfCode]){
            RMfCodeToRMfValueMap.put(RMf.Rating_Modifier_Code__c, RMf.Rating_Modifier_Value__c);
        }
        
        for(ItemWrapper baseRateRMf :ratingModifierWrapAlls){
            if(baseRateRMf.item.Rating_Modifier_Value__c != RMfCodeToRMfValueMap.get(baseRateRMf.item.Rating_Modifier_Code__c)){
                isBaseRateChanged = true;
                break;
            }         
        }        
        return isBaseRateChanged;
    }

    public static ResultResponse updateQuoteStatus(List<Rating_Modifiers__c> newItems){
        ResultResponse result = new ResultResponse();
        try{
            Set<String> oppIDs = new Set<String>();
            for(Rating_Modifiers__c ratingModifier : newItems){
                oppIDs.add(ratingModifier.Opportunity__c);
            }
            List<Quote> updateItems = new List<Quote>();
            for(Quote q : [Select Id,Status
                            from Quote
                            where OpportunityId in:oppIDs and (Status = 'Quoted' OR Status = 'Rated' )]) {
                q.Status = 'In Progress';
                updateItems.add(q);
            }
            update  updateItems;
            result.isSuccess  = true;
            return result;
        }catch (Exception ex){
            result.errors.add(ex.getMessage());
            return result;
        }
    }
    /*************************************************
    * Author: Phuong La
    * Date: 07-April-2020
    * Params:  productName   - Product Name
               opportunityId - Opportunity Id
    * Return:  tabWrapRes -  Tab Wrapper
    * Description: get Rating Modifiers for CheckRiskHealthCmp
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static List<Rating_Modifiers__c> getRatingModifiersForRiskHealth(String productName, String opportunityId ) {
        String searchEli = '%' + Label.ELIGIBILITY_SECTION_HEADER  + '%';

        // fetch Rating Modifiers based on Product Name List 
        List<Rating_Modifiers__c> ratingModTemps = [Select Id, Name, Rating_Modifier_Value__c, Eligibility_Status__c
                                                    From Rating_Modifiers__c  Where Product__c =: productName
                                                    And Opportunity__c =: opportunityId
                                                    And Page_Section__c != null
                                                    And Display_Format__c = 'Primary Modifiers'
                                                    Order By Product__c ASC, Page_Section__c ASC, Sort_Order__c ASC,Sort_Sub_Section__c ASC];

        return ratingModTemps;
    }

    /****************************https://innoviskcp3--celertydev.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#*********************
    * Author: Phuong La
    * Date: 07-April-2020
    * Params:  opportunityId - Opportunity Id
    * Return:  
    * Description: update Stage and populate fields of Opportunity
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static Boolean updateStageAndPopulateFields(String opportunityId){
        Boolean result = false;
        try{
            List<Opportunity> opportunities = [SELECT Id,Product_Name__c,StageName,Eligibility_Approver__c,Eligibility_Approval_Date_Time__c	
            FROM Opportunity WHERE Id =: opportunityId];
            if(opportunities.isEmpty()) return null;

            opportunities[0].StageName = QUOTE_STATUS_QUALIFIED;
            opportunities[0].Eligibility_Approver__c = UserInfo.getUserId();
            opportunities[0].Eligibility_Approval_Date_Time__c = System.now();

            List<Quote_Process__c> quotes = [SELECT Id,Status__c From Quote_Process__c WHERE Submission__c =: opportunityId];
            for (Quote_Process__c quote : quotes) {
                
                quote.Status__c = QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES;
                if(opportunities[0].Product_Name__c == 'Private Company Combo'){
                    quote.Status__c = QUOTE_PROCESS_STATUS_QUOTE_VERSION_CONSOLE;
                }
            }
            // Compare & Rate Quotes
            update quotes;
            update opportunities;
            result = true;

        }catch(Exception e){
            System.debug('@@@ Proceed to Quote Err '+ e.getMessage());
        }
        return result;
    }

    /*************************************************
    * Author: Hang Lam
    * Date: 07-April-2020
    * Params: opportunityId - Opportunity Id
    * Return: quotes - List Quote
    * Description: get quotes of opportunity
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static List<Quote> getQuoteRelatedOppt(String opportunityId) {
        Set<String> statusQts = new Set<String>{'In Progress','Rated', 'Referred', 'Quoted', 'Presented', 'Bound Pending'};
        List<Quote> quotes = [Select Id,Status, Product_Name__c From Quote
                                Where OpportunityId =: opportunityId
                                And Status IN: statusQts];

        return quotes;
    }
    
    @AuraEnabled
    public static String getMainProfession(String opportunityId){
        List<Opportunity> opp = [Select Name, Main_Profession__c From Opportunity Where Id=:opportunityId];
        String mainPro;
        if(!opp.isEmpty()){
            mainPro = opp[0].Main_Profession__c;
        }
        return mainPro;
    }
    
    /*************************************************
    * Author: Hang Lam
    * Date: 07-April-2020
    * Params: productName - product name
              opportunityId - Opportunity Id
    * Return: result - ResultResponse
    * Description: get main section data to return data for component
    * Revision: 
    *************************************************/
	@AuraEnabled
    public static ResultResponse getMainSectionFromProduct(String productName, String opportunityId){
    	return getMainSectionByProduct(productName,opportunityId);
    }

    @AuraEnabled
    public static ResultResponse getMainSectionFromProductLwc(String productName, String opportunityId){
    	return getMainSectionByProduct(productName,opportunityId);
    }

    private static ResultResponse getMainSectionByProduct(String productName, String opportunityId) {
        ResultResponse result = new ResultResponse();
        try {
            system.debug('productName '+productName);
            List<Opportunity> opportunities = [Select Id, StageName, Type From Opportunity Where Id =: opportunityId];
            if(opportunities.isEmpty()) return result;
            
            system.debug('opportunities -'+opportunities);
            List<Rating_Modifiers__c> ratingModList = getEligibilityRatingModifiers(productName, opportunityId);
        	Map<String, MainSection> mainSectionMap = getDataForMainSecWrapper(ratingModList);
            system.debug('mainSectionMap '+mainSectionMap);
        	TabItem tab = new TabItem();
        	if(mainSectionMap != null){
        		// get main and sub sections
	            //tab.mainSections = mainSectionMap.values();

	            // get active sections
	            for(MainSection mainSec : mainSectionMap.values()){
	            	if(mainSec.isActiveSection){
                        if(mainSec.name != 'SME Eligibility'){
                            tab.activeSections.add(mainSec.name);
                        }                        
                        tab.mainSections.add(mainSec);
                    } 
	            }
                for(MainSection mainSec : mainSectionMap.values()){
                    if(!mainSec.isActiveSection){
                        tab.mainSections.add(mainSec);
                    } 
                }
        	}
            result.data = tab;
            result.isSuccess = true;
        }catch (Exception ex) {
        	System.debug('@@@Exception: ' + ex.getMessage());
        	result.errors.add(CommonUtil.getExceptionMessage(ex));
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex)); 
        }
        return result;
    }

    /*************************************************
    * Author: Hang Lam
    * Date: 07-April-2020
    * Params: ratingModTemps - list of rating modifier
    * Return: mainSec_MainSecWrapMap - Map(String, MainSection)
    * Description: get data for main section and sub section
    * Revision: 
    *************************************************/
    private static Map<String, MainSection> getDataForMainSecWrapper(List<Rating_Modifiers__c> ratingModTemps) {
        //Map<String,MainSection> mainSecWrapMap = new  Map<String,MainSection>();
        List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String currentProflieName = lstProfile[0].Name;
        Map<String, SubSection> mainSubSec_SubSecWrapMap = new  Map<String, SubSection>();
        Map<String, MainSection> mainSec_MainSecWrapMap = new  Map<String, MainSection>();
        for(Rating_Modifiers__c ratingModf : ratingModTemps){
            ItemWrapper ratingModifierWrap = createRatingModifierWrap(ratingModf, currentProflieName);
        	if(!mainSec_MainSecWrapMap.containsKey(ratingModf.Page_Section__c)) {
        		MainSection mainSecWrap = new MainSection();
                mainSecWrap.name = ratingModf.Page_Section__c;
                if(String.isBlank(ratingModf.Sub_Section__c)) {
                    mainSecWrap.items.add(ratingModifierWrap);
                }else {
                	String mainSubSecKey = ratingModf.Page_Section__c + ratingModf.Sub_Section__c;
                	// Create a new Sub Section Wrapper
                    
                    if(!mainSubSec_SubSecWrapMap.containsKey(mainSubSecKey)){
                    	SubSection subSecWrap = new SubSection();
	                    subSecWrap.name = ratingModf.Sub_Section__c;
	                    subSecWrap.items.add(ratingModifierWrap);
	                    mainSecWrap.subSections.add(subSecWrap);
                    	mainSubSec_SubSecWrapMap.put(mainSubSecKey, subSecWrap);
                    }

                    //mainSubSec_SubSecWrapMap.put(mainSubSecKey, subSecWrap);
                    //mainSecWrap.subSections.add(subSecWrap);
                }
                if(ratingModf.Display_Format__c == 'Primary Modifiers') mainSecWrap.isActiveSection = true;
                mainSec_MainSecWrapMap.put(ratingModf.Page_Section__c, mainSecWrap);
        	}else{
        		MainSection mainSecWrapExist = mainSec_MainSecWrapMap.get(ratingModf.Page_Section__c);
        		if(String.isBlank(ratingModf.Sub_Section__c)) {
                    mainSecWrapExist.items.add(ratingModifierWrap);
                }else {
                	String mainSubSecKey = ratingModf.Page_Section__c + ratingModf.Sub_Section__c;
                    
                    if(!mainSubSec_SubSecWrapMap.containsKey(mainSubSecKey)) {
                    	SubSection subSecWrap = new SubSection();
                        subSecWrap.name = ratingModf.Sub_Section__c;
                        subSecWrap.items.add(ratingModifierWrap);
                        mainSecWrapExist.subSections.add(subSecWrap);
                        mainSubSec_SubSecWrapMap.put(mainSubSecKey, subSecWrap);
                    }else{
                    	SubSection subSecWrapExist = mainSubSec_SubSecWrapMap.get(mainSubSecKey);
                    	for(Integer i = 0; i< mainSecWrapExist.subSections.size() ; i++){
                    		if(mainSecWrapExist.subSections[i].name == subSecWrapExist.name){
                    			mainSecWrapExist.subSections[i].items.add(ratingModifierWrap);
                    		}
                    	}
                        mainSubSec_SubSecWrapMap.put(mainSubSecKey, subSecWrapExist);
                    }

                }
        	}
        }

        return mainSec_MainSecWrapMap;
    }

    /*************************************************
    * Author: Hang Lam
    * Date: 07-April-2020
    * Params: ratingModifier - Rating_Modifiers__c
    * Return: ratingModifierWrap - ItemWrapper
    * Description: get data for ItemWrapper base on ratingModifier
    * Revision: 08/25/2020 - Hang Lam - Defect 27641
    *************************************************/
    private static ItemWrapper createRatingModifierWrap(Rating_Modifiers__c ratingModifier, String currentProflieName){
    	// Create new Rating Modifier Template Wrapper
        ItemWrapper ratingModifierWrap = new ItemWrapper();
        ratingModifierWrap.item = ratingModifier;

        // When Modifier Format is Picklist
        if(ratingModifier.Format__c == 'Picklist' || ratingModifier.Format__c == 'Radio Button') {
            List<PicklistOption> picklistOptTemps = createPicklistOptionValues(ratingModifier.Picklist_Values__c);
            if(!picklistOptTemps.isEmpty()) {
                ratingModifierWrap.pickOptList.addAll(picklistOptTemps);
                for(PicklistOption option : picklistOptTemps){
                    if(option.value == 'Default' && String.isBlank(ratingModifier.Rating_Modifier_Value__c)){
                        ratingModifier.Rating_Modifier_Value__c = 'Default';
                        break;
                    }
                }
            }
        }
        // When Modifier Format is Percentage
        else if(ratingModifier.Format__c == 'Percentage') {
            ratingModifierWrap.ratingModfPercent = String.isBlank(ratingModifier.Rating_Modifier_Value__c) 
                                                     ? null : Decimal.valueOf(ratingModifier.Rating_Modifier_Value__c);
        }
        else if(ratingModifier.Format__c == 'Currency') {
            ratingModifierWrap.ratingModfCurrency = String.isBlank(ratingModifier.Rating_Modifier_Value__c) 
                                                     ? null : Decimal.valueOf(ratingModifier.Rating_Modifier_Value__c);
        }
        else if(ratingModifier.Format__c == 'Integer') {
            ratingModifierWrap.ratingModfInteger = String.isBlank(ratingModifier.Rating_Modifier_Value__c) 
                                                     ? null : Integer.valueOf(ratingModifier.Rating_Modifier_Value__c);
        }
        else if(ratingModifier.Format__c == 'Number') {
            ratingModifierWrap.ratingModfNumber = String.isBlank(ratingModifier.Rating_Modifier_Value__c) 
                                                     ? null : Decimal.valueOf(ratingModifier.Rating_Modifier_Value__c);
        }
        else if(ratingModifier.Format__c == 'Text') {
            ratingModifierWrap.ratingModfStr = ratingModifier.Rating_Modifier_Value__c;
        }
        // If the Factor Min, Factor Max and Factor Default is null and Format is Percentage or Picklist 
        // Range and Default field labels on the lighting page.
        if((ratingModifier.Format__c == 'Percentage' || ratingModifier.Format__c == 'Picklist' || ratingModifier.Format__c == 'Radio Button'))
        {
            ratingModifierWrap.isShowRangeDefault = true;
            ratingModifierWrap.isShowFactorValue = true;
        }

        // If the Factor Min, Factor Max and Factor Default is null and Format is Picklist
        // do not show the Factor Value
        if(ratingModifier.Format__c == 'Picklist' || ratingModifier.Format__c == 'Radio Button'){
            SelectedOptionWrapper selOptWrap = new SelectedOptionWrapper();
            selOptWrap.selectedOpt = ratingModifier.Rating_Modifier_Value__c;
            ratingModifierWrap.selectedOptWrap = selOptWrap;
        }

        if(ratingModifier.Display_Format__c == FACTOR_VALUES_ONLY){
            ratingModifierWrap.isShowRatingModifierValue = false;
        }
        if(ratingModifier.Profile_Name_for_Read_Only__c != null){
            if(ratingModifier.Profile_Name_for_Read_Only__c == 'All'){
                ratingModifierWrap.isReadOnly = true;
            }else{
                ratingModifierWrap.isReadOnly = ratingModifier.Profile_Name_for_Read_Only__c.contains(currentProflieName) ? true : false;
            }
        }
        
        /* These Rating Modifiers should be able to be edited until the Opportunity is Closed Won. (i.e. Quote is Bound) 
            This only applies to Rating Modifiers AND Factor Values Only with Display Format = Modifier and Factor Values */
        // if(ratingModifier.Display_Format__c == MODIFIER_AND_FACTOR_VALUES 
        //     || ratingModifier.Display_Format__c == FACTOR_VALUES_ONLY) {
        
            if(ratingModifier.Opportunity__r.StageName == 'Closed Won' || ratingModifier.Opportunity__r.StageName == 'Declined') {
                ratingModifierWrap.isReadOnly = true;
            }
            else {
                if(!ratingModifierWrap.isReadOnly) // 08/25/2020 - Hang Lam - Defect 27641
                    ratingModifierWrap.isReadOnly = getReadonlyWithQuoteStatusBound(ratingModifier.Opportunity__c);
            }
        // }

        // Eligibility Section
        // if(ratingModifier.Page_Section__c.contains(Label.ELIGIBILITY_SECTION_HEADER)) {
            
        // } else {
            
        //     if(ratingModifier.Name == Label.ANNUAL_REVENUES 
        //         || ratingModifier.Name == Label.INDUSTRY_RISK_CLASSIFICATION) {
        //         if(String.isNotBlank(ratingModifier.Rating_Modifier_Value__c)) {
        //             ratingModifierWrap.isReadOnly = true;
        //         }
        //     }
        // }
        String inputClass = 'inputCmp';
        ratingModifierWrap.inputClass = ratingModifier.Is_Required__c ? inputClass + ' required-field' : inputClass;
        
        return ratingModifierWrap;
    }

    /*************************************************
    * Author: Duc Pham
    * Date: 19-August-2020
    * Params: opportunityId - opportunity Id  
    * Return: readonly
    * Description: get readonly
    * Revision: 
    *************************************************/
    private static Boolean getReadonlyWithQuoteStatusBound(String opportunityId){
        List<Quote> lockedQuotes =  [SELECT Id, Name, Status, Rating_Status__c
											FROM Quote
											WHERE OpportunityId = :opportunityId
    										AND Opportunity.Type != 'Full Amendment'
                                            AND (Status = 'Bound')];
        return lockedQuotes.size() > 0;
    }

    /*************************************************
    * Author: Hang Lam
    * Date: 07-April-2020
    * Params: productName - product name
              opportunityId - opportunity Id  
    * Return: ratingMods - List Rating_Modifiers__c
    * Description: get Primary Modifiers
    * Revision: 
    *************************************************/
    private static List<Rating_Modifiers__c> getEligibilityRatingModifiers(String productName, String opportunityId) {
        // fetch Rating Modifiers based on Product Name List 
        // show only Display format are Primary Modifiers, Secondary Modifiers and Pros and Cons
        List<String> displayFormatList = new List<String>{'Primary Modifiers', 'Secondary Modifiers', 'Pros and Cons'};
        if(mapProductPageSection.get(productName) != null) displayFormatList = mapProductPageSection.get(productName);
        List<Rating_Modifiers__c> ratingMods = [Select Id,Azure_ID__c,Name,Profile_Name_for_Read_Only__c,   
                                                            Format__c,Rating_Modifier_Code__c , Is_Required__c,Factor_Max__c,
                                                            Page_Section__c,Picklist_Values__c,Sub_Section__c,Factor_Min__c,
                                                            Product__c, Rating_Modifier_Value__c, SME_Question__c,     
                                                            Eligibility_Status__c,Eligibility_Weighting_Factor__c,
                                                            Opportunity__c, Opportunity__r.StageName,Display_Format__c,
                                                            Opportunity__r.SyncedQuote.Status,Opportunity__r.Type
                                                    From Rating_Modifiers__c Where 
                                                    Opportunity__c =: opportunityId
                                                    And Display_Format__c IN: displayFormatList
                                                	And Page_Section__c != Null
                                                    Order By Product__c ASC, Order_of_Page_Section__c ASC, Page_Section__c ASC, Sort_Order__c ASC,Sort_Sub_Section__c ASC];
       system.debug('ratingMods '+ratingMods);
        return ratingMods;
    }

    /*************************************************
    * Author: Hang Lam
    * Date: 07-April-2020
    * Params: strPicklistOpt - value of Picklist
    * Return: picklistOpts - List PicklistOption
    * Description: get picklist values
    * Revision: 
    *************************************************/
    private static List<PicklistOption> createPicklistOptionValues(String strPicklistOpt) {
        List<PicklistOption> picklistOpts = new List<PicklistOption>();
        if(String.isBlank(strPicklistOpt)) return picklistOpts;
 
        // check String picklist opt does not contain 'None' and not first string
        // if(strPicklistOpt.trim().toLowerCase().indexOf('none') != 0) {
        //     picklistOpts.add(new PicklistOption('', 'None'));
        // }

        List<String> strSplits = strPicklistOpt.split(';');
        for(String str : strSplits) {
            if(String.isNotBlank(str)){
                str = str.trim();
                str = str.replace('\r\n', '');
                str = str.replace('\n', '');
                str = str.replace('\r', '');

                if(str.toLowerCase() == 'none') picklistOpts.add(new PicklistOption('none', str));
                else {
                    PicklistOption option = new PicklistOption(str, str);
                    if(str == 'Default') option.isSelected = true;
                    picklistOpts.add(option);
                }
            }
        }

        return picklistOpts;
    }

    @AuraEnabled
    public static String updateStageAndPopulateFieldsLwc(String opportunityId){
        String quoteProcessId = null;
        try{
            List<Opportunity> opportunities = [SELECT Id,StageName,Eligibility_Approver__c,Eligibility_Approval_Date_Time__c,Product_Name__c	
            FROM Opportunity WHERE Id =: opportunityId];
            if(opportunities.isEmpty()) return null;

            opportunities[0].StageName = QUOTE_STATUS_QUALIFIED;
            opportunities[0].Eligibility_Approver__c = UserInfo.getUserId();
            opportunities[0].Eligibility_Approval_Date_Time__c = System.now();

            List<Quote_Process__c> listQuoteProcess = [SELECT Id,Status__c From Quote_Process__c WHERE Submission__c =: opportunityId];
            for (Quote_Process__c quoteProcess : listQuoteProcess) {
                quoteProcess.Status__c = QUOTE_PROCESS_STATUS_COMPARE_RATE_QUOTES;
                if(opportunities[0].Product_Name__c == System.Label.Product_Name_for_PCC || opportunities[0].Product_Name__c == System.Label.Product_Name_for_Professional_Indemnity){
                    quoteProcess.Status__c = QUOTE_PROCESS_STATUS_QUOTE_VERSION_CONSOLE;
                }
            }
            // Compare & Rate Quotes
            if(!listQuoteProcess.isEmpty()) {
                update listQuoteProcess;
                quoteProcessId = listQuoteProcess[0].Id;
            }
        
            update opportunities;
            return quoteProcessId;

        }catch(Exception e){
            System.debug('@@@ Proceed to Quote Err '+ e.getMessage());
        }
        return quoteProcessId;
    }
    //This method checks if Opp State is in Restricted list for creating Primary Quote 
    public static boolean isPrimaryQuoteAllowedForOppState(Opportunity opp ){
        Boolean isAllowed = true;
        if( Opp.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PCC ){
            Product_Setting__mdt mdtSetting = [Select Id,States_Restricted_For_Primary_Quote__c from Product_Setting__mdt where MasterLabel = :GlobalVariables.PROD_NAME_FOR_PCC ];
            if( String.isNotBlank( mdtSetting.States_Restricted_For_Primary_Quote__c) ){
                list<String> restrictedStatesForPrimaryQuote = mdtSetting.States_Restricted_For_Primary_Quote__c.split(',');
                //new list<String>{'VT','VA','CA','AK','HI'};
                if( restrictedStatesForPrimaryQuote.contains( opp.Account.BillingStateCode) ){
                    isAllowed = false;
                }
            }
        }
        return isAllowed;
    }
    @AuraEnabled
    public static ResultResponse checkProceedtoQuote(String opportunityId){
        ResultResponse rp = new ResultResponse();
        try{
            
            List<Broker_account__c> brokerAccounts = [SELECT Id, IsPrimaryBroker__c, Broker_Contact__c, Broker_Contact__r.AccountId
            FROM Broker_Account__c  WHERE IsPrimaryBroker__c = true
            AND Opportunity__c = :OpportunityId];

            List<Rating_Modifiers__c> ratingModifiers = [SELECT Id, Name, Rating_Modifier_Value__c  FROM Rating_Modifiers__c 
                    WHERE Opportunity__c =: OpportunityId AND (Name = 'Annual Revenues' OR Name = 'Next Year Revenue')];

            List<Opportunity> opportunities = [SELECT Id,StageName,Product_Name__c,Eligibility_Approver__c,Eligibility_Approval_Date_Time__c,Account_Clearance__c,AnnualRevenue__c,
                                                Account.BillingStateCode
                                                FROM Opportunity WHERE Id =: opportunityId];

            //check if Opp state is restricted
            Boolean isOppStateAllowed = isPrimaryQuoteAllowedForOppState(opportunities[0]);
            rp.data = '{"isOppStateAllowed": '+isOppStateAllowed+'}';

            if(brokerAccounts.isEmpty()){
                rp.errors.add('Primary broker is required');
            }
            if(opportunities[0].Product_Name__c.contains('MPL')){
                if( ratingModifiers.isEmpty() || ratingModifiers[0].Rating_Modifier_Value__c == null  ){
                    rp.errors.add('Annual Revenue is required');
                }
            }
            //Check required NextYearRevenue
            if(opportunities[0].Product_Name__c.contains('Cyber')){
                if( ratingModifiers.isEmpty() || ratingModifiers[0].Rating_Modifier_Value__c == null  ){
                    rp.errors.add('Next Year Revenue is required');
                }
            }
            if(opportunities[0].Product_Name__c == 'Professional Indemnity'){
                
            }else if(opportunities[0].Account_Clearance__c != 'Cleared' && opportunities[0].Product_Name__c != 'Private Company Combo' ){
                rp.errors.add('Account Clearance must be Cleared');
            }
            if(rp.errors.isEmpty()){
                rp.isSuccess = true;
            }
            return rp;
        }catch(Exception e){
            System.debug('@@@ Check Proceed to Quote Error '+ e.getMessage() +e.getLineNumber() + e.getStackTraceString());
            return rp;
        }
    }

    /***   For Ticket 54090 *******/
    @AuraEnabled
    public static Quote getBinderDetail(String quoteId){
          return  [select id,Master_Binder__c from Quote where id=:quoteId];
      
    }

    public class TabItem {
        @AuraEnabled public List<String> activeSections {get; set;}
        @AuraEnabled public List<MainSection> mainSections {get; set;}
        @AuraEnabled public Boolean isReadonly {get; set;}

        public TabItem() {
            activeSections = new List<String>();
            mainSections = new List<MainSection>();
            isReadonly = false;
        }
    }

    public virtual class SectionItem {
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public List<ItemWrapper> items {get; set;}
    }

    public class MainSection extends SectionItem {
        @AuraEnabled public List<SubSection> subSections {get; set;}
        @AuraEnabled public List<String> subActiveSections {get; set;}
        @AuraEnabled public Boolean isActiveSection {get; set;}
        public MainSection() {
            this.name = '';
            this.subSections = new List<SubSection>();
            this.items = new List<ItemWrapper>();
            this.subActiveSections = new List<String>();
            this.isActiveSection = false;
        }

        public MainSection(String mainSectionName) {
            this.name = mainSectionName;
            this.subSections = new List<SubSection>();
            this.items = new List<ItemWrapper>();
            this.subActiveSections = new List<String>();
        }
    }

    public class SubSection extends SectionItem {
        public SubSection() {
            this.name = '';
            this.items = new List<ItemWrapper>();
        }

        public SubSection(String subSectionName) {
            this.name = subSectionName;
            this.items = new List<ItemWrapper>();
        }
    }

    public class ItemWrapper{
    	@AuraEnabled public List<PicklistOption> pickOptList {get; set;}
        @AuraEnabled public Rating_Modifiers__c item {get; set;}

        @AuraEnabled public Boolean isShowRangeDefault {get; set;}
        @AuraEnabled public Boolean isShowFactorValue {get; set;}
        @AuraEnabled public Boolean isShowRatingModifierValue {get; set;}

        @AuraEnabled public Decimal ratingModfPercent {get; set;}
        @AuraEnabled public Decimal ratingModfCurrency {get; set;}
        @AuraEnabled public Integer ratingModfInteger {get; set;}
        @AuraEnabled public Decimal ratingModfNumber {get; set;}
        @AuraEnabled public String ratingModfStr {get; set;}

        @AuraEnabled public String strFactorMax {get; set;}
        @AuraEnabled public String strFactorMin {get; set;}
        @AuraEnabled public SelectedOptionWrapper selectedOptWrap {get; set;}
        @AuraEnabled public Boolean isReadOnly {get; set;}
        @AuraEnabled public Boolean isRequired {get; set;} //Giangphan 13/jul/2020
        @AuraEnabled public String inputClass {get; set;}
        
        public ItemWrapper() {
            this.pickOptList = new List<PicklistOption>();
            this.item = new Rating_Modifiers__c();
            this.isShowRangeDefault = false;
            this.isShowFactorValue = false;
            this.isShowRatingModifierValue = true;
            this.ratingModfPercent = null;
            this.ratingModfCurrency = null;
            this.ratingModfInteger = null;
            this.ratingModfNumber = null;
            this.strFactorMax = '';
            this.strFactorMin = '';
            this.ratingModfStr = null;
            this.selectedOptWrap = new SelectedOptionWrapper();
            this.isReadOnly = false;
            this.isRequired = false;
        }
    }

    public class SelectedOptionWrapper{
        @AuraEnabled public String selectedOpt {get; set;}
        //@AuraEnabled public Decimal Factor_Default_Value {get; set;}
        @AuraEnabled public Decimal Factor_Max {get; set;}
        @AuraEnabled public Decimal Factor_Min {get; set;}
        @AuraEnabled public Decimal Factor_Value {get; set;}
        public SelectedOptionWrapper() {
            selectedOpt = '';
            //Factor_Default_Value = null;
            Factor_Max = null;
            Factor_Min = null;
            Factor_Value = null;
        }
    }
    public class OpportunityWrapper{
        @AuraEnabled public Boolean isPrimaryButtonDisabled {get; set;}
        @AuraEnabled public Boolean isExcessButtonDisabled {get; set;}
        @AuraEnabled public Boolean disableSplitSection {get; set;}
        @AuraEnabled public String previousAnnualTurnover {get; set;}
        @AuraEnabled public String previousRateableExposure {get; set;}
        @AuraEnabled public List<Quote> quoteList {get; set;}
        @AuraEnabled public Opportunity submissionDetails {get; set;}
    }
    @AuraEnabled
    public static OpportunityWrapper getSubmissionDetails(String opportunityId) {
        Opportunity opp = new Opportunity();
        OpportunityWrapper wrapper = new OpportunityWrapper();
        try{
            opp = [Select Id,StageName,Product_Name__c,Type,Effective_Date__c,Expiration_Date__c,Parent_Opportunity__c,RecordTypeId,
                   (Select Id,Name,Layer__c,Quote_Type__c,Status from Quotes) from Opportunity where 
                   Id =: opportunityId];
            List<Rating_Modifiers__c> parentSubmissionRatingModifiers = getEligibilityRatingModifiers(opp.Product_Name__c,opp.Parent_Opportunity__c);
            if(parentSubmissionRatingModifiers.size() > 0){
                for(Rating_Modifiers__c ratingModifier : parentSubmissionRatingModifiers){
                    if(ratingModifier.Name == 'Annual gross fees / turnover'){
                        wrapper.previousAnnualTurnover = ratingModifier.Rating_Modifier_Value__c;                       
                    }
                    if(ratingModifier.Name == 'Rateable Exposure'){
                        wrapper.previousRateableExposure = ratingModifier.Rating_Modifier_Value__c;                       
                    }
                }
            }
            wrapper.submissionDetails = opp;
            wrapper.quoteList = opp.Quotes;
            for(Quote quoteObj : opp.Quotes){
                String quoteType = quoteObj.Quote_Type__c;
                String quoteStatus = quoteObj.Status;
                String quoteLayer = quoteObj.Layer__c;
                if(quoteStatus == 'Bound'){
                    wrapper.disableSplitSection = true;
                }
                
                if ((quoteType == 'New Business' && quoteStatus == 'Bound' && quoteLayer == 'Primary') || (quoteType == 'Renewal' && quoteStatus == 'Bound' && quoteLayer == 'Primary')) {
                    wrapper.isPrimaryButtonDisabled = true;
                }else if ((quoteType == 'New Business' && quoteStatus == 'Bound' && quoteLayer == 'Excess') || (quoteType == 'Renewal' && quoteStatus == 'Bound' && quoteLayer == 'Excess')) {
                    wrapper.isExcessButtonDisabled = true;
                }else if (quoteType != 'New Business' && quoteType != 'Renewal') {
                    wrapper.isPrimaryButtonDisabled = true;
                    wrapper.isExcessButtonDisabled = true;
                }				
            }	
            if(opp.StageName == 'Declined'){
                wrapper.isPrimaryButtonDisabled = true;
                wrapper.isExcessButtonDisabled = true;
            } 
        }catch (Exception ex) {
            throw new AuraHandledException(CommonUtil.getExceptionMessage(ex)); 
        }  
        return wrapper;
    }
}