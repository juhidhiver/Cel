/**************************************************************************************************
* Class Name: REST_Invsk_Opportunities_v2
* Author: Sarthak Roy
* Created date: 02-Nov-2020
* Description: Sync from MW to SF
**************************************************************************************************/
@RestResource(urlMapping='/Invsk_Opportunities_v2/*')
global class REST_Invsk_Opportunities_v2 {
    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        ResponseObject responseObject = new ResponseObject();
        try {
            Boolean hasErrors = false;
            Integer contactCount = 0;
            Integer productCount = 0;
            String accountSalesforceId = '';
            String brokerSalesforceId = '';
            String channelSalesforceId = '';
            String contactSalesforceId = '';
            String opportunitySalesforceId = '';
            String productSalesforceId = '';
            String contactName = '';
            String productName = '';
            String productRecTypeName = '';
            
            String requestString = req.requestBody.toString();
            IncomingRequest request = (IncomingRequest)JSON.deserialize(requestString, IncomingRequest.class);                    
            
            //Check whether Opportunity Azure ID exists in the request
            if(String.isBlank(request.opportunityId)){
                responseObject.success = false;
                responseObject.errors.add('Opportunity AzureId cannot be Empty');
                RestContext.response.statusCode = 400;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObject));
                ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Opportunities_v2', 'REST_Invsk_Opportunities_v2.doPost');
                return ;
            }
            
            // --------------- Query data with broker key provided ---------------
            if (String.isNotBlank(request.brokerKey)){
                List<Contact> brokerContacts = [Select Id, Name, AccountId, Azure_ID__c From Contact
                                                Where Azure_Id__c = :request.brokerKey Limit 1];
                if (!brokerContacts.isEmpty()) {
                    brokerSalesforceId = brokerContacts[0].AccountId;
                    contactSalesforceId = brokerContacts[0].Id;
                    contactName = brokerContacts[0].Name;
                    
                } else {
                    hasErrors = true;
                    responseObject.errors.add('Could not find Broker Account for the provided Contact.');
                }
            }
            
            // --------------- Query data with channel key provided ---------------
            
            Account channelAcc = new Account();
            
            if (String.isNotBlank(request.channelKey)) {
                List<Account> channelAccounts = [Select Id, Name, Azure_ID__c From Account
                                                 Where Azure_Id__c = :request.channelKey Limit 1];           
                if (!channelAccounts.isEmpty()) {
                    channelSalesforceId = channelAccounts[0].Id;
                    channelAcc = channelAccounts[0];
                    productCount = [Select Count() From Account_Product__c Where Account_Id__c = :channelSalesforceId];
                } else {
                    hasErrors = true;
                    responseObject.errors.add('Unrecognized channel-key.');
                } 
            }                         
            
            if (productCount == 0) {
                hasErrors = true;
                responseObject.errors.add('Could not find product for specified id(s).');
            }
            
            // --------------- Query data with account Id provided ---------------
            if (String.isNotBlank(request.accountId)) {
                List<Account> accounts = [Select Id, Azure_Id__c From Account 
                                          Where Azure_Id__c = :request.accountId Limit 1];
                if (!accounts.isEmpty()) accountSalesforceId = accounts[0].Id;
                else {
                    hasErrors = true;
                    responseObject.errors.add('Could not find insured Account.');
                }
            }
            
            // --------------- Query data with product Id provided ---------------
            if (String.isBlank(request.productId)){
                responseObject.success = false;
                responseObject.errors.add('Product Id cannot be Empty');
                RestContext.response.statusCode = 400;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObject));
                ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Opportunities_v2', 'REST_Invsk_Opportunities_v2.doPost');
                return ;
            }else{
                List<Product2> products = [Select Id, Name, Azure_Id__c, RecordType.Name From Product2
                                           Where Azure_Id__c = :request.productId Limit 1];
                if (!products.isEmpty()) {
                    productSalesforceId = products[0].Id;
                    productName = products[0].Name;
                    productRecTypeName = products[0].RecordType.Name;
                    
                    // Get products related Channel Account
                    Set<String> productIdCompare = new Set<String>();
                    
                    for(Account_Product__c accPro : [Select Id,Product_Id__c From Account_Product__c 
                                                     Where Account_Id__c =: channelAcc.Id]){
                                                         if(String.isNotBlank(accPro.Product_Id__c)) productIdCompare.add(accPro.Product_Id__c);
                                                     }
                    if(!productIdCompare.isEmpty() && !productIdCompare.contains(productSalesforceId)) {
                        hasErrors = true;
                        responseObject.errors.add('Product coming in the request does not exist in Channel Account.');
                    }
                } else {
                    hasErrors = true;
                    responseObject.errors.add('Unrecognized product id.');
                }
            }
            
            if (hasErrors) {
                responseObject.success = false;
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObject));
                ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Opportunities_v2', 'REST_Invsk_Opportunities_v2.doPost');
                return;
            }
            
            Opportunity newOpportunity = new Opportunity();
            if (String.isBlank(opportunitySalesforceId)){
                // Create a new Opportunity
                newOpportunity.AccountId = accountSalesforceId;
                newOpportunity.Product__c = productSalesforceId;
                newOpportunity.Azure_ID__c = request.opportunityId;
                newOpportunity.Name = contactName + ' - ' + productName;
                newOpportunity.CloseDate = date.today().addYears(1);
                newOpportunity.LeadSource = 'Shopping X';
                newOpportunity.Source__c = 'SME';
                Id opptRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Celerity').getRecordTypeId();
                newOpportunity.RecordTypeId = opptRtId;
                newOpportunity.StageName = 'Qualified';
                newOpportunity.Type ='New Business';
                upsert newOpportunity;
                
                opportunitySalesforceId = newOpportunity.Id;
                responseObject.opportunityId = newOpportunity.Azure_ID__c;
                responseObject.success = true;
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObject));
            }
            
            // Check if the broker has been added
            contactCount = [Select Count() From Broker_Account__c 
                            Where Broker_Contact__c = :contactSalesforceId 
                            And Opportunity__c = :opportunitySalesforceId];
            
            if (contactCount == 0) {
                Broker_Account__c brokerContact = new Broker_Account__c();
                brokerContact.Opportunity__c = opportunitySalesforceId;
                brokerContact.Broker_Contact__c = contactSalesforceId;
                brokerContact.Relationship_Type__c = 'Broker';
                brokerContact.IsPrimaryBroker__c = true;
                insert brokerContact;
            }
            
            responseObject.success = true;
            responseObject.errors.clear();
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObject));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Opportunities_v2', 'REST_Invsk_Opportunities_v2.doPost');
            
        } catch (Exception ex) {
            responseObject.success = false;
            responseObject.errors.add(CommonUtil.getExceptionMessage(ex));
            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObject));
            ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_Opportunities_v2', 'REST_Invsk_Opportunities_v2.doPost');
        }
    }
    public class IncomingRequest {
        public String brokerKey;
        public String channelKey;
        public String accountId;
        public String productId;
        public String opportunityId;   
    }
    public class ResponseObject {
        public String opportunityId = '';
        public List<String> errors = new List<String>();
        public Boolean success = false;
    }
}