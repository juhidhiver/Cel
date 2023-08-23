/**************************************************************************************************
 * Class Name: CoverageQueryUtilTest
 * Author: Vinay V
 * Date: Dec 28th, 2021
 * Description: Test class for CoverageQueryUtil
 **************************************************************************************************/
@isTest
public with sharing class CoverageQueryUtilTest {
    @testsetup
	static void testSetup(){
		Coverage__c cov1 = new Coverage__c(Name = 'Coverage Name', Form_Number__c = 'ACMP 27 03 08 04', Coverage_Product__c = 'MPL', Coverage_Type__c = 'Endorsement');
		insert cov1;
    }

    static testmethod void test_fetchCoveragesByProducts(){
        Test.startTest();
        List<Coverage__c> coverages = CoverageQueryUtil.fetchCoveragesByProducts(new list<String>{'MPL'});
        // added by Rinku Saini 3rd Jan 2022
        CoverageQueryUtil.fetchCoveragesByProductName(new list<String>{'MPL'});
        system.assert(coverages.size() > 0);
        Test.stopTest();
    }
}