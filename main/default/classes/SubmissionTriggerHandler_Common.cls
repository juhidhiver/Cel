/**************************************************************************************************
 * Class Name: SubmissionTriggerHandler_Common
 * Author: 
 * Date: 
 * Description: Class to keep common methods
 * Test Class : SubmissionTriggerHandler_Common
 **************************************************************************************************/
public with sharing class SubmissionTriggerHandler_Common {
    public static final String DEFAULT_SUBMISSION_NAME_FOR_PCC = System.Label.DEFAULT_SUBMISSION_NAME_PCC; 

    /*************************************************
    * Method Name: updateDnbInfoFromAccount
    * Author: 
    * Date: 
    * Params: List<Opportunity> newOpportunityList
    * Return: 
    * Exceptions:
    * Description: Update data on submission fetched from account.
    * Revision: 
     *************************************************/
    public static void updateDnbInfoFromAccount(List<Opportunity> newOpportunityList){
        Map<Id,Account> mapAccount = new Map<Id, Account>();
        Set<String> accIds = new Set<String>();
        for(Opportunity opp: newOpportunityList){
            accIds.add(opp.AccountId);
        }
        for(Account acc : AccountQueryUtil.fetchAccountsById(accIds))
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
    * Method Name: generateOpportunityName
    * Author: 
    * Date: 
    * Params: List<Opportunity> opportunitiesNew
    * Return: 
    * Exceptions:
    * Description: Generate Opportunity Name
    * Revision: 
     *************************************************/
    public static void generateOpportunityName(List<Opportunity> opportunitiesNew, Map<Id, Opportunity> oldDataMap){
        Map<Id, String> accountIdbyOpptMaps = new Map<Id, String>();
        Map<Id, Id> productIdbyOpptMaps = new Map<Id, Id>();
        Map<id, Opportunity> newMapOpp = new Map<id, Opportunity>();
        String productName = '';
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Set<id> updatedAccOppIds = new Set<id>(); //Mary
        Set<String> oldAccIds = new Set<String>(); 
        Set<String> newAccIds = new Set<String>(); 
        
        list<Quote> quoteR  = new  list<Quote>();
        
        Set<String> combinedAccountIdsSet = new Set<String>();
        Set<String> setOfAccountIdsOpptMap = new Set<String>();
        
        for (Opportunity oppt : opportunitiesNew){
            if(oldDataMap == null || (oldDataMap != null && oldDataMap.get(oppt.Id) != null && oldDataMap.get(oppt.Id).AccountId != oppt.AccountId) ){
                if((oldDataMap != null && oldDataMap.get(oppt.Id) != null && oldDataMap.get(oppt.Id).AccountId != oppt.AccountId) && oppt.Innovisk_Entity_ID__c == 'Aqueous' 
                && (oppt.StageName == 'Closed Lost' || oppt.StageName == 'Closed Won'))
                {continue ;}
                oppsToUpdate.add(oppt);
                accountIdbyOpptMaps.put(oppt.Id, oppt.AccountId);
                productIdbyOpptMaps.put(oppt.Id, oppt.Product__c);
                
                /************ New Set Added by Navdeep***/
                setOfAccountIdsOpptMap.add(oppt.AccountId);
                
            }  
            
            if(oldDataMap != null && oldDataMap.get(oppt.Id) != null && oldDataMap.get(oppt.Id).AccountId != oppt.AccountId 
                    && oldDataMap.get(oppt.Id).Innovisk_Entity_ID__c == 'Aqueous')
            {
               updatedAccOppIds.add(oppt.id);
               oldAccIds.add(oldDataMap.get(oppt.id).AccountId);
               newMapOpp.put(oppt.id,oppt);

            }
        }
        combinedAccountIdsSet.addAll(oldAccIds);
        combinedAccountIdsSet.addAll(accountIdbyOpptMaps.values());
        
        Map<Id, Account> mapofAllAccounts = new Map<Id, Account>(AccountQueryUtil.fetchAccountsById(new Set<String>(combinedAccountIdsSet)));
           
        Map<Id, Account> mapAccountOld = new Map<Id,Account>();
        Map<Id, Account> mapAccount = new Map<Id,Account>();
        
        
        for(Id accId  : mapofAllAccounts.keySet()){
            
            if(oldAccIds.contains(accId)){
             mapAccountOld.put(accId,mapofAllAccounts.get(accId));   
            }
            if(setOfAccountIdsOpptMap.contains(accId)){
                mapAccount.put(accId,mapofAllAccounts.get(accId));
            }
        }
        
        /******************* Changes done By Navdeep *********************/
        //    Map<Id, Account> mapAccountOld = new Map<Id, Account>(AccountQueryUtil.fetchAccountsById(new Set<String>(oldAccIds)));
       // Map<Id, Account> mapAccount = new Map<Id, Account>(AccountQueryUtil.fetchAccountsById(new Set<String>(accountIdbyOpptMaps.values())));
        
        
        //'Bound','Rejected','Closed','Correction','Cancelled'
        if(updatedAccOppIds.size() > 0)
        {
           
              /** Commented by Navdeep CD-133 ***/
             //List<Quote> oppRelatedQuotes = QuoteQueryUtil.fetchQuotesByOpportunties(updatedAccOppIds);
             
             
            List<Quote> oppRelatedQuotes =  [SELECT Id, Status,Layer__c, OpportunityId ,Opportunity.CreatedDate,AccountId, Name ,Broker__c,Product_Name__c, Broker_Email__c 
                                             FROM Quote WHERE OpportunityId IN : updatedAccOppIds order by Createddate asc];
            
            Map<String,Integer> countOfQuotes = new Map<String,Integer>();
            for(Quote q : oppRelatedQuotes)
            {
                //New IF else added by Navdeep based on CD-133
                if(!countOfQuotes.containsKey(q.Layer__c)){
                    countOfQuotes.put(q.Layer__c,1);
                }
                else{
                   countOfQuotes.put(q.Layer__c,countOfQuotes.get(q.Layer__c)+1); 
                }
                
                String oldName =  mapAccountOld.containskey(q.AccountId) ? mapAccountOld.get(q.AccountId).Name : '';
                String newName =  mapAccount.get(newMapOpp.get(q.OpportunityId).AccountId).Name;
                
                
                if(q.Status != 'Bound' && q.Status != 'Rejected' && q.Status != 'Closed' && q.Status != 'Correction' && q.Status != 'Cancelled' )
                {
                    
                    
                    if(q.Layer__c=='Primary'){
                        q.Name = newName+' '+ q.Opportunity.CreatedDate.format('dd/MM/yyyy')+' Primary '+countOfQuotes.get(q.Layer__c);
                     }
                    else{
                        q.Name = newName+' '+q.Opportunity.CreatedDate.format('dd/MM/yyyy')+' Excess '+countOfQuotes.get(q.Layer__c);
                    }
                    
                   // q.Name = q.Name.replace(oldName, newName);
                    quoteR.add(q);   
                }
                
            }
        }
        TriggerHandler.bypass('QuoteTriggerBaseHandler'); 
        if(quoteR.size()>0)update quoteR;
        TriggerHandler.clearBypass('QuoteTriggerBaseHandler');
        
        
        
        // get Map of Account
      
        // get Map of Product
        Map<Id, Product2> mapProduct = new Map<Id, Product2>(ProductQueryUtil.fetchProductsByIds(new Set<Id>(productIdbyOpptMaps.values())));
        for (Opportunity oppt : oppsToUpdate){
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
            //query all quote for the submission
            //bypass quote trigger on Upadate
            // reset 
        }
    }


    /*************************************************
    * Method Name: updateExpirationDate
    * Author: 
    * Date: 
    * Params: List<Opportunity> newList, Map<Id, Opportunity> oldMap
    * Return: 
    * Exceptions:
    * Description: update submission expiration date.
    * Revision: 
     *************************************************/
    public static void updateExpirationDate(List<Opportunity> newDataList, Map<Id, Opportunity> oldDataMap){
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
    * Method Name: accountClearancetoStagechange
    * Author: 
    * Date: 
    * Params: List<Opportunity> oppsListNew
    * Return: 
    * Exceptions:
    * Description: update submission stage based on account clearence
    * Revision: 
     *************************************************/
    public static void accountClearancetoStagechange(List<Opportunity> oppsListNew){
        for(Opportunity opp : oppsListNew){
            if(opp.Account_Clearance__c == 'Closed Market' && opp.StageName != 'Declined'){
                opp.StageName = 'New';
            }
        }
    }

    /*************************************************
    * Method Name: createNewDataMap
    * Author: 
    * Date: 
    * Params: List<Opportunity> newDataList
    * Return: 
    * Exceptions:
    * Description: Create submission map querying related object fields.
    * Revision: 
     *************************************************/
    public static Map<Id, Opportunity> createNewDataMap(List<Opportunity> newDataList){
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity item : newDataList){
            oppIds.add(item.Id);
        }
        return new Map<Id, Opportunity>(OpportunityQueryUtil.fetchOpportunityByIds(oppIds));
    }

    /*************************************************
    * Method Name: AddRatingModifier
    * Author: 
    * Date: 
    * Params: List<Opportunity> opps
    * Return: 
    * Exceptions:
    * Description: Generate Rating Modifiers for Submission
    * Revision: 
     *************************************************/
    public static void AddRatingModifier(List<Opportunity> opps){
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

    /*************************************************
    * Method Name: getAllProductOptions
    * Author: 
    * Date: 
    * Params: List<Opportunity> items
    * Return: 
    * Exceptions:
    * Description: Get all submission products
    * Revision: 
     *************************************************/
    public static List<String> getAllProductOptions(List<Opportunity> items){
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
    * Method Name: getAllProductOptions
    * Author: 
    * Date: 
    * Params: List<Rating_Modifiers__c> items
    * Return: 
    * Exceptions:
    * Description: get Submission products
    * Revision: 
     *************************************************/
    public static List<String> getAllProductOptions(List<Rating_Modifiers__c> items){
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
    * Method Name: generateTemplateMap
    * Author: 
    * Date: 
    * Params: List<Rating_Modifier_Template__c> items
    * Return: 
    * Exceptions:
    * Description: Generate Submission Rating Modifier Template Map
    * Revision: 
     *************************************************/
    public static Map<String, List<Rating_Modifier_Template__c>> generateTemplateMap(List<Rating_Modifier_Template__c> items){
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
    * Method Name: generateModifiersForInsert
    * Author: 
    * Date: 
    * Params: Map<String, List<Rating_Modifier_Template__c>> templateMap, List<Opportunity> items
    * Return: 
    * Exceptions:
    * Description: Generate Rating Modifiers
    * Revision: 
     *************************************************/
    public static List<Rating_Modifiers__c> generateModifiersForInsert(Map<String, List<Rating_Modifier_Template__c>> templateMap, List<Opportunity> items){
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
    * Method Name: generateOppMap
    * Author: 
    * Date: 
    * Params: List<Opportunity> items
    * Return: 
    * Exceptions:
    * Description: Generate Submission Id map.
    * Revision: 
     *************************************************/
    public static Map<String, Opportunity> generateOppMap(List<Opportunity> items){
        Map<String, Opportunity> result = new Map<String, Opportunity>();
        if (items.isEmpty())
            return result;
        for (Opportunity item : items){
            result.put(item.Id, item);
        }
        return result;
    }
    
    /*************************************************
    * Method Name: getProductOptions
    * Author: 
    * Date: 
    * Params: Opportunity item
    * Return: 
    * Exceptions:
    * Description: Get Submission Products
    * Revision: 
     *************************************************/
    private static List<String> getProductOptions(Opportunity item){
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
    * Method Name: getTemplateByOpportunity
    * Author: 
    * Date: 
    * Params: Map<String, List<Rating_Modifier_Template__c>> templates, Opportunity opp
    * Return: 
    * Exceptions:
    * Description: Get Submission Rating Modifier Temaplates
    * Revision: 
     *************************************************/
    private static List<Rating_Modifier_Template__c> getTemplateByOpportunity(Map<String, List<Rating_Modifier_Template__c>> templates, Opportunity opp){
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
    * Method Name: generateRatingModifier
    * Author: 
    * Date: 
    * Params: List<Rating_Modifier_Template__c> templates, Opportunity oppt
    * Return: 
    * Exceptions:
    * Description: Generate Rating Modifiers for Submission
    * Revision: 
     *************************************************/
    public static List<Rating_Modifiers__c> generateRatingModifier(List<Rating_Modifier_Template__c> templates, Opportunity oppt){
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
            //**This query is in a loop !!!!!! */
            for(Rating_Modifiers__c ratingMod: RatingModifierQueryUtil.fetchRatingModifiersByOpportunity(oppt.Parent_Opportunity__c)){
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
    * Method Name: createQuoteProcess
    * Author: 
    * Date: 
    * Params: List<Opportunity> newList
    * Return: 
    * Exceptions:
    * Description: Create Submission linked Quote Process(UW Workbench) record if not exists.
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
            //added if condition by Yogesh Mandlik on 07/09/22 for 58961
            if(opp.Product_Name__c == 'Private Company Combo'){
                
                newQuoteProcessList.add(new Quote_Process__c(Submission__c = opp.Id,Product__c = opp.Product_Name__c, Account__c = opp.AccountId, Status__c = 'Submission Console', Record_Type__c = opp.Innovisk_Entity_ID__c ));
            }
            else{newQuoteProcessList.add(new Quote_Process__c(Submission__c = opp.Id,Product__c = opp.Product_Name__c, Account__c = opp.AccountId, Status__c = 'Submission Info', Record_Type__c = opp.Innovisk_Entity_ID__c ));
            }
        }
        insert newQuoteProcessList;
    }
    
    /*************************************************
    * Method Name: addSubmissionLostDetail
    * Author: 
    * Date: 
    * Params: Map<Id, Opportunity> newDataMap
    * Return: 
    * Exceptions:
    * Description: Generate Submssion loss detail record for Submission
    * Revision: 
     *************************************************/
    public static void addSubmissionLostDetail(Map<Id, Opportunity> newDataMap){
        List<Opportunity> listOpps = OpportunityQueryUtil.fetchOpportunityByIds(newDataMap.keySet());
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : listOpps)
            accountIds.add(opp.AccountId);
        
        List<Submission_Loss_Detail__c> listSubmissionLoss = new List<Submission_Loss_Detail__c>();
        for(Account_Loss_Detail__c accLoss : AccountLossDetailQueryUtil.fetchAccountLossDetailsByAccountId(accountIds)) 
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
    * Method Name: updateServiceClassificationRattingModifiers
    * Author: 
    * Date: 
    * Params: Map<Id,Opportunity> newMap,Map<Id,Opportunity> oldMap
    * Return: 
    * Exceptions:
    * Description: Update submission rating modifiers for 'Service Classification' 
    * Revision: 
     *************************************************/
    public static void updateServiceClassificationRattingModifiers(Map<Id,Opportunity> newMap,Map<Id,Opportunity> oldMap ){
        List<Rating_Modifiers__c> updateItems = new List<Rating_Modifiers__c>();
        System.debug('ratingModifiersList');
        List<Rating_Modifiers__c> ratingModifiersList = RatingModifierQueryUtil.fetchRatingModifiersByOpportunityForServiceClassification(newMap.keySet());
        System.debug('ratingModifiersList'+ratingModifiersList);
        //Giang added 21/Jul/2020
        Map<String, String> eligibilityStatusMap = new Map<String,String>();
        for(Eligibility_Status__c eliStatus: EligibilityStatusQueryUtil.fetchELStatusForServiceClassification()) 
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
    * Method Name: stageUnqualifiedCloseAllQuote
    * Author: 
    * Date: 
    * Params: List<Opportunity> oppListNew, Map<Id,Opportunity> oppMapOld
    * Return: 
    * Exceptions:
    * Description: Close submission quotes if unqualified.
    * Revision: 
     *************************************************/
    public static void stageUnqualifiedCloseAllQuote(List<Opportunity> oppListNew, Map<Id,Opportunity> oppMapOld){
        List<Quote> quotes = QuoteQueryUtil.fetchQuotesByOpportunties(oppMapOld.keySet()); 
        List<Quote_Process__c> quoteProcesses = QuoteProcessQueryUtil.fetchQPForSubmissions(oppMapOld.keySet());
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
                //Check logic for this?
                for(Quote_Process__c qp: quoteProcesses){
                    if(qp.Submission__c == opp.Id){
                        qp.Status__c = 'Submission Console'; //Changed to Submission Console from Submission Info
                        updateProcess.add(qp);
                    }
                }
            }
        }
        if(!updateQuotes.isEmpty())	 update updateQuotes;
        if(!updateProcess.isEmpty()) update updateProcess;
    }
    

    /*************************************************
    * Method Name: deleteQuoteProcess
    * Author: 
    * Date: 
    * Params: Map<Id, Opportunity> oldDataMap
    * Return: 
    * Exceptions:
    * Description: Delete Submission lnked Quote Process record.
    * Revision: 
     *************************************************/
    public static void deleteQuoteProcess(Map<Id, Opportunity> oldDataMap){
        List<Quote_Process__c> qp = QuoteProcessQueryUtil.fetchQPForSubmissions(oldDataMap.keySet());
        if(!qp.isEmpty()) {
            delete qp;
        }
    }

    /*************************************************
    * Method Name: UpdateRelatedQuoteStatusAQ
    * Author: Mary Elizabeth
    * Date: 30-03-22
    * Params: List<Opportunity> OppListNew
    * Return: 
    * Exceptions:
    * Description: update status of quotes related to submission
    * Revision: 
     *************************************************/
    public static void updateOpenQuoteForDeclinedSub(List<Opportunity> OppListNew)
    {
        Map<id, String> mapOfOppIdVsStatus = new Map<Id, String>();
        List<Quote> listQuotesToBeUpdated = new List<Quote>();

        //Iterating after update opportunity records and chechking the stage , status and loss reason
        for(Opportunity opp : OppListNew ) 
        {
            if(opp.StageName == 'Closed Lost' && opp.Submission_Status__c == 'Declined' && opp.Loss_Reason__c == 'Sanctioned Entity')
            {
                mapOfOppIdVsStatus.put(opp.Id, 'FailedSanction');
            }
        }
        //Querying the records which satisfies the above condition and changing related record status value to closed
        List<Opportunity> Opplist = OpportunityQueryUtil.fetchSubmissionsWithRelatedQuotes(mapOfOppIdVsStatus.keySet());
        if(OppList.size() > 0 ){
            for(Opportunity opp : Opplist){
                if(opp.Quotes != null ){
                    for(Quote objQuote : opp.Quotes){
                        if(objQuote.Status == 'In Progress' || objQuote.Status == 'Rated' || objQuote.Status == 'Referred' || objQuote.Status == 'Quoted'){
                            objQuote.Status='Closed';
                            objQuote.Closed_Reason__c = opp.Loss_Reason__c;
                            listQuotesToBeUpdated.add(objQuote);
                        }
                    }
                }
            }
        }

        if(!listQuotesToBeUpdated.isEmpty()){
            GlobalStaticVar.byPassQuoteTrigger = true;
            update listQuotesToBeUpdated;
            GlobalStaticVar.byPassQuoteTrigger = false;

        }
    }
}