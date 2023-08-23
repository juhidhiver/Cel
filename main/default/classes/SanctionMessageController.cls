public with sharing class SanctionMessageController {
    public SanctionMessageController() {

    }

    /*************************************************
    * Method Name: checkSanctionStatus
    * Author: 
    * Date: 
    * Params: String 
    * Return: 
    * Description: This method returns Sanction search URL and account Name
    * Can be moved to Flows: No
     *************************************************/ 
    @AuraEnabled
    public static ReturnValue checkSanctionStatus(String recordId) {
        
        String objType = ((Id)recordId).getSobjectType().getDescribe().getName();
        System.debug(objType);  
        Returnvalue retrunval;
        if (objType == 'Opportunity'){
            Opportunity objOpp = [Select Id,Name, Account.Name, Account.AQ_Sanction_Status__c,Account.Cel_Sanction_Status__c,Account.searchId__c from Opportunity where Id = :recordId];
            system.debug('objOpp==> '+objOpp);
            retrunval = new ReturnValue();
            if(objOpp.Account.AQ_Sanction_Status__c == 'Failed' || objOpp.Account.Cel_Sanction_Status__c == 'Failed'){
                
                retrunval.hasSanctionFail = true;
                String sanurlforsearch='https://www.sanctionssearch.com/members/search/details';
                String sanurl ='https://www.sanctionssearch.com';
                String stringURL;
                if(objOpp.Account.searchId__c!=null){
                    stringURL  = '<a href='+sanurlforsearch+'/'+objOpp.Account.searchId__c+' style="text-decoration:underline !important">'+objOpp.Account.Name+'</a>';
                }
                else{
                    stringURL  = '<a href='+sanurl+'  style="text-decoration:underline !important">'+objOpp.Account.Name+'</a>';
                }
                system.debug('StringURL--> '+stringURL);
                retrunval.names = stringURL;
            }
        }
        else if(objType == 'Account'){
            System.debug('recordId--->'+recordId);
            Account objAcc = [Select Id, Name, AQ_Sanction_Status__c,Cel_Sanction_Status__c, searchId__c from Account where Id = :recordId];
           // Id recordTypeId =Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
           //Added on 30/05/22
           Id recordTypeId;
           if(UserInfo.getUserRoleId() != null ){
                User loggedInUser =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id =: UserInfo.getUserId()];
                
                String runningUserRoleName = loggedInUser.UserRole.Name;
                if(runningUserRoleName.contains('Aqueous')){ 
                    recordTypeId   = Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
                }
                else if(runningUserRoleName.contains('Celerity')){
                    recordTypeId   = Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(); 
                }
           }    
               
            system.debug('recordTypeId-->'+recordTypeId);
            List<Sanction_Status__c> listSanctionStatus = [Select Id, Account__c,Sanction_Status__c,searchId__c  from Sanction_Status__c where Account__c =: recordId and RecordTypeId =: recordTypeId and Sanction_Status__c NOT IN ('Cleared','Pass')];
            system.debug('listSanctionStatus-->'+listSanctionStatus);
            if(listSanctionStatus != null && !listSanctionStatus.isEmpty()){
                Sanction_Status__c objSanctionStatus = listSanctionStatus[0];
                retrunval = new ReturnValue();
                
                if(objSanctionStatus.Sanction_Status__c == 'Failed' || objSanctionStatus.Sanction_Status__c == 'Potential Match'){
                    
                    retrunval.hasSanctionFail = true;
                    String sanurlforsearch='https://www.sanctionssearch.com/members/search/details';
                    String sanurl ='https://www.sanctionssearch.com';
                    String stringURL;
                    if(objSanctionStatus.searchId__c!=null){
                        stringURL  = '<a href='+sanurlforsearch+'/'+objSanctionStatus.searchId__c+' style="text-decoration:underline !important">'+objAcc.Name+'</a>';
                    }
                    else{
                        stringURL  = '<a href='+sanurl+'  style="text-decoration:underline !important">'+objAcc.Name+'</a>';
                    }
                    retrunval.names = stringURL;
                    System.debug('String URL-- >'+stringURL);
                }
            }
        }
        system.debug('Return Val at 82 -->'+retrunval);
        return retrunval;
    }

    @AuraEnabled( cacheable=true )
    public static ReturnValueUW checkUWSanctionStatus(String recordId) {

        String objType = ((Id)recordId).getSobjectType().getDescribe().getName();
        System.debug('objType==>'+objType); 
        String insuredAccId;
        ReturnValueUW retrunval;
        Opportunity objOpp;
        Set<String> setAccountIds = new Set<String>();
        if (objType == 'Quote_Process__c'){
            Quote_Process__c objUW = [Select Id,Submission__c,Account__c from Quote_Process__c where Id = : recordId];
            if(objUW.Account__c != null){
                setAccountIds.add(objUW.Account__c);
                insuredAccId = objUW.Account__c;
            }
            if(objUW.Submission__c != null){
                objOpp = [Select Id,Name,AccountId, Account.Name, Account.AQ_Sanction_Status__c, Account.Cel_Sanction_Status__c,Account.searchId__c from Opportunity where Id = :objUW.Submission__c];
            }
        }
       else if (objType == 'Opportunity'){
            objOpp = [Select Id,Name,AccountId, Account.Name, Account.AQ_Sanction_Status__c, Account.Cel_Sanction_Status__c,Account.searchId__c from Opportunity where Id = :recordId];
            setAccountIds.add(objOpp.AccountId);
            insuredAccId = objOpp.AccountId;
        }

        /**** New Code for 26/04/2022  *****/
       else if(objType == 'Account'){
           system.debug('objType'+objType);
          Account acc = [select id from Account where Id=:recordId];
          setAccountIds.add(acc.Id);
          insuredAccId = acc.Id;          
        }
        /****** New Code Ended *************/
        
        if(objOpp != null){
            for(Additional_Insured__c objAddIns : [Select Id, Additional_Insured_Account__c from Additional_Insured__c where Submission__c = :objOpp.Id]){
                setAccountIds.add(objAddIns.Additional_Insured_Account__c);
            }
        }
        if(!setAccountIds.isEmpty()){
            Map<String,Sanction_Status__c> mapSanctionStatus = new Map<String,Sanction_Status__c>();

            Id recordTypeId;
            if(UserInfo.getUserRoleId() != null){
                User loggedInUser =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id =: UserInfo.getUserId()];
                
                String runningUserRoleName = loggedInUser.UserRole.Name;
                
                if(runningUserRoleName.contains('Aqueous')){
                    recordTypeId   = Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
                }
                else if(runningUserRoleName.contains('Celerity')){
                    recordTypeId   = Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Celerity').getRecordTypeId(); 
                }
            }


          //  Id recordTypeId =Schema.SObjectType.Sanction_Status__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
            for(Sanction_Status__c objSanctionStatus : [Select Id, Account__c,Account__r.Name,Sanction_Status__c,searchId__c  from Sanction_Status__c where Account__c in: setAccountIds and ((RecordTypeId!=null And RecordTypeId =: recordTypeId) or RecordTypeId=null)  Order By CreatedDate Desc]){
                if(!mapSanctionStatus.containsKey(objSanctionStatus.Account__c)){
                    mapSanctionStatus.put(objSanctionStatus.Account__c,objSanctionStatus);
                }
            }
            system.debug('mapSanctionStatus'+mapSanctionStatus);
            //List<Sanction_Status__c> listSanctionStatus = [Select Id, Account__c,Sanction_Status__c,searchId__c  from Sanction_Status__c where Account__c =: objOpp.AccountId and RecordTypeId =: recordTypeId and Sanction_Status__c NOT IN ('Cleared','Pass')];
            if(mapSanctionStatus != null && !mapSanctionStatus.isEmpty()){
                retrunval = new ReturnValueUW();
                List<AddistionalAccountData> listAddistionalAccountData = new List<AddistionalAccountData>();
                for(Id accId : setAccountIds){
                    if(mapSanctionStatus.containsKey(accId)){
                        Sanction_Status__c objSanctionStatus = mapSanctionStatus.get(accId);
                        if(objSanctionStatus.Sanction_Status__c == 'Potential Match' || objSanctionStatus.Sanction_Status__c == 'Failed'){
                            retrunval.hasSanctionFail = true;
                            if(objSanctionStatus.Account__c == insuredAccId){
                                retrunval.insuredAccountName = objSanctionStatus.Account__r.Name;
                                retrunval.insuredAccountId = accId;
                            }
                            else{
                                AddistionalAccountData objAddistionalAccountData = new AddistionalAccountData();
                                objAddistionalAccountData.additionalAccountName = objSanctionStatus.Account__r.Name;
                                objAddistionalAccountData.additionalAccountId = objSanctionStatus.Account__c;
                                objAddistionalAccountData.searchId = objSanctionStatus.searchId__c;
                                listAddistionalAccountData.add(objAddistionalAccountData);
                            }
                        }
                    }
                }
                if(retrunval.hasSanctionFail == true && !listAddistionalAccountData.isEmpty()){
                    retrunval.listAddistionalAccountData = listAddistionalAccountData;
                }
                
            }
        }
        system.debug('Return Val -->'+retrunval);
        return retrunval;

    }

    public class ReturnValueUW{

        @AuraEnabled public Boolean hasSanctionFail;
        @AuraEnabled public String insuredAccountName;
        @AuraEnabled public String insuredAccountId;
        @AuraEnabled public String searchId;
        @AuraEnabled public List<AddistionalAccountData> listAddistionalAccountData;
        public ReturnValueUW(){
            this.hasSanctionFail = false;
        }

    }

    public class AddistionalAccountData{

        @AuraEnabled public String searchId;
        @AuraEnabled public String additionalAccountName;
        @AuraEnabled public String additionalAccountId;

    }


    public class ReturnValue{
        @AuraEnabled Public String names;
        @AuraEnabled public Boolean hasSanctionFail;
        @AuraEnabled public String searchId;
        @AuraEnabled public Map<String,String> namewithLinks;
        @AuraEnabled public List<String> nameList;
        @AuraEnabled public List<String> sIdList;
    }
}