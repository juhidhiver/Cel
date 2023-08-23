@isTest
public class SessionIdControllerTest {
	@isTest
    static void getSessionIdTest(){
        Test.startTest();
        try{
          SessionIdController.getSessionId();  
        }
        catch(exception ex){
            System.debug('Exception'+ex.getMessage());
        }
                Test.stopTest();
    }
}