/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 10-28-2021
 * @last modified by  : Vinayesh
 * Modifications Log 
 * Ver   Date         Author     Modification
 * 1.0   06-24-2021   Vinayesh   Initial Version
 * 1.1   11-21-2021   Vinay      Added logic to clear Coverage line items, Rating Modifiers and Rating Modifier Factors
**/
public with sharing class ProductOptionLineItemTriggerHandler extends TriggerHandler {
    List<Product_Option_Line_Item__c> newDataList;
    List<Product_Option_Line_Item__c> oldDataList;
    Map<Id, Product_Option_Line_Item__c> oldDataMap;
    Map<Id, Opportunity> oppMap;
    private static final String CLEARANCE_STATUS = 'Clearance';
    public ProductOptionLineItemTriggerHandler() {
        if(Trigger.isDelete){
            this.oldDataList = (List<Product_Option_Line_Item__c>)Trigger.old;
        }
        else{
            //US 52811 :set old data map
            this.oldDataMap = (Map<id, Product_Option_Line_Item__c>)Trigger.oldMap;
            this.newDataList = (List<Product_Option_Line_Item__c>)Trigger.new;
            //Needs to be bulkified. Also Soql maybe needs to be removed from constructor.
            this.oppMap = new Map<Id, Opportunity>([SELECT Id, Industry__c, Service_Classification__c, Coverage_Product_Options__c,
                                                        Product__r.Name, Product_Name__c
                                                        FROM Opportunity WHERE Id =:newDataList[0].Submission__c]);
        }      
    }
  
  public override void beforeInsert(){
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
        List<Product_Option_Line_Item__c> existingPoli = [Select Submission__c, Product__c, Product__r.Name From Product_Option_Line_Item__c
                                                          Where Submission__c In :oppIds And Product__c In :prodIds];
        

        for (Product_Option_Line_Item__c poli : newDataList){
            for (Product_Option_Line_Item__c poli1 : existingPoli){
                if((poli.Submission__c == poli1.Submission__c) && (poli.Product__c == poli1.Product__c)){
                    poli.addError('Poli already exist for: ' + poli1.Product__r.Name);
                }
            }
        }
    }

    public override void afterInsert(){
        //List<Product_Option_Line_Item__c> currPoli = this.newDataList[0];
        //Maybe dont need validate for new. Just add for selected.
        RatingModifiersValidate();
        CommonUtil.updateRatingModifiersForOpps(this.oppMap);
    }

    public override void afterUpdate(){
        //List<Product_Option_Line_Item__c> currPoli = this.newDataList[0];
        RatingModifiersValidate();
        CommonUtil.updateRatingModifiersForOpps(this.oppMap);
    }

    
    /**
    * @description : Method to add rating modifiers for cleared POLI and  
      delete rating modifiers when POLI status changed from cleared to any other status other than Decline.
    * @author Vinayesh | 08-02-2021
    * Modified: Vinay for US 52811 
    **/
    private void RatingModifiersValidate(){
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
                    }else if(poli.Clearance_Status__c == 'Decline' && oldDataMap.get(poli.id).Clearance_Status__c == 'Cleared'){
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
        List<Product2> prodList = [Select Name from Product2 Where Id  In : prodIds];
        
        //prepare map of product name and id
        for (Product2 prod : prodList){
            if(prodOptionsMap.get(prod.Id).Is_Selected__c){
                prodNames.add(prod.Name);
                prodNameMap.put(prod.Name, prod.Id);
            }             
            prodMap.put(prod.Id, prod.Name);
        }

        //delete all rating modifiers except clearance, coverage lines and rating modifier factors
        if(!declinedPOLIs.isEmpty())
            cleanupData(declinedPOLIs, prodMap, true);

        //delete all rating modifiers, coverage lines and rating modifier factors 
        if(!unClearedPOLIs.isEmpty())
            cleanupData(unClearedPOLIs, prodMap, false);

        if(!clearedSubmissionIDs.isEmpty()){
            //clear old and add new rating modifiers
            AddRatingModifiers(prodOptionsToUpdate, clearedSubmissionIDs);

            //fetch active quotes and create coverage lines and rating modifier factors
            List<Quote> activeQuotes = [Select Id,Quote_Type__c,Effective_Date__c,Endorsement_Effective_Date__c,OpportunityId,Product_Name__c,Layer__c,Coverage_Product_Options__c from Quote where OpportunityId in: clearedSubmissionIDs and Status in ('In Progress', 'Rated', 'Quoted', 'Referred')];
            if(!activeQuotes.isEmpty()){
                //generate rating modifier factors and coverage line items
                QuoteTriggerHandler handler = new QuoteTriggerHandler(activeQuotes);
            }
        }
    }

     /**
     * Generate Rating Modifiers for selected opportunity products on insert of POLI.
    **/
    private void AddRatingModifiers(List<Product_Option_Line_Item__c> poliList, Set<Id> clearedSubmissionIDs ){
        System.debug('poli'+poliList);
        //Need to generate Rating Modifiers per opportunity
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        //Map<String, List<Rating_Modifier_Template__c>> templateMap = new Map<String, List<Rating_Modifier_Template__c>>();
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        Set<Id> prodIds = new Set<Id>();
        List<String> prodNames = new List<String>();
        for (Product_Option_Line_Item__c poli : poliList){
            if(poli.Product__c != null){
                prodIds.add(poli.Product__c);
            }
        }
        List<Product2> prodList = [Select Name from Product2 Where Id  In : prodIds];
        for (Product2 prod : prodList){
            prodNames.add(prod.Name);
        }
        
        //clear existing rating modifiers
        List<Rating_Modifiers__c> rms = [Select id from Rating_Modifiers__c where Opportunity__c in: clearedSubmissionIDs and Product__c in: prodNames];
        if(!rms.isEmpty())
            delete rms;

        try{
            templates = getRatingTemplates(prodNames);
            // no templates is found
            if (templates.isEmpty())
                return;
    
            result = generateRatingModifiers(templates, newDataList);
            insert result;
        } catch (Exception ex){
            system.debug(ex.getMessage()+'***!!!');
            String errorMsg = 'Failed to create Rating Modifier.<br/>Please contact your administators.';
        }
    }

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


    private List<Rating_Modifiers__c> generateRatingModifiers(List<Rating_Modifier_Template__c> templates, List<Product_Option_Line_Item__c> poliList){
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();
        List<Opportunity> opps = [SELECT id,Product__r.Name,Industry__c,Service_Classification__c from Opportunity where id =: poliList[0].Submission__c];
        if(!opps.isEmpty()){
            for (Rating_Modifier_Template__c item : templates){
                Rating_Modifiers__c rating = new Rating_Modifiers__c();
                rating.Opportunity__c = opps[0].Id;
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
                if(opps[0].Product__r.Name == 'Private Company Combo') {
                    if(item.Rating_Modifier_Code__c == 'DO000014' || item.Rating_Modifier_Code__c == 'EPL000016'){
                        rating.Rating_Modifier_Value__c = opps[0].Industry__c != null && opps[0].Service_Classification__c != null ? opps[0].Industry__c+' - '+opps[0].Service_Classification__c : '';
                    }
                    else{
                        rating.Rating_Modifier_Value__c = item.Picklist_Default_Value__c;  
                    }
                    rating.Rating_Modifier_Template_Code__c = item.External_Id__c; 
                }                    
                result.add(rating);
            }		
        }	     
        return result;
    }

    
    private void cleanupData(List<Product_Option_Line_Item__c> poliList, Map<String, String> prodNameMap, boolean isClearanceAllowed){
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

    private void deleteRatingModifiersForNotClearedStatus(List<String> prodNames, Set<Id> submissionIds, boolean isClearanceAllowed){
        String qry = 'Select Id From Rating_Modifiers__c Where Opportunity__c IN: submissionIds And Product__c In :prodNames';
        if(isClearanceAllowed)
            qry += ' AND Display_Format__c != \'Clearance\'';
        List<Rating_Modifiers__c> ratModsToDelete = Database.Query(qry);
        if(ratModsToDelete.size() > 0){
            delete ratModsToDelete;
        }
    }

    private void deleteQuoteRelatedData(List<String> prodNames, Set<Id> submissionIds){
        List<Quote> quotes = new List<Quote>();
        Set<id> quoteIds = new Set<Id>();
        for(Quote qt : [Select id,Status  from Quote where Status in ('In Progress', 'Rated', 'Quoted', 'Referred') and OpportunityId in: submissionIds]){
            quoteIds.add(qt.Id);
            if(qt.Status != 'In Progress'){
                qt.Status = 'In Progress';
                qt.Rating_Status__c = '';
                quotes.add(qt);
            }
        }

        String prodNamesQuerySelector = string.join(prodNames,',');
        List<CoveragesLineItem__c> clis = [select id from CoveragesLineItem__c where Coverage_Product_Combo__c INCLUDES (:prodNamesQuerySelector) and Quote__c in: quoteIds];
        if(!clis.isEmpty())
            delete clis;
        List<Rating_Modifier_Factor__c> ratingModifiers = [SELECT id from Rating_Modifier_Factor__c where Rating_Modifier__r.Product__c in: prodNames and Quote__c in: quoteIds];
        if(!ratingModifiers.isEmpty())
            delete ratingModifiers;
        
        if(!quotes.isEmpty())
            update quotes;
    }

    //Delete rating modifiers for deleted POLIs
    public override void afterDelete(){
        //List<Product_Option_Line_Item__c> currPoli = this.newDataList[0];
        List<String> prodIds = new List<String>();
        for(Product_Option_Line_Item__c p : oldDataList){
            prodIds.add(p.Product__c);
        }
        List<Product2> comboProds = [Select Name From Product2
                                       Where Id in: prodIds];
        List<Rating_Modifiers__c> oppRatingModifiers = [Select Id, Product__c, Page_Section__c From Rating_Modifiers__c
                                                          Where Opportunity__c =: oldDataList[0].Submission__c];
        
        
        
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
}