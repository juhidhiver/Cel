/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 08-26-2021
 * @last modified by  : Maeran Shaikh
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   07-18-2021   Maeran Shaikh   Initial Version
**/
public without sharing class productSelectionController {

    @AuraEnabled(cacheable=true)
    public static List<Product_Selection__mdt> getProductsForSelection(){
        try {
            return [Select Id,MasterLabel,Component_Name__c,Code__c,Picture_URL__c, Sort_Order__c,Quote_Process_Record_Type__c, Icon_Name__c from Product_Selection__mdt Order by Sort_Order__c ASC];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
    * @description : Used to create a placeholder Opp for PCC start step
    * @author Maeran Shaikh | 08-24-2021 
    * @return string 
    **/
    @AuraEnabled
    public static string insertPlaceholderSubmission(String prodName){

        Product2 prd = [Select Id,name from Product2 where Name =:prodName LIMIT 1 ];
        try {
            Opportunity tbdOpp = new Opportunity();
            tbdOpp.Name='To be defined';
            tbdOpp.CloseDate = date.today().addYears(1);
            tbdOpp.StageName = 'New';
            tbdOpp.Product__c = prd.id;
            insert tbdOpp;
            return tbdOpp.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }



    // @AuraEnabled 
    // public static string createQuoteProcessPcc(String recordTypeName,String productName, String oppId){
    //     return CreateQuoteProcess.insertQuoteForPCC(recordTypeName,productName,oppId);
    //    // return insertQuote2(recordTypeName,productName);
	// }


    /**
    * @description Will delete all Opps created before x minutes
    * @author Maeran Shaikh | 08-26-2021 
    **/
    @AuraEnabled
    public static string deletePlaceholderOppsAndGetProdId(String prodName){
        try {
            List<Opportunity> lstOpp= [select Id,name from Opportunity where CreatedDate < :Datetime.now().addMinutes(-10) and Name like 'To be defined%'];
            if(!lstOpp.isEmpty()){
                delete lstOpp;
            }
 
        } catch (Exception e) {
            System.debug('Error deleting Opps-->'+e.getMessage());
        }

        Product2 prod = [Select Id from Product2 where Name=:prodName];
        return prod.Id;
    }
}