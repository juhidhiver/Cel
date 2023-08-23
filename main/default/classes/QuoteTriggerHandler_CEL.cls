/**************************************************************************************************
 * Class Name: QuoteTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: Class to keep Aqueous related methods
 * Test Class: QuoteTriggerHandlerTest
 **************************************************************************************************/
public class QuoteTriggerHandler_CEL extends TriggerHandler{
	private List<Quote> oldDataList;
    private List<Quote> newDataList; 
    private Map<Id, Quote> newDataMap;
    private Map<Id, Quote> oldDataMap;
    boolean isPccQuote = false;
    
    public QuoteTriggerHandler_CEL(List<Quote> newDataList, List<Quote> oldDataList, 
                                         Map<Id, Quote> newDataMap, Map<Id, Quote> oldDataMap, Boolean isPccQuote){
                                             this.oldDataList = oldDataList;
                                             this.newDataList = newDataList;
                                             this.newDataMap = newDataMap;
                                             this.oldDataMap = oldDataMap;
                                             this.isPccQuote = isPccQuote;
                                         }

    public override void beforeInsert(){

        //Method to update Broker Name and Broker Email on Quote
        QuoteTriggerHandler_Common.updateQuoteWithBrokerName(newDataList);
        //Method to update Broker Name and Broker Email on Quote
        QuoteTriggerHandler_Common.updateCommission(newDataList);
        if(isPccQuote){
            //Method to generate opp combro product map used later in after context for adding coverage line item and rating modifier factors
            QuoteTriggerHandler_Common.generateSubmissionPoliMap(newDataList);
            //Method to validate if Quote Coverage Product Options matched the ones selected on Submission Console.
            QuoteTriggerHandler_Common.checkValidQuoteComboCoverageOptions(newDataList);
        }
        //Method to populate Pending_or_Prior_Proceedings_Date__c on Quote
        pendingOrPriorProceedingsDate(newDataList);


    }

    public override void beforeUpdate(){

        //Method to update Broker Name and Broker Email on Quote
        QuoteTriggerHandler_Common.updateQuoteWithBrokerName(newDataList);
        if(isPccQuote){
            //Method to generate opp combro product map used later in after context for adding coverage line item and rating modifier factors
            QuoteTriggerHandler_Common.generateSubmissionPoliMap(newDataList);
            //Method to validate if Quote Coverage Product Options matched the ones selected on Submission Console.
            QuoteTriggerHandler_Common.checkValidQuoteComboCoverageOptions(newDataList);
        }
        //Method to add error on Quote if status = 'Quoted\' or \'Presented\' or \'Bound\'
        QuoteTriggerHandler_Common.lockEditOnQuote(newDataList,oldDataMap);
        //Method to send email to Submitter on Approval/Rejection
        QuoteTriggerHandler_Common.sendEmailToApprovalSubmitter(newDataList,oldDataMap);
        //Method to set Force_Rating__c whici is sent to and used by M/W.
        QuoteTriggerHandler_Common.checkForceRating(newDataList,oldDataMap);
        //Method to add error when Opportunity StageName in Declined state, Quote should be Readonly 
        declinedsubmissionQuote(newDataList);
        //set default ERP duration and Rate Charged for PCC Quotes
        setERPDurationAndrate(newDataList);

    }

    public override void afterInsert(){
        //Fetching quote list with accountId field populated as issue with SF Standard Quote object not populating this field.
        List<Quote> quotes = QuoteQueryUtil.fetchQuoteInfo(newDataList);
        
        //Method to create quote premium when related submission's poli is marked as cleared
        processQuotePremiums(newDataList);
        //Method to Create CoverageLineItems from Coverage for each Quote
        QuoteTriggerHandler_Common.AddCoverageLineItems(quotes); 
        //Method to add Quote Locations 
        QuoteTriggerHandler_Common.createPrimaryLocation(newDataList);
        //Method to create rating modifier factor from template for each quote
        QuoteTriggerHandler_Common.AddRatingModifierFactor(newDataList); 
        //Method to create Subjectivities for each quote
        createSubjectivityByDefaultCelerity(quotes);
        
    }

    public override void afterUpdate(){

        //Method to generate Quote Documanet for each quote
        QuoteTriggerHandler_Common.generatedQuoteDocument(oldDataMap, newDataMap);
        //Method to create Coverage Line Items from Coverage for each Quote
        QuoteTriggerHandler_Common.updateCoverageLineItems(newDataList, oldDataMap);
        //Method to Count open Subjectivities on quote and update on Policy
        QuoteTriggerHandler_Common.countOpenSubjectivityOnBoundQuote(newDataList);
        //Method to update Coverage_Effective_Date__c of CoveragesLineItem__c when quote is update
        QuoteTriggerHandler_Common.updateCliEffectiveDate(newDataList, oldDataMap);
        //update Quote LastSource
      
        updateLastSource(newDataList);
        //Method to make sync Callout
        QuoteTriggerHandler_Common.syncCallout(newDataList,oldDataMap);
    }

    public override void beforeDelete(){}

     

    /*************************************************
    * Author: 
    * Date: 
    * Params: celerityQuotes - List of New Quotes
    * Return: none
    * Description: Method to populate Pending_or_Prior_Proceedings_Date__c on Quote
    * Revision:
    *************************************************/
    public static void pendingOrPriorProceedingsDate(List<Quote> celerityQuotes){
        
         
        for(Quote quote : celerityQuotes){
        
            if(quote.Quote_Type__c == 'New Business' && quote.Effective_Date__c != null && quote.Pending_or_Prior_Proceedings_Date__c == null)
                quote.Pending_or_Prior_Proceedings_Date__c = quote.Effective_Date__c;
        
        }
        
    }

    /**************************************************************************
    * Method Name: declinedsubmissionQuote
    * Author: Ashik Zahir
    * Date: 27-July-2021
    * Params: List<Quote> celerityQuotes
    * Description:  Method to add error when Opportunity StageName in Declined state, Quote should be Readonly 
    ***************************************************************************/
    public static void declinedsubmissionQuote(List<Quote> celerityQuotes){
        try{
            Map<Id, Quote> newQuotesMap = (Map<Id, Quote>) Trigger.newMap;
            for(Quote q : [Select Id, Opportunity.StageName from Quote where ID IN :celerityQuotes]){
                if(q.Opportunity.StageName == 'Declined'){
                        newQuotesMap.get(q.Id).addError('Cannot Modify the Rejected Quote');
                }
            }            
        }catch (Exception ex) {
            System.debug('@@@Exception'+ ex.getMessage());
            String errorMsg = 'Failed to edit Quote! <br/>Please contact your administators.';
            for(Quote item : (List<Quote>)Trigger.new ){
                item.addError(errorMsg);
            }
        }             
    }

    /*************************************************
    * Author: 
    * Date: 
    * Params: quotes - list of Quotes
    * Return: Void
    * Description: Method to create Subjectivities for each quote
    * Revision: 
    *************************************************/
    public static void createSubjectivityByDefaultCelerity(List<Quote> quotes) {
        List<Subjectivity__c> subjectivityListByDefault = new List<Subjectivity__c>();
        List<String> quoteProducts = new List<String>();

        for(Quote qt : quotes){
            if(qt.Product_Name__c != null){
                quoteProducts.add(qt.Product_Name__c);
            }
        }
        
        List<Subjectivity_Template__c> subjTemplate = [SELECT Id, Name,State__c,Subjectivity_Name__c,Product__c,Subjectivity_Text__c,
                                                       Stage__c, Layer__c,Applicable_Products__c
                                                       FROM Subjectivity_Template__c 
                                                       // added by Rinku 06 Dec 2022 MTA-74
                                                       WHERE Default_Load__c = True and  Product__c =: GlobalVariables.RT_NAME_CELERITY];
        											// commented by Rinku 06 Dec 2022 MTA-74
                                                     //  WHERE Subjectivity_Name__c ='Completed Surplus Lines Tax Form' limit 1];
       
        //quotes = QuoteQueryUtil.fetchQuoteInfo(quotes);
        
        Set<Id> accountIds = New Set<Id>();
        for( Quote qt : quotes ){
            accountIds.add(qt.AccountId);
        }
        
        Map<Id,Account> accMap = AccountQueryUtil.fetchAccountInfo(accountIds);
        
        if( !subjTemplate.isEmpty() ){
            for( Quote quote : quotes ){
                //added a condition to check if the quote is created from Shop x it should not add default subjectivity to it.[55938] - JUHI
                if(quote.Opportunity.LeadSource != 'Shopping X'){
                system.debug( quote.Layer__c );
                for( Subjectivity_Template__c subTemp : subjTemplate ){
                    if(subTemp.Applicable_Products__c != null && quote.Product_Name__c != null){
                        List<String> subjProducts =  subTemp.Applicable_Products__c.split(';');
                        boolean prodMatch = false;
                        for(String prod : subjProducts){
                            if(quote.Product_Name__c.contains(prod)){
                                prodMatch = true;
                            }
                        }
                        if(!prodMatch) continue;
                    }
                    if( String.isEmpty( subTemp.Layer__c ) || subTemp.Layer__c.containsIgnoreCase( quote.Layer__c ) ){// added by jai MTA-95
                        if( String.isEmpty(subTemp.State__c) ){
                            subjectivityListByDefault.add(prepareSubjectivityData(quote, subTemp));
                        }else if( accMap.containsKey(quote.AccountId) && subTemp.State__c.contains(accMap.get(quote.AccountId).BillingStateCode) ){
                                subjectivityListByDefault.add(prepareSubjectivityData(quote, subTemp));  
                        }   
                    }                
                }
             }
          }  
        }
        system.debug('subjectivityListByDefault '+subjectivityListByDefault);
        
       /* if(!subjTemplate.isEmpty()){
            for(Quote quote: quotes){
                Subjectivity__c subRecord = new Subjectivity__c(); 
                subRecord.Quote__c = quote.Id;
                subRecord.Subjectivity__c = subjTemplate[0].Subjectivity_Name__c;
                subRecord.Subjectivity_Text__c = subjTemplate[0].Subjectivity_Text__c;
                subRecord.Stage__c =subjTemplate[0].Stage__c ;
                subRecord.Cleared__c = false;
                subRecord.Cleared_Date__c = null;
                subRecord.Subjectivity_Template__c = subjTemplate[0].Id;

                // commented by Rinku 06 Dec 2022 MTA-74
               /* if( quote.Product_Name__c == GlobalVariables.PROD_NAME_FOR_CYBER ||
                    quote.Product_Name__c == GlobalVariables.PROD_NAME_FOR_MPL ||
                    quote.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PCC
                ){*/
                  //  subRecord.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
               // commented by Rinku 06 Dec 2022 MTA-74
                /* }else if(quote.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PI){
                    subRecord.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS).getRecordTypeId();
                }*/

               // subjectivityListByDefault.add(subRecord);
          //  } 
       // }
        
        if(!subjectivityListByDefault.isEmpty()) insert subjectivityListByDefault;
        
    }
    
    public static Subjectivity__c prepareSubjectivityData( Quote quote, Subjectivity_Template__c subjTemplate){
        Subjectivity__c subRecord = new Subjectivity__c(); 
        subRecord.Quote__c = quote.Id;
        subRecord.Subjectivity__c = subjTemplate.Subjectivity_Name__c;
        subRecord.Subjectivity_Text__c = subjTemplate.Subjectivity_Text__c;
        subRecord.Stage__c =subjTemplate.Stage__c ;
        subRecord.Cleared__c = false;
        subRecord.Cleared_Date__c = null;
        subRecord.Subjectivity_Template__c = subjTemplate.Id;        
        subRecord.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_CELERITY).getRecordTypeId();
        return subRecord; 
    }

    /*************************************************
    * Method Name: processQuotePremiums
    * Author:
    * Date: 14th Dec 2021
    * Params: List<Quote>
    * Return: 
    * Exceptions:
    * Description: Method to create quote premium when related submission's poli is marked as cleared
    * Revision: 
     *************************************************/
    private static void processQuotePremiums(List<Quote> quotes){
        Set<id> submissionIds = new Set<Id>();
        List<Quote_Premium__c> quotePremiums = new List<Quote_Premium__c>();
        for(Quote qt : quotes){
            if(qt.Product_Name__c == System.Label.Product_Name_for_PCC){
                submissionIds.add(qt.Opportunityid);
            }
        }
        if(!submissionIds.isEmpty()){
            // added by RINKU SAINI In Query Util 3rd Jan 2022
            Map<id,Opportunity> submissionMap = new Map<id,Opportunity>(OpportunityQueryUtil.fetchSubmissionsFromIdswithProductOption(submissionIds));
            for(Quote qt : quotes){
                if(submissionMap.containsKey(qt.OpportunityId)){
                    for(Product_Option_Line_Item__c poli : submissionMap.get(qt.OpportunityId).Product_Option_Line_Items__r){
                        Quote_Premium__c quotePrem = new Quote_Premium__c();
                        quotePrem.Quote__c = qt.id;
                        quotePrem.Product_Name__c = poli.Product__r.Name;
                        quotePremiums.add(quotePrem);
                    }
                }
            }
        }
        if(!quotePremiums.isEmpty())
            insert quotePremiums;
    }


    /*************************************************
    * Method Name: setERPDurationAndrate
    * Author: Jai
    * Date: 17/02/2022
    * Params: List<Quote>
    * Return: 
    * Exceptions:
    * Description: Method to set default ERP Duration and Rate Charged for PCC quotes
    * Revision: 
     *************************************************/
    public static void setERPDurationAndrate( List<Quote> quotes ){
        String productName = GlobalVariables.PROD_NAME_FOR_PCC;
        Product_Setting__mdt mdt = [SELECT DeveloperName, MasterLabel, Active__c, Applicable_ERP_Duration__c, Applicable_Rate_Charged__c,Applicable_ERP_Duration_Rate_Charged__c 
                                  FROM Product_Setting__mdt 
                                  WHERE MasterLabel = :productName Limit 1];
        
        String applicableDuration = '';
        String applicableRate = '';

        if( String.isNotBlank(mdt.Applicable_ERP_Duration__c) ){
            applicableDuration = mdt.Applicable_ERP_Duration__c.split(',')[0];
        
            if( String.isNotBlank(mdt.Applicable_ERP_Duration_Rate_Charged__c) ){
                list<Object> dAndRList = (list<Object>)JSON.deserializeUntyped(mdt.Applicable_ERP_Duration_Rate_Charged__c);
                map<String,String> dAndRmap = new map<String,String>();
                for( Object o : dAndRList ){
                    map<String,Object> t = (map<String,Object>)o;
                    dAndRmap.put( (String)t.get('ERPDuration'), (String)t.get('RateCharged') );
                }
                if( dAndRMap != null && dAndRMap.containsKey(applicableDuration) ){
                    applicableRate = (String) dAndRMap.get(applicableDuration);
                }
            }
            for( Quote q : quotes ){
                if( q.Product_Name__c == GlobalVariables.PROD_NAME_FOR_PCC ){
                    if( String.isBlank( q.ERP_Duration__c)  ){
                        q.ERP_Duration__c = applicableDuration;
                    }
                    if( q.Rate_Charged__c == null ){
                        q.Rate_Charged__c = Decimal.valueOf(applicableRate);
                    }
                }
            }
        }
    }
    
    /*************************************************
    * Method Name: updateLastSource
    * Author:
    * Date: 29 Jul 2022
    * Params: List<Quote>
    * Return: 
    * Exceptions:
    * Description: Method to update LastSource in Opportunity for QuoteSync
    * Revision: 
     *************************************************/
   private static void updateLastSource(List<Quote> newQuote){
    List<Quote> quotes = QuoteQueryUtil.fetchQuoteInfo(newQuote);
    Map<Id,Quote> Oppmap = new Map<Id,Quote>();
    List<Opportunity> opplist = new List<Opportunity>();
     try {
        system.debug(quotes);

        // get opportunity ids
        for (Quote item : quotes) {
            system.debug(item.Opportunity);
            Oppmap.put(item.OpportunityId, item);
        }
        system.debug('Oppmap->'+Oppmap);
        for(Opportunity o : [Select Id, Name, LastSource__c,LastModifiedBy.Name from Opportunity where Id IN: Oppmap.keyset()]){
          system.debug('o-->'+o.LastSource__c);
          system.debug('MAP-->'+Oppmap.get(o.id).LastModifiedBy.Name);
          if(Oppmap.get(o.Id).LastModifiedBy.Name != System.Label.Integration_Username && o.LastSource__c != 'UnderWriter' ){
            o.LastSource__c = 'UnderWriter';
           }
           else if(Oppmap.get(o.Id).LastModifiedBy.Name == System.Label.Integration_Username && o.LastSource__c != 'ShopX'){
            o.LastSource__c = 'ShopX'; 
           }else{}
           opplist.add(o);
           system.debug(' LastSource__c-->'+opplist);
           TriggerHandler.bypass('OpportunityTriggerHandler');
           TriggerHandler.bypass('SubmissionTriggerBaseHandler');
           if(!opplist.isEmpty()) update opplist;
           TriggerHandler.clearBypass('OpportunityTriggerHandler');
           TriggerHandler.clearBypass('SubmissionTriggerBaseHandler');
        }
    }catch(Exception e){
      ErrorLogsUtilityHelper.logError(e, 'QuoteTriggerHandler_Cel.updateLastSource', CommonUtil.getExceptionMessage(e), '', 'Cel_Exceptions', '', String.valueOf(e.getLineNumber()));         
      System.debug('Failed. Error = ' + e.getMessage() );
    } 
  } 
}