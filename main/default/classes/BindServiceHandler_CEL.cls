/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 02-23-2022
 * @last modified by  : Maeran Shaikh
**/
public with sharing class BindServiceHandler_CEL {

    private static Boolean isIncomingBind = false;

    public static ResultResponse bindQuoteCelerity(String quoteId, String payPlan, Boolean isBoundPending, Boolean isIncomingBindCall) {
        isIncomingBind = isIncomingBindCall;
        return bindQuoteCelerity(quoteId, payPlan, isBoundPending);
    }

    @AuraEnabled
    public static ResultResponse bindQuoteCelerity(String quoteId, String payPlan, Boolean isBoundPending) {     
        ResultResponse result = new ResultResponse();
        List<API_Log__c> apiLogs = new List<API_Log__c>();

        Savepoint sp;
        try {
            List<Quote> quotes = QuoteQueryUtil.fetchQuoteById(quoteId);
           
            if (quotes.isEmpty()) {
                result.errors.add('No quote is found');
                return result;
            }
            string quoteAzureId = quotes[0].Azure_Id__c;
            string productName = quotes[0].Product_Name__c;            
           
            API_Configuration__mdt apiSettingBindQuote = CommonUtil.getAPIconfiguration('Bind_Quote_V2');
            
            if (apiSettingBindQuote == null){
                result.errors.add('API Configuration Bind Quote V2 is missing');
            }
            IncomingBindResponseCelerity bindResponse;

            if(!isIncomingBind){

                
                // SYnc MW before Bind 
                API_Log__c objApiLog = new API_Log__c();
                objApiLog = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', quotes[0], 'BindQuote'); // Added by Maeran for US:55030 as part of PreSync before Bind  
                if(objApiLog != null){
                    apiLogs.add(objApiLog);        
                }
                
                HttpRequest request = BindServiceHandler_Common.getHttpRequest(apiSettingBindQuote, quoteAzureId, 'Bind_Quote_V2');
                system.debug('request'+request);
                Http http = new Http();
                request.setHeader('Content-Length', '4096');
                request.setBody('{}');
                HttpResponse returnResponse = http.send(request);
                system.debug('returnResponse--'+returnResponse);
                string resp =  returnResponse.getBody();
                system.debug('resp'+resp);
                ApiUtil.logAPICall(request,returnResponse,'Celerity Bind Quote V2 Callout','Bind_Quote_V2', apiSettingBindQuote.HeaderParams__c, 'Outbound');
                if (returnResponse.getStatusCode() == 200) {
                    bindResponse = (IncomingBindResponseCelerity) JSON.deserialize(resp, IncomingBindResponseCelerity.class);
                    system.debug('bindResponse'+bindResponse);
                }
                else {
                    if(string.isNotBlank(resp)){
                        BindServiceHandler_Common.ResponseWrapper errorResponse = (BindServiceHandler_Common.ResponseWrapper) JSON.deserialize(resp, BindServiceHandler_Common.ResponseWrapper.class);
                        if(errorResponse.message.contains('PreConditionNotMet')){
                            result.errors.add(errorResponse.data);
                        }else{
                            result.errors.add('Bind Quote Callout Failed'); 
                        }
                        
                    }else{
                        result.errors.add('Bind Quote Callout Failed'); 
                    }
                    return result;
                }
            }
            // Check NIPR Logic 
            // NIPR fails  - STOP the Bind process and display an error message "Broker does not have license for Insured State".
            // Update the NIPR_Status__c field on the Quote to "Broker does not have license for Insured State"  Return to Quote view page
            // Invsk_Callout.NIPRResponse resNIPR;
            // Invsk_Callout.NIPRResponseAgency resNIPRAgency;
            String nIPRResult = 'Fail';
            String licenseNumber = '';
            Invsk_Callout.NIPRResponse resNIPR = new Invsk_Callout.NIPRResponse();
            Invsk_Callout.NIPRResponseAgency resNIPRAgency = new Invsk_Callout.NIPRResponseAgency();

            String qType = quotes[0].Quote_Type__c;
            if( qType == 'New Business' || qType == 'Renewal' || qType == 'Broker on Record Change' ){ //added by Jai to prevent Binder Lisence info overwrite in case of MTA Quote
                resNIPR = Invsk_Callout.getNIPRCallOut(quotes[0], apiLogs);
                // Callout NIPR Agency License
                resNIPRAgency = Invsk_Callout.getNIPRCallOutAgency(quotes[0], apiLogs); 
                
                sp = Database.setSavepoint();
                    
                // check for OFAC API Logic
                //Boolean isBoundPending = checkBoundPendingFromCallOutApi(quotes[0]);
                //isBoundPending = false; //Comment 23/June/2020 Commented for US-35795
                Boolean isNIPRResultBrokerIsStop = resNIPR.isStop; //Giang added 21/Jul/2020
                Boolean isNIPRResultAgencyIsStop = resNIPRAgency.isStop;
                    
                if(!resNIPR.isStop) 
                {
                    system.debug('@@@@@ Hello');
                    quotes[0].NIPR_Status__c = resNIPR.msgError;
                    //update quotes;
                    if(resNIPR.accountUpdate != null)
                        update resNIPR.accountUpdate;
                    if(resNIPR.brokerLicenseUpdate != null)
                        update resNIPR.brokerLicenseUpdate;
                }else if(String.isNotBlank(resNIPR.msgError)){//no broker & license                  
                    result.errors.add(resNIPR.msgError);
                } 
                    
                if(!resNIPRAgency.isStop)
                {
                    system.debug('@@@@@ Bonjour');
                    if(resNIPRAgency.agencyLicenseUpdate != null)
                        update resNIPRAgency.agencyLicenseUpdate;
                }else{
                    if(String.isNotBlank(resNIPRAgency.msgError)){//no license agency
                        result.errors.add(resNIPRAgency.msgError);
                    }
                }
                    
                /***
                * If either one passes (exists for the Insured State and passes NIPR we set the NIPR_Results__c field to Pass). 
                * If both Fail (do not exist or fails NIPR) set the NIPR_Results__c field to Fail. 
                * Added a new field on the Policy named Binding_License_Number__c. 
                * If only one of the two License pass populate this field with the License Number used in the passing NIPR check. 
                * If both pass populate Binding_License_Number__c with the Agency License used in the NIPR check.
                */
                if(isNIPRResultAgencyIsStop == false){
                    nIPRResult = 'Pass';
                    licenseNumber = resNIPRAgency.licenseNumber; //License Agency
                } else if (isNIPRResultBrokerIsStop == false){
                    nIPRResult = 'Pass';
                    licenseNumber = resNIPR.licenseNumber;
                } else {//Fail
                    if(String.isNotBlank(resNIPRAgency.msgError)){//no license agency
                        result.errors.add(resNIPRAgency.msgError);
                    }else if(String.isNotBlank(resNIPR.msgError)){//no broker & license                  
                        result.errors.add(resNIPR.msgError);
                    } 
                }
            }
            //End Check NIPR and continue Generate/Update Policy
            Policy__c policy = BindServiceHandler_Common.generatePolicyFromQuote(quotes[0], isBoundPending, nIPRResult, licenseNumber);
            if(!isIncomingBind){
                policy.Policy_Number__c = bindResponse.data.policyInformation.PolicyNumber;
                // if(quotes[0].Product_Name__c == 'Private Company Combo')
                //     policy.Policy_Number__c = bindResponse.data.policyInformation.PolicyNumber + bindResponse.data.policyInformation.PolicyId;
                policy.Azure_ID__c = bindResponse.data.policyInformation.PolicyId;
                update policy;                       
                
                //Document Generation
                string recordType = [SELECT Id, Name, SobjectType FROM RecordType where SobjectType = 'Document_Revision__c' And Name = 'Policy'].Id;
                DateTime dates = DateTime.now();
                //String datesStr = dates.format('dd-MM-yyyy');
                List<Document_Revision__c> docRevisionList = new List<Document_Revision__c>();
                for(Documents doc : bindResponse.data.policyInformation.Documents){
                    Document_Revision__c newDoc = new Document_Revision__c();
                    if(string.isNotBlank(doc.Id)){
                        if(string.isNotBlank(doc.Type)){
                            // Added by Maeran for US:51821
                            if(doc.Type == 'CelerityExcessQuote'){
                                doc.Type = 'QuoteProposal';
                            }
                            if(doc.Type == 'CelerityExcessPolicy'){
                                doc.Type = 'PolicyForm';
                            }
                            if(doc.Type == 'CelerityExcessBinder'){
                                doc.Type = 'Binder';
                            }
                            newDoc.Name = doc.Type +'_'+ dates;
                            newDoc.Document_Type__c = doc.Type;
                        } 
                        newDoc.Document_Azure_Id__c = doc.Id;
                        newDoc.Policy__c = policy.Id;
                        newDoc.RecordTypeId = recordType;
                        docRevisionList.add(newDoc);
                    }
                }
                if(!docRevisionList.isEmpty())
                    insert docRevisionList;
            }
            else{
                // policy.Policy_Number__c = bindResponse.data.policyInformation.PolicyNumber;
                // policy.Azure_ID__c = bindResponse.data.policyInformation.PolicyId;
            }  
                
            Opportunity opp = BindServiceHandler_Common.generateOpportunity(policy, quotes[0].OpportunityId);
            if(isBoundPending) opp.StageName = 'Bound Pending';
            upsert opp;
            system.debug('upsert opp='+opp);
            // update closingQuotes;
            BindServiceHandler_Common.updateQuoteListAfterBind(quotes[0]);
            
            result.data = policy.Id;
            result.extraData = quotes[0];
            result.isSuccess = true;
            
            if(!isIncomingBind){
                insert apiLogs;
            }
                
            
        }catch (Exception ex) {
            system.debug('exception : ' + ex.getMessage()+'  '+ex.getlinenumber());
            // rollback data 
            if(sp!=null) Database.rollback(sp);
            String errorMessage = CommonUtil.getExceptionMessage(ex);
            if(String.isBlank(errorMessage)) result.errors.add('Unable to bind this Policy. Please contact your Salesforce Administrator.');
            result.errors.add(errorMessage);
        }
        //System.debug('result===' + result);
        return result;
    }

    //method is being used for MPL/Cyber to bind with Binding License info
    @AuraEnabled
    public static ResultResponse bindQuoteWithBLInfo(String quoteId, String payPlan, Boolean isBoundPending, String blInfo ){
        ResultResponse result = new ResultResponse();
        result = BindService.bindQuote(quoteId, payPlan, isBoundPending);
        system.debug('result->'+result);
        if( result.isSuccess ){
           
            system.debug(blInfo);
            if(!String.isBlank(blInfo)){
                UpdateLicenseInfoOnPolicy.BindingLicenseInfo blObj = (UpdateLicenseInfoOnPolicy.BindingLicenseInfo)JSON.deserialize(blInfo, UpdateLicenseInfoOnPolicy.BindingLicenseInfo.class );
               // if( blObj.oppRecordType == GlobalVariables.RT_NAME_CELERITY && blObj.productName != GlobalVariables.PROD_NAME_FOR_PCC  ){
                    TriggerHandler.bypass('PolicyTriggerBaseHandler');       
                    Policy__c pol =  new Policy__c(
                        Id = (Id)result.data,
                         Binding_License_Number__c = blObj.bindingLicenseNumber,
                         Binding_License_Owner__c = blObj.bindingLicenseOwner,
                         Binding_License_Owner_Address__c = blObj.bindingLicenseOwnerAddress ,
                         Binding_License_Owner_Name__c = blObj.bindingLicenseOwnerName
                    );   
                   if(blObj.IsSignaturePackUploaded != Null){
                      pol.Is_Signature_Pack_Uploaded__c = blObj.IsSignaturePackUploaded;
                    }
                    if(pol != NULL) update pol;
                    TriggerHandler.clearBypass('PolicyTriggerBaseHandler');
                }
            
        }
       system.debug('New policy in BindServiceHandler__CEL==>>'+result.data);
        return result;
    }

    /*************************************************
    * Method Name: fetchMReAppointmentDetails
    * Author: Jai
    * Date: 23-NOv-2021
    * Params: quoteId Quote Id
    * Return:
    * Exceptions:
    * Revision:
    *************************************************/
    @AuraEnabled
    public static mReAppointWR fetchMReAppointmentDetails(String quoteId, String oppId, String insuredState) {
        String brokerConId = '';
        Boolean isAppointNeededForBroker = false;
        Boolean isAppointNeededForAgency = false;
        Boolean isAppointExistForBroker = false;
        Boolean isAppointExistForAgency = false;

        MRe_Appointment_Configuration__mdt MReAppointmentConfig = MRe_Appointment_Configuration__mdt.getInstance(insuredState);
        if(MReAppointmentConfig != null  && MReAppointmentConfig.Is_Active__c){
            if(MReAppointmentConfig.Appointment_Required_for_Individual__c){
                isAppointNeededForBroker = true;
            }
            if(MReAppointmentConfig.Appointment_Required_for_Agency__c){
                isAppointNeededForAgency = true;
            }
        }
        if(isAppointNeededForBroker || isAppointNeededForAgency){
            List<Opportunity> oppList = OpportunityQueryUtil.fetchOpportunityWithBrokerById(oppId);
            if(oppList.size()>0 && oppList[0].Opportunity_Accounts1__r.size()>0){
                brokerConId = oppList[0].Opportunity_Accounts1__r[0].Broker_Contact__c;
            
                if(String.isNotBlank(brokerConId) ){
                    Contact brokerContact = ContactQueryUtil.fetchContactWithBrokerLicenseById(brokerConId, insuredState);
                    if( isAppointNeededForBroker ){
                        if(brokerContact.Broker_Licenses__r.size()>0){
                            isAppointExistForBroker = true;
                        }
                    }
                    if(brokerContact.AccountId != null && isAppointNeededForAgency){
                        List<Agency_License__c> tempAgencyLicense = AgencyLicenseQueryUtil.fetchLicenseByAgencyId(brokerContact.AccountId, insuredState);
                        if(tempAgencyLicense.size()>0){
                            isAppointExistForAgency = true;
                        }                                        
                    }
                }
            }
        }
        return new mReAppointWR(isAppointExistForBroker, isAppointExistForAgency, isAppointNeededForBroker, isAppointNeededForAgency);
    }
    
    public class mReAppointWR{
        @AuraEnabled
        public Boolean isAppointExistForBroker;
        @AuraEnabled
        public Boolean isAppointExistForAgency;
        @AuraEnabled
        public Boolean isAppointNeededForBroker;
        @AuraEnabled
        public Boolean isAppointNeededForAgency;
        public mReAppointWR(Boolean isAppointExistForBroker, Boolean isAppointExistForAgency, Boolean isAppointNeededForBroker, Boolean isAppointNeededForAgency){
            this.isAppointExistForBroker = isAppointExistForBroker;
            this.isAppointExistForAgency = isAppointExistForAgency;
            this.isAppointNeededForBroker = isAppointNeededForBroker;
            this.isAppointNeededForAgency = isAppointNeededForAgency;
        }
    }
    
     public class IncomingBindResponseCelerity {
        public String status {get;set;}
        public String message {get;set;}
        public DataCelerity data {get;set;}
    }
    
    public class DataCelerity {
        public String quoteId {get;set;}
        public String status {get;set;}
        public policyInformationCelerity policyInformation {get;set;}
    }
    
    public class policyInformationCelerity {
        public String PolicyNumber {get;set;}
        public String PriorPolicyNumber {get;set;}	
        public String PolicyId {get;set;}
        public String BoundDateTime {get;set;}
        public String IssueDate {get;set;}
        public String BindingLicenseNumber {get;set;}
        public String BindingLicenseOwner {get;set;}
        public String BindingLicenseOwnerAddress {get;set;}
        public String BindingLicenseOwnerName {get;set;}
        public List<Documents> Documents {get;set;} 
        public PaymentDetails PaymentDetails {get;set;} 
        public String BillingType {get;set;}
        public WritingCompany WritingCompany {get;set;} 
        public Boolean IsSignaturePackUploaded {get;set;}
    }
    
    public class WritingCompany {
         public String Id {get;set;}
         public String Name {get;set;}
         public String Street {get;set;}
         public String City {get;set;}
         public String State {get;set;}
         public String PostalCode {get;set;}
    }
    
     public class PaymentDetails {
        public String TransactionID {get;set;}
        public String CardHolderName {get;set;}
        public String ProcessorResponseText {get;set;}
        public String Timestamp {get;set;}
        public String Amount {get;set;}
        public String PaymentInstrumentType {get;set;}
    }
    
    public class Documents {
        public String Id {get;set;}
        public String Type {get;set;}
        public String GeneratedDate {get;set;}
    }
}