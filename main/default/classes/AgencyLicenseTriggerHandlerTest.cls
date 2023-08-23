/**************************************************************************************************
 * Class Name: AgencyLicenseTriggerHandlerTest
 * Author:  RINKU SAINI
 * Date: 
 * Description: 
 **************************************************************************************************/

@isTest
private class AgencyLicenseTriggerHandlerTest {
    static {
        
        Id brokerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Account acc = TestUtil.createAccount('Account_Business_Test_01', brokerRtId, '5305, Monroe Street', 'Toledo', 'Ohio','43623', 'United States');
        insert acc;
        
        //Create Agency License
        Agency_License__c agencyLicense = new Agency_License__c(
            License_Number__c 	= '123456',NIPR_License_Status__c = 'Pass', License_State__c = 'OH'	
        );
        
        insert agencyLicense;
        
        //Create Agency License added by RINKU SAINI 23-Dec-2021
        Agency_License__c agencyLicense1 = new Agency_License__c(
            License_Number__c 	= '123456',NIPR_License_Status__c = 'Pass', License_State__c = 'OH',
            RecordTypeId = Schema.SObjectType.Agency_License__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE).getRecordTypeId() 
        );
        insert agencyLicense1;
        //Create Agency License added by RINKU SAINI 23-Dec-2021
        Agency_License__c agencyLicense2 = new Agency_License__c(
            License_Number__c 	= '1234567',NIPR_License_Status__c = 'Pass', License_State__c = 'OH',
            RecordTypeId = Schema.SObjectType.Agency_License__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_BROKER_LICENSE_MRE).getRecordTypeId() 
        );
        insert agencyLicense2;
        
  
    }
    
    @isTest static void updatingTest(){
        List<Agency_License__c> agencyLicense = new List<Agency_License__c>();
        for (Agency_License__c item: [Select Id, License_Number__c, NIPR_License_Status__c, License_State__c from Agency_License__c]){
            item.License_Number__c = '12345679';
            item.NIPR_License_Status__c = 'Pass';
            item.License_State__c = 'NY';
            agencyLicense.add(item);
        }
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        Test.startTest();
        update agencyLicense;
        Test.stopTest();
        AgencyLicenseQueryUtil.fetchLicenseByAgencyId(agencyLicense[0].Id,'NY');
        system.debug('$$$agencyLicense='+agencyLicense);
        System.assertEquals(false, agencyLicense.isEmpty());
        
    }   
    
}