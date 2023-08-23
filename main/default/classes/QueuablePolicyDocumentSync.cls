public class QueuablePolicyDocumentSync implements Queueable,Database.AllowsCallouts { 
    
    public string policyId; 
    public string accountId; 
    
    public QueuablePolicyDocumentSync(String accountId,String policyId){
        this.policyId = policyId;
        this.accountId = accountId;
    }
    
    public void execute(QueueableContext context) {
        List<Quote> lstQuote = [Select Id,QuoteNumber,Quote_Type__c,Binder__c,Master_Binder__c,AccountId,Master_Binder__r.Name,Opportunity.RecordType.Name, 
                                Azure_Id__c,Rating_Status__c,Layer__c from Quote where Policy__c=:policyId And Status='Bound' 
                                AND Opportunity.RecordType.Name =: 'Aqueous' And Rating_Status__c='Clear' And Binder__c!=null
                                order by Endorsement_Quote_Bound_Date__c desc limit 1];
        GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', lstQuote[0], 'POstDocGenerationSync_Synchronous');
        
        List<Account> accList = [select Review_Requested_By__r.Email,Name,Reviewed_By__r.Email,Review_Requested_By__c,Review_Requested_By__r.Name,Reviewed_By__r.Name from Account where id=:accountId And Review_Requested_By__c!=null];
        List<Policy__c> policyList = [select id,name,Policy_Number__c from Policy__c where Id=:policyId];
        
        Account acc = new Account();
        acc.Id = accountId;
        acc.Action_Point__c = '';
        acc.Insured_Account_Update_Policy_Id__c = '';
        update acc;
        
        if(accList.size()>0){
            
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            String[] sendingTo = new String[]{accList[0].Review_Requested_By__r.Email};
                semail.setToAddresses(sendingTo);
            semail.setSubject('Insured Account Update Successful');
            String htmlbody = 'Hello,';
            htmlbody +='<br/>';
            htmlbody +='<p>The sanction on the Account: '+'<a href='+URL.getOrgDomainUrl().toExternalForm()+'/'+accList[0].Id+'>'+accList[0].Name+'</a>'+' has been cleared, and the';
            htmlbody +=' corresponding documents for the Insured Account Update have been generated';
            htmlbody +=' on the Policy: '+'<a href='+URL.getOrgDomainUrl().toExternalForm()+'/'+policyId+'>'+policyList[0].Policy_Number__c+'.'+'</a></p>';
            htmlbody += '<p>Kind Regards,</p>';
            htmlbody +='<p>'+accList[0].Reviewed_By__r.Name+'</p>';
            htmlbody +='<div><img src="https://irrinnsfdcdimages.blob.core.windows.net/aqueous/images/AQLine.jpg" height:2px;width:50%;text-align:left;margin-left:0;/>       <br> <br> </div> <div><img src="https://irrinnsfdcdimages.blob.core.windows.net/aqueous/images/aqueous_logo_rgb.png" width="250" height="75"/>       <a href="http://www.aqueousuw.com">www.aqueousuw.com</a>       <img src="https://irrinnsfdcdimages.blob.core.windows.net/aqueous/images/mgaa_4_Col_Hi_Res.jpg" width="72" height="72"/> </div> <br> <div>Aqueous Underwriting is a trading name of Aqueous Management Limited which is an appointed representative of Davies MGA Services Limited, a company authorised and regulated by the Financial Conduct Authority under firm reference number 597301 to carry on insurance distribution activities. Aqueous Management Limited is registered in England and Wales. Company Number 09634781. Registered Address at 10th Floor, 5 Churchill Place, London, E14 5HU.</div></br> <div><b>Confidentiality Statement</b></div> <br><div>This email message, including any attachments(s), is intended only for the named receipient(s) and may contain confidential, proprietary or legally priviledged information. Unauthorised individuals or entities are not permitted access to this information. Any dissemination, distribution, disclosure, or copying of this information is unauthorised and strictly proibited. If you have received this message in error, please advise the sender by reply email, and delete this message and any attachments.</div> <br><div>Further information on Aqueous’ Privacy Policy can be found by visiting <a href="https://aqueousuw.com/">https://aqueousuw.com/</a></div>';
            semail.setHtmlBody(htmlbody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
        }
    }
}