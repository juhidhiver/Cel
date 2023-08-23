/*************************************************
* Class Name: RejectedQuoteBatch
* Author: Namana K G
* Date: 2020/07/02
* User Story on DevOps: 48743
* Description: RejectedQuote Batch Program 
* Finding Rejected Quotes. 
* Changing Quote Status to closed. 
*************************************************/
public class RejectedQuoteBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext BC) {       
        String strQuery = 'select Id ,Approval_Status__c,Status,CloseDate__c,Product_Name__c,Closed_Reason__c from Quote' +
            ' where Status = \'Rejected\' AND Product_Name__c = \'Professional Indemnity\'';
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<Quote> quoteList) { 
        
        if(!quoteList.isEmpty()){
            for(Quote quo: quoteList){
                quo.Status ='Closed' ;
                quo.Closed_Reason__c = 'Approval Rejected';
            }
            update quoteList;
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
    
}