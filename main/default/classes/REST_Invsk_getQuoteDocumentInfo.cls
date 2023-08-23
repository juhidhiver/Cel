/*************************************************
* Class Name: REST_Invsk_getQuoteDocumentInfo 
* Author: 
* Date: 27/09/2019
* Requirement/Project Description: Get Quote Document Info API
*************************************************/
@RestResource(urlMapping='/Invsk_getQuoteDocumentInfo/*')
global class REST_Invsk_getQuoteDocumentInfo {

    @HttpGet
    global static void getDocumentInfoV2() {
        try{
            String param = RestContext.request.params.get('quoteId');
            String quoteAzureId = escapeParam(param);
            String functionName = 'getDocumentInfoV2';
            List<Quote> azureQuotes = [SELECT id FROM Quote WHERE Azure_ID__c = :quoteAzureId LIMIT 1];
            if (azureQuotes.isEmpty()) {
                setResponse(200, Label.QUOTE_IS_NOT_FOUND, functionName);
                return;
            } 
            String quoteId = azureQuotes[0].Id;

            List<Quote> oppQuotes = [SELECT OpportunityId FROM Quote WHERE Id = :quoteId LIMIT 1];
            if (oppQuotes.isEmpty()) {
                setResponse(200, Label.QUOTE_IS_NOT_FOUND, functionName);
                return;
            }
            String oppId = oppQuotes[0].OpportunityId;

            // ---------------- Opportunity ----------------
            List<Opportunity> opps = [SELECT Azure_ID__c, AccountId, Product__c, Amount, StageName,Industry__c,
                                                Effective_Date__c, Expiration_Date__c, Probability, MPL_Professional_Services__c,
                                                LeadSource, Product_Name__c, Renewed__c, Retroactive_Date_Docs__c, Retroactive_Date__c,
                                                Effective_Date_Docs__c, OwnerId, Owner.Name ,Pros__c,Cons__c,Prior_Policy__r.Policy_Number__c,Prior_Policy__r.Name
                                        FROM Opportunity WHERE Id = :oppId LIMIT 1];
            if (opps.isEmpty()) {
                setResponse(200, Label.OPPORTUNITY_IS_NOT_FOUND, functionName);
                return;
            }
            Opportunity oppty = opps[0];            
 
            // ---------------- Product ----------------
            List<Product2> products = [SELECT Name, UMR__c, Azure_ID__c, Writing_Company__c,  Carrier_Commission__c
                                        FROM Product2 WHERE Id = :oppty.Product__c LIMIT 1];
            if (products.isEmpty()) {
                setResponse(200, Label.PRODUCT_IS_NOT_FOUND, functionName);
                return;
            }
            Product2 prd = products[0];System.debug('@@@ Writing_Company__c: ' + prd);      
 
            // ---------------- Writing company ----------------
            Account writingCompany = null;
            List<Account> writingCompanies = [Select Name, Azure_ID__c, BillingStreet, BillingCity, BillingState,
                                                BillingStateCode, BillingPostalCode, BillingCountry, BillingCountryCode,
                                                Billing_County__c//Long Ly - 06/20/2019
                                                From Account Where Id = :prd.Writing_Company__c];System.debug('@@@ Writing_Company__c: ' + writingCompanies);
            if (!writingCompanies.isEmpty()) {
                writingCompany = writingCompanies[0];
            }

            // ---------------- Insured account ----------------
            List<Account> insuredAccs = [SELECT Name, Azure_ID__c, BillingStreet, BillingCity, 
                                                BillingState, BillingStateCode, BillingPostalCode, 
                                                BillingCountry, BillingCountryCode,Billing_County__c
                                        FROM Account WHERE Id = :oppty.AccountId];
            Account insuredAccount = insuredAccs.isEmpty() ? new Account() : insuredAccs[0];   
            
            // ---------------- Quote with Related Record ----------------
            // Phuc Ha added on 10 June 2020
            List<Quote> getQuote = [Select Id, QuoteNumber,Transaction_Premium__c, Endorsement_Quote_Bound_Date__c,
                                                Quote_Type__c, Name, Effective_Date__c,ExpirationDate,
                                                CloseDate__c, QuotePremium__c, Total_Premium__c, Tax, 
                                                Commission__c, Commission_percentage__c,
                                                Rating_Status__c, UW_Reason__c, Policy__c,
                                                Accept_Terror_Premium__c, Endorsement_Effective_Date__c,
                                                Azure_ID__c, TIV__c, Sequence_Number__c,Binder_Expiry_Date__c,
                                                Pending_or_Prior_Proceedings_Date__c,
                                                //Get Related Coverage Line Items
                                                (Select Id, Azure_ID__c, Name, Coverage__r.Name, Coverage__r.Coverage_Code__c,
                                                 Coverage__r.Coverage_Product__c,Coverage__r.RecordTypeName__c,
                                                 Coverage__r.Endorsement_Categories__c,Coverage__r.Product__c,
                                                 Coverage__r.Page_Section__c,Coverage__r.Coverage_Selection_Level__c,
                                                 Coverage__r.Azure_ID__c, Sub_Coverage__r.Name, Sub_Coverage__r.Coverage_Code__c, 
                                                 Sub_Coverage__r.Azure_ID__c, Limits_Deductibles__r.Name, 
                                                 Limits_Deductibles__r.Type__c, Limits_Deductibles__r.RecordTypeId, 
                                                 Limits_Deductibles__r.RecordType.Name,Limits_Deductibles__r.LmtDedCode__c,
                                                 Coverage_Premium__c,Coverage_Product__c,Quote__c,
                                                 Coverage_Type__c,Deductible_Frequency__c,Factor_Default_Value__c,
                                                 Factor_Max__c,Factor_Min__c,Factor_Value__c, Max_amt__c,Min_amt__c,
                                                 Options_Value_Percent__c,Option_Picklist__c,Option_Type__c,
                                                 Option_Value__c,Option_Value_Default__c,Override_Premium__c,
                                                 Page_Section__c,CoverageLineItemType__c,Coverage_Sort_Order__c,
                                                 Coverage__c,Endorsement_Categories__c,Group__c,
                                                //  Parent_Coverages_Line_Item__c,
                                                 Increment_Step__c,IsIncluded__c,Limits_Deductibles__c,Line_Item_Level__c,
                                                 Non_Prorated_Coverage_Premium__c,Rating__c,Sub_Coverage__c,
                                                 Notes__c,Form_Number__c
                                                 from Coverages_Line_Items__r 
                                                 ORDER BY Sub_Coverage__r.Name ASC, Limits_Deductibles__r.Name ASC),
                                                 (SELECT Id,Name,Due_Date__c,Quote__c,Stage__c,Subjectivity__c,Subjectivity_Status__c,
                                                 Subjectivity_Type__c
                                                 FROM Subjectivity__r) ,
                                    (SELECT Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                                     Factor_Value__c, Rating_Modifier__r.Rating_Modifier_Value__c,
                                     Rating_Modifier__r.Rating_Modifier_Code__c, Rating_Modifier__r.Format__c,
                                     Rating_Modifier__r.Name, Rating_Modifier__r.Product__c,Rating_Modifier__r.Factor_Max__c,
                                     Rating_Modifier__r.Factor_Min__c,Rating_Modifier__r.Factor_Value__c,
                                     Rating_Modifier__r.Azure_ID__c, Rating_Modifier__r.Page_Section__c
                                     FROM Rating_Modifier_Factors__r)
                                    From Quote Where Id = :quoteId];
            Quote quote = getQuote.isEmpty() ? new Quote() : getQuote[0];

            // ---------------- Additional interest ----------------
            List<Additional_Interests__c> adds = 
             [Select Id, Name, Azure_ID__c, Relationship_Type__c, Loan_Reference_number__c, Primary_Mortgage_Servicer__c,
                     Additional_Interest_Account__r.Name, Additional_Interest_Account__r.BillingStreet, 
                     Additional_Interest_Account__r.BillingCity, Additional_Interest_Account__r.BillingState, 
                     Additional_Interest_Account__r.BillingStateCode, Additional_Interest_Account__r.BillingPostalCode,
                     Additional_Interest_Account__r.BillingCountry, Additional_Interest_Account__r.BillingCountryCode,
                     Additional_Interest_Account__r.Azure_ID__c, Additional_Interest_Account__r.Billing_County__c                   
              From Additional_Interests__c Where Quote__c = :quoteId]; 
 
            // ---------------- Broker ----------------
            List<Broker_Account__c> brokers = 
            [Select Id, Broker_Contact__c, Broker_Contact__r.Name,Broker_Contact__r.Email,
                    Broker_Contact__r.Account.Name, Broker_Contact__r.Account.BillingStreet, 
                    Broker_Contact__r.Account.BillingCity, Broker_Contact__r.Account.BillingState, 
                    Broker_Contact__r.Account.BillingStateCode, Broker_Contact__r.Account.BillingPostalCode,
                    Broker_Contact__r.Account.BillingCountry, Broker_Contact__r.Account.BillingCountryCode,
                    Broker_Contact__r.Account.Azure_ID__c, Broker_Contact__r.Account.Billing_County__c
             From Broker_Account__c Where Opportunity__c = :oppId  And IsPrimaryBroker__c = true Limit 1]; 
            System.debug('@@@ Thao: ' + brokers);
            BrokerAccount brokerAcc = null;
            if (!brokers.isEmpty()) {
                brokerAcc = new BrokerAccount(brokers[0].Broker_Contact__r.Account, brokers[0].Broker_Contact__r.Name, brokers[0].Broker_Contact__r.Email);  
            } 
 
            // ------------------------------- Policy -----------------------------
            String policyId = quote.Policy__c;
            Policy__c policy = null;
          
            List<Policy__c> policys = [Select Policy_Number__c, Azure_ID__c, Cancellation_Date__c,
                                        Binding_License_Owner__c, Binding_License_Owner_Address__c,Binding_License_Owner_Name__c,
                                       Policy_Status__c, Name, Product_Name__c, Pending_or_Prior_Proceedings_Date__c
                                       From Policy__c Where Id = :policyId];
            if (!policys.isEmpty()) policy = policys[0];
            

            // ------------------------------Quote Endorsement Change Summary -----------------------------
                            
            List<QuoteEndorsementChangeSummary__c> quotesEndorsement = [Select Id,CoverageName__c,Deleted_Record_Summary__c,
                                                     FieldName__c,Name,New_Record_Summary__c, NewValue__c,ObjectName__c,
                                                     OldValue__c,Operation__c, SubCoverageName__c,RecordId__c,
                                                     Update_Record_Summary__c,Limit_Deductible__c
                                                     FROM QuoteEndorsementChangeSummary__c Where QuoteId__c = :quoteId];
            // ---------------- Quote location ----------------//
            List<Quote_Location__c> quoteLocations = [Select Name, Locations__c, Azure_ID__c, Primary_Location__c,
                            Locations__r.Address__c, Locations__r.City__c, Locations__r.State_Province__c,
                            Locations__r.State_Code__c, Locations__r.Postal_Code__c, Locations__r.Country__c,
                            Locations__r.Country_Code__c, Locations__r.Azure_ID__c,Locations__r.Protection_Class__c,
                            Locations__r.County__c
                            From Quote_Location__c Where Quote__c = :quoteId];
            // ---------------- Pros and Cons ----------------//
            List<Rating_Modifiers__c> ProsandConsRatingModifiers = [Select Id,Azure_ID__c,
                                                         Eligibility_Status__c,Eligibility_Weighting_Factor__c,
                                                         Format__c,Page_Section__c,
                                                         Picklist_Values__c,
                                                         Product__c,Rating_Modifier_Value__c,
                                                         Name,Sort_Order__c,
                                                         Sort_Sub_Section__c,Sub_Section__c
                                                         From Rating_Modifiers__c
                                                         Where Opportunity__c =: oppty.Id AND Page_Section__c ='Pros and Cons'
                                                         Order By Product__c ASC, Page_Section__c ASC, Sort_Order__c ASC,Sort_Sub_Section__c ASC]; 
            
            ResponseBody resBody = new ResponseBody();
            resBody.opportunity = oppty;
            resBody.product = prd;
            resBody.writingCompany = writingCompany;
            resBody.insuredAccount = insuredAccount;
            resBody.ProsandCons = ProsandConsRatingModifiers;
            //resBody.quoteLineItem = qli;
            resBody.additionalInterests = adds;
            resBody.broker = brokerAcc;
            resBody.policy = policys;
         //   resBody.ratingModifiers = ratingModifiers;
        //    resBody.ratingModifierFactors = ratingModifierFactors; 
            //resBody.coverLineItems = coverLineItems;
            resBody.quoteEndorsementChangeSummary = QuoteEndorsementChangeSummaryUtil.getMapQECSFilterSection(quotesEndorsement);// Phuc Ha add 10 June 20
            resBody.quote = quote;
            resBody.quoteLocations = quoteLocations;
            
            RestContext.response.statusCode = 200;
            String jsonResponse = JSON.serialize(resBody, false);
            //long ly - 29/05 - remove unsued field
            /*
            jsonResponse = jsonResponse.replaceAll('Deductible_Frequency__c','Limit_Value__c');
            System.debug('@@@ json: ' + jsonResponse);*/

            RestContext.response.responseBody = Blob.valueOf(jsonResponse);
            RestContext.response.addHeader('Content-Type', 'application/json');
            ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_getQuoteDocumentInfo', 'REST_Invsk_getQuoteDocumentInfo.getDocumentInfoV2');          
        
        } catch(Exception e) {
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('An error has occured: ' + CommonUtil.getExceptionMessage(e));
            ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_getQuoteDocumentInfo', 'REST_Invsk_getQuoteDocumentInfo.getDocumentInfoV2');
        }
    }


    private static void setResponse(Integer statusCode, String response, String functionName) {
        String apiName = 'REST_Invsk_getQuoteDocumentInfo';
        RestContext.response.statusCode = statusCode;
        RestContext.response.responseBody = Blob.valueOf(response);
        ApiUtil.logAPICallIn(RestContext.request, RestContext.response, apiName, functionName);
    }

    private class BrokerAccount {
        public String accountName;
        public String accountBillingStreet;
        public String accountBillingCity;
        public String accountBillingState;
        public String accountBillingPostalCode;
        public String billingCounty;
        public String brokerContactName;
        public String brokerContactEmail;
        public BrokerAccount(Account acc, String brokerContactName, String brokerContactEmail) {
            if (acc != null) {
                this.accountName = acc.Name;
                this.accountBillingStreet = acc.BillingStreet;
                this.accountBillingCity = acc.BillingCity;
                this.accountBillingState = acc.BillingState;
                this.accountBillingPostalCode = acc.BillingPostalCode;
                this.billingCounty = acc.Billing_County__c;
            }
            this.brokerContactName = brokerContactName;
            this.brokerContactEmail = brokerContactEmail;
        }
    }

    public class ResponseBody {
        public Opportunity opportunity                                          {get; set;}
        public Product2 product                                                 {get; set;}
        public Account writingCompany                                           {get; set;}
        public Account insuredAccount                                           {get; set;}
        public List<Quote_Location__c> quoteLocations                           {get; set;}
        public List<Additional_Interests__c> additionalInterests                {get; set;}
        public BrokerAccount broker                                             {get; set;}
        public List<Policy__c> policy                                           {get; set;}
        public List<Rating_Modifier_Factor__c> ratingModifierFactors            {get; set;}
        public List<Rating_Modifiers__c> ratingModifiers           {get; set;}
        public List<Rating_Modifiers__c> ProsandCons {get; set;}
        public Map<String,List<QuoteEndorsementChangeSummaryUtil.QuoteEndorsementChangeSummaryInfo>> quoteEndorsementChangeSummary {get; set;}
        public Quote quote                                                      {get; set;}
        
    }

    public static String escapeParam(String param) {
        return String.isNotBlank(param) ? String.escapeSingleQuotes(param) : '';
    }
}