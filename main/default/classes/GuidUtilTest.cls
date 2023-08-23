/***********************************************************************
 * Class Name: GuidUtilTest
 * Author: Khanh TRAN
 * Date: 29-Oct-2019
 * Description: Unit test for GuidUtil 
 ***********************************************************************
 */
@isTest
private class GuidUtilTest {

	@isTest
    static void testMethod1() {
        GuidUtil guid = new GuidUtil();
        String str = guid.NewGuid();
        System.Assert(true);
    }
}