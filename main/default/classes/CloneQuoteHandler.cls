/**
* Class       : CloneQuoteHandler
* created     : 24-Sep-2019 Khanh TRAN
* Description : Controller for Clone Quote.
* @modified   : Quang Pham has been modified
*/
public with sharing class CloneQuoteHandler {
    /**
     * Method name : cloneWithChildren
     * Arguments   : Id quoteId - the id of the record Quote whose name needs to be clone
     *              Map<String,Object> fieldUpdateMap
     * Return type : String
     * Description : Clones parent Quote and child records
     * Revisions: Hoang Bui - 28-May-20
    **/

    //method_Common_QuickActionOnQuote
    @AuraEnabled
    public static ResultResponse cloneQuoteWithChildren(String quoteId, Map<String,Object> fieldUpdateMap) {
        return CloneService.cloneQuoteWithChildren(quoteId, fieldUpdateMap);
    }

}