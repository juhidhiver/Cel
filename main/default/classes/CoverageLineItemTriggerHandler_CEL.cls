/**************************************************************************************************
 * Class Name: CoverageLineItemTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: Class to keep Celerity related  common methods
 * Test Class : CoverageLineItemTriggerTest
 **************************************************************************************************/
public class CoverageLineItemTriggerHandler_CEL extends TriggerHandler {


    private List<CoveragesLineItem__c> oldDataList;
    private List<CoveragesLineItem__c> newDataList; 
    private Map<Id, CoveragesLineItem__c> newDataMap;
    private Map<Id, CoveragesLineItem__c> oldDataMap; 

    Map<Id, Quote> updateQuoteMap = new Map<Id, Quote>();
    
    public CoverageLineItemTriggerHandler_CEL(List<CoveragesLineItem__c> newDataList, List<CoveragesLineItem__c> oldDataList, 
                                         Map<Id, CoveragesLineItem__c> newDataMap, Map<Id, CoveragesLineItem__c> oldDataMap){
                                             this.oldDataList = oldDataList;
                                             this.newDataList = newDataList;
                                             this.newDataMap = newDataMap;
                                             this.oldDataMap = oldDataMap;
                                         } 

	public override void beforeInsert()	{
        //filterEndorsement(newDataList);
        // Generate Azure Id before insert of CLI
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);
	}

    public override void beforeUpdate(){
        
        //filterEndorsement(newDataList);
        // Generate Azure Id before update of CLI
		CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

	
	public override void afterInsert(){
        filterEndorsement(newDataList);
        //update Quote ExcessLimit
        map<Id,Quote> updateExcessLimitMap = CommonCoverageLineItemUtil.updateExcessLimit(this.newDataMap);
        updateQuoteMap.putAll(updateExcessLimitMap);

        //update quote Technical Premium
        map<Id,Quote> updateTechPremiumMap = updateCelTechnicalPremium(this.newDataList);
        updateQuoteMap.putAll(updateTechPremiumMap);

        //update quote status
        map<Id,Quote> updateStatusMap = CommonCoverageLineItemUtil.updateQuoteStatus(this.newDataList,null);
        updateQuoteMap.putAll(updateStatusMap);

        if(updateQuoteMap.Values().size() > 0){
            update updateQuoteMap.Values();
        } 
    }

	
	public override void afterUpdate(){
        filterEndorsement(newDataList);
        //update quote status
        map<Id,Quote> updateStatusMap = CommonCoverageLineItemUtil.updateQuoteStatus(this.newDataList,this.oldDataMap);
        updateQuoteMap.putAll(updateStatusMap);

        //update Quote ExcessLimit
        map<Id,Quote> updateExcessLimitMap = CommonCoverageLineItemUtil.updateExcessLimit(this.newDataMap);
        updateQuoteMap.putAll(updateExcessLimitMap);

        //update quote Technical Premium
        map<Id,Quote> updateTechPremiumMap = updateCelTechnicalPremium(this.newDataList);
        updateQuoteMap.putAll(updateTechPremiumMap);

        if(updateQuoteMap.Values().size() > 0){
            update updateQuoteMap.Values();
        }

        //update CLI Option_Value_Default__c
        CommonCoverageLineItemUtil.handleUpdateSyncLimitDeductible(this.oldDataMap, this.newDataMap);
    }

    
    public override void afterdelete(){
        //update quote status
        map<Id,Quote> updateStatusMap = CommonCoverageLineItemUtil.updateQuoteStatus(oldDataList,null);

        /* should it updated, trigger handler does not have DML?*/
        
     }


     /*************************************************
    * Method Name: updateCelTechnicalPremium
    * Author: 
    * Date: 
    * Params: Map<Id, CoveragesLineItem__c>
    * Return: 
    * Exceptions:
    * Description: update Technical premium Term
    * Revision: 
     *************************************************/
    public static Map<Id, Quote> updateCelTechnicalPremium(List<CoveragesLineItem__c > newDataList) {
        Set<ID> quoteIds = new Set<ID>();
        Set<ID> existQuoteId = new Set<ID>();
        List<Quote> updateQuote = new List<Quote>();
        Map<Id, Quote> updateQuoteMap = new Map<Id, Quote>();
        List<CoveragesLineItem__c> CLIList = CoverageLineItemQueryUtil.fetchCLIsForTechnicalPremium(newDataList);
        if(CLIList.size()>0){
           for (CoveragesLineItem__c cli : CLIList){
               quoteIds.add(cli.Quote__c);
           } 
           String queryFields = 'Id,Celerity_Excess_Limit__c,Underlying_Excess_Limit__c, Celerity_Technical_Premium__c, Status, Product_Name__c';
           Map<Id,Quote> mapQuote = new Map<Id,Quote>( QuoteQueryUtil.fetchQuotesForQuoteIds(quoteIds, queryFields) );

           //can be removed
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
           //can be removed

           for (CoveragesLineItem__c cli: CLIList) {
               if(String.isNotBlank(cli.Coverage_Premium__c) && ((cli.Quote__r.Layer__c != 'Excess' && Trigger.isInsert) || Trigger.isUpdate)){ //check added by Vinay to bypass for Excess layer
                if(cli.Coverage_Product__c =='MPL' || cli.Coverage_Product__c =='Cyber' || cli.Coverage_Product__c =='Private Company Combo' ){
                    mapQuote.get(cli.Quote__c).Celerity_Technical_Premium__c = cli.Technical_Premium__c;
                    }
               }
           }
       }
       return updateQuoteMap;
   }
    
  //Filtering Endorsement coverages as per US:56883
    public static void filterEndorsement(List<CoveragesLineItem__c> clis){
        List<EndorsementTabLwcController.Endorsement> selEndorsementCovs =  EndorsementTabLwcController.getSelectedEndorsement(clis[0].Quote__c);
        String selClis = '';
        List<CoveragesLineItem__c> clisForRating = new List<CoveragesLineItem__c>();
        for(EndorsementTabLwcController.Endorsement endtCli : selEndorsementCovs){
            selClis += endtCli.id +  ' ' + ';';
        }

        List<CoveragesLineItem__c> existCli = [Select Id, IsSelected__c, Coverage__r.Coverage_Type__c, Coverage__r.Id,
                                                Coverage__r.Coverage_Code__c,Quote__c
                                                From CoveragesLineItem__c
                                                Where Quote__c = :clis[0].Quote__c];

        
        List<CoveragesLineItem__c> tempCli = new List<CoveragesLineItem__c>();
        // List<String> covToUpdateSelected = new List<String>();
        // List<String> covToUpdateNotSelected = new List<String>();
        for(CoveragesLineItem__c c1 : existCli){
            if(c1.Coverage__r.Coverage_Type__c == null) continue;
            CoveragesLineItem__c updateCli = new CoveragesLineItem__c();
            updateCli.Id = c1.Id;
            if(c1.Coverage__r.Coverage_Type__c.contains('Endorsement')){
                if(!selClis.contains(c1.Coverage__r.Id)){
                    updateCli.IsSelected__c = false;
                }
                else{
                    system.debug('vinay selected cov ' + c1.Coverage__r.Coverage_Code__c);
                    updateCli.IsSelected__c = true;
                }
                tempCli.add(updateCli);
            }
        }

        // List<CoveragesLineItem__c> cliToUpdate = new List<CoveragesLineItem__c>();
        // for(CoveragesLineItem__c c1 : tempCli){
        //     boolean cliInTrigger = false;
        //     for(CoveragesLineItem__c c2 : clis){
        //         if(c1.Id == c2.Id){
        //             c2.IsSelected__c = c1.IsSelected__c;
        //             cliInTrigger = true;
        //         }
        //     }
        //     if(!cliInTrigger) cliToUpdate.add(c1);
        // }

        GlobalStaticVar.byPassCoverageLineItemTrigger = true;
        GlobalStaticVar.byPassQuoteTrigger = true;
        update tempCli;
        GlobalStaticVar.byPassCoverageLineItemTrigger = false;
        GlobalStaticVar.byPassQuoteTrigger = false;
    }
}