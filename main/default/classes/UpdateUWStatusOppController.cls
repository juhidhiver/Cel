public with sharing  class UpdateUWStatusOppController {
 public static final String QUOTE_PROCESS_OBJ = 'Quote_Process__c';
  public static final String OPPORTUNITY_OBJ = 'Opportunity';
 @AuraEnabled
    public static void UpdateStatus(String recordId,String UwStatus) {
        system.debug('recordId'+recordId);
         system.debug('UwStatus'+UwStatus);
          Id myId = Id.valueOf(recordId);
       String sObjName = myId.getSObjectType().getDescribe().getName();
        if(sObjName == OPPORTUNITY_OBJ) {
          Opportunity opp = [select id,name,UW_Status__c from Opportunity where id=:recordId];
          
        if(UwStatus == 'Awaiting UW Review'){
            opp.UW_Status__c = 'Awaiting Underwriting Review';
        }else{
            opp.UW_Status__c = UwStatus;
        }
        Update  opp;
          }
       else  if(sObjName == QUOTE_PROCESS_OBJ) {
   Quote_Process__c qpObj = [select id,name,Submission__r.UW_Status__c,Submission__c from Quote_Process__c  where id=:recordId];
  
   opportunity opp = new opportunity();
   opp.id = qpObj.Submission__c;
    if(UwStatus == 'Awaiting UW Review'){
   opp.UW_Status__c =  'Awaiting Underwriting Review';
   }
           
        else{
             opp.UW_Status__c =  UwStatus ;
        }
         Update  opp;
      
   }   
   
    }
    
    @AuraEnabled
    public static void UpdateSubmissisonStatus(String recordId,String subStatus) {
        Id myId = Id.valueOf(recordId);
        String sObjName = myId.getSObjectType().getDescribe().getName();
        if(sObjName == OPPORTUNITY_OBJ) {
            Opportunity opp = [select id,name,Submission_Status__c from Opportunity where id=:recordId];
            opp.Submission_Status__c = subStatus;
            Update  opp;
        }
        else  if(sObjName == QUOTE_PROCESS_OBJ) {
            Quote_Process__c qpObj = [select id,name,Submission__r.Submission_Status__c,Submission__c from Quote_Process__c  where id=:recordId];
            
            opportunity opp = new opportunity();
            opp.id = qpObj.Submission__c;
            opp.Submission_Status__c =  subStatus;
            Update  opp;
            
        }   
   
    }
    
    
   @AuraEnabled
    public static String selectedValueUwStatus(String recordId) {
     system.debug('recordId'+recordId);
     String SelectedValue ='';
     Id myId = Id.valueOf(recordId);
       String sObjName = myId.getSObjectType().getDescribe().getName();
            system.debug('sObjName:' + sObjName);
     if(sObjName == OPPORTUNITY_OBJ) {
   Opportunity opp = [select id,name,UW_Status__c from Opportunity where id=:recordId];
   SelectedValue = opp.UW_Status__c ;
   }
   else  if(sObjName == QUOTE_PROCESS_OBJ) {
   Quote_Process__c qpObj = [select id,name,Submission__r.UW_Status__c,Submission__c from Quote_Process__c  where id=:recordId];
   if(String.isNotBlank(qpObj.Submission__c)){
   SelectedValue = qpObj.Submission__r.UW_Status__c ;
   }
   else{
   SelectedValue ='OppNotCreated';
   }
   }
 
   return SelectedValue;
    }
    
    
    @AuraEnabled
    public static String selectedValueSubmissionStatus(String recordId) {
        String SelectedValue ='';
        Id myId = Id.valueOf(recordId);
        String sObjName = myId.getSObjectType().getDescribe().getName();
        
        if(sObjName == OPPORTUNITY_OBJ) {
            Opportunity opp = [select id,name,StageName,Submission_Status__c from Opportunity where id=:recordId];
            if(opp != null){
                if(opp.StageName == 'Declined'){SelectedValue = 'Invalid StageName';} 
                else{
                        SelectedValue = string.isNotBlank(opp.Submission_Status__c) ? opp.Submission_Status__c : 'Hold Cover';
                    }
                } 
        }
        else  if(sObjName == QUOTE_PROCESS_OBJ) {
            Quote_Process__c qpObj = [select id,name,Submission__r.StageName,Submission__r.Submission_Status__c,Submission__c from Quote_Process__c  where id=:recordId];
            if(qpObj != null){
                if(qpObj.Submission__r.StageName == 'Declined'){
                    SelectedValue = 'Invalid StageName';
                }else{
                    if(String.isNotBlank(qpObj.Submission__c)){
                        SelectedValue = string.isNotBlank(qpObj.Submission__r.Submission_Status__c) ? qpObj.Submission__r.Submission_Status__c : 'Hold Cover';
                    }
                    else{
                        SelectedValue ='OppNotCreated';
                    }
                }
            }
            
        }
        
        return SelectedValue;
    }
      
     @AuraEnabled //get Account Industry Picklist Values
    public static Map<String, String> getUWStatus(){
        Map<String, String> options = new Map<String, String>();
        //get Account Industry Field Describe
        Schema.DescribeFieldResult fieldResult = Opportunity.UW_Status__c.getDescribe();
        //get Account Industry Picklist Values
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            //Put Picklist Value & Label in Map
           if(p.getValue() !='Bound' && p.getValue() !='Declined'){
            options.put(p.getValue(), p.getLabel());
           }
        }
        return options;
    }
    
    @AuraEnabled
    public static Map<String, String> getSubmisisonStatus(){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.Submission_Status__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
           if(p.getValue() =='VRI' || p.getValue() =='Information Requested' || p.getValue() =='Hold Cover'){
            options.put(p.getValue(), p.getLabel());
           }
        }
        return options;
    }
    
        
    @AuraEnabled
    public static string getObjectType(string recordId){
        string recordTypeName;
       Id myId = Id.valueOf(recordId);
       String sObjName = myId.getSObjectType().getDescribe().getName();
        if(sObjName == OPPORTUNITY_OBJ) {
         Opportunity oppo = [select Id,RecordType.Name from Opportunity where id=:recordId];
            if(oppo != null) recordTypeName = oppo.RecordType.Name;
          }
        else  if(sObjName == QUOTE_PROCESS_OBJ) {
            Quote_Process__c qpObj = [select id,Submission__r.RecordType.Name from Quote_Process__c  where id=:recordId];
            if(qpObj != null) recordTypeName = qpObj.Submission__r.RecordType.Name;
        }
        return recordTypeName;
    }
}