/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 01-07-2022
 * @last modified by  : Vinayesh
**/
public with sharing class BindServiceHandler_AQ {

    private static Boolean isIncomingBind = false;

    public static ResultResponse bindQuoteAqueous(String quoteId, String payPlan, Boolean isBoundPending, String binder, Boolean isIncomingBindCall) {
        isIncomingBind = isIncomingBindCall;
        return bindQuoteAqueous(quoteId, payPlan, isBoundPending, binder);
    }

    @AuraEnabled
    public static ResultResponse bindQuoteAqueous(String quoteId, String payPlan, Boolean isBoundPending, String binder){
        ResultResponse result = new ResultResponse();   

        List<Quote> quoteList =  QuoteQueryUtil.fetchQuoteById(quoteId);

        string quoteAzureId = quoteList[0].Azure_Id__c;
        API_Configuration__mdt apiSettingBindQuote = CommonUtil.getAPIconfiguration('Bind_Quote_V2');
        
        system.debug('apiSettingBindQuote'+apiSettingBindQuote);                               
        if (apiSettingBindQuote == null){
            result.errors.add('API Configuration Bind Quote V2 is missing');
        }
        try{
          
            HttpRequest request = BindServiceHandler_Common.getHttpRequest(apiSettingBindQuote, quoteAzureId, 'Bind_Quote_V2');
            system.debug('request'+request);
            Http http = new Http();
            request.setHeader('Content-Length', '4096');
            request.setBody('{}');
            HttpResponse returnResponse = http.send(request);
            system.debug('returnResponse--'+returnResponse);
            string resp =  returnResponse.getBody();
            system.debug('resp'+resp);
            ApiUtil.logAPICall(request,returnResponse,'Bind Quote V2 Callout','Bind_Quote_V2', apiSettingBindQuote.HeaderParams__c, 'Outbound');
            if (returnResponse.getStatusCode() == 200) {
               IncomingBindResponseAQ bindResponse = (IncomingBindResponseAQ) JSON.deserialize(resp, IncomingBindResponseAQ.class);
                Boolean createTransaction = false;
                if(quoteList[0].Policy__c == null){
                    createTransaction = true;
                }
                    
                Policy__c policy = BindServiceHandler_Common.generatePolicyFromQuote(quoteList[0], isBoundPending, '', '');
                policy.Policy_Number__c = bindResponse.data.policyInformation.PolicyNumber;
                policy.Azure_ID__c = bindResponse.data.policyInformation.PolicyId;
                if(quoteList[0].ExpirationDate != policy.Expiration_Date__c){
                    policy.Expiration_Date__c = quoteList[0].ExpirationDate;
                }
                update policy;
                system.debug('after gen policy='+policy);

                BindServiceHandler_Common.updateQuoteListAfterBind(quoteList[0]);
                Opportunity opp = BindServiceHandler_Common.generateOpportunity(policy, quoteList[0].OpportunityId);
                if(quoteList[0].Quote_Type__c == 'Policy Duration Change'){
                    opp.Expiration_Date__c = quoteList[0].ExpirationDate;
                }
                system.debug('opp-->'+opp);
                upsert opp;
                /*Id parentOppId = [Select Id, Parent_Opportunity__c from Opportunity where Id=:opp.Id].Parent_Opportunity__c;
                System.debug('parentOppId:'+parentOppId);
                if(opp!=null && parentOppId!=null){
                    System.debug('enter inactive loop');
                    Opportunity parentOppToUpdate = [Select Id,Transaction_Status__c from Opportunity where Id=:parentOppId];
                	parentOppToUpdate.Transaction_Status__c = 'Inactive';
                    System.debug('parentOpp.Transaction_Status__c before update::'+parentOppToUpdate.Transaction_Status__c);
                	update parentOppToUpdate;  
                    System.debug('parentOpp.Transaction_Status__c after update::'+parentOppToUpdate.Transaction_Status__c);
                }*/
                
                Set<Id> policyIds = new Set<Id>();
                for(Quote objQuote : QuoteQueryUtil.fetchQuotesByOpportunty(opp.Id)){
                    policyIds.add(objQuote.Policy__c);
                }
                List<Transactions__c> transList = [SELECT Id, Policy__c, Submission__c, Submission__r.Transaction_Status__c FROM Transactions__c 
                                                  WHERE Policy__c in :policyIds AND Submission__c!=:opp.Id];
                //Opportunity opp = [Select Id, StageName, Transaction_Status__c from Opportunity where Id=:opp.Id];
                Opportunity oppo = OpportunityQueryUtil.fetchOpportunityById(opp.Id)[0];
                Set <Id> oppIds = new Set <Id>();
                if(!transList.isEmpty()){
                     for(Transactions__c trans : transList){
                    //trans.Submission__r.Transaction_Status__c = 'Inactive';
                    oppIds.add(trans.Submission__c);
                	}
                    System.debug('oppIds:'+oppIds);
                    List<Opportunity> oppList = OpportunityQueryUtil.fetchOpportunityByIds(oppIds);
                    for(Opportunity oppRec: oppList){
                        if(oppo.Transaction_Status__c == 'Active' && oppo.StageName == 'Closed Won')
                        	{
                            	oppRec.Transaction_Status__c = 'Inactive';
                        	}
                        }
                    update oppList;
                    System.debug('oppList:'+oppList[0].Transaction_Status__c);
                }
                system.debug('Condition check!');
                
                if(oppo.Type == 'Renewal' && oppo.Parent_Opportunity__c !=null && oppo!=null){
                    	system.debug('Condition OK!');
                        Id parentOppId = OpportunityQueryUtil.fetchOpportunityById(oppo.Id)[0].Parent_Opportunity__c;
                    	System.debug('parentOppId:'+parentOppId);
                        Opportunity parentOppToUpdate = OpportunityQueryUtil.fetchOpportunityById(parentOppId)[0];
                    	if(oppo.Transaction_Status__c == 'Active' && oppo.StageName == 'Closed Won'){
                        	parentOppToUpdate.Transaction_Status__c = 'Inactive';
                   		}
                		update parentOppToUpdate; 
                        System.debug('parentOpp.Transaction_Status__c after update::'+parentOppToUpdate.Transaction_Status__c);
                }

                
                if((quoteList[0].Quote_Type__c == 'New Business'||quoteList[0].Quote_Type__c == 'Renewal') && createTransaction){
                    Transactions__c trans = new Transactions__c();
                    trans.Policy__c = policy.Id;
                    trans.Submission__c = opp.Id;
                    insert trans;
                }
                
                string recordType = [SELECT Id, Name, SobjectType FROM RecordType where SobjectType = 'Document_Revision__c' And Name = 'Policy'].Id;
                DateTime dates = DateTime.now();
                String datesStr = dates.format('dd-MM-yyyy');
                List<Document_Revision__c> docRevision = new List<Document_Revision__c>();
                List<Document_Revision__c> docRevisionList = new List<Document_Revision__c>();
                for(Documents doc : bindResponse.data.policyInformation.Documents){
                     Document_Revision__c newDoc = new Document_Revision__c();
                        if(string.isNotBlank(doc.Id)){
                            if(string.isNotBlank(doc.Type)){
                                
                                newDoc.Name = doc.Type +' '+ datesStr;
                                //newDoc.Name = doc.Type +' '+ doc.GeneratedDate; 
                                newDoc.Document_Type__c = doc.Type;
                            } 
                            if(string.isNotBlank(doc.Id)) newDoc.Document_Azure_Id__c = doc.Id;
                            newDoc.Policy__c = policy.Id;
                            newDoc.RecordTypeId  = recordType;
                            newDoc.Quote_Id__c = quoteId;
                            newDoc.Submission__c = opp.Id;
                            if(String.isNotBlank(binder)){
                                newDoc.Binder__c = binder;
                            }
                            docRevision.add(newDoc);
                        }
                }
                if(!docRevision.isEmpty())
                    insert docRevision;
                
                //Policy Wording
                DateTime dt = DateTime.now();
                String dateStr = dt.format('dd-MM-yyyy');
            
                Document_Revision__c newDocRevi = new Document_Revision__c();
                newDocRevi.Name = 'Policy Wording '+ dateStr;
                newDocRevi.Policy_Wording_Link__c = string.isNotBlank(quoteList[0].Policy_Wording_Document__c) ? quoteList[0].Policy_Wording_Document__c : '';
                newDocRevi.Policy__c = policy.Id;
                newDocRevi.Quote_Id__c = quoteId;
                newDocRevi.Submission__c = opp.Id;
                newDocRevi.Document_Azure_Id__c = 'Policy Wording';
                if(String.isNotBlank(binder)){
                    newDocRevi.Binder__c = binder;
                }
                newDocRevi.RecordTypeId = [SELECT Id, Name, SobjectType FROM RecordType where SobjectType = 'Document_Revision__c' And Name = 'Policy'].Id;
                docRevisionList.add(newDocRevi);
                
                if(!docRevisionList.isEmpty() && string.isNotBlank(quoteList[0].Policy_Wording_Document__c)){
                     insert docRevisionList;
                }
                   
                //Update Referral Reasons
                List<Referral_Reason__c> referralReasonQuo = ReferralReasonQueryUtil.fetchRefReasonsByQuoteId(quoteId); 
                if(referralReasonQuo.size() > 0){
                    for(Referral_Reason__c referrals : referralReasonQuo){
						if(String.isBlank(referrals.Approval_Status__c))
                        	referrals.Approval_Status__c = 'Not used';
                    }
                    update referralReasonQuo;
                }
				
                result.data = policy.Id;
                result.extraData = quoteList[0];
                result.isSuccess = true;
            } else { 
                BindServiceHandler_Common.ResponseWrapper errorResponse = (BindServiceHandler_Common.ResponseWrapper) JSON.deserialize(resp, BindServiceHandler_Common.ResponseWrapper.class);
                if(errorResponse.message.contains('PreConditionNotMet')){
                     result.errors.add(errorResponse.data);
                }else{
                    result.errors.add('Bind Quote Callout Failed'); 
                }
               
            }
            
            //ApiUtil.logAPICall(request,returnResponse,'Bind Quote V2 Callout','Bind_Quote_V2', apiSettingBindQuote.HeaderParams__c, 'Outbound');
        }catch (NullPointerException ex){            
            System.debug('NullException-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add(CommonUtil.getExceptionMessage(ex));
        }
        catch(Exception ex){
            System.debug('Exception-->'+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getMessage());
            result.errors.add(CommonUtil.getExceptionMessage(ex));
        }
        
        return result;
    }

    public class IncomingBindResponseAQ {
        public String status {get;set;}
        public String message {get;set;}
        public Data data {get;set;}
    }
    
    public class Data {
        public String quoteId {get;set;}
        public String status {get;set;}
        public policyInformation policyInformation {get;set;}
    }
    
    public class policyInformation {
        public String PolicyNumber {get;set;}
        //public String status {get;set;}
        public String Id {get;set;}
        public String WritingCompany {get;set;}
        public String PolicyId {get;set;}
        public String BoundDateTime {get;set;}
        public List<Documents> Documents {get;set;} 
    }
    
    public class WritingCompany {
         public String Id {get;set;}
         public String Name {get;set;}
         public String Street {get;set;}
         public String City {get;set;}
         public String State {get;set;}
         public String PostalCode {get;set;}
    }
    
    public class Documents {
        public String Id {get;set;}
        public String Type {get;set;}
        public String GeneratedDate {get;set;}
    }
}