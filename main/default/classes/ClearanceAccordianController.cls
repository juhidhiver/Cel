/*
@description       : 
@author            : Prashank
@group             : 
@last modified on  : 01-12-2022
@last modified by  : Maeran Shaikh
Modifications Log 
Ver   Date         Author     Modification
1.0   06-25-2021   Prashank   Initial Version
*/

public class ClearanceAccordianController {
    public ClearanceAccordianController() {
        
    }
    // Define Custom Exception for LWC error Handling
    public class MyException extends Exception {
    }

    /*************************************************
    * Author: Prashank Varshney
    * Date: 03-July-2021
    * Params: opportunityId - Opportunity id for which rating modifiers will be fetched
              productName - List of product names for which rating modifiers will be queried
    * Return: ClearanceWrapper
    * Description: Populating Json wrapper for Clearance LWC UI
    * Revision: 
    *************************************************/
    @AuraEnabled(cacheable=true)
    public static ClearanceWrapper getRatingModifiersrecords(String opportunityId){
        
        List<RatingModifierWrapper> wrapperObjList ;
        List<RatingModifierWrapper> childWrapperObjList ;
        Map<String,List<RatingModifierWrapper>> productRatingModifierMap = new Map<String,List<RatingModifierWrapper>>();
        Map<String,List<RatingModifierWrapper>> productChildRatingModifierMap = new Map<String,List<RatingModifierWrapper>>();
        List<ProductWrapper> productWrapperList = new List<ProductWrapper>();
        Set<String> ratingModifierCodeSet = new Set<String>();
        Map<String, Product_Option_Line_Item__c> mapPrdVsPoli= new Map<String, Product_Option_Line_Item__c>();
        ClearanceWrapper clearanceWrapObj = new ClearanceWrapper();
        final String CLEARANCE_STATUS = 'Clearance';
        List<String> productNames = new List<String>();
        try {
            
            if(String.isNotBlank(opportunityId)){


                // Logic to get Notes from POLI for wrapperList
                
                List<Product_Option_Line_Item__c> productOptions  = [SELECT Product__r.Name,Is_Selected__c,Notes__c,Rich_Text_Notes__c, Clearance_Status__c 
                                                                     FROM Product_Option_Line_Item__c 
                                                                     WHERE Submission__c =: opportunityId and (Clearance_Status__c = 'Cleared' or Clearance_Status__c = 'Decline')];
                for(Product_Option_Line_Item__c eachPoli : productOptions){
                    if(String.isNotEmpty(eachPoli.Rich_Text_Notes__c)){
                        mapPrdVsPoli.put(eachPoli.Product__r.Name, eachPoli);
                    }  
                    // if(eachPoli.Is_Selected__c  ) {
                    //     productNames.add(eachPoli.Product__r.Name);
                    // }
                    productNames.add(eachPoli.Product__r.Name);                
                }


                for(Rating_Modifiers__c eachRatingModified : [SELECT Id, Name,Product__c, Format__c, Picklist_Values__c, Is_Required__c,Eligibility_Status__c,
                            Page_Section__c, Opportunity__c, Rating_Modifier_Code__c,Rating_Modifier_Value__c,Controlling_Picklist_API_Name__c,Dependent_Picklist_API_Name__c,
                            Object_API_Name_of_Picklist__c,Controlling_Picklist_Value__c,Dependent_Picklist_Value__c, Sub_Section__c, Sort_Sub_Section__c, Profile_Name_for_Read_Only__c,
                            Submission_Field_API_Name__c, Factor_Default_Value__c
                            FROM Rating_Modifiers__c where Opportunity__c =: opportunityId AND Display_Format__c = :CLEARANCE_STATUS AND Product__c in :productNames
                            ORDER by Order_of_Page_Section__c ASC, Sort_Order__c ASC, Sort_Sub_Section__c ASC]){
                    system.debug('********'+eachRatingModified.Format__c);
                    ratingModifierCodeSet.add(eachRatingModified.Rating_Modifier_Code__c);
                    RatingModifierWrapper wrapperObj = new RatingModifierWrapper();
                   
                    wrapperObj.ratingModifiers = eachRatingModified;
                    if(eachRatingModified.Profile_Name_for_Read_Only__c != null && eachRatingModified.Profile_Name_for_Read_Only__c.contains('All')){
                        wrapperObj.isReadOnly = true;
                    }
                    if(eachRatingModified.Name == 'Notes'){
                        wrapperObj.isNotesField = true;
                    }
                    if(eachRatingModified.Format__c == 'Number'){
                        wrapperObj.numberType = true;
                    }
                    if(eachRatingModified.Format__c == 'Currency'){
                        wrapperObj.currencyType = true;
                    }
                    if(eachRatingModified.Format__c == 'Percentage'){
                        wrapperObj.percentageType = true;
                    }
                    if(eachRatingModified.Format__c == 'Integer'){
                        wrapperObj.integerType = true;
                    }
                    if(eachRatingModified.Format__c == 'Text'){
                        wrapperObj.textType = true;
                    }
                    if(eachRatingModified.Format__c == 'Radio Button'){
                        wrapperObj.radioButtonType = true;
                    }
                    if(eachRatingModified.Format__c == 'Date'){
                        wrapperObj.dateType = true;
                    }
                    if(eachRatingModified.Format__c == 'Text Area'){
                        wrapperObj.textAreaType = true;
                    }
                    if(eachRatingModified.Format__c == 'Picklist'){
                        wrapperObj.pickListType = true;
                    }
                    if(eachRatingModified.Format__c == 'Picklist' || eachRatingModified.Format__c == 'Radio Button'){
                        if(String.isNotBlank(eachRatingModified.Picklist_Values__c)){
                            if(eachRatingModified.Picklist_Values__c.contains(';')){
                                List<OptionWrapper> optionsList = new List<OptionWrapper>();
                                //Adding None option only for picklist and not for radio button
                                if(eachRatingModified.Format__c == 'Picklist'){
                                    optionsList.add(new OptionWrapper('None',''));
                                }
                                for(String s: eachRatingModified.Picklist_Values__c.split(';')){
                                    optionsList.add(new OptionWrapper(s.trim(),s.trim()));
                                }
                                wrapperObj.pickListValueList = optionsList;
                            }else{
                                wrapperObj.pickListValueList.add(new OptionWrapper(eachRatingModified.Picklist_Values__c.trim(), eachRatingModified.Picklist_Values__c.trim()));
                            }
                        }
                        else{
                            wrapperObj.controlPicklistApiName = String.isNotBlank(eachRatingModified.Controlling_Picklist_API_Name__c) ? eachRatingModified.Controlling_Picklist_API_Name__c: '';
                            wrapperObj.dependPicklistApiName = String.isNotBlank(eachRatingModified.Dependent_Picklist_API_Name__c)?eachRatingModified.Dependent_Picklist_API_Name__c:'';
                            wrapperObj.objApiName = String.isNotBlank(eachRatingModified.Object_API_Name_of_Picklist__c)?eachRatingModified.Object_API_Name_of_Picklist__c:'';
                        }
                    }  
                    

                   //Logic to populate subsections if any(currently only logic for 1 subsection)
                   if(!String.isBlank(eachRatingModified.Sub_Section__c)) {
                       system.debug('vinay factor default');
                       system.debug(eachRatingModified.Factor_Default_Value__c);
                       system.debug( eachRatingModified.Rating_Modifier_Value__c);
                        if(eachRatingModified.Factor_Default_Value__c != null){
                            if(eachRatingModified.Rating_Modifier_Value__c == null || eachRatingModified.Rating_Modifier_Value__c == ''){
                                eachRatingModified.Rating_Modifier_Value__c = String.valueOf(Integer.valueOf(String.valueOf(eachRatingModified.Factor_Default_Value__c)));
                            }
                        }
                        if(!productChildRatingModifierMap.containsKey(eachRatingModified.Product__c)){
                            childWrapperObjList = new List<RatingModifierWrapper>();
                        }else{
                            childWrapperObjList = productChildRatingModifierMap.get(eachRatingModified.Product__c);
                        }

                        childWrapperObjList.add(wrapperObj);
                        productChildRatingModifierMap.put(eachRatingModified.Product__c, childWrapperObjList);
                   }
                  
                   else{
                        //wrapperObjList.add(wrapperObj);
                        if(!productRatingModifierMap.containsKey(eachRatingModified.Product__c)){
                            wrapperObjList = new List<RatingModifierWrapper>();
                        }else{
                            wrapperObjList = productRatingModifierMap.get(eachRatingModified.Product__c);
                        }

                        wrapperObjList.add(wrapperObj);
                        productRatingModifierMap.put(eachRatingModified.Product__c,wrapperObjList);
                   }
                   
                }
            }
            String helpTextVal = System.label.PCC_Generic_Clearance_Warning_Message;

            for(String prodName : productRatingModifierMap.keySet()){
                ProductWrapper prodWrapObj = new ProductWrapper();
                prodWrapObj.productName = prodName;
                prodWrapObj.modifiersList = productRatingModifierMap.get(prodName);
                if(productChildRatingModifierMap.containsKey(prodName)){
                    List<RatingModifierWrapper> childList  = productChildRatingModifierMap.get(prodName);
                    RatingModifierWrapper wrapperObj = new RatingModifierWrapper();
                    wrapperObj.ratingModifiers = new Rating_Modifiers__c();
                    wrapperObj.isChildSection = true;
                    wrapperObj.childSectionName = childList[0].ratingModifiers.Sub_Section__c;
                    wrapperObj.childRatingModifiers = childList;
                    prodWrapObj.modifiersList.add(wrapperObj);
                }
                prodWrapObj.poliNotes = mapPrdVsPoli.containsKey(prodName)? mapPrdVsPoli.get(prodName).Rich_Text_Notes__c : '';
                
                String helpTextVal1 = helpTextVal.replace('{ProdName}', prodName);
                prodWrapObj.helpTextNote = helpTextVal1;
                productWrapperList.add(prodWrapObj);
            }

            clearanceWrapObj.productWrapperList = productWrapperList;
            clearanceWrapObj.eligibilityStatusWrapper = getEnquiryStatusMap(ratingModifierCodeSet);
            return clearanceWrapObj;
            
        }catch(Exception exp){
            throw new MyException(exp.getMessage());
        }
    }

    /*************************************************
    * Author: Prashank Varshney
    * Date: 03-July-2021
    * Params: ratingModifierCodes - Set of Rating modifier codes
    * Return: Map<String,List<Eligibility_Status__c>>
    * Description: Return a Map of Eligibility Status on basis of rating Modifier codes 
    * Revision: 
    *************************************************/
    private static Map<String,List<Eligibility_Status__c>> getEnquiryStatusMap(Set<String> ratingModifierCodes){
        Map<String,List<Eligibility_Status__c>> enquiryStatusMap = new Map<String,List<Eligibility_Status__c>>();
        for(Rating_Modifier_Template__c templateRec : [SELECT Id, Rating_Modifier_Code__c ,(SELECT Id, Eligibility_Status__c,Modifier_Product__c, Rating_Modifier_Value__c, Rating_Modifier_Template__c FROM 
                            Eligibility_Statuses__r) FROM Rating_Modifier_Template__c where Rating_Modifier_Code__c in: ratingModifierCodes]){
            enquiryStatusMap.put(templateRec.Rating_Modifier_Code__c,templateRec.Eligibility_Statuses__r);
        }

        return enquiryStatusMap;
    }

     /*************************************************
    * Author: Prashank Varshney
    * Date: 04-July-2021
    * Params: clearanceWrapperJson - JSON Wrapper passed from LWC UI 
    * Return: 
    * Description: Will be used to parse the JSON wrapper and update the rating modifier records 
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static void saveClearanceData(String clearanceWrapperJson, String opportunityid){

        List<Rating_Modifiers__c> updatedRatingModifierList = new List<Rating_Modifiers__c>();
        List<ProductWrapper> inputWrapper = (List<ProductWrapper>)JSON.deserialize(clearanceWrapperJson, List<ProductWrapper>.class);
        Map<String,Product_Option_Line_Item__c> mapPrdVsPoli =new  Map<String,Product_Option_Line_Item__c>();
        List<Product_Option_Line_Item__c> poliListToUpdate = new List<Product_Option_Line_Item__c>();
        // Save Notes for POLI
        System.debug('OppId-->'+opportunityid);
        List<Product_Option_Line_Item__c> productOptions  = [SELECT Product__r.Name,Is_Selected__c,Notes__c,Rich_Text_Notes__c FROM Product_Option_Line_Item__c WHERE Submission__c =: opportunityId and Is_Selected__c = true];
        Opportunity oppRec = [Select Id, AnnualRevenue__c, Ratable_Employees__c, Foreign_Employees__c,
                              Average_Part_Time_Ratio__c, Percent_of_Employees_located_in_CA__c, Foreign_Ratio__c,
                              Full_Time_Employees__c, Part_Time_Employees__c, Plan_Assets__c
                              from Opportunity where Id = :opportunityId];
        for(Product_Option_Line_Item__c eachPoliRec:productOptions ){
            mapPrdVsPoli.put(eachPoliRec.Product__r.Name , eachPoliRec);
        }
        System.debug('mapPrdVsPoli-->'+mapPrdVsPoli);
        try{
            for(ProductWrapper eachProduct : inputWrapper){
                for(RatingModifierWrapper eachModifier : eachProduct.modifiersList){
                    if(eachModifier.isChildSection){
                        for(RatingModifierWrapper eachChildModifier : eachModifier.childRatingModifiers){
                            populateUpdateRatingModifierFields(eachChildModifier, updatedRatingModifierList,
                                                                mapPrdVsPoli, poliListToUpdate);
                            if(eachChildModifier.ratingModifiers.Submission_Field_API_Name__c != null){
                                if(eachChildModifier.integerType || eachChildModifier.numberType ||
                                   eachChildModifier.percentageType || eachChildModifier.currencyType){
                                    if(eachChildModifier.ratingModifiers.Rating_Modifier_Value__c != null && eachChildModifier.ratingModifiers.Rating_Modifier_Value__c != ''){
                                        System.debug('vinay rating value-->' + eachChildModifier.ratingModifiers.Submission_Field_API_Name__c);
                                        System.debug(eachChildModifier.ratingModifiers.Rating_Modifier_Value__c);
                                        oppRec.put(eachChildModifier.ratingModifiers.Submission_Field_API_Name__c, decimal.valueOf(eachChildModifier.ratingModifiers.Rating_Modifier_Value__c));
                                    }
                                }
                                else{
                                    oppRec.put(eachChildModifier.ratingModifiers.Submission_Field_API_Name__c, eachChildModifier.ratingModifiers.Rating_Modifier_Value__c);
                                }                               
                            }
                        }
                    }
                    else{
                        populateUpdateRatingModifierFields(eachModifier, updatedRatingModifierList,
                        mapPrdVsPoli, poliListToUpdate);
                    }
                   
                    // if(eachModifier.isChildSection) continue;
                    // Rating_Modifiers__c updatedRatingModifier = new Rating_Modifiers__c();
                    // if(eachModifier.ratingModifiers.Rating_Modifier_Value__c != null){
                    //     updatedRatingModifier.Rating_Modifier_Value__c = eachModifier.ratingModifiers.Rating_Modifier_Value__c ;
                    // }
                    // //system.debug('>>>>>'+eachModifier.ratingModifiers.Eligibility_Status__c);
                    // if(eachModifier.ratingModifiers.Eligibility_Status__c != 'None'){
                    //     updatedRatingModifier.Eligibility_Status__c = eachModifier.ratingModifiers.Eligibility_Status__c ;
                    // }else{
                    //     updatedRatingModifier.Eligibility_Status__c = '' ;
                    // }
                    // if((eachModifier.ratingModifiers.Controlling_Picklist_Value__c != null && 
                    // eachModifier.ratingModifiers.Dependent_Picklist_Value__c != null)){
                    //     updatedRatingModifier.Controlling_Picklist_Value__c = eachModifier.ratingModifiers.Controlling_Picklist_Value__c ;
                    //     updatedRatingModifier.Dependent_Picklist_Value__c = eachModifier.ratingModifiers.Dependent_Picklist_Value__c ;
                    // }
                    // updatedRatingModifier.Id = eachModifier.ratingModifiers.Id;
                    // updatedRatingModifierList.add(updatedRatingModifier);
                      
                }
                 // Save Notes for POLI
                 System.debug('eachProduct.poliNotes-->'+eachProduct.poliNotes);
                if(mapPrdVsPoli.containsKey(eachProduct.productName) && (String.isNotEmpty(eachProduct.poliNotes) || !eachProduct.poliNotes.equals(mapPrdVsPoli.get(eachProduct.productName).Rich_Text_Notes__c) )){
                    System.debug('Notes for '+ eachProduct.productName + 'is '+ mapPrdVsPoli.get(eachProduct.productName).Rich_Text_Notes__c);
                    Product_Option_Line_Item__c updatedPoli = new Product_Option_Line_Item__c(
                        Id = mapPrdVsPoli.get(eachProduct.productName).Id,
                        
                        Rich_Text_Notes__c = eachProduct.poliNotes
                    );
                    
                    poliListToUpdate.add(updatedPoli);
                }
                
            }
    
            if(!updatedRatingModifierList.isEmpty()){
                update updatedRatingModifierList;
            }
    
            if(!poliListToUpdate.isEmpty()){
                System.debug('Test Update');
                update poliListToUpdate;
            }
            //Update opportunity record for subsection fields data.
            update oppRec;
        }
        catch(Exception e){
           System.debug('Exception @ Save-->'+e.getMessage());
           throw new MyException(e.getMessage());
        }
    }    

   
    private static void populateUpdateRatingModifierFields(RatingModifierWrapper eachModifier, List<Rating_Modifiers__c> updatedRatingModifierList, 
                                                            Map<String,Product_Option_Line_Item__c> mapPrdVsPoli,
                                                              List<Product_Option_Line_Item__c> poliListToUpdate){
        Rating_Modifiers__c updatedRatingModifier = new Rating_Modifiers__c();
        if(eachModifier.ratingModifiers.Rating_Modifier_Value__c != null){
            updatedRatingModifier.Rating_Modifier_Value__c = eachModifier.ratingModifiers.Rating_Modifier_Value__c ;
        }
        //system.debug('>>>>>'+eachModifier.ratingModifiers.Eligibility_Status__c);
        if(eachModifier.ratingModifiers.Eligibility_Status__c != 'None'){
            updatedRatingModifier.Eligibility_Status__c = eachModifier.ratingModifiers.Eligibility_Status__c ;
        }else{
            updatedRatingModifier.Eligibility_Status__c = '' ;
        }
        if((eachModifier.ratingModifiers.Controlling_Picklist_Value__c != null && 
        eachModifier.ratingModifiers.Dependent_Picklist_Value__c != null)){
            updatedRatingModifier.Controlling_Picklist_Value__c = eachModifier.ratingModifiers.Controlling_Picklist_Value__c ;
            updatedRatingModifier.Dependent_Picklist_Value__c = eachModifier.ratingModifiers.Dependent_Picklist_Value__c ;
        }
        updatedRatingModifier.Id = eachModifier.ratingModifiers.Id;
        updatedRatingModifierList.add(updatedRatingModifier);
    }


    @AuraEnabled
    public static void addRatingModifier(Id opportunityId){
        String PRIMARY_MODIFIERS = 'Primary Modifiers';
        if (opportunityId == null)
                return;
        List<Rating_Modifier_Template__c> templates = new List<Rating_Modifier_Template__c>();
        List<Rating_Modifiers__c> result            = new List<Rating_Modifiers__c>();

        try{

            Set<String> existedProducts    = new Set<String>();
            List<String> productsToAdd     = new List<String>();
            List<String> productsToDelete  = new List<String>();
            List<Product_Option_Line_Item__c> productOptions  = [SELECT Product__r.Name,Is_Selected__c FROM Product_Option_Line_Item__c WHERE Submission__c =: opportunityId];
            
            for(AggregateResult ar : [SELECT Product__c FROM Rating_Modifiers__c WHERE Opportunity__c = :opportunityId AND Display_Format__c = :PRIMARY_MODIFIERS GROUP BY Product__c]){
                existedProducts.add((String)ar.get('Product__c'));
            }
            for(Product_Option_Line_Item__c productOption: productOptions){
                if(productOption.Is_Selected__c == true && (existedProducts == null || !existedProducts.contains(productOption.Product__r.Name)))
                    productsToAdd.add(productOption.Product__r.Name);
                else if(productOption.Is_Selected__c == false && existedProducts != null && existedProducts.contains(productOption.Product__r.Name))
                    productsToDelete.add(productOption.Product__r.Name);
            }

            if(!productsToDelete.isEmpty()){
                List<Rating_Modifiers__c> ratingModifiersToDelete = [SELECT Id FROM Rating_Modifiers__c WHERE Opportunity__c = :opportunityId AND Display_Format__c = :PRIMARY_MODIFIERS AND Product__c IN :productsToDelete];
                if(ratingModifiersToDelete != null)
                    delete ratingModifiersToDelete;
            }

            //Rating Modifiers already inserted
            if(productsToAdd.isEmpty())
                return;

            templates = getRatingTemplates(productsToAdd);

            // no templates is found
            if (templates.isEmpty())
                return;
    
            result = generateRatingModifier(templates, opportunityId);
            insert result;

        } catch (Exception ex){
            String errorMsg = 'Failed to create Rating Modifier.<br/>Please contact your administators.';
            System.debug('@@@ ex'+ex.getMessage());
            throw new MyException('Failed to create Rating Modifier.<br/>Please contact your administators.' + ex.getMessage());
        }
    }

    public static List<Rating_Modifier_Template__c> getRatingTemplates(List<String> products) {
        List<Rating_Modifier_Template__c> result = new List<Rating_Modifier_Template__c>();
        List<String> fields = new List<String>();
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
            fields.add('External_Id__c');
            fields.add('Rating__c');
            fields.add('Rating_Reference_Name__c');
            fields.add('Coverage_Code__c');
            String objName = 'Rating_Modifier_Template__c';
        
            condition = '(Product__c IN :products OR Page_Section__c IN :products) AND Display_Format__c = :PRIMARY_MODIFIERS';         
            
            String query = CommonUtil.buildQuery(fields, objName, condition);
            System.debug(query);
            result = Database.query(query);
        } catch (Exception ex) {
            result = new List<Rating_Modifier_Template__c>();
            throw new MyException(ex.getMessage());
        }

        return result;
    }


    private static List<Rating_Modifiers__c> generateRatingModifier(List<Rating_Modifier_Template__c> templates, Id opportunityId){
        List<Rating_Modifiers__c> result = new List<Rating_Modifiers__c>();

        Opportunity opp = [Select Id, Product__r.Name, Industry__c, Service_Classification__c from Opportunity where Id = :opportunityId];
        System.debug('opp---->'+opp);
        for (Rating_Modifier_Template__c item : templates){
         
                Rating_Modifiers__c rating = new Rating_Modifiers__c();
                rating.Opportunity__c = opportunityId;
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
                rating.Profile_Name_for_Read_Only__c = item.Profile_Name_for_Read_Only__c;
                rating.Is_Required__c = item.Is_Required__c; 
                rating.Order_of_Page_Section__c = item.Order_of_Page_Section__c;
                rating.Controlling_Picklist_API_Name__c = item.Controlling_Picklist_API_Name__c;
                rating.Controlling_Picklist_Label__c = item.Controlling_Picklist_Label__c;
                rating.Dependent_Picklist_API_Name__c = item.Dependent_Picklist_API_Name__c;
                rating.Dependent_Picklist_Label__c = item.Dependent_Picklist_Label__c;
                rating.Object_API_Name_of_Picklist__c = item.Object_API_Name_of_Picklist__c; 
                rating.Rating__c = item.Rating__c; // Added for US:53759
                if(opp.Product__r.Name == 'Private Company Combo') {
                    if(item.Name == 'Selected Industry'){
                        System.debug('item.Rating_Modifier_Code__c---->'+item.Rating_Modifier_Code__c);
                        rating.Rating_Modifier_Value__c = opp.Industry__c != null && opp.Service_Classification__c != null ? opp.Industry__c+' - '+opp.Service_Classification__c : '';
                    }
                    else{
                        System.debug('item.Rating_Modifier_Code__c---->'+item.Rating_Modifier_Code__c);
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

    public class ClearanceWrapper{
        @AuraEnabled
        public List<ProductWrapper> productWrapperList {get;set;}
        @AuraEnabled
        public Map<String,List<Eligibility_Status__c>> eligibilityStatusWrapper {get;set;}
    }

    public class ProductWrapper{
        @AuraEnabled
        public String productName {get;set;}
        @AuraEnabled
        public String poliNotes {get;set;}
        //helpTextNote
        @AuraEnabled
        public String helpTextNote {get;set;}
        @AuraEnabled
        public List<RatingModifierWrapper> modifiersList {get;set;}
        

        public ProductWrapper() {
            productName = '';
            modifiersList = new List<RatingModifierWrapper>();
            poliNotes ='';
            helpTextNote='';
        }
    }

    public class RatingModifierWrapper {
        
        @AuraEnabled
        public Rating_Modifiers__c ratingModifiers {get;set;}
        @AuraEnabled
        public List<RatingModifierWrapper> childRatingModifiers {get;set;}
        @AuraEnabled
        public boolean isChildSection {get;set;}
        @AuraEnabled
        public String childSectionName {get;set;}
        @AuraEnabled
        public boolean isNotesField {get;set;}
        @AuraEnabled
        public boolean isReadOnly {get;set;}
        @AuraEnabled
        public List<OptionWrapper> pickListValueList {get;set;}
        @AuraEnabled
        public boolean pickListType {get;set;}
        @AuraEnabled
        public boolean numberType {get;set;}
        @AuraEnabled
        public boolean currencyType {get;set;}
        @AuraEnabled
        public boolean percentageType {get;set;}
        @AuraEnabled
        public boolean integerType {get;set;}
        @AuraEnabled
        public boolean textType {get;set;}
        @AuraEnabled
        public boolean radioButtonType {get;set;}
        @AuraEnabled
        public boolean dateType {get;set;}
        @AuraEnabled
        public boolean textAreaType {get;set;}
        @AuraEnabled
        public String status {get;set;}
        @AuraEnabled
        public String badgeColor {get;set;}
        @AuraEnabled
        public String selectedValue {get;set;}
        // Below listed nodes are for Dependent Picklist
        @AuraEnabled
        public String objApiName {get;set;}
        @AuraEnabled
        public String controlPicklistApiName {get;set;}
        @AuraEnabled
        public String dependPicklistApiName {get;set;}

        public RatingModifierWrapper(){
            
            pickListType = false;
            numberType = false;
            currencyType = false;
            percentageType = false;
            integerType = false;
            textType = false;
            radioButtonType = false;
            dateType = false;
            textAreaType = false;
            isChildSection = false;
            isNotesField = false;
            isReadOnly = false;
            status = '';
            badgeColor = '';
            selectedValue = '';
            objApiName ='';
            controlPicklistApiName='';
            dependPicklistApiName ='';
            childSectionName = '';
        }
    }
    
    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}