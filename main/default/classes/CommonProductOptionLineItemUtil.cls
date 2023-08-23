/**************************************************************************************************
 * Class Name: CommonProductOptionLineItemUtil
 * Author: Vinay
 * Date: 16th Dec 2021
 * Description: Utility class for product option line items
 * Test Class : ProductOptionLineItemTriggerHandlerTest
 **************************************************************************************************/
public with sharing class CommonProductOptionLineItemUtil {
    private static List<Quote> quotesForStatusUpdate;
    /*************************************************
    * Method Name: updateRatingModifiersForOpps
    * Author:
    * Date: 
    * Params: List<Product_Option_Line_Item__c> newDataList 
    * Return: 
    * Exceptions: 
    * Description: Update rating modifiers for opportunities
    * Revision: 
    * Can be moved to Flows: No
     *************************************************/
    public static void updateRatingModifiersForOpps(List<Product_Option_Line_Item__c> newDataList){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(OpportunityQueryUtil.fetchOpportunityByIds(new Set<Id>{newDataList[0].Submission__c}));
        CommonUtil.updateRatingModifiersForOpps(oppMap, null);
    }

    /*************************************************
    * Method Name: deleteRatingModifiers
    * Author:
    * Date: 
    * Params: List<Product_Option_Line_Item__c> oldDataList 
    * Return: 
    * Exceptions: 
    * Description: Delete rating modifiers
    * Revision: 
    * Can be moved to Flows: No
     *************************************************/
    public static void deleteRatingModifiers(List<Product_Option_Line_Item__c> oldDataList){
        //List<Product_Option_Line_Item__c> currPoli = this.newDataList[0];
        Set<Id> prodIds = new Set<Id>();
        for(Product_Option_Line_Item__c p : oldDataList){
            prodIds.add(p.Product__c);
        }
        List<Product2> comboProds = ProductQueryUtil.fetchProductsByIds(prodIds);
        List<Rating_Modifiers__c> oppRatingModifiers = RatingModifierQueryUtil.fetchRatingModifiersByOpportunity(oldDataList[0].Submission__c);
        
        List<Rating_Modifiers__c> ratingModsToDelete = new List<Rating_Modifiers__c>();
        for(Product2 cProd : comboProds){
            for(Rating_Modifiers__c rm : oppRatingModifiers){
                if(rm.Product__c == cProd.Name){
                    ratingModsToDelete.add(rm);
                }               
            }
        }
        
        delete ratingModsToDelete;
    }

    /*************************************************
    * Method Name: existingPOLIValidation
    * Author:
    * Date: 
    * Params: List<Product_Option_Line_Item__c> newDataList 
    * Return: 
    * Exceptions: 
    * Description: Validation for existing POLIs.
    * Revision: 
    * Can be moved to Flows: No
     *************************************************/
    public static void existingPOLIValidation(List<Product_Option_Line_Item__c> newDataList){
        //Checking if Poli already exist for product in submission. Throw exception if true.
        Set<Id> prodIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        for (Product_Option_Line_Item__c poli : newDataList){
            if(poli.Product__c != null){
                prodIds.add(poli.Product__c);
            }
            if(poli.Submission__c != null){
                oppIds.add(poli.Submission__c);
            }
        }
        List<Product_Option_Line_Item__c> existingPoli = ProductOptionLineItemQueryUtil.fetchPOLIByProdsAndOpps(oppIds,prodIds);

        for (Product_Option_Line_Item__c poli : newDataList){
            for (Product_Option_Line_Item__c poli1 : existingPoli){
                if((poli.Submission__c == poli1.Submission__c) && (poli.Product__c == poli1.Product__c)){
                    poli.addError('Poli already exist for: ' + poli1.Product__r.Name);
                }
            }
        }
    }

    /*************************************************
    * Method Name: RatingModifiersValidate
    * Author: Vinay
    * Date: 
    * Params: List<Product_Option_Line_Item__c> newDataList, Map<Id, Product_Option_Line_Item__c> oldDataMap
    * Return: 
    * Exceptions: 
    * Description: Method to add rating modifiers for cleared POLI and delete rating modifiers when POLI status changed from cleared to any other status other than Decline.
    * Revision: Vinay for US 52811 
    * Can be moved to Flows: No
     *************************************************/
    public static void RatingModifiersValidate(List<Product_Option_Line_Item__c> newDataList, Map<Id, Product_Option_Line_Item__c> oldDataMap){
        quotesForStatusUpdate = new List<Quote>();
        //variable declarations
        Set<Id> prodIds = new Set<Id>();
        List<String> prodNames = new List<String>();
        Map<String, Product_Option_Line_Item__c> prodOptionsMap = new Map<String, Product_Option_Line_Item__c>();
        Map<String, String> prodNameMap = new Map<String, String>();
        Map<String, String> prodMap = new Map<String, String>();
        Set<Id> clearedSubmissionIDs = new Set<Id>();
        List<Product_Option_Line_Item__c> unClearedPOLIs = new List<Product_Option_Line_Item__c>();
        List<Product_Option_Line_Item__c> declinedPOLIs = new List<Product_Option_Line_Item__c>();
        List<Product_Option_Line_Item__c> prodOptionsToUpdate = new List<Product_Option_Line_Item__c>();
        for (Product_Option_Line_Item__c poli : newDataList){
            if(poli.Product__c != null){
                //check if clearance status is changer for updated records
                if(Trigger.isInsert || (Trigger.isUpdate && poli.Clearance_Status__c != oldDataMap.get(poli.id).Clearance_Status__c)){
                    if(poli.Clearance_Status__c == 'Cleared'){
                        clearedSubmissionIDs.add(poli.Submission__c);
                        prodOptionsToUpdate.add(poli);
                    }else if(poli.Clearance_Status__c == 'Decline' && oldDataMap != null && oldDataMap.get(poli.id).Clearance_Status__c == 'Cleared'){
                        declinedPOLIs.add(POLI);
                    }else{
                        unClearedPOLIs.add(poli);
                    }
                    prodIds.add(poli.Product__c);
                    prodOptionsMap.put(poli.Product__c, poli);
                }
            }
        }

        //fetch product names for product ids
        List<Product2> prodList = ProductQueryUtil.fetchProductsByIds(prodIds);
        
        //prepare map of product name and id
        for (Product2 prod : prodList){
            if(prodOptionsMap.get(prod.Id).Is_Selected__c){
                prodNames.add(prod.Name);
                prodNameMap.put(prod.Name, prod.Id);
            }             
            prodMap.put(prod.Id, prod.Name);
        }

        //Update all active prebound quotes to InProgress if newly cleared Poli available for qote.
        if(!prodOptionsToUpdate.isEmpty()){
            updateQuoteStatusForClearedPoli(clearedSubmissionIDs);
        }
        

        //delete all rating modifiers except clearance, coverage lines and rating modifier factors
        if(!declinedPOLIs.isEmpty())
            cleanupData(declinedPOLIs, prodMap, true);

        //delete all rating modifiers, coverage lines and rating modifier factors 
        if(!unClearedPOLIs.isEmpty())
            cleanupData(unClearedPOLIs, prodMap, false);

        if(!clearedSubmissionIDs.isEmpty()){
            //add quote premiums
            processQuotePremiums(prodOptionsToUpdate, prodMap);

            //clear old and add new rating modifiers
            AddRatingModifiers(prodOptionsToUpdate, clearedSubmissionIDs, newDataList);

            //fetch active quotes and create coverage lines and rating modifier factors
            List<Quote> activeQuotes = QuoteQueryUtil.fetchActiveQuotesOfOpportunities(clearedSubmissionIDs);

            if(!activeQuotes.isEmpty()){
                //generate rating modifier factors and coverage line items
                QuoteTriggerHandler_Common.processPoliCleanup(activeQuotes);
            }
        }

        if(!quotesForStatusUpdate.isEmpty()){
            TriggerHandler.bypass('QuoteTriggerBaseHandler');
            Set<Id> quoteIds = new Set<Id>();
            List<Quote> uniqueQuotes = new List<Quote>();
            for(Quote qt : quotesForStatusUpdate){
                if(!quoteIds.contains(qt.Id)){
                    quoteIds.add(qt.Id);
                    uniqueQuotes.add(qt);
                }
            }
            update uniqueQuotes;
            TriggerHandler.clearBypass('QuoteTriggerBaseHandler');
        }
    }

    /*************************************************
    * Method Name: processQuotePremiums
    * Author:
    * Date: 14th Dec 2021
    * Params: List<Product_Option_Line_Item__c> poliList, Map<String, String> prodMap
    * Return: 
    * Exceptions:
    * Description: To create quote premium for quotes when poli is marked as cleared
    * Revision: 
     *************************************************/
    private static void processQuotePremiums(List<Product_Option_Line_Item__c> poliList, Map<String, String> prodMap){
        Map<id, List<Product_Option_Line_Item__c>> poliBySubmission = new Map<id, List<Product_Option_Line_Item__c>>();
        List<Quote_Premium__c> quotePremiums = new List<Quote_Premium__c>();
        for(Product_Option_Line_Item__c poli : poliList){
            if(poliBySubmission.containsKey(poli.Submission__c))
                poliBySubmission.get(poli.Submission__c).add(poli);
            else
                poliBySubmission.put(poli.Submission__c, new List<Product_Option_Line_Item__c>{poli});
        }
        for(Quote qt : QuoteQueryUtil.fetchQuotesByOpportunties(poliBySubmission.keySet())){
            if(poliBySubmission.containsKey(qt.OpportunityId)){
                for(Product_Option_Line_Item__c poli : poliBySubmission.get(qt.OpportunityId)){
                    Quote_Premium__c quotePrem = new Quote_Premium__c();
                    quotePrem.Quote__c = qt.id;
                    quotePrem.Product_Name__c = prodMap.containsKey(poli.Product__c) ? prodMap.get(poli.Product__c) : null;
                    quotePremiums.add(quotePrem);
                }
            }
        }
        if(!quotePremiums.isEmpty()){
            insert quotePremiums;
        }
    }

    /*************************************************
    * Method Name: AddRatingModifiers
    * Author:
    * Date: 14th Dec 2021
    * Params: List<Product_Option_Line_Item__c> poliList, Set<Id> clearedSubmissionIDs, List<Product_Option_Line_Item__c> newDataList
    * Return: 
    * Exceptions:
    * Description: Generate Rating Modifiers for selected opportunity products on insert of POLI.
    * Revision: 
     *************************************************/
    private static void AddRatingModifiers(List<Product_Option_Line_Item__c> poliList, Set<Id> clearedSubmissionIDs, List<Product_Option_Line_Item__c> newDataList){
        System.debug('poli'+poliList);
        //Need to generate Rating Modifiers per opportunity
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        //Map<String, List<Rating_Modifier_Template__c>> templateMap = new Map<String, List<Rating_Modifier_Template__c>>();
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        Set<Id> prodIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        List<String> prodNames = new List<String>();
        Map<String, Set<String>> oppProdMap = new  Map<String, Set<String>> ();
        for (Product_Option_Line_Item__c poli : poliList){
            if(poli.Product__c != null){
                prodIds.add(poli.Product__c);
            }
            if(poli.Submission__c != null){
                oppIds.add(poli.Submission__c);
            }
        }
        Map<String,String> prodNameMap = new Map<String,String>();
        List<Product2> prodList = [Select Name from Product2 Where Id  In : prodIds];
        for (Product2 prod : prodList){
            prodNames.add(prod.Name);
            if(!prodNameMap.containsKey(prod.Id)){
                prodNameMap.put(prod.Id, prod.Name);
            }
        }
        for (Product_Option_Line_Item__c poli : poliList){
            if(!oppProdMap.containsKey(poli.Submission__c)){
                oppProdMap.put(poli.Submission__c, new Set<String>());
            }
            oppProdMap.get(poli.Submission__c).add(prodNameMap.get(poli.Product__c));
        }
        
        //clear existing rating modifiers
        Map<String, Set<String>> existRatingMap = new  Map<String, Set<String>> ();
        List<Rating_Modifiers__c> rms = RatingModifierQueryUtil.fetchRatingModifiersByOpportunityAndProduct(clearedSubmissionIDs, prodNames);
        for(Rating_Modifiers__c rm : rms){
            if(!existRatingMap.containsKey(rm.Opportunity__c)){
                existRatingMap.put(rm.Opportunity__c, new Set<String>());
            }
            existRatingMap.get(rm.Opportunity__c).add(rm.Product__c);
        }
        // if(!rms.isEmpty())
        //     delete rms;
        Map<String,Opportunity> oppMap = new Map<String,Opportunity>();
        List<Opportunity> opps = OpportunityQueryUtil.fetchOpportunityByIds(oppIds);
        for(Opportunity oppr : opps){
            oppMap.put(oppr.Id, Oppr);
        }
        try{
            templates = getRatingTemplates(prodNames);
            // no templates is found
            if (templates.isEmpty())
                return;
    
            for(String oppId : oppProdMap.keySet()){
                List<Rating_Modifiers__c> oppRatings = generateRatingModifiers(templates, oppMap.get(oppId));
                for(Rating_Modifiers__c rm : oppRatings){
                    if(!oppProdMap.get(oppId).contains(rm.Product__c)) continue;
                    if(existRatingMap.get(oppId) != null && existRatingMap.get(oppId).contains(rm.Product__c)){
                        if(rm.Display_Format__c == 'Clearance') continue;
                    }
                    result.add(rm);
                }
            }
            if(result.size() > 0)
                insert result;
        } catch (Exception ex){
            system.debug(ex.getMessage()+'***!!!');
            String errorMsg = 'Failed to create Rating Modifier.Please contact your administators.';
        }
    }

    /*************************************************
    * Method Name: getRatingTemplates
    * Author:
    * Date: 14th Dec 2021
    * Params: List<String> prodNames
    * Return: List<Rating_Modifier_Template__c>
    * Exceptions:
    * Description: Configure Rating Modifier templates
    * Revision: 
     *************************************************/
    public static List<Rating_Modifier_Template__c> getRatingTemplates(List<String> prodNames) {
        List<Rating_Modifier_Template__c> result = new List<Rating_Modifier_Template__c>();
        List<String> fields = new List<String>();
        List<String> prods = new List<String>();
        String PRIMARY_MODIFIERS = 'Primary Modifiers';
        String condition = '';
        try {
            fields.add('Factor_Default_Value__c');
            fields.add('Factor_Max__c');
            fields.add('Factor_Min__c');
            fields.add('Modifier_Format__c');
            fields.add('Product__c');
            fields.add('Name');
            fields.add('Page_Section__c');
            fields.add('Picklist_Default_Value__c');
            fields.add('Picklist_Range__c'); 
            fields.add('Picklist_Values__c');
            fields.add('Sort_Order__c');
            fields.add('Sort_Sub_Section__c');
            fields.add('Comment__c');
            fields.add('Sub_Section__c');
            fields.add('Eligibility_Weighting_Factor__c');
            fields.add('Rating_Modifier_Code__c');
            fields.add('Display_Format__c');
            fields.add('Profile_Name_for_Read_Only__c');
            fields.add('Is_Required__c');
            fields.add('Create_Criteria__c');
            fields.add('Order_of_Page_Section__c');
            fields.add('Object_API_Name_of_Picklist__c');
            fields.add('Controlling_Picklist_API_Name__c');
            fields.add('Controlling_Picklist_Label__c');
            fields.add('Dependent_Picklist_API_Name__c');
            fields.add('Dependent_Picklist_Label__c');
            fields.add('Submission_Field_API_Name__c');
            fields.add('External_Id__c');
            fields.add('Rating__c'); // Added for US:53759
            fields.add('Rating_Reference_Name__c');
            fields.add('Coverage_Code__c');
            String objName = 'Rating_Modifier_Template__c';
        
            condition = '(Product__c In :prodNames OR Page_Section__c In :prodNames)';
            //condition = 'Page_Section__c =: prod';
                // condition = 'Modifier_Product__c in (\''+ String.join(products,'\',\'') + '\')';
            
            
            String query = CommonUtil.buildQuery(fields, objName, condition);
            System.debug(query);
            result = Database.query(query);
        } catch (Exception ex) {
            result = new List<Rating_Modifier_Template__c>();
        }

        return result;
    }


    /*************************************************
    * Method Name: generateRatingModifiers
    * Author:
    * Date: 14th Dec 2021
    * Params: List<Rating_Modifier_Template__c> templates, List<Product_Option_Line_Item__c> poliList
    * Return: List<Rating_Modifiers__c>
    * Exceptions:
    * Description: Generate rating modifiers
    * Revision: 
     *************************************************/
    private static List<Rating_Modifiers__c> generateRatingModifiers(List<Rating_Modifier_Template__c> templates, Opportunity opp){
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        //List<Opportunity> opps = OpportunityQueryUtil.fetchOpportunityByIds(new Set<id>{poliList[0].Submission__c});
        for (Rating_Modifier_Template__c item : templates){
            Rating_Modifiers__c rating = new Rating_Modifiers__c();
            rating.Opportunity__c = opp.Id;
            rating.Page_Section__c = item.Page_Section__c;
            rating.Picklist_Values__c = item.Picklist_Values__c;
            rating.Product__c = item.Product__c;
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
            rating.Factor_Default_Value__c = item.Factor_Default_Value__c;
            rating.Profile_Name_for_Read_Only__c = item.Profile_Name_for_Read_Only__c;
            rating.Is_Required__c = item.Is_Required__c; 
            rating.Order_of_Page_Section__c = item.Order_of_Page_Section__c;
            rating.Controlling_Picklist_API_Name__c = item.Controlling_Picklist_API_Name__c;
            rating.Controlling_Picklist_Label__c = item.Controlling_Picklist_Label__c;
            rating.Dependent_Picklist_API_Name__c = item.Dependent_Picklist_API_Name__c;
            rating.Dependent_Picklist_Label__c = item.Dependent_Picklist_Label__c;
            rating.Object_API_Name_of_Picklist__c = item.Object_API_Name_of_Picklist__c;
            rating.Submission_Field_API_Name__c	 = item.Submission_Field_API_Name__c;
            rating.Rating__c = item.Rating__c; // Added for 53759         
            if(opp.Product__r.Name == 'Private Company Combo') {
                if(item.Name.contains('Selected Industry')){
                    rating.Rating_Modifier_Value__c = opp.Industry__c != null && opp.Service_Classification__c != null ? opp.Industry__c+' - '+opp.Service_Classification__c : '';
                }
                else{
                    rating.Rating_Modifier_Value__c = item.Picklist_Default_Value__c;  
                }
                rating.Rating_Modifier_Template_Code__c = item.External_Id__c; 
                rating.Rating_Reference_Name__c = item.Rating_Reference_Name__c;
                rating.Coverage_Code__c = item.Coverage_Code__c; 
            }                    
            result.add(rating);
        }		
         
        return result;
    }

    /*************************************************
    * Method Name: cleanupData
    * Author:
    * Date: 14th Dec 2021
    * Params: List<Product_Option_Line_Item__c> poliList, Map<String, String> prodNameMap, boolean isClearanceAllowed
    * Return: 
    * Exceptions:
    * Description: delete rating modifiers and quote related data
    * Revision: 
     *************************************************/
    private static void cleanupData(List<Product_Option_Line_Item__c> poliList, Map<String, String> prodNameMap, boolean isClearanceAllowed){
        List<String> prodNames = new List<String>();
        Set<Id> submissionIds = new Set<Id>();
        for(Product_Option_Line_Item__c p : poliList){
            prodNames.add(prodNameMap.get(p.Product__c));
            submissionIds.add(p.Submission__c);
        }
        if(!prodNames.isEmpty()){
            deleteRatingModifiersForNotClearedStatus(prodNames, submissionIds, isClearanceAllowed);
            deleteQuoteRelatedData(prodNames, submissionIds);
        }
    }

    /*************************************************
    * Method Name: deleteRatingModifiersForNotClearedStatus
    * Author:
    * Date: 14th Dec 2021
    * Params: List<String> prodNames, Set<Id> submissionIds, boolean isClearanceAllowed
    * Return: 
    * Exceptions:
    * Description: delete rating modifiers for not cleared status
    * Revision: 
     *************************************************/
    private static void deleteRatingModifiersForNotClearedStatus(List<String> prodNames, Set<Id> submissionIds, boolean isClearanceAllowed){
        String qry = 'Select Id From Rating_Modifiers__c Where Opportunity__c IN: submissionIds And Product__c In :prodNames';
        if(isClearanceAllowed)
            qry += ' AND Display_Format__c != \'Clearance\'';
        List<Rating_Modifiers__c> ratModsToDelete = Database.Query(qry);
        if(ratModsToDelete.size() > 0){
            delete ratModsToDelete;
        }
    }

    /*************************************************
    * Method Name: deleteQuoteRelatedData
    * Author:
    * Date: 14th Dec 2021
    * Params: List<String> prodNames, Set<Id> submissionIds
    * Return: 
    * Exceptions:
    * Description: delete quote related data
    * Revision: 
     *************************************************/
    private static void deleteQuoteRelatedData(List<String> prodNames, Set<Id> submissionIds){
        //List<Quote> quotes = new List<Quote>();
        Set<id> quoteIds = new Set<Id>();
        for(Quote qt : QuoteQueryUtil.fetchActiveQuotesOfOpportunities(submissionIds)){
            quoteIds.add(qt.Id);
            if(qt.Status != 'In Progress'){
                qt.Status = 'In Progress';
                qt.Rating_Status__c = '';
                quotesForStatusUpdate.add(qt);
            }
        }

        String prodNamesQuerySelector = string.join(prodNames,',');
        List<CoveragesLineItem__c> clis = CoverageLineItemQueryUtil.fetchCLIsByProductNamesAndQuotes(prodNamesQuerySelector, quoteIds);
        if(!clis.isEmpty())
            delete clis;
        List<Rating_Modifier_Factor__c> ratingModifiers = RatingModifierFactorQueryUtil.fetchNewCLIs(prodNames, quoteIds);
        if(!ratingModifiers.isEmpty())
            delete ratingModifiers;
        // Added for US:53340
        List<Quote_Premium__c> lstQPsToDelete = QuotePremiumQueryUtil.fetchQuotePremiumsByProductNamesAndQuotes(prodNames, quoteIds);
        if(!lstQPsToDelete.isEmpty()){
            delete lstQPsToDelete;
        }
        // if(!quotes.isEmpty()){
        //     TriggerHandler.bypass('QuoteTriggerBaseHandler');
        //     update quotes;
        //     TriggerHandler.clearBypass('QuoteTriggerBaseHandler');
        // }
        
    }

     /*************************************************
    * Method Name: updateQuoteStatusForClearedPoli
    * Author:
    * Date: 10th Jan 2022
    * Params: Set<Id> newlyClearedSubmissionIds
    * Return: 
    * Exceptions:
    * Description: update quote status to In Progress
    * Revision: 
     *************************************************/
    private static void updateQuoteStatusForClearedPoli(Set<Id> submissionIds){       
        Set<id> quoteIds = new Set<Id>();
        for(Quote qt : QuoteQueryUtil.fetchActiveQuotesOfOpportunities(submissionIds)){
            quoteIds.add(qt.Id);
            if(qt.Status != 'In Progress'){
                qt.Status = 'In Progress';
                qt.Rating_Status__c = '';
                quotesForStatusUpdate.add(qt);
            }
        }
    }
}