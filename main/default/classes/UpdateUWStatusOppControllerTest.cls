@isTest
public class UpdateUWStatusOppControllerTest {
@testSetup
    public static void setup() {
        TriggerSettings__c setting = new TriggerSettings__c();
        setting.BypassOpportunityTrigger__c = true;
        setting.BypassQuoteTrigger__c = true;
        setting.BypassRatingModifiersTrigger__c = true;
        insert setting;
        
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

        Product2 product = TestUtil.createProduct('MPL');
    insert product;
        
        Policy__c policy = new Policy__c();
        policy.Account__c = acc1.Id; 
        policy.Expiration_Date__c = Date.today().addDays(100);
        insert policy;
        
        Opportunity opportunity = TestUtil.createOpportunity('Opp Test',acc1.Id, product.Id);
        opportunity.Policy__c = policy.Id;
        insert opportunity;
        
        //Create Rating_Modifier_Template__c list
        List<Rating_Modifier_Template__c> listRatingModifierTemp = new List<Rating_Modifier_Template__c>();
        Rating_Modifier_Template__c ratingModifiersTemp1 = TestUtil.createRatingModifierTemplate('Input number field', product.Name , 'Number');
        ratingModifiersTemp1.Rating_Modifier_Code__c = 'MPL000025';
        Rating_Modifier_Template__c ratingModifiersTemp2 = TestUtil.createRatingModifierTemplate('Input number field', 'MPL' , 'Integer');
        listRatingModifierTemp.add(ratingModifiersTemp1);
        listRatingModifierTemp.add(ratingModifiersTemp2);
        insert listRatingModifierTemp;
        
        //Create Eligibility Status
        Eligibility_Status__c es = new Eligibility_Status__c();
        es.Rating_Modifier_Template__c = listRatingModifierTemp[0].Id;
        es.Rating_Modifier_Value__c = 'Yes';
        es.Eligibility_Status__c = 'Proceed';
        es.Modifier_Product__c = 'MPL';
        insert es;
        
        
        //Create Rating_Modifiers__c list
        List<Rating_Modifiers__c> lstRatingModifier = new List<Rating_Modifiers__c>();
        Rating_Modifiers__c ratingModifier1 = TestUtil.createRatingModifier('Rating field test1', product.Name, opportunity.Id);
        ratingModifier1.Rating_Modifier_Code__c = 'MPL000025';
        ratingModifier1.Display_Format__c = 'Primary Modifiers';
        ratingModifier1.Opportunity__c = opportunity.Id;
        ratingModifier1.Rating_Modifier_Value__c = 'Yes';
        ratingModifier1.Page_Section__c = 'Pros and Cons';
        ratingModifier1.Format__c = 'Picklist';
        ratingModifier1.Picklist_Values__c = 'At least one very restrictive endorsement;At least one restrictive endorsement and no very restrictive endorsements;No restrictive endorsement';
        Rating_Modifiers__c ratingModifier2 = TestUtil.createRatingModifier('Rating field test2', 'MPL', opportunity.Id);
        ratingModifier2.Display_Format__c = 'Pros and Cons';
        ratingModifier2.Rating_Modifier_Value__c = '27';
        ratingModifier2.Rating_Modifier_Code__c = 'MPL000004';
        ratingModifier2.Page_Section__c = 'Industry Class';
        ratingModifier2.Sub_Section__c = 'Company Info'; 
        ratingModifier2.Opportunity__c = opportunity.Id;
        ratingModifier2.Format__c = 'Percentage';
        lstRatingModifier.add(ratingModifier1);
        lstRatingModifier.add(ratingModifier2);
        
        for(Integer i=0;i<5;i++) {
          Rating_Modifiers__c ratingModifier = TestUtil.createRatingModifier('Rating field test'+String.valueOf(i+5),'MPL', opportunity.Id);                 
          ratingModifier.Rating_Modifier_Code__c = 'MPL0000'+String.ValueOf((i+20));
          
          ratingModifier.Opportunity__c = opportunity.Id;
          ratingModifier.Rating_Modifier_Value__c = '27';
          ratingModifier.Page_Section__c = 'Pros and Cons';
            if(i==0) {
              ratingModifier.Sub_Section__c = 'Company Info';  
              ratingModifier.Format__c = 'Currency';
              ratingModifier.Display_Format__c = 'Primary Modifiers';  
            } else if(i==1) {
              ratingModifier.Format__c = 'Integer';
              ratingModifier.Display_Format__c = 'Primary Modifiers';  
            } else if(i==2) {
              ratingModifier.Format__c = 'Number';
              ratingModifier.Display_Format__c = 'Primary Modifiers';
            } else if(i==3) {
              ratingModifier.Format__c = 'Text';
              ratingModifier.Display_Format__c = 'Primary Modifiers';
              ratingModifier.Profile_Name_for_Read_Only__c = 'Celerity Senior Underwriter';  
            } else if(i==4) {
              ratingModifier.Display_Format__c = 'Primary Modifiers';
              ratingModifier.Profile_Name_for_Read_Only__c = 'All';  
            }
              
          lstRatingModifier.add(ratingModifier);
        }
        insert lstRatingModifier;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opportunity.Id);
    quote.Coverage_Product_Options__c ='MPL';
        quote.Policy__c = policy.Id;
        quote.Status = 'Rated';
        insert quote;
        
        Quote_Process__c qp = new Quote_Process__c();
        qp.Account__c = acc1.Id;
        qp.Submission__c = opportunity.Id;
        insert qp;
    }
    @isTest
    public static void testGetProductNameTabs() {
    Opportunity opp =[select id from Opportunity Limit 1];
    Quote_Process__c  qpObj=[select id from Quote_Process__c Limit 1];
    UpdateUWStatusOppController.UpdateStatus(opp.id,'Quoted');
     UpdateUWStatusOppController.UpdateStatus(qpObj.id,'Quoted');
     String test1 = UpdateUWStatusOppController.selectedValueUwStatus(opp.id);
     String test =  UpdateUWStatusOppController.selectedValueUwStatus(qpObj.id);
      UpdateUWStatusOppController.getUWStatus();
      System.assertEquals(test1 != null,true);
    }
    
    @isTest
    public static void testGetProduct() {
    Opportunity opp =[select id,Submission_Status__c  from Opportunity Limit 1];
     Quote_Process__c  qpObj=[select id from Quote_Process__c Limit 1];
     
      UpdateUWStatusOppController.UpdateSubmissisonStatus(opp.id,opp.Submission_Status__c);
      UpdateUWStatusOppController.UpdateSubmissisonStatus(qpObj.id,opp.Submission_Status__c);
      UpdateUWStatusOppController.selectedValueSubmissionStatus(opp.Id);
      UpdateUWStatusOppController.selectedValueSubmissionStatus(qpObj.id);
      UpdateUWStatusOppController.getSubmisisonStatus();
       String test =UpdateUWStatusOppController.getObjectType(opp.id);
      UpdateUWStatusOppController.getObjectType(qpObj.id);
     
      System.assertEquals(test != null,true);
    }
    }