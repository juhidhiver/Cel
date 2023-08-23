/**************************************************************************************************
 * Class Name: APILogBatch
 * Author: 
 * Date: 25-May-2022
 * Description: API Log Object delete old data 2 weeks ago
 **************************************************************************************************/
global class APILogBatch implements Database.Batchable<sObject> {
    global final String Obj;

    global APILogBatch(String ObjName) {
        //this.query = query;
        this.Obj = ObjName;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
       return Database.getQueryLocator(
            'SELECT Id ' +
            'FROM ' + Obj +
            ' WHERE CreatedDate < LAST_N_DAYS:90'
            );
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        delete scope;    
    }

    global void finish(Database.BatchableContext BC) {

    }
}