/**************************************************************************************************
 * Class Name: CommonAdditionalInterestUtil
 * Author: 
 * Date: 15th Dec 2021
 * Description: Utility class for Additional Interest Trigger
 * Test Class: AdditionalInterestTriggerTest
 **************************************************************************************************/
public with sharing class CommonAdditionalInterestUtil {
    /*************************************************
    * Method Name: checkDuplicateAdditionalInterest
    * Author:
    * Description: Check if the list of AdditionalInterest is existed, if existed add the error to prevent save it to DB
    * Params: List<Additional_Interests__c>
    * Return:
    * Exceptions:
    * Revision: 
     *************************************************/ 
    public static void checkDuplicateAdditionalInterest(List<Additional_Interests__c> newAddInts) {
        Map<String, Additional_Interests__c> addIntsMap = new Map<String, Additional_Interests__c>();
        Set<Id> quoteIds = new Set<Id>();

        // Check duplicate between incoming records
        for (Additional_Interests__c newAddInt : newAddInts) {
            String key = newAddInt.Quote__c + '' + newAddInt.Additional_Interest_Account__c;
            if (addIntsMap.containsKey(key)) {
                newAddInt.addError(Label.ADDITIONALINTEREST_ACCOUNTDUPPLICATE_MSG);
            } else {
                addIntsMap.put(key, newAddInt);
                quoteIds.add(newAddInt.Quote__c);
            }
        }
    
        // Get records in db
        List<Additional_Interests__c> addIntsInSystem = new List<Additional_Interests__c>();
        for (Additional_Interests__c addInt : AdditionalInterestQueryUtil.fetchAdditionalInterestsByQuote(quoteIds)){
            addIntsInSystem.add(addInt);
        }
        
        // Check duplicate of incoming records with records in db
        for (Additional_Interests__c addIntInSystem : addIntsInSystem) {
            String key = addIntInSystem.Quote__c + '' + addIntInSystem.Additional_Interest_Account__c;
            if (addIntsMap.containsKey(key)) {
               addIntsMap.get(key).addError(Label.ADDITIONALINTEREST_ACCOUNTDUPPLICATE_MSG);   
            }
        }
    }

    /*************************************************
    * Method Name: deleteValidationWhenQuoteLock
    * Author:
    * Date: If Quote is 'Bound' or 'Bound Pending', prevent delete it's Additional_Interests__c  
    * Params: List<Additional_Interests__c>
    * Return:
    * Exceptions:
    * Revision: 
     *************************************************/ 
    public static void deleteValidationWhenQuoteLock(List<Additional_Interests__c> addInts) {        
        Map<String, List<Additional_Interests__c>> addIntMap = new Map<String, List<Additional_Interests__c>>();

        for(Additional_Interests__c addInt : addInts){
            if(!addIntMap.containsKey(addInt.Quote__c)) {
                addIntMap.put(addInt.Quote__c, new List<Additional_Interests__c>{addInt});
            }else {
                 addIntMap.get(addInt.Quote__c).add(addInt);
            }
        }

        for(Quote qt : [Select Id,Status From Quote Where Id IN: addIntMap.keySet()]) {
            if(qt.Status == 'Bound' || qt.Status == 'Bound Pending') {                
                if(addIntMap.containsKey(qt.Id)) {
                    for(Additional_Interests__c ai : addIntMap.get(qt.Id)) {
                        ai.addError(Label.QUOTE_LOCK_DELETE_CHILDREN);
                    }
                }
            }
        }
    }

    /*************************************************
    * Method Name: setOldValueWhenAccountChanged
    * Author:
    * Description: When Account change then save old value to old field
    * Params: oldAddtInterestMap, newAddtInterests 
    * Return:
    * Exceptions:
    * Revision: 
     *************************************************/ 
    public static void setOldValueWhenAccountChanged(Map<Id, Additional_Interests__c> oldAddtInterestMap,
                                                     List<Additional_Interests__c> newAddtInterests) {        
        for(Additional_Interests__c newAI : newAddtInterests) {                    
            // When Account change then save old value to old field
            if(oldAddtInterestMap.get(newAI.Id).Additional_Interest_Account__c != newAI.Additional_Interest_Account__c) {                                
                // when Account change more times then save account changed the first time
                if(String.isBlank(newAI.Old_Additional_Interest_Account__c)) {
                    newAI.Old_Additional_Interest_Account__c = oldAddtInterestMap.get(newAI.Id).Additional_Interest_Account__c;
                }
            }
        }
    }
}