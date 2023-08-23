public inherited sharing class ContentDocumentLinkTriggerHandler extends TriggerHandler {
    
    private List<ContentDocumentLink> oldDataList;
    private List<ContentDocumentLink> newDataList;
    private Map<Id, ContentDocumentLink> newDataMap;
    private Map<Id, ContentDocumentLink> oldDataMap;
    
    public ContentDocumentLinkTriggerHandler(){  
        this.oldDataList = (List<ContentDocumentLink>) Trigger.old;
        this.oldDataMap = (Map<Id, ContentDocumentLink>) Trigger.oldMap;
        this.newDataList = (List<ContentDocumentLink>) Trigger.new;
        this.newDataMap = (Map<Id, ContentDocumentLink>) Trigger.newMap;
    
    }
    
    public override void beforeInsert(){
        system.debug(this.newDataList);
    }
    
	public override void afterInsert(){
        List<ContentDocumentLink> lstCntLinks = this.newDataList; 
		String strObjPrefix;
		Set<Id> setCntDocIds = new set<Id>();
		set<Id> setAccIds = new set<Id>();
		Map<Id, List<ContentDocumentLink>> conDocToConDocLink = new Map<Id, List<ContentDocumentLink>>();
		for (ContentDocumentLink clIterator : lstCntLinks){
			setCntDocIds.add(clIterator.ContentDocumentId);
            if(conDocToConDocLink.get(clIterator.Id) != null) {
                conDocToConDocLink.get(clIterator.ContentDocumentId).add(clIterator);
            } else {
                conDocToConDocLink.put(clIterator.ContentDocumentId, new List<ContentDocumentLink>{clIterator});
            }
		}

		// Get content document object for current set of files
		map<Id, ContentDocument> mapContentDocuments = new map<Id, ContentDocument>([SELECT Id, Title, FileExtension, OwnerId
		                                                                             FROM ContentDocument 
		                                                                             WHERE Id IN :setCntDocIds]);
		List<ContentVersion> cv = [SELECT Id, ContentDocument.Title
		                           FROM ContentVersion 
		                           WHERE ContentDocumentId IN :setCntDocIds];

		List<Coverage__c> coverages = getCoverageByProducts(new List<String>{'MPL', 'Cyber'});


		List<ContentDistribution> cds = new List<ContentDistribution>();
		for (ContentVersion ver : cv){
			ContentDistribution cd = new ContentDistribution();
			cd.Name = ver.ContentDocument.Title;
			cd.ContentVersionId = ver.Id;
			cd.PreferencesAllowViewInBrowser = true;
			cd.PreferencesLinkLatestVersion = true;
			cd.PreferencesNotifyOnVisit = false;
			cd.PreferencesPasswordRequired = false;
			cd.PreferencesAllowOriginalDownload = true;
			cds.add(cd);
		}
		insert cds;
		System.debug('@cds '+cds);
		List<String> urls = new List<String>();
		List<Coverage__c> updatedCov = new List<Coverage__c>();


        List<String> callOuts = new List<String>();
		List<ContentDistribution> contentDistributions = [SELECT Id,Name, DistributionPublicUrl,
                                                          ContentVersion.ContentDocument.Id
		                                   FROM ContentDistribution 
		                                   WHERE ID IN :cds];
		for (ContentDistribution content : contentDistributions){
			urls.add(content.DistributionPublicUrl);
			Coverage__c cov = null;
			for (Coverage__c item : coverages){
				if(item.Form_Number__c.length() >= 16){
					String temp = item.Form_Number__c.substring(0, item.Form_Number__c.length()-6);
					System.debug('contains '+ content.Name.contains(temp));
					if (content.Name.contains(temp)){
						cov = item;
						break;
					}
				}
			}
			if(cov != null){
				cov.Link_Document__c = content.DistributionPublicUrl;
				content.RelatedRecordId = cov.Id;
				String contentDocumentId = content.ContentVersion.ContentDocument.Id;
				if(String.isNotBlank(contentDocumentId) && String.isNotBlank(cov.Id)) {
					if(!callOuts.contains(contentDocumentId + '_' + cov.Id)) {
						callOuts.add(contentDocumentId + '_' + cov.Id);
					}
				}
				updatedCov.add(cov);
			}
        }
		System.debug('updatedCov ' + updatedCov);
		update updatedCov;
		System.enqueueJob(new ContentDocumentLinkQueueable(callOuts));
	}
    
    public override void afterDelete() {
    }

	public static List<Coverage__c> getCoverageByProducts(List<String> productnames){
		List<Coverage__c> result = new List<Coverage__c>();

		try{
			result = [SELECT Id, Name, Coverage_Product__c, Form_Number__c
			          FROM Coverage__c 
			          WHERE Coverage_Type__c = 'Endorsement' AND Coverage_Product__c IN :productnames AND Form_Number__c != NULL]; //TS added filter to not include Endorsement Coverage records
		} catch (Exception ex){
			result = new List<Coverage__c>();
		}

		return result;
	}
}