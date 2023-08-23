/**
 * @File Name          : QuoteProcessLWCController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Vinayesh
 * @Last Modified On   : 09-02-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/2/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class QuoteProcessLWCController {

    public static final String DEFAULT_SUBMISSION_NAME_FOR_PCC = System.Label.DEFAULT_SUBMISSION_NAME_PCC;

	@AuraEnabled
	public static List<ItemWrapper> fletchData(Integer offset, Integer recordNumber, Boolean isInit){
		List<ItemWrapper> items = new List<ItemWrapper>();
   		String queryString  = 'SELECT Id, Name,Product_Name__c, Amount, Effective_Date__c, Expiration_Date__c, StageName, LeadSource, CreatedDate,(select Id from Quote_Process__r Limit 1) FROM Opportunity LIMIT :recordNumber';
   		Integer customOffset = recordNumber * offset;
   		if(!isInit) {
      		queryString += ' offset :customOffset';
   		}
		for (Opportunity opp : (List<Opportunity>) Database.query(queryString)){
                if(opp.Name == DEFAULT_SUBMISSION_NAME_FOR_PCC) continue;
				ItemWrapper item = new ItemWrapper();
				List<Quote_Process__c> lstQp = opp.Quote_Process__r;
				item.QpId = lstQp.isEmpty() ? '' : lstQp[0].Id;
				item.Id = opp.Id;
				item.Name = opp.Name;
				item.CreatedDate = opp.CreatedDate;
				item.Product_Name = opp.Product_Name__c;
				item.Amount = opp.Amount;
				item.Effective_Date = opp.Effective_Date__c;
				item.Expiration_Date = opp.Expiration_Date__c;
				item.StageName = opp.StageName;
				item.LeadSource = opp.LeadSource;
				items.add(item);
			}
		return items;
	}


    public static String insertQuote2(String recordTypeName,String productName){
        try {           
			List<Quote_Process__c> lstQp = [SELECT Id, Status__c,Record_Type__c,Product__c 
                                            FROM Quote_Process__c 
                                            WHERE Account__c = NULL AND Submission__c = NULL LIMIT 1];
			
            if(lstQp.isEmpty()){
				Quote_Process__c obj =  new Quote_Process__c();
                obj.Record_Type__c = recordTypeName;
                obj.Product__c = productName;
				insert obj;
				return obj.Id;
            }else {
                Quote_Process__c obj =  lstQp[0];
                if(obj.Status__c =='Insured Info') {
                    obj.Record_Type__c = recordTypeName;
                    obj.Product__c = productName;
                    update obj;
                }
                if(obj.Status__c !='Insured Info'){
                    obj.Status__c ='Insured Info';
                    update obj;
                } 
                return obj.Id;
            }
            
        }catch (Exception ex) {
            system.debug('Exception: '+ex.getMessage());
            return null;
        }
	}
	

    @AuraEnabled 
    public static string createQuoteProcess(String recordTypeName,String productName){
        return CreateQuoteProcess.insertQuote(recordTypeName,productName);
       // return insertQuote2(recordTypeName,productName);
	}
	
	public static string addAccountToQuoteProcess(String quoteProcessId,String accountId){
		try {
			List<Quote_Process__c> lstQp = [SELECT Id, Status__c FROM Quote_Process__c WHERE Id = :quoteProcessId AND Submission__c = NULL LIMIT 1];
			if(!lstQp.isEmpty()){
				Quote_Process__c obj =  lstQp[0];
				obj.Account__c = accountId;
				update obj;
				System.debug('addAccount '+obj);
				return obj.Id;
			}else return null;
            
        }catch (Exception ex) {
            return null;
        }
	}
    @AuraEnabled 
    public static string addAccount(String quoteProcessId, String accountId){
         return addAccountToQuoteProcess(quoteProcessId,accountId);
    }

    //Lightning Web Components get List Opportunity
    @AuraEnabled(cacheable=true)
    public static List<ItemWrapper> getOpportunityList() {
        List<ItemWrapper> resultList = new List<ItemWrapper>();
		for (Opportunity opp : [SELECT Id, Name, CreatedDate, Product_Name__c, Amount,
								Effective_Date__c, Expiration_Date__c, StageName, LeadSource,
								(select Id from Quote_Process__r Limit 1) FROM Opportunity])
		{
			List<Quote_Process__c> lstQp = opp.Quote_Process__r;
			ItemWrapper item = new ItemWrapper();
			item.Id = opp.Id;
			item.QpId = lstQp.isEmpty() ? '' : lstQp[0].Id;
			item.Name = opp.Name;
			item.CreatedDate = opp.CreatedDate;
			item.Product_Name = opp.Product_Name__c;
			item.Amount = opp.Amount;
			item.Effective_Date = opp.Effective_Date__c;
			item.Expiration_Date = opp.Expiration_Date__c;
			item.StageName = opp.StageName;
			item.LeadSource = opp.LeadSource;
			resultList.add(item);
	    }
	    return resultList;
	}
	
	//Search Opportunity
	@AuraEnabled( cacheable = true )  
    public static List<ItemWrapper> fetchOpportunity(String searchKey, String objectName, String accId, Integer recordNumber) {
		String strKey = '%' + searchKey + '%';
		String queryString = '';
		if(String.isNotBlank(searchKey)){
			queryString = 'SELECT Id, Name, CreatedDate, Product_Name__c, Amount,Effective_Date__c, Expiration_Date__c, StageName, LeadSource,(select Id from Quote_Process__r Limit 1) FROM Opportunity WHERE Name LIKE: strKey LIMIT 10';
		}else{
			if(objectName == 'Account' && String.isNotBlank(accId)) {
				queryString = 'SELECT Id, Name, CreatedDate, Product_Name__c, Amount,Effective_Date__c, Expiration_Date__c, StageName, LeadSource,(select Id from Quote_Process__r Limit 1) FROM Opportunity WHERE AccountId = : accId';
			}else{
				queryString = 'SELECT Id, Name, CreatedDate, Product_Name__c, Amount,Effective_Date__c, Expiration_Date__c, StageName, LeadSource,(select Id from Quote_Process__r Limit 1) FROM Opportunity LIMIT : recordNumber';
			}
		}
		System.debug('String' + queryString);

		//return [ SELECT Id, Name FROM Opportunity WHERE Name LIKE: strKey LIMIT 10 ];
		List<ItemWrapper> resultList = new List<ItemWrapper>();
		for (Opportunity opp :(List<Opportunity>) Database.query(queryString))
		{
			List<Quote_Process__c> lstQp = opp.Quote_Process__r;
			ItemWrapper item = new ItemWrapper();
			item.Id = opp.Id;
			item.QpId = lstQp.isEmpty() ? '' : lstQp[0].Id;
			item.Name = opp.Name;
			item.CreatedDate = opp.CreatedDate;
			item.Product_Name = opp.Product_Name__c;
			item.Amount = opp.Amount;
			item.Effective_Date = opp.Effective_Date__c;
			item.Expiration_Date = opp.Expiration_Date__c;
			item.StageName = opp.StageName;
			item.LeadSource = opp.LeadSource;
			resultList.add(item);
	    }
		System.debug('resultList' + resultList);
	    return resultList;
	}
	
	@AuraEnabled(cacheable=true)
    public static List<ItemWrapper1> getPolicyList(String searchKeyPol) {
        
        List<Opportunity> lstOpp = [SELECT Id,Policy__c,Name,Product_Name__c, Amount, Effective_Date__c, Expiration_Date__c, StageName, LeadSource, CreatedDate,
                            (select Id from Quote_Process__r Limit 1) FROM Opportunity where Policy__c !=null];
        
        Map<String,String> mapQuoteProcessPolicy = new Map<String,String>();
        if(!lstOpp.isEmpty()) {
            for(Opportunity opp : lstOpp) {
                if(!opp.Quote_Process__r.isEmpty())
                    mapQuoteProcessPolicy.put(opp.Policy__c, opp.Quote_Process__r[0].Id);
            }
        }
        String strKeyPol = searchKeyPol + '%';
        List<Policy__c> lstPolicy = [SELECT Id, Name, Policy_Status__c, Policy_Number__c, Effective_Date__c, Expiration_Date__c, Total_Premium__c
                                        FROM Policy__c WHERE Id IN : mapQuoteProcessPolicy.keySet() AND Policy_Number__c LIKE: strKeyPol];
       
        List<ItemWrapper1> resultList = new List<ItemWrapper1>();
        for (Policy__c pol : lstPolicy) {
            //List<Endorsement_Process__c> lstQp = pol.Endorsement_Process__r;
            ItemWrapper1 item = new ItemWrapper1();
            item.Id = pol.Id;
            item.QpId = mapQuoteProcessPolicy.get(pol.Id) == null ? '' : mapQuoteProcessPolicy.get(pol.Id);
            //item.QpId = lstQp.isEmpty() ? '' : lstQp[0].Id;
            item.Name = pol.Name;
            item.Policy_Status = pol.Policy_Status__c;
            item.Policy_Number = pol.Policy_Number__c;
            item.Total_Premium = pol.Total_Premium__c;
            item.Effective_Date = pol.Effective_Date__c;
            item.Expiration_Date = pol.Expiration_Date__c;
            resultList.add(item);
        }
        return resultList;
    } 
    
    
    @AuraEnabled(cacheable = true)
    public static Map<String,List<ProductWrapper>> mapRecordTypeWithProductName(){
        // Modified by Vinayesh on 24/5/2021 for CD: 58
        //Combo child products should not be returned in products query.
        List<Product2> lstProduct = [Select Id,Name,RecordType.Name From Product2 
                                        Where IsActive = true And IsComboProduct__c = false];
        System.debug('lstProduct:' + lstProduct);
        Map<String,List<ProductWrapper>> returnedMap  = new Map<String,List<ProductWrapper>>();
        for(Product2 product : lstProduct) {
            if(returnedMap.get(product.RecordType.Name) == null) {
                returnedMap.put(product.RecordType.Name,new List<ProductWrapper>{new ProductWrapper(product)});
            } else {
                returnedMap.get(product.RecordType.Name).add(new ProductWrapper(product));
            }
        }
        return returnedMap;
    }

    @AuraEnabled
    public static Map<String,String> getDefaultProductName(List<String> recordTypeNames){
        List<Product_Setting__mdt> lstObj =[Select Id,MasterLabel,DeveloperName,Default__c,Record_Type__c
                                From Product_Setting__mdt WHERE Record_Type__c IN :recordTypeNames AND Default__c = true];
        Map<String,String> defaultProductNames = new Map<String,String>();  
        for(Product_Setting__mdt tmp : lstObj) {
            defaultProductNames.put(tmp.Record_Type__c,tmp.MasterLabel);
        }
        return defaultProductNames;//lstObj.isEmpty() ? '' : lstObj[0].MasterLabel;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,RecordTypeInfoWrapper> getRecordTypeObject(String sObjectName){
        sObject obj; 
        Map<String,RecordTypeInfoWrapper> recordTypeInfoMap = new Map<String,RecordTypeInfoWrapper>();  
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);  
        if(sObjectType != null) {  
            obj = sObjectType.newsObject();  
            Schema.DescribeSObjectResult sObjDesc = obj.getSObjectType().getDescribe();  
            if(sObjDesc != null) {  
                for(Schema.RecordTypeInfo recordTypeInfo : sObjDesc.getRecordTypeInfosByName().values()) {
                    System.debug('recordTypeInfo:' + recordTypeInfo);
                    if(recordTypeInfo.Available && recordTypeInfo.Active && !recordTypeInfo.Master) {
                        recordTypeInfoMap.put(recordTypeInfo.Name, new RecordTypeInfoWrapper(recordTypeInfo));
                    }
                }  
            }
        }  
        return recordTypeInfoMap;  
    }

    public class RecordTypeInfoWrapper {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}
        @AuraEnabled
        public Boolean defaultRecordTypeMapping {get;set;}
        public RecordTypeInfoWrapper() {
            this.defaultRecordTypeMapping = false;
        }

        public RecordTypeInfoWrapper(RecordTypeInfo recordTypeInfo) {
            this.label = recordTypeInfo.Name;
            this.value = recordTypeInfo.RecordTypeId;
            this.defaultRecordTypeMapping = recordTypeInfo.DefaultRecordTypeMapping;
        }

    }


    public class ProductWrapper {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}

        public ProductWrapper() {}

        public ProductWrapper(Product2 product) {
            this.label = product.Name;
            this.value = product.Name;
        }

    }


	public class ItemWrapper{
		@AuraEnabled public String Id {get; set;}
		@AuraEnabled public String QpId {get; set;}
		@AuraEnabled public String Name {get; set;}
		@AuraEnabled public Datetime CreatedDate {get; set;}
        @AuraEnabled public String Product_Name {get; set;}
		@AuraEnabled public Decimal Amount {get; set;}
		@AuraEnabled public Datetime Effective_Date {get; set;}
		@AuraEnabled public Datetime Expiration_Date {get; set;}
		@AuraEnabled public String StageName {get; set;}
		@AuraEnabled public String LeadSource {get; set;}
        public ItemWrapper() {
            Id = '';
			QpId = '';
			CreatedDate = null;
			Product_Name = '';
			Amount = 0;
			Effective_Date = null;
			Expiration_Date = null;
			StageName = '';
			LeadSource = '';
        }
	}
	
	public class ItemWrapper1{
		@AuraEnabled public String Id {get; set;}
		@AuraEnabled public String QpId {get; set;}
		@AuraEnabled public String Name {get; set;}
        @AuraEnabled public String Policy_Status {get; set;}
        @AuraEnabled public String Policy_Number {get; set;}
		@AuraEnabled public Decimal Total_Premium {get; set;}
		@AuraEnabled public Datetime Effective_Date {get; set;}
		@AuraEnabled public Datetime Expiration_Date {get; set;}
        public ItemWrapper1() {
            Id = '';
			QpId = '';
            Policy_Status = '';
            Policy_Number = '';
			Total_Premium = 0;
			Effective_Date = null;
			Expiration_Date = null;
        }
    }
}