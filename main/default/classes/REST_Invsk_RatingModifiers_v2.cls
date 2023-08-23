/*************************************************
* Class Name: REST_Invsk_RatingModifiers_v2
* Author: Priyanka Fulwani
* Date: 10/20/2020
* Requirement/Project Description: Get RatingModifiers API
*************************************************/
@RestResource(urlMapping='/Invsk_RatingModifiers_v2/*')
global class REST_Invsk_RatingModifiers_v2{
    @HttpPost 
    global static void upsertRatingModifiers(){
        
        RestRequest ratingModifierReq = RestContext.request;
        String requestBody = ratingModifierReq.requestBody.toString();
        List<Rating_Modifiers__c> upsertRatingModifier = new List<Rating_Modifiers__c>();
        Map<String,Rating_Modifiers__c> ratingModifierIdtoRMObjmap = new Map<String,Rating_Modifiers__c>();
        List<Rating_Modifiers__c> ratingModifierRequest = new List<Rating_Modifiers__c>();
        OutcomingResponsePost outResponse = new OutcomingResponsePost();
        List<Rating_Modifiers__c> sendResponseList = new List<Rating_Modifiers__c>();
        Set<String> ratingModifierCode = new Set<String>();
        Set<String> oppAzureId = new Set<String>();
        Map<String,ID> oppAzureIdtoIdmap = new Map<String,ID>();
        Set<String> oppIds =new Set<String>();
        Map<String,Rating_Modifier_Template__c> ratingModifierTemplatemap = new Map<String,Rating_Modifier_Template__c>();
        
        try{
            
            ratingModifierRequest = (List<Rating_Modifiers__c>) JSON.deserialize(requestBody, List<Rating_Modifiers__c>.class);
            
            for(Rating_Modifiers__c rmObj : ratingModifierRequest){
                if(String.isBlank(rmObj.Rating_Modifier_Code__c) || String.isBlank(rmObj.Product__c) || String.isBlank(rmObj.Opportunity__c)){
                    
                    
                    
                    outResponse.status = 'Failed';
                    outResponse.isSuccess = false;
                    if(String.isBlank(rmObj.Rating_Modifier_Code__c))
                        outResponse.errors.add('Rating_Modifier_Code__c is Blank');
                    if(String.isBlank(rmObj.Product__c))
                        outResponse.errors.add('Product__c is Blank');
                    if(String.isBlank(rmObj.Opportunity__c))
                        outResponse.errors.add('Opportunity__c AzureId is Blank');
                    RestContext.response.statusCode = 500;
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                    ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_RatingModifiers_v2', 'REST_Invsk_RatingModifiers.upsertRatingModifiers');
                    return;
                }
                else{
                    
                    oppAzureId.add(rmObj.Opportunity__c);
                    ratingModifierCode.add(rmObj.Rating_Modifier_Code__c);
                }
            }
             
            for (Opportunity oppObj : [Select Id,Azure_Id__c From Opportunity Where Azure_Id__c =: oppAzureId])
            {   
              
                oppAzureIdtoIdmap.put(oppObj.Azure_Id__c,oppObj.Id);
                oppIds.add(oppObj.Id);
            }
            
            for(Rating_Modifiers__c rm :[Select Id,Azure_ID__c,Rating_Modifier_Code__c FROM Rating_Modifiers__c WHERE Opportunity__c IN:oppIds])
            {   
                ratingModifierIdtoRMObjmap.put(rm.Rating_Modifier_Code__c,rm);
            }
            //fetching rating modifier template from RM Code
            for(Rating_Modifier_Template__c ratingModTemp :[SELECT Id, Name, Modifier_Format__c, Is_Required__c, 
                                                            Eligibility_Weighting_Factor__c, Rating_Modifier_Code__c,
                                                            Picklist_Values__c, Factor_Min__c, Factor_Max__c, 
                                                            Picklist_Default_Value__c, Factor_Default_Value__c,
                                                            Page_Section__c, Sort_Order__c, Picklist_Range__c, 
                                                            Sub_Section__c, Comment__c, Sort_Sub_Section__c, Display_Format__c,
                                                            Product__c, Profile_Name_for_Read_Only__c, External_Id__c ,SME_Question__c
                                                            FROM Rating_Modifier_Template__c WHERE Rating_Modifier_Code__c =:ratingModifierCode AND Page_Section__c = 'SME Eligibility'])
            {   
                ratingModifierTemplatemap.put(ratingModTemp.Rating_Modifier_Code__c,ratingModTemp);
            }
            for(Rating_Modifiers__c rmObj : ratingModifierRequest){
                if(oppAzureIdtoIdmap.get(rmObj.Opportunity__c) != null) {
                    rmObj.Opportunity__c = oppAzureIdtoIdmap.get(rmObj.Opportunity__c);
                } 
                else{
                    outResponse.status = 'Failed';
                    outResponse.isSuccess = false;
                    outResponse.errors.add('Opportunity AzureId - '+rmObj.Opportunity__c+' is invalid for Rating Modifier');
                    RestContext.response.statusCode = 500;
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                    ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_RatingModifiers_v2', 'REST_Invsk_RatingModifiers.upsertRatingModifiers');
                    return;
                } 
                
                if(ratingModifierIdtoRMObjmap.containsKey(rmObj.Rating_Modifier_Code__c)){
                    rmObj.Id = ratingModifierIdtoRMObjmap.get(rmObj.Rating_Modifier_Code__c).Id;
                }
                else if(ratingModifierTemplatemap.containsKey(rmObj.Rating_Modifier_Code__c))
                {
                    rmObj.Name = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Name;
                    rmObj.Format__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Modifier_Format__c;
                    rmObj.Page_Section__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Page_Section__c;
                    rmObj.Sub_Section__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Sub_Section__c;
                    rmObj.Picklist_Values__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Picklist_Values__c;
                    rmObj.Is_Required__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Is_Required__c;
                    rmObj.Factor_Max__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Factor_Max__c;
                    rmObj.Factor_Min__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Factor_Min__c;
                    rmObj.Sort_Order__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Sort_Order__c;
                    rmObj.Eligibility_Weighting_Factor__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Eligibility_Weighting_Factor__c;
                    rmObj.SME_Question__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).SME_Question__c;
                    rmObj.Sort_Sub_Section__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Sort_Sub_Section__c;
                    rmObj.Display_Format__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Display_Format__c;
                    rmObj.Profile_Name_for_Read_Only__c = ratingModifierTemplatemap.get(rmObj.Rating_Modifier_Code__c).Profile_Name_for_Read_Only__c;
                }
                
                if(rmObj.Product__c=='Celerity_Cyber')
                {
                    rmObj.Product__c='Cyber';
                }
                else if(rmObj.Product__c=='Celerity_MPL'){
                    rmObj.Product__c='MPL';
                }
                upsertRatingModifier.add(rmObj);
            }
            if(!upsertRatingModifier.isEmpty())
            {
                upsert upsertRatingModifier;
                
                sendResponseList = [SELECT Id, Azure_Id__c from Rating_Modifiers__c where Id IN :upsertRatingModifier];
                
                outResponse.status = 'Success';
                outResponse.isSuccess = true;
                outResponse.RatingModifiers = sendResponseList;
                RestContext.response.statusCode = 200;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
                
                ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_RatingModifiers_v2', 'REST_Invsk_RatingModifiers.upsertRatingModifiers');
                return;
            }
        }catch(Exception ex){
            outResponse.status = 'Failed';
            outResponse.isSuccess = false;
            outResponse.errors.add('An error occurred '+ex.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(outResponse));
            ApiUtil.logAPICallIn(RestContext.request, RestContext.response, 'REST_Invsk_RatingModifiers_v2', 'REST_Invsk_RatingModifiers.upsertRatingModifiers');
            return;
        } 
    }
    
    
    public class OutcomingResponseGet {
        public String status                {get; set;}
        public Boolean isSuccess            {get; set;}
        public List<String> errors          {get; set;}
        public List<Rating_Modifiers__c> ratingModifiers   {get; set;}
        public OutcomingResponseGet() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.ratingModifiers = new List<Rating_Modifiers__c>();
        }
    }
    public class OutcomingResponsePost {
        public String status;
        public Boolean isSuccess;
        public List<String> errors;
        
        public List<Rating_Modifiers__c> RatingModifiers   {get; set;}
        public OutcomingResponsePost() {
            this.status = null;
            this.isSuccess = false;
            this.errors = new List<String>();
            this.RatingModifiers = new List<Rating_Modifiers__c>();
            
        }
    }
}