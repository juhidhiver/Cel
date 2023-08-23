/*************************************************
* Class Name: ApiUtil 
* Author: Binh Dang
* Date: 
* Requirement/Project Name: Innovisk
* Requirement/Project Description: 
*************************************************/
public with sharing class ApiUtil {
    public static decimal postalcodeAccumTIV = 0;
    /*************************************************
* Method Name: logAPICall
* Author:
* Description: create new logAPICall
* Params: HttpRequest req, HttpResponse res, String APIName, String functionName, String headerRequest, String callType
* Return:
* Exceptions:
* Revision: 
*************************************************/ 
    public static void logAPICall(HttpRequest req, HttpResponse res, String APIName, 
                                  String functionName, String headerRequest, String callType) 
    {
        if(checkExportLogAPICall(APIName)){
            API_Log__c apiLog =  createLogAPICall(req, res, APIName, functionName, headerRequest, callType);
            try{
                if(APIName == 'Bind Quote V2 Callout' || APIName == 'Finalize Quote Document V2 Callout'
                    || APIName == 'Sync Quote Status' || APIName == 'RatingAPI Callout'){
                        system.debug('req---->>>>>'+req.getBody());

                        /*************** Adding Quote Id in API log ************/
                        Map<String,Object> mapOfReq =  (Map<String, Object>) JSON.deserializeUntyped(req.getBody());

                        Map<String,Object>  mapOfQuote = mapOfReq.containsKey('quote') ?  (Map<String, Object>) mapOfReq.get('quote') : null;

                        if(mapOfQuote != null){
                        String quoteId =  mapOfQuote.containskey('Id') ?  (String)mapOfQuote.get('Id') : '';
                        apiLog.Quote_Id__c = quoteId;
                        }

                        if(apiLog.Status_Code__c == 200){
                        Map<String,Object> mapOfRes =  (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                        if(APIName == 'Bind Quote V2 Callout' || APIName == 'Finalize Quote Document V2 Callout'){
                        Map<String,Object>  mapOfData = mapOfRes.containsKey('data') ?  (Map<String, Object>) mapOfRes.get('data') : null;
                            String azureId =   mapOfData != null ? (String)mapOfData.get('quoteId') : null;
                        
                            if(mapOfData != null){
                                apiLog.Azure_Id__c = azureId;
                        }
                        }
                        else if(APIName == 'Sync Quote Status'){
                            List<Object>  listOfQuotes = mapOfRes.containsKey('Quotes') ?  (List<Object>) mapOfRes.get('Quotes') : null;
                            Map<String,Object> quoteObj  =    (Map<String, Object>) listOfQuotes[0];
                            String azureId = quoteObj != null ? (String)quoteObj.get('Id') : '';

                            if(String.isNotBlank('azureId')){
                                apiLog.Azure_Id__c = azureId;
                        }
                        }
                        else if(APIName == 'RatingAPI Callout'){
                            Map<String,Object>  mapOfData = mapOfRes.containsKey('quote') ?  (Map<String, Object>) mapOfRes.get('quote') : null;
                            String azureId   =  mapOfData.containskey('Azure_ID__c') ? (string) mapOfData.get('Azure_ID__c') : '';
                        
                            if(String.isNotBlank('azureId')){
                                apiLog.Azure_Id__c = azureId;
                        }
                        }
                    }

                        if(mapOfQuote != null){
                        String quoteId =  mapOfQuote.containskey('Id') ?  (String)mapOfQuote.get('Id') : '';
                        apiLog.Quote_Id__c = quoteId;
                        }
                }

                insert apiLog;
                System.debug('APILOg' +apiLog.Id );
            }
            catch(Exception ex){
                System.debug('Exception occurred while inserting API Log --> '+ex.getMessage());
            }
        }
    }
    
    /*************************************************
* Method Name: logAPICallIn
* Author:
* Description: create new logAPI Call In
* Params: RestRequest req, RestResponse res, String APIName, String functionName
* Return:
* Exceptions:
* Revision: 
*************************************************/
    public static void logAPICallIn(RestRequest req, RestResponse res, String APIName, String functionName) {       
        if(!checkExportLogAPICall(APIName)) return;
        
        API_Log__c log = new API_Log__c();
        log.Name = APIName;
        log.Function_Name__c = functionName;
        log.Endpoint__c = req.requestURI;
        log.Request_Body__c = getRequestBody(req);
        log.Request_Header__c = String.valueOf(req.headers);
        log.Request_Method__c = req.httpMethod;
        log.Response_Body__c = getResponseBody(res);
        log.Status_Code__c = res.statusCode;
        log.Call_Type__c = 'Inbound';
        //return log;
        
        
        /*
API_Log__c log = new API_Log__c();
log.Name = APIName;
log.Function_Name__c = functionName;
log.Endpoint__c = req.requestURI;
log.Request_Header__c = String.valueOf(req.headers);
log.Request_Method__c = req.httpMethod;
log.Status_Code__c = res.statusCode;
log.Call_Type__c = 'Inbound';

String objType = '';
// Request Body
String valueReq = '';
if(req.requestBody != null) {
//if(getTypeObject(req.requestBody) == 'Blob')  valueReq = req.requestBody.toString().left(131060) + '...';
//else valueReq = String.valueOf(req.requestBody).left(131060) + '...';
//valueReq = getTypeObject(req.requestBody) == 'Blob' ?  req.requestBody.toString().left(131060) + '...' : String.valueOf(req.requestBody).left(131060) + '...' ;
// 2019-07-19 Hung: Fix empty response
objType = getTypeObject(req.requestBody);
valueReq = String.valueOf(req.requestBody);
if (objType == 'Blob' || 
objType == 'String') {
valueReq = String.isNotEmpty(valueReq) ? valueReq.left(131060) : '';
} else {
valueReq = '';
}
}
log.Request_Body__c = valueReq;

// Response Body
String valueRes = null;
if(res.responseBody != null) {

valueRes = String.valueOf(res.responseBody);
if (objType == 'Blob' || objType == 'String') {
valueRes = String.isNotEmpty(valueRes) ? valueRes.left(131060)  : '';
} else valueRes = '';

}
log.Response_Body__c = valueRes;
*/
        
        insert log;
    }
    
    /*************************************************
* Method Name: createLogAPICall
* Author:
* Description: create new logAPI Object
* Params: HttpRequest req, HttpResponse res, String APIName, String functionName, String headerRequest, String callType
* Return:
* Exceptions:
* Revision: 
*************************************************/
    public static API_Log__c createLogAPICall(HttpRequest req, HttpResponse res, String APIName, 
                                              String functionName, String headerRequest, String callType) {
                                                API_Log__c log = new API_Log__c();
                                                log.Name = APIName;
                                                if(!Test.isRunningTest() && APIName == 'Sync Quote Status' && res!=NULL){
                                                    /* Map<String,Object> mapOfRes =  (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                                                    List<Object>  listOfQuotes = mapOfRes.containsKey('Quotes') ?  (List<Object>) mapOfRes.get('Quotes') : null;
                                                    Map<String,Object> quoteObj  =    (Map<String, Object>) listOfQuotes[0];
                                                    String azureId = quoteObj != null ? (String)quoteObj.get('Id') : '';
                                
                                                    if(String.isNotBlank('azureId')){
                                                        log.Azure_Id__c = azureId;
                                                    }
                                                   */
                                                }
                                                log.Function_Name__c = functionName;
                                                log.Endpoint__c = req.getEndpoint();
                                                log.Request_Body__c = getRequestBody(req);
                                                log.Request_Header__c = headerRequest;
                                                log.Request_Method__c = req.getMethod();
                                                log.Response_Body__c = getResponseBody(res);
                                                log.Status_Code__c = res.getStatusCode();
                                                log.Status__c = res.getStatus();
                                                log.Call_Type__c = callType;
                                                return log;
                                              }
    
    /*************************************************
* Method Name: getRequestBody
* Author:
* Description: covert RequestBody to string
* Params: HttpRequest
* Return: String 
* Exceptions:
* Revision: 
*************************************************/
    private static String getRequestBody(HttpRequest req) {
        String returnVal = null;
        if (req != null) {
            // if object type is Blob then convert to string
            if(String.isNotBlank(req.getBody()) && getTypeObject(req.getBody()) == 'Blob') {
                returnVal = Blob.valueof(req.getBody()).toString().left(131060);
                return returnVal;
            }
            if (String.isNotBlank(req.getBody())) returnVal = req.getBody().left(131060);
        }
        return returnVal;
    }
    
    /*************************************************
* Method Name: getResponseBody
* Author:
* Description: covert getResponseBody to string
* Params: HttpResponse
* Return: String 
* Exceptions:
* Revision: 
*************************************************/
    private static String getResponseBody(HttpResponse res) {
        String returnVal = null;
        if (res != null) {
            // if object type is Blob then convert to string
            if(String.isNotBlank(res.getBody()) && getTypeObject(res.getBody()) == 'Blob') {
                returnVal = Blob.valueof(res.getBody()).toString().left(131060);
                return returnVal;
            }
            
            if (String.isNotBlank(res.getBody())) returnVal = res.getBody().left(131060);
        }
        return returnVal;
    }
    
    private static String getResponseBody(RestResponse res) {
        String returnVal = null;
        if (res != null) {
            // if object type is Blob then convert to string
            if(res.responseBody == null) {
                return returnVal;
            }
            
            returnVal = res.responseBody.toString().left(131060);
        }
        return returnVal;
    }
    
    private static String getRequestBody(RestRequest req) {
        String returnVal = null;
        if (req != null) {
            // if object type is Blob then convert to string
            if(req.requestBody == null) {
                return returnVal;
            }
            
            returnVal = req.requestBody.toString().left(131060);
        }
        return returnVal;
    }
    
    /*************************************************
* Method Name: getTypeObject
* Author:
* Description: checking type of Object
* Params: HttpResponse
* Return: Type of object 'String' or 'Blob' 
* Exceptions:
* Revision: 
*************************************************/
    private static String getTypeObject(Object o) {
        if(o instanceof String) return 'String';
        if(o instanceof Blob)  return 'Blob';
        
        return '';
    }
    
    /*************************************************
* Method Name: checkExportLogAPICall
* Author:Binh Dang
* Date: 16-May-2019 / Check custom meta data 'API Log Configuration' to switch on/off export log on API Log obj..
* Params: String apiName
* Return: Boolean
* Exceptions:
* Revision: 
*************************************************/
    public static Boolean checkExportLogAPICall(String apiName) {
        List<String> apiValueList = new List<String>();
        for (API_Log_Configuration__mdt api_log : [SELECT Label, MasterLabel, DeveloperName 
                                                   FROM API_Log_Configuration__mdt 
                                                   WHERE Is_Active__c = true]) 
            apiValueList.add(api_log.MasterLabel);
        
        return (apiValueList.contains(apiName) || apiValueList.contains('All API')) ? true : false;
    }
    // 2019/05/16 Binh Dang added end
    
    /*************************************************
* Method Name: getRatingJsonString
* Author:Binh Dang
* Date: 16-May-2019 / Covert Rating request to String
* Params: quoteId
* Return: String of coverted request
* Exceptions:
* Revision: 
*************************************************/
    public static String getRatingJsonString(String quoteId) {      
        String result = '';
        try {  
            //QuoteUtil.QuoteWrapper quoteWrapper = QuoteUtil.getRatingWrapper(quoteId);
            
            List<Quote> q = [SELECT Id,OpportunityId FROM Quote WHERE Id = :quoteId LIMIT 1];
            if (q.isEmpty()) return '';
            //Quote qItem = REST_Invsk_Rate.getRateQuote(quoteId);
            //Opportunity opp = REST_Invsk_Rate.getOpportunity(q.OpportunityId);
            RatingRequest req = RatingRequest.getRatingRequest(quoteId, q[0].OpportunityId);
            result = JSON.serialize(req);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new Warnings.RatingException(ex.getMessage());
        }
        return result;
        
    }
    
    /*************************************************
* Method Name: getRatingJson
* Author:
* Date: 19-Oct-2020  / Covert Rating request to String
* Params: quoteId
* Return: JSON string of request FOR rating and reverse sync
* Exceptions:
* Revision: 
*************************************************/
    public static String getRatingJson(String quoteId) {
        String ratingRequest = '';
        try{
            Quote ratedQuote = [SELECT Id,OpportunityId, Opportunity.RecordType.Name, Parent_Quote__c,Quote_Type__c, Policy__c,
                                Master_Binder__c
                                FROM Quote Where Id = :quoteId
                                AND OpportunityId != null AND Opportunity.Product__c != null LIMIT 1];
            String quoteOppRecordType = ratedQuote.Opportunity.RecordType.Name;
            
            if(quoteOppRecordType == 'Aqueous'){
                ratingRequest = getRatingJsonAQ(ratedQuote);
            }else if(quoteOppRecordType == 'Celerity'){
                ratingRequest = getRatingJsonCelerity(ratedQuote);
            }
            
            system.debug('rating req --'+ratingRequest);
        }
        catch(Exception ex){
            System.debug('Exception from Rating request --> '+ex.getMessage());
        }  
        return ratingRequest;
    } 
    
    /*************************************************
* Method Name: getRatingJson
* Author:
* Date: 22-Mar-2021  / Covert Rating request to String for AQ
* Params: quoteId
* Return: JSON string of request FOR rating and reverse sync for AQ
*************************************************/
    public static String getRatingJsonAQ(Quote ratedQuote) {
        String ratingRequest = '';
        Id oppId = ratedQuote.OpportunityId;
        Id parentQuoteId = ratedQuote.Parent_Quote__c;
        ID policyID = ratedQuote.Policy__c;
        String masterBinderId = '';
        if(ratedQuote.Master_Binder__c != null){
            masterBinderId = ratedQuote.Master_Binder__c;
        }
        /*List<Rating_Modifier_Factor__c> aa = [SELECT Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                             Factor_Value__c, Rating_Modifier__r.Rating_Modifier_Value__c,
                             Rating_Modifier__r.Rating_Modifier_Code__c, Rating_Modifier__r.Format__c,
                             Rating_Modifier__r.Name, Rating_Modifier__r.Product__c,Rating_Modifier__r.Factor_Max__c,
                             Rating_Modifier__r.Factor_Min__c,Rating_Modifier__r.Factor_Value__c,
                             Rating_Modifier__r.Azure_ID__c, Rating_Modifier__r.Page_Section__c
                             FROM Rating_Modifier_Factor__c where Quote__c = :ratedQuote];*/
        List<Opportunity> productConfigAttributesList = [SELECT Id,
                                                         Product__r.Azure_ID__c, Product__r.Carrier_Commission__c,
                                                         Product__r.Description, Product__r.DisplayUrl,
                                                         Product__r.Effective_Date__c, Product__r.Expiration_Date__c,
                                                         Product__r.ExternalId, Product__r.Family, 
                                                         Product__r.Innovisk_Entity_ID__c, Product__r.IsActive,
                                                         Product__r.Marketing_Minimum_premium__c, Product__r.Model_ID__c,
                                                         Product__r.Name, Product__r.Offer__c, Product__r.Package_Indicator__c, 
                                                         Product__r.Pay_Plan__c, Product__r.Product_Features__c, 
                                                         Product__r.Product_Image_URL__c, Product__r.ProductCode,
                                                         Product__r.QuantityUnitOfMeasure, Product__r.StockKeepingUnit, 
                                                         Product__r.UMR__c, Product__r.Writing_Company__c
                                                         FROM Opportunity WHERE Id = :oppId];
        String productName = '';
        
        if(productConfigAttributesList.size() > 0)	productName = productConfigAttributesList[0].Product__r.Name;
        
        List<CoveragesLineItem__c> priorQuoteCoverageLineItemsNew = new  List<CoveragesLineItem__c>();
        if(ratedQuote.Quote_Type__c != 'New Business' && String.isNotBlank(ratedQuote.Parent_Quote__c)){
            priorQuoteCoverageLineItemsNew = [SELECT ID, Name, Azure_ID__c, 
                                              Sub_Coverage__r.Id, Sub_Coverage__r.Name,
                                              Sub_Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Code__c,
                                              Coverage__r.Id, Coverage__r.Azure_ID__c, Coverage__r.Name, Coverage_Premium__c,
                                              Factor_Value__c, Coverage__r.Coverage_Product__c,Coverage__r.Form_Number__c,
                                              Coverage__r.Additional_Requirements__c,
                                              Factor_Min__c, Factor_Max__c, Increment_Step__c, 
                                              Factor_Default_Value__c,Limits_Deductibles__c, Limits_Deductibles__r.Azure_ID__c,
                                              Limits_Deductibles__r.Name, Limits_Deductibles__r.Type__c,
                                              Limits_Deductibles__r.RecordTypeId,Limits_Deductibles__r.LmtDedCode__c,
                                              Limits_Deductibles__r.RecordType.DeveloperName,
                                              Limits_Deductibles__r.RecordType.Name, Max_amt__c, Min_amt__c,
                                              Option_Type__c, Option_Value_Default__c,
                                              Option_Picklist__c,Override_Premium__c, Rating__c,
                                              Added_in_current_transaction__c , IsSelected__c 
                                              FROM CoveragesLineItem__c WHERE Quote__c =: parentQuoteId];
        }
        
        List<Opportunity> opportunity = [SELECT Id,Azure_ID__c, Name,Industry__c,Total_Revenues__c,
                                         AnnualRevenue__c, Cash_Flow_From_Operating_Activities__c,
                                         Current_Assets__c, Current_Liabilities__c,Largest_Work_Type__c,Main_Profession__c,
                                         Long_Term_Debt__c, Net_Income__c, Retained_Earnings__c,
                                         Shareholders_Equity__c, Total_Assets__c, Total_Liabilities__c,
                                         Attachment_Point__c, Account.Name,Account.Website, Account.Azure_ID__c,Tax_Country__c,
                                         Account.BillingAddress, Account.Duns_Number__c,CreatedBy.Name,
                                         Account.D_B_Rating_Classification__c,Service_Classification__c, 
                                         Account.Composite_Credit_Appraisal__c,Account.AQ_Sanction_Status__c,
                                         (Select Id,Name,Amount__c,Notional_Income__c,Rating_Factor__c,Sort_Order__c,
                                          Split_Percentage__c,Submission__c,UW_Analysis_Code__c,UW_Analysis_Name__c,
                                          UW_Analysis_Template__c,UW_Analysis_Template__r.Criteria__c,UW_Analysis_Template__r.Rating_Factor__c,
                                          UW_Analysis_Template__r.Sort_Order__c,UW_Analysis_Template__r.Default_Split_Percentage__c,
                                          UW_Analysis_Template__r.UW_Analysis_Code__c,UW_Analysis_Template__r.UW_Analysis_Name__c,
                                          UW_Analysis_Template__r.Name from UW_Analysis__r),
                                         (SELECT Name, Loss_Amount__c, Status__c, Year__c,Number_of_Losses__c 
                                          FROM Submission_Loss_Details__r),
                                         (SELECT Name, Additional_Insured_Account__r.Name FROM Additional_Insured__r)
                                         FROM Opportunity WHERE Id = :oppId]; 
        List<Quote> quoteList = new List<Quote>();
        for(quote quoteObj:[Select Id,Commission_percentage__c,Azure_ID__c, Effective_Date__c, QuoteNumber, ExpirationDate,
                            AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                 
                            Quote_Type__c, Name, Status, Rating_Status__c,Tax,Commission__c, Override_Premium__c, Override_Premium_Percentage__c ,Parent_Quote__c, 
                            Technical_Premium__c,QuotePremium__c,Total_Premium__c,CloseDate__c,Accept_Terror_Premium__c,
                            Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c, Special_Coverages__c,
                            Parent_Quote__r.Non_Prorated_Quote_Premium__c,Parent_Quote__r.QuotePremium__c,Broker__r.Account.Azure_ID__c,BypassRating__c,
                            Broker__r.Azure_ID__c,Broker__r.id,Endorsement_Quote_Bound_Date__c,Broker__r.Name,Broker__r.Account.Name,Prior_Policy__c, Prior_Policy__r.Policy_Number__c,
                            //Aqueous New Fields
                            Endorsement_Reason__c,Endorsement_Reason_Other__c,Change_In_Actual_Premium__c,Change_In_Broker_Netted_Down_Premium__c,
                            Change_In_Fee__c,Change_in_IPT__c,Change_in_Total_Cost_to_Client__c,
                            Override_Actual_Premium_Percent__c, Override_Fee_Percent__c, Override_Actual_Excess_Percent__c, 
                            Technical_Fee__c,OverrideBrokerNettedDownPremiumPercent__c,
                            Actual_Excess__c, Actual_Premium__c, As_if_Book_Rated_Premium_rate_change__c, Binder__c, 
                            Book_Excess__c, Book_Premium__c, Book_Rated_Premium__c, Broker_Commission__c, 
                            Broker_Netted_Down_Premium__c, Discretion__c, Excess_Basis__c, Fee__c, Final_Discretion__c, 
                            IPT_on_Broker_Netted_Down_Premium__c, Jurisdiction_Limits__c, Layer__c, Limit_Basis__c, 
                            MGA_Commission__c, Minimum_Premium__c, Netted_Down_Premium_Broker_Commission__c, 
                            Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c,PI_Limit_of_Indemnity__c, 
                            Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, 
                            Previous_Year_Final_Discretion__c, Previous_Year_Exposure__c, Price_Adequacy__c, 
                            Rate__c, Rateable_Exposure__c, RetroDate__c,Technical_Premium_Discretion__c, 
                            Retroactive_Date__c, Revised_Broker_Commission__c, Revised_MGA_Commission__c, 
                            Territorial_Limits__c, Total_Underlying_Layer__c,Rate_Change__c,Force_Rating__c,
                            Parent_Quote__r.Actual_Premium__c,Parent_Quote__r.Broker_Netted_Down_Premium__c,Parent_Quote__r.Fee__c,
                            Parent_Quote__r.NonProrated_Actual_Premium__c,Parent_Quote__r.NonProRated_BNDP__c,Quote_Action__c,Name_Insured_Update_Effective_Date__c,
                            (Select Id,Insurer__c,Layer__c,Insurer_Policy_Number__c,Insurer_Layer_Limit__c from Insurer_Layer_Limit__r),
                            (SELECT ID, Name, Azure_ID__c, Coverage_Type__c, Sub_Coverage__r.Id, Coverage__r.Azure_ID__c,
                             Sub_Coverage__r.Name,Sub_Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Code__c,
                             Coverage__r.Id, Coverage__r.Name, Coverage_Premium__c,Coverage__r.Coverage_Type__c,Coverage__r.Form_Number__c,
                             Factor_Value__c, Coverage__r.Coverage_Product__c, Coverage__r.Additional_Requirements__c,
                             Factor_Min__c, Factor_Max__c, Increment_Step__c, 
                             Factor_Default_Value__c,Limits_Deductibles__c, Limits_Deductibles__r.Azure_ID__c,
                             Limits_Deductibles__r.Name, Limits_Deductibles__r.Type__c,
                             Limits_Deductibles__r.RecordTypeId,Limits_Deductibles__r.LmtDedCode__c,
                             Limits_Deductibles__r.RecordType.DeveloperName,
                             Limits_Deductibles__r.RecordType.Name, Max_amt__c, Min_amt__c,
                             Option_Type__c,  Option_Value_Default__c,
                             CoverageLineItemType__c, IsSelected__c,
                             Option_Picklist__c,Override_Premium__c, Rating__c  
                             FROM Coverages_Line_Items__r),
                            (SELECT Id, Name, Quote__c, Form_Number__c, Endorsement_Name__c, Endorsement_Wording__c, 
                             Coverage_Effective_Date__c FROM Free_Form_Endorsements__r ORDER BY createdDate),
                            (SELECT Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                             Factor_Value__c, Rating_Modifier__r.Rating_Modifier_Value__c,
                             Rating_Modifier__r.Rating_Modifier_Code__c, Rating_Modifier__r.Format__c,
                             Rating_Modifier__r.Name, Rating_Modifier__r.Product__c,Rating_Modifier__r.Factor_Max__c,
                             Rating_Modifier__r.Factor_Min__c,Rating_Modifier__r.Factor_Value__c,
                             Rating_Modifier__r.Azure_ID__c, Rating_Modifier__r.Page_Section__c
                             FROM Rating_Modifier_Factors__r),
                            (SELECT Id, Name, Subjectivity__c, Subjectivity_Status__c, Subjectivity_Type__c, Stage__c, Due_Date__c,
                             Cleared__c,Cleared_Date__c,RecordTypeId,RecordType.Name,Subjectivity_Text__c,Subjectivity_Template__c,                           
                             Subjectivity_Template__r.Name,Subjectivity_Template__r.Cleared__c,Subjectivity_Template__r.Cleared_Date__c,
                             Subjectivity_Template__r.Profession_Criteria__c,Subjectivity_Template__r.Proposal_Form_Date__c,
                             Subjectivity_Template__r.Subjectivity_Name__c,Subjectivity_Template__r.Subjectivity_Text__c 
                             FROM Subjectivity__r),
                            (SELECT Id, Name, Additional_Interest_Account__c, Quote__c, Azure_ID__c, Relationship_Type__c, 
                             Parent_Additional_Interest__c, Loan_Reference_number__c,Loss_Payee_Interest__c,Primary_Mortgage_Servicer__c, 
                             Entity_Type__c
                             FROM Additional_Interests__r),
                            (SELECT Id, AccountId__c,Azure_ID__c,OpportunityId__c, OriginCreation__c, 
                             Primary_Location__c,Name,Usage_Type__c,State_Review_Required__c,
                             Quote_Location__c.Locations__r.State_Province__c,
                             Quote_Location__c.Locations__r.Address__c,
                             Quote_Location__c.Locations__r.Azure_ID__c,
                             Quote_Location__c.Locations__r.City__c,
                             Quote_Location__c.Locations__r.Country__c,
                             Quote_Location__c.Locations__r.Country_Code__c,
                             Quote_Location__c.Locations__r.County__c,
                             Quote_Location__c.Locations__r.Geolocation__c,
                             Quote_Location__c.Locations__r.Name,
                             Quote_Location__c.Locations__r.Postal_Code__c,
                             Quote_Location__c.Locations__r.State_Code__c
                             FROM Quote_Locations__r),
                            (SELECT Id, Name, RecordTypeId, Document_Azure_Id__c, Document_Type__c, 
                             Quote_Id__c, Sent_to_Billing__c, Policy__c FROM 
                             Document_Revisions__r),
                            (SELECT Id, Name, Quote__r.Name, Status__c, Reason__c, Azure_ID__c, 
                             Reason_Type__c, Approval_Level_Required__c, Entity_Path__c, Approval_Status__c, 
                             Approver_Level__c, Approved_By__r.Name, Approval_Rejected_Date__c,Option_Id__c,
                             Quote_Option__c,Quote_Option__r.Selected__c,Option_Type__c,Option_Limit__c 
                             FROM Referral_Reasons__r),
                            (SELECT Azure_ID__c, Actual_Premium_Annual__c, Actual_Premium_Final__c, 
                             Book_Premium__c, Broker_Netted_Down_Premium_Annual__c, 
                             Broker_Netted_Down_Premium_Final__c, Fee_Annual__c, Fee_Final__c, 
                             Final_Discretion__c, Limit__c, Minimum_Premium__c, Price_Adequacy__c, 
                             Technical_Premium__c, Technical_Premium_Discretion__c, 
                             Selected__c, Bound__c, Option_Type__c, Final_Technical_Premium__c,
                             Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c,
                             Technical_Fee__c,IPT__c,Total_Cost_To_Client__c, Actual_Premium__c,
                             Broker_Netted_Down_Premium__c, Fee__c, IPT_on_Broker_Netted_Down_Premium__c, 
                             Limit_Of_Indemnity__c, NDPB_Commission_Percent__c,
                             NonProrated_Actual_Premium__c, NonProRated_BNDP__c, Netted_Down_Commission_Percent__c,
                             Change_In_Actual_Premium__c, Change_In_Broker_Netted_Down_Premium__c,
                             Change_In_Fee__c, Change_in_IPT__c, Change_in_Total_Cost_to_Client__c FROM Quote_Options__r)
                            FROM Quote WHERE id=:ratedQuote.Id])
        {
            quoteList.add(quoteObj);
        }
        
        Policy__c policy = new Policy__c();
        if(String.isNotBlank(policyID))
            policy =[SELECT Id, Name, Policy_Number__c, Effective_Date__c, Expiration_Date__c, 
                     Initial_Premium__c, Total_Premium__c, Net_Endorsement__c, Account__c, Cancellation_Date__c, 
                     Cancellation_Reason__c, Azure_ID__c, Policy_Status__c, Product_Name__c, NIPR_Results__c, 
                     Binding_License_Number__c, NJ_Transaction_Code__c, Invoice_Status__c, Policy_Document_sent__c, 
                     Number_Open_Subjectivity_Bound_Quote__c,
                     (SELECT Id, Name, RecordTypeId, Document_Azure_Id__c, Document_Type__c, 
                      Quote_Id__c, Sent_to_Billing__c, Policy__c FROM 
                      Document_Revisions__r) FROM Policy__c WHERE Id =:policyID];
        
        Master_Binder__c masterBinder = new Master_Binder__c();
        List<Binding_Authority_Agreement__c> bAAList = new List<Binding_Authority_Agreement__c>();
        if(String.isNotBlank(masterBinderId)){
            /*masterBinder = [Select Id,Name,Layer__c,Coverholder_Name__c,Coverholder_Pin__c,Expiry_Date__c,Inception_Date__c,
                            MGA_Commission__c,(Select Id,Name,Binder_Reference_Number__c,Capacity__c, Total_Percentage__c,
                           (SELECT Id, Name, Total_Percentage__c, Binding_Authority_Agreement__c FROM Capacities_On_Documents__r)                   
                            FROM Binding_Authority_Agreements__r) 
                            FROM Master_Binder__c 
                            WHERE Id =:masterBinderId][0];*/
            masterBinder = [Select Id,Name,Layer__c,Coverholder_Name__c,Coverholder_Pin__c,Expiry_Date__c,Inception_Date__c,
                            MGA_Commission__c FROM Master_Binder__c WHERE Id =:masterBinderId][0];
            bAAList.addAll([Select Id,Name,Binder_Reference_Number__c,Master_Binder__c,Capacity__c, Total_Percentage__c,Sort_Order__c,
                           (SELECT Id, Name, Total_Percentage__c, Binding_Authority_Agreement__c,Sort_Order__c FROM Capacities_On_Documents__r ORDER BY Sort_Order__c)                   
                            FROM Binding_Authority_Agreement__c WHERE Master_Binder__c =: masterBinderId ORDER BY Sort_Order__c]); 
        }
		        
        ratingRequest = '{ "productConfigAttributes":' + JSON.serialize(productConfigAttributesList) +  
            ', "priorQuoteCoverageLineItems":' + JSON.serialize(priorQuoteCoverageLineItemsNew) +
            ',"opportunity":' +JSON.serialize(opportunity) +
            ',"quote":'+JSON.serialize(quoteList[0]) + 
            ',"masterBinder":'+JSON.serialize(masterBinder) + 
            //',"QuoteOptions":'+'' +
            ',"binderAuthAgreement":'+JSON.serialize(bAAList)+
            ',"policy":' +JSON.serialize(policy) +'}';

            
        
        system.debug('rating req AQ--'+ratingRequest);        
        return ratingRequest;
    }
    
    /*************************************************
* Method Name: getRatingJson
* Author:
* Date: 22-Mar-2021  / Covert Rating request to String for Celerity
* Params: quoteId
* Return: JSON string of request FOR rating and reverse sync for Celerity
*************************************************/
    public static String getRatingJsonCelerity(Quote ratedQuote){
        String ratingRequest = '';
        Id oppId = ratedQuote.OpportunityId;
        Id parentQuoteId = ratedQuote.Parent_Quote__c;
        ID policyID = ratedQuote.Policy__c;
        String IsAdmitted;
        
        List<Opportunity> productConfigAttributesList = [SELECT Id,
                                                         Product__r.Azure_ID__c, Product__r.Carrier_Commission__c,
                                                         Product__r.Description, Product__r.DisplayUrl,
                                                         Product__r.Effective_Date__c, Product__r.Expiration_Date__c,
                                                         Product__r.ExternalId, Product__r.Family, 
                                                         Product__r.Innovisk_Entity_ID__c, Product__r.IsActive,
                                                         Product__r.Marketing_Minimum_premium__c, Product__r.Model_ID__c,
                                                         Product__r.Name, Product__r.Offer__c, Product__r.Package_Indicator__c, 
                                                         Product__r.Pay_Plan__c, Product__r.Product_Features__c, 
                                                         Product__r.Product_Image_URL__c, Product__r.ProductCode,
                                                         Product__r.QuantityUnitOfMeasure, Product__r.StockKeepingUnit, 
                                                         Product__r.UMR__c, Product__r.Writing_Company__c,Product__r.Writing_Company__r.Name,
                                                         Product__r.Writing_Company__r.BillingAddress
                                                         FROM Opportunity WHERE Id = :oppId];
        String productName = '';
        
        if(productConfigAttributesList.size() > 0)	productName = productConfigAttributesList[0].Product__r.Name;
        
        List<CoveragesLineItem__c> priorQuoteCoverageLineItemsNew = new  List<CoveragesLineItem__c>();
        if(ratedQuote.Quote_Type__c != 'New Business' && String.isNotBlank(ratedQuote.Parent_Quote__c)){
            priorQuoteCoverageLineItemsNew = [SELECT ID, Name, Azure_ID__c, 
                                              Sub_Coverage__r.Id, Sub_Coverage__r.Name,
                                              Sub_Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Code__c,
                                              Coverage__r.Id, Coverage__r.Azure_ID__c, Coverage__r.Name, Coverage_Premium__c,
                                              Factor_Value__c, Coverage__r.Coverage_Product__c,Coverage__r.Coverage_Product_Combo__c,
                                              Coverage__r.Additional_Requirements__c,Coverage__r.Form_Number__c,
                                              Non_Prorated_Coverage_Premium__c, // Added Non_Prorated_Coverage_Premium__c for US:52937
                                              Factor_Min__c, Factor_Max__c, Increment_Step__c, 
                                              Factor_Default_Value__c,Limits_Deductibles__c, Limits_Deductibles__r.Azure_ID__c,
                                              Limits_Deductibles__r.Name, Limits_Deductibles__r.Type__c,
                                              Limits_Deductibles__r.RecordTypeId,Limits_Deductibles__r.LmtDedCode__c,
                                              Limits_Deductibles__r.RecordType.DeveloperName,
                                              Limits_Deductibles__r.RecordType.Name, Max_amt__c, Min_amt__c,
                                              Option_Type__c, Option_Value_Default__c, IsSelected__c,
                                              Option_Picklist__c,Override_Premium__c, Rating__c,
                                              Added_in_current_transaction__c,Coverage_Effective_Date__c
                                              FROM CoveragesLineItem__c WHERE Quote__c =: parentQuoteId];
        }
        
        List<Opportunity> opportunity = [SELECT Id,Azure_ID__c, Name,Industry__c,Total_Revenues__c, MPL_Professional_Services__c,
                                         AnnualRevenue__c, Cash_Flow_From_Operating_Activities__c,
                                         Current_Assets__c, Current_Liabilities__c,Largest_Work_Type__c,Main_Profession__c,
                                         Long_Term_Debt__c, Net_Income__c, Retained_Earnings__c,
                                         Shareholders_Equity__c, Total_Assets__c, Total_Liabilities__c,
                                         Retroactive_Date__c,Retroactive_Date_Docs__c,
                                         Effective_Date_Docs__c, Account.Name,Account.Website, Account.Azure_ID__c,Tax_Country__c,
                                         Account.BillingAddress,Account.BillingState, Account.Billing_County__c, Account.Duns_Number__c,CreatedBy.Name,
                                         Account.D_B_Rating_Classification__c,Service_Classification__c, 
                                         Account.Composite_Credit_Appraisal__c,Account.AQ_Sanction_Status__c,
                                         OwnerId, Owner.Name, Owner.Email, Prior_Policy__c, Prior_Policy__r.Policy_Number__c,
                                         // Added by Maeran Shaikh on 10/6/2021 for US: 47350
                                         Description, Part_Time_Employees__c, Ratable_Employees__c, Foreign_Employees__c,
                                         Average_Part_Time_Ratio__c, Percent_of_Employees_located_in_CA__c, Foreign_Ratio__c,
                                         Full_Time_Employees__c, Plan_Assets__c,
                                         (Select Id,Name,Amount__c,Notional_Income__c,Rating_Factor__c,Sort_Order__c,
                                          Split_Percentage__c,Submission__c,UW_Analysis_Code__c,UW_Analysis_Name__c,
                                          UW_Analysis_Template__c,UW_Analysis_Template__r.Criteria__c,UW_Analysis_Template__r.Rating_Factor__c,
                                          UW_Analysis_Template__r.Sort_Order__c,UW_Analysis_Template__r.Default_Split_Percentage__c,
                                          UW_Analysis_Template__r.UW_Analysis_Code__c,UW_Analysis_Template__r.UW_Analysis_Name__c,
                                          UW_Analysis_Template__r.Name from UW_Analysis__r),
                                         (SELECT Name, Loss_Amount__c, Status__c, Year__c,Number_of_Losses__c 
                                          FROM Submission_Loss_Details__r),
                                          (Select Id, Clearance_Date__c, Clearance_Status__c, IsManualClearance__c, Product__c, Product__r.Name, 
                                         Name, Is_Selected__c from Product_Option_Line_Items__r  where Is_Selected__c = true)
                                         FROM Opportunity WHERE Id = :oppId]; 
        List<Quote> quoteList = new List<Quote>();
        for(quote quoteObj:[Select Id,Commission_percentage__c,Azure_ID__c, Effective_Date__c, QuoteNumber, ExpirationDate,
                            AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                            Quote_Type__c, Name, Status, Rating_Status__c,Tax,Commission__c, Override_Premium__c, Override_Premium_Percentage__c ,Parent_Quote__c, 
                            Technical_Premium__c,QuotePremium__c,Total_Premium__c,CloseDate__c,Accept_Terror_Premium__c,
                            Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c, Special_Coverages__c,
                            Parent_Quote__r.Non_Prorated_Quote_Premium__c,Parent_Quote__r.QuotePremium__c,Broker__r.Account.Azure_ID__c,BypassRating__c,
                            Broker__r.Azure_ID__c,Broker__r.id,Endorsement_Quote_Bound_Date__c,Broker__r.Name,
                            Broker__r.Email,Broker__r.Account.Name,Broker__r.Account.BillingAddress,
                            Broker__r.FirstName,Transaction_Premium__c,Excess_Min_Premium__c,
                            Pending_or_Prior_Proceedings_Date__c,Prior_Discount_Quote_Premium__c, Shared_Aggregate_Limit__c,
                            RatesEffectiveDate__c, // Added for US:52235
                            Rate_Charged__c,ERP_Duration__c,// Added for newly created fields for ERP US:52571 by Maeran Shaikh
                            Quote_Action__c, // Added for US:53646
                            Municipal_Tax__c,Collection_Fee__c,Surcharges__c,Total_Surcharges__c,Combined_Max_Agg_Limit_of_Liability__c,
                            //Aqueous New Fields
                            Actual_Excess__c, Actual_Premium__c, As_if_Book_Rated_Premium_rate_change__c, Binder__c, 
                            Book_Excess__c, Book_Premium__c, Book_Rated_Premium__c, Broker_Commission__c, 
                            Broker_Netted_Down_Premium__c, Discretion__c, Excess_Basis__c, Fee__c, Final_Discretion__c, 
                            IPT_on_Broker_Netted_Down_Premium__c, Jurisdiction_Limits__c, Layer__c, Limit_Basis__c, 
                            MGA_Commission__c, Minimum_Premium__c, Netted_Down_Premium_Broker_Commission__c, 
                            Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c,PI_Limit_of_Indemnity__c, 
                            Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, 
                            Previous_Year_Final_Discretion__c, Previous_Year_Exposure__c, Price_Adequacy__c, 
                            Rate__c, Rateable_Exposure__c, RetroDate__c,Technical_Premium_Discretion__c, 
                            Retroactive_Date__c, Revised_Broker_Commission__c, Revised_MGA_Commission__c, 
                            Territorial_Limits__c, Total_Underlying_Layer__c,Rate_Change__c, Special_Coverage_Selected__c, Special_Coverage_Text__c, KY_Tax_Rate__c,
                            (SELECT Factor_Default_Value__c, Factor_Max__c, Factor_Min__c,
                             Factor_Value__c, Rating_Modifier__r.Rating_Modifier_Value__c,
                             Rating_Modifier__r.Rating_Modifier_Code__c, Rating_Modifier__r.Format__c,
                             Rating_Modifier__r.Name, Rating_Modifier__r.Product__c,Rating_Modifier__r.Factor_Max__c,
                             Rating_Modifier__r.Factor_Min__c,Rating_Modifier__r.Factor_Value__c,
                             Rating_Modifier__r.Azure_ID__c, Rating_Modifier__r.Page_Section__c
                             FROM Rating_Modifier_Factors__r),(SELECT Id, Name, Quote__c, Form_Number__c, Endorsement_Name__c, Endorsement_Wording__c, 
                             Coverage_Effective_Date__c,Notes__c,Applicable_Coverage__c FROM Free_Form_Endorsements__r ORDER BY createdDate),
                            (SELECT Id, Name, Subjectivity__c, Subjectivity_Status__c, Subjectivity_Type__c, Stage__c, Due_Date__c,
                             Cleared__c,Cleared_Date__c,RecordTypeId,RecordType.Name,Subjectivity_Text__c,Subjectivity_Template__c,                           
                             Subjectivity_Template__r.Name,Subjectivity_Template__r.Cleared__c,Subjectivity_Template__r.Cleared_Date__c,
                             Subjectivity_Template__r.Profession_Criteria__c,Subjectivity_Template__r.Proposal_Form_Date__c,
                             Subjectivity_Template__r.Subjectivity_Name__c,Subjectivity_Template__r.Subjectivity_Text__c 
                             FROM Subjectivity__r),
                            (SELECT Id, Name, Additional_Interest_Account__c, Quote__c, Azure_ID__c, Relationship_Type__c, 
                             Parent_Additional_Interest__c, Loan_Reference_number__c,Loss_Payee_Interest__c,Primary_Mortgage_Servicer__c, 
                             Entity_Type__c
                             FROM Additional_Interests__r),
                             (SELECT Code__c, Description__c, Value__c
                             FROM Surcharge_Breakdown__r),
                            (SELECT Id, AccountId__c,Azure_ID__c,OpportunityId__c, OriginCreation__c, 
                             Primary_Location__c,Name,Usage_Type__c,State_Review_Required__c,
                             Quote_Location__c.Locations__r.State_Province__c,
                             Quote_Location__c.Locations__r.Address__c,
                             Quote_Location__c.Locations__r.Azure_ID__c,
                             Quote_Location__c.Locations__r.City__c,
                             Quote_Location__c.Locations__r.Country__c,
                             Quote_Location__c.Locations__r.Country_Code__c,
                             Quote_Location__c.Locations__r.County__c,
                             Quote_Location__c.Locations__r.Geolocation__c,
                             Quote_Location__c.Locations__r.Name,
                             Quote_Location__c.Locations__r.Postal_Code__c,
                             Quote_Location__c.Locations__r.State_Code__c
                             FROM Quote_Locations__r),
                            (SELECT Id, Name, RecordTypeId, Document_Azure_Id__c, Document_Type__c, 
                             Quote_Id__c, Sent_to_Billing__c, Policy__c FROM 
                             Document_Revisions__r),
                             (  // Added by Maeran for US:53340
                                 Select Id,Name,Product_Name__c,Quote_Premium__c,Excess_Premium__c from Quote_Premiums__r
                             ) 
                            FROM Quote WHERE id=:ratedQuote.Id])
        {
            quoteList.add(quoteObj);
        }
        
        List<CoveragesLineItem__c> clis = [SELECT ID, Name, Azure_ID__c, Coverage_Type__c, Sub_Coverage__r.Id, Coverage__r.Azure_ID__c,
        Sub_Coverage__r.Name,Sub_Coverage__r.Coverage_Code__c, Coverage__r.Coverage_Code__c,
        Coverage__r.Id, Coverage__r.Name, Coverage_Premium__c,Coverage__r.Coverage_Type__c, Coverage__r.Coverage_Product__c, Coverage__r.Additional_Requirements__c,
        Factor_Min__c, Factor_Max__c, Increment_Step__c, Notes__c,Group__c,
        Factor_Default_Value__c,Limits_Deductibles__c, Limits_Deductibles__r.Azure_ID__c,
        Limits_Deductibles__r.Name, Limits_Deductibles__r.Type__c,
        Limits_Deductibles__r.RecordTypeId,Limits_Deductibles__r.LmtDedCode__c,
        Limits_Deductibles__r.RecordType.DeveloperName,
        Limits_Deductibles__r.RecordType.Name, Max_amt__c, Min_amt__c,
        Option_Type__c,  Option_Value_Default__c, IsSelected__c,
        CoverageLineItemType__c, Coverage__r.Coverage_Product_Combo__c,Coverage__r.Form_Number__c,
        Option_Picklist__c,Override_Premium__c, Rating__c , Added_in_current_transaction__c ,Coverage_Effective_Date__c
        FROM CoveragesLineItem__c where Quote__c = :ratedQuote.Id order by Coverage_Sort_Order__c];
        

        String quoteString = JSON.serialize(quoteList[0]);
        String clisString = '"Coverages_Line_Items__r": {'
            + '"totalSize": ' + clis.size() + ', '
            + '"done": true,'
            + '"records": ' + JSON.serialize(clis)
            + '}';


        quoteString = quoteString.substring(0, quoteString.length() - 1) + ','
            + clisString
            +  '}';

        //Quote newQuote = (Quote) JSON.deserialize(quoteString, Quote.class);
        //quoteString = JSON.serialize(newQuote);

        Policy__c policy = new Policy__c();
        if(String.isNotBlank(policyID))
            policy =[SELECT Id, Name, Policy_Number__c, Effective_Date__c, Expiration_Date__c, 
                     Initial_Premium__c, Total_Premium__c, Net_Endorsement__c, Account__c, Cancellation_Date__c, 
                     Cancellation_Reason__c, Azure_ID__c, Policy_Status__c, Product_Name__c, NIPR_Results__c, 
                     Binding_License_Number__c,
                     Binding_License_Owner__c, Binding_License_Owner_Address__c,Binding_License_Owner_Name__c,
                     NJ_Transaction_Code__c, Invoice_Status__c, Policy_Document_sent__c, 
                     Number_Open_Subjectivity_Bound_Quote__c,Pending_or_Prior_Proceedings_Date__c,
                     // Added by Maeran Shaikh on 10/6/2021 for US: 47350
                     Parent_Policy_Number__c,
                     (SELECT Id, Name, RecordTypeId, Document_Azure_Id__c, Document_Type__c, 
                      Quote_Id__c, Sent_to_Billing__c, Policy__c FROM 
                      Document_Revisions__r) FROM Policy__c WHERE Id =:policyID];
        
            
            IsAdmitted = getAdmittedStatus(opportunity[0].Account.BillingState);

            ratingRequest = '{ "productConfigAttributes":' + JSON.serialize(productConfigAttributesList) +  
            ', "priorQuoteCoverageLineItems":' + JSON.serialize(priorQuoteCoverageLineItemsNew) +
            ',"opportunity":' +JSON.serialize(opportunity) +
            ',"quote":'+quoteString+ 
            ',"policy":' +JSON.serialize(policy) +
            ',"IsAdmitted":'+IsAdmitted+'}';
        
        system.debug('rating req Celerity --'+ratingRequest);
        return ratingRequest;
    }

    public static String getAdmittedStatus(String IncomingState){
        String IsAdmitted;
       
        try{
            if(IncomingState != ''){
                List<Admitted_States__mdt> stateslist = [SELECT Billing_States__c FROM Admitted_States__mdt];
                for(Admitted_States__mdt state : stateslist){
                    if(IncomingState == state.Billing_States__c){
                        IsAdmitted = 'false';
                    }else{
                        IsAdmitted = 'true';
                    }
                }
            }
        }catch(Exception e){

        }
        return IsAdmitted;
    }
}