/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 09-03-2021
 * @last modified by  : Vinayesh
**/
global class PreRatingServiceHandlerBatch implements Database.Batchable<object>, Database.AllowsCallouts, Database.Stateful {
    global InComingRequest ratingsData {get;set;}
    global RestRequest restReq;
    global RestResponse restResp;
    global Boolean specsSaved = false;
    global Boolean finishedProcess = false;
    global Integer currIndex = 0;

    global Map<Decimal, Product2> productList;
    global Map<Decimal,Rating_Reference_Name__c> ratingsReferencesNames = new Map<Decimal,Rating_Reference_Name__c>();
    global Map<Decimal,Rating_Reference_Info__c> ratingRefInfos = new Map<Decimal,Rating_Reference_Info__c>();
    global Map<Decimal,Rating_Specific_Value__c> ratingsSpecificValues = new Map<Decimal,Rating_Specific_Value__c>();
    global Map<Decimal,Rating_Range_Value__c> ratingsRangeValues = new Map<Decimal,Rating_Range_Value__c>();
    global Map<Decimal,Rating_Matrix_Value__c> ratingsMatrixValues = new Map<Decimal,Rating_Matrix_Value__c>();

    global PreRatingServiceHandlerBatch(RestRequest req, RestResponse resp) {
        this.restReq = req;
        this.restResp = resp;
    }
    
    public Iterable<object> start(Database.BatchableContext BC) {
     List<Object> singleItemList = new List<Object>();
    try{
        

         String jsonUrl = '';
         if(this.restReq != null && this.restReq.requestBody != null){
            String reqJson = this.restReq.requestBody.toString();
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(reqJson);
            if(m.get('blob') != null){
                jsonUrl = m.get('blob').toString();
                System.debug('jsonUrl: ' + jsonUrl);
            }
         }
         if(jsonUrl == null || jsonUrl == '')
            jsonUrl = 'https://irrinndwolverinev2.blob.core.windows.net/rating-factors/Celerity_PCC/rating_database_factors.json?sp=r&st=2021-08-03T10:49:11Z&se=2021-08-31T18:49:11Z&spr=https&sv=2020-08-04&sr=b&sig=3WrrdUo%2BNh9QauDhYXJ0e70I8NCBWTgN5tNcCKbI9KE%3D';
         // Instantiate a new http object
         Http h = new Http();
         // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
         HttpRequest req = new HttpRequest();
         req.setEndpoint(jsonUrl);
         req.setTimeout(60000);//sets maximum timeout
         req.setMethod('GET');
         // Send the request, and return a response
         //HttpResponse res = h.send(req);
         //Blob body = res.getBodyAsBlob();
         JSONParser parser;
         if(!Test.isRunningTest()) {
               parser = JSON.createParser(h.send(req).getBodyAsBlob().toString());
               parser.nextValue();
               ratingsData = (InComingRequest)parser.readValueAs(InComingRequest.class);
         }
         else {
            ratingsData = (InComingRequest)Json.deserialize(jsonUrl, InComingRequest.class);
         }
               
         //boolean finishParse = false;  
         

         ErrorLogsUtilityHelper.logInfo('PreRatingServiceHandlerBatch.start', 'Factors Data Insert Batch Started', BC.getJobId(), 'Batch Job', 'Upsert', 'Start method of batch job');
         
         //System.debug(ratingsData.rating_specific_values.size());
         System.debug(Limits.getHeapSize());
   
         Integer numBatches = (ratingsData.rating_specific_values.size()/1000) + 5; 
        //Creating a list to execute batch numBatches times. Might need to increase number later.
         
         for(Integer i = 0; i<numBatches ; i++){
             object a = (object)i;
             singleItemList.add(a);
         }
         return singleItemList;
      } 
      catch(Exception ex){
        System.debug('@@@prerating Batch Start Error'+ex.getMessage());
        ErrorLogsUtilityHelper.logError(ex, 'PreRatingServiceHandlerBatch.start', CommonUtil.getExceptionMessage(ex), BC.getJobId(), 'Batch Job', 'Upsert', 'Parsing Json Method');
      }

      return null;
    }
    
    public void execute(Database.BatchableContext info, List<Object> singleItemList) {
        System.debug('Batch start entry: ' + this.currIndex);
        if(this.finishedProcess) return;
        String batchId = info.getJobId();
        RestRequest req = this.restReq;
        //InComingRequest request = this.ratingsData;
        OutGoingResponse outResponse = new OutGoingResponse();
        //Integer currIndex = (Integer)singleItemList[0];
        try{  
        if(this.currIndex == 0){
        productList = getProductsAndPreRatingIds(this.ratingsData.products);
        
        if(productList.isEmpty()){
            outResponse.status = 'Failed';
            outResponse.errors.add('Product ID does not exist in Salesforce');
            // RestContext.response.statusCode = 200;
            // RestContext.response.addHeader('Content-Type', 'application/json');
            // RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
            // RestResponse res = RestContext.response;
            // ApiUtil.logAPICallIn(null, res, 'Invsk_PreRating', 'Invsk_PreRating.doPost');
            System.debug('@@@Product ID does not exist in Salesforce');
            return;
        }else{
           // update productList.values();
        }
        ratingsReferencesNames = new Map<Decimal,Rating_Reference_Name__c>();
        for(Rating_Reference_Name ratingsReferencesName: this.ratingsData.rating_reference_name){
            Rating_Reference_Name__c ratingRefName = new Rating_Reference_Name__c();    
            ratingRefName.Rating_Reference_Name_Id__c = ratingsReferencesName.id;
            //if(ratingsReferencesName.id == '1772') ratingRefName.Rating_Reference_Name_Id__c = '1799';
            ratingRefName.Product_Id__c = productList.get(ratingsReferencesName.product_id).Id;
            ratingRefName.Reference_Name__c = ratingsReferencesName.reference_name;
            ratingRefName.BatchId__c = batchId;
            ratingsReferencesNames.put(decimal.valueof(ratingRefName.Rating_Reference_Name_Id__c),ratingRefName); 
        }
        
        if(!ratingsReferencesNames.isEmpty()){
            Schema.SObjectField field = Rating_Reference_Name__c.Fields.Rating_Reference_Name_Id__c;
            Database.UpsertResult [] cr = Database.upsert(ratingsReferencesNames.values(), field, true);
            
            if(!cr.isEmpty()){
                outResponse.status = 'Success';
                // RestContext.response.statusCode = 200;
                // RestContext.response.addHeader('Content-Type', 'application/json');
                // RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                // RestResponse res = RestContext.response;
                System.debug('@@@Success');
                ErrorLogsUtilityHelper.logInfo('PreRatingServiceHandlerBatch.execute', 'Rating reference names data upserted.', info.getJobId(), 'Batch Job', 'Upsert', '1 of 5 objects data upserted.');
            }
        }
        
        
        ratingRefInfos = new Map<Decimal,Rating_Reference_Info__c>();
        if(this.ratingsData.rating_reference_info != null)
            for(Rating_Reference_Info ratingsReferencesInfo: this.ratingsData.rating_reference_info){
                Rating_Reference_Info__c ratingRefInfo = new Rating_Reference_Info__c ();
                ratingRefInfo.Rating_Reference_Info_Id__c = ratingsReferencesInfo.id;
                ratingRefInfo.Reference_Name_Id__c=ratingsReferencesNames.get(ratingsReferencesInfo.reference_name_id) !=null?ratingsReferencesNames.get(ratingsReferencesInfo.reference_name_id).Id: null;
                ratingRefInfo.Reference_Type__c=ratingsReferencesInfo.reference_type;
                ratingRefInfo.Default_Value__c=ratingsReferencesInfo.default_value;
                ratingRefInfo.Option_List__c=ratingsReferencesInfo.option_list;
                ratingRefInfo.Effective_Date__c =ratingsReferencesInfo.effective_date;
                ratingRefInfo.Expiration_Date__c =ratingsReferencesInfo.expiration_date;
                ratingRefInfo.BatchId__c = batchId;
                ratingRefInfos.put(decimal.valueOf(ratingRefInfo.Rating_Reference_Info_Id__c),ratingRefInfo);
            }
            System.debug('@@@reqReferenceInfos.size'+this.ratingsData.rating_reference_info.size());
        if(!ratingRefInfos.isEmpty()){
            Schema.SObjectField field2 = Rating_Reference_Info__c.Fields.Rating_Reference_Info_Id__c;
            Database.UpsertResult [] cr2 = Database.upsert(ratingRefInfos.values(), field2, true);
            
            if(!cr2.isEmpty()){
                outResponse.status = 'Success';
                // RestContext.response.statusCode = 200;
                // RestContext.response.addHeader('Content-Type', 'application/json');
                // RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                // RestResponse res = RestContext.response;
                System.debug('@@@Success');
                ErrorLogsUtilityHelper.logInfo('PreRatingServiceHandlerBatch.execute', 'Rating reference Info data upserted.', info.getJobId(), 'Batch Job', 'Upsert', '2 of 5 objects data upserted.');
            }
        }
        
        
        ratingsSpecificValues = new Map<Decimal,Rating_Specific_Value__c>();
        if(this.ratingsData.rating_specific_values != null){
            Integer count = this.ratingsData.rating_specific_values.size();
            for(Integer j = 0; j<count ; j++){
                Rating_Specific_Value reqSpecificValue = this.ratingsData.rating_specific_values[j];
                Rating_Specific_Value__c ratingSpecificValue = new Rating_Specific_Value__c();
                ratingSpecificValue.Rating_Specific_Value_Id__c =reqSpecificValue.id;
                ratingSpecificValue.Reference_Name_Id__c = ratingsReferencesNames.get(reqSpecificValue.reference_name_id) !=null?ratingsReferencesNames.get(reqSpecificValue.reference_name_id).Id: null;
                ratingSpecificValue.Specific_Value__c =reqSpecificValue.specific_value;
                ratingSpecificValue.Factor__c =reqSpecificValue.factor;
                ratingSpecificValue.UW_Value__c =reqSpecificValue.uw_value;
                ratingSpecificValue.Effective_Date__c =reqSpecificValue.effective_date;
                ratingSpecificValue.Expiration_Date__c =reqSpecificValue.expiration_date;
                ratingSpecificValue.UW_Code__c =reqSpecificValue.uw_code;
                ratingSpecificValue.Minimum_Premium__c =String.isNotBlank(reqSpecificValue.minimum_premium) ?Decimal.valueOf(reqSpecificValue.minimum_premium):null;
                ratingSpecificValue.Sort_Order__c=String.isNotBlank(reqSpecificValue.sort_order) ?Decimal.valueOf(reqSpecificValue.sort_order):null;
                ratingSpecificValue.BatchId__c = batchId;
                ratingsSpecificValues.put(ratingSpecificValue.Rating_Specific_Value_Id__c,ratingSpecificValue);
                this.ratingsData.rating_specific_values[j] = null;
            }
        }
            System.debug('@@@reqSpecificValues.size'+this.ratingsData.rating_specific_values.size());
            System.debug(Limits.getHeapSize());
        }
        /**
         * Insert specific values 1000 at a time.
         */
        if((currIndex > 0 && !this.specsSaved) || Test.isRunningTest()){
            List<Rating_Specific_Value__c> specValueList = ratingsSpecificValues.values();
            List<Rating_Specific_Value__c> specValuesToUpsert = new List<Rating_Specific_Value__c>();
            if(Test.isRunningTest()) currIndex = 1;
            Integer currListIndex = currIndex*1000 - 1000;
            Integer currListIndexEnd = currIndex*1000;
            if(currListIndexEnd >= specValueList.size()){
                currListIndexEnd = specValueList.size();
                this.specsSaved = true;
            }
            // if(currListIndexEnd >= 8000){
            //     currListIndexEnd = 8000;
            //     this.specsSaved = true;
            // }
            for(integer k = currListIndex; k < currListIndexEnd; k++){
                Rating_Specific_Value__c rSpecVal = specValueList[k];
                if(rSpecVal != null && rSpecVal.Specific_Value__c != null){
                    String optVal = rSpecVal.Specific_Value__c;
                    List<String> parts = optVal.split(';');
                    if(parts.size() > 1){
                        rSpecVal.State__c = parts[parts.size()-1];
                    }
                }         
                specValuesToUpsert.add(rSpecVal);
            }
            Schema.SObjectField ratingSpecificValueId = Rating_Specific_Value__c.Fields.Rating_Specific_Value_Id__c; 
            Database.upsert(specValuesToUpsert, ratingSpecificValueId, true);
            if(this.specsSaved){
                ErrorLogsUtilityHelper.logInfo('PreRatingServiceHandlerBatch.execute', 'Rating specific values data upserted.', info.getJobId(), 'Batch Job', 'Upsert', '3 of 5 objects data upserted.');
            }
        }

        if(this.specsSaved || Test.isRunningTest()){
        Map<Decimal,Rating_Range_Value__c> ratingsRangeValues = new Map<Decimal,Rating_Range_Value__c>();
        if(this.ratingsData.rating_range_values != null)
            for(Rating_Range_Value ratingsRangeValue: this.ratingsData.rating_range_values){
                Rating_Range_Value__c ratingRangeValue = new Rating_Range_Value__c();
                ratingRangeValue.Rating_Range_Value__c= ratingsRangeValue.id;
                ratingRangeValue.Reference_Name_Id__c = ratingsReferencesNames.get(ratingsRangeValue.reference_name_id) !=null?ratingsReferencesNames.get(ratingsRangeValue.reference_name_id).Id: null;
                ratingRangeValue.Lower_Value__c = ratingsRangeValue.lower_value;
                ratingRangeValue.Upper_Value__c =ratingsRangeValue.upper_value;
                ratingRangeValue.Factor__c = ratingsRangeValue.factor;
                ratingRangeValue.UW_Value__c = ratingsRangeValue.uw_value;
                ratingRangeValue.Effective_Date__c= ratingsRangeValue.effective_date;
                ratingRangeValue.Expiration_Date__c =ratingsRangeValue.expiration_date;
                ratingRangeValue.UW_Code__c = ratingsRangeValue.uw_code;
                ratingRangeValue.Minimum_Premium__c =String.isNotBlank(ratingsRangeValue.minimum_premium)?Decimal.valueOf(ratingsRangeValue.minimum_premium):null;
                ratingRangeValue.SortOrder__c = String.isNotBlank(ratingsRangeValue.sort_order)?Decimal.valueOf(ratingsRangeValue.sort_order):null;
                ratingRangeValue.BatchId__c = batchId;
                ratingsRangeValues.put(ratingRangeValue.Rating_Range_Value__c,ratingRangeValue);
                
            }
            System.debug('@@@reqRangeValues.size'+this.ratingsData.rating_range_values.size());
        if(!ratingsRangeValues.isEmpty()){
            Schema.SObjectField field4 = Rating_Range_Value__c.Fields.Rating_Range_Value__c;
            Database.UpsertResult [] cr4 = Database.upsert(ratingsRangeValues.values(), field4, true);
            
            if(!cr4.isEmpty()){
                outResponse.status = 'Success';
                // RestContext.response.statusCode = 200;
                // RestContext.response.addHeader('Content-Type', 'application/json');
                // RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                // RestResponse res = RestContext.response;
                System.debug('@@@Success');
                ErrorLogsUtilityHelper.logInfo('PreRatingServiceHandlerBatch.execute', 'Rating range values data upserted.', info.getJobId(), 'Batch Job', 'Upsert', '4 of 5 objects data upserted.');
            }
        }
        
        //Map<Decimal, Id> ratingSpecificValueIds = getRatingSpecificValueIds();
        Map<Decimal, Id> ratingSpecificValueIds = new Map<Decimal, Id>();
        for(Rating_Specific_Value__c specificValue: ratingsSpecificValues.values()){
            ratingSpecificValueIds.put(specificValue.Rating_Specific_Value_Id__c, specificValue.Id);
        }
        Map<Decimal,Rating_Matrix_Value__c> ratingsMatrixValues = new Map<Decimal,Rating_Matrix_Value__c>();
        if(this.ratingsData.rating_matrix_values != null)
            for(Rating_Matrix_Value ratingsMatrixValue: this.ratingsData.rating_matrix_values){
                Rating_Matrix_Value__c ratingMatrixValue = new Rating_Matrix_Value__c();
                ratingMatrixValue.Rating_Matrix_Value_Id__c= ratingsMatrixValue.id;
                ratingMatrixValue.Reference_Name_Id__c = ratingsReferencesNames.get(ratingsMatrixValue.reference_name_id) !=null?ratingsReferencesNames.get(ratingsMatrixValue.reference_name_id).Id: null;
                ratingMatrixValue.Rating_Range_Id__c = ratingsRangeValues.get(ratingsMatrixValue.rating_range_id)!= null ? ratingsRangeValues.get(ratingsMatrixValue.rating_range_id).Id : null;
                ratingMatrixValue.Rating_Specific_Id__c = ratingSpecificValueIds.get(ratingsMatrixValue.rating_specific_id) != null ? ratingSpecificValueIds.get(ratingsMatrixValue.rating_specific_id) : null;
                ratingMatrixValue.Factor__c = ratingsMatrixValue.factor;
                ratingMatrixValue.UW_Value__c = ratingsMatrixValue.uw_value;
                ratingMatrixValue.UW_Code__c = ratingsMatrixValue.uw_code;
                ratingMatrixValue.Effective_Date__c= ratingsMatrixValue.effective_date;
                ratingMatrixValue.Expiration_Date__c = ratingsMatrixValue.expiration_date;
                ratingMatrixValue.Minimum_Premium__c = String.isNotBlank(ratingsMatrixValue.minimum_premium)? Decimal.valueOf(ratingsMatrixValue.minimum_premium): null;
                ratingMatrixValue.Rating_Specific_Id2__c = ratingsRangeValues.get(ratingsMatrixValue.rating_specific_id2)!= null ? ratingsRangeValues.get(ratingsMatrixValue.rating_specific_id2).Id : null;
                ratingMatrixValue.Rating_Range_Id2__c = ratingsRangeValues.get(ratingsMatrixValue.rating_range_id2)!= null ? ratingsRangeValues.get(ratingsMatrixValue.rating_range_id2).Id : null;
                ratingMatrixValue.BatchId__c = batchId;
                ratingsMatrixValues.put(ratingMatrixValue.Rating_Matrix_Value_Id__c,ratingMatrixValue);
                
            }
            System.debug('@@@reqMatrixValues.size'+this.ratingsData.rating_matrix_values.size());
        if(!ratingsMatrixValues.isEmpty()){
            Schema.SObjectField field5 = Rating_Matrix_Value__c.Fields.Rating_Matrix_Value_Id__c;
            Database.UpsertResult [] cr5 = Database.upsert(ratingsMatrixValues.values(), field5, true);
            
            if(!cr5.isEmpty()){
                outResponse.status = 'Success';
                // RestContext.response.statusCode = 200;
                // RestContext.response.addHeader('Content-Type', 'application/json');
                // RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                // RestResponse res = RestContext.response;
                System.debug('@@@Success');
                ErrorLogsUtilityHelper.logInfo('PreRatingServiceHandlerBatch.execute', 'Rating matrix values data upserted.', info.getJobId(), 'Batch Job', 'Upsert', '5 of 5 objects data upserted.');
            }
        }
        this.finishedProcess = true;
    }

    this.currIndex ++;
    
        }catch(Exception ex){
            this.currIndex ++;
            System.debug('@@@Exception'+ex.getMessage());
            System.debug('@@@Exception'+ex.getLineNumber());
            System.debug('@@@Exception'+ex.getCause());
        }

        
    }

    public static Map<Decimal, Product2> getProductsAndPreRatingIds(List<ProductWrapper> reqProducts){
        
        Map<String, ProductWrapper> productsAzureIds = new Map<String, ProductWrapper>();
        for(ProductWrapper reqProduct: reqProducts){
            productsAzureIds.put(reqProduct.guid, reqProduct);
        }
        Map<Decimal, Product2> productsToUpdate = new Map<Decimal, Product2>();
        for(Product2 product: [Select Id, Azure_ID__c  from Product2 where Azure_ID__c IN :productsAzureIds.keySet()]){
            ProductWrapper productFromRequest = productsAzureIds.get(product.Azure_ID__c.toUpperCase());
            if(productFromRequest != null){
                product.Pre_Rating_Id__c = Integer.valueOf(productFromRequest.id);
                product.Pre_Rating_Value__c  = productFromRequest.value;
                product.Pre_Rating_Description__c  = productFromRequest.description;
                productsToUpdate.put(product.Pre_Rating_Id__c, product);
            }
           
        }
        return productsToUpdate;
    }

    public static Map<Decimal, Id> getRatingSpecificValueIds(){
        
        Map<Decimal, Id> specificValueIds = new Map<Decimal, Id>();
        for(Rating_Specific_Value__c specificValue: [Select Id,Rating_Specific_Value_Id__c from Rating_Specific_Value__c]){
            specificValueIds.put(specificValue.Rating_Specific_Value_Id__c, specificValue.Id);
        }
        return specificValueIds;
    }

    public class InComingRequest {
        public List<ProductWrapper> products					   {get; set;}
        public List<Rating_Reference_Name> rating_reference_name   {get; set;}
        public List<Rating_Reference_Info> rating_reference_info   {get; set;}
        public List<Rating_Specific_Value> rating_specific_values  {get; set;}
        public List<Rating_Terrorism_Value> rating_terrorism_values{get; set;}
        public List<Rating_Range_Value> rating_range_values        {get; set;}
        public List<Rating_Matrix_Value> rating_matrix_values      {get; set;}
    }
    Public class ProductWrapper{
        public decimal id;
        public string value;
        public string description;
        public string guid;
        
    }
    public class Rating_Reference_Name{
        public string id;                  
        public decimal product_id;          
        public string reference_name;      
        
    }
    public class Rating_Reference_Info{
        public string id; 
        public decimal reference_name_id;
        public string reference_type;          
        public string default_value;
        public string option_list;
        public date effective_date;
        public date expiration_date;
        
    }
    public class Rating_Specific_Value{
        public decimal id;
        public decimal reference_name_id;
        public string specific_value;
        public string factor;
        public string uw_value;
        public date effective_date;
        public date expiration_date;
        public string uw_code;
        public string minimum_premium;
        public string sort_order;
        
    }
    public class Rating_Terrorism_Value{
        
    }
    public class Rating_Range_Value {
        public decimal id;
        public decimal reference_name_id;
        public decimal lower_value;
        public decimal upper_value;
        public string factor;
        public string uw_value;
        public date effective_date;
        public date expiration_date;
        public string uw_code;
        public string minimum_premium;
        public string sort_order;
    }
    public class Rating_Matrix_Value {
        public decimal id;
        public decimal reference_name_id;
        public decimal rating_range_id;
        public decimal rating_specific_id;
        public string factor;
        public string uw_value;
        public string uw_code;
        public date effective_date;
        public date expiration_date;
        public string minimum_premium;
        public integer rating_specific_id2;
        public integer rating_range_id2;
    }
    
    public class OutGoingResponse {        
        public String status                       		 		{get; set;}
        public String batchJobId                       		 	{get; set;}
        public List<String> errors                  			{get; set;}
        public OutGoingResponse() {
            this.status = null;
            this.batchJobId = null;
            this.errors = new List<String>();
        }
    }
    
    public void finish(Database.BatchableContext info) {
        OutGoingResponse outResponse = new OutGoingResponse();
        outResponse.status = 'Success';
        outResponse.batchJobId = info.getJobId();
        this.restResp.statusCode = 200;
        this.restResp.addHeader('Content-Type', 'application/json');
        this.restResp.responseBody = Blob.valueOf(JSON.serialize(outResponse));
        RestResponse res = RestContext.response;
        ApiUtil.logAPICallIn(this.restReq, this.restResp, 'REST_Invsk_FactorsSync', 'REST_Invsk_FactorsSync.doPost');
        ErrorLogsUtilityHelper.logInfo('PreRatingServiceHandlerBatch.finish', 'Factors Data Insert Batch Completed', info.getJobId(), 'Batch Job', 'Upsert', 'Finish method of batch job');
}    
    
}