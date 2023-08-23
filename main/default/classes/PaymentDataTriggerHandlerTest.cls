@isTest
public class PaymentDataTriggerHandlerTest {
    @testSetup
    public static void setup() {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassBrokerAccountTrigger__c = false;
        setting.BypassContactTrigger__c = true;
        update setting;
        
        //Create Account
        Account acc1 = new Account();
        acc1.Name = 'Test account 2';
        acc1.BillingStreet = '11 Tran Duy Hung';
        acc1.BillingCity = 'Westminster';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '90000';
        acc1.BillingCountry = 'United States';
        //acc1.Billing_County__c;
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        
        // Create contact
        Contact con = new Contact(
            Lastname = 'Test broker',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con;
        
        Product2 product = TestUtil.createProduct('AQPI');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'Bound';
        quote1.Rating_Status__c = 'Clear';
        quote1.Quote_Type__c = 'New Business';
        
        insert quote1; 
        
        // create policy  
        Policy__c policy = new Policy__c();
        policy.Account__c = acc1.Id;
        policy.Product_Name__c = 'Professional Indemnity';
        policy.Expiration_Date__c = Date.today().addDays(100);
        policy.Total_Premium__c = 2000;
        policy.RecordTypeId = Schema.SObjectType.Policy__c.getRecordTypeInfosByName().get('Aqueous').getRecordTypeId();
        policy.Initial_Premium__c = null;
        insert policy;
        
        
        
    }
    @isTest
    public static void testMethod1() {
        Policy__c policy = [SELECT id FROM Policy__c LIMIT 1];
        Quote quote = [SELECT id FROM Quote LIMIT 1];
        Payment_Data__c paymentData = new  Payment_Data__c();
        paymentData.Policy__c = policy.Id ; 
        paymentData.Quote__c = quote.id;
        paymentData.Amount_Paid__c = 1234 ;
        paymentData.Last_Modified_Date__c = System.now();
        insert paymentData;
        
        Test.startTest();
        paymentData.Amount_Paid__c = 4444 ;
        update paymentData;
        list<Payment_Data__c> pd = [Select id , Last_Modified_Date__c from Payment_Data__c where id =: paymentData.Id ];
        
        DateTime lastModifiedDate;
        lastModifiedDate = System.now();
        //System.assertEquals(lastModifiedDate, pd[0].Last_Modified_Date__c);
        test.stopTest();
        
    }
    
    
    
    
}