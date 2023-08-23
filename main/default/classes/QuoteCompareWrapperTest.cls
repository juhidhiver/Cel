@isTest
public class QuoteCompareWrapperTest {
	@isTest
    static void method1(){
        Test.startTest();
        QuoteCompareWrapper obj = new QuoteCompareWrapper();
           obj.quoteName = 'Quote 1';				
	 	   obj.status 	= 'Test Status';				
	  	   obj.version = '2';					
	 	   obj.aggregateLimit 	= '22';		
	 	   obj.retention 	= '3';		
	 	   obj.sublimitsAndEndorsements= 'test';
	 	   obj.supplementaryPayments = '222';	
	 	   obj.retro 		= '22';			
		   obj.ratingAdjustments = 'test';		
		   obj.yearInBussiness 	= 'test';		
        Test.stopTest();
    }
}