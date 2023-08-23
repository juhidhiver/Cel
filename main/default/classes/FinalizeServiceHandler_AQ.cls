public class FinalizeServiceHandler_AQ {

    public static Boolean checkSelectedQuoteOption(ID quoteId){
        try {
            List<Quote_Option__c> listQuoteOptions = [Select Id, Limit__c, Minimum_Premium__c, Book_Premium__c, Technical_Premium__c
                                                      , Actual_Premium_Annual__c, Broker_Netted_Down_Premium_Annual__c, Fee_Annual__c
                                                      , Technical_Premium_Discretion__c, Final_Discretion__c, Price_Adequacy__c
                                                      , Actual_Premium_Final__c, Broker_Netted_Down_Premium_Final__c, Fee_Final__c
                                                      , Bound__c, Selected__c, Option_Type__c, Final_Technical_Premium__c
                                                      , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c, Override_Fee_Percent__c
                                                      , Technical_Fee__c, IPT__c, Total_Cost_To_Client__c from Quote_Option__c 
                                                      where Quote__c = :quoteId AND Selected__c = true];
            if(!listQuoteOptions.isEmpty()){
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static AsyncApexJob validateSyncForQuoteBind(ID jobId){
        AsyncApexJob jobInfo = [SELECT Status,NumberOfErrors FROM AsyncApexJob WHERE Id=:jobID];
        return jobInfo;
    }

    public static List<CommentsWrapper> getQuoteApprovalComments(String quoteId){
        Set<Id> instanceIdSet = new Set<Id>();
        List<CommentsWrapper> commentsList = new List<CommentsWrapper>();
        try{
            List<ProcessInstance> instanceList = [Select Id,TargetObjectId From ProcessInstance where TargetObjectId =:quoteId];
            for(ProcessInstance instance : instanceList){
                instanceIdSet.add(instance.Id);
            }
            List<ProcessInstanceStep> instanceStepList = [Select id,StepStatus, Comments,Actor.Name From ProcessInstanceStep
                                                          where ProcessInstanceId IN :instanceIdSet AND (StepStatus = 'Approved' OR StepStatus = 'Rejected')];
            for(ProcessInstanceStep instanceStep : instanceStepList){
                if(String.isNotBlank(instanceStep.Comments)){
                    commentsList.add(new CommentsWrapper(instanceStep));
                }
            }
            return commentsList;
        }catch(Exception ex){throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));}
    }

    public static String generateApprovalURL(String quoteId){
        String approvalLink = '';  
        String userId = UserInfo.getUserId();
        List<ProcessInstanceWorkitem> workItemLst = [SELECT id  FROM ProcessInstanceWorkitem WHERE 
                                                     processInstance.TargetObjectId=:quoteId
                                                     AND OriginalActorId =:userId];
        
        if(workItemLst.size() > 0)  {   
            approvalLink='https://'+ System.URL.getSalesforceBaseUrl().getHost() +   
                '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItemLst[0].id;      
        }
        system.debug('approvalLink::'+approvalLink);
        return approvalLink;  
    }

    public static Boolean checkIsPrimaryBroker(string quoteId){
        List<Quote> quoteList = [select Id,opportunityId from Quote where Id =: quoteId];
        List<Broker_Account__c> brokerAccount = new List<Broker_Account__c>();
        Boolean isPrimaryMissing = false;
        
        if(!quoteList.isEmpty()){
            brokerAccount = [select Id,IsPrimaryBroker__c,Broker_Contact__c,Opportunity__c 
                             from Broker_Account__c
                             where IsPrimaryBroker__c = true AND Opportunity__c =: quoteList[0].opportunityId];
        }
        if(brokerAccount.isEmpty()){
            isPrimaryMissing = true;
        }
        
        return isPrimaryMissing;
    }

    public static API_Log__c syncQuoteToMiddleware(String quoteId) {
        Quote objQuote = [Select Id, Actual_Premium__c, Broker_Netted_Down_Premium__c, Fee__c
                            , Status, Name, Rating_Status__c,Accept_Terror_Premium__c,Endorsement_Quote_Bound_Date__c
                            , Quote_Type__c,Non_Prorated_Quote_Premium__c, Parent_Quote__c, Product_Name__c, Opportunity.Id
                            , Override_Actual_Premium_Percent__c, OverrideBrokerNettedDownPremiumPercent__c
                            , Override_Fee_Percent__c, IPT_on_Broker_Netted_Down_Premium__c
                            , Total_Cost_to_Client__c, Technical_Fee__c, Technical_Premium__c from Quote where Id =: quoteId];
        API_Log__c objApiLog = new API_Log__c();
        objApiLog = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', objQuote, 'FinalizeQuoteSync');
        insert objApiLog;
        return objApiLog;
    }

    public static Quote finalizeAndGenerateDocAQ(Quote quote){
        API_Log__c objApiLog = new API_Log__c();
        objApiLog = GenericSyncApi.getResponseFromApi('Quote_Sync', 'Sync Quote Status', quote, 'PreFinalizeSync'); // PreSync before Finalize  
        
        FinalizeServiceHandler_Common.ResultResponseWrapper returnStatus = FinalizeServiceHandler_Common.generateFinalizeDocument(quote.Azure_ID__c,quote.Id);
        if(returnStatus.errors.isEmpty() && returnStatus.status == 'Quoted'){
            quote.Status = 'Quoted';
            update quote;
        }

        if(objApiLog != null){
            insert objApiLog;
        }
        return quote;
    }

    public class CommentsWrapper{
        @AuraEnabled public String actorName{get;set;}
        @AuraEnabled public String comments{get;set;}
        @AuraEnabled public String approvalStatus{get;set;}
        public CommentsWrapper(ProcessInstanceStep instanceStep){
            this.actorName = instanceStep.Actor.Name;
            this.comments = instanceStep.Comments;
            this.approvalStatus = instanceStep.StepStatus;
        }
    }

}