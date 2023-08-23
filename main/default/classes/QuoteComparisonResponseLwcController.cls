/**
 * @File Name          : quoteComparisonLWC_HangController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Vinayesh
 * @Last Modified On   : 10-01-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    3/16/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class QuoteComparisonResponseLwcController {
     
    @AuraEnabled
    public static ResultResponse getMainColumns(String rowValues){
        ResultResponse response = new ResultResponse();
        
        try {
            System.debug('row values: ' + rowValues);
            ListRowTittleWrapper listRowTitles = (ListRowTittleWrapper) JSON.deserialize(rowValues, ListRowTittleWrapper.class);
            //List<QuoteCompareItemWrapper> listCompareItem = (List<QuoteCompareItemWrapper>)System.JSON.deserialize(rowValues, List<QuoteCompareItemWrapper>.class);
            System.debug('listRowTitles: ' + listRowTitles);
            List<QuoteCompareItemWrapper> listCompareItem = listRowTitles.compareItems;
            System.debug('listCompareItem: ' + listCompareItem);
            response.isSuccess = true;
            //response.data = mainColWrappers;
            response.data = listCompareItem;
        } catch (Exception ex) {
            System.debug('@@@Exception: ' + ex.getMessage());
            response.isSuccess = false;
            response.errors.add('@@@Exception: ' + ex.getMessage());
            response.data = null;
        }
        return response;
    }

    @AuraEnabled
    public static ResultResponse getMainTitles(String submissionId, Boolean isPrimaryQuote){
        ResultResponse response = new ResultResponse();
        List<RowTitleWrapper> rowTitleWrapperList = new List<RowTitleWrapper>();

        response.data = getListRowTittleWrapper(submissionId,isPrimaryQuote);
        response.isSuccess = true;
        return response;
    }

    public class MainColumnWrapper{
        @AuraEnabled public Quote mainItem {get; set;}
        @AuraEnabled public List<RowWrapper> rowWrappers {get; set;}
        @AuraEnabled public String quoteId {get; set;}

        MainColumnWrapper(Quote quote){
            this.mainItem = quote;
        }
    }
    public class RowWrapper{
        @AuraEnabled public String rowItem {get; set;}
        @AuraEnabled public String rowTitleBelong {get; set;}
        @AuraEnabled public Boolean isField {get; set;}
        RowWrapper(String rowItem){
            this.rowItem = rowItem;
            this.isField = false;
        }

    }

    public class RowTitleWrapper{
        @AuraEnabled public String mainTitle {get; set;}
        @AuraEnabled public List<String> subtitles {get; set;}
        
        RowTitleWrapper(String mainTitle, List<String> subtitles){
            this.mainTitle = mainTitle;
            this.subtitles = subtitles;
        }
    }
    
    public class ListRowTittleWrapper {
        @AuraEnabled public List<RowTitleWrapper> listRowTitles {get; set;}
        //@AuraEnabled public List<List<RowWrapper>> columnValues {get; set;}
        @AuraEnabled public List<QuoteCompareItemWrapper> compareItems {get; set;}

        public ListRowTittleWrapper(List<RowTitleWrapper> titles, List<QuoteCompareItemWrapper> compareItems) {
            this.listRowTitles = titles;
            this.compareItems = compareItems;
        }
    }
    //getListRowTittleWrapperBackUp
    //getListRowTittleWrapper
    public static ListRowTittleWrapper getListRowTittleWrapper(String submissionId, Boolean isPrimaryQuote) {
        system.debug('isPrimaryQuote==>'+isPrimaryQuote);
         system.debug('submissionId==>'+submissionId);
     
         String layerName = isPrimaryQuote? 'Primary' : 'Excess';
     
        QuoteComparePageGenericController.QuoteResultItemWrapper obj = new QuoteComparePageGenericController().getQuoteResultItemWrapper(submissionId,'Rate Quotes',layerName);
         System.debug('Rate Quote Compare Items' + JSON.serialize(obj.quoteCompareItems));
        //sectionWrapper.setSectionSettingWrapper(submission, listSection);
        List<RowTitleWrapper> rowTitles = new List<RowTitleWrapper>();
        // List<List<String>> quoteValues = new List<List<String>>();
        for(Integer i = 0; i < obj.mainSections.size(); i++) {
            List<String> subTitle = new List<String>();

            for(Integer j = 0; j < obj.mainSections[i].fields.size(); j++) {
                subTitle.add(obj.mainSections[i].fields[j].sourceFieldLabel);
        
            }
            for(Integer j = 0; j < obj.mainSections[i].subSections.size(); j++) {
                subTitle.add(obj.mainSections[i].subSections[j].name);
  
                for(Integer k = 0; k < obj.mainSections[i].subSections[j].fields.size(); k++) {
                    subTitle.add(obj.mainSections[i].subSections[j].fields[k].sourceFieldLabel);
 
                }
            }
            RowTitleWrapper row = new RowTitleWrapper(obj.mainSections[i].name, subTitle);
            rowTitles.add(row);
        }

        ListRowTittleWrapper lstRowTitles = new ListRowTittleWrapper(rowTitles, obj.quoteCompareItems);
        return lstRowTitles;
    }


    public static List<Quote> sortListQuote(List<Quote> listQuotes, List<String> quoteIds) {
        List<Quote> result = new List<Quote>();
        Integer index = 0;
        for(Integer i = 0; i < listQuotes.size(); i++) {
            if(listQuotes[i].Id == quoteIds[index]) {
                result.add(listQuotes[i]);
                index++;
                i = -1;
                if(index >= quoteIds.size())
                    break;
            }
        }
        return result;
    }
    @AuraEnabled
    public static ResultResponse createInitQuote(String opportunityId,String quoteLayer,String binderRecordObj,Boolean quoteComingThroughEvent){
        ResultResponse result = new ResultResponse();
        try{
            System.debug('quoteLayer-->'+quoteLayer);            
            List<Opportunity> opps = [select Id,Name,StageName,Policy__c, Product_Name__c, Expiration_Date__c From Opportunity where Id = :opportunityId];
            List<Quote> quoteRecords = new List<Quote>();
            quoteRecords = getQuoteRecords(opps[0]);
            if(quoteRecords.isEmpty() && (quoteLayer == 'undefined' || quoteLayer == null)){
                System.debug('quoteLayer INSIDE -->'+quoteLayer);
                result.isSuccess = false;
                result.data = opportunityId;
                result.errors.add('Please choose a Quote Layer on Underwriting Analysis Tab');
                return result;
            }          
            //if(quoteRecords.isEmpty()){  quoteRecords.isEmpty() && 
            if(!(quoteLayer == 'undefined' || quoteLayer == null || quoteLayer == '') && ((opps[0].Product_Name__c != 'Professional Indemnity' && quoteComingThroughEvent) || //working as expected for Celerity
               (opps[0].Product_Name__c == 'Professional Indemnity' && quoteComingThroughEvent))){//41767 for Aqueous
                   Quote newQuote =  QuoteComparePageGenericController.createNewQuote(opportunityId,null,quoteLayer);
                   if(String.isNotBlank(binderRecordObj) && opps[0].Product_Name__c == 'Professional Indemnity'){
                       Master_Binder__c masterBinder = (Master_Binder__c)JSON.deserialize(binderRecordObj, Master_Binder__c.class);
                       newQuote.Master_Binder__c = masterBinder.Id;
                       newQuote.MGA_Commission__c = masterBinder.MGA_Commission__c;
                       Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(newQuote);
                       newQuote.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                       if(newQuote.Layer__c != 'Excess')	newQuote.IPID_Document__c = quoteDoc.IPID_Document__c;  	                    
                   }
                   System.debug('New Quote Before Insert-->'+newQuote);
                   insert newQuote;
                   System.debug('New Quote-->'+newQuote);
                   result.data = newQuote.Id;
                   result.isSuccess = true;
                   result.extraData = newQuote.Layer__c;
                   return  result;
               }
            else if(!quoteRecords.isEmpty() && quoteRecords[0].Quote_Type__c == 'Renewal'){
                result.data = quoteRecords[0].Id;
                // result.isSuccess = true;
                result.extraData = getDefaultLayer(quoteRecords);
                return  result;
            }
            if(!quoteRecords.isEmpty()){
                //result.isSuccess = true;
                result.data = getDefaultLayer(quoteRecords);
                result.extraData = getDefaultLayer(quoteRecords);
            }
            result.errors.add('Quote Is Exist');
            
            return result;
        }catch (DMLException ex){
            result.errors.add(ex.getDmlMessage(0));
            return result;
        }catch (Exception ex){
            System.debug('ex-->'+ex);
            result.errors.add(ex.getMessage());
            return result;
        }
    }
    
    public static String getDefaultLayer(List<Quote> quoteRecords){
        String quoteLayer = null;
        if(!quoteRecords.isEmpty()){
            for(Quote quo: quoteRecords){
                if(quo.Layer__c == 'Primary'){
                    quoteLayer = quo.Layer__c;
                    return quoteLayer;
                }else{
                    quoteLayer = quo.Layer__c;
                }
            }
        }
        return quoteLayer;
    }
    
	public static List<Quote> getQuoteRecords(Opportunity submission){
		List<Quote> results = new List<Quote>();
		if(submission.StageName == 'Closed Won') {
			List<Quote> boundQuotes =  [SELECT Id, name,Quote_Type__c, status, Rating_Status__c, Last_Quote_Version__c, Layer__c
											FROM Quote
											WHERE OpportunityId = :submission.Id
											AND Status = 'Bound'                                        	
											ORDER BY Endorsement_Quote_Bound_Date__c Desc LIMIT 1];
			List<Quote> amendmentQuotes = [SELECT Id, name,Quote_Type__c, status, Rating_Status__c, Last_Quote_Version__c, Layer__c
											FROM Quote
											WHERE OpportunityId = :submission.Id                                            
											AND  Status != 'Bound' AND Status != 'Closed'
											AND Status != 'Rejected'  ORDER BY CreatedDate desc];
            
            if(!boundQuotes.isEmpty()) {
                results.add(boundQuotes[0]);
            }
			results.addAll(amendmentQuotes);
		}
		else{
            if(submission.Product_Name__c == 'MPL Standalone' ||  submission.Product_Name__c == 'Cyber Standalone' ||  submission.Product_Name__c == 'Private Company Combo'){
			results = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c
                                FROM Quote
								WHERE OpportunityId = :submission.Id                       			
								AND Status != 'Closed'
								ORDER BY CreatedDate];
            }else{
            results = [SELECT Id, name, status, Rating_Status__c, Last_Quote_Version__c, Quote_Type__c, Layer__c
                                FROM Quote
								WHERE OpportunityId = :submission.Id                       			
								AND Status != 'Closed'
								AND Status != 'Rejected'  ORDER BY CreatedDate];
            }
		}
		return results;
	}
}