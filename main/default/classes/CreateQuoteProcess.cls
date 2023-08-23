/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 08-24-2021
 * @last modified by  : Maeran Shaikh
 * Modifications Log 
 * Ver   Date         Author     Modification
 * 1.0   07-20-2021   Vinayesh   Initial Version
**/
public without sharing class CreateQuoteProcess {
    
    public static String insertQuote(String recordTypeName,String productName){
        try{
            List<Quote_Process__c> quoteProcess = [SELECT Id, Status__c,Record_Type__c,Product__c 
                                                   FROM Quote_Process__c WHERE Account__c = NULL AND Submission__c = NULL LIMIT 1];
            delete quoteProcess;
            
            Quote_Process__c obj =  new Quote_Process__c();
            obj.Record_Type__c = recordTypeName;
            obj.Product__c = productName;
            //Added by Vinayesh- Submission Console
            if(productName == 'Private Company Combo'){
                obj.Status__c = 'Submission Console';
            }
            insert obj;
            return obj.Id;
        }
        catch(Exception ex){
            system.debug('Excep: '+ex.getMessage());
            return null;
        }
    }
    
    /**
    * @description Inserted to accomodate Opp for Quote process
    * @author Maeran Shaikh | 08-24-2021 
    * @param recordTypeName 
    * @param productName 
    * @param oppId 
    * @return String 
    **/
    public static String insertQuoteForPCC(String recordTypeName,String productName, String oppId){
        try{
            List<Quote_Process__c> quoteProcess = [SELECT Id, Status__c,Record_Type__c,Product__c 
                                                   FROM Quote_Process__c WHERE Account__c = NULL AND Submission__c = NULL LIMIT 1];
            delete quoteProcess;
            
            Quote_Process__c obj =  new Quote_Process__c();
            obj.Record_Type__c = recordTypeName;
            obj.Product__c = productName;
            obj.Submission__c = oppId;
            //Added by Vinayesh- Submission Console
            if(productName == 'Private Company Combo'){
                obj.Status__c = 'Submission Console';
            }
            insert obj;
            return obj.Id;
        }
        catch(Exception ex){
            system.debug('Excep: '+ex.getMessage());
            return null;
        }
    }
}