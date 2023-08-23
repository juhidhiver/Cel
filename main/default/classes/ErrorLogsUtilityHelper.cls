/*
****************
@author:            Maeran Shaikh
@company:          Willis Towers Watson
@description:       Utility class to help log consistent messages into the Error_Log__c object
@inputs:            logLevel         - Debug, Error, Info, Warning
functionName   - Method in class above that initiated the log
ex               - The standard exception object for errors
message          - The user friendly message associated with the log record
referenceId      - The salesforce record or job ID related to the log
objectName          - Optional objectName. E.g. could be used to log the Request and Response of a web callout
logCode          - Optional logCode. Used for reporting purposes

@history
<Date>        <Authors Name>        <Brief Description of Change>
26/3/2021       Maeran Shaikh             created
*****************
*/

public without sharing class ErrorLogsUtilityHelper {
    @TestVisible
    private ErrorLogsUtilityHelper(){
        
    }
    public static final String LOGLEVEL_ERROR = 'error';
    public static final String LOGLEVEL_DEBUG = 'debug';
    public static final String LOGLEVEL_INFO = 'info';
    public static final String LOGLEVEL_WARN = 'warn';
    
    // Enabled/Disable error logs
    private static Boolean errorLoggingIsEnabled = false;
    private static Boolean debugLoggingIsEnabled = false;
    private static Boolean infoLoggingIsEnabled = false;
    private static Boolean warnLoggingIsEnabled = false;
    
    private static List<ErrorLogWrapper> errorLogContainer = new List<ErrorLogWrapper>();

    
    public static void checkIfEnabled(){
        // MetadataSelector.sendErrorLogSwitchMdt() will fetch details of Error_Log_Settings__mdt which fetches switch setting for Error log
        for( Error_Log_Settings__mdt errMDT : [SELECT MasterLabel,NamespacePrefix,isEnabled__c from Error_Log_Settings__mdt]) {
            System.debug('errMDT-->'+errMDT);
            if(errMDT.MasterLabel.contains(LOGLEVEL_ERROR) && errMDT.isEnabled__c){
                errorLoggingIsEnabled = true;
            }
            else if(errMDT.MasterLabel.contains(LOGLEVEL_DEBUG) && errMDT.isEnabled__c){
                debugLoggingIsEnabled = true;
            }
            else if(errMDT.MasterLabel.contains(LOGLEVEL_INFO) && errMDT.isEnabled__c){
                infoLoggingIsEnabled = true;
            }
            else if(errMDT.MasterLabel.contains(LOGLEVEL_WARN) && errMDT.isEnabled__c){
                warnLoggingIsEnabled = true;
            }
        }
    }
    
    /*
**Used to log exceptions that need support team visibility (e.g. a controller class failed to update a record)
*/
    
    
    // This method will accept a single refernce id to track error 
    public static void logError(Exception ex,String functionName,String message,String referenceID,String objectName,String errorOperation,String messageDescription){
        errorLogContainer = new List<ErrorLogWrapper>();
        checkIfEnabled();
        if(errorLoggingIsEnabled) {
            insertLog(LOGLEVEL_ERROR, functionName, ex, message, referenceID, objectName, errorOperation,messageDescription);
            commitLog();
        }
    }
    
    // this method will accept a set of Id as a source of reference in your error log record
    public  static void logError(Exception ex,String functionName,String message,set<Id> referenceIDs,String objectName,String errorOperation,String messageDescription) {
        checkIfEnabled();
        errorLogContainer = new List<ErrorLogWrapper>();
        errorLogContainer = new List<ErrorLogWrapper>();
        if(errorLoggingIsEnabled) {
            for(Id objID : referenceIDs){
                insertLog(LOGLEVEL_ERROR, functionName, ex, message, objID, objectName, errorOperation,messageDescription);
            }
            commitLog();
        }
    }

    
    // will accept a wrapper with details as mentioned in line 220 -231
    public static void logError(list<ErrorLogsUtilityHelper.ErrorLogWrapper> errorsLogWrapper) {
        System.debug('Error Wrapper-->'+errorsLogWrapper);
        checkIfEnabled();
        errorLogContainer = new List<ErrorLogWrapper>();
        if(errorLoggingIsEnabled && !errorsLogWrapper.isempty()) {
            for(ErrorLogsUtilityHelper.ErrorLogWrapper record : errorsLogWrapper){
                insertLog(LOGLEVEL_ERROR, record.functionName, record.ex, record.message, record.referenceId, record.objectName, record.errorOperation,record.messageDescription);
            }
            commitLog();
        }
    }
    
    // will accept a list of sObject as a source of parameter for reference
    public static void logError(Exception ex,String functionName,String message,List<sObject> referenceIDs,String objectName,String errorOperation,String messageDescription) {
        errorLogContainer = new List<ErrorLogWrapper>();
        checkIfEnabled();
        if(errorLoggingIsEnabled) {
            for(sObject record : referenceIDs){
                insertLog(LOGLEVEL_ERROR, functionName, ex, message, record.Id, objectName, errorOperation,messageDescription);
            }
            commitLog();
        }
    }
    
    /*
**Used to log a statement that will assist with issue resolution (
e.g. log the request and response from a web service callout)**
*/
    
    public static void logDebug(String functionName,String message,String referenceID,String objectName,String errorOperation,String messageDescription) {
        checkIfEnabled();
        if(debugLoggingIsEnabled) {
            insertLog(LOGLEVEL_DEBUG, functionName, null, message, referenceID, objectName, errorOperation,messageDescription);
            commitLog();
        }
    }
    
    /*
**Used to log information about a process (e.g. when a batch job finished, how many records were processed, 
how many batches were used, what time did the job start and finish)
*/
    
    public static void logInfo(String functionName,String message,String referenceID,String objectName,String errorOperation,String messageDescription) {
        checkIfEnabled();
        if(infoLoggingIsEnabled) {
            insertLog(LOGLEVEL_INFO, functionName, null, message, referenceID, objectName, errorOperation,messageDescription);
            commitLog();
        }
    }
    
        /*
**Used to log information about a process (e.g. when a batch job finished, how many records were processed, 
how many batches were used, what time did the job start and finish)
*/
    public static void logInfo(String functionName,String message,List<sObject>  sobjects,String objectName,String errorOperation,String messageDescription) {
        checkIfEnabled();
        if(infoLoggingIsEnabled) {
            for(Sobject rec: sobjects){
                insertLog(LOGLEVEL_INFO, functionName, null, message, rec.Id, objectName, errorOperation,messageDescription);
            }
            
            commitLog();
        }
    }
    /*
**Used to notify the support team that one or more application limits are in 
danger of being reached (e.g. an Account trigger results in 80 SOQL queries)
*/
    
    public static void logWarn(String functionName,String message,String referenceID,String objectName,String errorOperation,String messageDescription) {
        
        checkIfEnabled();
        System.debug('Check Log Warn Enabled status-->'+warnLoggingIsEnabled);
        if(warnLoggingIsEnabled) {
            
            insertLog(LOGLEVEL_WARN, functionName, null, message, referenceID, objectName, errorOperation,messageDescription);
            commitLog();
        }
    }
    
    /************************* New Error Logs for Auto Renewals *******************/

    public  static void logError(String functionName,String message,String referenceID,String objectName,String messageDescription) {
        errorLogContainer = new List<ErrorLogWrapper>();
        checkIfEnabled();
        if(errorLoggingIsEnabled) {
            insertLog(LOGLEVEL_ERROR, functionName, null, message, referenceID, objectName,'',messageDescription);
            commitLog();
        }
    }



    
    // Will store the value of errorLog into a container
    private static void insertLog(String logLevel,String functionName,Exception ex,String message,String referenceId,String objectName,String errorOperation,String messageDescription){
        try{
            ErrorLogWrapper errorLog = new ErrorLogWrapper();
            if(logLevel!=null) {
                errorLog.logLevel = logLevel;
            }
            if(functionName!=null){
                errorLog.functionName = functionName;
            }
            if(message!=null){
                errorLog.message = message;
            }
            if(referenceId!=null){
                errorLog.referenceId = referenceID;
            }
            if(objectName!=null){
                errorLog.objectName = objectName;
            }
            if(errorOperation!=null){
                errorLog.errorOperation = errorOperation;
            }
            if(ex!=null){
                errorLog.stackTrace = ex.getStackTraceString();
            }
            if(messageDescription!=null){
                errorLog.messageDescription = messageDescription;
            }
            // adding to container
            errorLogContainer.add(errorLog);
            
        }
        catch(Exception e){
            System.debug('Failed to add errorLog to errorLogContainer'
                         + ' Error = ' + e.getMessage()
                         + ' logLevel='+logLevel
                         + ' functionName='+functionName
                         + ' ex='+ex
                         + ' message='+message
                         + ' referenceID='+referenceID
                         + ' objectName='+objectName
                         + ' errorOperation='+errorOperation
                         +'messageDescription='+messageDescription);
        }
    }
    // Insert logic for Error_Log__c object
    
    public static void commitLog(){
        if (!errorLogContainer.isEmpty()){
            List<Error_Log__c> errorLogsForInsert = new List<Error_Log__c>();
            for(ErrorLogWrapper log: errorLogContainer) {
                Error_Log__c errorLog = new Error_Log__c();
                errorLog.Error_Description__c = log.messageDescription;
                errorLog.Error_Operation__c = log.errorOperation;
                errorLog.Function_Name__c = log.functionName;
                errorLog.Object_Name__c = log.objectName;
                errorLog.Reference_Id__c = log.referenceID;
                errorLog.Short_Message__c = log.message;
                errorLog.Stack_Trace__c = log.stackTrace;
                
                errorLogsForInsert.add(errorLog);
            }
            try{
                System.debug('vinay error log creatable: ' + Error_Log__c.sObjectType.getDescribe().isCreateable());
                if (Error_Log__c.sObjectType.getDescribe().isCreateable()) {  
                    insert errorLogsForInsert;
                    errorLogContainer.clear();
                }
                
            }
            catch(Exception ex){
                System.debug('Failed to insert contents of errorLogContainer to RMD_Error_Log__c'
                             + ' Error Message = ' + ex.getMessage()
                             + ' Error Stack Trace = ' + ex.getStackTraceString());
            }
        }
    }
    
    
    // Wrapper for Error Log
    public class ErrorLogWrapper{
        public String logLevel {get; set;}
        public String functionName {get; set;}
        public String message {get; set;}
        public String referenceID {get; set;}
        public String objectName {get; set;}
        public String errorOperation {get; set;}
        public String stackTrace {get; set;}
        public String messageDescription {get; set;}
        public Exception ex  {get; set;}
    }
 
}