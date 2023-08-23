/***
 * @description       : Test class to cover Error Logs utility helper
 * @author            : Maeran Shaikh
 * @Company           : Willis Towers Watson
 * @last modified on  : 03-26-2021
 * @last modified by  : Maeran Shaikh
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   03-26-2021   Maeran Shaikh   Initial Version
***/
@isTest
public with sharing class ErrorLogsUtilityHelperTest {
    @isTest
    public static void validateData(){
        ErrorLogsUtilityHelper.checkIfEnabled();
        Set<id> referenceIDs = new set<id>();
        List<sobject> lstsobject = new List<sobject>();
        List<ErrorLogsUtilityHelper.ErrorLogWrapper> wrapperList = new List<ErrorLogsUtilityHelper.ErrorLogWrapper>();

        // Create Account record
        Account acc = TestUtil.createBusinessAccount('Test Acc','Business', 'MG road','New York','New York', '10004', 'United States');
        insert acc;
        
        // Call ErrorLogsUtilityHelper
        ErrorLogsUtilityHelper.logDebug('Test', 'Test', acc.id, 'Account', 'Test', 'Test');     
        ErrorLogsUtilityHelper.logInfo('Test Function', 'Test Msg ', acc.Id, 'Account','errorOperation' , 'msg Decription');
        ErrorLogsUtilityHelper.logWarn('Test Function', 'Test Msg ', acc.Id, 'Account', 'errOperation', 'msgDesc');
        ErrorLogsUtilityHelper.logError(wrapperList);

        // Exception calls
        try{
            Integer j=10;
            j = j/0;
         }
         catch(Exception ex){
            ErrorLogsUtilityHelper.logError(ex, 'Test function', 'msg', referenceIDs, 'Account', 'errOperation','msgDesc');
            ErrorLogsUtilityHelper.logError(ex, 'Test function', 'msg', lstsobject,'Account', 'errOperation','msgDesc');
            ErrorLogsUtilityHelper.logError(ex, 'Test function', 'msg', acc.Id, 'Account', 'errOperation', 'msgDesc');
         }
    }

}