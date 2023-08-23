public class CloneQueryUtil {

    /****************************************************** Aqueous ***************************************************************/

    public static List<Opportunity> queryOpportunityAQ(String oppId) {
        List<Opportunity> oppList = [SELECT Id,Account.Name,Account.BillingAddress,Account.KYC_Date__c, AccountId, RecordType.Name, 
                                     Name, StageName, Amount, CloseDate, Type, Pricebook2Id, ContactId, ContractId, Attachment_Point__c, 
                                     Eligibility_Approver__c, Eligibility_Approval_Date_Time__c, Loss_Reason__c, Innovisk_Entity_ID__c, 
                                     Product__c, QP_link__c, Create_From_Quote_Process__c, Account_Clearance__c,Total_Revenues__c,
                                     Current_Liabilities__c, Renewed__c, Policy_Link__c, Expiration_Date__c, MPL_Professional_Services__c, 
                                     Effective_Date__c, Service_Classification__c, Industry__c, Prior_Policy__c, Retroactive_Date__c, 
                                     UW_Link__c, Retroactive_Date_Docs__c, Eplace_Score__c, Service_to_Run__c,Current_Assets__c,Total_Liabilities__c,
                                     Parent_Opportunity__c, Agency__c, Received_Date__c, Source__c, Effective_Date_Docs__c, UW_Status__c,
                                     Coverage_Product_Options__c, Policy__c, Product_Name__c, AnnualRevenue__c, Main_Profession__c, 
                                     Largest_Work_Type__c, Professional_Business_Description__c, Tax_Country__c,Net_Income__c,Total_Assets__c,
                                     Retained_Earnings__c,Long_Term_Debt__c, Competing_Insurer__c, Submission_Status__c, Transaction_Status__c, 
                                     (select Id,Rating_Modifier_Code__c,Rating_Modifier_Value__c,Name from Rating_Modifiers__r)
                                     FROM Opportunity 
                                     WHERE Id =: oppId 
                                     AND Transaction_Status__c = 'Active' 
                                     ORDER BY CreatedDate DESC LIMIT 1]; 
        
        return oppList;
    }

    public static List<Quote> queryQuoteAQ(Set<Id> policyIds){
        List<Quote> quoteListFromPolicy = [Select Id,Commission_percentage__c, Effective_Date__c, QuoteNumber, ExpirationDate,
                                           AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                                           Quote_Type__c, Name, Status, Rating_Status__c,Tax,Commission__c, Override_Premium__c, 
                                           Override_Premium_Percentage__c,Parent_Quote__c, IPID_Document__c,Policy_Wording_Document__c,
                                           Technical_Premium__c,QuotePremium__c,Total_Premium__c,CloseDate__c,Accept_Terror_Premium__c,
                                           Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c, Special_Coverages__c,
                                           Parent_Quote__r.Non_Prorated_Quote_Premium__c,Parent_Quote__r.QuotePremium__c,
                                           Broker__r.Account.Azure_ID__c, Broker__r.Azure_ID__c,Broker__r.Id,
                                           Endorsement_Quote_Bound_Date__c,Broker__r.Name,Broker__r.Account.Name,                            
                                           Endorsement_Reason__c,Endorsement_Reason_Other__c, Override_Actual_Premium_Percent__c, 
                                           Override_Fee_Percent__c, Override_Actual_Excess_Percent__c, Technical_Fee__c,
                                           OverrideBrokerNettedDownPremiumPercent__c,As_if_Book_Rated_Premium_rate_change__c,
                                           Actual_Excess__c, Actual_Premium__c, Binder__c, Policy__c,Master_Binder__c,
                                           Book_Excess__c, Book_Premium__c, Book_Rated_Premium__c, Broker_Commission__c, 
                                           Broker_Netted_Down_Premium__c, Discretion__c, Excess_Basis__c, Fee__c, Final_Discretion__c, 
                                           IPT_on_Broker_Netted_Down_Premium__c, Jurisdiction_Limits__c, Layer__c, Limit_Basis__c, 
                                           MGA_Commission__c, Minimum_Premium__c, Netted_Down_Premium_Broker_Commission__c, 
                                           Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c,PI_Limit_of_Indemnity__c, 
                                           Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, 
                                           Previous_Year_Final_Discretion__c, Previous_Year_Exposure__c, Price_Adequacy__c, 
                                           Rate__c, Rateable_Exposure__c, RetroDate__c,Technical_Premium_Discretion__c, 
                                           Retroactive_Date__c, Revised_Broker_Commission__c, Revised_MGA_Commission__c, 
                                           Territorial_Limits__c, Total_Underlying_Layer__c,Rate_Change__c
                                           FROM Quote 
                                           WHERE Policy__c IN: policyIds
                                           AND Status = 'Bound'
                                           ORDER BY Endorsement_Quote_Bound_Date__c DESC];
        return quoteListFromPolicy;
    }

    public static List<Quote> queryRenewalQuoteAQ(Set<Id> quoteId){
        List<Quote> quoteList = [Select Id,Commission_percentage__c, Effective_Date__c, QuoteNumber, ExpirationDate,
                                           AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                                           Quote_Type__c, Name, Status, Rating_Status__c,Tax,Commission__c, Override_Premium__c, 
                                           Override_Premium_Percentage__c,Parent_Quote__c, IPID_Document__c,Policy_Wording_Document__c,
                                           Technical_Premium__c,QuotePremium__c,Total_Premium__c,CloseDate__c,Accept_Terror_Premium__c,
                                           Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c, Special_Coverages__c,
                                           Parent_Quote__r.Non_Prorated_Quote_Premium__c,Parent_Quote__r.QuotePremium__c,
                                           Broker__r.Account.Azure_ID__c, Broker__r.Azure_ID__c,Broker__r.Id,Parent_Quote__r.Policy__c,
                                           Endorsement_Quote_Bound_Date__c,Broker__r.Name,Broker__r.Account.Name,                            
                                           Endorsement_Reason__c,Endorsement_Reason_Other__c, Override_Actual_Premium_Percent__c, 
                                           Override_Fee_Percent__c, Override_Actual_Excess_Percent__c, Technical_Fee__c,
                                           OverrideBrokerNettedDownPremiumPercent__c,As_if_Book_Rated_Premium_rate_change__c,
                                           Actual_Excess__c, Actual_Premium__c, Binder__c, Policy__c,Master_Binder__c,
                                           Book_Excess__c, Book_Premium__c, Book_Rated_Premium__c, Broker_Commission__c, 
                                           Broker_Netted_Down_Premium__c, Discretion__c, Excess_Basis__c, Fee__c, Final_Discretion__c, 
                                           IPT_on_Broker_Netted_Down_Premium__c, Jurisdiction_Limits__c, Layer__c, Limit_Basis__c, 
                                           MGA_Commission__c, Minimum_Premium__c, Netted_Down_Premium_Broker_Commission__c, 
                                           Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c,PI_Limit_of_Indemnity__c, 
                                           Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, 
                                           Previous_Year_Final_Discretion__c, Previous_Year_Exposure__c, Price_Adequacy__c, 
                                           Rate__c, Rateable_Exposure__c, RetroDate__c,Technical_Premium_Discretion__c, 
                                           Retroactive_Date__c, Revised_Broker_Commission__c, Revised_MGA_Commission__c, 
                                           Territorial_Limits__c, Total_Underlying_Layer__c,Rate_Change__c
                                           FROM Quote 
                                           WHERE Id IN: quoteId];
        return quoteList;
    }

    public static List<Quote> queryCoverageCancelQuoteAQ(Set<Id> quoteId){
        List<Quote> quoteList = [Select Id,Commission_percentage__c,OpportunityId, Effective_Date__c, QuoteNumber, ExpirationDate,
                                           AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                                           Quote_Type__c, Name, Status, Rating_Status__c,Tax,Commission__c, Override_Premium__c, 
                                           Override_Premium_Percentage__c,Parent_Quote__c, IPID_Document__c,Policy_Wording_Document__c,
                                           Technical_Premium__c,QuotePremium__c,Total_Premium__c,CloseDate__c,Accept_Terror_Premium__c,
                                           Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c, Special_Coverages__c,
                                           Parent_Quote__r.Non_Prorated_Quote_Premium__c,Parent_Quote__r.QuotePremium__c,
                                           Broker__r.Account.Azure_ID__c, Broker__r.Azure_ID__c,Broker__r.Id,
                                           Endorsement_Quote_Bound_Date__c,Broker__r.Name,Broker__r.Account.Name,                            
                                           Endorsement_Reason__c,Endorsement_Reason_Other__c, Override_Actual_Premium_Percent__c, 
                                           Override_Fee_Percent__c, Override_Actual_Excess_Percent__c, Technical_Fee__c,
                                           OverrideBrokerNettedDownPremiumPercent__c,As_if_Book_Rated_Premium_rate_change__c,
                                           Actual_Excess__c, Actual_Premium__c, Binder__c, Policy__c,Master_Binder__c,
                                           Book_Excess__c, Book_Premium__c, Book_Rated_Premium__c, Broker_Commission__c, 
                                           Broker_Netted_Down_Premium__c, Discretion__c, Excess_Basis__c, Fee__c, Final_Discretion__c, 
                                           IPT_on_Broker_Netted_Down_Premium__c, Jurisdiction_Limits__c, Layer__c, Limit_Basis__c, 
                                           MGA_Commission__c, Minimum_Premium__c, Netted_Down_Premium_Broker_Commission__c, 
                                           Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c,PI_Limit_of_Indemnity__c, 
                                           Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, 
                                           Previous_Year_Final_Discretion__c, Previous_Year_Exposure__c, Price_Adequacy__c, 
                                           Rate__c, Rateable_Exposure__c, RetroDate__c,Technical_Premium_Discretion__c, 
                                           Retroactive_Date__c, Revised_Broker_Commission__c, Revised_MGA_Commission__c, 
                                           Territorial_Limits__c, Total_Underlying_Layer__c,Rate_Change__c,Total_Cost_to_Client__c,Product_Name__c
                                           FROM Quote 
                                           WHERE Id IN: quoteId];
        return quoteList;
    }

    /****************************************************** Celerity ***************************************************************/

    public static List<Quote> queryCoverageCancelQuoteCEL(Set<Id> quoteId){
        List<Quote> quoteList = [Select Id,Commission_percentage__c,OpportunityId, Effective_Date__c, QuoteNumber, ExpirationDate,
                                           AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                                           Quote_Type__c, Name, Status, Rating_Status__c,Tax,Commission__c, Override_Premium__c, 
                                           Override_Premium_Percentage__c,Parent_Quote__c, IPID_Document__c,Policy_Wording_Document__c,
                                           Technical_Premium__c,QuotePremium__c,Total_Premium__c,CloseDate__c,Accept_Terror_Premium__c,
                                           Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c, Special_Coverages__c,
                                           Parent_Quote__r.Non_Prorated_Quote_Premium__c,Parent_Quote__r.QuotePremium__c,
                                           Broker__r.Account.Azure_ID__c, Broker__r.Azure_ID__c,Broker__r.Id,
                                           Endorsement_Quote_Bound_Date__c,Broker__r.Name,Broker__r.Account.Name,                            
                                           Endorsement_Reason__c,Endorsement_Reason_Other__c, Override_Actual_Premium_Percent__c, 
                                           Override_Fee_Percent__c, Override_Actual_Excess_Percent__c, Technical_Fee__c,
                                           OverrideBrokerNettedDownPremiumPercent__c,As_if_Book_Rated_Premium_rate_change__c,
                                           Actual_Excess__c, Actual_Premium__c, Binder__c, Policy__c,Master_Binder__c,
                                           Book_Excess__c, Book_Premium__c, Book_Rated_Premium__c, Broker_Commission__c, 
                                           Broker_Netted_Down_Premium__c, Discretion__c, Excess_Basis__c, Fee__c, Final_Discretion__c, 
                                           IPT_on_Broker_Netted_Down_Premium__c, Jurisdiction_Limits__c, Layer__c, Limit_Basis__c, 
                                           MGA_Commission__c, Minimum_Premium__c, Netted_Down_Premium_Broker_Commission__c, 
                                           Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c,PI_Limit_of_Indemnity__c, 
                                           Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, 
                                           Previous_Year_Final_Discretion__c, Previous_Year_Exposure__c, Price_Adequacy__c, 
                                           Rate__c, Rateable_Exposure__c, RetroDate__c,Technical_Premium_Discretion__c, 
                                           Retroactive_Date__c, Revised_Broker_Commission__c, Revised_MGA_Commission__c, 
                                           Territorial_Limits__c, Total_Underlying_Layer__c,Rate_Change__c,Total_Cost_to_Client__c,Product_Name__c
                                           FROM Quote 
                                           WHERE Id IN: quoteId];
        return quoteList;
    }

}