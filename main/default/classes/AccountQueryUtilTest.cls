/**************************************************************************************************
* Class Name: AccountQueryUtilTest
* Author: RINKU SAINI
* Date: 30th Dec 2021
* Description: 
**************************************************************************************************/
@isTest
public class AccountQueryUtilTest {
    
    public static testmethod void coverAccountQueryUtil(){
        Test.startTest();
        
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
        
        Contact con = new Contact(
            Email = 'test@j.com',
            Lastname = 'Test broker',
            AccountId = acc.Id
        );
        insert con;
        
        Location__c loc = TestUtil.createNewLocation('234, 1st Avenuet','New York', 'United States', '10593', 'California');
        loc.State_Code__c  = 'LA';
        insert loc; 
        
        
        Account_Location__c accLoc = new Account_Location__c();
        accLoc.Account__c = acc.Id;
        accLoc.Location__c = loc.Id;
        Database.insert(accLoc, false);
        
        
        
        AccountQueryUtil.fetchAllLocations( New Set<String>{'234, 1st Avenuet'}, New Set<String>{'New York'},  New Set<String>{'United States'}, New Set<String>{'10593'}, New Set<String>{'California'});
        AccountQueryUtil.fetchAccountLocations( New Set<Id>{acc.Id});
        AccountQueryUtil.fetchAccountsById( New Set<String>{acc.Id});
        AccountQueryUtil.fetchAccountById(acc.Id);
        AccountQueryUtil.fetchAccountWithContacts(acc.Id);
        AccountQueryUtil.fetchAccountWithSpecificContact(acc.Id,con.Id);
        AccountQueryUtil.fetchAccountInfo( New Set<Id>{acc.Id});
        Test.stopTest();
    }
}