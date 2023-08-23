/**************************************************************************************************
 * Class Name: AccountLocationQueryUtilTest
 * Author: Vinay Vernekar
 * Date: 27th Dec 2021
 * Description: Test class for AccountLocationQueryUtil
 **************************************************************************************************/
@isTest
public with sharing class AccountLocationQueryUtilTest {
    public static testmethod void test_fetchAccountLocations() {
        Account acc = new Account();
        acc.Name = 'Test account location';
        acc.BillingStreet = '234, 1st Avenue';
        acc.BillingCity = 'New York';
        acc.BillingState = 'California';
        acc.BillingPostalCode = '10593';
        acc.BillingCountry = 'United States';
        acc.BillingLongitude = Decimal.valueOf('28.388215');
        acc.BillingLatitude = Decimal.valueOf('-81.482303');		
        acc.Date_Started__c = Date.today().addYears(-2);
        insert acc;
        
        Location__c loc = TestUtil.createNewLocation('132, 1st Avenue','New York', 'United States', '10093', 'New York');
        insert loc;		
        
        Account_Location__c accLoc = new Account_Location__c();
        accLoc.Account__c = acc.Id;
        accLoc.Location__c = loc.Id;
        Database.insert(accLoc, false);

        Test.startTest();
        List<Account_Location__c> accountLocations = AccountLocationQueryUtil.fetchAccountLocations(new set<Id>{acc.id});
        System.assertEquals(accountLocations.size(), 2);
        Test.stopTest();
    }
}