public class SanctionStatusTriggerHandler_CEL extends TriggerHandler{
    private List<Sanction_Status__c> oldDataList;
    private List<Sanction_Status__c> newDataList; 
    private Map<Id, Sanction_Status__c> newDataMap;
    private Map<Id, Sanction_Status__c> oldDataMap;
    
    public SanctionStatusTriggerHandler_CEL(List<Sanction_Status__c> newDataList, List<Sanction_Status__c> oldDataList, 
                                         Map<Id, Sanction_Status__c> newDataMap, Map<Id, Sanction_Status__c> oldDataMap){
                                             this.oldDataList = oldDataList;
                                             this.newDataList = newDataList;
                                             this.newDataMap = newDataMap;
                                             this.oldDataMap = oldDataMap;
                                         }  

    public SanctionStatusTriggerHandler_CEL() {

    }

    public override void beforeInsert(){
        setFieldOnInsert(newDataList);
    }

    public override void beforeUpdate(){}

    public override void afterInsert(){
        setSanctionStatusonAccountonInsert(newDataList);
    }

    public override void afterUpdate(){
        setSanctionStatusonAccountonUpdate(newDataList,oldDataMap);
    }

    public static void setSanctionStatusonAccountonInsert(List<Sanction_Status__c> newDataList){

        List<Account> listAccounttoUpdate = new List<Account>();
        for(Sanction_Status__c objSanctionStatus : newDataList){
            Account acc = new Account();
            acc.Id = objSanctionStatus.Account__c;
            acc.CEL_Sanction_Status__c = objSanctionStatus.Sanction_Status__c;
            acc.Sanction_Date__c = objSanctionStatus.Sanction_Date__c;
            acc.SearchId__c = objSanctionStatus.SearchId__c;
            acc.Decline_Reason__c = objSanctionStatus.Decline_Reason__c;
            acc.Review_Note__c = objSanctionStatus.Review_Note__c;
            acc.Review_Requested__c = objSanctionStatus.Review_Requested__c;
            acc.Review_Requested_By__c = objSanctionStatus.Review_Requested_By__c;
            acc.Reviewed_By__c = objSanctionStatus.Reviewed_By__c;
            acc.Reviewed_On__c = objSanctionStatus.Reviewed_On__c;
            listAccounttoUpdate.add(acc);
        }

        if(!listAccounttoUpdate.isEmpty()){
            update listAccounttoUpdate;
        }
    }

    public static void setSanctionStatusonAccountonUpdate(List<Sanction_Status__c> newDataList, Map<Id, Sanction_Status__c> oldDataMap){

        List<Account> listAccounttoUpdate = new List<Account>();
        for(Sanction_Status__c objSanctionStatus : newDataList){
            if(objSanctionStatus.Sanction_Status__c != oldDataMap.get(objSanctionStatus.Id).Sanction_Status__c 
            || objSanctionStatus.Account__c != oldDataMap.get(objSanctionStatus.Id).Account__c){
                Account acc = new Account();
                acc.Id = objSanctionStatus.Account__c;
                acc.CEL_Sanction_Status__c = objSanctionStatus.Sanction_Status__c;
                acc.Sanction_Date__c = objSanctionStatus.Sanction_Date__c;
                acc.SearchId__c = objSanctionStatus.SearchId__c;
                acc.Decline_Reason__c = objSanctionStatus.Decline_Reason__c;
                acc.Review_Note__c = objSanctionStatus.Review_Note__c;
                acc.Review_Requested__c = objSanctionStatus.Review_Requested__c;
                acc.Review_Requested_By__c = objSanctionStatus.Review_Requested_By__c;
                acc.Reviewed_By__c = objSanctionStatus.Reviewed_By__c;
                acc.Reviewed_On__c = objSanctionStatus.Reviewed_On__c;    
                listAccounttoUpdate.add(acc);
            }
        }

        if(!listAccounttoUpdate.isEmpty()){
            update listAccounttoUpdate;
        }
    }
    
    /********************CD 170   *****************/
    public static void setFieldOnInsert(List<Sanction_Status__c> newDataList){
        
        List<String> AccountIDs = new List<String>();
        
        for(Sanction_Status__c san : newDataList){
            if(san.Account__c != null){
                AccountIDs.add(san.Account__c);
            }
        }
        Map<String,String> newAccountMap = new Map<String,String>();
        for(Account acc : [select id,Name from Account where Id IN:AccountIDs]){
            newAccountMap.put(acc.Id,acc.Name);
        }
        
        for(Sanction_Status__c objSanctionStatus : newDataList){
           objSanctionStatus.Account_Name__c   = !newAccountMap.isEmpty() && newAccountMap.containskey(objSanctionStatus.Account__c) ? newAccountMap.get(objSanctionStatus.Account__c) : '';
        }
        
    }
}