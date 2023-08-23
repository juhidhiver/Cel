/*
Saumyak - 17 May 2021 For full cancel & replace functionality
*/
public with sharing class fullCancellation {
    @AuraEnabled
    public static NewEndorsementAQController.ResultWrapper fullCancellation(string quoteId,Date createdDate,string effectiveDate,string policyId){
        NewEndorsementAQController.ResultWrapper result = new NewEndorsementAQController.ResultWrapper();
        Set<Id> oppIdsSet = new Set<Id>();
        Set<Id> policyIdsSet = new Set<Id>();
        //Set<Id> nonExpiredPolicyIds = new Set<Id>();
        Savepoint sp = Database.setSavepoint();
        try{
            Quote selectedQuote = [SELECT Id, Name, OpportunityId, Opportunity.CreatedDate, CreatedDate, Policy__c,Quote_Type__c,Master_Binder__c
                                   FROM Quote 
                                   WHERE Id =: quoteId][0];
            DateTime selectedQuoteCreatedDate = selectedQuote.CreatedDate;
            String selQuoOpp = selectedQuote.OpportunityId;
            String selQuoPol = selectedQuote.Policy__c;
            
            Id activeOppId;
            
            //Get all opp related to base policy
            for(Transactions__c subPolTransaction : [SELECT Name, Id, Policy__c, Submission__c, Submission__r.CreatedDate,Submission__r.Transaction_Status__c 
                                                     FROM Transactions__c 
                                                     WHERE Policy__c =: selectedQuote.Policy__c
                                                     AND Submission__r.CreatedDate >=: selectedQuote.Opportunity.CreatedDate]){
                                                         policyIdsSet.add(subPolTransaction.Policy__c);
                                                         oppIdsSet.add(subPolTransaction.Submission__c);
                                                         
                                                         if(subPolTransaction.Submission__r.Transaction_Status__c == 'Active'){
                                                             activeOppId = subPolTransaction.Submission__c;
                                                         }
                                                     }
            
            //Get all the policy related to all the opps
            for(Transactions__c subPolTran : [SELECT Name, Id, Policy__c, Submission__c 
                                              FROM Transactions__c
                                              WHERE Submission__c IN: oppIdsSet
                                              AND Policy__r.Policy_Status__c =:'Bound']){
                                                  policyIdsSet.add(subPolTran.Policy__c);                                                     
                                              }
            
           /* List<Policy__c> polList = [Select Id, Expiration_Date__c from Policy__c where Id IN :policyIdsSet];
            for(Policy__c pol: polList){
                if(pol.Expiration_Date__c >= System.today()){
                    nonExpiredPolicyIds.add(pol.Id);
                }
            }*/
            
            //Get all the quotes from the policies
            set<string> quoteTypes = new set<string>{'New Business','Full Amendment','Coverage Amendment','Renewal','Policy Duration Change'};
            Map<String,List<Quote>> policyIdToQuoteListMap = new Map<String,List<Quote>>();
            List<Quote> quoteListFromPolicy = [Select Id,Commission_percentage__c, Effective_Date__c, QuoteNumber, ExpirationDate,CreatedDate,
                                               AccountId, Coverage_Product_Options__c, Master_Set_ID__c, Endorsement_Effective_Date__c,                
                                               Quote_Type__c, Name, Status, Rating_Status__c,Tax,Commission__c, Override_Premium__c, 
                                               Override_Premium_Percentage__c,Parent_Quote__c, IPID_Document__c,Policy_Wording_Document__c,
                                               Technical_Premium__c,QuotePremium__c,Total_Premium__c,CloseDate__c,Accept_Terror_Premium__c,
                                               Non_Prorated_Quote_Premium__c,Non_prorated_Total_Premium__c, Special_Coverages__c,
                                               Parent_Quote__r.Non_Prorated_Quote_Premium__c,Parent_Quote__r.QuotePremium__c,OpportunityId,
                                               Broker__r.Account.Azure_ID__c, Broker__r.Azure_ID__c,Broker__r.Id,Total_Cost_to_Client__c,
                                               Endorsement_Quote_Bound_Date__c,Broker__r.Name,Broker__r.Account.Name,                            
                                               Endorsement_Reason__c,Endorsement_Reason_Other__c, Override_Actual_Premium_Percent__c, 
                                               Override_Fee_Percent__c, Override_Actual_Excess_Percent__c, Technical_Fee__c,
                                               OverrideBrokerNettedDownPremiumPercent__c,As_if_Book_Rated_Premium_rate_change__c,
                                               Actual_Excess__c, Actual_Premium__c, Binder__c, Policy__c,Master_Binder__c,
                                               Book_Excess__c, Book_Premium__c, Book_Rated_Premium__c, Broker_Commission__c, 
                                               Broker_Netted_Down_Premium__c, Discretion__c, Excess_Basis__c, Fee__c, Final_Discretion__c, 
                                               IPT_on_Broker_Netted_Down_Premium__c, Jurisdiction_Limits__c, Layer__c, Limit_Basis__c, 
                                               MGA_Commission__c, Minimum_Premium__c, Netted_Down_Premium_Broker_Commission__c, 
                                               Netted_Down_Premium_MGA_Commission__c, Policy_Wording__c,PI_Limit_of_Indemnity__c, 
                                               Previous_Year_Actual_Premium__c, Previous_Year_Book_Rated_Premium__c, 
                                               Previous_Year_Final_Discretion__c, Previous_Year_Exposure__c, Price_Adequacy__c, 
                                               Rate__c, Rateable_Exposure__c, RetroDate__c,Technical_Premium_Discretion__c, 
                                               Retroactive_Date__c, Revised_Broker_Commission__c, Revised_MGA_Commission__c, 
                                               Territorial_Limits__c, Total_Underlying_Layer__c,Rate_Change__c,Product_Name__c,Quote_Action__c
                                               FROM Quote 
                                               WHERE Policy__c IN: policyIdsSet
                                               //WHERE Policy__c IN: nonExpiredPolicyIds //fetch quotes only from non-expired policies
                                               AND Quote_Type__c IN :quoteTypes
                                               //AND OpportunityId IN:oppIdsSet
                                               //AND CreatedDate >=: selectedQuoteCreatedDate
                                               AND Opportunity.CreatedDate >=: selectedQuote.Opportunity.CreatedDate
                                               AND Status =:'Bound'
                                               ORDER BY CreatedDate];
            
            system.debug('## quoteListFromPolicy -- '+quoteListFromPolicy);
            
            List<Master_Binder__c> masterBinder = new List<Master_Binder__c>();
            if(selectedQuote.Quote_Type__c=='Renewal'){
               masterBinder = [select id,MGA_Commission__c from Master_Binder__c where id=:selectedQuote.Master_Binder__c];     
            }
            
            //Create a Map of Policy ID & related quotes
            for(Quote quo: quoteListFromPolicy){
                String polID = quo.Policy__c;
                if(selectedQuote.Quote_Type__c=='Renewal'){
                    quo.MGA_Commission__c = masterBinder.size()>0 ? masterBinder[0].MGA_Commission__c : quo.MGA_Commission__c;
                }
                if(policyIdToQuoteListMap.containsKey(polID)){
                    policyIdToQuoteListMap.get(polID).add(quo);
                }else{
                    policyIdToQuoteListMap.put(polID,new List<Quote> {quo});
                }
            }
            
            system.debug('## policyIdToQuoteListMap -- '+policyIdToQuoteListMap);
            
            //From the policyIdToQuoteListMap, take the oldest bound quote from each of the policy ID
            List<Quote> quoteListToClone = new List<Quote>();
            for(String key: policyIdToQuoteListMap.keySet()){
                List<Quote> quoteList = policyIdToQuoteListMap.get(key);
                if(quoteList.size() > 1){
                    quoteListToClone.add(quoteList[0]);
                }else{
                    quoteListToClone.addAll(quoteList);
                }
            }
            
            system.debug('## quoteListToClone -- '+quoteListToClone);
            
            //Segregate quote swhich are related to base opportunity
            List<Quote> quoteListToCloneFromBaseOpp = new List<Quote>(); //These quotes will be cloned with all the related records
            for(Quote quo: quoteListToClone){
                if(quo.OpportunityId == selectedQuote.OpportunityId){
                    quoteListToCloneFromBaseOpp.add(quo);
                }
            }
            
            system.debug('## quoteListToCloneFromBaseOpp -- '+quoteListToCloneFromBaseOpp);
            
            if(quoteListToCloneFromBaseOpp.isEmpty()){
                Database.rollback(sp);
                result.error = 'Error during cloning records';
                return result;
            }
            
            //Clone quotes for Correction
            //List<Quote> quoteClonedCorrectionType = cloneRecords.cloneQuote(quoteListToClone);
            List<Quote> quoteClonedCorrectionType = cloneRecords.cloneQuote(quoteListFromPolicy);
            for(Quote q: quoteClonedCorrectionType){
                q.Status = 'Correction';
                q.Quote_Type__c = 'Correction';
                q.Endorsement_Effective_Date__c = Date.today();
                q.Endorsement_Quote_Bound_Date__c = System.now();
                
                if(q.Fee__c != null){
                    q.Fee__c = -1 * q.Fee__c;
                }
                if(q.Actual_Premium__c != null){
                    q.Actual_Premium__c = -1 * q.Actual_Premium__c;
                }
                if(q.Broker_Netted_Down_Premium__c != null){
                    q.Broker_Netted_Down_Premium__c = -1 * q.Broker_Netted_Down_Premium__c;
                }
                if(q.Total_Cost_to_Client__c != null){
                    q.Total_Cost_to_Client__c = -1 * q.Total_Cost_to_Client__c;
                }
                if(q.IPT_on_Broker_Netted_Down_Premium__c != null){
                    q.IPT_on_Broker_Netted_Down_Premium__c = -1 * q.IPT_on_Broker_Netted_Down_Premium__c;
                }
            }
            system.debug('## quoteClonedCorrectionType -- '+quoteClonedCorrectionType);
            
            //Change status & type of orignal quotes
            //for(Quote quote: quoteListToClone){
            for(Quote quote: quoteListFromPolicy){
                quote.Status = 'Cancelled';
            }            
            
            //Clone opportunity
            Opportunity baseOpp = [SELECT Id,Account.Name,Account.BillingAddress,Account.KYC_Date__c, AccountId, RecordType.Name, 
                                   Name, StageName, Amount, CloseDate, Type, Pricebook2Id, ContactId, ContractId, Attachment_Point__c, 
                                   Eligibility_Approver__c, Eligibility_Approval_Date_Time__c, Loss_Reason__c, Innovisk_Entity_ID__c, 
                                   Product__c, QP_link__c, Create_From_Quote_Process__c, Account_Clearance__c,Total_Revenues__c,
                                   Current_Liabilities__c, Renewed__c, Policy_Link__c, Expiration_Date__c, MPL_Professional_Services__c, 
                                   Effective_Date__c, Service_Classification__c, Industry__c, Prior_Policy__c, Retroactive_Date__c, 
                                   UW_Link__c, Retroactive_Date_Docs__c, Eplace_Score__c, Service_to_Run__c,Current_Assets__c,Total_Liabilities__c,
                                   Parent_Opportunity__c, Agency__c, Received_Date__c, Source__c, Effective_Date_Docs__c, UW_Status__c,
                                   Coverage_Product_Options__c, Policy__c, Product_Name__c, AnnualRevenue__c, Main_Profession__c, 
                                   Largest_Work_Type__c, Professional_Business_Description__c, Tax_Country__c,Net_Income__c,Total_Assets__c,
                                   Retained_Earnings__c,Long_Term_Debt__c, Competing_Insurer__c, Submission_Status__c, Transaction_Status__c, 
                                   (select Id,Rating_Modifier_Code__c,Rating_Modifier_Value__c,Name from Rating_Modifiers__r)
                                   FROM Opportunity 
                                   WHERE Id =: selectedQuote.OpportunityId                                      
                                   ORDER BY CreatedDate DESC LIMIT 1][0];    
            system.debug('##  baseOpp -- '+baseOpp);
            
            Opportunity clonedOpp = cloneRecords.cloneOpportunityDetails(baseOpp);
            clonedOpp.AccountId = baseOpp.AccountId;
            clonedOpp.Parent_Opportunity__c = baseOpp.Id;
            clonedOpp.Transaction_Status__c = 'Inactive';
            //clonedOpp.Type = endorsementType; 
            clonedOpp.StageName = 'Qualified';                                                             
            clonedOpp.Azure_ID__c = new GuidUtil().NewGuid(); 
            if(baseOpp.Type == 'Renewal') clonedOpp.Received_Date__c = null;
            system.debug('## cloned opp -- '+clonedOpp);
            
            GlobalStaticVar.byPassOpportunityTrigger = true;
            insert clonedOpp;                        
            
            if(clonedOpp.Id == null){
                Database.rollback(sp);
                result.oppId = baseOpp.Id;
                result.error = 'Error during cloning opportunity';
                return result;
            }

            //Clone Notes #58474
            List<ContentDocumentLink> newNotes = new List<ContentDocumentLink>();
            List<ContentDocumentLink> items = [select ContentDocument.title , ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: baseOpp.Id];
            
            if(!items.isEmpty()){
                for(ContentDocumentLink note : items){
                    ContentDocumentLink newNote = note.clone(false,true,false,false);
                    newNote.LinkedEntityId = clonedOpp.Id;
                    newNotes.add(newNote);
                }
            }
            if(!newNotes.isEmpty()){
                insert newNotes;
            }
            
            /*Set orignal Opportunity's Transaction status as Inactive
            if(activeOppId != null){
                Opportunity activeOpp = [SELECT Id, Name, Transaction_Status__c FROM Opportunity WHERE Id =:activeOppId][0];
                activeOpp.Transaction_Status__c = 'Inactive';
                
                GlobalStaticVar.byPassOpportunityTrigger = true;
                update activeOpp;
            }*/
            
            //Clone related objects
            cloneRecords.cloneOppRelatedRecords(baseOpp.Id,clonedOpp);
            
            //Clone base opp quotes        
            //List<Quote> clonedQuoteList = cloneRecords.cloneQuote(quoteListToCloneFromBaseOpp);        
            //List<Quote> clonedQuoteList = cloneRecords.cloneQuote(quoteListToClone);      US#46875  
            List<Quote> clonedQuoteList = new List<Quote>();
            List<String> quoteIdList = new List<String>(); //Ids of orignal quotes which were cloned
            for(Quote quo: quoteListToClone){
                Quote quoteClone = quo.clone(false, true, false, false);
                //if(quoteClone.Quote_Type__c == 'New Business'){//52596
                    quoteClone.Parent_Quote__c = quo.Id;  //US#46875
                //}               
                clonedQuoteList.add(quoteClone);
            }
            
            for(Quote quoteClone: clonedQuoteList){
                quoteClone.Status = 'In Progress';
                quoteClone.Rating_Status__c = '';
                quoteClone.OpportunityId = clonedOpp.Id;
                quoteClone.Technical_Fee__c = 0;
                quoteCLone.Fee__c = 0;
                quoteClone.Endorsement_Effective_Date__c = Date.today();
                quoteClone.Quote_Action__c = 'CancelAndReplace';
                
                //quoteClone.Endorsement_Reason__c = endorsementReason != null ? endorsementReason : null;
                //quoteClone.Endorsement_Reason_Other__c = endoresementReasonOther;                  
                //quoteClone.Endorsement_Effective_Date__c = effDate != null ? Date.valueOf(effDate) : null;
                //quoteClone.UW_Reason__c = '';
                //quoteClone.Overall_UW_Codes__c = '';
            }
            
            //DMLs
            GlobalStaticVar.byPassQuoteTrigger = true;
            GlobalStaticVar.byPassFreeFormEndorsementTrigger = true;
            GlobalStaticVar.byPassSubjectivityTrigger = true;
            
            if(!quoteClonedCorrectionType.isEmpty()){
                insert quoteClonedCorrectionType;
            }
            
            /*if(!quoteListToClone.isEmpty()){
					update quoteListToClone;
			}*/
            
            if(!clonedQuoteList.isEmpty()){
                insert clonedQuoteList;
            }

            result.cloneQuoteId = clonedQuoteList[0].Id;
            
            //Containers with quote Ids for further use in quote related record cloning
            Map<String,String> parentQuoteIdToClonedQuoteIdMap = new Map<String,String>();            
            set<string> clonedQuoteId = new set<string>();
            List<Change_Log__c> chnageLogInsertList = new List<Change_Log__c>();
            
            //Create transaction object records for the new cloned opp and all policy
            List<Transactions__c> clonedOppTransactionRecords = new List<Transactions__c>();
            for(Quote quo: clonedQuoteList){
                Transactions__c transRec = new Transactions__c();
                transRec.Submission__c = quo.OpportunityId;
                transRec.Policy__c = quo.Policy__c;
                clonedOppTransactionRecords.add(transRec);
                clonedQuoteId.add(quo.Id);
                //For cloning related records
                parentQuoteIdToClonedQuoteIdMap.put(quo.Parent_Quote__c,quo.Id);                
                quoteIdList.add(quo.Parent_Quote__c);
                
                //Remove Parent_Quote__c US#46875
                if(quo.Quote_Type__c == 'New Business'){
                    quo.Parent_Quote__c = null;  
                } 

                if(String.isNotBlank(quo.Master_Binder__c)){ 
                    Quote quoteDoc = QuoteCompareItemWrapper.getQuoteDocumentLinks(quo);
                    quo.Policy_Wording_Document__c = quoteDoc.Policy_Wording_Document__c;  
                    if(quo.Layer__c != 'Excess')	quo.IPID_Document__c = quoteDoc.IPID_Document__c;  	                    
                }
                
                //create changelog for all created quotes
                Change_Log__c changelog = CommonUtil.createChangeLog(quo.Policy__c, 'Full Cancel & Replace', quo.OpportunityId);
                chnageLogInsertList.add(changelog);
            }
            
            if(!clonedQuoteList.isEmpty()){
                update clonedQuoteList;
            }
            
            if(!clonedOppTransactionRecords.isEmpty()){
                insert clonedOppTransactionRecords;
            }
            
            if(!chnageLogInsertList.isEmpty()){
                insert chnageLogInsertList;
            }
            
            //clone quote related records
            cloneRecords.cloneQuoteRelatedRecords(quoteIdList, parentQuoteIdToClonedQuoteIdMap,clonedOpp.Id);
            
            if(!quoteListFromPolicy.isEmpty()){
                update quoteListFromPolicy;
            }
            
            //Delete Referrals for full cancel and replace
            List<Referral_Reason__c> referralReasonsList = [select Id From Referral_Reason__c  WHERE Quote__c IN: clonedQuoteId];
            if(!referralReasonsList.isEmpty()) delete referralReasonsList;            
            
            //Create Quote options  ***Already getting added during clone***
            //QuoteTriggerHandler.addQuoteOptions(clonedQuoteList);            
            
            result.oppId = clonedOpp.Id;
                    
            return result;
            
        }catch (DMLException ex){
            Database.rollback(sp);
            system.debug('error DML: '+ex.getMessage()+' '+ex.getLineNumber()+' '+ex.getStackTraceString()+' '+ex.getCause());
            result.error = ex.getDmlMessage(0);
            return result;
        }catch(exception ex){
            Database.rollback(sp);
            system.debug('error: '+ex.getMessage()+' '+ex.getLineNumber());
            result.error = ex.getMessage();
            return result;
        }
    }
}