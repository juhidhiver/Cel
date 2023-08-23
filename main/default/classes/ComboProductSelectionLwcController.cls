/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 09-03-2021
 * @last modified by  : Vinayesh
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   06-18-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/

public with sharing class ComboProductSelectionLwcController {
    private static final String DandO_CELERITY = 'D&O';
    private static final String EPL_CELERITY = 'EPL';

    private static final String CLEARED_STATUS = 'Cleared';
    private static final String CLOSED_MARKET_STATUS = 'Closed Market';
    private static final String CLEARANCE_NOT_APPLICABLE_STATUS = 'Clearance Not Applicable';
    private static final String SERVICE_FAILED_STATUS = 'Service failed';

    public ComboProductSelectionLwcController() {

    }


    /**
    * @description : Get all combo products for parent product.
    * @author Vinayesh | 08-02-2021 
    * @param parentProductId 
    * @return List<Product2> 
    **/
    public static List<Product2> getComboProducts(string parentProductId) {

        List<Product2> comboProducts =  [SELECT Id, Name,Munich_LOB_Code__c  FROM Product2
                                            WHERE Parent_Product__c = :parentProductId];
        return comboProducts;
    }

    /**
    * @description : Get Product option lines data for submission and populate wrapper for UI.
    * @author Vinayesh | 08-02-2021 
    * @param parentProductId 
    * @param submissionId 
    * @return List<ItemWrapper> 
    **/
    @AuraEnabled(cacheable = true)
    public static List<ItemWrapper> getProductOptionLineItems(string parentProductId, string submissionId) {
        try{
            List<Product2> comboProducts = getComboProducts(parentProductId);
            List<Product_Option_Line_Item__c> poliList = new List<Product_Option_Line_Item__c>();
            if(submissionId != null){
                poliList =  [SELECT Id, Product__c, Product__r.Name, Notes__c, Submission__c, Clearance_Date__c,
                Clearance_Status__c, Is_Selected__c, Account__c, IsManualClearance__c , Account__r.Billing_County__c, Account__r.BillingCity, Account__r.BillingState,Account__r.BillingStreet, Account__r.BillingPostalCode, Account__r.BillingStateCode,
                Submission__r.Azure_ID__c, Product__r.Munich_LOB_Code__c,  Submission__r.Effective_Date__c,Product__r.Model_ID__c, Account__r.Name
                FROM Product_Option_Line_Item__c
                WHERE Submission__c = :submissionId];
            }
            
            
            Map<Id, Product_Option_Line_Item__c> poliMap = new Map<Id, Product_Option_Line_Item__c>();

            String accountId;
            for(Product_Option_Line_Item__c poli : poliList){
                poliMap.put(poli.Product__c, poli);
                accountId = poli.Account__c;
            }

            if(accountId == null || accountId == ''){
                List<Opportunity> currSubmission = [Select AccountId From Opportunity
                                                    Where Id =:submissionId];
                if(currSubmission.size() > 0){
                    accountId = currSubmission[0].AccountId;
                }
            }
            
            List<ItemWrapper> resultItems = new List<ItemWrapper>();
            for(Product2 prod : comboProducts){
                ItemWrapper resultItem = new ItemWrapper();
                if(poliMap.containsKey(prod.Id)){
                    resultItem = new ItemWrapper(poliMap.get(prod.Id));
                }
                else{
                    resultItem.Name = prod.Name;
                    //D&O is selected by default
                    if(prod.Name == DandO_CELERITY && poliList.size() == 0){
                        resultItem.Selected = true;
                    }
                    // else if(prod.Name == EPL_CELERITY && poliList.size() == 0){
                    //     resultItem.Selected = true;
                    // }
                    else{
                        resultItem.Selected = false;
                    }
                    
                    resultItem.ProductId = prod.Id;
                    resultItem.SubmissionId = submissionId;
                    resultItem.AccountId = accountId;
                    resultItem.coverages = new List<String>{prod.Munich_LOB_Code__c};
                    resultItem.DisableCheckBox = false;
                    resultItem.Status = null;
                }
                
                resultItems.add(resultItem);
        }


        //Logic to sort products so D&O and EPL show up first in UI.
        List<ItemWrapper> sortedResults = new List<ItemWrapper>();
        List<ItemWrapper> tempResults = new List<ItemWrapper>();
        for(ItemWrapper item : resultItems){
            if(item.Name == 'D&O'){
                if(sortedResults.size() == 0){
                    sortedResults.add(item);
                }
                else{
                    sortedResults.add(0, item);
                }
                
            }
            else if(item.Name == 'EPL'){
                sortedResults.add(item);
            }
            else {
                tempResults.add(item);
            }
        }

        sortedResults.addAll(tempResults);
        return sortedResults;
      }
      catch(Exception ex){
        System.debug('@@@Exception: '+ ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());
        throw new AuraHandledException(CommonUtil.getExceptionMessage(ex) + '' + ex.getLineNumber());
      }
    }

     /**
     * @description : Process clearence for product.
     * @author Vinayesh | 08-02-2021 
     * @param record 
     * @return String 
     **/
     @AuraEnabled(cacheable = false)
     public static String checkClearanceForProduct(string record) {
        ItemWrapper poliRecordWrapper = (ItemWrapper) JSON.deserialize(record, ItemWrapper.class);
        System.debug('vinay clearance check' + poliRecordWrapper);
        //Need to impement callout to clearance service
        //String clearanceStatus = AccountClearanceCallout.sendSubmissionDetails(poliRecordWrapper.AccountId, poliRecordWrapper.Product__c);
        //This code is to randomly mock callout result.
        Integer resCode = (Integer)(Math.random() * 9);
        String clearanceStatus = '';
        if(resCode < 6) clearanceStatus = CLEARED_STATUS;
        if(resCode == 6) clearanceStatus = CLOSED_MARKET_STATUS;
        if(resCode == 7) clearanceStatus = CLEARANCE_NOT_APPLICABLE_STATUS;
        if(resCode == 8) clearanceStatus = SERVICE_FAILED_STATUS;

        return clearanceStatus;
        //return 'Cleared';
    }

     /**
     * @description : Process clearance for products. Currently just mocking clearance service call.
     * Implementation pending.
     * @author Vinayesh | 08-02-2021 
     * @param products 
     * @return List<ItemWrapper> 
     **/
    @AuraEnabled(cacheable = false)
     public static List<ItemWrapper> checkClearanceForProducts(List<ItemWrapper> products) {
        for(ItemWrapper item : products){
            if(item.Name == DandO_CELERITY || item.Name == EPL_CELERITY){
                item.Status = CLEARED_STATUS;
                continue;
            }
            Integer resCode = (Integer)(Math.random() * 3);
            String clearanceStatus = '';
            if(resCode == 0) clearanceStatus = CLOSED_MARKET_STATUS;
            if(resCode == 1) clearanceStatus = CLEARANCE_NOT_APPLICABLE_STATUS;
            if(resCode == 2) clearanceStatus = SERVICE_FAILED_STATUS;
            item.Status = clearanceStatus;
        }

        return products;
        //return 'Cleared';
    }

     /**
     * @description : Save product option lines.
     * @author Vinayesh | 08-02-2021 
     * @param records 
     * @return List<ItemWrapper> 
     **/
    @AuraEnabled(cacheable = false)
     public static List<ItemWrapper> saveProductOptionLines(List<ItemWrapper> records) {
        String accountId;
        List<Opportunity> currSubmission = [Select AccountId From Opportunity
                                            Where Id =:records[0].SubmissionId];
        if(currSubmission.size() > 0){
            accountId = currSubmission[0].AccountId;
        }

        set<String> poliIds = new set<String>();
        for(ItemWrapper item : records){
            if(item.RecordId != null){
                poliIds.add(item.RecordId);
            }
        }
        Map<String, Product_Option_Line_Item__c> poliMap = new Map<String, Product_Option_Line_Item__c>([SELECT Id, Product__c, Product__r.Name, Notes__c, Submission__c, Account__c,
                                                                                                        Clearance_Status__c, Is_Selected__c, IsManualClearance__c FROM Product_Option_Line_Item__c
                                                                                                        WHERE Id in :poliIds]);
        
        
        List<Product_Option_Line_Item__c> poliToUpdate = new List<Product_Option_Line_Item__c>();
        List<Product_Option_Line_Item__c> poliToInsert = new List<Product_Option_Line_Item__c>();

        for(ItemWrapper item : records){
            Product_Option_Line_Item__c poliRec;
                                                  
            if(poliMap.containsKey(item.RecordId)){
                poliRec = poliMap.get(item.RecordId);
                poliRec.Clearance_Status__c = item.Status;
                poliRec.Is_Selected__c = item.Selected;
                poliRec.Notes__c = item.Notes;
                poliRec.IsManualClearance__c = item.ManualClearance;
                poliRec.Account__c = accountId;
                poliToUpdate.add(poliRec);
            }
            else{
                Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
                newRec.Product__c = item.ProductId;
                newRec.Submission__c = item.SubmissionId;
                newRec.Account__c = accountId;
                newRec.Clearance_Status__c = item.Status;
                newRec.Is_Selected__c = item.Selected;
                newRec.Notes__c = item.Notes;
                //newRec.Clearance_Date__c = Datetime.now();
                newRec.Clearance_Date__c = item.ClearanceDate;
                newRec.IsManualClearance__c = false;
                poliToInsert.add(newRec);
            }
        }
        if(poliToInsert.size() > 0){
            insert poliToInsert;
        }
        if(poliToUpdate.size() > 0){
            update poliToUpdate;
        }
        return records;
    }

    //Maybe need to use the saveproductlines method instead of this method.
        @AuraEnabled(cacheable = false)
        public static void saveProductOptionLine(string record) {
            ItemWrapper poliRecordWrapper = (ItemWrapper) JSON.deserialize(record, ItemWrapper.class);
        
            List<Product_Option_Line_Item__c> poliRec =  [SELECT Id, Product__c, Product__r.Name, Notes__c, Submission__c,
                                                            Clearance_Status__c, Is_Selected__c, IsManualClearance__c FROM Product_Option_Line_Item__c
                                                            WHERE Id = :poliRecordWrapper.RecordId];
            
                                                    
            if(poliRec.size() > 0){
                poliRec[0].Clearance_Status__c = poliRecordWrapper.Status;
                poliRec[0].Is_Selected__c = poliRecordWrapper.Selected;
                poliRec[0].Notes__c = poliRecordWrapper.Notes;
                poliRec[0].IsManualClearance__c = poliRecordWrapper.ManualClearance;
                update poliRec[0];
            }
            else{
                Product_Option_Line_Item__c newRec = new Product_Option_Line_Item__c();
                newRec.Product__c = poliRecordWrapper.ProductId;
                newRec.Submission__c = poliRecordWrapper.SubmissionId;
                newRec.Account__c = poliRecordWrapper.AccountId;
                newRec.Clearance_Status__c = poliRecordWrapper.Status;
                newRec.Is_Selected__c = poliRecordWrapper.Selected;
                newRec.IsManualClearance__c = false;
                newRec.Notes__c = poliRecordWrapper.Notes;
                newRec.Clearance_Date__c = Datetime.now();
                insert newRec;
            }

        }

    //Method just for testing. Needs to be removed.
    @AuraEnabled(cacheable = false)
     public static void deletePoliData(string submissionId) {
         system.debug('vinay ' + submissionId);
        List<Product_Option_Line_Item__c> poliRecList =  [SELECT Id From Product_Option_Line_Item__c
                                                          Where Submission__c = :submissionId];
        delete poliRecList;
    }

     //Method just for testing. Needs to be removed.
     @AuraEnabled(cacheable = false)
     public static void deleteExistingRatingModifiers() {
        // List<Rating_Modifiers__c> rtList =  [SELECT Id From Rating_Modifiers__c
        //                                                   Where Opportunity__c = '0062500000NE1XxAAL'];
        // delete rtList;
    }

    /**
    * @description : Check if cleared POLI data available for submission.
    * @author Vinayesh | 08-02-2021 
    * @param submissionId 
    * @return boolean 
    **/
    @AuraEnabled
    public static boolean checkAvailableClearedPoli(string submissionId) {
        try{
            List<Product_Option_Line_Item__c> poliList = new List<Product_Option_Line_Item__c>();
            if(submissionId != null){
                poliList =  [SELECT Id, Product__c, Product__r.Name, Notes__c, Submission__c, Clearance_Date__c,
                             Clearance_Status__c, Is_Selected__c, Account__c, IsManualClearance__c 
                             FROM Product_Option_Line_Item__c
                             WHERE Submission__c = :submissionId];
            }
            
            if(poliList.size() > 0){
                for(Product_Option_Line_Item__c poli : poliList){
                    if(poli.Is_Selected__c){
                        return true;
                    }
                    if(poli.Clearance_Status__c == 'Decline'){
                        List<Rating_Modifiers__c> rtList =  [SELECT Id From Rating_Modifiers__c
                                                             Where Opportunity__c =: submissionId and Product__c =: poli.Product__r.Name];
                        if(rtList.size() > 0) return true;
                    }
                }
            }           
            return false;
        }     
      catch(Exception ex){
        System.debug('@@@Exception: '+ ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());
        throw new AuraHandledException(CommonUtil.getExceptionMessage(ex) + '' + ex.getLineNumber());
      }
    }

    public class ItemWrapper{
        @AuraEnabled public String RecordId {get; set;}
        @AuraEnabled public String ProductId {get; set;}
        @AuraEnabled public String SubmissionId {get; set;}
        @AuraEnabled public String AccountId {get; set;}
		@AuraEnabled public String Name {get; set;}
		@AuraEnabled public String Status {get; set;}
		@AuraEnabled public boolean Selected {get; set;}
        @AuraEnabled public String Notes {get; set;}
        @AuraEnabled public Datetime ClearanceDate {get; set;}
        @AuraEnabled public boolean DisableCheckBox {get; set;}
        @AuraEnabled public boolean ManualClearance {get; set;}
        @AuraEnabled public QuotedRiskLocation locationDetails {get; set;}
        @AuraEnabled public String submissionAzureId {get; set;}
        @AuraEnabled public List<String> coverages {get; set;}
        @AuraEnabled public Date quoteEffectiveDate {get; set;}
        @AuraEnabled public String modelId {get; set;}
        @AuraEnabled public String accountName {get; set;}
        public ItemWrapper(){
            //
            System.debug('Empty Con');
        }
        public ItemWrapper(Product_Option_Line_Item__c poli) {
            RecordId = poli.Id;
            ProductId = poli.Product__c;
            SubmissionId = poli.Submission__c;
            AccountId = poli.Account__c;
            Name = poli.Product__r.Name;
			Status = poli.Clearance_Status__c;
            Selected = poli.Is_Selected__c;
            Notes = poli.Notes__c;
            ClearanceDate = poli.Clearance_Date__c;
            DisableCheckBox = false;
            ManualClearance = poli.IsManualClearance__c;

            locationDetails = new QuotedRiskLocation();
            locationDetails.City = poli.Account__r.BillingCity;
            locationDetails.State = poli.Account__r.BillingState;
            locationDetails.StreetAddress = poli.Account__r.BillingStreet;
            locationDetails.ZipCode = poli.Account__r.BillingPostalCode;
            submissionAzureId = poli.Submission__r.Azure_ID__c;
            coverages = new List<String>{poli.Product__r.Munich_LOB_Code__c};
            modelId = poli.Product__r.Model_ID__c;
            accountName = poli.Account__r.Name;
        }

    }
    public class QuotedRiskLocation {
        public String ZipCode;
        public String State;
        public String City;
        public String StreetAddress;
    }
}