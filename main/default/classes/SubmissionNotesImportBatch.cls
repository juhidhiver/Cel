/**************************************************************************************************
 * Class Name: SubmissionNotesImportBatch
 * Author: Vinayesh R
 * Date: 27-May-2021
 * Description: One time Batch Program to upload legacy Submission Notes
 **************************************************************************************************/
global class SubmissionNotesImportBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        String strQuery = 'Select SubmissionId__c, Title__c, Content__c, Error_Flag__c, Error_Message__c from TempNoteContent__c Order By CreatedDate';
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<TempNoteContent__c> importedNotesList) {
        set<String> subIds = new set<String>();
        for(TempNoteContent__c tnc : importedNotesList){
            if(tnc.SubmissionId__c != null){
                subIds.add(tnc.SubmissionId__c);
            }
        }
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id From Opportunity Where Id in :subIds]);
        Map<Id,Id> uWMap = new Map<Id,Id>();
        for(Quote_Process__c objUW : [Select Id,Submission__c From Quote_Process__c Where Submission__c in :subIds]){
            uWMap.put(objUW.Submission__c, objUW.Id);
        }
        Map<String,List<ContentNote>> subNotesMap = new Map<String,List<ContentNote>>();
        //Map<String,List<TempNoteContent__c>> unmappedNotes = new Map<String,List<TempNoteContent__c>>();
        List<TempNoteContent__c> unmappedNotes = new List<TempNoteContent__c>();
        List<ContentNote> cNotes = new List<ContentNote>();
        for(TempNoteContent__c tnc : importedNotesList){
            if(!oppMap.containsKey(tnc.SubmissionId__c)){
                tnc.Error_Flag__c = true;
                tnc.Error_Message__c = 'Submission not found.';
                // if(!unmappedNotes.containsKey(tnc.SubmissionId__c)){
                //     unmappedNotes.put(tnc.SubmissionId__c, new List<TempNoteContent__c>());
                // }
                // unmappedNotes.get(tnc.SubmissionId__c).add(tnc);
                unmappedNotes.add(tnc);
                continue;
            }
            ContentNote cn = new ContentNote();
            cn.Title = tnc.Title__c;
            blob b = Blob.valueOf(tnc.Content__c);
            cn.Content = b;
			cNotes.add(cn);
            if(tnc.SubmissionId__c != null && uWMap.containsKey(tnc.SubmissionId__c)){
                String uwId = uWMap.get(tnc.SubmissionId__c);
                if(!subNotesMap.containsKey(uwId)){
                    subNotesMap.put(uwId, new List<ContentNote>());
                }
                subNotesMap.get(uwId).add(cn);
            }            
        }

        TriggerHandler.bypass('ContentDocumentLinkTriggerHandler');
        if(cNotes.size() > 0) insert cNotes;

        
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for(String sId : subNotesMap.keySet()){
            for(ContentNote cn : subNotesMap.get(sId)){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cn.Id;
                cdl.LinkedEntityId = sId;
                cdlList.add(cdl);
        	}
        }
        
        if(cdlList.size() > 0) insert cdlList;

        TriggerHandler.clearBypass('ContentDocumentLinkTriggerHandler');

        if(unmappedNotes.size() > 0) update unmappedNotes;
        
    }

    global void finish(Database.BatchableContext BC) {

    }
}