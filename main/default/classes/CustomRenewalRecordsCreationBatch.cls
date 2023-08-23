public class CustomRenewalRecordsCreationBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable{

    String ProductName;
    Date renewalCreationDate;
    RenewalServiceHandler_AQ.AutoRenewalsWrapper wrapperAutoRenewals;

    public CustomRenewalRecordsCreationBatch(String ProductName, Date renewalCreationDate){
        this.ProductName = ProductName;
        this.renewalCreationDate = renewalCreationDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        //getQueryLocator - returns 50million records 
       // String productName = 'Professional Indemnity';
        //String statusVar = 'Bound';
        Date renewalDate = renewalCreationDate.addmonths(3);
        Integer getRenewalMonth = renewalDate.month();
        Integer getRenewalYear = renewalDate.year();
        String query = 'SELECT Id , Policy_Status__c , Product_Name__c ,Account__r.Renewal_Warning_Reason__c, Renewal_Date__c , Account__c , Renewal_Completed__c,Account__r.Renewal_Warning__c, (Select id , status, Layer__c ,Quote_Type__c, Opportunity.Main_Profession__c , OpportunityId from Quotes__r ORDER BY CreatedDate DESC Limit 1) from Policy__c where Policy_Status__c = \'Bound\'  and Product_Name__c = :ProductName and  CALENDAR_MONTH(Renewal_Date__c) =: getRenewalMonth AND CALENDAR_YEAR(Renewal_Date__c) =: getRenewalYear AND Renewal_Completed__c = false ORDER BY Account__c';
        //String query = 'SELECT Id , Policy_Status__c from Policy__c';
       // System.debug(query);
        System.debug('return text '+Database.getQueryLocator(query));
        //System.debug('querylocator'+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
        
     }
     public void execute(Database.BatchableContext bc, List<Policy__c> policy) {
        //RenewalServiceHandler_Common
        //RenewalServiceHandler_AQ
       
        System.debug('*****************policy**************'+policy);
        List<Policy__c> lstPoliciesForRenewal = new List<Policy__c>();
        for(Policy__c objPol: policy){
            if(objPol.Quotes__r.size() > 0 && objPol.Quotes__r[0].Status == 'Bound'){
                lstPoliciesForRenewal.add(objPol);
            }
        }

        if(!lstPoliciesForRenewal.isEmpty()){
            List<Renewal__c> renewalList   =  RenewalServiceHandler_Common.createRenewalRecords(lstPoliciesForRenewal,this.ProductName);
            if(renewalList.size()>0){
                List<Renewal__c> renewalsSucceded = new  List<Renewal__c>();
                Database.SaveResult[] saveResultList = Database.insert(renewalList, false);

                Integer index = 0;
                for (Database.SaveResult sr : saveResultList) {
                    if (sr.isSuccess()) {
                        renewalsSucceded.add(renewalList[index]);
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {

                            system.debug('Exception-------->>>>>>>'+ err.getMessage());

                        ErrorLogsUtilityHelper.logError('RenewalServiceHandler_Common.createRenewalRecords', 'Renwal Batch Insertion Failed','AQ_AutoRenewals','Renewals Insertion Failed',err.getMessage());
                        }
                    }
                    index++;
                }
                wrapperAutoRenewals = RenewalServiceHandler_AQ.autoAssignRenewals(wrapperAutoRenewals,renewalsSucceded);
            }
        }
    }

    /******************** Scheduler Execute  *************************/
    public void execute(SchedulableContext sc) {

        Integer batchSize = Integer.valueOf(System.Label.AQ_AutoRenewalBatchSize);

        CustomRenewalRecordsCreationBatch b = new CustomRenewalRecordsCreationBatch(this.ProductName, System.today());
        database.executebatch(b,batchSize);
    }


    public void finish(Database.BatchableContext bc) {

    }


}