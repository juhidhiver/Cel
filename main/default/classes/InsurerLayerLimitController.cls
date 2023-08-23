public with sharing class InsurerLayerLimitController {
    
    @AuraEnabled
    public static List<Insurer_Layer_Limit__c> getInsurerLayer(String quoteId){
        List<Insurer_Layer_Limit__c> insurerlist = new List<Insurer_Layer_Limit__c>();
        insurerlist = [SELECT Id, Layer__c, Quote__c, Insurer__c, Insurer_Layer_Limit__c, Insurer_Policy_Number__c,currencyIsoCode
                       FROM Insurer_Layer_Limit__c where Quote__c =: quoteId ORDER By CreatedDate ASC];
        return insurerlist;   
    }
    
    @AuraEnabled
    public static decimal fetchInsurerLimit(String quoteId){
        Decimal totalUnderlying = [SELECT Id, Total_Underlying_Layer__c FROM Quote WHERE Id  = :quoteId Limit 1].Total_Underlying_Layer__c;
        return totalUnderlying;  
    }
    
    @AuraEnabled
    public static void saveInsurerLayer(List<Insurer_Layer_Limit__c> insurerList){
        List<Insurer_Layer_Limit__c> addinsurerlist = new List<Insurer_Layer_Limit__c>();
        List<Insurer_Layer_Limit__c> updateinsurerlist = new List<Insurer_Layer_Limit__c>();
        system.debug('insurerList-->'+insurerList);
        for(Insurer_Layer_Limit__c insurer : insurerList){
            if(string.isNotBlank(insurer.Id)){
                updateinsurerlist.add(insurer);
            }
            else if(string.isBlank(insurer.Id)){
                addinsurerlist.add(insurer);
            }
        }
        if(!updateinsurerlist.isEmpty()){
            update updateinsurerlist;
        }
        if(!addinsurerlist.isEmpty()){
            insert addinsurerlist;
        }
    }
    
    @AuraEnabled
    public static void deleteInsurer(String insurerId){
        List<Insurer_Layer_Limit__c> insurerlist = new List<Insurer_Layer_Limit__c>();
        insurerlist = [SELECT Id, Layer__c, Quote__c, Insurer__c, Insurer_Layer_Limit__c, Insurer_Policy_Number__c
                       FROM Insurer_Layer_Limit__c where Id =: insurerId];
        if(!insurerlist.isEmpty()){
            delete insurerlist;
        }
        
    }
}