/**************************************************************************************************
 * Class Name: CommonCoverageLineItemUtil
 * Author: 
 * Date: 
 * Description: Class to keep common methods
 * Test Class : CoverageLineItemTriggerTest
 **************************************************************************************************/
public with sharing class CommonCoverageLineItemUtil {


    /*************************************************
    * Method Name: handleUpdateSyncLimitDeductible
    * Author: 
    * Date: 
    * Params: Map<Id, CoveragesLineItem__c>, Map<Id, CoveragesLineItem__c>
    * Return: 
    * Exceptions:
    * Description: updating Option_Value_Default__c of CLI
    * Revision: 
     *************************************************/
    public static void handleUpdateSyncLimitDeductible(Map<Id, CoveragesLineItem__c> oldDataMap,
                                                        Map<Id,CoveragesLineItem__c> newDataMap) {
                                                            
        List<CoveragesLineItem__c> listUpdateCLI = new List<CoveragesLineItem__c>();
        Set<String> SyncFromCLI = new Set<String>();  
        Set<String> quoteSet = new Set<String>();                                    
        Map<String, CoveragesLineItem__c> mapupdateFromCLI = new Map<String, CoveragesLineItem__c>(); 
                                                            
        List<CoveragesLineItem__c> newSyncCLIvalues = CoverageLineItemQueryUtil.fetchNewCLIs(newDataMap.keySet()); 
        
        for(CoveragesLineItem__c cli: newSyncCLIvalues) {
            
            if(oldDataMap.get(cli.Id).Option_Value_Default__c != cli.Option_Value_Default__c) {
                mapupdateFromCLI.put(cli.Limits_Deductibles__r.Name,cli);
                SyncFromCLI.add(cli.Limits_Deductibles__r.Name);
                quoteSet.add(cli.Quote__c);
            }
        }
        List<CoveragesLineItem__c> cliToUpdate = CoverageLineItemQueryUtil.fetchChangedCLIs(quoteSet,SyncFromCLI);
                
        if(!cliToUpdate.isEmpty()){                                              
            for (CoveragesLineItem__c cliUpdate : cliToUpdate){
                if(mapupdateFromCLI.get(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name).Quote__c == cliUpdate.Quote__c){
                    if(mapupdateFromCLI.containsKey(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name) ){
                        if(mapupdateFromCLI.get(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name).Option_Value_Default__c != null){
                            if(cliUpdate.Option_Value_Default__c != mapupdateFromCLI.get(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name).Option_Value_Default__c){ 
                                cliUpdate.Option_Value_Default__c = mapupdateFromCLI.get(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name).Option_Value_Default__c;
                                listUpdateCLI.add(cliUpdate);
                            }

                        }
                    }
                }
            }
        }
        if(!listUpdateCLI.isEmpty()){
            update listUpdateCLI;       
        }
    }

    /*************************************************
    * Method Name: updateExcessLimit
    * Author: 
    * Date: 
    * Params: Map<Id, CoveragesLineItem__c>
    * Return: Map<Id, Quote>
    * Exceptions:
    * Description: update excess limit on quote
    * Revision: 
     *************************************************/
    public static Map<Id, Quote> updateExcessLimit(Map < Id, CoveragesLineItem__c > newDataMap) {

         Set<ID> quoteIds = new Set<ID>();
         Set<ID> existQuoteId = new Set<ID>();
         List<Quote> updateQuote = new List<Quote>();
         List<String> ExcessLimitDeductibles = new List<String>{'CelerityExcessLimit', 'UnderlyingExcessLimit'};
         Map<Id, Quote> updateQuoteMap = new Map<Id, Quote>();
         List<CoveragesLineItem__c> CLIList = CoverageLineItemQueryUtil.fetchExcessCLIs(newDataMap, ExcessLimitDeductibles);
         
        if(CLIList.size()>0){
            for (CoveragesLineItem__c cli : CLIList){
               quoteIds.add(cli.Quote__c);
            } 
            //query quotes
            String queryFields = 'Id,Celerity_Excess_Limit__c,Underlying_Excess_Limit__c, Celerity_Technical_Premium__c, Status, Product_Name__c';
            Map<Id,Quote> mapQuote = new Map<Id,Quote>( QuoteQueryUtil.fetchQuotesForQuoteIds(quoteIds, queryFields) );

            //can be optimised/removed
            for(Quote qt : mapQuote.values()){
                if(updateQuoteMap.containsKey(qt.Id)){
                    existQuoteId.add(qt.Id);
                }
                else{
                    updateQuoteMap.put(qt.Id, qt);
                }
            }
 
            for(Id existingId : existQuoteId){
                mapQuote.put(existingId, updateQuoteMap.get(existingId));
            }
            //can be optimised/removed

            for (CoveragesLineItem__c cli: CLIList) {
                if(String.isNotBlank(cli.Option_Value_Default__c)){
                     if(cli.Limits_Deductibles__r.LmtDedCode__c =='CelerityExcessLimit'){
                        mapQuote.get(cli.Quote__c).Celerity_Excess_Limit__c = Decimal.valueOf(cli.Option_Value_Default__c);
                    }
                    if(cli.Limits_Deductibles__r.LmtDedCode__c == 'UnderlyingExcessLimit'){
                        mapQuote.get(cli.Quote__c).Underlying_Excess_Limit__c = Decimal.valueOf(cli.Option_Value_Default__c);
                    }
                }
            }
        }
        return updateQuoteMap;
    }


    /*************************************************
    * Method Name: updateQuoteStatus
    * Author: 
    * Date: 
    * Params: List<CoveragesLineItem__c>, Map<Id, CoveragesLineItem__c>
    * Return: Map<Id, Quote>
    * Exceptions:
    * Description: update quote status basis pf CLI updated with Rating check
    * Revision: 
     *************************************************/
    public static Map<Id, Quote> updateQuoteStatus(List<CoveragesLineItem__c> CoveragesLineItem,Map<Id,CoveragesLineItem__c > oldDataMap){
        Set<Id> quoteToInprogressIds = new Set<Id>();
        Set<Id> quoteToRatedIds = new Set<Id>();
        List<Quote> quoteToInProgressList = new List<Quote>();
        List<Quote> quoteToRatedList = new List<Quote>();
        Map<Id, Quote> updateQuoteMap = new Map<Id, Quote>();

        for(CoveragesLineItem__c cov:CoveragesLineItem){
            if(Trigger.isUpdate){
                if(cov.Rating__c == true && oldDataMap.get(cov.Id).Rating__c != true){
                    quoteToInprogressIds.add(cov.Quote__c); 
                }else if(cov.Rating__c == false){
                    quoteToRatedIds.add(cov.Quote__c);
                }
            }else if(Trigger.isInsert){
                if(cov.Rating__c == true){
                    quoteToInprogressIds.add(cov.Quote__c);
                }else{
                    quoteToRatedIds.add(cov.Quote__c);
                } 
            } else if(Trigger.isDelete){
                if(cov.Rating__c == true){
                    quoteToInprogressIds.add(cov.Quote__c);
                }else{
                    quoteToRatedIds.add(cov.Quote__c);
                } 
            } 
        }
        
        if(!quoteToInprogressIds.isEmpty()){
            quoteToInProgressList = QuoteQueryUtil.fetchNonPIandPCCQuotes(quoteToInprogressIds);
        }
        
        if(!quoteToRatedIds.isEmpty()){
            quoteToRatedList = QuoteQueryUtil.fetchNonPIandPCCQuotes(quoteToRatedIds);
        }
        
        
        if(!quoteToRatedList.isEmpty()){
            for(Quote quo: quoteToRatedList){
                if(quo.status == 'Quoted'){
                    quo.status = 'Rated';
                }
            }
             
            for(Quote qt : quoteToRatedList){
                if(updateQuoteMap.containsKey(qt.Id)){
                    updateQuoteMap.get(qt.Id).Status = qt.Status;
                }
                else{
                    updateQuoteMap.put(qt.Id, qt);
                }
            }
        }
        
        if(!quoteToInProgressList.isEmpty()){
            for(Quote quo: quoteToInProgressList){
                if(quo.status == 'Rated' || quo.status == 'Quoted'){
                    quo.status = 'In Progress';
                }
            }
            
            for(Quote qt : quoteToInProgressList){
                if(updateQuoteMap.containsKey(qt.Id)){
                    updateQuoteMap.get(qt.Id).Status = qt.Status;
                }
                else{
                    updateQuoteMap.put(qt.Id, qt);
                }
            }
        }
        return updateQuoteMap;
    }

}