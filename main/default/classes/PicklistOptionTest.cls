/***********************************************
 * Class Name: PicklistOptionTest
 * Author: Giang Phan
 * Date: 09-Nov-2019
 * Description: PicklistOption Test
 ***********************************************/
@isTest
private class PicklistOptionTest {
	@isTest
    static void testPicklistOption() {
    	String valueStr = 'Value String';
    	String labelStr = 'Label String';
    	Test.startTest();
    	PicklistOption pl = new PicklistOption(valueStr,labelStr);
    	Test.stopTest();

    	System.assertEquals(true,pl.value == valueStr);
		System.assertEquals(true,pl.label == labelStr);
    }
}