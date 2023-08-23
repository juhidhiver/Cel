/**************************************************************************************************
* Class Name: CyberIntelCallout
* Author: Priyanka Fulwani
* Created date: 25-Nov-2020
* Description: Callout API for CyberIntel Service
**************************************************************************************************/
public with sharing class CyberIntelCallout {
    @AuraEnabled
    public static void cyberIntelRequest(Id submissionId){
        try{
            List<Opportunity> opp = [SELECT Id, Account.Website, Product_Name__c, Service_to_Run__c FROM Opportunity 
                                    WHERE Id  =: submissionId AND
                                    Product_Name__c ='Cyber Standalone'];
            if(String.isNotEmpty(opp[0].Id)){
                if(String.isEmpty(opp[0].Account.Website) || opp[0].Service_to_Run__c == 'None'){
                    List<Rating_Modifiers__c> listOfRateMod = [SELECT Id, Name, Rating_Modifier_Value__c
                                                            FROM Rating_Modifiers__c WHERE Opportunity__c =:submissionId
                                                            AND Name = 'Cyber Intel Service'];
                    listOfRateMod[0].Rating_Modifier_Value__c = opp[0].Service_to_Run__c;
                    if(listOfRateMod.size() > 0){
                        update listOfRateMod;
                    }
                }
                else{
                    HttpRequest request = new HttpRequest();
                    HttpResponse response = new HttpResponse();
                    Http https = new Http();  
                    API_Configuration__mdt apiSetting;
                    
                    try{
             List<String> rateMods = new List<String>{'Cyber Intel Score','Cyber Intel Service',
                 'Cyber Intel BitSight Rules','Cyber Intel Failed Reason'};
                            List<Rating_Modifiers__c> updateRateMod = new List<Rating_Modifiers__c>();
                        apiSetting = CommonUtil.getAPIconfiguration('CyberIntel');        
                        
                        
                        request = Invsk_Callout.getHttpRequest(apiSetting);
                        system.debug('cyberIntel apisetting --'+request);
                        String endpoint = request.getEndpoint();
                        endpoint = endpoint + '?url=' +opp[0].Account.Website;
                        system.debug('endpoint'+endpoint);
                        request.setEndpoint(endpoint);
                        response = https.send(request);
                        if(response.getStatusCode() == 200) {
                            CyberIntelWrapper CyberIntelWrap = (CyberIntelWrapper)JSON.deserialize(response.getBody(),CyberIntelWrapper.class);
                         
                            system.debug('averageScore - -'+CyberIntelWrap.average_score);
          
                            List<Rating_Modifiers__c> listOfRateMod = [SELECT Id, Name, Rating_Modifier_Value__c
                                                                    FROM Rating_Modifiers__c WHERE Opportunity__c =:submissionId
                                                                    AND Name = :rateMods];
                            for(Rating_Modifiers__c ratingMod:listOfRateMod){
                                if(ratingMod.Name =='Cyber Intel Score'){
                                    Date lastestDate = Date.newInstance(0,0,0);
                                    String latestRating = '';
                                    if(CyberIntelWrap.ratings != null)
                                    for(Ratings r: CyberIntelWrap.ratings){
                                        if(lastestDate < date.valueOf(r.rating_date)){
                                            lastestDate = date.valueOf(r.rating_date);
                                            latestRating = String.valueOf(r.rating);
                                        }
                                    }
                                    ratingMod.Rating_Modifier_Value__c = latestRating;
                                    updateRateMod.add(ratingMod);
                                }
                                else if(ratingMod.Name =='Cyber Intel Service'){
                                    ratingMod.Rating_Modifier_Value__c = opp[0].Service_to_Run__c;
                                    updateRateMod.add(ratingMod);
                                }
                                if(ratingMod.Name =='Cyber Intel BitSight Rules'){
                                if(CyberIntelWrap.average_score >='650' 
                                   && CyberIntelWrap.Rating_details.spam_propagation.grade == 'A'
                                   && CyberIntelWrap.Rating_details.botnet_infections.grade == 'A'
                                   && CyberIntelWrap.Rating_details.potentially_exploited.grade == 'A'
                                   && CyberIntelWrap.Rating_details.malware_servers.grade == 'A'
                                   && CyberIntelWrap.Rating_details.unsolicited_comm.grade == 'A'
                                   && (CyberIntelWrap.Rating_details.patching_cadence.grade == 'A'
                                      || CyberIntelWrap.Rating_details.patching_cadence.grade == 'B')
                                   && (CyberIntelWrap.Rating_details.open_ports.grade == 'A' 
                                       || CyberIntelWrap.Rating_details.open_ports.grade == 'B'))
                                   
                                { 
                                    ratingMod.Rating_Modifier_Value__c = 'Pass';
                                }
                                    else
                                     ratingMod.Rating_Modifier_Value__c = 'Fail';
                                   
                                     updateRateMod.add(ratingMod);
                                }
                                   if(ratingMod.Name =='Cyber Intel Failed Reason'){
                                     List<String> errors = new List<String>();
                                       
                                   if(CyberIntelWrap.average_score <'650')
                                       errors.add('Latest Overall score is less than 650');

                                   if(CyberIntelWrap.Rating_details.spam_propagation.grade != 'A')
                                       errors.add('Spam Propagation grade = '+CyberIntelWrap.Rating_details.spam_propagation.grade);
                                       
                                   if(CyberIntelWrap.Rating_details.botnet_infections.grade != 'A')
                                       errors.add('Botnet Infections = '+CyberIntelWrap.Rating_details.botnet_infections.grade);
                                       
                                   if(CyberIntelWrap.Rating_details.potentially_exploited.grade != 'A')
                                       errors.add('Potentially Exploited = '+CyberIntelWrap.Rating_details.potentially_exploited.grade);
                                       
                                   if(CyberIntelWrap.Rating_details.malware_servers.grade != 'A')
                                       errors.add('Malware Servers = '+CyberIntelWrap.Rating_details.malware_servers.grade);
                                       
                                   if(CyberIntelWrap.Rating_details.unsolicited_comm.grade != 'A' ) 
                                       errors.add('Unsolicited Communications = '+CyberIntelWrap.Rating_details.unsolicited_comm.grade);
                                       
                                   if(CyberIntelWrap.Rating_details.patching_cadence.grade != 'A'
                                      && CyberIntelWrap.Rating_details.patching_cadence.grade != 'B')
                                       errors.add('Patching Cadence = '+CyberIntelWrap.Rating_details.patching_cadence.grade);
                                       
                                   if(CyberIntelWrap.Rating_details.open_ports.grade != 'A' 
                                       && CyberIntelWrap.Rating_details.open_ports.grade != 'B')
                                       errors.add('Open Ports = '+CyberIntelWrap.Rating_details.open_ports.grade);
                                     
                                       if(errors.Size()>0)
                                     ratingMod.Rating_Modifier_Value__c = string.join(errors,',');
                                       else
                                        ratingMod.Rating_Modifier_Value__c = '';
                                     
                                       updateRateMod.add(ratingMod);
                                   
                            }
                                
                            }
                            if(updateRateMod.size() > 0){
                                update updateRateMod; 
                            }   
                                                 
                        }
                        else
                        {
                Rating_Modifiers__c RateMod = [SELECT Id, Name, Rating_Modifier_Value__c
                                                FROM Rating_Modifiers__c WHERE Opportunity__c =:submissionId
                                                AND Name =:'Cyber Intel BitSight Rules'];            
                         RateMod.Rating_Modifier_Value__c = 'Service Failed';
                         if(String.isNotBlank(RateMod.Rating_Modifier_Value__c))
                            update RateMod;
                        }
                    }                
                    catch(Exception ex){
                        System.debug(ex.getMessage());            
                    }
                    ApiUtil.logAPICall(request, response, 'CyberIntelCallout', 'cyberIntelRequest', apiSetting.HeaderParams__c , 'Outbound');
                }
            }    
            else{
                return;
            }
        }
        catch(Exception ex){
            System.debug(ex.getMessage());            
        }
    }
    public class CyberIntelWrapper {
        public String average_score;
        public String primary_domain;
        public Rating_details rating_details;
        public List<Ratings> ratings;
        public Quota_details quota_details;
	
    }
    public class RatingDetailsData {
		public String name;
		public Integer rating;
		public String grade;
		//public Integer percentile;
		public String grade_color;
		public String category;
		public Integer category_order;
		public Boolean beta;
		public Integer order;
	}
    	public class Rating_details {
		public RatingDetailsData botnet_infections;
		public RatingDetailsData spam_propagation;
		public RatingDetailsData malware_servers;
		public RatingDetailsData unsolicited_comm;
		public RatingDetailsData potentially_exploited;
		public RatingDetailsData spf;
		public RatingDetailsData dkim;
		public RatingDetailsData ssl_certificates;
		public RatingDetailsData ssl_configurations;
		public RatingDetailsData open_ports;
		public RatingDetailsData dnssec;
		public RatingDetailsData application_security;
		public RatingDetailsData patching_cadence;
		public RatingDetailsData file_sharing;
		public RatingDetailsData insecure_systems;
		public RatingDetailsData server_software;
		public Desktop_software desktop_software;
		public Desktop_software mobile_software;
		public RatingDetailsData data_breaches;
		public Desktop_software mobile_application_security;
	}

	public class Desktop_software {
		public String name;
		public String rating;
		public String grade;
		public String percentile;
		public String grade_color;
		public String category;
		public Integer category_order;
		public Boolean beta;
		public Integer order;
	}

	public class Ratings {
		public String rating_date;
		public Integer rating;
		public String range;
		public String rating_color;
	}

    
    	public class Quota_details {
		public Integer quota_purchased;
		public Integer quota_used;
		public Integer quota_available;
	}
    @AuraEnabled(Cacheable=True)
    public static Boolean checkProductType(Id ProductId){
        if(ProductId==null || !String.isNotBlank(ProductId)){
            return false;
        }
        else{
            Product2 prod = [Select Id, Name from Product2 where Id=:ProductId];
            if(prod.Name == 'Cyber Standalone'){
                return True;
            }
            else{
                return false;
            }   
        }
        
    }
    @AuraEnabled()
    public static Opportunity getOppId(Id sobjectId){
        String sobjectType = sobjectId.getSObjectType().getDescribe().getName();
        if(sobjectType == 'Opportunity'){
            Opportunity opp = [Select Id , Service_to_Run__c, Product_Name__c, StageName  from Opportunity where Id=:sobjectId];
            return opp;
        }
        else{
            List<Quote_Process__c> quoProc = [Select id, Submission__c from Quote_Process__c where Id = : sobjectId];
            Opportunity opp = [Select Id , Service_to_Run__c, Product_Name__c, StageName from Opportunity where Id=:quoProc[0].Submission__c];
            return opp;
        }
    }
}