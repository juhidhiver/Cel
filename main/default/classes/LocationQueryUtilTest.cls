/**************************************************************************************************
 * Class Name: LocationQueryUtilTest
 * Author: Vinay Vernekar
 * Date: 27th Dec 2021
 * Description: Test class for LocationQueryUtil
 **************************************************************************************************/
@isTest
public with sharing class LocationQueryUtilTest {
    public static testmethod void test_fetchAllLocations() {
        Location__c loc = TestUtil.createNewLocation('132, 1st Avenue','New York', 'United States', '10093', 'New York');
        insert loc;		

        Test.startTest();
        List<Location__c> locations = LocationQueryUtil.fetchAllLocations(new Set<String>{'132, 1st Avenue'}, new Set<String>{'New York'}, new Set<String>{'New York'}, new Set<String>{'10093'}, new Set<String>{'United States'});
        System.assert(locations.size() != 0);
        Test.stopTest();
    }
}