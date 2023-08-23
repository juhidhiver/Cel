public without sharing class CreateFactorSummary {
    public static void createNewFactorSummary(List<Factor_Summary__c> newFactorSummary, String quoteId) {
        Map<String,Factor_Summary_Template__c> mapTemplate = new Map<String,Factor_Summary_Template__c>();
        
        if(string.isBlank(quoteId)){
            return;
        }
        List<Factor_Summary__c> fsList =  [SELECT Id FROM Factor_Summary__c WHERE Quote__c = : quoteId];
        if(!fsList.isEmpty()) delete fsList;
        
        AggregateResult result = [SELECT MAX(Sort_Order__c) FROM Factor_Summary_Template__c];
        Decimal max = result.get('expr0') == null ? 0 : (Decimal)result.get('expr0');
        for (Factor_Summary_Template__c item : [SELECT Id,Sort_Order__c,Code__c FROM Factor_Summary_Template__c]) {
            mapTemplate.put(item.Code__c,item);
        }
        
        for(Factor_Summary__c fs : newFactorSummary) {
            fs.Quote__c = quoteId;
            if(!mapTemplate.containsKey(fs.Code__c)){
                Factor_Summary_Template__c template = new Factor_Summary_Template__c();
                template.Code__c = fs.Code__c;
                template.Sort_Order__c = ++max;
                mapTemplate.put(fs.Code__c, template);
            }
        }
        if(!mapTemplate.values().isEmpty()){
            upsert mapTemplate.values();
        }
        insert newFactorSummary;
    }

    public static void createNewFactorSummaryQC(Map<String, List<Factor_Summary__c>> mapOfOptionIdVsListOfFactorSummary) {
        Map<String,Factor_Summary_Template__c> mapTemplate = new Map<String,Factor_Summary_Template__c>();
        List<Factor_Summary__c> lstFactorSummaryToBeInserted = new List<Factor_Summary__c>();
        
        List<Factor_Summary__c> fsList =  [SELECT Id FROM Factor_Summary__c WHERE Quote_Option__c IN: mapOfOptionIdVsListOfFactorSummary.keySet()];
        if(!fsList.isEmpty()) delete fsList;
        
        AggregateResult result = [SELECT MAX(Sort_Order__c) FROM Factor_Summary_Template__c];
        Decimal max = result.get('expr0') == null ? 0 : (Decimal)result.get('expr0');
        for (Factor_Summary_Template__c item : [SELECT Id,Sort_Order__c,Code__c,Format__c FROM Factor_Summary_Template__c]) {
            mapTemplate.put(item.Code__c,item);
        }

        for(String strQuoteOptionId: mapOfOptionIdVsListOfFactorSummary.keySet()){
            List<Factor_Summary__c> lstFactorSummary = new List<Factor_Summary__c>();
            lstFactorSummary = mapOfOptionIdVsListOfFactorSummary.get(strQuoteOptionId);
            for(Factor_Summary__c objFS : lstFactorSummary){
                objFS.Quote_Option__c = strQuoteOptionId;
                if(mapTemplate.containsKey(objFS.Code__c) && mapTemplate.get(objFS.Code__c).Format__c == 'Percent'){
                    objFS.Value__c = objFS.Value__c != null ? String.valueOf(Decimal.valueOf(objFS.Value__c).setScale(2)) : '0';
                }
                lstFactorSummaryToBeInserted.add(objFS);
                if(!mapTemplate.containsKey(objFS.Code__c)){
                    Factor_Summary_Template__c template = new Factor_Summary_Template__c();
                    template.Code__c = objFS.Code__c;
                    template.Sort_Order__c = ++max;
                    mapTemplate.put(objFS.Code__c, template);
                }
            }
        }

        if(!mapTemplate.values().isEmpty()){
            upsert mapTemplate.values();
        }
        insert lstFactorSummaryToBeInserted;
    }
}