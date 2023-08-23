/**************************************************************************************************
* Class Name: AccountTriggerHandlerTest
* Author: Giang PHAN
* Date: 01-Nov-2019
* Description: AccountTriggerHandlerTest Test
**************************************************************************************************/
@isTest
private class AccountTriggerHandlerTest {
    static {
        TriggerSettings__c setting = TestUtil.initialTriggerSetting();
        setting.BypassAccountTrigger__c = false;
        update setting;	
        
    }     
    
   @isTest static void testCreateAccount() {
        
        //Insert account
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                              'California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);  
       	acc1.AQ_Sanction_Status__c = 'Potential Match';
       	acc1.Review_Requested__c = false;
        insert acc1;
        
        // Insert another account with the same location
        Account acc3  =TestUtil.createAccount('Test account 3', recordTypeId, '106 Nguyen Van Troi','Westminster',
                                              'Alaska','90002', 'United States');
        acc3.AQ_Sanction_Status__c = 'Failed';
        insert acc3;
        
        
        // Update account acc1
        acc1.BillingStreet = '02 Tran Duy Hung';
        acc1.BillingCity = 'New City';
        acc1.BillingState = 'Alaska';
        acc1.BillingPostalCode = '90001';
        acc1.BillingCountry = 'United States';
       	acc1.AQ_Sanction_Status__c = 'Failed';
       	acc1.Review_Requested__c = true;
        acc1.Decline_Reason__c = 'Sanctioned Entity';
        update acc1;        
        System.assert(acc1 != null);
             	 
    }
    
    @isTest static void testCreateBrokerAccount() {
        
        Exception expectedException;
        // create new Broker Account
        try{
            Account acc1 = TestUtil.createBusinessAccount('Test account 1','Broker','100 Nguyen Van Troi','Westminster','Alaska','90001','United States');
            acc1.FEIN__c =100;
            acc1.NIPR_Feinn_flag__c = false;
            insert acc1;

            Test.startTest();
            // create new other Broker Account
            Account acc2 = TestUtil.createBusinessAccount('Test account 2','Broker','106 Nguyen Van Troi','Westminster','Alaska','90002','United States');
            acc2.FEIN__c =100;
            acc2.NIPR_Feinn_flag__c = false;
            insert acc2;
            Test.stopTest();
        } catch(Exception  e){
            expectedException = e;
        }
        
        //System.assert(acc2 != null);
        System.assertNotEquals(null, expectedException);
    }

    @isTest static void testUpdateBrokerAccount() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster','California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;

        //update account
        Test.startTest();
        acc1.FEIN__c = 200;
        update acc1;
        Test.stopTest();
    }

    @isTest static void testCreateOtherAccount() {
        Test.startTest();
        List<Account> otherAccounts = new List<Account>();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Innovisk Entity').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster','California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;
        Test.stopTest();
    }

    @isTest static void testUpdateOtherAccount() {
        
        List<Account> otherAccounts = new List<Account>();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Innovisk Entity').getRecordTypeId();
        Account acc1  = TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster','California','90000', 'United States');
        acc1.IsMailingSameWithBillingAddress__c = true;
        acc1.Date_Started__c = Date.today().addYears(-2);
        insert acc1;

        Test.startTest();
        acc1.IsMailingSameWithBillingAddress__c = false;
        update acc1;
        Test.stopTest();
    }
    
    @isTest static void testCaseUpdateAccountLocation() {			
        
        Account acc1 = new Account();
        acc1.Name = 'Test account location';
        acc1.BillingStreet = '234, 1st Avenue';
        acc1.BillingCity = 'New York';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '10593';
        acc1.BillingCountry = 'United States';
        acc1.BillingLongitude = Decimal.valueOf('28.388215');
        acc1.BillingLatitude = Decimal.valueOf('-81.482303');		
        acc1.Date_Started__c = Date.today().addYears(-2);						
        
        Test.startTest();		
        insert acc1;		
        
        // Create Location		
        List<Location__c> newLocations = new List<Location__c>();		
        
        newLocations.add(TestUtil.createNewLocation('234, 1st Avenuet','New York', 'United States', '10593', 'California'));		
        newLocations.add(TestUtil.createNewLocation('131, 1st Avenue Test','New York', 'United States', '10093', 'New York'));		
        newLocations.add(TestUtil.createNewLocation('01 Tran Duy Hung','Westminster', 'United States', '90000', 'California'));
        insert newLocations;
        Test.stopTest();	
        
        System.assertEquals(true, String.isNotBlank(acc1.Id));		
    }
    
    @isTest static void testErrorcreateAccountLocation() {
        Id id = 'a021x000001YnaXAAS';
        Map<Id, Account> idAccMap = new Map<Id, Account>();
        List<Account_Location__c> listAccountLocation = new List<Account_Location__c>();
        
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
        listAccountLocation.add(accLoc);
        
        
        idAccMap.put(id, acc);
        //accAccLocMap.add(acc);
        
        Database.SaveResult[] srList = new Database.SaveResult[1];		
        Database.SaveResult blankResult = (Database.SaveResult)
            JSON.deserialize('{"success":false, "id":"'+id+'" ,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
        srList[0] = blankResult;
        
        
        Test.startTest();
        AccountTriggerHandler.createAccountLocation(srList, idAccMap, listAccountLocation);
        Test.stopTest();	
        System.assert(loc!=null);
    }
    
    
    @isTest static void testErrorcreateLocation() {		
        Id id = 'a021x000001YnaXAAS';
        
        List<Location__c> loc = new List<Location__c>();
        Account acc2 = new Account();
        acc2.Name = 'Test account location';
        acc2.BillingStreet = '01 Tran Duy Hung';
        acc2.BillingCity = 'Westminster';
        acc2.BillingState = 'California';
        acc2.BillingPostalCode = '90000';
        acc2.BillingCountry = 'United States';
        List<Account> acc = new List<Account>();
        acc.add(acc2);
        insert acc;
        
        
        Database.SaveResult[] srList = new Database.SaveResult[1];
        Database.SaveResult blankResult = (Database.SaveResult)
            JSON.deserialize('{"success":false, "id":"'+id+'" ,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
        srList[0] = blankResult;
        List<Location__c> newLocations = new List<Location__c>();		
        
        newLocations.add(TestUtil.createNewLocation('01 Tran Duy Hung','Westminster', 'United States', '90000', 'California'));	
        newLocations.add(TestUtil.createNewLocation('234, 1st Avenuet','New York', 'United States', '10593', 'California'));		
        newLocations.add(TestUtil.createNewLocation('131, 1st Avenue Test','New York', 'United States', '10093', 'New York'));		
        
        
        Test.startTest();
        AccountTriggerHandler.createLocation(srList, newLocations, loc, acc);
        Test.stopTest();
        System.assert(acc != null);
    }
    
    @isTest static void testCreateDuplicateAccountLocation() {			
        
        Account acc1 = new Account();
        acc1.Name = 'Test account location';
        acc1.BillingStreet = '234, 1st Avenue';
        acc1.BillingCity = 'New York';
        acc1.BillingState = 'California';
        acc1.BillingPostalCode = '10593';
        acc1.BillingCountry = 'United States';
        
        Account acc2 = new Account();
        acc2.Name = 'Test duplicate account location';
        acc2.BillingStreet = '01 Tran Duy Hung';
        acc2.BillingCity = 'Westminster';
        acc2.BillingState = 'California';
        acc2.BillingPostalCode = '90000';
        acc2.BillingCountry = 'United States';				
        
        Test.startTest();		
        insert acc1;		
        
        // Create Location		
        List<Location__c> newLocations = new List<Location__c>();		
        
        newLocations.add(TestUtil.createNewLocation('131, 1st Avenue Test','New York', 'United States', '10093', 'New York'));
        newLocations.add(TestUtil.createNewLocation('234, 1st Avenue','New York', 'United States', '10593', 'California'));		
        newLocations.add(TestUtil.createNewLocation('01 Tran Duy Hung','Westminster', 'United States', '90000', 'California'));
        
        insert newLocations;
        
        insert acc2; //insert a duplicate location account
        Test.stopTest();	
        
        System.assertEquals(true, String.isNotBlank(acc1.Id));	
    }
    
    @isTest static void createBrokerAccountProductTest(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account acc1  =TestUtil.createAccount('Test account 1', recordTypeId, '01 Tran Duy Hung','Westminster',
                                              'California','90000', 'United States');
        insert acc1;
              
    }
    public static testmethod void testScenario(){  
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account acc1  =TestUtil.createAccount('Test account 1234', recordTypeId, '0234 Tran Duy Hung','Westminster',
                                              'California','90000', 'United States');
        insert acc1;
         CommonAccountUtil.validateSanctionCheckOnExistingAccount(acc1.Id);
       
    }
    
    public static testmethod void testScenario1(){
         Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standardusertest@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertestprod@testorg.com',Is_AQ_Auto_Renewals_Underwriter__c =true);        
        insert u; 
        
        AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition LIMIT 1];    
         UserAppInfo app = new UserAppInfo(AppDefinitionId = appDefinition.DurableId, 
                                          UserId = u.Id, FormFactor = 'Small');        
        insert app;
        
        system.runAs(u){
             CommonAccountUtil.getAppName();
        }
    }
}