/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 02-16-2022
 * @last modified by  : Vinayesh
**/
public with sharing class subjectivityController{
	@AuraEnabled(cacheable = true)
	public static List<ItemWrapper> getSubjectivityByQuoteId(String quoteId){
        List<Subjectivity__c> lstSub = new List<Subjectivity__c>();
		 lstSub= [SELECT Id,Name, Subjectivity__c, Subjectivity_Status__c, Subjectivity_Type__c,Stage__c,Due_Date__c,
                                       Subjectivity_Text__c, Cleared__c, Cleared_Date__c, Quote__c, Quote__r.Product_Name__c  FROM Subjectivity__c
		WHERE Quote__c = :quoteId];

		List<ItemWrapper> result = new List<ItemWrapper>();
		for(Subjectivity__c item : lstSub){
			ItemWrapper temp = new ItemWrapper();
			temp.Id = item.Id;
			temp.name = item.Name;
			temp.linkSubjectivityName = '/'+item.Id;
			temp.subjectivity = item.Subjectivity__c;
			temp.subjectivityStatus = item.Subjectivity_Status__c;
			temp.subjectivityType = item.Subjectivity_Type__c;
            temp.subjectivityStage = item.Stage__c;
            temp.subjectivityDueDate = String.valueOf(item.Due_Date__c);
            temp.subjectivityText = item.Subjectivity_Text__c;
            temp.cleared = item.Cleared__c;
            temp.clearedDate = item.Cleared_Date__c;
            result.add(temp);
		}
		return result;
	}
	@AuraEnabled
	public static Boolean updateRecords(String jsonStringRecord){
		if(String.isEmpty(jsonStringRecord)) return false;
		List<ItemWrapper> params = (List<ItemWrapper>)JSON.deserialize(jsonStringRecord,List<ItemWrapper>.class);
		List<Subjectivity__c> lstUpdated = new List<Subjectivity__c>();

		for(ItemWrapper item : params){
			Subjectivity__c subject = new Subjectivity__c();
			subject.Id = item.Id;
            if(item.subjectivity != null)
			    subject.Subjectivity__c = item.subjectivity;
            if(item.subjectivityStatus != null)    
			    subject.Subjectivity_Status__c = item.subjectivityStatus;
            if(item.subjectivityType != null)    
			    subject.Subjectivity_Type__c = item.subjectivityType;
            if(item.subjectivityStage != null)
                subject.Stage__c = item.subjectivityStage;
            if(String.isNotBlank(item.subjectivityDueDate) && item.subjectivityDueDate.contains('T'))
                subject.Due_Date__c =  Date.valueOf(item.subjectivityDueDate.split('T')[0]).addDays(1);
            if(item.subjectivityText != null)
                subject.Subjectivity_Text__c = item.subjectivityText;
            if(item.cleared != null)
                subject.Cleared__c = Boolean.valueOf(item.cleared);
            //system.debug('Cleared__c::'+subject.Cleared__c);
            if(item.clearedDate != null)
                subject.Cleared_Date__c = Date.valueOf(item.clearedDate);
			lstUpdated.add(subject);
		}

		update lstUpdated;
		return true;
	}
    @AuraEnabled(cacheable = true)
    public static String getProductName (String quoteId){
        String productName = [SELECT Id, Product_Name__c FROM Quote WHERE Id  = :quoteId Limit 1].Product_Name__c;
        System.debug('String.valueOf(productName)::'+String.valueOf(productName));
        return String.valueOf(productName) ;
    }
    
    @AuraEnabled
    public static List<Subjectivity_Template__c> getSubjectivityTemplateList(String quoteId){
		 return getSubjectivityTemplates(quoteId);   
    }
    
    private static List<Subjectivity_Template__c> getSubjectivityTemplates(String quoteId){
        Quote quoteRec = [Select Id, OpportunityId, Layer__c, Product_Name__c from Quote where Id =:quoteId];
        Opportunity oppRec = [Select Id, Main_Profession__c, Account.BillingStateCode From Opportunity where Id =:quoteRec.OpportunityId]; 
        String mainProfession = oppRec.Main_Profession__c;
        String insuredState = oppRec.Account.BillingStateCode;//added by Jitendra on 11-Jan-2022
        Set<Id> usedSubjectivityTemplates = new Set<Id>();
        List <Subjectivity__c> existingSubjOnQuote = [Select Id, Subjectivity_Template__c from Subjectivity__c where Quote__c =:quoteId ];

        Set<String> existingStateList = new Set<String>();
        if(quoteRec.Product_Name__c != GlobalVariables.PROD_NAME_FOR_PI){
            for (Subjectivity_Template__c eachSubTemp : [Select Id,State__c from Subjectivity_Template__c where State__c != '']){
                existingStateList.add(eachSubTemp.State__c);
            }
        }
        
        for(Subjectivity__c sub : existingSubjOnQuote){
            usedSubjectivityTemplates.add(sub.Subjectivity_Template__c);
        }
        System.debug('@@usedSubjectivityTemplates::'+usedSubjectivityTemplates);
        Set<String> primarySub = new Set<String>{'Copy of the Primary Insurer Policy Wording and Terms.','Primary Insurer Security','Primary and/or Underlying Policy Numbers.','XOL Retroactive Date'};
        Set<String> excessSub = new Set<String>{'RICS 4 storey or under fire safety','Current Primary Retroactive Date'};
        List<Subjectivity_Template__c> returnsubTempList = new List<Subjectivity_Template__c>();
        if(quoteRec.Layer__c == 'Excess'){
            List<Subjectivity_Template__c> subTempList = new List<Subjectivity_Template__c>();
            if(quoteRec.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                subTempList = [Select Id, Subjectivity_Name__c, Subjectivity_Text__c, Applicable_Products__c,
                                                        Profession_Criteria__c
                                                        From Subjectivity_Template__c
                                                        Where Profession_Criteria__c INCLUDES(:mainProfession)
                                                        AND Subjectivity_Name__c NOT IN : excessSub
                                                        AND Id NOT IN :usedSubjectivityTemplates];
            }
            else{
                if(existingStateList.contains(insuredState)){
                    subTempList = [Select Id, Subjectivity_Name__c, Subjectivity_Text__c, 
                    Profession_Criteria__c,Applicable_Products__c
                    From Subjectivity_Template__c
                    Where Layer__c INCLUDES('Excess')
                    AND Subjectivity_Name__c NOT IN : excessSub
                    AND Id NOT IN :usedSubjectivityTemplates
                    AND (State__c INCLUDES(:insuredState) OR  State__c ='') ];
                }
                else{
                    subTempList = [Select Id, Subjectivity_Name__c, Subjectivity_Text__c, 
                    Profession_Criteria__c,Applicable_Products__c
                    From Subjectivity_Template__c
                    Where Layer__c INCLUDES('Excess')
                    AND Subjectivity_Name__c NOT IN : excessSub
                    AND Id NOT IN :usedSubjectivityTemplates
                    AND  State__c ='' ];
                }
                
            }
            if(!subTempList.isEmpty()) returnsubTempList = subTempList;

            //return returnsubTempList;
        }
        else{
            //List<Subjectivity_Template__c> returnsubTempList = new List<Subjectivity_Template__c>();
            List<Subjectivity_Template__c> subTempList = new List<Subjectivity_Template__c>();
            if(quoteRec.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                subTempList = [Select Id, Subjectivity_Name__c, Subjectivity_Text__c, Applicable_Products__c,
                                                        Profession_Criteria__c
                                                        From Subjectivity_Template__c
                                                        Where Profession_Criteria__c INCLUDES(:mainProfession)
                                                        AND Subjectivity_Name__c NOT IN : primarySub
                                                        AND Id NOT IN :usedSubjectivityTemplates];
            }
            else{
                if(existingStateList.contains(insuredState)){
                    subTempList = [Select Id, Subjectivity_Name__c, Subjectivity_Text__c, 
                    Profession_Criteria__c,Applicable_Products__c
                    From Subjectivity_Template__c
                    Where Layer__c INCLUDES('Primary')
                    AND Subjectivity_Name__c NOT IN : excessSub
                    AND Id NOT IN :usedSubjectivityTemplates
                    AND (State__c INCLUDES(:insuredState) OR  State__c ='')];
                }
                else{
                    subTempList = [Select Id, Subjectivity_Name__c, Subjectivity_Text__c, 
                    Profession_Criteria__c,Applicable_Products__c
                    From Subjectivity_Template__c
                    Where Layer__c INCLUDES('Primary')
                    AND Subjectivity_Name__c NOT IN : excessSub
                    AND Id NOT IN :usedSubjectivityTemplates
                    AND State__c ='' ];
                }               
            }
            if(!subTempList.isEmpty()) returnsubTempList = subTempList;

            //return returnsubTempList;
        }

        List<Subjectivity_Template__c> filteredSubTempList = new List<Subjectivity_Template__c>();
        if(returnsubTempList.size() > 0 && quoteRec.Product_Name__c != null && quoteRec.Product_Name__c != GlobalVariables.PROD_NAME_FOR_PI){
            for( Subjectivity_Template__c subTemp : returnsubTempList ){
                if(subTemp.Applicable_Products__c != null){
                    List<String> subjProducts =  subTemp.Applicable_Products__c.split(';');
                    boolean prodMatch = false;
                    for(String prod : subjProducts){
                        if(quoteRec.Product_Name__c.contains(prod)){
                            prodMatch = true;
                        }
                    }
                    if(!prodMatch) continue;
                }
                filteredSubTempList.add(subTemp);
            }
            return filteredSubTempList;
        }

        return returnsubTempList;
    }
    
    @AuraEnabled(cacheable = true)
    public static String getProfessionName (String quoteId){
        Quote quoteRec = [Select Id, OpportunityId from Quote where Id =:quoteId];
        Opportunity oppRec = [Select Id, Main_Profession__c From Opportunity where Id =:quoteRec.OpportunityId];
        String mainProfession = oppRec.Main_Profession__c;
        return mainProfession;
    }
    
    @AuraEnabled
    public static String createSubjectivitiesBySubjTemplate(String quoteId, List<String> subjTemplates){
        String operation = '';
        List<Subjectivity__c> subjectivityListToSave = new List<Subjectivity__c>();
        if(String.isNotBlank(quoteId) && !subjTemplates.isEmpty()){
            List<Quote> quotes = [Select Id,OpportunityId, Product_Name__c from Quote WHERE Id = :quoteId];
            for(Subjectivity_Template__c sTemp : [Select Id, Subjectivity_Name__c, Subjectivity_Text__c, 
                                                  Profession_Criteria__c,Stage__c
                                                  From Subjectivity_Template__c Where Id IN: subjTemplates])
            {
                Subjectivity__c subRec = new Subjectivity__c(); 
                subRec.Quote__c = quoteId;
                subRec.Subjectivity__c = sTemp.Subjectivity_Name__c;
                subRec.Subjectivity_Text__c = sTemp.Subjectivity_Text__c;
                
                subRec.Cleared__c = false;
                subRec.Cleared_Date__c = null;
                subRec.Subjectivity_Template__c = sTemp.Id;
                
                if( quotes[0].Product_Name__c == GlobalVariables.PROD_NAME_FOR_CYBER ||
                    quotes[0].Product_Name__c == GlobalVariables.PROD_NAME_FOR_MPL ||
                    quotes[0].Product_Name__c == GlobalVariables.PROD_NAME_FOR_PCC
                ){
                    subRec.Stage__c = sTemp.Stage__c;
                    subRec.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
                }else if(quotes[0].Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                    subRec.Stage__c = 'Pre-Bind';
                    subRec.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS).getRecordTypeId();
                }

                subjectivityListToSave.add(subRec);
            }
        }
        if(!subjectivityListToSave.isEmpty()){
            System.debug('@@subjectivityListToSave::'+subjectivityListToSave);
            insert subjectivityListToSave;
            operation = 'success';
            //rowsInserted = subjectivityListToSave.size();
        }
        System.debug('@@operation::'+operation);
        return operation;
    }
    
    
    @AuraEnabled
    public static string checkIsExcess (String quoteId){
        String layer = [SELECT Id,Layer__c FROM Quote WHERE Id  = :quoteId Limit 1].Layer__c;
        return layer;
    }
    
    
    
	public class ItemWrapper{
		@AuraEnabled public String Id {get; set;}
		@AuraEnabled public String name {get; set;}
		@AuraEnabled public String linkSubjectivityName {get; set;}
		@AuraEnabled public String subjectivity {get; set;}
		@AuraEnabled public String subjectivityStatus {get; set;}
        @AuraEnabled public String subjectivityStage {get; set;}
		@AuraEnabled public String subjectivityType {get; set;}
        @AuraEnabled public String subjectivityText {get; set;}
        @AuraEnabled public Boolean cleared {get; set;}
        @AuraEnabled public Date clearedDate {get; set;}
        @AuraEnabled public String subjectivityDueDate {get; set;}
        public ItemWrapper() {
            Id = '';
			name ='';
			linkSubjectivityName='';
			subjectivity = '';
			subjectivityStatus='';
            subjectivityStage ='';
			subjectivityType='';
            subjectivityText='';
            cleared=false;
            clearedDate=null;
            subjectivityDueDate=null;
        }
    }

}