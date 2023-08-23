@isTest
public class HttpConsumerTest {
    @isTest
    public static void testGetHttpRequest() {
        API_Configuration__mdt apiSettings = [SELECT id,Base_Url__c,Endpoint__c,HeaderParams__c,Method__c 
                                              FROM API_Configuration__mdt LIMIT 1];
        HttpConsumer.getHttpRequest(apiSettings,'Name=Test');
    }
}