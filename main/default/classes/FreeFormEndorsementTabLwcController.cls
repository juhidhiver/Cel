public with sharing class FreeFormEndorsementTabLwcController {
    
    @AuraEnabled(cacheable = true)
	public static List<FFEndorsementItemWrapper> getFFEndorsementByQuoteId(String quoteId){
		List<Free_Form_Endorsements__c> endList= [SELECT Id, Name, Quote__c, Form_Number__c, Endorsement_Name__c, Endorsement_Wording__c, 
                                                  Coverage_Effective_Date__c FROM Free_Form_Endorsements__c
												  WHERE Quote__c = :quoteId ORDER BY CreatedDate DESC];
		List<FFEndorsementItemWrapper> result = new List<FFEndorsementItemWrapper>();
		for(Free_Form_Endorsements__c item : endList){
			FFEndorsementItemWrapper temp = new FFEndorsementItemWrapper();
            temp.Id = item.Id;
			temp.endorsementId = item.Name;
			temp.endorsementName = item.Endorsement_Name__c;
			temp.linkFFEndorsementName = '/'+item.Id;
			temp.formNumber = item.Form_Number__c;
            temp.covEffectiveDate = item.Coverage_Effective_Date__c;
			result.add(temp);
		}
        System.debug('#result::'+result);
		return result;
	}
    @AuraEnabled
    public static Date getCoverageEffDate(String quoteId){
        Quote quoteRec = [SELECT Id, Effective_Date__c FROM Quote where Id=:quoteId];
        Date covEffectiveDate;
        if(quoteRec!=null){
            covEffectiveDate = quoteRec.Effective_Date__c;
        }
        return covEffectiveDate;
    }
    @AuraEnabled
    public static String generateFormNumber(String quoteId){
        String formNum = 'AQUW999';
    	List<Free_Form_Endorsements__c> ffList= [SELECT Id, Quote__c, Form_Number__c FROM Free_Form_Endorsements__c
												  WHERE Quote__c = :quoteId ORDER BY Form_Number__c DESC];
        String currFormNum= '';
        
        if(ffList.size()==0){
          return formNum;
        }
        else if(ffList.size()==1){
            //currFormNum = ffList[0].Form_Number__c;
            //formNum = formNum + getNextChar(currFormNum.substring(currFormNum.length() - 1));
            formNum = formNum + 'A';
            return formNum;
        }
        else{
            if(!ffList.isEmpty()){
               currFormNum = ffList[0].Form_Number__c; 
               formNum = formNum + getNextChar(currFormNum.substring(currFormNum.length() - 1));
            }
            return formNum;
        }
    }
    public static String getNextChar(String oldChar) {
        String key = ' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        Integer index = key.indexOfChar(oldChar.charAt(0));
        return index == -1? null: key.substring(index+1, index+2);
	}

    public class FFEndorsementItemWrapper{
		@AuraEnabled public String Id {get; set;}
        @AuraEnabled public String endorsementId {get; set;}
		@AuraEnabled public String formNumber {get; set;}
		@AuraEnabled public String endorsementName {get; set;}
        @AuraEnabled public Date covEffectiveDate {get; set;}
        @AuraEnabled public String linkFFEndorsementName {get; set;}
        public FFEndorsementItemWrapper() {
            Id='';
            endorsementId = '';
			formNumber ='';
			endorsementName = '';
            covEffectiveDate=null;
            linkFFEndorsementName='';
        }
    }
}