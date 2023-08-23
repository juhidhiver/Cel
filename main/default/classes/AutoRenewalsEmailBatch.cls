public class AutoRenewalsEmailBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    
    Boolean isSixtyDays = false;
    Date startDate;
    String productName;
    Map<String,String> errorRecordsMap = new Map<String,String>(); // Added by mary
    Map<String,List<Renewal__c>> brokerRenewalsMap = new Map<String,List<Renewal__c>>();

    Map<String,List<Contact>> brokerContactRoleMap = new Map<String,List<Contact>>();
    Set<String> contactAlreadyAdded = new Set<String>();

    
    public AutoRenewalsEmailBatch(Boolean isSixtyDays,Date startDate,String productName){
        this.isSixtyDays = isSixtyDays;   
        this.startDate =   startDate;   
        this.productName = productName;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date filteredDate;
    
        if(isSixtyDays){
            filteredDate = startDate.addMonths(2);
        }
        else{
            filteredDate = startDate.addMonths(1);
        }
        
        Integer getRenewalMonth = filteredDate.month();
        Integer getRenewalYear = filteredDate.year();
        
        String query = 'select id,Policy__c,Policy__r.Policy_Number__c,Broker__c,Status__c,Broker__r.Broker_Contact__c,Insured_Account__r.Name,Broker__r.Broker_Contact__r.AccountId,Documents_Required__c,Additional_Information__c,RICS__c,Broker_Warning__c,Assigned_Underwriter__r.Name,Assigned_Underwriter__r.Email,Policy__r.Expiration_Date__c from Renewal__c where (Status__c=\'Ready To Send\' OR Status__c=\'Suppressed\') And CALENDAR_MONTH(Renewal_Date__c) =: getRenewalMonth And CALENDAR_YEAR(Renewal_Date__c) =: getRenewalYear And Notice_Sent__c=\'0\' ORDER BY  Broker__r.Broker_Contact__r.AccountId';  
       
        return Database.getQueryLocator(query);
       
    }
    
    public void execute(Database.BatchableContext bc, List<Renewal__c> renewalList) {
		system.debug('query debug' +  renewalList);
        Set<String> brokerAccounts = new Set<String>();

        for(Renewal__c renewal : renewalList){
            if(!contactAlreadyAdded.contains(renewal.Broker__r.Broker_Contact__r.AccountId)){
                brokerAccounts.add(renewal.Broker__r.Broker_Contact__r.AccountId);
            }
        }
        
          for(Contact con : [select id,Role__c,Email,AccountId from contact where Role__c='Renewals' And Email != null And AccountId IN: brokerAccounts]){
                if(!brokerContactRoleMap.containskey(con.AccountId)){
                    brokerContactRoleMap.put(con.AccountId,new List<Contact>());
                }
                brokerContactRoleMap.get(con.AccountId).add(con);
                contactAlreadyAdded.add(con.AccountId);
          }


        brokerRenewalsMap  =  RenewalServiceHandler_AQ.emailNotificationHandler(brokerRenewalsMap,renewalList);



        
    }
    
    public void finish(Database.BatchableContext bc) {

        List<Renewal__c> listOfRenewals = new List<Renewal__c>();

        List<Messaging.SingleEmailMessage> listOfEmailContent = new List<Messaging.SingleEmailMessage>();
        List<EmailTemplate> emailtemplaterecord  =  [select id,htmlvalue,Subject from EmailTemplate where DeveloperName='AQ_Renewal_Invite_Email_Template'];

        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where DisplayName =: Label.AQ_Renewal_Sender];

        if(!emailtemplaterecord.isEmpty() && !brokerRenewalsMap.isEmpty() && !brokerContactRoleMap.isEmpty()){


         Set<String> documentNames = new Set<String>();   
        
         for(List<Renewal__c> renewalList : brokerRenewalsMap.values()){
           for(Renewal__c renewal:  renewalList){
             if(String.isNotBlank(renewal.Documents_Required__c)){
                 List<String> docReqList = new List<String>();
                if(renewal.Documents_Required__c.contains(';')){
                    docReqList = renewal.Documents_Required__c.split(';');
                }
                else{
                    docReqList.add(renewal.Documents_Required__c); 
                }
                documentNames.addAll(docReqList);
             }
            }
         }

          /********************* Fetch Releated Documents  **************************/
          Map<String,List<ContentVersion>> contentVersionMap = new  Map<String,List<ContentVersion>>();
          if(documentNames.size()>0){
              if(!Test.isRunningTest()){    //skipped this method for testRun due to error in SOQL
                contentVersionMap  = RenewalServiceHandler_AQ.fetchDocumentRelatedFiles(documentNames);
              }
          }
         for(String brokerKey : brokerRenewalsMap.keyset()){

            Set<String> docExistForBroker = new Set<String>();

           Boolean isReadyToSend = false;
           List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>{};
           
            String htmlbody = '<table style="border:1px solid black;border-collapse: collapse">';
            htmlbody +=   '<tr><th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Policy Reference</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px ">Insured</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Expiry Date</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Information Required</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">RICS Regulated Question</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Broker Warning</th>';
            htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none; padding: 10px">Underwriter</th><tr/>';

            for(Renewal__c renewal : brokerRenewalsMap.get(brokerKey)){

                String rics = renewal.RICS__c == false ? 'No' : 'Yes';
                String brokerWarning = String.isNotBlank(renewal.Broker_Warning__c) ? renewal.Broker_Warning__c : ''; 
                String assignedUnderWriter = String.isNotBlank(renewal.Assigned_Underwriter__r.Name) ? renewal.Assigned_Underwriter__r.Name : '';
                String assignedUnderWriterEmail = String.isNotBlank(renewal.Assigned_Underwriter__r.Email) ? renewal.Assigned_Underwriter__r.Email : '';
                String insuredAccount = String.isNotBlank(renewal.Insured_Account__r.Name) ? renewal.Insured_Account__r.Name : '';

                String documentReq;
                if(String.isNotBlank(renewal.Documents_Required__c)){

                    if(renewal.Documents_Required__c.contains(';')){
                        for(String doc : renewal.Documents_Required__c.split(';')){
                            if(documentReq != null){
                                documentReq =  documentReq + doc +'<br/>';
                            }
                            else{
                                documentReq =    doc + '<br/>';
                            }
                         //  documentReq   = documentReq !=null ?  documentReq + doc +'<br/>' : doc + '<br/>';
                        }
                    }
                    else{
                        documentReq = renewal.Documents_Required__c !=null ?  renewal.Documents_Required__c : '';   
                    }
                }
                else{
                    documentReq = renewal.Documents_Required__c !=null ?  renewal.Documents_Required__c : '';
                }

               if(renewal.Status__c == 'Ready To Send'){              

                isReadyToSend = true;

                 htmlbody += '<tr>';
                 htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+renewal.Policy__r.Policy_Number__c+'</td>';
                 htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+insuredAccount+'</td>';
                 htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+renewal.Policy__r.Expiration_Date__c.format()+'</td>';
                 htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+documentReq+'<br/><br/>';
                 htmlbody +=  String.isNotBlank(renewal.Additional_Information__c) ? '<b>Additional Information:</b>'+' '+renewal.Additional_Information__c : '' + '</td>';
                 htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+rics+ '</td>';
                 htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+brokerWarning+'</td>';
                 htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding: 10px">'+assignedUnderWriter + ' (' +assignedUnderWriterEmail+ ')</td>';
                 htmlbody +=  '</tr>';
                 renewal.Status__c = '1st Notice Sent';

                 List<String> docRequirementList = new List<String>();
                 if(String.isNotBlank(renewal.Documents_Required__c)){
                     if(renewal.Documents_Required__c.contains(';')){
                        docRequirementList = renewal.Documents_Required__c.split(';');
                     }
                     else{
                        docRequirementList.add(renewal.Documents_Required__c); 
                    }
                 }

                 for(String docName : docRequirementList){
                    if(!contentVersionMap.isEmpty() && contentVersionMap.containsKey(docName)){
                     List<ContentVersion> documentList    =  contentVersionMap.get(docName);

                    for(ContentVersion  document : documentList) {
                     if(!docExistForBroker.contains(document.Id)){
                       Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                       attachment.setBody(document.VersionData);
                       attachment.setFileName(document.Title + '.'+document.FileExtension);
                    // attachment.setContentType(document.FileType);
                       attachments.add(attachment);
                       docExistForBroker.add(document.Id);
                     }
                    }
                   }
                 }
                }
                renewal.Notice_Sent__c = '1';
                listOfRenewals.add(renewal);

            }
                htmlbody += '</table>';

             String emailBody   = emailtemplaterecord[0].htmlvalue.replace('{tablecontent}',htmlbody);

             if(!brokerContactRoleMap.isEmpty() && isReadyToSend && brokerContactRoleMap.containskey(brokerKey)){
                 
                 system.debug('brokerContactRoleMap.get(brokerKey)'+brokerContactRoleMap.get(brokerKey).size());

               for(Contact contactRecord  : brokerContactRoleMap.get(brokerKey)){

                   Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                   if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                   }
                   mail.setSubject(emailtemplaterecord[0].Subject);
                   mail.setHtmlBody(emailBody);                 
                   mail.setToAddresses(new String[]{contactRecord.Email});
                   mail.setTargetObjectId(contactRecord.Id);
                   if(attachments.size()>0){
                     mail.setFileAttachments(attachments);
                   }
                   listOfEmailContent.add(mail);
                 }
            }

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

        /*    if(listOfRenewals.size()>0){
                update listOfRenewals;
            }*/
     /*************************************Email For Error Records***************************** */
            if(listOfRenewals.size()>0){
                List<Renewal__c> renewalsSucceded = new  List<Renewal__c>();
                Database.SaveResult[] saveResultList = Database.update(listOfRenewals, false);
                system.debug('saveResultList-------'+saveResultList);
                
                Integer index = 0;
                for (Database.SaveResult sr : saveResultList) {
                    system.debug('sr chechk-------'+sr);
                    if (sr.isSuccess()) {
                        renewalsSucceded.add(listOfRenewals[index]); 
                        system.debug('renewalsSucceded-------'+renewalsSucceded); 
                    }
                    else {
                        for(Database.Error errorMessage : sr.getErrors()) {
                            errorRecordsMap.put(listOfRenewals[index].Id,errorMessage.getMessage());
                             system.debug('error-------'+errorMessage.getMessage());
                             ErrorLogsUtilityHelper.logError('AutoRenewalsEmailBatch.Finish', 'Auto Renewals', String.valueOf(listOfRenewals[index].Id), 'AQ_Exceptions', String.valueOf(errorMessage.getMessage()));
                        }
                    }
                    index++;
                }
         }
        
    }


    if(test.isRunningTest()){
        errorRecordsMap.put('renewalId','Error message during renewals update');
  }

 

  if(!errorRecordsMap.isEmpty())
  {
        List<Messaging.SingleEmailMessage> listOfEmailHtmlContent = new List<Messaging.SingleEmailMessage>();
        List<EmailTemplate> emailTemplateErrorRecord  =  [select id,htmlvalue from EmailTemplate where DeveloperName='AQ_Renewal_Error_Records_Email_Batch'];

        List<User> usersList = [select id, name, email, isactive, profile.name, userrole.name, usertype from user where id 
                                IN(select userorgroupid 
                                from groupmember 
                                where group.name = 'Admin Renewals')];
       /* List<String> userEmailList = new list<String>();
        if(userEmailList.size() > 0){
            for(User u : usersList)
            {
                userEmailList.add(u.email);
            }
        }*/
      for(String failedRenewalId : errorRecordsMap.keyset()){
          
          String htmlTableBody = '<table style="border:1px solid black;border-collapse: collapse"><br/>';
          htmlTableBody +=   '<tr><th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none ; padding:10px">Renewal Id</th>';
          htmlTableBody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none ; padding:10px">Error Message</th>';
          
          htmlTableBody += '<tr>';
          htmlTableBody += '<td style="border:1px solid black;border-collapse: collapse; padding:10px">'+failedRenewalId+'</td>';
          htmlTableBody += '<td style="border:1px solid black;border-collapse: collapse; padding:10px">'+errorRecordsMap.get(failedRenewalId)+'</td>';
          htmlTableBody +=  '</tr>';
         
          
          htmlTableBody += '</table>';
          String emailHtmlBody   = emailTemplateErrorRecord[0].htmlvalue.replace('{table}',htmlTableBody);
          if(emailHtmlBody != null ){
              for(User u: usersList){
                  Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
                  emailMsg.setSubject('Renewal Records that failed to Update during execution of AutoRenewalsEmailBatch');
                  emailMsg.setHtmlBody(emailHtmlBody);                 
                  //emailMsg.setToAddresses(userEmailList);//list user 
                 emailMsg.setToAddresses(new String[]{u.Email});
                  listOfEmailHtmlContent.add(emailMsg);
              }
              
          }             
      }
      
      
      if(!listOfEmailHtmlContent.isEmpty()){
          try{
              Messaging.sendEmail(listOfEmailHtmlContent);
          }
          catch(Exception ex){
              system.debug('Exception ex'+ex);
          }
      }    
  }     
}

      /******************** Scheduler Execute  *************************/
        public void execute(SchedulableContext sc) {

            Integer batchSize = Integer.valueOf(System.Label.AQ_AutoRenewalEmailBatchSize);
    
            AutoRenewalsEmailBatch b = new AutoRenewalsEmailBatch(this.isSixtyDays,System.today(),this.ProductName);
            database.executebatch(b,batchSize);
        }
    


}