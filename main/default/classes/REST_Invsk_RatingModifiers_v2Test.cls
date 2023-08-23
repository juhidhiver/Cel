@isTest
public class REST_Invsk_RatingModifiers_v2Test {
    @testSetup
    public static void setup() {
        Account acc = TestUtil.createBusinessAccount('Bussiness Account Test', 'Business', '123 Main Street', 'Anycity', 'New York', '11354', 'United States');
        insert acc;
        
        Product2 product = TestUtil.createProduct('MPL Standalone');
        insert product; 
        
        Opportunity opp = TestUtil.createOpportunity('Opp Test',acc.Id, product.Id);
        opp.CloseDate = Date.today();
        opp.StageName = 'Prospect';
        opp.Azure_ID__c = '123';
        insert opp;
        
        Quote quote1 = TestUtil.createQuote('New quote 1', opp.Id);
        quote1.Status = 'In Progress';
        quote1.Coverage_Product_Options__c = 'D&O';
        quote1.Quote_Type__c = 'New Business';
        quote1.Refer_Type__c = 'Underwriting Referral';
        insert quote1; 
        
        //Create coverage
        List<Coverage__c> lCov = new List<Coverage__c>();
        Coverage__c cov = TestUtil.createCoverage('Coverage test', 'D&O');
        cov.Coverage_Product__c = 'D&O';
        lCov.add(cov);
        Coverage__c cov1 = TestUtil.createCoverage('Coverage test', 'MPL');
        lCov.add(cov1);
        insert lCov;
        
        //create limit deductables
        Coverage_Limits_Deductibles__c ded = TestUtil.creatLimitsDeductibles('Deductible test', cov.Id);
        insert ded;
        
        Quote quote = TestUtil.createQuote('New Quote Test',opp.Id);
        quote.Coverage_Product_Options__c ='MPL';       
        insert quote;
        
        quote.Status = 'Rated';
        update quote;
        
        Rating_Modifiers__c ratingModifier = new Rating_Modifiers__c(Name = 'New Rating Modifier1',Product__c='MPL',
                                                          Rating_Modifier_Code__c='abcd', Opportunity__c = opp.Id );
        insert ratingModifier;
        
        Rating_Modifier_Template__c ratingModifierTemplate = TestUtil.createRatingModifierTemplate('New input integer','MPL','Integer');
        insert ratingModifierTemplate;
        
        ratingModifierTemplate.Page_Section__c = 'SME Eligibility';
        ratingModifierTemplate.Rating_Modifier_Code__c = 'MPL100001';
        update ratingModifierTemplate;      
    }
    
    @isTest
    static void  upsertRatingModifiersFailTest1(){
        Test.startTest();        
        Opportunity currentOpp = [SELECT Azure_ID__c FROM Opportunity];
        
        Rating_Modifiers__c rating =[SELECT Id,Azure_Id__c,Name,Rating_Modifier_Code__c,Opportunity__c from Rating_Modifiers__c];
        List<Rating_Modifiers__c> requestRM = new List<Rating_Modifiers__c>();
        requestRM.add(rating);
        
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_RatingModifiers_v2/*';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(requestRM));
        system.debug('requestBody' + request.requestBody);
        
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;        
        
        REST_Invsk_RatingModifiers_v2.upsertRatingModifiers();
        Test.stopTest();
        
        System.assertEquals(500, RestContext.response.statusCode);
    }
    
    @isTest
    static void  upsertRatingModifiersFailTest2(){
        Test.startTest();
        
        Opportunity currentOpp = [SELECT Azure_ID__c FROM Opportunity];
        
        Rating_Modifiers__c rating =[SELECT Id,Azure_Id__c,Name,Rating_Modifier_Code__c,Opportunity__c,Product__c
                                     from Rating_Modifiers__c where Rating_Modifier_Code__c = 'abcd'];
        
        List<Rating_Modifiers__c> newRatings = new List<Rating_Modifiers__c>();
        newRatings.add(rating);
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_RatingModifiers_v2/*';
        request.httpMethod = 'POST';
        
        String jsonRequestBody = JSON.serialize(newRatings);
        jsonRequestBody = jsonRequestBody.replace(rating.Opportunity__c, currentOpp.Azure_ID__c);
        request.requestBody = Blob.valueOf(jsonRequestBody);
        
        system.debug('requestBody' + request.requestBody);
        
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;
        
        
        REST_Invsk_RatingModifiers_v2.upsertRatingModifiers();
        Test.stopTest();
        
        System.assertEquals(500, RestContext.response.statusCode);
    }
    
    @isTest
    static void  upsertRatingModifiersSuccessTest1(){
        Test.startTest();        
        Opportunity currentOpp = [SELECT Azure_ID__c FROM Opportunity];
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_RatingModifiers_v2/*';
        request.httpMethod = 'POST';
        
        String jsonRequestBody1 = '[{"Product__c": "Celerity_MPL","Opportunity__c": "'+currentOpp.Azure_ID__c+'","Rating_Modifier_Value__c": "Yes","Rating_Modifier_Code__c": "MPL100001"}]';
        request.requestBody = Blob.valueOf(jsonRequestBody1);
        
        system.debug('requestBody' + request.requestBody);
        
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;       
        
        REST_Invsk_RatingModifiers_v2.upsertRatingModifiers();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }    
    
    @isTest
    static void  upsertRatingModifiersSuccessTest2(){
        Test.startTest();
        
        Opportunity currentOpp = [SELECT Azure_ID__c FROM Opportunity];
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Invsk_RatingModifiers_v2/*';
        request.httpMethod = 'POST';
        
        String jsonRequestBody1 = '[{"Product__c": "Celerity_MPL","Opportunity__c": "'+currentOpp.Azure_ID__c+'","Rating_Modifier_Value__c": "Yes","Rating_Modifier_Code__c": "MPL100001"}]';
        request.requestBody = Blob.valueOf(jsonRequestBody1);
        
        system.debug('requestBody' + request.requestBody);
        
        // Set up a test request
        RestResponse response = new RestResponse();
        
        // Call the method to test
        RestContext.request = request;
        RestContext.response = response;        
        
        REST_Invsk_RatingModifiers_v2.upsertRatingModifiers();
        Test.stopTest();
        
        System.assertEquals(200, RestContext.response.statusCode);
    }
    
    @isTest static void  OutcomingResponsePostTest(){
        Test.startTest();
        
        REST_Invsk_RatingModifiers_v2.OutcomingResponsePost outcomeResponsePost
            = new REST_Invsk_RatingModifiers_v2.OutcomingResponsePost();
        outcomeResponsePost.status = 'Test Status';
        outcomeResponsePost.isSuccess = true;
        outcomeResponsePost.errors = new List<String>{'Error1', 'Error2'};
            
            List<Rating_Modifiers__c> ratings =[SELECT Id,Azure_Id__c,Name,Rating_Modifier_Code__c,Opportunity__c,Product__c
                                                from Rating_Modifiers__c where Rating_Modifier_Code__c = 'abcd'];
        outcomeResponsePost.RatingModifiers = ratings; 
        
        Test.stopTest();
        System.assert(outcomeResponsePost != null);
    }
    
    @isTest static void  OutcomingResponseGetTest(){
        Test.startTest();
        
        REST_Invsk_RatingModifiers_v2.OutcomingResponseGet outcomeResponseGet
            = new REST_Invsk_RatingModifiers_v2.OutcomingResponseGet();
        outcomeResponseGet.status = 'Test Status';
        outcomeResponseGet.isSuccess = true;
        outcomeResponseGet.errors = new List<String>{'Error1', 'Error2'};
            
            List<Rating_Modifiers__c> ratings =[SELECT Id,Azure_Id__c,Name,Rating_Modifier_Code__c,Opportunity__c,Product__c
                                                from Rating_Modifiers__c where Rating_Modifier_Code__c = 'abcd'];
        outcomeResponseGet.RatingModifiers = ratings;  
        
        Test.stopTest();
        System.assert(outcomeResponseGet != null);
    }
}