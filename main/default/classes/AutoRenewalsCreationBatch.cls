public class AutoRenewalsCreationBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    
    String ProductName;
    Date renewalCreationDate;
    RenewalServiceHandler_AQ.AutoRenewalsWrapper wrapperAutoRenewals;
    String errorMessage; 
        Map<String,String> errorRecordsMap = new Map<String,String>();
    
    public AutoRenewalsCreationBatch(String ProductName, Date renewalCreationDate){
        this.ProductName = ProductName;
        this.renewalCreationDate = renewalCreationDate;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        Date renewalDate = renewalCreationDate.addmonths(3);
        Integer getRenewalMonth = renewalDate.month();
        Integer getRenewalYear = renewalDate.year();
        String query = 'SELECT Id , Policy_Status__c , Product_Name__c ,Account__r.Renewal_Warning_Reason__c, Renewal_Date__c , Account__c , Account__r.Renewal_Warning__c, Renewal_Completed__c, (Select id , status, Layer__c ,Quote_Type__c, Opportunity.Main_Profession__c , OpportunityId from Quotes__r ORDER BY CreatedDate DESC Limit 1) from Policy__c where Policy_Status__c = \'Bound\'  and Product_Name__c = :ProductName and  CALENDAR_MONTH(Renewal_Date__c) =: getRenewalMonth AND CALENDAR_YEAR(Renewal_Date__c) =: getRenewalYear AND Renewal_Completed__c = false ORDER BY Account__c';
        
        System.debug('return text '+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
        
    }
    public void execute(Database.BatchableContext bc, List<Policy__c> policy) {
        
        System.debug('*****************policy**************'+policy);
        List<Policy__c> lstPoliciesForRenewal = new List<Policy__c>();
        for(Policy__c objPol: policy){
            if(objPol.Quotes__r.size() > 0 && objPol.Quotes__r[0].Status == 'Bound'){
                lstPoliciesForRenewal.add(objPol);
            }
        }
        
        if(!lstPoliciesForRenewal.isEmpty()){
            List<Renewal__c> renewalList   =  RenewalServiceHandler_Common.createRenewalRecords(lstPoliciesForRenewal,this.ProductName);
            if(renewalList.size()>0){
                List<Renewal__c> renewalsSucceded = new  List<Renewal__c>();
                Database.SaveResult[] saveResultList = Database.insert(renewalList, false);
                
                
                Integer index = 0;
                for (Database.SaveResult sr : saveResultList) {
                    system.debug('sr chechk-------'+sr);
                    if (sr.isSuccess()) {
                        renewalsSucceded.add(renewalList[index]);  
                    }
                    else {
                        for(Database.Error errorMessage : sr.getErrors()) {
                            errorRecordsMap.put(renewalList[index].Policy__c,errorMessage.getMessage());
                             system.debug('error-------');
                        }
                    }
                    index++;
                }
                wrapperAutoRenewals = RenewalServiceHandler_AQ.autoAssignRenewals(wrapperAutoRenewals,renewalsSucceded);
            }
        }
    }
    
    /******************** Scheduler Execute  *************************/
    public void execute(SchedulableContext sc) {
        
        Integer batchSize = Integer.valueOf(System.Label.AQ_AutoRenewalBatchSize);
        AutoRenewalsCreationBatch b = new AutoRenewalsCreationBatch(this.ProductName, System.today());
        database.executebatch(b,batchSize);
    }
    
    
    public void finish(Database.BatchableContext bc) {
        
        List<Messaging.SingleEmailMessage> listOfEmailContent = new List<Messaging.SingleEmailMessage>();
        List<EmailTemplate> emailTemplateRecord  =  [select id,htmlvalue from EmailTemplate where DeveloperName='Renewal_Error_Records_Email'];
        
        set<String> recipientsIds = new Set<String>();
        List<User> userList = [select id, name, email, isactive, profile.name, userrole.name, usertype from user where id 
                               IN(select userorgroupid 
                                  from groupmember 
                                  where group.name = 'Admin Renewals')];

        if(test.isRunningTest()){
              errorRecordsMap.put('policyId','Error message for renewals insertion');
        }
        if(!errorRecordsMap.isEmpty())
        {
            for(String failedPolicyId : errorRecordsMap.keyset()){
                
                String htmlbody = '<table style="border:1px solid black;border-collapse: collapse"><br/>';
                htmlbody +=   '<tr><th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none ; padding:10px">Policy Id</th>';
                htmlbody +=   '<th style="border:1px solid black;border-collapse: collapse; border-bottom-style: none ; padding:10px">Error Message</th>';
                
                htmlbody += '<tr>';
                htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding:10px">'+failedPolicyId+'</td>';
                htmlbody += '<td style="border:1px solid black;border-collapse: collapse; padding:10px">'+errorRecordsMap.get(failedPolicyId)+'</td>';
                htmlbody +=  '</tr>';
               
                
                htmlbody += '</table>';
                String emailBody   = emailTemplateRecord[0].htmlvalue.replace('{table}',htmlbody);
                if(emailBody != null ){
                    for(User u: userList){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setSubject('Renewal Records that failed to Insert in AutoRenewalsCreationBatch');
                        mail.setHtmlBody(emailBody);                 
                        mail.setToAddresses(new String[]{u.Email});
                        listOfEmailContent.add(mail);
                    }
                    
                }             
            }
            
            
            if(!listOfEmailContent.isEmpty()){
                try{
                    Messaging.sendEmail(listOfEmailContent);
                }
                catch(Exception ex){
                    system.debug('Exception ex'+ex);
                }
            }    
        }     
    }
    
   
    
    
}