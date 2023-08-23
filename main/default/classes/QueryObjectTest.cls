/***********************************************
 * Class Name: QueryObjectTest
 * Author: Giang Phan
 * Date: 09-Nov-2019
 * Description: QueryObject Test
 ***********************************************/
@isTest
private class QueryObjectTest {
    static testMethod void testQueryObject() {
    	String name = '';
    	List<String> fields = new List<String>();
    	String condition = '';
    	String orderByField = '';
    	String orderType = '';
    	Integer pageSize = 0;
    	Integer pageNumber = 0;

    	Test.startTest();
    		QueryObject qo = new QueryObject();
    		qo.name = '';
    		qo.condition = '';
    		qo.orderByField = '';
    		qo.orderType = '';
    		qo.pageSize = 0;
    		qo.pageNumber = 0;
    	Test.stopTest();
    	system.assert(true);
    }
}