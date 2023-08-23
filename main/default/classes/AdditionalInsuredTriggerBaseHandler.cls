public class AdditionalInsuredTriggerBaseHandler extends TriggerHandler{

    private List<Additional_Insured__c> oldDataList;
    private List<Additional_Insured__c> newDataList;
    private Map<Id, Additional_Insured__c> newDataMap;
    private Map<Id, Additional_Insured__c> oldDataMap;
    
    public AdditionalInsuredTriggerBaseHandler() {
        this.oldDataList = (List<Additional_Insured__c>) Trigger.old;
        this.oldDataMap = (Map<Id, Additional_Insured__c>) Trigger.oldMap;
        
        this.newDataList = (List<Additional_Insured__c>) Trigger.new;
        this.newDataMap = (Map<Id, Additional_Insured__c>) Trigger.newMap;
    }

    public override void beforeInsert(){}

    public override void beforeUpdate(){}

    public override void afterInsert(){
        validateSanctionCheckOnInsert(newDataList);
    }

    public override void afterUpdate(){
        //validateSanctionCheckOnUpdate(newDataList,oldDataMap);
    }

    public static void validateSanctionCheckOnInsert(List<Additional_Insured__c> newDataList){

        Set<Id> setAccIds = new Set<Id>();
        for(Additional_Insured__c objAdditionalInsured : newDataList){
            setAccIds.add(objAdditionalInsured.Additional_Insured_Account__c);
        }
        List<Account> lstAccount = [SELECT Id, OwnerId,Action_Point__c,CEL_Sanction_Status__c,AQ_Sanction_Status__c,BillingCountryCode FROM Account WHERE Id in: setAccIds];
        
        if(!lstAccount.isEmpty()){
            CommonAccountUtil.validateSanctionCheckOnInsert(lstAccount, true);
        }

    }

    /*public static void validateSanctionCheckOnUpdate(List<Additional_Insured__c> newDataList, Map<Id, Additional_Insured__c> oldDataMap){

        Set<Id> setAccIds = new Set<Id>();
        for(Additional_Insured__c objAdditionalInsured : newDataList){
            if(objAdditionalInsured.Additional_Insured_Account__c != oldDataMap.get(objAdditionalInsured.Id).Additional_Insured_Account__c){
                setAccIds.add(objAdditionalInsured.Additional_Insured_Account__c);
            }
        }
        List<Account> lstAccount = [SELECT Id, OwnerId, AQ_Sanction_Status__c FROM Account WHERE Id in: setAccIds];
        
        if(!lstAccount.isEmpty()){
            CommonAccountUtil.validateSanctionCheckOnInsert(lstAccount, true);
        }
        
    }*/
    
}