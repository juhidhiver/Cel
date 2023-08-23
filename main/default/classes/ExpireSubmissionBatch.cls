global class ExpireSubmissionBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('## test');
        List<String> quoteStatus = new List<String>{'In Progress','Rated','Referred','Quoted','Presented'};
        List<String> oppStageName = new List<String>{'New','Qualified','Prospect'};   
		String rdname = 'Aqueous';            
        String strQuery = 'SELECT Id, RecordType.Name, StageName,Effective_Date__c,LastModifiedDate, CloseDate,Submission_Loss_Detail_Last_Modified__c,' +            
                'Rating_Modifier_Last_Modified__c, (SELECT LastModifiedDate,Rating_Modifier_Factors_Last_Modified__c,'+           
                'Coverages_Line_Item_Last_Modified__c,Free_Form_Endorsement_Last_Modified__c,Subjectivity_Last_Modified__c,'+
                'Additional_Interest_Last_Modified__c,Quote_Location_Last_Modified__c,'+ 
                'Insurer_Layer_Limit_Last_Modified__c FROM Quotes WHERE Status IN: quoteStatus),'+
                '(Select Id,LastModifiedDate from UW_Analysis__r) FROM Opportunity WHERE StageName IN: oppStageName AND RecordType.Name =:rdname';
        system.debug('## query---'+strQuery);
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> opportunityList) {
        List<Opportunity> opptUpdates = new List<Opportunity>();
        List<Quote> quoteUpdates = new List<Quote>();
        Map<Id, List<Quote>> oppIdToQuoteMap = new Map<Id, List<Quote>>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        
        //Get Opp & Quote Ids
        for(Opportunity oppt : opportunityList){
            oppIds.add(oppt.Id);
            if(!oppt.Quotes.isEmpty()){
                List<Quote> quoteList = oppt.Quotes;
                oppIdToQuoteMap.put(oppt.Id,quoteList);
                for(Quote quo: quoteList){
                    quoteIds.add(quo.Id);
                }
            }
        }
        
        try{
            //Get related records for last date comparison
            Map<Id, List<Document_Revision__c>> oppIdToDocRevMap = new Map<Id, List<Document_Revision__c>>();
            Map<Id, List<Referral_Reason__c>> oppIdToReferralReasonMap = new Map<Id, List<Referral_Reason__c>>();
            if(quoteIds != null){
                List<Quote> quoteList = [SELECT Id, OpportunityId, 
                                         (SELECT Id, Name, LastModifiedDate FROM Document_Revisions__r),
                                         (SELECT Id, Name, LastModifiedDate FROM Referral_Reasons__r)
                                         FROM Quote
                                         WHERE Id IN:quoteIds];
                for(Quote quote: quoteList){
                    if(!quote.Document_Revisions__r.isEmpty()){
                        if(oppIdToDocRevMap.containsKey(quote.OpportunityId)){
                            oppIdToDocRevMap.get(quote.OpportunityId).addAll(quote.Document_Revisions__r);
                        }else{
                            oppIdToDocRevMap.put(quote.OpportunityId,quote.Document_Revisions__r);                            
                        }
                    }
                    
                    /*if(!quote.Referral_Reasons__r.isEmpty()){
						if(oppIdToReferralReasonMap.containsKey(quote.OpportunityId)){
						oppIdToReferralReasonMap.get(quote.OpportunityId).addAll(quote.Referral_Reasons__r);
					}else{
						oppIdToReferralReasonMap.put(quote.OpportunityId,quote.Referral_Reasons__r);                            
						}
					}*/
                }
            }
            
            //Check for last modified in all obj records
            for(Opportunity oppt : opportunityList){
                Date finalExpiryDate = Date.today(); //To check with todays date for expiration
                system.debug('## finalExpiryDate---'+finalExpiryDate);
                DateTime dT = oppt.LastModifiedDate;
                Date oppLastModiDate = Date.newinstance(dT.year(), dT.month(), dT.day());
                system.debug('## oppLastModiDate---'+oppLastModiDate);
                Boolean toExpireSubmissionFlag = false;
                if(oppLastModiDate.daysBetween(finalExpiryDate) > 90){
                    toExpireSubmissionFlag = true;
                }else if(oppLastModiDate.daysBetween(finalExpiryDate) <= 90){
                    toExpireSubmissionFlag = false;
                    continue;
                }
                
                if(oppt.Rating_Modifier_Last_Modified__c != null){
                    DateTime dtSRtm = oppt.Rating_Modifier_Last_Modified__c;
                    Date RMLastModified = Date.newinstance(dtSRtm.year(), dtSRtm.month(), dtSRtm.day());
                    if(RMLastModified.daysBetween(finalExpiryDate) > 90){
                        toExpireSubmissionFlag = true;
                    }else if(RMLastModified.daysBetween(finalExpiryDate) <= 90){
                        toExpireSubmissionFlag = false;
                        continue;
                    }
                }
                
                if(oppt.Submission_Loss_Detail_Last_Modified__c != null){
                    DateTime dtSub = oppt.Submission_Loss_Detail_Last_Modified__c;
                    Date subLossDetailLastModified = Date.newinstance(dtSub.year(), dtSub.month(), dtSub.day());
                    if(subLossDetailLastModified.daysBetween(finalExpiryDate) > 90){
                        toExpireSubmissionFlag = true;
                    }else if(subLossDetailLastModified.daysBetween(finalExpiryDate) <= 90){
                        toExpireSubmissionFlag = false;
                        continue;
                    }
                }
                
                if(!oppt.UW_Analysis__r.isEmpty()){
                    for(UW_Analysis__c uw : oppt.UW_Analysis__r){
                        DateTime dtUW = uw.LastModifiedDate;
                        Date UWLastModified = Date.newinstance(dtUW.year(), dtUW.month(), dtUW.day());
                        if(UWLastModified.daysBetween(finalExpiryDate) > 90){
                           toExpireSubmissionFlag = true;
                        }else if(UWLastModified.daysBetween(finalExpiryDate) <= 90){
                            toExpireSubmissionFlag = false;
                            continue;
                        }
                    }
                }
                
                if(oppt.Quotes.isEmpty()) continue;                
                
                for(Quote qt : oppt.Quotes){
                    Map<String,Object> quoteFieldsMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(qt));
                    system.debug('## quoteFieldsMap -- '+quoteFieldsMap);
                    for(String fieldVals :quoteFieldsMap.keySet()){
                        if(fieldVals == 'LastModifiedDate' || fieldVals == 'Rating_Modifier_Factors_Last_Modified__c' || 
                           fieldVals == 'Additional_Interest_Last_Modified__c' || 
                           fieldVals == 'Quote_Location_Last_Modified__c' || 
                           fieldVals == 'Coverages_Line_Item_Last_Modified__c' || 
                           fieldVals == 'Free_Form_Endorsement_Last_Modified__c' || 
                           fieldVals == 'Subjectivity_Last_Modified__c' || 
                           fieldVals == 'Insurer_Layer_Limit_Last_Modified__c'){
                               Object dte = quoteFieldsMap.get(fieldVals);
                               DateTime resultDateTime = DateTime.ValueofGmt(dte.toString().replace('T', ' ')); 
                               Date dateValue = Date.valueOf(resultDateTime);
                               if(dateValue.daysBetween(finalExpiryDate) > 90){
                                   toExpireSubmissionFlag = true;                                   
                               }else if(dateValue.daysBetween(finalExpiryDate) <= 90){
                                   toExpireSubmissionFlag = false;
                                   continue;
                               }
                           }
                    }
                }
                
                if(!oppIdToDocRevMap.get(oppt.Id).isEmpty()){
                    List<Document_Revision__c> docRe = oppIdToDocRevMap.get(oppt.Id);
                    for(Document_Revision__c doc: docRe){
                        DateTime dtDoc = doc.LastModifiedDate;
                        Date docLastModified = Date.newinstance(dtDoc.year(), dtDoc.month(), dtDoc.day());
                        if(docLastModified.daysBetween(finalExpiryDate) > 90){
                            toExpireSubmissionFlag = true;                                   
                        }else if(docLastModified.daysBetween(finalExpiryDate) <= 90){
                            toExpireSubmissionFlag = false;
                            continue;
                        }
                    }
                }
                
                /*if(!oppIdToReferralReasonMap.get(oppt.Id).isEmpty() && toExpireSubmissionFlag == false){
                    List<Referral_Reason__c> referralReason = oppIdToReferralReasonMap.get(oppt.Id);
                    for(Referral_Reason__c ref: referralReason){
                        DateTime dtRef = ref.LastModifiedDate;
                        Date refLastModified = Date.newinstance(dtRef.year(), dtRef.month(), dtRef.day());
                        if(refLastModified.daysBetween(finalExpiryDate) > 90){
                            oppt.StageName = 'Closed Lost';
                            oppt.Loss_Reason__c = 'No Activity';
                            opptUpdates.add(oppt);
                            continue;
                        }
                    }
                }*/
                
                if(toExpireSubmissionFlag){
                    oppt.StageName = 'Closed Lost';
                    oppt.Loss_Reason__c = 'No Activity';
                    opptUpdates.add(oppt);
                }
            }
            
            if(!opptUpdates.isEmpty()){
                update opptUpdates;
                Set<Id> quoteIdsSet = new Set<Id>();
                for(Opportunity op:opptUpdates){
                    List<Quote> quoList = oppIdToQuoteMap.get(op.Id);
                    for(Quote qu: quoList){
                        quoteIdsSet.add(qu.Id);                        
                    }
                }
                
                if(quoteIdsSet != null){
                    for(Quote qts:[SELECT Id, Closed_Reason__c, Status FROM Quote WHERE Id IN:quoteIdsSet]){
                        qts.Closed_Reason__c = 'Expired';
                        qts.Status = 'Closed';
                        quoteUpdates.add(qts);
                    }
                }
                
                if(!quoteUpdates.isEmpty()){
                    update quoteUpdates;
                }
            }
        }catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}