/*************************************************
* Class Name: GenerateEmailTemplateHandler
* Author: Prachi
* Date: 
* Description: GenerateEmailTemplateHandler
* Revison : 
*************************************************/
public with sharing class GenerateEmailTemplateHandler {
    @AuraEnabled
    public static sucesMsg getEmailList(String oppId){
        //get Object Name QuoteProcess or Opportunity
        String subId = getSubmissionId(oppId);
        List<Broker_Account__c> brokers = new List<Broker_Account__c>();
        Opportunity oppRec;
        
        if(subId!=null){
         	brokers = [Select Broker_Name__c,
                                           Broker_Contact__r.Name, Broker_Contact__r.Email
                                            From Broker_Account__c
                                            Where Opportunity__c = :subId
                                            And IsPrimaryBroker__c = true limit 1];
        	oppRec = [SELECT Id, Owner.Email FROM Opportunity where Id=:subId];
        

       if (brokers.isEmpty()){
            return new sucesMsg(false, 'This Submission has no primary Broker!'); 
        } else {
            if(String.isNotBlank(brokers[0].Broker_Contact__r.Email)){
                sucesMsg mess = new sucesMsg(true, 'Success');
                mess.data = brokers[0].Broker_Contact__r.Email;
                if(oppRec!=null){
                    mess.dataCClist = oppRec.Owner.Email;
                }
                return mess;
            } else {
                    return new sucesMsg(false, 'This primary Broker Contact has empty email address!');
            }
        }
        }
        else {
                    return new sucesMsg(false, 'Please create a submission before continuing to use the Email Template.');
            }
                             
    }
    
     @AuraEnabled
    public static boolean checkQuotesEmpty(String oppId){
        List<Quote> totalQuotes = new List<Quote>();
        String subId = getSubmissionId(oppId);
        if(subId!=null){
           totalQuotes = [Select Id, Name, Status, Layer__c from Quote where OpportunityId=:subId]; 
        }
       if(totalQuotes.size()>=1){
            return true;
        }
        else 
            return false;
    }
    
    

    /*************************************************
    * Method Name: getEmailTemplates
    * Author: Prachi 
    * Date: 22-March-2021
    * Params: String oppId
    * Return: List<EmailTemplate>
    * Exceptions: 
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static List<EmailTemplate> getEmailTemplates(String oppId){
        List<EmailTemplate> emailTemp = new list<EmailTemplate>();
		String subId = getSubmissionId(oppId);
        //Dynamic query
        List<String> fields = new List<String>();
        List<String> params = new List<String>();
        String condition = '';
        String objName = 'EmailTemplate';
        
        fields.add('Id');
        fields.add('Name');
        fields.add('Subject');

        //get Object Name QuoteProcess or Opportunity and RecordType Submission
        String recordTypeOpp = getOpportunityRecordType(oppId);
        List<Quote> primaryQuoteList = [Select Id, Name, Status, Layer__c from Quote 
                                        where OpportunityId=:subId AND Layer__c='Primary' AND Status='Quoted'];
        String primaryQuoteTemp = '';
        if(!primaryQuoteList.isEmpty()){
            primaryQuoteTemp = 'DeveloperName = \'Quote_Email_Primary\' ';
            params.add(primaryQuoteTemp);
        }
        List<Quote> excessQuoteList = [Select Id, Name, Status, Layer__c from Quote 
                                        where OpportunityId=:subId AND Layer__c='Excess' AND Status='Quoted'];
        String excessQuoteTemp = '';
        if(!excessQuoteList.isEmpty()){
            excessQuoteTemp = 'DeveloperName = \'Quote_Email_Excess\' ';
            params.add(excessQuoteTemp);
        }
         List<Quote> primaryBindList = [Select Id, Name, Status, Layer__c from Quote 
                                        where OpportunityId=:subId AND Layer__c='Primary' AND Status='Bound'];
        /*String primaryBindTemp = '';
        if(!primaryBindList.isEmpty()){
            primaryBindTemp = 'DeveloperName = \'Bind_Email_Primary\' ';
            params.add(primaryBindTemp);
        }
        List<Quote> excessBindList = [Select Id, Name, Status, Layer__c from Quote 
                                        where OpportunityId=:subId AND Layer__c='Excess' AND Status='Bound'];
        String excessBindTemp = '';
        if(!excessBindList.isEmpty()){
            excessBindTemp = 'DeveloperName = \'Bind_Email_Excess\' ';
            params.add(excessBindTemp);
        }*/
        String genericTemp = '';
        List<Quote> totalQuotes = [Select Id, Name, Status, Layer__c from Quote where OpportunityId=:subId];
        if(recordTypeOpp == Label.Aqueous_RT && totalQuotes.size()>=1){ 
            genericTemp = 'DeveloperName = \'Generic_Email\' ';
            params.add(genericTemp);
            //deScripTionEmail = Label.Description_AQ_Email_Template;
        }
        String holdCoverTemp = '';
        
        if(recordTypeOpp == Label.Aqueous_RT && totalQuotes.size()>=1){ 
            holdCoverTemp = 'DeveloperName = \'Hold_Cover_Email\' ';
            params.add(holdCoverTemp);
        }
        
         condition = String.join(params, ' OR ');
         String sortCondition = ' ORDER BY Name ASC';
         String query = CommonUtil.buildQuery(fields, objName, condition) + sortCondition;
         System.debug('template query-->'+query);
         emailTemp = (List<EmailTemplate>) Database.query(query);
        System.debug('##emailTemp'+emailTemp);
        return emailTemp;
    }

    /*************************************************
    * Method Name: getTemplateDetails
    * Author: Prachi
    * Date: 22-March-2021
    * Params: string templateId, String oppId
    * Return: EmailTemplate
    * Exceptions: 
    * Revision: 
    *************************************************/
    @AuraEnabled 
    public static EmailTemplate getTemplateDetails(string templateId, String oppId, String selectQuoteId){      
        List<EmailTemplate> emailTempLst = [SELECT Id,Name,Subject,HtmlValue  
                                            FROM EmailTemplate 
                                            WHERE ID =: templateId];
        if (emailTempLst.isEmpty()){
            return new EmailTemplate();
        }

        //get Object Name QuoteProcess or Opportunity and RecordType Submission
        String subId = getSubmissionId(oppId);
        Opportunity opp = [SELECT Id, (Select Id, OpportunityId, Layer__c From Quotes 
                                      WHERE OpportunityId = :subId ORDER BY CreatedDate ASC) 
            						FROM Opportunity where Id=:subId];
        //Quote qRec = opp.Quotes[0];
        String selectedQuoteId = selectQuoteId;
        String recordTypeOpp = getOpportunityRecordType(oppId);
        if(recordTypeOpp == Label.Aqueous_RT){ //RecordType AQ
            return fillInformationForEmailAQ(emailTempLst[0],subId, selectedQuoteId);
        }
        else{
            return new EmailTemplate();  
        }   
    }


    /*************************************************
    * Method Name: fillInformationForEmailAQ
    * Author: Prachi
    * Date: 22-Mar-2021
    * Params: EmailTemplate, String Opportunity Id
    * Return: EmailTemplate
    *************************************************/
    public static EmailTemplate fillInformationForEmailAQ(EmailTemplate tempEmail, String oppId, String selectedQuoteId){
        String htmlBody = tempEmail.HtmlValue;
        String htmlSubject = tempEmail.Subject;
        Opportunity opp = [SELECT Id, Name, Effective_Date__c, Expiration_Date__c, Loss_Reason__c,
                                Policy__r.Policy_Number__c, Policy__r.Effective_Date__c, Policy__r.Expiration_Date__c,
                                Prior_Policy__r.Policy_Number__c, Type,
                                Agency__r.Name, Agency__r.BillingStreet,Agency__r.BillingCity,
                                Agency__r.BillingPostalCode,Agency__r.BillingState,Account.BillingState,Account.Name,
                                Owner.Name, Owner.Title, Owner.Phone, Owner.MobilePhone, Owner.Email,
                                (Select Broker_Name__c, CreatedDate,Broker_Contact__r.FirstName,
                                        Broker_Contact__r.Name, Broker_Contact__r.Email,
                                        Broker_Contact__r.Account.Name,Broker_Contact__r.Account.BillingStreet,
                                        Broker_Contact__r.Account.BillingCity,Broker_Contact__r.Account.BillingPostalCode,
                                        Broker_Contact__r.Account.BillingState
                                    From Opportunity_Accounts1__r 
                                    Where IsPrimaryBroker__c = true limit 1),
                           (Select Id, Name, OpportunityId, Layer__c, QuoteNumber, Effective_Date__c From Quotes WHERE OpportunityId =:oppId AND Id=:selectedQuoteId LIMIT 1)
                            FROM Opportunity
                            WHERE Id =:oppId limit 1];
        //system.debug('opp='+opp);                    
        if(opp != null && !opp.Opportunity_Accounts1__r.isEmpty()){          
            Broker_Account__c broker = opp.Opportunity_Accounts1__r[0];
            //system.debug('broker='+broker);
            if (broker.Broker_Contact__r != null){
                system.debug(broker.Broker_Contact__r.Email);
                //get valuesReplace
                Map<String,String> valuesReplace = new Map<String,String>();
                valuesReplace.put(genKeyToHTML('IssuedDate'), String.valueOf(convertDateUS(Date.today())));
                valuesReplace.put(genKeyToHTML('BrokerName'), broker.Broker_Name__c);
                valuesReplace.put(genKeyToHTML('BrokerFirstName'), broker.Broker_Contact__r.FirstName);

                valuesReplace.put(genKeyToHTML('AgencyName'),broker.Broker_Contact__r.Account.Name);
                valuesReplace.put(genKeyToHTML('AgencyStreet'),broker.Broker_Contact__r.Account.BillingStreet);
                valuesReplace.put(genKeyToHTML('AgencyCity'),broker.Broker_Contact__r.Account.BillingCity);
                valuesReplace.put(genKeyToHTML('AgencyState'),broker.Broker_Contact__r.Account.BillingState);
                valuesReplace.put(genKeyToHTML('AgencyPostalCode'),broker.Broker_Contact__r.Account.BillingPostalCode);
                
                valuesReplace.put(genKeyToHTML('NamedInsured'),opp.Account.Name); //insured business Account Name
                valuesReplace.put(genKeyToHTML('EffectiveDate'),String.valueOf(convertDateUS(opp.Effective_Date__c)));
                valuesReplace.put(genKeyToHTML('ExpirationDate'),String.valueOf(convertDateUS(opp.Expiration_Date__c)));
                valuesReplace.put(genKeyToHTML('BORDate'),String.valueOf(convertDateTimeUS(broker.CreatedDate))); 
                valuesReplace.put(genKeyToHTML('ChangeDate'),String.valueOf(convertDateUS(opp.Effective_Date__c)));
                valuesReplace.put(genKeyToHTML('NeedByDate'),String.valueOf(convertDateUS(Date.today().addDays(5))));
                //valuesReplace.put(genKeyToHTML('DeclinationReason'),String.isNotBlank(opp.Additional_UW_Details__c) ? opp.Additional_UW_Details__c : '');

                valuesReplace.put(genKeyToHTML('PolicyNumber'), String.isNotBlank(opp.Policy__r.Policy_Number__c)? opp.Policy__r.Policy_Number__c : '');
                valuesReplace.put(genKeyToHTML('PolicyEffectiveDate'),String.valueOf(convertDateUS(opp.Policy__r.Effective_Date__c)));
                valuesReplace.put(genKeyToHTML('PolicyExpirationDate'),String.valueOf(convertDateUS(opp.Policy__r.Expiration_Date__c)));

                valuesReplace.put(genKeyToHTML('AccountState'),String.isNotBlank(opp.Account.BillingState)? opp.Account.BillingState : '');

                valuesReplace.put(genKeyToHTML('Underwriter'),String.isNotBlank(opp.Owner.Name) ? opp.Owner.Name : '');
                valuesReplace.put(genKeyToHTML('UnderwriterTitle'),String.isNotBlank(opp.Owner.Title) ? opp.Owner.Title : '');
                
                string phone = '';
                if(String.isNotBlank(opp.Owner.Phone) && String.isNotBlank(opp.Owner.MobilePhone)) phone = opp.Owner.Phone + ' / ' + opp.Owner.MobilePhone;
                else if(String.isNotBlank(opp.Owner.Phone)) phone = opp.Owner.Phone;
                else if(String.isNotBlank(opp.Owner.MobilePhone)) phone = opp.Owner.MobilePhone;
                valuesReplace.put(genKeyToHTML('UnderwriterPhone'),phone);
                
                valuesReplace.put(genKeyToHTML('UnderwriterEmail'),String.isNotBlank(opp.Owner.Email) ? opp.Owner.Email : '');  
                
                //replace for subject
                valuesReplace.put(genKeyToText('PolicyNumber'), String.isNotBlank(opp.Policy__r.Policy_Number__c)? opp.Policy__r.Policy_Number__c : '');   
                valuesReplace.put(genKeyToText('NamedInsured'),opp.Account.Name); //insured business Account Name
                valuesReplace.put(genKeyToText('ReplyToSubmissionEmail'), String.isNotBlank(broker.Broker_Contact__r.Email) ? broker.Broker_Contact__r.Email : ''); //broker contact email
                //valuesReplace.put(genKeyToText('QuoteNumber'), ); //
                //valuesReplace.put(genKeyToText('PolicyNumber'), String.isNotBlank(opp.Policy__r.Policy_Number__c)? opp.Policy__r.Policy_Number__c : '');
                valuesReplace.put(genKeyToText('PolicyEffectiveDate'),String.valueOf(convertDateUS(opp.Policy__r.Effective_Date__c)));
                valuesReplace.put(genKeyToText('NEW/REN'), opp.Type == 'Renewal'? 'REN' : 'NEW'); // New Or Renewal Submissionb
                //valuesReplace.out(genKeyToText('EndorsementEffectiveDate'),) //endorsementEffectiveDate for quote email
                //valuesReplace.out(genKeyToText('EndorsementSequenceNumber'),)
                valuesReplace.put(genKeyToText('ExpiringPolicyNumber'), String.isNotBlank(opp.Prior_Policy__r.Policy_Number__c) ? opp.Prior_Policy__r.Policy_Number__c : ''); 
                //valuesReplace.out(genKeyToText('SubmissionSubjectLine'),) 
                //set valuesReplace
                for(String key : valuesReplace.keySet()){
                    String valueData = '';
                    if(String.isNotBlank(valuesReplace.get(key))) valueData = valuesReplace.get(key);
                    if(htmlBody.contains(key)) htmlBody = htmlBody.replace(key, valueData);// ex: key = '{!Contact.FirstName}'
                    if(htmlSubject.contains(key)) htmlSubject = htmlSubject.replace(key, valueData);
                }
            }
            
        }
        if(!opp.Quotes.isEmpty()){
            Quote quote = opp.Quotes[0];
            System.debug('quote id:'+quote.Id);
            Map<String,String> valuesReplace = new Map<String,String>();
            Map<String,List<String>> subjvalues = new Map<String,List<String>>();
            valuesReplace.put(genKeyToHTML('QuoteName'),String.isNotBlank(quote.Name) ? quote.Name : '');
            valuesReplace.put(genKeyToHTML('QuoteLayer'),String.isNotBlank(quote.Layer__c) ? quote.Layer__c : '');
            valuesReplace.put(genKeyToHTML('QuoteRefNumber'),String.isNotBlank(quote.QuoteNumber) ? quote.QuoteNumber : '');
            //valuesReplace.put(genKeyToHTML('QuoteEffectiveDate'), String.ValueOf(quote.Effective_Date__c));
            valuesReplace.put(genKeyToHTML('QuoteEffectiveDate'),String.valueOf(convertDateUS(quote.Effective_Date__c)));
            
            List<Subjectivity__c> subjList = [SELECT Id, Subjectivity__c , Subjectivity_Text__c FROM Subjectivity__c 
                                              where Quote__c =:quote.Id and Cleared__c = false]; //added subjectivity text Mary
            List<String> subjNameList = new List<String>();
            for(Subjectivity__c subj : subjList){
                //subjNameList.add(subj.Subjectivity__c);
                subjNameList.add(subj.Subjectivity_Text__c); //Mary Added 
            }
            if(!subjNameList.isEmpty()){
               subjvalues.put(genKeyToHTML('UntickedSubjectivities'),subjNameList); 
            }
            else if(subjNameList.isEmpty()){
                List<String> emptySubMsg = new List<String>{'No uncleared subjectivities'};
                subjvalues.put(genKeyToHTML('UntickedSubjectivities'),emptySubMsg);
            }
            System.debug('##subjvalues::'+subjvalues);
            List <String> subjValueData = new List <String>();
            for(String key : subjvalues.keySet()){   
                if(!subjvalues.get(key).isEmpty()){
                    subjValueData.addAll(subjvalues.get(key));
                }
                system.debug('##subjValueData::'+subjValueData);
                String subjListData = '';
                String subjDataLineBreak = '';
                if(!subjValueData.isEmpty()){
                  subjListData = string.join(subjValueData,';;'); //55115
                  system.debug('##subjListData::'+subjListData);
                  //subjDataLineBreak = subjListData.replaceAll(',','<br>'+' &#10148; ');
                  subjDataLineBreak = subjListData.replaceAll(';;','<li>');   // 55115 mary
                  system.debug('##subjDataLineBreak::'+subjDataLineBreak);
                }                
                   if(htmlBody.contains(key)) 
                       if(subjDataLineBreak.contains('No uncleared subjectivities')){
                          htmlBody = htmlBody.replace(key,subjDataLineBreak);
                       }
                	else{
                        htmlBody = htmlBody.replace(key,  '<ol>'+'<li>'+ subjDataLineBreak + '</ol>');
                    }      
            }
            for(String key : valuesReplace.keySet()){
                    String valueData = '';
                    if(String.isNotBlank(valuesReplace.get(key))) valueData = valuesReplace.get(key);
                    if(htmlBody.contains(key)) htmlBody = htmlBody.replace(key, valueData);// ex: key = '{!Contact.FirstName}'
                    if(htmlSubject.contains(key)) htmlSubject = htmlSubject.replace(key, valueData);
            }
            
        }
        tempEmail.HtmlValue = htmlBody;
        tempEmail.Subject = htmlSubject;
        return tempEmail;
    }



    /*************************************************
    * Method Name: genKeyToHTML
    * Author: Prachi
    * Date: 21-May-2021
    * Params: string key
    * Return: String
    * Exceptions: 
    * Revision: 
    *************************************************/
    public static String genKeyToHTML(String key){
        //return '&lt;&lt;<span class=SpellE>' + key + '</span>&gt;&gt;';
        return '&lt;&lt;' + key + '&gt;&gt;';
    }

    /*************************************************
    * Method Name: genKeyToHTML
    * Author: Prachi
    * Date: 21-May-2020
    * Params: string key
    * Return: String
    * Exceptions: 
    * Revision: 
    *************************************************/
    public static String genKeyToText(String key){
        //return '&lt;&lt;<span class=SpellE>' + key + '</span>&gt;&gt;';
        return '<<' + key + '>>';
    }

    /*************************************************
    * Method Name: convertDateUS
    * Author: Prachi
    * Date: 12-Nov-2020
    * Params: Date
    * Return: Date format US
    *************************************************/
    public static String convertDateUS(Date dateUs){
        if(dateUs == null) return '';
        //Convert US date format 
        Date datee = dateUs;
        Datetime dt = Datetime.newInstance(datee.year(), datee.month(),datee.day());
        return dt.format('MMMM dd, YYYY');
    }

    /*************************************************
    * Method Name: convertDateTimeUS
    * Author: Prachi
    * Date: 12-Nov-2020
    * Params: Datetime
    * Return: Datetime format US
    *************************************************/
    public static String convertDateTimeUS(Datetime dateTimeUs){
        if(dateTimeUs == null) return '';
        //Convert US Datetime format 
        Datetime dt = dateTimeUs;
        Date da = Date.newInstance(dt.year(),dt.month(),dt.day());
        return convertDateUS(da);
    }

    /*************************************************
    * Method Name: sendEmailMsg
    * Author: Prachi 
    * Date: 22-Mar-2020
    * Params: string templateId, EmailTemplate emailTemp, List<String> emails
    * Return: sucesMsg
    * Exceptions: 
    * Revision: 
    *************************************************/
    @AuraEnabled
    public static sucesMsg sendEmailMsg(string templateId, EmailTemplate emailTemp, List<String> emails,
                                        String ccEmails, String bccEmails, List<String> attFiles, String recordId){
        system.debug('templateId='+templateId);
        try {
            Messaging.SingleEmailMessage[] mails = new Messaging.SingleEmailMessage[]{};
            String senderEmail = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserID() limit 1].Email;

            //Add list send emails
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(UserInfo.getUserId());
            mail.setSenderDisplayName(senderEmail);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setTemplateId(templateId);
            mail.setUseSignature(false);
            mail.setToAddresses(emails);
            mail.setSubject(emailTemp.Subject);
            mail.setHtmlBody(formatEmailTemplate(emailTemp.HtmlValue, recordId));//To make line spacing consistent
            mail.setWhatId(recordId); 
            mail.setSaveAsActivity(true);
			
            if(ccEmails==''){
                ccEmails = null;
            }
            //GiangPhan added CC & BCC Address email
            system.debug('ccEmails' + ccEmails);
            system.debug('bccEmails' + bccEmails);
            
            if(ccEmails != null){
                List<String> sendEmailsCC = ccEmails.split(';');
                mail.setCcAddresses(sendEmailsCC);
            }
           
            if(bccEmails != null){
                List<String> sendEmailsBCC = bccEmails.split(';');
                mail.setBccAddresses(sendEmailsBCC);
            }
            //End CC & BCC
            System.debug('attFiles===='+attFiles);
            if(!attFiles.isEmpty()){
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                for(String fileString : attFiles) {
                    AttachmentEmail attachmentFile = (AttachmentEmail)JSON.deserialize(fileString, AttachmentEmail.Class);
                    
                        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                        efa.setFileName(attachmentFile.FileName);
                        efa.setContentType(attachmentFile.FileType);
                        efa.Body = EncodingUtil.base64Decode(attachmentFile.Body);
                        attachments.add(efa);
                }
                mail.setFileAttachments(attachments);
                System.debug('attachments===='+attachments);
            }
            //End Add Email file Attachment
            
            mails.add(mail);
			// Send the email
			if(!mails.isEmpty()) {
				Messaging.sendEmail(mails);
            }
           updateActivityHistory(recordId);
        } catch(Exception e) {
            system.debug('*************--Exception @sendAnEmailMsg method ---*********');
            System.debug('****--Exception type caught: ' + e.getTypeName());    
            System.debug('****--Message: ' + e.getMessage());    
            System.debug('****--Cause: ' + e.getCause());    
            System.debug('****--Line number: ' + e.getLineNumber());    
            System.debug('****--Stack trace: ' + e.getStackTraceString());    
            
            return new sucesMsg(false, e.getMessage()+' - '+e.getCause()+' - '+e.getStackTraceString()+' - '+e.getLineNumber());
        }
        return new sucesMsg(true, 'Sucess!');      
    } 
     private static void updateActivityHistory(String recordId){
        //For Bug 49054 - Email Activity - Name field is not getting populated for email activity.
            if(recordId != null){ 
                List<Broker_Account__c> brokerAccounts = [SELECT Broker_Contact__c FROM Broker_Account__c 
                                      Where Opportunity__c IN (SELECT Submission__c  FROM Quote_Process__c WHERE Id = :recordId)];
                List<Task> tasks = [SELECT Id, WhoId, WhatId, Subject, OwnerId,LastModifiedById FROM Task where WhatId = :recordId AND WhoId = null];
                for(Task t:tasks){
                    t.WhoID = brokerAccounts[0].Broker_Contact__c;
                }
                if(!tasks.isEmpty()){
                	update tasks;
                }
        	}
    }
	
    private static String formatEmailTemplate(String emailBody, String recordId){
        System.debug('emailBody'+emailBody);
        try{
            if(String.isNotBlank(recordId) && String.isNotBlank(emailBody)){
                Quote_Process__c quoteProcess = [SELECT ID, Owner.Name, Owner.Title, Owner.Phone, Owner.Email FROM Quote_Process__c WHERE ID = :recordId];
                System.debug('quoteProcess ==> '+quoteProcess);
                
                emailBody = emailBody.replaceAll('p>','div>');
                Integer indexOfAQWebsite = emailBody.indexOf('www.aqueousuw.com');
                Integer indexOfGreeting = emailBody.indexOf('Kind regards');
                
                if(indexOfAQWebsite != -1 && indexOfGreeting != -1){ //Run only when AQ website and greetings is present
                    String htmlBeforeAQWebsite = emailBody.substring(0,indexOfAQWebsite);
                    htmlBeforeAQWebsite.replaceAll('<div>', '<div style="font-size: 11pt;">');
                    String htmlAfterAQWebsite = emailBody.substring(indexOfAQWebsite);
                    
                    String htmlBodyBeforeGreetings = htmlBeforeAQWebsite.substring(0,indexOfGreeting);
                    String htmlBodyAfterGreetings = htmlBeforeAQWebsite.substring(indexOfGreeting);
            
                    htmlBodyAfterGreetings = htmlBodyAfterGreetings.replace('<div><b>'+quoteProcess.Owner.Name, '<div style="color: rgb(7, 77, 133);font-size: 11pt;"><b>'+quoteProcess.Owner.Name);
                    htmlBodyAfterGreetings = htmlBodyAfterGreetings.replace('<div><b>'+quoteProcess.Owner.Title, '<div style="color: rgb(29, 176, 231);font-size: 11pt;"><b>'+quoteProcess.Owner.Title);
                    htmlBodyAfterGreetings = htmlBodyAfterGreetings.replace('<div>'+quoteProcess.Owner.Phone, '<div style="color: rgb(149, 193, 30);font-size: 11pt;">'+quoteProcess.Owner.Phone);
            
                    htmlBeforeAQWebsite = htmlBodyBeforeGreetings + htmlBodyAfterGreetings;
            
                    htmlAfterAQWebsite = htmlAfterAQWebsite.replaceAll('<div>','<div style="font-size: 9.25pt; ">');//font-family: Calibri;
                    emailBody = htmlBeforeAQWebsite + htmlAfterAQWebsite;
                }
                return emailBody;
            }
        }catch(Exception ex){
            System.debug('Error while formating email : ' + ex.getMessage());
        }
        return emailBody;
    }
    
    /*************************************************
    * Method Name: getQuoteDocumentBySubmissionId
    * Author: Prachi
    * Date: 15-Dec-2020
    * Params: String Opportunity Id
    * Return: List Quote Documents
    *************************************************/
    @AuraEnabled
    public static List<GenerateDocumentApiHandler.GenerateResult> getQuoteDocumentBySubmissionId(String oppId, String templateName, String selectedQuoteId){
        List<GenerateDocumentApiHandler.GenerateResult> result = new  List<GenerateDocumentApiHandler.GenerateResult>();
        //get Object Name QuoteProcess or Opportunity
        String subId = getSubmissionId(oppId);

        List<Email_Template_Setting__mdt> templatesData = [SELECT DeveloperName, Attach_Document_Type__c, Record_Type__c FROM Email_Template_Setting__mdt WHERE Label =: templateName];
        if(templatesData.isEmpty())
        	return result;
        List<String> documentTypes = new List<String>();
    
        Map<String,Object> documentMap = (Map<String,Object>) JSON.deserializeUntyped(templatesData[0].Attach_Document_Type__c);
        for(String key : documentMap.keySet()) {
            documentTypes = (List<String>) JSON.deserialize(JSON.serialize(documentMap.get(key)), List<String>.class);
        }
		System.debug('##documentTypes::'+documentTypes);
        List<Document_Revision__c> docs = new List<Document_Revision__c>();

        if(documentMap.keySet().contains('Policy')) {
            List<Opportunity> opps = [SELECT Policy__c FROM Opportunity WHERE Id =: subId];
            if(opps.isEmpty())
                return result;
            //query list Documents Revision
            docs = [SELECT Id, Name, Document_Azure_Id__c,Document_Type__c 
                        FROM Document_Revision__c 
                        WHERE Policy__c =: opps[0].Policy__c
                        AND Document_Type__c IN :documentTypes ORDER By CreatedDate DESC];
            System.debug('Docs Type: ' + documentTypes);
            System.debug('Docs: ' + docs);
        } else {
            //query list Documents Revision
            /*docs = [SELECT Id, Name, Document_Azure_Id__c,Document_Type__c 
                       FROM Document_Revision__c WHERE Submission__c =:subId 
                       AND Document_Type__c IN :documentTypes ORDER By CreatedDate DESC];*/
            docs = [SELECT Id, Name, Document_Azure_Id__c,Document_Type__c 
                       FROM Document_Revision__c WHERE Quote_Id__c =:selectedQuoteId 
                       AND Document_Type__c IN :documentTypes ORDER By CreatedDate DESC]; //Bug 47031 - Prachi
        }
        
        List<String> docTypeList = new List<String>();
        for(Document_Revision__c document : docs){
            //If the document has the same documents type, it gets the most recent.
            if(docTypeList.contains(document.Document_Type__c) == false){
                GenerateDocumentApiHandler.GenerateResult resultGenerate = new GenerateDocumentApiHandler.GenerateResult();
                resultGenerate = GenerateDocumentApiHandler.getDocumentEncode(document.Document_Azure_Id__c);
                resultGenerate.docName = (document.Document_Type__c == 'Worksheet') ? document.Name + '.docx' : document.Name + '.pdf';
                docTypeList.add(document.Document_Type__c);
                result.add(resultGenerate);
            }
        }
        //Working code for loading policy wording documents in template automatically
        Set<String> contentDocIds = new Set<String>();
        if(selectedQuoteId!=''){
            Quote quoteRec = [SELECT Id, Policy_Wording_ContentDoc_Id__c, IPID_ContentDoc_Id__c FROM Quote WHERE Id=:selectedQuoteId];
            //Quote q = [Select Id, IPID_ContentDoc_Id__c, Policy_Wording_ContentDoc_Id__c from Quote where Id=:quoteId];
            if(quoteRec.Policy_Wording_ContentDoc_Id__c!=null){
                contentDocIds.add(quoteRec.IPID_ContentDoc_Id__c);
                contentDocIds.add(quoteRec.Policy_Wording_ContentDoc_Id__c);
            }
            if(!contentDocIds.isEmpty()){
                for(ContentVersion cv : [select Id, ContentDocumentId, Title, VersionData 
                                         from ContentVersion where ContentDocumentId IN :contentDocIds]){
                                             GenerateDocumentApiHandler.GenerateResult resultGenerated = new GenerateDocumentApiHandler.GenerateResult();
                                             resultGenerated = GenerateDocumentApiHandler.getQuoteDocumentEncode(cv.ContentDocumentId);
                                             result.add(resultGenerated); 
        }
       
                                  
      }
      } 
		if(docs.isEmpty() && contentDocIds.isEmpty()){
            return result;
        }
        system.debug('##result::'+result);
        return result;
    }

    /*************************************************
    * Method Name: getOpportunityRecordType
    * Author: Prachi
    * Date: 15-Dec-2020
    * Params: String Opportunity Id
    * Return: RecordType Name of Opportunity
    *************************************************/
    @AuraEnabled
    public static String getOpportunityRecordType(String oppId) {
        //get Object Name QuoteProcess or Opportunity
        String subId = getSubmissionId(oppId);
        //Return RecordType Name of Opportunity
        String rtName;
        if(subId!=null){
            rtName = [SELECT Id, RecordType.Name FROM Opportunity WHERE Id =: subId][0].RecordType.Name;
        }
		return rtName;
   }

    /*************************************************
    * Method Name: getSubmissionId
    * Author: Prachi
    * Date: 15-Dec-2020
    * Params: String Opportunity Id or Quote Process Id
    * Return: Submission Id
    *************************************************/
    public static String getSubmissionId(String oppId){
        Id objectId = oppId;
        String objName = objectId.getsobjecttype().getDescribe().getName();
        Id subId = null;
        if(objName == 'Quote_Process__c') //Object Quote Process
            subId = [SELECT Id, Submission__c FROM Quote_Process__c WHERE Id =:oppId LIMIT 1].Submission__c;
        else //Object Opportunity
            subId = oppId;
        return subId;
    }
    @AuraEnabled
    public static String getTemplateName(String templateId){
		String tempName	= [SELECT Id,Name,Subject,HtmlValue FROM EmailTemplate WHERE ID =: templateId].Name;
        system.debug('tempName::'+tempName);
        return tempName;
    }
    
    @AuraEnabled
    public static sucesMsg getQuoteList(String oppId, String tempName){
        sucesMsg result = new sucesMsg(true, 'Success');
        sucesMsg resultError = new sucesMsg(false, 'Error');
        String subId = getSubmissionId(oppId);
        if(tempName == 'Quote Email Excess' || tempName == 'Quote Email Primary'){
            String layer = (tempName == 'Quote Email Excess') ? 'Excess' : 'Primary';
            List<Quote> quoteList = [SELECT Id, Name, QuoteNumber, Status FROM Quote 
                                     WHERE OpportunityId =:subId AND Status='Quoted' AND Layer__c =:layer
                                     ORDER BY CreatedDate ASC];
            System.debug('quoteList'+quoteList.size());
            if(!quoteList.isEmpty()){
                if(quoteList.size()==1){
                    result.quoteId = quoteList[0].Id;
                    result.quoteList = new List <Quote>();
                    system.debug('quoteId::'+result.quoteId);
                }
                else{
                    result.quoteId = '';
                    result.quoteList = quoteList;
                    system.debug('quoteList::'+result.quoteList);
                } 
                return result;
            }else{
                resultError.errMsg = 'No quotes found!';
                return resultError;
            } 
        }
        else if(tempName == 'Hold Cover Email' || tempName == 'Generic Email'){
            List<Quote> quoteList = [SELECT Id, Name, QuoteNumber, Status FROM Quote 
                                     WHERE OpportunityId =:subId ORDER BY CreatedDate ASC];
            System.debug('quoteList'+quoteList.size());
            if(!quoteList.isEmpty()){
                if(quoteList.size()==1){
                    result.quoteId = quoteList[0].Id;
                    result.quoteList = new List <Quote>();
                    system.debug('quoteId::'+result.quoteId);
                }
                else{
                    result.quoteId = '';
                    result.quoteList = quoteList;
                    system.debug('quoteList::'+result.quoteList);
                } 
                return result;
            }else{
                resultError.errMsg = 'No quotes found!';
                return resultError;
            } 
        }
        else {
            resultError.errMsg = 'No quote/template found!';
            return resultError;
        }
    }
    
    
    //Wrapper Success/Error
    public class sucesMsg {       
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public string errMsg;
        @AuraEnabled public string data;
        @AuraEnabled public string dataCClist;
        @AuraEnabled public List<Quote> quoteList {get; set;}
        @AuraEnabled public string quoteId {get; set;}
        public sucesMsg(boolean isSuccess, string errMsg){
            this.isSuccess = isSuccess;
            this.errMsg = errMsg;
            quoteList = new List <Quote>();
        }
        
    }

    //Wrapper Attachment Send Email
    public class AttachmentEmail {
        @AuraEnabled 
        public string FileName {get; set;}
        @AuraEnabled 
        public string Body {get; set;}
        @AuraEnabled 
        public string FileType {get; set;}
    }

}