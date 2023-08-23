public with sharing class QuoteOptionTriggerHandler extends TriggerHandler{

    public static Boolean isRecursive = false;
	
    private List<Quote_Option__c> oldDataList;
    private List<Quote_Option__c> newDataList;
    private Map<Id, Quote_Option__c> newDataMap;
    private Map<Id, Quote_Option__c> oldDataMap;
    
    public QuoteOptionTriggerHandler(){  
        this.oldDataList = (List<Quote_Option__c>) Trigger.old;
        this.oldDataMap = (Map<Id, Quote_Option__c>) Trigger.oldMap;
       	this.newDataList = (List<Quote_Option__c>) Trigger.new;
        this.newDataMap = (Map<Id, Quote_Option__c>) Trigger.newMap;
        
    }
    
    public override void beforeInsert(){
        CommonUtil.generateExternalID('Azure_Id__c', newDataList);
    }
    
    public override void beforeUpdate(){
        //deselectMultipleBoundOptions();
        revertCheckboxesforBoundQuotes();
    }
    
    public override void afterInsert(){
        updateTransactionPremiumOnQuote(newDataList);
    }
    
    public override void afterUpdate(){
        deselectMultipleBoundOptions();
        calculateNettedDownPremiumPrecent();
        updateTransactionPremiumOnQuote(newDataList);
    }

    public static void revertCheckboxesforBoundQuotes(){
        Map<Id, Quote_Option__c> oldMapQO = (Map<Id, Quote_Option__c>)Trigger.oldMap;
        for(Quote_Option__c newQO: (List<Quote_Option__c>)Trigger.new){
            if(newQO.Quote_Status__c == 'Bound' && (oldMapQO.get(newQO.Id).Bound__c != newQO.Bound__c
                || oldMapQO.get(newQO.Id).Selected__c != newQO.Selected__c)){
                newQO.Bound__c = oldMapQO.get(newQO.Id).Bound__c;
                newQO.Selected__c = oldMapQO.get(newQO.Id).Selected__c;
            }
        }
    }
    
    public static void deselectMultipleBoundOptions(){
        System.debug('isRecursive'+isRecursive);
        if(!isRecursive){
            System.debug('in isRecursive');
            map<String,String> mapQuoteIDtoQOId = new Map<String,String>();
            for(Quote_Option__c newQO: (List<Quote_Option__c>)Trigger.new){
                Quote_Option__c oldQO = (Quote_Option__c)Trigger.oldMap.get(newQO.Id);
                if(oldQO.Bound__c != newQO.Bound__c && !oldQO.Bound__c && newQO.Bound__c && newQO.Quote_Status__c != 'Bound'){
                    mapQuoteIDtoQOId.put(newQO.Quote__c, newQO.Id);
                }
            }

            List<Quote_Option__c> listQuoteOptiontoUpdate = new List<Quote_Option__c>();
            for(Quote_Option__c objQO : [Select Id, Bound__c, Quote__c from Quote_Option__c where Quote__c in :mapQuoteIDtoQOId.keySet()]){

                if(mapQuoteIDtoQOId.containsKey(objQO.Quote__c) && mapQuoteIDtoQOId.get(objQO.Quote__c) != objQO.Id){
					
                    if(objQO.Bound__c == true){
						objQO.Bound__c = false;
                    	listQuoteOptiontoUpdate.add(objQO);                        
                    }
                    
                }

            }

            if(!listQuoteOptiontoUpdate.isEmpty()){
                isRecursive = true;
                update listQuoteOptiontoUpdate;
            }
        }
        
    }

    public static void calculateNettedDownPremiumPrecent(){

        Map<Id, Quote_Option__c> oldMapQO = (Map<Id, Quote_Option__c>)Trigger.oldMap;
        Map<String,Quote_Option__c> mapQO = new Map<String,Quote_Option__c>();
        map<String,String> mapQuoteIDtoQOId = new Map<String,String>();
        for(Quote_Option__c newQO: (List<Quote_Option__c>)Trigger.new){
            Quote_Option__c oldQO = oldMapQO.get(newQO.Id);
            if(oldQO.Netted_Down_Commission_Percent__c != newQO.Netted_Down_Commission_Percent__c || oldQO.Netted_Down_Commission_Amount__c != newQO.Netted_Down_Commission_Amount__c
               || oldQO.Netted_Down_MGA_Commission_Percent__c != newQO.Netted_Down_MGA_Commission_Percent__c || oldQO.Netted_Down_MGA_Commission_Amount__c != newQO.Netted_Down_MGA_Commission_Amount__c
               || oldQO.Rate__c != newQO.Rate__c || oldQO.Rate_Change__c != newQO.Rate_Change__c){
                mapQO.put(newQO.Id,newQO);
            }
        }

        if(!mapQO.isEmpty()){

            populateFactorSummary(mapQO);

        }

    }

    public static void populateFactorSummary(Map<String,Quote_Option__c> mapQO){

        List<Factor_Summary__c> factorSummarytoUpdate = new List<Factor_Summary__c>();
        for(Factor_Summary__c objFactorSummary : [Select Id, Code__c, Value__c, Quote_Option__c from Factor_Summary__c 
                                where Quote_Option__c in :mapQO.keySet() AND Code__c in ('Netted Down Premium Broker Commission Percent','Netted Down Premium Broker Commission Sum','Netted Down Premium MGA Commission Percent','Netted Down Premium MGA Commission Sum','Rate','Rate Change')]){

            if(objFactorSummary.Code__c == 'Netted Down Premium Broker Commission Sum'){
                objFactorSummary.Value__c = String.valueOf(mapQO.get(objFactorSummary.Quote_Option__c).Netted_Down_Commission_Amount__c);
                factorSummarytoUpdate.add(objFactorSummary);
            }
            if(objFactorSummary.Code__c == 'Netted Down Premium Broker Commission Percent'){
                Decimal decimalValue = mapQO.get(objFactorSummary.Quote_Option__c).Netted_Down_Commission_Percent__c;
                objFactorSummary.Value__c = decimalValue != null ? String.valueOf(decimalValue.setScale(2)) : '0';
                factorSummarytoUpdate.add(objFactorSummary);
            }
            if(objFactorSummary.Code__c == 'Netted Down Premium MGA Commission Percent'){
                Decimal decimalValue = mapQO.get(objFactorSummary.Quote_Option__c).Netted_Down_MGA_Commission_Percent__c;
                objFactorSummary.Value__c = decimalValue != null ? String.valueOf(decimalValue.setScale(2)) : '0';
                factorSummarytoUpdate.add(objFactorSummary);
            }
            if(objFactorSummary.Code__c == 'Netted Down Premium MGA Commission Sum'){
                objFactorSummary.Value__c = String.valueOf(mapQO.get(objFactorSummary.Quote_Option__c).Netted_Down_MGA_Commission_Amount__c);
                factorSummarytoUpdate.add(objFactorSummary);
            }
            if(objFactorSummary.Code__c == 'Rate'){
                objFactorSummary.Value__c = String.valueOf(mapQO.get(objFactorSummary.Quote_Option__c).Rate__c);
                factorSummarytoUpdate.add(objFactorSummary);
            }
            if(objFactorSummary.Code__c == 'Rate Change'){
                objFactorSummary.Value__c = String.valueOf(mapQO.get(objFactorSummary.Quote_Option__c).Rate_Change__c);
                factorSummarytoUpdate.add(objFactorSummary);
            }

        }

        if(!factorSummarytoUpdate.isEmpty()){
            update factorSummarytoUpdate;
        }

    }
    public static void updateTransactionPremiumOnQuote(List<Quote_Option__c> newDataList)
    {
       
        set<Id> quoteIds = new set<Id>();
        set<Id> quoteId = new set<Id>();
        list<Quote> listQuote = new list<Quote>();
       for(Quote_Option__c qo : newDataList)
        {
            quoteId.add(qo.Quote__c);
        }
        
        Map<Id , Quote> mapQuote = new Map<Id , Quote>([Select id, Quote_Type__c,
                                    Change_In_Broker_Netted_Down_Premium__c ,NonProRated_BNDP__c, Status
                                    from Quote where id IN: quoteId ]);
       
            for( Quote_Option__c qo: newDataList)
            {
                Quote q = new Quote();
                q.Id = qo.Quote__c;
                    if((mapQuote.get(q.Id).Quote_Type__c == 'Full Amendment' || mapQuote.get(q.Id).Quote_Type__c == 'Coverage Amendment'
                    || mapQuote.get(q.Id).Quote_Type__c == 'Midterm Cancellation' || mapQuote.get(q.Id).Quote_Type__c == 'Policy Duration Change' 
                    || mapQuote.get(q.Id).Quote_Type__c == 'Flat Cancellation' ) 
                        && qo.Bound__c == true && qo.Selected__c == true 
                        && (mapQuote.get(q.Id).Status == 'In Progress' || mapQuote.get(q.Id).Status == 'Rated' || mapQuote.get(q.Id).Status == 'Quoted' ) )
                    {
                        q.Transaction_Premium_AQ__c = qo.Change_In_Broker_Netted_Down_Premium__c ; //  BNDP aprp

                        if(!quoteIds.contains(q.Id)){

                            listQuote.add(q);
                            quoteIds.add(q.Id);
                        }
                    }
            }

            if(listQuote.size() > 0) 
            {   update listQuote;   }
            System.debug('listQuote3 '+listQuote );
    }
}