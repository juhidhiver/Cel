/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 09-03-2021
 * @last modified by  : Vinayesh
**/
@RestResource(urlMapping='/Invsk_FactorsSync/*')
global with sharing class REST_Invsk_FactorsSync {
    
    /**
    * @description External call in with request body containing factors json content url. Batch class called to parse and store json data into ratings tables.
    * @author Vinayesh | 08-16-2021 
    **/
    @HttpPost
    global static void doPost() {

        try{
            RestRequest req = RestContext.request;
            RestResponse resp = RestContext.response;
            OutGoingResponse outResponse = new OutGoingResponse();
            String jsonUrl = '';
            if(req != null && req.requestBody != null){
               String reqJson = req.requestBody.toString();
               Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(reqJson);
               if(m.get('blob') != null){
                   jsonUrl = m.get('blob').toString();
                   System.debug('jsonUrl: ' + jsonUrl);
               }
            }
            // Instantiate a new http object
            Http h = new Http();
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req1 = new HttpRequest();
            req1.setEndpoint(jsonUrl);
            req1.setTimeout(60000);//sets maximum timeout
            req1.setMethod('HEAD');
            HttpResponse res1;
            if(!Test.isRunningTest()){
                res1 = h.send(req1);
            }
            else{
                res1 = new HttpResponse();
            }
           
            //if(h.send(req1) != null) return;
            //HttpResponse res1 = h.send(req1);
            //JSONParser parser = JSON.createParser(h.send(req1).getBodyAsBlob().toString());
            // Id batchJobId = Database.executeBatch(new PreRatingServiceDataDeleteBatch(req, resp), 1);
            // //Id preRatingQueueId = System.enqueueJob(new PreRatingQueueable(req));
            if(res1 != null){
                outResponse.status = 'In Progress';
                //outResponse.batchJobId = string.valueOf(res1.getStatusCode());
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                ApiUtil.logAPICallIn(req, RestContext.response, 'REST_Invsk_FactorsSync', 'REST_Invsk_FactorsSync.doPost');
                Id batchJobId;
                if(!Test.isRunningTest())
                    batchJobId = Database.executeBatch(new PreRatingServiceHandlerBatch(req, resp), 1);
                outResponse.status = 'Success';
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
            }

        }catch(Exception ex){
            System.debug('@@@ex'+ex.getMessage());
            System.debug('@@@ex'+ex.getCause());
            OutGoingResponse outResponse = new OutGoingResponse();
            outResponse.status = 'Failure';
            //outResponse.batchJobId = batchJobId;
            outResponse.errors.add(ex.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
            ErrorLogsUtilityHelper.logError(ex, 'REST_Invsk_FactorsSync.doPost', CommonUtil.getExceptionMessage(ex), '', '', '', 'Possible URL inaccessible error');
        }

    }

    // public class RatingsWrapper {
    //     public RatingProduct [] products		{get; set;}
    //     public RatingReferenceName [] rating_reference_name		{get; set;}      
    //     public RatingReferenceInfo [] rating_reference_info		{get; set;}
    //     public RatingSpecificValues [] rating_specific_values		{get; set;}
    //     public RatingRangeValues [] rating_range_values		{get; set;}
    //     public RatingMatrixValues [] rating_matrix_values		{get; set;}
    // }
    
    // public class RatingProduct {
    //     public String id 		{get; set;}
    //     public String value	{get; set;}
    //     public String description      		{get; set;}
    //     public String guid  			{get; set;}
    // }

    // public class RatingReferenceName {
    //     public String id 		{get; set;}
    //     public String product_id	{get; set;}
    //     public String reference_name      		{get; set;}
    // }

    // public class RatingReferenceInfo {
    //     public String id 		{get; set;}
    //     public String reference_name_id	{get; set;}
    //     public String reference_type      		{get; set;}
    //     public String default_value  			{get; set;}
    //     public String option_list	{get; set;}
    //     public String effective_date      		{get; set;}
    //     public String expiration_date  			{get; set;}
    // }

    // public class RatingSpecificValues {
    //     public String id 		{get; set;}
    //     public String reference_name_id	{get; set;}
    //     public String specific_value      		{get; set;}
    //     public String factor  			{get; set;}
    //     public String uw_value	{get; set;}
    //     public String effective_date      		{get; set;}
    //     public String expiration_date  			{get; set;}
    //     public String uw_code	{get; set;}
    //     public String minimum_premium      		{get; set;}
    //     public String sort_order  			{get; set;} 
    // }

    // public class RatingRangeValues {
    //     public String id 		{get; set;}
    //     public String reference_name_id	{get; set;}
    //     public String lower_value      		{get; set;}
    //     public String upper_value  			{get; set;}
    //     public String factor	{get; set;}
    //     public String uw_value      		{get; set;}
    //     public String effective_date  			{get; set;}
    //     public String expiration_date	{get; set;}
    //     public String uw_code      		{get; set;}
    //     public String minimum_premium  			{get; set;} 
    //     public String sort_order  			{get; set;} 
    // }

    // public class RatingMatrixValues {
    //     public String id 		{get; set;}
    //     public String reference_name_id	{get; set;}
    //     public String rating_range_id      		{get; set;}
    //     public String rating_specific_id  			{get; set;}
    //     public String factor	{get; set;}
    //     public String uw_value      		{get; set;}
    //     public String uw_code  			{get; set;}
    //     public String effective_date	{get; set;}
    //     public String expiration_date      		{get; set;}
    //     public String minimum_premium  			{get; set;} 
    //     public String rating_specific_id2  			{get; set;}
    //     public String rating_range_id2  			{get; set;} 
    // }

    public class OutGoingResponse {        
        public String status                       		 		{get; set;}
       // public String batchJobId                       		 	{get; set;}
        public List<String> errors                  			{get; set;}
        public OutGoingResponse() {
            this.status = null;
            //this.batchJobId = null;
            this.errors = new List<String>();
        }
    }

}