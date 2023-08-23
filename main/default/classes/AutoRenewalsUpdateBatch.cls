/**************************************************************************************************
 * Class Name: AutoRenewalsUpdateBatch
 * Author: Mary Elizabeth
 * Date: 03-08-2022
 * Description: Batch Class to update Renewal Status to Expired if the Renewal date is less than todays date
 * Test Class: 
 **************************************************************************************************/
public class AutoRenewalsUpdateBatch implements Database.Batchable<sObject>,Schedulable,Database.Stateful{

    Map<String,List<RenewalWrapper>> mapOfRenewalWrapp = new Map<String,List<RenewalWrapper>>();
    Map<String,String> mapOfAQUnderwriter = new Map<String,String>();
    Set<String> AQUnderWriter = new Set<String>();
    List<RenewalWrapper> renewalWrapperList = new List<RenewalWrapper>();
    
    public AutoRenewalsUpdateBatch() {

    }
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = 'Select id,Name,Broker__r.Broker_Contact__r.Account.Appointed__c,Insured_Account__c,Notice_Sent__c,Insured_Account__r.Renewal_Warning__c,Claims_Number__c,Renewal_Warning__c,Broker_Appointed__c,Policy__c,Policy__r.Policy_Number__c,Claim_Amount__c,Payment_Status__c,Renewal_Date__c, Status__c,Assigned_Underwriter__r.username,Assigned_Underwriter__c from Renewal__c where (Status__c = \'Ready to Send\' OR Status__c = \'Suppressed\') order by name asc' ;
        System.debug('return text '+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc ,List<Renewal__c> renewalList){

        Set<String> accountIds = new Set<String>();
        Set<String> policyIds = new Set<String>();
        Map<String,AggregateResult> claimDataSummaryMap = new  Map<String,AggregateResult>();
        Map<String,String> paymentStatusMap = new  Map<String,String>();
        Map<String,String> labelAPIMap = new Map<String,String>();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType renewalSchema = schemaMap.get('Renewal__c');
        Map<String, Schema.SObjectField> fieldMap = renewalSchema.getDescribe().fields.getMap();
          for (String fieldName: fieldMap.keySet()) {
                labelAPIMap.put(fieldName ,fieldMap.get(fieldName).getDescribe().getLabel());
          }


        System.debug('***********RenewalList******'+renewalList);

        try{
        list<Renewal__c> updateRenewalList = new List<Renewal__c>();
        if(renewalList.size()> 0)
        {
            for(Renewal__c renewal : renewalList){
                accountIds.add(renewal.Insured_Account__c);
                policyIds.add(renewal.Policy__c);
                AQUnderWriter.add(renewal.Assigned_Underwriter__c);
                //renewal.Status__c = 'Expired';
               // updateRenewalList.add(renewal);
            }
            for(AggregateResult aggr : [select Account__c acc,SUM(Total_Incurred__c) sumInsured,COUNT(id) countIds from Claim_Data__c  GROUP BY Account__c HAVING Account__c IN:accountIds ]){
                claimDataSummaryMap.put((String)aggr.get('acc'),aggr);
            }
            for(Payment_Data__c paymentrec : [select id,Paid_Status__c,Quote__c,quote__r.Endorsement_Effective_Date__c,quote__r.Policy__r.Renewal_Date__c,quote__r.Quote_Type__c,Policy__c
                                             from Payment_Data__c where Policy__c IN: policyIds]){
                if(paymentrec.Paid_Status__c=='Not Paid' || paymentrec.Paid_Status__c=='Query'){
                   paymentStatusMap.put(paymentrec.Policy__c,'Outstanding'); 
                }
            }

            for(Renewal__c renewalrec : renewalList){
                    if(renewalrec.Renewal_Date__c < System.Today()){
                        renewalrec.Status__c = 'Expired';
                        updateRenewalList.add(renewalrec);
                    }
                else{

                    RenewalWrapper renewalwrapp = new RenewalWrapper();
                    renewalwrapp.fieldMapList = new List<fieldMap>();

                    if(!mapOfRenewalWrapp.containskey(renewalrec.Assigned_Underwriter__r.username)){
                        mapOfRenewalWrapp.put(renewalrec.Assigned_Underwriter__r.username,new List<RenewalWrapper>{});  
                    }


                    if(renewalrec.Broker_Appointed__c != renewalrec.Broker__r.Broker_Contact__r.Account.Appointed__c){
                        renewalwrapp.fieldMapList.add(new fieldMap(labelAPIMap.get('broker_appointed__c'),String.valueOf(renewalrec.Broker_Appointed__c),String.valueOf(renewalrec.Broker__r.Broker_Contact__r.Account.Appointed__c)));
                        renewalrec.Broker_Appointed__c = renewalrec.Broker__r.Broker_Contact__r.Account.Appointed__c;
                 //       mapOfRenewalWrapp.get(renewalrec.Assigned_Underwriter__r.username).add(new RenewalWrapper(renewalrec.Name,renewalrec.Policy__r.Policy_Number__c,renewalrec.Renewal_Date__c.format(),labelAPIMap.get('Broker_Appointed__c'),String.valueOf(renewalrec.Broker_Appointed__c),String.valueOf(renewalrec.Broker__r.Broker_Contact__r.Account.Appointed__c)));
                    }
                    if(renewalrec.Renewal_Warning__c != renewalrec.Insured_Account__r.Renewal_Warning__c){
                        renewalwrapp.fieldMapList.add(new fieldMap(labelAPIMap.get('renewal_warning__c'),String.valueOf(renewalrec.Renewal_Warning__c),String.valueof(renewalrec.Insured_Account__r.Renewal_Warning__c)));
                        renewalrec.Renewal_Warning__c = renewalrec.Insured_Account__r.Renewal_Warning__c;
                   //     mapOfRenewalWrapp.get(renewalrec.Assigned_Underwriter__r.username).add(new RenewalWrapper(renewalrec.Name,renewalrec.Policy__r.Policy_Number__c,renewalrec.Renewal_Date__c.format(),labelAPIMap.get('Renewal_Warning__c'),String.valueOf(renewalrec.Renewal_Warning__c),String.valueof(renewalrec.Insured_Account__r.Renewal_Warning__c)));
                    }
                    if(!claimDataSummaryMap.isEmpty() && claimDataSummaryMap.containskey(renewalrec.Insured_Account__c) && (renewalrec.Claims_Number__c !=  Integer.valueof(claimDataSummaryMap.get(renewalrec.Insured_Account__c).get('countIds'))) ){
                        renewalwrapp.fieldMapList.add(new fieldMap(labelAPIMap.get('claims_number__c'),String.valueOf(renewalrec.Claims_Number__c),String.valueof(claimDataSummaryMap.get(renewalrec.Insured_Account__c).get('countIds'))));
                        renewalrec.Claims_Number__c = Integer.valueof(claimDataSummaryMap.get(renewalrec.Insured_Account__c).get('countIds'));
                     //   mapOfRenewalWrapp.get(renewalrec.Assigned_Underwriter__r.username).add(new RenewalWrapper(renewalrec.Name,renewalrec.Policy__r.Policy_Number__c,renewalrec.Renewal_Date__c.format(),labelAPIMap.get('Claims_Number__c'),String.valueOf(renewalrec.Claims_Number__c),String.valueof(claimDataSummaryMap.get(renewalrec.Insured_Account__c).get('countIds'))));

                    }
                    if(!claimDataSummaryMap.isEmpty() && claimDataSummaryMap.containskey(renewalrec.Insured_Account__c) && (renewalrec.Claim_Amount__c !=  claimDataSummaryMap.get(renewalrec.Insured_Account__c).get('sumInsured')) ){
                        renewalwrapp.fieldMapList.add(new fieldMap(labelAPIMap.get('claim_amount__c'),String.valueOf(renewalrec.Claim_Amount__c),String.valueof(claimDataSummaryMap.get(renewalrec.Insured_Account__c).get('sumInsured'))));
                        renewalrec.Claim_Amount__c  =  (Decimal)(claimDataSummaryMap.get(renewalrec.Insured_Account__c).get('sumInsured'));
                       // mapOfRenewalWrapp.get(renewalrec.Assigned_Underwriter__r.username).add(new RenewalWrapper(renewalrec.Name,renewalrec.Policy__r.Policy_Number__c,renewalrec.Renewal_Date__c.format(),labelAPIMap.get('Claim_Amount__c'),String.valueof(renewalrec.Claim_Amount__c),String.valueof(claimDataSummaryMap.get(renewalrec.Insured_Account__c).get('sumInsured'))));

                    }
                    if(!paymentStatusMap.isEmpty() && paymentStatusMap.containsKey(renewalrec.policy__c) && renewalrec.Payment_Status__c != paymentStatusMap.get(renewalrec.policy__c)){
                        renewalwrapp.fieldMapList.add(new fieldMap(labelAPIMap.get('payment_status__c'),String.valueOf(renewalrec.Payment_Status__c),paymentStatusMap.get(renewalrec.policy__c)));
                        renewalrec.Payment_Status__c  =  paymentStatusMap.get(renewalrec.policy__c);
                      //  mapOfRenewalWrapp.get(renewalrec.Assigned_Underwriter__r.username).add(new RenewalWrapper(renewalrec.Name,renewalrec.Policy__r.Policy_Number__c,renewalrec.Renewal_Date__c.format(),labelAPIMap.get('Payment_Status__c'),renewalrec.Payment_Status__c,paymentStatusMap.get(renewalrec.policy__c)));

                    }
                    else if(renewalrec.Payment_Status__c !='Paid' &&  !paymentStatusMap.containsKey(renewalrec.policy__c)){
                        renewalwrapp.fieldMapList.add(new fieldMap(labelAPIMap.get('payment_status__c'),String.valueOf(renewalrec.Payment_Status__c),'Paid'));
                        renewalrec.Payment_Status__c = 'Paid';
                       // mapOfRenewalWrapp.get(renewalrec.Assigned_Underwriter__r.username).add(new RenewalWrapper(renewalrec.Name,renewalrec.Policy__r.Policy_Number__c,renewalrec.Renewal_Date__c.format(),labelAPIMap.get('Payment_Status__c'),renewalrec.Payment_Status__c,'Paid'));

                    }

                      if(renewalwrapp.fieldMapList.size()>0){
                        renewalwrapp.Name = renewalrec.Name;
                        renewalwrapp.PolicyNumber = renewalrec.Policy__r.Policy_Number__c;
                        renewalwrapp.RenewalDate = renewalrec.Renewal_Date__c.format();
                       // mapOfRenewalWrapp.get(renewalrec.Assigned_Underwriter__r.username).add(renewalwrapp);
                        updateRenewalList.add(renewalrec);
                        renewalWrapperList.add(renewalwrapp);
                      }

                }
            }

        }

        if(updateRenewalList.size() > 0)
        {
            Database.SaveResult[] saveResultList = Database.update(updateRenewalList, false);
        
        }
    }
    catch(Exception e){
        System.debug('Error while updating renewals status to Expired: '
        + ' Error = ' + e.getMessage());
    }
/*
        if(saveResultList.size() > 0){
        Integer index = 0;
        List<Renewal__c> renewalsExpired = new  List<Renewal__c>();
        for(Database.SaveResult sr : saveResultList)
            {
                if(sr.isSuccess())
                {
                    renewalsExpired.add(updateRenewalList[index]);
                    System.debug('renewalsExpired---'+renewalsExpired);
                }
                else 
                {
                    system.debug('Error while updating renewals status to Expired: '+sr.getErrors());
                }
            }

        }
    
*/
    }
    /******************** Scheduler Execute  *************************/

    public void execute(SchedulableContext sc)
    {
        AutoRenewalsUpdateBatch b = new AutoRenewalsUpdateBatch();
        database.executebatch(b);
    }

    public void finish(Database.BatchableContext bc)
    {
      /*  Map<String,String> mapofUserEmail = new Map<String,String>();
        for(User userRec : [select id,Email,username from User where Id IN: AQUnderWriter]){
            mapofUserEmail.put(userRec.username,userRec.Email);
        }*/
         List<String> emailuserId = new List<String>();
         List<String> emailIds = new List<String>();
        
           for(GroupMember objMember : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE Group.Name = 'AQAutoRenewalsUWTeam']){
           if(String.valueOf(objMember.UserOrGroupId).startsWith('005')){
            emailuserId.add(String.valueOf(objMember.UserOrGroupId));
            }  
          }

        for(user userrec : [select id,email from user where id in:emailuserId and email != null ] ){
            emailIds.add(userrec.email);
        }

        List<EmailTemplate> emailtemplaterecord = [select id,htmlvalue,Subject from EmailTemplate where DeveloperName='AQ_Auto_Renewals_Update_Email_Template'];

        List<Messaging.SingleEmailMessage> listOfEmailContent = new List<Messaging.SingleEmailMessage>();


        //for(String username : mapOfRenewalWrapp.keyset()){

          //  if(mapOfRenewalWrapp.get(username).size()>0){
       
            String htmlbody = '<table style="border:1px solid black;border-collapse: collapse">';
            htmlbody +=   '<tr><th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Name</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Policy Number</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Renewal Date</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Fields Updated</th></tr>';
          
            for(RenewalWrapper renewalRecord : renewalWrapperList){
                htmlbody += '<tr>';
                htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+renewalRecord.Name+'</td>';
                htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+renewalRecord.PolicyNumber+'</td>';
                htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+renewalRecord.RenewalDate+'</td>';

                htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">';
                for(fieldMap field  : renewalRecord.fieldMapList){
                    String strOldValue = field.oldValue != null ? field.oldValue : '';
                    String strNewValue = field.newValue != null ? field.newValue : '';
                    htmlbody+= '<b>'+field.Label+': '+'</b>'+'Old Value  = "' +strOldValue+'", New Value = "'+strNewValue+'"'+'</br>';
                }
                htmlbody+= '</td>';

                htmlbody +=  '</tr>';
            }
            htmlbody += '</table>';


            if(renewalWrapperList.size()>0){
              String emailBody  = emailtemplaterecord[0].htmlvalue.replace('{tablecontent}',htmlbody);
              Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
              mail.setSubject(emailtemplaterecord[0].Subject);
              mail.setHtmlBody(emailBody);                 
              mail.setToAddresses(emailIds);
              listOfEmailContent.add(mail);
            }
        if(!listOfEmailContent.isEmpty()){
            try{
              system.debug('listOfEmailContent'+listOfEmailContent.size());
              Messaging.sendEmail(listOfEmailContent);
            }
            catch(Exception ex){
                system.debug('Exception ex'+ex);
            }
        }


    }

    public class RenewalWrapper{
        public  string Name;
        public  string PolicyNumber;
        public  string RenewalDate;
        public List<fieldMap> fieldMapList; 
    }
     public class fieldMap{
        public  string Label;
        public  string oldValue;
        public  string newValue;

        public fieldMap(String Label,String oldValue,String newValue){
            this.Label = Label;
            this.oldValue = oldValue;
            this.newValue = newValue;
        }
     }
}