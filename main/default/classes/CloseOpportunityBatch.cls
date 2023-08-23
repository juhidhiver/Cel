/**************************************************************************************************
 * Class Name: CloseOpportunityBatch
 * Author: Giang PHAN
 * Date: 24-Sep-2019
 * Description: Batch Program to Close Opportunity and all related Quotes
 **************************************************************************************************/
global class CloseOpportunityBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        List<String> statusQuot = new List<String>{'In Progress','Rated','Referred','Quoted','Presented'};
        List<String> stageNames = new List<String>{'New','Qualified','Prospect'};
        
        String strQuery = 'SELECT Id, StageName, CloseDate, (SELECT Id, Status FROM Quotes WHERE Status IN : statusQuot) FROM Opportunity WHERE StageName IN : stageNames AND CloseDate = TODAY';
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> opportunityList) {
        List<Opportunity> opptUpdates = new List<Opportunity>();
        List<Quote> quoteUpdates = new List<Quote>();
        for(Opportunity oppt : opportunityList){
            oppt.StageName = 'Closed';
            oppt.Loss_Reason__c = 'No Activity';

            if(oppt.Quotes.isEmpty()) continue;

            for(Quote qt : oppt.Quotes) {
                // Quotes status 
                if(qt.Status == 'In Progress' || qt.Status == 'Rated' || qt.Status == 'Referred' || qt.Status == 'Quoted' || qt.Status == 'Presented') {
                    qt.Status = 'Close';
                    qt.Closed_Reason__c = 'No activity';
                    quoteUpdates.add(qt);
                }
            }
        }
        //Update List Quote
        if(!quoteUpdates.isEmpty()) update quoteUpdates;
        //Update List Opportunity
        if(!opportunityList.isEmpty()) update opportunityList;
    }

    global void finish(Database.BatchableContext BC) {

    }
}