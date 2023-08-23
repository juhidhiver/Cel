@isTest
public class CommonAccountUtil_Test {
    
    @isTest
    static void testGetInitData1() {
       
        List<Account> newAcc = new List<Account>();
        List<Account> oldAcc = new List<Account>();
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;
        acc.Review_Requested_By__c = UserInfo.getUserId();
        acc.AQ_Sanction_Status__c = 'Cleared';
        acc.IsMailingSameWithBillingAddress__c = true;
        
        insert acc;
        
        Account acc1 = TestUtil.createBusinessAccount('Bussiness Accoun Aq1', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc1.BillingStreet = acc1.ShippingStreet;
        acc1.BillingCity = acc1.ShippingCity;
        acc1.BillingState = acc1.ShippingState;
        acc1.BillingPostalCode = acc1.ShippingPostalCode;
        acc1.BillingCountry = acc1.ShippingCountry;
        acc1.Review_Requested_By__c = UserInfo.getUserId();
        acc1.AQ_Sanction_Status__c = 'Amber';
        insert acc1;
        oldAcc.add(acc);
        
        
        acc.AQ_Sanction_Status__c = 'Amber';
        acc.Insured_Account_Update_Policy_Id__c = 'ABC';
        acc.Action_Point__c = 'Endorsement';
        update acc;
        
        newAcc.add(acc);
        
        AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition LIMIT 1];        
        
        UserAppInfo app = new UserAppInfo(AppDefinitionId = appDefinition.DurableId, 
                                          UserId = UserInfo.getUserId(), FormFactor = 'Small');        
        insert app;
        
        Test.startTest();
        	CommonAccountUtil.copyBillingAddressToMailingAddress(newAcc);
        	CommonAccountUtil.insertKYCSanctionDate(newAcc);
        	CommonAccountUtil.updateKYCSanctionDate(oldAcc, newAcc);
        	CommonAccountUtil.validateSanctionCheckOnExistingAccount(acc.Id);
        	CommonAccountUtil.generateExternalID('Azure_ID__c',newAcc);
        	CommonAccountUtil.getAppName();
        Test.stopTest();
        
    }
    
}