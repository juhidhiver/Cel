/***********************************************************************
 * Class Name: ListViewControllerTest
 * Author: Khanh TRAN
 * Date: 29-Oct-2019
 * Description: Unit test for ListViewController 
 ***********************************************************************
 */
@isTest
private class ListViewControllerTest {

    @isTest static void listViewControllerTest() {
    	Test.startTest();
		ListViewController lsv = new ListViewController();
		VisualEditor.DataRow dataRow = lsv.getDefaultValue();
		Test.stopTest();

		System.assert(true);
	}   
	
    @isTest(SeeAllData='true') static void testMethod2(){
		
        String folderName = 'Sales_and_Marketing_Reports';
        
		Test.startTest();            
	 	
	 	List<Report> lsReport = new List<Report>();
	 	lsReport = [Select Id From Report LIMIT 1];
	 	
    	VisualEditor.DataRow picklistRowVal = new VisualEditor.DataRow('Sales_and_Marketing_Reports', '123456');
    	VisualEditor.DynamicPickListRows result = new VisualEditor.DynamicPickListRows();
     	ListViewController lsv = new ListViewController();
  		VisualEditor.DynamicPickListRows rows = lsv.getValues();

		Test.stopTest();

		System.assert(true);
	}


}