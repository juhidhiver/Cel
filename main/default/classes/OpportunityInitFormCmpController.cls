/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 11-03-2021
 * @last modified by  : Vinayesh
**/
public with sharing class OpportunityInitFormCmpController {
    
    @AuraEnabled (cacheable=true)
    public static List<RecordType> getOpportunityRecordType() {
        return [SELECT Id,Name FROM RecordType WHERE SobjectType='Opportunity' AND ISActive = true];
    }
    
    @AuraEnabled (cacheable=true)
    public static string getDefaultRecordType(String quoteProcessId) {
        String recordTypeName = [SELECT Id,Record_Type__c FROM Quote_Process__c WHERE Id  = :quoteProcessId Limit 1].Record_Type__c;
        RecordType recordType = [select Id,Name from RecordType where SobjectType='Opportunity' And Name =: recordTypeName];
        return recordType.Id + '__' + recordType.Name;
    }
    
    @AuraEnabled(cacheable = true)
    public static String getDefaultProduct(String quoteProcessId){
        String defaultProductName = [SELECT Id,Record_Type__c,Product__c FROM Quote_Process__c WHERE Id  = :quoteProcessId][0].Product__c;
        List<Product2> lstProduct = [SELECT Id,Name FROM Product2 WHERE Name = :defaultProductName AND IsActive=true];
        return lstProduct.isEmpty() ? '' : lstProduct[0].Id;  
    }

    @AuraEnabled
    public static List<PicklistOption> getPicklistValues(String fieldName, string recordType){
        return CommonUtil.getPicklistValueByRecordType('Opportunity', fieldName, recordType);
    }
    
    @AuraEnabled
    public static String getSubmissionName(String accountId, String productId){
        string submissionName;
        List<Account> accountName = [SELECT Id,Name FROM Account WHERE Id  = :accountId];
        List<Product2> productName = [SELECT Id,Name FROM Product2 WHERE Id = :productId];
        if(!accountName.isEmpty())
            submissionName = accountName[0].Name + ' '+'PI'+ ' '+date.today().format();
        return submissionName;        
    }
    
    @AuraEnabled 
    public static GenerateResult getOpportunityInfo(String accId, String productId) {
        GenerateResult result =  new GenerateResult();
        String oppName = '';
        Account acc = [SELECT   Name, 
                       AnnualRevenue, 
                       Cash_Flow_From_Operating_Activities__c, 
                       Current_Assets__c,
                       Current_Liabilities__c,
                       Long_Term_Debt__c,
                       Net_Income__c,
                       Retained_Earnings__c,
                       Shareholders_Equity__c,
                       Total_Assets__c,
                       Total_Liabilities__c,
                       Total_Revenues__c 
                       FROM Account WHERE Id =:accId limit 1];               
        if (String.isNotBlank(acc.Name)) oppName = acc.Name;
        
        if(String.isNotBlank(productId)){
            Product2 prod = [SELECT Name FROM Product2 Where Id =:productId limit 1];
            if (String.isNotBlank(prod.Name))  oppName = oppName +' '+ prod.Name;
            
            //system.debug('prod'+prod);
        }
        //system.debug('acc'+acc);
        
        AccountWrapper accWrapper = new AccountWrapper();
        accWrapper.AnnualRevenue = getString(acc.AnnualRevenue);
        accWrapper.CashFlowFromOperatingActivities = getString(acc.Cash_Flow_From_Operating_Activities__c);
        accWrapper.CurrentAssets = getString(acc.Current_Assets__c);
        accWrapper.CurrentLiabilities = getString(acc.Current_Liabilities__c);
        accWrapper.LongTermDebt = getString(acc.Long_Term_Debt__c);
        accWrapper.NetIncome = getString(acc.Net_Income__c);
        accWrapper.RetainedEarnings = getString(acc.Retained_Earnings__c);
        accWrapper.ShareholdersEquity = getString(acc.Shareholders_Equity__c);
        accWrapper.TotalAssets = getString(acc.Total_Assets__c);
        accWrapper.TotalLiabilities = getString(acc.Total_Liabilities__c);
        accWrapper.TotalRevenues = getString(acc.Total_Revenues__c);
        
        result.accInf = accWrapper;
        result.oppName = oppName;
        system.debug('accWrapper'+accWrapper);
        return result;
    }
    private static String getString(Object str){
        return str == null ? '' :  String.ValueOf(str);//(String)str;
    }
    
    @AuraEnabled 
    public static Opportunity getInfo(String id) {
        return [SELECT Id,Name,AccountId,Coverage_Product_Options__c,Effective_Date__c,Expiration_Date__c,CloseDate  
                FROM Opportunity WHERE Id=: id limit 1];
    }
    
    public class GenerateResult {
        @AuraEnabled
        public AccountWrapper accInf  	{get; set;}
        @AuraEnabled
        public String oppName  	        {get; set;}
    }  
    
    public class AccountWrapper {
        @AuraEnabled  public String AnnualRevenue   	            {get; set;}
        @AuraEnabled  public String CashFlowFromOperatingActivities  	{get; set;}
        @AuraEnabled  public String CurrentAssets 	{get; set;}
        @AuraEnabled  public String CurrentLiabilities   	{get; set;}
        @AuraEnabled  public String LongTermDebt   	{get; set;}
        @AuraEnabled  public String NetIncome   	{get; set;}
        @AuraEnabled  public String RetainedEarnings   	{get; set;}
        @AuraEnabled  public String ShareholdersEquity   	{get; set;}
        @AuraEnabled  public String TotalAssets   	{get; set;}
        @AuraEnabled  public String TotalLiabilities   	{get; set;}
        @AuraEnabled  public String TotalRevenues   	{get; set;}
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldNameOpportunity(){
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get('Opportunity').getDescribe().fields.getMap();
        List<String> apiNames =  new list<String>();
        for(Schema.SObjectField sfield : fieldMap.Values()){
            apiNames.add(sfield.getDescribe().getName());
        }
        return apiNames;
    }
    
    public class ValidateResult {
        @AuraEnabled
        public Boolean status  	{get; set;}
        @AuraEnabled
        public String oppId  	{get; set;}
        @AuraEnabled
        public String errorMessage 	        {get; set;}
        @AuraEnabled
        public List<ItemWrapper> oppList {get; set;}
        @AuraEnabled
        public Boolean showDuplicateList	{get; set;}
        @AuraEnabled
        public String duplicatePopUptitle	{get; set;}
        @AuraEnabled
        public String diffAgencyPopUptitle	{get; set;}
        @AuraEnabled
        public Boolean isShowDuplicate	{get; set;}
        @AuraEnabled
        public Boolean isShowDiffAgency	{get; set;}
        @AuraEnabled
        public List<ItemWrapper> oppAgencyList	{get; set;}
    } 
    
    /*************************************************
* Author: Hoang Bui
* Date: 09-Jun-2020
* Params: String accountId, String productId, String contactId, Boolean brokerBlockOverride
* Return: 
* Description: validateOpportunity follow the UserStory #2750
* Revision: 
*************************************************/
    /*@AuraEnabled(cacheable=true)
public static ValidateResult validateOpportunity(String accountId, String productId, String contactId, Boolean brokerBlockOverride, String attachmentPoint){
ValidateResult result =  new ValidateResult();
if(attachmentPoint == 'Primary'){
system.debug('attachmentPoint'+attachmentPoint);
system.debug('brokerBlockOverride'+brokerBlockOverride);    
List<Opportunity> oppList = [SELECT Id,Name,StageName,Policy__r.Expiration_Date__c, 
CreatedDate, Policy__c,
(SELECT Opportunity__c,Broker_Contact__c 
FROM Opportunity_Accounts1__r 
WHERE IsPrimaryBroker__c = true) 
FROM Opportunity 
WHERE AccountId =:accountId
And Product__c =:productId  

];
system.debug('oppList='+oppList);
Boolean isDuplicate = false;
for(Opportunity opp: oppList){
if(opp.Opportunity_Accounts1__r != null && !opp.Opportunity_Accounts1__r.isEmpty()) {
for(Broker_Account__c broAcc : opp.Opportunity_Accounts1__r) {
if(broAcc.Broker_Contact__c == contactId){ //same accc+ product+ broker
result.status = false;
result.oppId = opp.Id;//return oppid for redirect to exist opp
return result; 
}
}               
isDuplicate = true;//same accc+ product, different broker
}
}

if (isDuplicate && !brokerBlockOverride) {//isduplicate & not OVerride check
result.status = false;
result.errorMessage = Label.BROCKER_ACCOUNT_DUPLICATE_OPPT_INTERNAL_CLEARANCE_MSG;
return result;                   
}
} 
result.status = true;
return result; 

}
*/
    
    //Commented for US-40361
/*  @AuraEnabled(cacheable=true) 
    public static ValidateResult validateOpportunity(String accountId, String productId, String contactId, String attachmentPoint){
        ValidateResult result =  new ValidateResult(); 
        string isAqueous;
        List<Product2> product = [select Id, RecordType.Name from Product2 where Id =:productId];
        if(!product.isEmpty())isAqueous = product[0].RecordType.Name;
        system.debug('isAqueous: '+isAqueous);
        if(attachmentPoint == 'Primary'|| attachmentPoint == 'Excess' || ( attachmentPoint == '' && isAqueous == Label.Aqueous_RT)){
            List<Broker_Account__c> brokerAccs = [SELECT Broker_Contact__r.AccountId FROM Broker_Account__c 
                                                  WHERE Broker_Contact__c =: contactId
                                                  AND IsPrimaryBroker__c = true
                                                  LIMIT 1];
            Broker_Account__c brokerAcc;
            if (!brokerAccs.isEmpty()) 
                brokerAcc = brokerAccs[0];
            
            String agencyId = brokerAcc != null ? brokerAcc.Broker_Contact__r.AccountId : null;
            system.debug('agencyId='+agencyId);   
            List<String> stageNames = new List<String>{'New','Qualified','Prospect'};
                List<Opportunity> oppList = new List<Opportunity>();
            if(attachmentPoint == 'Excess'){
                oppList = [SELECT Id,Name,StageName,Policy__r.Expiration_Date__c,
                           CreatedDate, Policy__c, Agency__c,
                           Product_Name__c, Effective_Date__c, Expiration_Date__c
                           FROM Opportunity 
                           WHERE AccountId =: accountId
                           AND Product__c =: productId 
                           AND Agency__c =: agencyId
                           AND (Type = 'New Business' OR Type = 'Renewal')
                           AND Attachment_Point__c = 'Excess'
                           AND (StageName IN :stageNames
                                OR (StageName = 'Closed Won' AND Policy__r.Policy_Status__c = 'Bound' AND Expiration_Date__c > TODAY))
                           ORDER BY CreatedDate Desc];
            }
            else
            {
                oppList = [SELECT Id,Name,StageName,Policy__r.Expiration_Date__c,
                           CreatedDate, Policy__c, Agency__c,
                           Product_Name__c, Effective_Date__c, Expiration_Date__c
                           FROM Opportunity 
                           WHERE AccountId =:accountId
                           AND Product__c =:productId 
                           AND Type = 'New Business'
                           AND (Attachment_Point__c = 'Primary' OR Attachment_Point__c = '')
                           AND (StageName IN :stageNames
                                OR (StageName = 'Closed Won' AND Policy__r.Policy_Status__c = 'Bound' AND Expiration_Date__c > TODAY))
                           ORDER BY CreatedDate Desc];
            }
            system.debug('oppList='+oppList);
            Boolean isDuplicate = false;
            for(Opportunity opp : oppList) {
                if(opp.Agency__c == agencyId){ //same accc+ product+ agency
                    //There could be one New Business Submission where the Policy is still in effect (Expiration Date > today()) 
                    //and there could also be a Renewal Submission that was created before the Expiration Date of the Policy.
                    List<Opportunity> renewalOpp = new List<Opportunity>();
                    if(opp.Policy__c != null) {
                        Date policyExpirationDate = opp.Policy__r.Expiration_Date__c; 
                        renewalOpp = [SELECT Id, CreatedDate FROM Opportunity 
                                      WHERE Type = 'Renewal'
                                      AND CreatedDate < :policyExpirationDate
                                      AND Parent_Opportunity__c =: opp.Id
                                      ORDER BY CreatedDate Desc];
                    }                                               
                    result.status = false;            
                    result.oppId = !renewalOpp.isEmpty()? renewalOpp[0].Id : opp.Id;//return renewal opportunity Id or new business opportunity Id for redirect to exist opp
                    if(attachmentPoint == 'Excess' || attachmentPoint == '')
                    {
                        result.showDuplicateList = true;
                        result.oppId = opp.Id;
                    }
                    
                    result.errorMessage = Label.SUBMISSION_DUPLICATED_CONFIRM_REDIRECT_MSG;
                    result.oppList = oppList;
                    system.debug('result::'+result);
                    return result; 
                } 
                isDuplicate = true;//same accc+ product, different broker 

                //for Aqueous - different broker will work as same broker - show potential duplicates without Closed Lost
                //if(isAqueous == Label.Aqueous_RT && isDuplicate)    {
                    //result.showDuplicateList = true;
                    //result.errorMessage = Label.SUBMISSION_DUPLICATED_CONFIRM_REDIRECT_MSG;
                    //result.oppList = oppList;
                    //result.status = true;
                    //return result;
                //}
            }
            
            //if (isDuplicate && attachmentPoint != 'Excess' && isAqueous != Label.Aqueous_RT) {//isduplicate & not OVerride check
            if (isDuplicate && attachmentPoint != 'Excess') {
                result.status = false;
                result.errorMessage = Label.SUBMISSION_DUPLICATED_CONFIRM_CREATE_MSG;
                return result;                   
            }
        }
        result.status = true;
        return result; 
    }*/
    
   /*  @AuraEnabled(cacheable=true)
    public static ValidateResult validateOpportunity(String accountId, String productId, String contactId, String attachmentPoint){
        system.debug('attachmentPoint='+attachmentPoint);
        ValidateResult result =  new ValidateResult(); 
        string isAqueous;
        List<Product2> product = [select Id, RecordType.Name from Product2 where Id =:productId];
        if(!product.isEmpty())isAqueous = product[0].RecordType.Name;
        if(attachmentPoint == ''){
            List<Broker_Account__c> brokerAccs = [SELECT Broker_Contact__r.AccountId FROM Broker_Account__c 
                                                  WHERE Broker_Contact__c =: contactId
                                                  AND IsPrimaryBroker__c = true
                                                  LIMIT 1];
            Broker_Account__c brokerAcc;
            if (!brokerAccs.isEmpty()) 
                brokerAcc = brokerAccs[0];
            
            String agencyId = brokerAcc != null ? brokerAcc.Broker_Contact__r.AccountId : null;
            List<String> stageNames = new List<String>{'New','Qualified','Prospect'};
                List<Opportunity> oppList = new List<Opportunity>();
          
                oppList = [SELECT Id,Name,StageName,Policy__r.Expiration_Date__c,
                           CreatedDate, Policy__c, Agency__c,
                           Product_Name__c, Effective_Date__c, Expiration_Date__c
                           FROM Opportunity 
                           WHERE AccountId =:accountId
                           AND Product__c =:productId 
                           AND (Type = 'New Business' OR Type = 'Renewal')
                           AND Attachment_Point__c = '' 
                           AND (StageName IN :stageNames
                                OR (StageName = 'Closed Won' AND Policy__r.Policy_Status__c = 'Bound' AND Expiration_Date__c > TODAY))
                           ORDER BY CreatedDate Desc];
            
            system.debug('oppList='+oppList);
            Boolean isDuplicate = false;
            for(Opportunity opp : oppList) {
                if(opp.Agency__c == agencyId){ //same accc+ product+ agency
                    //There could be one New Business Submission where the Policy is still in effect (Expiration Date > today()) 
                    //and there could also be a Renewal Submission that was created before the Expiration Date of the Policy.
                    List<Opportunity> renewalOpp = new List<Opportunity>();
                    if(opp.Policy__c != null) {
                        Date policyExpirationDate = opp.Policy__r.Expiration_Date__c; 
                        renewalOpp = [SELECT Id, CreatedDate FROM Opportunity 
                                      WHERE Type = 'Renewal'
                                      AND CreatedDate < :policyExpirationDate
                                      AND Parent_Opportunity__c =: opp.Id
                                      ORDER BY CreatedDate Desc];
                    }                                               
                    result.status = false;            
                    result.oppId = !renewalOpp.isEmpty()? renewalOpp[0].Id : opp.Id;//return renewal opportunity Id or new business opportunity Id for redirect to exist opp

                    if(attachmentPoint == '')
                    {
                        result.showDuplicateList = true;
                        result.oppId = opp.Id;
                    }
                    
                    result.errorMessage = Label.SUBMISSION_DUPLICATED_CONFIRM_REDIRECT_MSG;
                    result.oppList = oppList;
                    system.debug('result::'+result);
                    return result; 
                } 
                isDuplicate = true;//same accc+ product, different broker 
            }

            if (isDuplicate) {
                result.status = false;
                result.errorMessage = Label.SUBMISSION_DUPLICATED_CONFIRM_CREATE_MSG;
                return result;                   
            }
        }
        result.status = true;
        return result; 
    }*/
    
   @AuraEnabled(cacheable=true)
    public static ValidateResult validateOpportunity(String accountId, String productId, String contactId, String attachmentPoint){
         ValidateResult result =  new ValidateResult(); 

        List<Contact> brokerAccs = [select Id, AccountId from Contact where Id =: contactId LIMIT 1];
        String agencyId = brokerAccs != null ? brokerAccs[0].AccountId : null;
        system.debug('agencyId='+agencyId);
       
        List<String> stageNames = new List<String>{'New','Qualified','Prospect'};
            List<Opportunity> oppList = new List<Opportunity>();
        
        
        oppList = [SELECT Id, Account.Name, Name, Agency__r.Name ,Effective_Date__c, StageName,
                   Policy__r.Expiration_Date__c,
                   CreatedDate, Policy__c, Agency__c,
                   Product_Name__c, Expiration_Date__c,
                   (SELECT Broker_Name__c FROM Opportunity_Accounts1__r Where IsPrimaryBroker__c = true LIMIt 1) 
                   FROM Opportunity 
                   WHERE AccountId =:accountId
                   AND Product__c =:productId 
                   //AND Agency__c =: agencyId 
                   AND (Type = 'New Business' OR Type = 'Renewal')
                   AND (StageName IN :stageNames
                        OR (StageName = 'Closed Won' AND Policy__r.Policy_Status__c = 'Bound' AND Expiration_Date__c > TODAY))
                   ORDER BY CreatedDate Desc];
        
        system.debug('oppList='+oppList);
        Boolean isExist = false;
       
        
        List<ItemWrapper> duplicatOpp = new List<ItemWrapper>();
        List<ItemWrapper> differentAgency = new List<ItemWrapper>();
        
        
        if(!oppList.isEmpty()){
          //  Broker_Account__c broker = oppList.Opportunity_Accounts1__r[0];
            for(Opportunity opp : oppList) {
                if(opp.Agency__c == agencyId){ //same accc+ product+ agency
                    ItemWrapper item = new ItemWrapper();
                    item.Id = opp.Id;
                    item.Name = opp.Name;
                    item.Product_Name = opp.Product_Name__c;
                    item.Effective_Date = opp.Effective_Date__c;
                    item.Expiration_Date = opp.Expiration_Date__c;
                    item.StageName = opp.StageName;
                    item.Account_Name = opp.Account.Name;
                    item.Broker_Agency = opp.Agency__r.Name;
                    if(!opp.Opportunity_Accounts1__r.isEmpty()){
                        item.Broker_Producer =  opp.Opportunity_Accounts1__r[0].Broker_Name__c;
                    } 
                    duplicatOpp.add(item); 
                    result.oppId = opp.Id;
                } 
                else  //same accc+ product, different broker 
                {
                    ItemWrapper item = new ItemWrapper();
                    item.Id = opp.Id;
                    item.Name = opp.Name;
                    item.Product_Name = opp.Product_Name__c;
                    item.Effective_Date = opp.Effective_Date__c;
                    item.Expiration_Date = opp.Expiration_Date__c;
                    item.StageName = opp.StageName;
                    item.Account_Name = opp.Account.Name;
                    item.Broker_Agency = opp.Agency__r.Name;
                    if(!opp.Opportunity_Accounts1__r.isEmpty()){
                        item.Broker_Producer =  opp.Opportunity_Accounts1__r[0].Broker_Name__c;
                    } 
                    differentAgency.add(item);
                    result.oppId = opp.Id;
                }
            }
        }
            
        if(differentAgency.size() > 0)
        {
            isExist = true;
            result.isShowDiffAgency = true;
            result.status = false;
            result.showDuplicateList = true;
            result.diffAgencyPopUptitle  = Label.SUBMISSION_EXIST_FOR_DIFFERENT_BROKER;
            //result.errorMessage = Label.SUBMISSION_DUPLICATED_CONFIRM_CREATE_MSG;//different broker
            result.oppAgencyList = differentAgency;
        }
        
     if(duplicatOpp.size() > 0)
        { 
            isExist = true;
            result.isShowDuplicate = true;
            result.status = false;
            result.showDuplicateList = true;
            result.duplicatePopUptitle  = Label.SUBMISSION_EXIST_FOR_SAME_BROKER;
            //result.errorMessage = Label.SUBMISSION_DUPLICATED_CONFIRM_REDIRECT_MSG;//same broker
            result.oppList = duplicatOpp;
        }
        if(isExist){
            return result; 
        }

        result.status = true;
        return result; 
    }
    
    public class ItemWrapper{
        @AuraEnabled public String Id {get; set;}
		@AuraEnabled public String Name {get; set;}
        @AuraEnabled public String Product_Name {get; set;}
		@AuraEnabled public Date Effective_Date {get; set;}
		@AuraEnabled public Date Expiration_Date {get; set;}
		@AuraEnabled public String StageName {get; set;}
        @AuraEnabled public String Account_Name {get; set;}
        @AuraEnabled public String Broker_Agency {get; set;}
        @AuraEnabled public String Broker_Producer {get; set;}
        public ItemWrapper() {
            Id = '';
            Name = '';
			Product_Name = '';
			Effective_Date = null;
			Expiration_Date = null;
            StageName = '';
			Account_Name = '';
            Broker_Agency = '';
            Broker_Producer = '';
        }
	}
    @AuraEnabled
    public static Product2 fetchProductName(String productId){
        return [SELECT Id,Name FROM Product2 WHERE Id = :productId];
    }
}