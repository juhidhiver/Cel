public with sharing class ProConAnalysisLwcController {
    @AuraEnabled
    public static List<String> getCategories(String opportunityId){
        List<String> categories = new List<String>();
        List<Rating_Modifiers__c> listRM = [SELECT Id, Name, Sub_Section__c, Rating_Modifier_Value__c FROM Rating_Modifiers__c WHERE Opportunity__c =: opportunityId AND Page_Section__c = 'Pros and Cons'];
        for(Rating_Modifiers__c rating : listRM) {
            if(!categories.contains(rating.Sub_Section__c))
                categories.add(rating.Sub_Section__c);
        }
        return categories;
    }

    @AuraEnabled
    public static List<Rating_Modifiers__c> getProsConsList(String opportunityId){
        List<Rating_Modifiers__c> prosConsList = new List<Rating_Modifiers__c>();
        List<Rating_Modifiers__c> listRM = [SELECT Id, Name, Sub_Section__c, Rating_Modifier_Value__c FROM Rating_Modifiers__c WHERE Opportunity__c =: opportunityId AND Page_Section__c = 'Pros and Cons'];
        List<Rating_Modifiers__c> listProsRM = filterListRatingModifier(listRM, 'Pro', false);
        List<Rating_Modifiers__c> listConsRM = filterListRatingModifier(listRM, 'Con', false);
        prosConsList.addAll(listProsRM);
        prosConsList.addAll(listConsRM);
        return prosConsList;
    }

    @AuraEnabled
    public static List<Rating_Modifiers__c> searchRatingModifier(String opportunityId, List<String> searchCategories, 
                                                                    List<String> listAddedRatingModifier) {
        List<Rating_Modifiers__c> resultedRM = new List<Rating_Modifiers__c>();
        if(searchCategories.size() > 0)
            resultedRM = [SELECT Id, Name, Sub_Section__c, Rating_Modifier_Value__c
                         FROM Rating_Modifiers__c 
                         WHERE Opportunity__c =: opportunityId 
                         AND Page_Section__c = 'Pros and Cons' AND Sub_Section__c IN :searchCategories
                         AND Id NOT IN :listAddedRatingModifier];
        // else 
        //     resultedRM = [SELECT Id, Name, Sub_Section__c, Rating_Modifier_Value__c
        //     FROM Rating_Modifiers__c WHERE Opportunity__c =: opportunityId AND Page_Section__c = 'Pros and Cons'];
        resultedRM = filterListRatingModifier(resultedRM, '', true);
        return resultedRM;
    }

    public static List<Rating_Modifiers__c> filterListRatingModifier(List<Rating_Modifiers__c> listRM, String filterValue, Boolean isSearching) {
        List<Rating_Modifiers__c> resultRM = new List<Rating_Modifiers__c>();
        if(isSearching == true) {
            for(Rating_Modifiers__c rating : listRM) {
                if(rating.Rating_Modifier_Value__c == null)
                    resultRM.add(rating);
            }
        } else {
            for(Rating_Modifiers__c rating : listRM) {
                if(rating.Rating_Modifier_Value__c != null && rating.Rating_Modifier_Value__c.contains(filterValue))
                    resultRM.add(rating);
            }
        }
        return resultRM;
    }

    @AuraEnabled
    public static String saveRatingModifier(List<String> prosId, List<String> consId){
        List<Rating_Modifiers__c> listUpdateRM = new List<Rating_Modifiers__c>();
        for(String id : prosId) {
            Rating_Modifiers__c item = new Rating_Modifiers__c();
            item.Id = id;
            item.Rating_Modifier_Value__c = 'Pro';
            listUpdateRM.add(item);
        }
        for(String id : consId) {
            Rating_Modifiers__c item = new Rating_Modifiers__c();
            item.Id = id;
            item.Rating_Modifier_Value__c = 'Con';
            listUpdateRM.add(item);
        }
        Savepoint sp = Database.setSavepoint();
        try {
            update listUpdateRM;
        } catch (Exception ex) {
            Database.rollback(sp);
            return ex.getMessage();
        }
        return 'success';
    }

    @AuraEnabled
    public static String clearRatingModifier(List<String> ratingModifierIds){
        List<Rating_Modifiers__c> listUpdateRM = new List<Rating_Modifiers__c>();
        for(String id : ratingModifierIds) {
            Rating_Modifiers__c item = new Rating_Modifiers__c();
            item.Id = id;
            item.Rating_Modifier_Value__c = '';
            listUpdateRM.add(item);
        }
        Savepoint sp = Database.setSavepoint();
        try {
            update listUpdateRM;
        } catch (Exception ex) {
            Database.rollback(sp);
            return ex.getMessage();
        }
        return 'success';
    }
}