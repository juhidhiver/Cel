/*************************************************
* Class Name: RenewalBatch
* Author: Priyanka Fulwani
* Date: 2020/12/15
* User Story on DevOps: 35317
* Description: Renewal Batch Program 
* Finding Policy/Opportunities that will expire in 90 days. 
* Creating a new Opportunity by cloning the existing Opportunity (ParentOpportunity). 
* Create Quote by cloning the Quote that is/will be in force on the Policy at the time it expires.
*************************************************/
public class RenewalBatch implements Database.Batchable<sObject>, Database.Stateful {
        
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = getOpportunityQuery();

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> oppts) {
        
        RenewalPolicyController.cloneOpportunityRenewal(oppts);
    }

    public void finish(Database.BatchableContext BC) {
        
    }
    

    //-------------- Opportunity----------------------//
    public String getOpportunityQuery() {
        String result = '';
        String obj = 'Opportunity';
        Date expDate = Date.today().addDays(120);
        String expDateStr = expDate.year() + '-' + String.valueOf(expDate.month()).leftPad(2, '0')
                            + '-' + String.valueOf(expDate.day()).leftPad(2, '0');
        
        List<String> params = new List<String>();
        params.add('Expiration_Date__c = '  + expDateStr);
        params.add('(Policy__r.Policy_Status__c = \'Active\' Or Policy__r.Policy_Status__c = \'Bound\')');
        params.add('StageName = \'Closed Won\'');
        params.add('Product__r.IsActive = true');
        params.add('Renewed__c = false');
        params.add('RecordType.DeveloperName = \'Celerity\'');      //to skip submission auto-renewal for AQPI

        String condition = String.join(params, ' AND ');
        result = CommonUtil.buildQuerySelectAll(obj, condition);
        
        return result;
    }
}