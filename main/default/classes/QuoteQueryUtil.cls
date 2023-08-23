/**************************************************************************************************
 * Class Name: QuoteQueryUtil
 * Author: Jai
 * Date: Dec 02, 2021
 * Description: Class to keep Quote queries
 * Test Class : QuoteQueryUtilTest
 **************************************************************************************************/
public with sharing class QuoteQueryUtil {
    /*************************************************
    * Method Name: fetchOpenQuotesAQ
    * Author: Vinay
    * Date: 8th March 2022
    * Params: List<Policy__c>
    * Return: list<Quote>
    * Exceptions:
    * Revision: 
    * Description: Fetch quotes which are not in 'Bound','Closed','Rejected','Correction','Cancelled'
     *************************************************/
    public static List<Quote> fetchOpenQuotesAQ(Set<Id> opportunityIds){
        return [SELECT ID,Status,OpportunityId,Opportunity.Product_Name__c,Opportunity.AccountId From Quote where OpportunityId in: opportunityIds and Status not in ('Bound','Closed','Rejected','Correction','Cancelled') AND Product_Name__c =: GlobalVariables.PROD_NAME_FOR_PI];
    }

    
    /*************************************************
    * Method Name: fetchQuotes_CEL
    * Author: Jai
    * Date: 2 Dec 2021
    * Params: List<Policy__c>
    * Return: list<Quote>
    * Exceptions:
    * Revision: 
    * Description: Fetch Celerity Quotes for the Policies 
     *************************************************/
    public static List<Quote> fetchQuotes_CEL(List<Policy__c> newDataList){
       
        return	[	Select Id from Quote
                        WHERE 
                        (   Product_Name__c = :GlobalVariables.PROD_NAME_FOR_MPL OR 
                            Product_Name__c = :GlobalVariables.PROD_NAME_FOR_CYBER OR 
                            Product_Name__c = :GlobalVariables.PROD_NAME_FOR_PCC
                        ) 
                        AND 
                        (Policy__c IN : newDataList)
                    ];
    }

    /*************************************************
    * Method Name: fetchQuoteMapByOpportunity
    * Author: Vinay Vernekar
    * Date: 6th Dec 2021
    * Params: Set<id> opportunityIds, List<String> statuses
    * Return: Map of id and quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes with opportunity and status 
     *************************************************/
    public static Map<Id,Quote> fetchQuoteMapByOpportunity(Set<id> opportunityIds, List<String> statuses){
        return new Map<Id, Quote>([SELECT Id, Name,OpportunityId ,Broker__c, Broker_Email__c FROM Quote WHERE OpportunityId IN : opportunityIds AND Status IN :statuses]);
    }

     /*************************************************
    * Method Name: fetchQuotesByOpportunties
    * Author: Vinay Vernekar
    * Date: 7th Dec 2021
    * Params: Set<id> opportunityIds
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes
     *************************************************/
    public static List<Quote> fetchQuotesByOpportunties(Set<id> opportunityIds){
        return [SELECT Id, Status, OpportunityId ,AccountId, Name ,Broker__c,Product_Name__c, Broker_Email__c FROM Quote WHERE OpportunityId IN : opportunityIds];
    }

    
    /*************************************************
    * Method Name: fetchQuotesForQuoteIds
    * Author: Jai
    * Date: 9 Dec 2021
    * Params: Set<id>
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes with Id
     *************************************************/
    public static List<Quote> fetchQuotesForQuoteIds(Set<id> quoteIds, String fields){
        String query = 'Select '+fields+ ' From Quote where Id IN :quoteIds';
        return (list<Quote>)database.query(query);
    }

     /*************************************************
    * Method Name: fetchQuoteById
    * Author: 
    * Date: 30 Dec 2021
    * Params: Id
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch quote by Id
     *************************************************/
    public static List<Quote> fetchQuoteById(String quoteId){
        return [SELECT Id,Master_Binder__c,RetroDate__c,Retroactive_Date__c, Status, Azure_Id__c, Policy__c, AccountId,
            Account.Name, QuotePremium__c, Effective_Date__c, ExpirationDate,Endorsement_Reason__c,
            Total_Premium__c,Total_Cost_To_Client__c,Policy_Wording_Document__c, OpportunityId, Rating_Status__c, Product_Name__c, 
            Endorsement_Quote_Bound_Date__c,Quote_Type__c, Layer__c,Endorsement_Effective_Date__c,MGA_Commission__c,
            Opportunity.Policy__c, Opportunity.Product__r.Name,Opportunity.Type,Parent_Quote__c,Parent_Quote__r.Rate__c, 
            Opportunity.RecordType.Id, Opportunity.RecordType.Name, Shared_Aggregate_Limit__c, Combined_Max_Agg_Limit_of_Liability__c,
            Opportunity.Account.RecordType.Name, Opportunity.Account.Name, 
            Opportunity.Account.BillingStreet, Opportunity.Account.Billing_County__c,
            Opportunity.Account.BillingCity, Opportunity.Account.BillingState,
            Opportunity.Account.BillingPostalCode, Opportunity.Account.BillingCountryCode,
            Opportunity.Account.ShippingStreet, Opportunity.Account.Shipping_County__c, 
            Opportunity.Account.ShippingCity, Opportunity.Account.ShippingState,
            Opportunity.Account.ShippingPostalCode, Opportunity.Account.ShippingCountryCode,
            Opportunity.AccountId,Opportunity.Prior_Policy__c,Opportunity.Prior_Policy__r.Policy_Number__c,
            Opportunity.Prior_Policy__r.Pending_or_Prior_Proceedings_Date__c,
            Opportunity.Account.FEIN__c, Account.AQ_Sanction_Status__c, Account.KYC_Status__c,
            Opportunity.Account.BillingStateCode, Opportunity.Policy__r.Policy_Number__c, Opportunity.Product__r.Pay_Plan__c
            FROM Quote 
            WHERE Id = :quoteId];
    }

    /*************************************************
    * Method Name: fetchNonPIandPCCQuotes
    * Author: Jai
    * Date: 9 Dec 2021
    * Params: Set<id>
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch quotes which are non PI and PCC in selected collection
     *************************************************/
    public static List<Quote> fetchNonPIandPCCQuotes(Set<id> quoteToInprogressIds){
        return [    SELECT Id, Status, OpportunityId, Product_Name__c 
                    FROM Quote WHERE Product_Name__c NOT IN ('Professional Indemnity','Private Company Combo') AND Id IN :quoteToInprogressIds];
    }

    /*************************************************
    * Method Name: fetchPIQuotedQuotes
    * Author: Vinay
    * Date: 22 Dec 2021
    * Params: Set<id>
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch quotes with status as Quoted and Product Name as Professional Indemnity
     *************************************************/
    public static List<Quote> fetchPIQuotedQuotes(Set<id> opportunityIds){
        return [SELECT Id, Status, OpportunityId, Product_Name__c FROM Quote WHERE OpportunityId IN:opportunityIds and Status = 'Quoted' AND Product_Name__c =: GlobalVariables.PROD_NAME_FOR_PI];
    }

    /*************************************************
    * Method Name: fetchActiveQuotesOfOpportunities
    * Author: Vinay 
    * Date: 22 Dec 2021
    * Params: Set<id>
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all active quotes of opportunities
     *************************************************/
    public static List<Quote> fetchActiveQuotesOfOpportunities(Set<id> clearedSubmissionIDs){
        return [Select Id,Status,Quote_Type__c,Effective_Date__c,Endorsement_Effective_Date__c,
				OpportunityId,Product_Name__c,Layer__c,Coverage_Product_Options__c, AccountId
				from Quote where OpportunityId in: clearedSubmissionIDs 
				and Status in ('In Progress', 'Rated', 'Quoted', 'Referred')];
    }

    /*************************************************
    * Method Name: fetchCyberMPLQuotesByQuoteIDs
    * Author: Vinay 
    * Date: 24 Dec 2021
    * Params: Set<id>
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes related to MPL and Cyber but status not In Progress or Rated
     *************************************************/
    public static List<Quote> fetchCyberMPLQuotesByQuoteIDs(Set<id> quoteIds){
        return [select Id, Status, Name, Rating_Status__c,Endorsement_Quote_Bound_Date__c, Quote_Type__c, Parent_Quote__c, Product_Name__c, Opportunity.Id  from Quote where (Product_Name__c = 'MPL Standalone' OR Product_Name__c = 'Cyber Standalone') and (id in :quoteIds )  and (Status != 'In Progress' and Status != 'Rated')];
    }

    /*************************************************
    * Method Name: fetchQuotesForOppsAndStatus
    * Author:  
    * Date: 27 Dec 2021
    * Params: Set<String> oppIds, Set<String> quoteStatus
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes for opps and quote status
     *************************************************/
    public static List<Quote> fetchQuotesForOppsAndStatus(Set<Id> oppIds, Set<String> quoteStatus){
        return [Select Id,Status, Product_Name__c, OpportunityId From Quote Where OpportunityId IN :oppIds And Status IN: quoteStatus]; 
    }

    /*************************************************
    * Method Name: fetchQuotesForOppsAndStatus
    * Author:  
    * Date: 27 Dec 2021
    * Params: Set<String> oppIds
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes for opps which are not closed or rejected.
     *************************************************/
    public static List<Quote> fetchOpenQuotesForOpps(Set<Id> oppIds){
        return [Select Id,Status,Name,IPID_Document__c,Policy_Wording_Document__c,Master_Binder__c, Quote_Type__c,
                Policy_Wording__c,Layer__c,Opportunity.Main_Profession__c from Quote where OpportunityId IN :oppIds 
                AND (Status != 'Closed' AND Status != 'Rejected')];
    }

    /*************************************************
    * Method Name: fetchQuotesForOppsAndStatus
    * Author:  
    * Date: 27 Dec 2021
    * Params: Id oppId, List<String> closeQuoteStatus
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes for opps which are not closed
     *************************************************/
    public static List<Quote> fetchOpenQuotesForOpps(Id oppId, List<String> closeQuoteStatus){
        return [SELECT Id, Status,OpportunityId FROM Quote where OpportunityId =: oppID AND Status NOT IN: closeQuoteStatus];
    }
    
     /*************************************************
    * Method Name: fetchQuotesAndQuoteOprions
    * Author:  RINKU SAINI
    * Date: 3rd Jan 2022
    * Params: Id oppId, List<String> closeQuoteStatus
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes 
     *************************************************/
    public static List<Quote> fetchQuotesAndQuoteOprions( List<Id> listQuoteIdtoQuery ){
        return [Select Id, OpportunityId, layer__c,Status, ExpirationDate, Effective_Date__c, Quote_Type__c,
                (Select Id from Quote_Options__r)
                from Quote where Id in : listQuoteIdtoQuery ];
    }

     /*************************************************
    * Method Name: fetchQuotesByOpportunty
    * Author: 
    * Date: 7th Dec 2021
    * Params: Set<id> opportunityIds
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes
     *************************************************/
    public static List<Quote> fetchQuotesByOpportunty(String oppId){
        return [SELECT Id, Name, Status, Opportunity.Name, OpportunityId ,Broker__c,Product_Name__c, Broker_Email__c, Policy__c,  Layer__c, Quote_Type__c
               FROM Quote WHERE OpportunityId =: oppId];
    }

      /*************************************************
    * Method Name: fetchQuoteWithPolicy
    * Author: 
    * Date: 6th Jan 2022
    * Params: String quoteId
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch all quotes
     *************************************************/
    public static List<Quote> fetchQuoteWithPolicy(String quoteId){
        return [ Select Id, OpportunityId, AccountId, Endorsement_Quote_Bound_Date__c, 
                Total_Premium__c, Status, Effective_Date__c, ExpirationDate,
                Policy__c, Quote_Type__c, Endorsement_Effective_Date__c, Azure_ID__c
                From Quote Where Id = :quoteId And Policy__c != null];
    }

     /*************************************************
    * Method Name: fetchExistingQuotesByOpportunty
    * Author: 
    * Date: 6th Jan 2022
    * Params: String oppId, String currQuoteId
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: Fetch other quotes of opportunity
     *************************************************/
    public static List<Quote> fetchExistingQuotesByOpportunty(String oppId, String currQuoteId){
        return [Select Id,Status,Closed_Reason__c,Layer__c
                From Quote 
                Where OpportunityId = :oppId
                And Id !=:currQuoteId
                And Status != 'Bound' And Status != 'Bound Pending'
                And Status != 'Closed' And Status != 'Rejected'
                And Status != 'Correction' And Status != 'Cancelled'];
    }
    
     /*************************************************
    * Method Name: fetchExistingQuotesByOpportunty
    * Author: RINKU SAINI 
    * Date: 11th Jan 2022
    * Params: List Quote
    * Return: list of quote
    * Exceptions:
    * Revision: 
    * Description: 
     *************************************************/
    public static List<Quote> fetchQuoteInfo( List<Quote> quoteList ){
        return [SELECT Id,Master_Binder__c,RetroDate__c,Retroactive_Date__c, Status, Azure_Id__c, Policy__c, AccountId,
                Account.Name, QuotePremium__c, Effective_Date__c, ExpirationDate,Endorsement_Reason__c,
                Total_Premium__c,Total_Cost_To_Client__c,Policy_Wording_Document__c, OpportunityId, Rating_Status__c, Product_Name__c, 
                Endorsement_Quote_Bound_Date__c,Quote_Type__c, Layer__c,Endorsement_Effective_Date__c,
                Opportunity.Policy__c, Opportunity.Product__r.Name,Opportunity.Type, Opportunity.LeadSource,
                Opportunity.RecordType.Id, Opportunity.RecordType.Name,LastModifiedBy.Name,
                Opportunity.Account.RecordType.Name, Opportunity.Account.Name, 
                Opportunity.Account.BillingStreet, Opportunity.Account.Billing_County__c,
                Opportunity.Account.BillingCity, Opportunity.Account.BillingState,
                Opportunity.Account.BillingPostalCode, Opportunity.Account.BillingCountryCode,
                Opportunity.Account.ShippingStreet, Opportunity.Account.Shipping_County__c, 
                Opportunity.Account.ShippingCity, Opportunity.Account.ShippingState,
                Opportunity.Account.ShippingPostalCode, Opportunity.Account.ShippingCountryCode,
                Opportunity.AccountId,Opportunity.Prior_Policy__c,Opportunity.Prior_Policy__r.Policy_Number__c,
                Opportunity.Prior_Policy__r.Pending_or_Prior_Proceedings_Date__c,
                Opportunity.Account.FEIN__c, Account.AQ_Sanction_Status__c, Account.KYC_Status__c,
                Opportunity.Account.BillingStateCode, Opportunity.Policy__r.Policy_Number__c, Opportunity.Product__r.Pay_Plan__c
                FROM Quote
                WHERE Id =: quoteList];
    }

}