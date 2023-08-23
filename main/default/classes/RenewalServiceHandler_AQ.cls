public class RenewalServiceHandler_AQ {


public static AutoRenewalsWrapper autoAssignRenewals(AutoRenewalsWrapper wrapperAutoRenewals, List<Renewal__c> listOfRenewals){

   List<String> publicGroupUsers = new List<String>();
   List<Renewal__c> renewalListUpdate = new List<Renewal__c>(); 

    for(User user : [select Id from user where Is_AQ_Auto_Renewals_Underwriter__c = true]){
      publicGroupUsers.add(user.Id);
   }

    
    
   for( Renewal__c renewalRecord  : [select id,Policy__c,Policy__r.Account__c,Assigned_Underwriter__c from Renewal__c where Id IN: listOfRenewals]){

      if( renewalRecord.Policy__c != null && renewalRecord.Policy__r.Account__c != null){

    
    
           /****************** If map is empty then assign first user from group ************/
           if(wrapperAutoRenewals == null || (wrapperAutoRenewals != null && wrapperAutoRenewals.mapOfAccountVsUser.isEmpty())){
              if(wrapperAutoRenewals == null){
                        wrapperAutoRenewals = new RenewalServiceHandler_AQ.AutoRenewalsWrapper();
                        wrapperAutoRenewals.index = 0;
                        wrapperAutoRenewals.mapOfAccountVsUser = new Map<String,String>();
                  }
                renewalRecord.Assigned_Underwriter__c = publicGroupUsers[wrapperAutoRenewals.index];

                wrapperAutoRenewals.mapOfAccountVsUser.put(renewalRecord.Policy__r.Account__c,renewalRecord.Assigned_Underwriter__c);
                
               }
               else if(!wrapperAutoRenewals.mapOfAccountVsUser.isEmpty()){

                  /******************** If user map contains Account whom we already have assigned the user */
                   if(wrapperAutoRenewals.mapOfAccountVsUser.containsKey(renewalRecord.Policy__r.Account__c)){

                    renewalRecord.Assigned_Underwriter__c = wrapperAutoRenewals.mapOfAccountVsUser.get(renewalRecord.Policy__r.Account__c);

                   }
                   else{

                     /*************************** Emptying the map so that map gets empty if account id gets changed to maintain the heap size*/
                     wrapperAutoRenewals.mapOfAccountVsUser = new Map<String,String>();
                  
                     renewalRecord.Assigned_Underwriter__c = publicGroupUsers[wrapperAutoRenewals.index];

                     wrapperAutoRenewals.mapOfAccountVsUser.put(renewalRecord.Policy__r.Account__c,renewalRecord.Assigned_Underwriter__c);
                    

                  }

               }

                   
               /********* Indexing Logic ***********/
               if(wrapperAutoRenewals.index <= publicGroupUsers.size()-2){
                  wrapperAutoRenewals.index++;
               }
               else{
                  wrapperAutoRenewals.index = 0;
               }

            }

            renewalListUpdate.add(renewalRecord);
          }

          if(renewalListUpdate.size()>0){
            system.debug('Assigned Underwriter Before Update'+renewalListUpdate[0].Assigned_Underwriter__c);
            GlobalStaticVar.byPassRenewalTrigger = true;
            update renewalListUpdate;
            system.debug('listOfRenewals update'+renewalListUpdate[0].Id);
             system.debug('Assigned Underwriter After Update'+renewalListUpdate[0].Assigned_Underwriter__c);
        }
          return wrapperAutoRenewals;
   }

   public static Map<String,List<Renewal__c>> emailNotificationHandler(Map<String,List<Renewal__c>> mapofBrokerAndRenewals,List<Renewal__c> listOfRenewals){


      for(Renewal__c renewalRecord : listOfRenewals){
       
         if(renewalRecord.Broker__c != null &&  renewalRecord.Broker__r.Broker_Contact__c != null){

            if(mapofBrokerAndRenewals==null ||  mapofBrokerAndRenewals.isEmpty() ){

               mapofBrokerAndRenewals = new Map<String,List<Renewal__c>>();

               mapofBrokerAndRenewals.put(renewalRecord.Broker__r.Broker_Contact__r.AccountId,new List<Renewal__c>{renewalRecord});

            }
            else if(mapofBrokerAndRenewals.containsKey(renewalRecord.Broker__r.Broker_Contact__r.AccountId)){

               mapofBrokerAndRenewals.get(renewalRecord.Broker__r.Broker_Contact__r.AccountId).add(renewalRecord);
            }
            else if(!mapofBrokerAndRenewals.containsKey(renewalRecord.Broker__r.Broker_Contact__r.AccountId)){
               
               mapofBrokerAndRenewals.put(renewalRecord.Broker__r.Broker_Contact__r.AccountId,new List<Renewal__c>{renewalRecord});
            }

         }
      }

      return mapofBrokerAndRenewals;



   }

   public static Map<String,List<ContentVersion>> fetchDocumentRelatedFiles(Set<String> documentRequired){
    
    List<ContentVersion> documents  = new List<ContentVersion>{};
    List<String> contentDocumentIds = new List<String>();
    List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>{};
    Map<String,String> documentNameMap = new Map<String,String>();
    Map<String,String> contentLinkDocMap = new Map<String,String>();
    Map<String,List<ContentVersion>> ContentVersionMap = new Map<String,List<ContentVersion>>();

    Set<Id> documentsIds = new Set<Id>();
   
    List<Document_Template__c> documentTemplates   = [select id,Document_Name__c from Document_Template__c where Document_Name__c IN:documentRequired];

    for(Document_Template__c docTemp  : documentTemplates){
      documentsIds.add(docTemp.Id);
      documentNameMap.put(docTemp.Id,docTemp.Document_Name__c.trim());
    }
    
    for(ContentDocumentLink contdocLink  : [SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink where LinkedEntityId IN:documentsIds]){
      contentDocumentIds.add(contdocLink.ContentDocumentId);
      contentLinkDocMap.put(contdocLink.ContentDocumentId,contdocLink.LinkedEntityId);
    }
    documents.addAll([
      SELECT Id, Title, FileType, VersionData, isLatest, ContentDocumentId,FileExtension
      FROM ContentVersion
      WHERE isLatest = true AND ContentDocumentId IN :contentDocumentIds
    ]);

    for (ContentVersion document: documents) {

       String documentId  = contentLinkDocMap.get(document.ContentDocumentId);
       String documentName = documentNameMap.get(documentId);

       if(!ContentVersionMap.containskey(documentName)){
         ContentVersionMap.put(documentName,new List<ContentVersion>{});
       }
       ContentVersionMap.get(documentName).add(document);
      /*  Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setBody(document.VersionData);
        attachment.setFileName(document.Title);
       attachments.add(attachment);*/
    }

    return ContentVersionMap; 

   }


   public class AutoRenewalsWrapper{
      public Map<String,String> mapOfAccountVsUser;
      public Integer index;
   }

}