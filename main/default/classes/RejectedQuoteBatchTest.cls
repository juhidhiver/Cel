@istest
public class RejectedQuoteBatchTest {
public static Product2 product;
    public static Account acc;
    
    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassPolicyTrigger__c = true;       
        setting.BypassRatingModifiersTrigger__c = true;
        setting.BypassAccountLossDetailTrigger__c = true;
        update setting;
        
  }	
    @isTest static void test(){
          acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        insert acc;
        
        Id aqueousRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        Product2 prod = TestUtil.createProduct('Professional Indemnity');
        prod.RecordTypeId = aqueousRecordTypeId;
        prod.Innovisk_Entity_ID__c = 'Aqueous';
        insert prod;
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, prod.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        opp.CloseDate = Date.today();
        opp.Innovisk_Entity_ID__c = 'Aqueous';        
        opp.Coverage_Product_Options__c = 'Professional Indemnity';
        
        opp.StageName = 'Qualified';
        opp.Expiration_Date__c = Date.today()+60;
        insert opp;
          
        Quote quote = TestUtil.createQuote('New quote', opp.Id);
        quote.Layer__c = 'Primary';
        quote.Coverage_Product_Options__c = 'Professional Indemnity';
        quote.Status = 'In Approval';
        quote.Refer_Type__c = 'Underwriting Referral';
        insert quote; 
        quote.Is_Quote_Approved_AQ__c = 'Rejected';
        quote.Status = 'Rated';
        update quote;
         
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(quote.id);
        
        app.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        Approval.ProcessResult result = Approval.process(app);
        
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('Rejecting request.');
        req.setAction('Reject');
        ProcessInstanceWorkitem pItem = [Select Id from ProcessInstanceWorkitem  where ProcessInstance.TargetObjectId =: quote.id];
        req.setWorkitemId(pItem.Id);
        Approval.ProcessResult result2 = Approval.process(req);
        
        List<ProcessInstance> processInstances = [SELECT Status,TargetObjectId,CompletedDate FROM ProcessInstance WHERE Status = 'Rejected' ]; 
        
        Test.startTest();  
        RejectedQuoteBatch rejectedQuote = new RejectedQuoteBatch();
        //rejectedQuote.dateBeforeSevenDays = System.now();
        Id batchId = Database.executeBatch(rejectedQuote, 10);
        system.assert(batchId != null);
        
       // rejectedQuote.dateBeforeSevenDays = null;
        Id batchId2 = Database.executeBatch(rejectedQuote, 10);
        system.assert(batchId2 != null);
        Test.stopTest();
    }

}