@isTest
public class strike_utilitiesTest {
	@testSetup
    public static void setupData() {
        
    }
    
    @isTest
    public static void testSerializeWithoutNamespace() {
        Object myObject = '';
        Test.startTest();
        String result = strike_utilities.serializeWithoutNamespace(myObject);
        Test.stopTest();
        System.assert(result!=null);
    }
    
    @isTest
    public static void testConvertObjectToMap() {
        Object myObject = null;
        Test.startTest();
        Map<String, Object> m = strike_utilities.convertObjectToMap(myObject);
        Test.stopTest();
        System.assert(m==null);
	}
}