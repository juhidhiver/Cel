public without sharing class CommonUtilAQ {
    
    public static void removeApprovalRequestsFromQuote(List<Quote> newQuote, Map<ID,Quote> oldQuoteMap){
        Set<Id> setOfQuoteIds = new Set<Id>();

        for(Quote quote: newQuote){
            if(quote.Status != oldQuoteMap.get(quote.Id).Status && oldQuoteMap.get(quote.Id).Status == 'Referred'
                && quote.Product_Name__c == 'Professional Indemnity' && quote.Closed_Reason__c == oldQuoteMap.get(quote.Id).Closed_Reason__c
                && quote.Rating_Status__c == oldQuoteMap.get(quote.Id).Rating_Status__c){
                    setOfQuoteIds.add(quote.Id);    //Quote ids which are updated without approving/rejecting referrals
            }
        }

        if(!setOfQuoteIds.isEmpty()){
            removeApprovalRequestsAndUnlockQuote(setOfQuoteIds);
        }
    }

    public static void removeApprovalRequestsAndUnlockQuote(Set<Id> setOfQuoteIds){
        List<Approval.ProcessWorkitemRequest> lstRequests = new List<Approval.ProcessWorkitemRequest> ();

        //Get ProcessInstance Items
        Map<Id,ProcessInstance> mapOfIdVsPI = new Map<Id,ProcessInstance>([Select Id from ProcessInstance where Status = 'Pending' AND TargetObjectId IN :setOfQuoteIds]);
            
        if(!mapOfIdVsPI.isEmpty()){
            for(ProcessInstanceWorkItem objPIWorkItem : [Select Id from ProcessInstanceWorkItem where ProcessInstanceId IN :mapOfIdVsPI.keySet()]){
                // if there's a work item, set the action to 'rejected' and execute
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setAction('Reject');
                req.setWorkitemId(objPIWorkItem.Id);
                lstRequests.add(req);
            }
            Approval.ProcessResult[] processResults = null;
            processResults = Approval.process(lstRequests, false);
            
            //Unlock the Quote and related Quote Versions after rejecting the referral
            Quote[] quotesToBeUnlocked = [SELECT Id FROM Quote WHERE Id IN: setOfQuoteIds];
            Approval.UnlockResult[] quoteUnlockResultList = Approval.unlock(quotesToBeUnlocked, false);
            
            //Update the quote status back to In Progress
            GlobalStaticVar.byPassQuoteTrigger = true;
            List<Quote> lstQuoteToBeUpdated = [SELECT Id, Status, Closed_Reason__c FROM Quote WHERE Id IN: setOfQuoteIds];
            lstQuoteToBeUpdated[0].Status = 'In Progress';
            lstQuoteToBeUpdated[0].Closed_Reason__c = '';
            update lstQuoteToBeUpdated;
            
            //Revert the rejected Referral Reason records field values
            List<Referral_Reason__c> referralReasonList = [SELECT Id,Name,Approval_Level_Required__c,Approval_Status__c,Quote__c,
                                                           Approval_Rejected_Date__c, Approver_Level__c,Approved_By__c, Entity_Path__c,
                                                           Reason__c,Reason_Type__c, Status__c,Approved_By__r.Name,
                                                           Quote_Option__c,Option_Type__c,Option_Limit__c,Option_Id__c,Quote_Option__r.Selected__c  
                                                           FROM Referral_Reason__c 
                                                           WHERE Approval_Status__c = 'Rejected' 
                                                           AND Quote__c IN:setOfQuoteIds];
            
            if(!referralReasonList.isEmpty()){
                for(Referral_Reason__c refReason: referralReasonList){
                    refReason.Approval_Rejected_Date__c = null;
                    refReason.Approved_By__c = null;
                    refReason.Approval_Status__c = null;
                    refReason.Approver_Level__c = null;
                }
                update referralReasonList;
            }

            GlobalStaticVar.byPassQuoteTrigger = false;
        }
    }

}