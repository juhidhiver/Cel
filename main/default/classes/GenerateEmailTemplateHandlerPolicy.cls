public class GenerateEmailTemplateHandlerPolicy {
    public GenerateEmailTemplateHandlerPolicy() {
        
    }
    
     @AuraEnabled
    public static String getTemplateName(String templateId){
		String tempName	= [SELECT Id,Name,Subject,HtmlValue FROM EmailTemplate WHERE ID =: templateId].Name;
        system.debug('tempName::'+tempName);
        return tempName;
    }
    
    @AuraEnabled
    public static sucessMsg getEmailList(String policyId){
        //get Object Name QuoteProcess or Opportunity
        String subId = getSubmissionId(policyId);
        List<Broker_Account__c> brokers = [Select Broker_Name__c,
                                           Broker_Contact__r.Name, Broker_Contact__r.Email
                                           From Broker_Account__c
                                           Where Opportunity__c = :subId
                                           And IsPrimaryBroker__c = true limit 1];
        Opportunity oppRec = [SELECT Id, Owner.Email FROM Opportunity where Id=:subId];
        if (brokers.isEmpty()){
            return new sucessMsg(false, 'This Submission has no primary Broker!'); 
        } else {
            if(String.isNotBlank(brokers[0].Broker_Contact__r.Email)){
                sucessMsg mess = new sucessMsg(true, 'Success');
                mess.data = brokers[0].Broker_Contact__r.Email;
                if(oppRec!=null){
                    mess.dataCClist = oppRec.Owner.Email;
                }
                return mess;
            } else {
                return new sucessMsg(false, 'This primary Broker Contact has empty email address!');
            }
        }
        
    }
    
    @AuraEnabled
    public static List<EmailTemplate> getEmailTemplates(String policyId){
        List<EmailTemplate> emailTemp = new list<EmailTemplate>();
        //String subId = getSubmissionId(oppId);
        //Dynamic query
        List<String> fields = new List<String>();
        List<String> params = new List<String>();
        String condition = '';
        String objName = 'EmailTemplate';
        //String recordTypeOpp = getOpportunityRecordType(oppId);
        fields.add('Id');
        fields.add('Name');
        fields.add('Subject');
        
        String layer = '';
        Quote quoteRec = [SELECT Id, Layer__c,Quote_Type__c,Quote_Action__c,Name_Insured_Update_Effective_Date__c FROM Quote 
                          WHERE Policy__c =: policyId AND Status = 'Bound' ORDER BY CreatedDate DESC Limit 1];
         System.debug('quoteRec query-->'+quoteRec);
        layer = quoteRec.Layer__c;
        
        String genericTemp = '';
         if(layer=='Excess' || layer=='Primary'){
            genericTemp = 'DeveloperName = \'Generic_Email_Policy\' ';
            params.add(genericTemp);
        }
        
        String primaryBindTemp = '';
        if(layer=='Primary' && (quoteRec.Quote_Type__c=='New Business' || quoteRec.Quote_Type__c=='Renewal')){
            primaryBindTemp = 'DeveloperName = \'Bind_Email_Primary\' ';
            params.add(primaryBindTemp);
        }
        String excessBindTemp = '';
        if(layer=='Excess' && (quoteRec.Quote_Type__c=='New Business' || quoteRec.Quote_Type__c=='Renewal')){
            excessBindTemp = 'DeveloperName = \'Bind_Email_Excess\' ';
            params.add(excessBindTemp);
        }
        
        /********* New Lines Added By Navdeep **/
        if(layer=='Primary' || layer=='Excess'){
           if(quoteRec.Quote_Type__c =='Midterm Cancellation'){
               excessBindTemp = 'DeveloperName = \'Mid_Term_Cancellation_Template\' ';
               params.add(excessBindTemp);
           }
            else if(quoteRec.Quote_Type__c =='Flat Cancellation'){
                excessBindTemp = 'DeveloperName = \'Flat_Cancellation_Template\' ';
                params.add(excessBindTemp);
            }
            else if( quoteRec.Quote_Type__c =='Full Amendment' || quoteRec.Quote_Type__c =='Coverage Amendment' || quoteRec.Quote_Type__c =='Policy Duration Change'
                    || quoteRec.Quote_Action__c == 'InsuredAccountUpdate' || quoteRec.Name_Insured_Update_Effective_Date__c!=null){
                excessBindTemp = 'DeveloperName = \'Bind_Amendment_Template\' ';
                params.add(excessBindTemp);
            }        
         }
        condition = String.join(params, ' OR ');
        String sortCondition = ' ORDER BY Name ASC';
        String query = CommonUtil.buildQuery(fields, objName, condition) + sortCondition;
        System.debug('template query-->'+query);
        emailTemp = (List<EmailTemplate>) Database.query(query);
        System.debug('##emailTemp'+emailTemp);
        return emailTemp;
    }
    
    public static String getSubmissionId(String policyId){
        Id objectId = policyId;
        String objName = objectId.getsobjecttype().getDescribe().getName();
        Id subId = null;
        if(objName == 'Policy__c') //Object Ploicy
            subId = [SELECT Name, Id, Policy__c, Submission__c,Submission__r.StageName
                     FROM Transactions__c WHERE Policy__c =:policyId AND 
                     Submission__r.Transaction_Status__c = 'Active' LIMIT 1].Submission__c;
        //subId = [SELECT Id, Submission__c FROM Quote_Process__c WHERE Id =:oppId LIMIT 1].Submission__c;
        //else //Object Opportunity
        //    subId = policyId;
        return subId;
    }
     /****************** Created By Navdeep *********************/
    @AuraEnabled
    public static Quote getLatestQuote(String policyId){
        return [SELECT Id, Layer__c,Quote_Type__c,Quote_Action__c FROM Quote WHERE Policy__c =: policyId AND Status = 'Bound' ORDER BY CreatedDate DESC Limit 1];
    }
    @AuraEnabled
    public static List<GenerateDocumentApiHandler.GenerateResult> getAmendmentDocuments(String policyId, String templateName){
        List<GenerateDocumentApiHandler.GenerateResult> result = new  List<GenerateDocumentApiHandler.GenerateResult>();
        
        List<Quote> quoteList = [SELECT Id, Layer__c,Quote_Type__c,Quote_Action__c,Policy_Wording_ContentDoc_Id__c, IPID_ContentDoc_Id__c,
                                 Name_Insured_Update_Effective_Date__c
                                 FROM Quote WHERE Policy__c =: policyId AND Status = 'Bound' ORDER BY CreatedDate DESC Limit 1];

        List<Document_Revision__c>  docList = new List<Document_Revision__c>();
        if(!quoteList.isEmpty()){
            if(quoteList[0].Quote_Action__c=='InsuredAccountUpdate' && quoteList[0].Name_Insured_Update_Effective_Date__c!=null){
                docList =  [SELECT Id, Name, Document_Azure_Id__c,Document_Type__c FROM Document_Revision__c 
                            WHERE Policy__c =: policyId And Name like '%_Insured Account Update%'  ORDER By CreatedDate DESC];
            }else{
                docList =  [SELECT Id, Name, Document_Azure_Id__c,Document_Type__c FROM Document_Revision__c 
                            WHERE Policy__c =: policyId AND Quote_Type__c=:quoteList[0].Quote_Type__c ORDER By CreatedDate DESC];
            }
        }
        List<String> docTypeList = new List<String>();
        for(Document_Revision__c document : docList){
            //If the document has the same documents type, it gets the most recent.
            if(docTypeList.contains(document.Document_Type__c) == false && !document.Name.contains('Policy Wording')){
                GenerateDocumentApiHandler.GenerateResult resultGenerate = new GenerateDocumentApiHandler.GenerateResult();
                resultGenerate = GenerateDocumentApiHandler.getDocumentEncode(document.Document_Azure_Id__c);
                resultGenerate.docName = (document.Document_Type__c == 'Worksheet') ? document.Name + '.docx' : document.Name + '.pdf';
                docTypeList.add(document.Document_Type__c);
                result.add(resultGenerate);
            }
        }
        Set<String> contentDocIds = new Set<String>();
        //Quote q = [Select Id, IPID_ContentDoc_Id__c, Policy_Wording_ContentDoc_Id__c from Quote where Id=:quoteId];
        if(quoteList[0].Policy_Wording_ContentDoc_Id__c!=null && quoteList[0].Quote_Action__c!='InsuredAccountUpdate' ){
            //contentDocIds.add(quoteRec.IPID_ContentDoc_Id__c);
            contentDocIds.add(quoteList[0].Policy_Wording_ContentDoc_Id__c);
        }
        if(!contentDocIds.isEmpty()){
            for(ContentVersion cv : [select Id, ContentDocumentId, Title, VersionData 
                                     from ContentVersion where ContentDocumentId IN :contentDocIds]){
                                         GenerateDocumentApiHandler.GenerateResult resultGenerated = new GenerateDocumentApiHandler.GenerateResult();
                                         resultGenerated = GenerateDocumentApiHandler.getQuoteDocumentEncode(cv.ContentDocumentId);
                                         result.add(resultGenerated);                            
                                     }
        }
        if(docList.isEmpty() && contentDocIds.isEmpty()){
            return result;
        }
        system.debug('##result::'+result);
        return result;
        
    }
    
    
   
    @AuraEnabled
    public static String getPolicyRecordType(String policyId) {
        return [SELECT Id, RecordType.Name FROM Policy__c WHERE Id =: policyId][0].RecordType.Name;
    }
      
    
    
    @AuraEnabled 
    public static EmailTemplate getTemplateDetails(string templateId, String policyId){    
        List<EmailTemplate> emailTempLst = [SELECT Id,Name,Subject,HtmlValue  
                                            FROM EmailTemplate 
                                            WHERE ID =: templateId];
        if (emailTempLst.isEmpty()){
            return new EmailTemplate();
        }
        
        //get Object Name QuoteProcess or Opportunity and RecordType Submission
        String subId = getSubmissionId(policyId);
        if(subId!=''){
            Opportunity opp = [SELECT Id, (Select Id, OpportunityId, Layer__c From Quotes 
                                           WHERE OpportunityId = :subId ORDER BY CreatedDate ASC) 
                               FROM Opportunity where Id=:subId];
            Quote qRec = opp.Quotes[0];
            String layer = qRec.Layer__c;
            String recordTypeOpp = getPolicyRecordType(policyId);
            if(recordTypeOpp == Label.Aqueous_RT){ //RecordType AQ
                return fillInformationForEmailAQ(emailTempLst[0],subId, layer, policyId);
            }
        }
        return new EmailTemplate();         
    }
    
    public static EmailTemplate fillInformationForEmailAQ(EmailTemplate tempEmail, String oppId, String layer, String policyId){
        String htmlBody = tempEmail.HtmlValue;
        String htmlSubject = tempEmail.Subject;
        System.debug('htmlSubject-->'+htmlSubject);
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
                           (Select Id, Name, OpportunityId, Layer__c From Quotes WHERE OpportunityId =:oppId AND Layer__c =:layer  
                            ORDER BY CreatedDate ASC LIMIT 1)
                           FROM Opportunity
                           WHERE Id =:oppId limit 1];

        Policy__c objPolicy = [Select Id, Policy_Number__c from Policy__c where Id =: policyId];
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
                
                valuesReplace.put(genKeyToHTML('PolicyNumber'), String.isNotBlank(objPolicy.Policy_Number__c)? objPolicy.Policy_Number__c : '');
                valuesReplace.put(genKeyToHTML('PolicyEffectiveDate'),String.valueOf(convertDateUS(opp.Policy__r.Effective_Date__c)));
                valuesReplace.put(genKeyToHTML('PolicyExpirationDate'),String.valueOf(convertDateUS(opp.Policy__r.Expiration_Date__c)));
                
                valuesReplace.put(genKeyToHTML('AccountState'),String.isNotBlank(opp.Account.BillingState)? opp.Account.BillingState : '');
                
                valuesReplace.put(genKeyToHTML('Underwriter'),String.isNotBlank(opp.Owner.Name) ? opp.Owner.Name : '');
                valuesReplace.put(genKeyToHTML('UnderwriterTitle'),String.isNotBlank(opp.Owner.Title) ? opp.Owner.Title : '');
                String phone = ''; 
                if(String.isNotBlank(opp.Owner.Phone)){
                    phone =  opp.Owner.Phone;
                }
                if (String.isNotBlank(opp.Owner.MobilePhone)){
                    phone = phone + ' / ' + opp.Owner.MobilePhone;
                }
                valuesReplace.put(genKeyToHTML('UnderwriterPhone'),String.isNotBlank(opp.Owner.Phone) ? opp.Owner.Phone : '');  
                valuesReplace.put(genKeyToHTML('UnderwriterEmail'),String.isNotBlank(opp.Owner.Email) ? opp.Owner.Email : '');  
                
                //replace for subject
                System.debug('htmlSubject-->');
                valuesReplace.put(genKeyToText('PolicyNumber'), String.isNotBlank(objPolicy.Policy_Number__c)? objPolicy.Policy_Number__c : '');   
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
            
            Map<String,String> valuesReplace = new Map<String,String>();
            Map<String,List<String>> subjvalues = new Map<String,List<String>>();
            valuesReplace.put(genKeyToHTML('QuoteName'),String.isNotBlank(quote.Name) ? quote.Name : '');
            valuesReplace.put(genKeyToHTML('QuoteLayer'),String.isNotBlank(quote.Layer__c) ? quote.Layer__c : '');
            
            /* List<Subjectivity__c> subjList = [SELECT Id, Subjectivity__c FROM Subjectivity__c 
where Quote__c =:quote.Id and Cleared__c = false];
List<String> subjNameList = new List<String>();
for(Subjectivity__c subj : subjList){
subjNameList.add(subj.Subjectivity__c);
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
subjListData = string.join(subjValueData,',');
system.debug('##subjListData::'+subjListData);
//subjDataLineBreak = subjListData.replaceAll(',','<br>'+' &#10148; ');
subjDataLineBreak = subjListData.replaceAll(',','<li>');   
system.debug('##subjDataLineBreak::'+subjDataLineBreak);
}                
if(htmlBody.contains(key)) 
//htmlBody = htmlBody.replace(key,  '&#10148; ' + subjDataLineBreak);// ex: key = '{!Contact.FirstName}'
if(subjDataLineBreak.contains('No uncleared subjectivities')){
htmlBody = htmlBody.replace(key,subjDataLineBreak);
}
else{
htmlBody = htmlBody.replace(key,  '<ol>'+'<li>'+ subjDataLineBreak + '</ol>');
}
//if(htmlSubject.contains(key)) htmlSubject = htmlSubject.replace(key, valueData); 
}*/
            for(String key : valuesReplace.keySet()){
                String valueData = '';
                if(String.isNotBlank(valuesReplace.get(key))) valueData = valuesReplace.get(key);
                if(htmlBody.contains(key)) htmlBody = htmlBody.replace(key, valueData);// ex: key = '{!Contact.FirstName}'
                if(htmlSubject.contains(key)) htmlSubject = htmlSubject.replace(key, valueData);
            }
            
        }
        System.debug('htmlSubject-->'+htmlSubject);
        tempEmail.HtmlValue = htmlBody;
        tempEmail.Subject = htmlSubject;
        return tempEmail;
    }
    
    public static String genKeyToHTML(String key){
        //return '&lt;&lt;<span class=SpellE>' + key + '</span>&gt;&gt;';
        return '&lt;&lt;' + key + '&gt;&gt;';
    }
    
    public static String genKeyToText(String key){
        //return '&lt;&lt;<span class=SpellE>' + key + '</span>&gt;&gt;';
        return '<<' + key + '>>';
    }
    
    public static String convertDateUS(Date dateUs){
        if(dateUs == null) return '';
        //Convert US date format 
        Date datee = dateUs;
        Datetime dt = Datetime.newInstance(datee.year(), datee.month(),datee.day());
        return dt.format('MMMM dd, YYYY');
    }
    
    public static String convertDateTimeUS(Datetime dateTimeUs){
        if(dateTimeUs == null) return '';
        //Convert US Datetime format 
        Datetime dt = dateTimeUs;
        Date da = Date.newInstance(dt.year(),dt.month(),dt.day());
       return convertDateUS(da);
    }
    
    @AuraEnabled
    public static List<GenerateDocumentApiHandler.GenerateResult> getQuoteDocumentBySubmissionId(String policyId, String templateName){
        List<GenerateDocumentApiHandler.GenerateResult> result = new  List<GenerateDocumentApiHandler.GenerateResult>();
        //get Object Name QuoteProcess or Opportunity
        //String subId = getSubmissionId(policyId);
        
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
            
            if(policyId!=''){
                docs = [SELECT Id, Name, Document_Azure_Id__c,Document_Type__c 
                        FROM Document_Revision__c 
                        WHERE Policy__c =: policyId
                        AND Document_Type__c IN :documentTypes ORDER By CreatedDate DESC];
                System.debug('Docs Type: ' + documentTypes);
                System.debug('Docs: ' + docs);
            }         
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
        Quote quoteRec = [SELECT Id, Policy_Wording_ContentDoc_Id__c, IPID_ContentDoc_Id__c FROM Quote WHERE Policy__c =:policyId 
                          AND Status = 'Bound' ORDER BY CreatedDate DESC LIMIT 1];
        Set<String> contentDocIds = new Set<String>();
        //Quote q = [Select Id, IPID_ContentDoc_Id__c, Policy_Wording_ContentDoc_Id__c from Quote where Id=:quoteId];
        if(quoteRec.Policy_Wording_ContentDoc_Id__c!=null){
            //contentDocIds.add(quoteRec.IPID_ContentDoc_Id__c);
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
        if(docs.isEmpty() && contentDocIds.isEmpty()){
            return result;
        }
        system.debug('##result::'+result);
        return result;
    }
    
    @AuraEnabled
    public static sucessMsg sendEmailMsg(string templateId, EmailTemplate emailTemp, List<String> emails,
                                         String ccEmails, String bccEmails, List<String> attFiles, String recordId){
                                             system.debug('templateId='+templateId);
                                             try {
                                                 Messaging.SingleEmailMessage[] mails = new Messaging.SingleEmailMessage[]{};
                                                 //String senderEmail = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserID() limit 1].Email;	/*----Commented by Gaurish CD-95------*/
            
                                                     //----Changing Sender Email from Currently logged in user to Submission's Owner's Email --- CD-95 ----START
                                                     String senderEmail;
                                                 String senderId = UserInfo.getUserId();
                                                 List<Opportunity> opp = [SELECT Owner.Email,OwnerId FROM Opportunity WHERE Policy__c =: recordId LIMIT 1];
                                                 if(opp != null && opp.size() > 0){
                                                     senderEmail = opp[0].Owner.Email;
                                                     senderId = opp[0].OwnerId;
                                                 }
                                                 else{
                                                     senderEmail = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserID() limit 1].Email;
                                                 }//----Changing Sender Email from Currently logged in user to Submission's Owner's Email --- CD-95 ----END
                                                 
                                                 //Add list send emails
                                                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                                 mail.setTargetObjectId(senderId);
                                                 mail.setSenderDisplayName(senderEmail);
                                                 mail.setTreatTargetObjectAsRecipient(false);
                                                 mail.setTemplateId(templateId);
                                                 mail.setUseSignature(false);
                                                 mail.setToAddresses(emails);
                                                 mail.setSubject(emailTemp.Subject);
                                                 mail.setHtmlBody(formatEmailTemplate(emailTemp.HtmlValue, recordId));
                                                 mail.setWhatId(recordId); //added by Vien Pham 12/Nov/2020
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
                                                 
                                                 //29-Oct-2020 GiangPhan Add Email file Attachment
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
                                                 
                                                 return new sucessMsg(false, e.getMessage()+' - '+e.getCause()+' - '+e.getStackTraceString()+' - '+e.getLineNumber());
                                             }
                                             return new sucessMsg(true, 'Sucess!');      
                                         }
     private static void updateActivityHistory(String recordId){
        //For Bug 49054 - Email Activity - Name field is not getting populated for email activity.
            if(recordId != null){ 
                List<Broker_Account__c> brokerAccounts = [SELECT Broker_Contact__c FROM Broker_Account__c 
                                      Where Opportunity__c IN (SELECT Id  FROM Opportunity  WHERE Policy__c = :recordId)];
                if(!brokerAccounts.isEmpty()){
                    List<Task> tasks = [SELECT Id, WhoId, WhatId, Subject, OwnerId,LastModifiedById FROM Task where WhatId = :recordId AND WhoId = null];
                    for(Task t:tasks){
                        t.WhoID = brokerAccounts[0].Broker_Contact__c;
                    }
                    if(!tasks.isEmpty()){
                        update tasks;
                	}
                }
        	}
    }
    
    private static String formatEmailTemplate(String emailBody, String recordId){
        try{
            if(String.isNotBlank(recordId) && String.isNotBlank(emailBody)){
                Policy__c policy = [SELECT ID, Owner.Name, Owner.Title, Owner.Phone, Owner.Email FROM Policy__c WHERE ID = :recordId];
                System.debug('policy ==> '+policy);
                
                emailBody = emailBody.replaceAll('p>','div>');
                Integer indexOfAQWebsite = emailBody.indexOf('www.aqueousuw.com');
                Integer indexOfGreeting = emailBody.indexOf('Kind regards');
                
                if(indexOfAQWebsite != -1 && indexOfGreeting != -1){ //Run only when AQ website and greetings is present
                    String htmlBeforeAQWebsite = emailBody.substring(0,indexOfAQWebsite);
                    htmlBeforeAQWebsite.replaceAll('<div>', '<div style="font-size: 11pt;">');
                    String htmlAfterAQWebsite = emailBody.substring(indexOfAQWebsite);
                    
                    String htmlBodyBeforeGreetings = htmlBeforeAQWebsite.substring(0,indexOfGreeting);
                    String htmlBodyAfterGreetings = htmlBeforeAQWebsite.substring(indexOfGreeting);
            
                    htmlBodyAfterGreetings = htmlBodyAfterGreetings.replace('<div><b>'+policy.Owner.Name, '<div style="color: rgb(7, 77, 133);font-size: 11pt;"><b>'+policy.Owner.Name);
                    htmlBodyAfterGreetings = htmlBodyAfterGreetings.replace('<div><b>'+policy.Owner.Title, '<div style="color: rgb(29, 176, 231);font-size: 11pt;"><b>'+policy.Owner.Title);
                    htmlBodyAfterGreetings = htmlBodyAfterGreetings.replace('<div>'+policy.Owner.Phone, '<div style="color: rgb(149, 193, 30);font-size: 11pt;">'+policy.Owner.Phone);
            
                    htmlBeforeAQWebsite = htmlBodyBeforeGreetings + htmlBodyAfterGreetings;
            
                    htmlAfterAQWebsite = htmlAfterAQWebsite.replaceAll('<div>','<div style="font-size: 9.25pt;">');
                    emailBody = htmlBeforeAQWebsite + htmlAfterAQWebsite;
                }
                return emailBody;
            }
        }catch(Exception ex){
            System.debug('Error while formating email : ' + ex.getMessage());
        }
        return emailBody;
    }
    
    //Wrapper Success/Error
    public class sucessMsg {       
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public string errMsg;
        @AuraEnabled public string data;
        @AuraEnabled public string dataCClist;
        public sucessMsg(boolean isSuccess, string errMsg){
            this.isSuccess = isSuccess;
            this.errMsg = errMsg;
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