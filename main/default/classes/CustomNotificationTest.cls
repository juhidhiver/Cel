@isTest
public class CustomNotificationTest {

    @isTest
    static void testGetInitData1() {
        
        Account acc = TestUtil.createBusinessAccount('Bussiness Accoun Aq', 'Business', '123 Main Street', 'Anycity', 'England', '11354', 'United Kingdom');
        acc.BillingStreet = acc.ShippingStreet;
        acc.BillingCity = acc.ShippingCity;
        acc.BillingState = acc.ShippingState;
        acc.BillingPostalCode = acc.ShippingPostalCode;
        acc.BillingCountry = acc.ShippingCountry;       
        insert acc;
        
        Test.startTest();
        	CustomNotification.requestSanctionClearance(acc.Id, acc.Name);
        	CustomNotification.notificationApprovingClearance(acc.Id, acc.Name);
        	CustomNotification.notificationDeclineSanction(acc.Id, acc.Name);
        Test.stopTest();
        
    }
    
}