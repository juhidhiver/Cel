@isTest
public class TreeStructureTest {

    @isTest
    static void method1(){
        Test.startTest();
       	TreeStructure ts = new TreeStructure('Test','Tree', True, new List<TreeStructure>{});
        Test.stopTest();
    }
}