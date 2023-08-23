/***************************************************************************************************
    class: CoverageLineItemTriggerHandler
    test class: CoverageLineItemTriggerHandlerTest
    created date: 2019/8/20
    created by: Quan Tran
***************************************************************************************************/
public with sharing class CoverageLineItemTriggerHandler extends TriggerHandler {
    private List < CoveragesLineItem__c > oldDataList;
    private List < CoveragesLineItem__c > newDataList;
    private Map < Id, CoveragesLineItem__c > oldDataMap;
    private Map < Id, CoveragesLineItem__c > newDataMap;
    private static Map<Id, Quote> updateQuoteMap = new Map<Id, Quote>();

    public CoverageLineItemTriggerHandler() {
        this.oldDataList = (List < CoveragesLineItem__c > ) Trigger.old;
        this.newDataList = (List < CoveragesLineItem__c > ) Trigger.new;
        this.oldDataMap = (Map < Id, CoveragesLineItem__c > ) Trigger.oldMap;
        this.newDataMap = (Map < Id, CoveragesLineItem__c > ) Trigger.newMap;
        system.debug('inside con');
    }

   public override void beforeInsert() {
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);

    }

    public override void beforeUpdate() {
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }
     public override void afterInsert() {
        updateExcessLimit(this.newDataMap);
        updateCelTechnicalPremium(this.newDataList);
         updateQuoteStatus(this.newDataList,null);

         if(updateQuoteMap.Values().size() > 0) update updateQuoteMap.Values();
    }
    public override void afterUpdate() {
        updateQuoteStatus(this.newDataList,this.oldDataMap);
        updateExcessLimit(this.newDataMap);
        updateCelTechnicalPremium(this.newDataList);
        if(updateQuoteMap.Values().size() > 0) update updateQuoteMap.Values();

        handleUpdateSyncLimitDeductible(this.oldDataMap, this.newDataMap);
        
    }
    
    public override void afterdelete(){
       updateQuoteStatus(oldDataList,null);
    }
    
   public static void handleUpdateSyncLimitDeductible(Map<Id, CoveragesLineItem__c> oldDataMap,
														Map<Id,CoveragesLineItem__c> newDataMap) {
                                                            
        List<CoveragesLineItem__c> listUpdateCLI = new List<CoveragesLineItem__c>();
        Set<String> SyncFromCLI = new Set<String>();  
        Set<String> quoteSet = new Set<String>();                                    
        Map<String, CoveragesLineItem__c> mapupdateFromCLI = new Map<String, CoveragesLineItem__c>(); 
                                                            
		List<CoveragesLineItem__c> newSyncCLIvalues = [SELECT Id, Name, Quote__c, Option_Value_Default__c,
														Limits_Deductibles__r.Name 
														FROM CoveragesLineItem__c 
														WHERE Id IN : newDataMap.keySet()]; 
		
		for(CoveragesLineItem__c cli: newSyncCLIvalues) {
			
				if(oldDataMap.get(cli.Id).Option_Value_Default__c != cli.Option_Value_Default__c)
                {
				mapupdateFromCLI.put(cli.Limits_Deductibles__r.Name,cli);
                
				SyncFromCLI.add(cli.Limits_Deductibles__r.Name);
                quoteSet.add(cli.Quote__c);
                }
		}
        List<CoveragesLineItem__c> cliToUpdate = [SELECT Id, Limits_Deductibles__r.Name, Quote__c,Quote__r.Status,
                                                  Limits_Deductibles__r.Sync_From__c, Option_Value_Default__c,
                                                  Limits_Deductibles__r.Sync_From__r.Name
		                                          FROM CoveragesLineItem__c 
		                                          WHERE Limits_Deductibles__r.Sync_From__r.Name IN : SyncFromCLI
                                                  AND Quote__c IN : quoteSet 
                                                 ];
				
              if(!cliToUpdate.isEmpty())
         {                                              
       for (CoveragesLineItem__c cliUpdate : cliToUpdate)
       {
           if(mapupdateFromCLI.get(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name).Quote__c == cliUpdate.Quote__c){
               if(mapupdateFromCLI.containsKey(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name) ){
                   if(mapupdateFromCLI.get(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name).Option_Value_Default__c != null){
                
            
            if(cliUpdate.Option_Value_Default__c != mapupdateFromCLI.get(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name).Option_Value_Default__c)
            { 
			System.debug('cliUpdate.Option_Value_Default__c '+cliUpdate.Option_Value_Default__c);
           cliUpdate.Option_Value_Default__c = mapupdateFromCLI.get(cliUpdate.Limits_Deductibles__r.Sync_From__r.Name).Option_Value_Default__c;
           System.debug('cliUpdate.Option_Value_Default__c '+cliUpdate.Option_Value_Default__c);
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

   public static void updateExcessLimit(Map < Id, CoveragesLineItem__c > newDataMap) {

       // System.debug('oldDataMap' + oldDataMap);
        System.debug('newDataMap' + newDataMap);
        Set<ID> quoteId = new Set<ID>();
        Set<ID> existQuoteId = new Set<ID>();
        List<Quote> updateQuote = new List<Quote>();
        List<String> ExcessLimitDeductibles = new List<String>{'CelerityExcessLimit', 'UnderlyingExcessLimit'};
        List<CoveragesLineItem__c> CLIList = [SELECT Id, Name, Quote__c, Option_Value_Default__c,Quote__r.Status,
                                              Limits_Deductibles__r.LmtDedCode__c
                FROM CoveragesLineItem__c WHERE  Id IN: newDataMap.keySet() AND 
                Limits_Deductibles__r.LmtDedCode__c IN :ExcessLimitDeductibles ];
        
        if(CLIList.size()>0){
        for (CoveragesLineItem__c cli : CLIList)
          {
              quoteId.add(cli.Quote__c);
          } 
            
        
        Map<Id,Quote> mapQuote = new Map<Id,Quote>([Select Id,Celerity_Excess_Limit__c,Underlying_Excess_Limit__c, Celerity_Technical_Premium__c, Status
                                    From Quote WHERE Id IN : quoteId]);
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

        for (CoveragesLineItem__c cli: CLIList) {
            if(String.isNotBlank(cli.Option_Value_Default__c)){
          
                    if(cli.Limits_Deductibles__r.LmtDedCode__c =='CelerityExcessLimit')
                     mapQuote.get(cli.Quote__c).Celerity_Excess_Limit__c = Decimal.valueOf(cli.Option_Value_Default__c);
                    
                     if(cli.Limits_Deductibles__r.LmtDedCode__c == 'UnderlyingExcessLimit')
                     mapQuote.get(cli.Quote__c).Underlying_Excess_Limit__c = Decimal.valueOf(cli.Option_Value_Default__c);
            }
        }
                    if(mapQuote.values() != null)
              {
                   
                //update mapQuote.values();
               // AddToUpdateQuoteList(mapQuote.values());
              }
            
        
        }
    }
      public static void updateCelTechnicalPremium(List<CoveragesLineItem__c > newDataList) {

       // System.debug('oldDataMap' + oldDataMap);
        System.debug('newDataList' + newDataList);
          
        Set<ID> quoteId = new Set<ID>();
        Set<ID> existQuoteId = new Set<ID>();
        List<Quote> updateQuote = new List<Quote>();
        
        List<CoveragesLineItem__c> CLIList = [SELECT Id, Name, Quote__r.Layer__c, Quote__c, Coverage_Premium__c,Coverage_Product__c,Quote__r.Status
                             FROM CoveragesLineItem__c WHERE  Id IN: newDataList AND 
                             CoverageLineItemType__c  =:'Main Coverage' AND 
                           (Coverage__r.Name =:'Cyber Coverage' OR Coverage__r.Name =:'Miscellaneous Professional Liability')];
        system.debug('CLIList'+CLIList);
        if(CLIList.size()>0){
        for (CoveragesLineItem__c cli : CLIList)
          {
              
              quoteId.add(cli.Quote__c);
          } 
            
        
        Map<Id,Quote> mapQuote = new Map<Id,Quote>([Select Id,Celerity_Excess_Limit__c,Underlying_Excess_Limit__c, Celerity_Technical_Premium__c, Status
                                    From Quote WHERE Id IN : quoteId]);

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
        for (CoveragesLineItem__c cli: CLIList) {
            if(String.isNotBlank(cli.Coverage_Premium__c) && ((cli.Quote__r.Layer__c != 'Excess' && Trigger.isInsert) || Trigger.isUpdate)){ //check added by Vinay to bypass for Excess layer
                    
                    if(cli.Coverage_Product__c =='MPL')
                     mapQuote.get(cli.Quote__c).Celerity_Technical_Premium__c = Decimal.valueOf(cli.Coverage_Premium__c);
                    
                     if(cli.Coverage_Product__c =='Cyber')
                     mapQuote.get(cli.Quote__c).Celerity_Technical_Premium__c = Decimal.valueOf(cli.Coverage_Premium__c);
            }
        }
                    if(mapQuote.values() != null)
              {
                   system.debug('inside mapQuote '+mapQuote);
                    update mapQuote.values();
                    //AddToUpdateQuoteList(mapQuote.values());
              }
            
        
        }
    }
    
      private static void updateQuoteStatus(List<CoveragesLineItem__c> CoveragesLineItem,Map<Id,CoveragesLineItem__c > oldDataMap){
          Set<Id> quoteToInprogressIds = new Set<Id>();
          Set<Id> quoteToRatedIds = new Set<Id>();
          List<Quote> quoteToInProgressList = new List<Quote>();
          List<Quote> quoteToRatedList = new List<Quote>();
          system.debug('inside method');
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
              quoteToInProgressList = [SELECT Id, Status, OpportunityId, Product_Name__c 
                             FROM Quote WHERE Product_Name__c NOT IN ('Professional Indemnity','Private Company Combo') AND Id IN:quoteToInprogressIds];
          }
          
          if(!quoteToRatedIds.isEmpty()){
              quoteToRatedList = [SELECT Id, Status, OpportunityId, Product_Name__c 
                             FROM Quote WHERE Product_Name__c NOT IN ('Professional Indemnity','Private Company Combo') AND Id IN:quoteToRatedIds];
          }
          
          
          if(!quoteToRatedList.isEmpty()){
              for(Quote quo: quoteToRatedList){
                  if(quo.status == 'Quoted'){
                      quo.status = 'Rated';
                  }
              }
               //update quoteToRatedList;
               //AddToUpdateQuoteList(quoteToRatedList);
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
              
              //update quoteToInProgressList;
             // AddToUpdateQuoteList(quoteToInProgressList);
             for(Quote qt : quoteToInProgressList){
                if(updateQuoteMap.containsKey(qt.Id)){
                 updateQuoteMap.get(qt.Id).Status = qt.Status;
                }
                else{
                 updateQuoteMap.put(qt.Id, qt);
                }
            }
          }
    }

    // private static void AddToUpdateQuoteList(List<Quote> quoteList){
    //     for(Quote qt : quoteList){
    //         Boolean isQuoteAdded = false;
    //         for(Quote qt1 : quoteListToUpdate){
    //             if(qt.Id != qt1.Id){
    //                 isQuoteAdded = true;
    //             }
    //         }
    //         if(!isQuoteAdded) quoteListToUpdate.add(qt);
    //     }
    // }

}