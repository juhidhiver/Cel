/**************************************************************************************************
 * Class Name: ContentDocumentLinkTriggerHandler
 * Author: 
 * Date: 
 * Description: Class to keep all methods of content document link
 **************************************************************************************************/
public inherited sharing class ContentDocumentLinkTriggerHandler_CEL extends TriggerHandler {
    
    private List<ContentDocumentLink> oldDataList;
    private List<ContentDocumentLink> newDataList;
    private Map<Id, ContentDocumentLink> newDataMap;
    private Map<Id, ContentDocumentLink> oldDataMap;

	public ContentDocumentLinkTriggerHandler_CEL(List<ContentDocumentLink> newDataList, List<ContentDocumentLink> oldDataList, Map<Id, ContentDocumentLink> newDataMap, Map<Id, ContentDocumentLink> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    }
    
    public override void beforeInsert(){
		
    }
    
	public override void afterInsert(){
        insertCoveragesByLinks(this.newDataList);
	}
    
    public override void afterDelete() {

    }

	/*************************************************
    * Method Name: insertCoveragesByLinks
    * Author: 
    * Date: 
    * Params: List<ContentDocumentLink> newDataList
    * Return: 
    * Description: Link content versions with the coverages of CELERITY
     *************************************************/
	public static void insertCoveragesByLinks(List<ContentDocumentLink> newDataList){
		String strObjPrefix;
		Set<Id> setCntDocIds = new set<Id>();
		set<Id> setAccIds = new set<Id>();
		Map<Id, List<ContentDocumentLink>> conDocToConDocLink = new Map<Id, List<ContentDocumentLink>>();
		for (ContentDocumentLink clIterator : newDataList){
			setCntDocIds.add(clIterator.ContentDocumentId);
            if(conDocToConDocLink.get(clIterator.Id) != null) {
                conDocToConDocLink.get(clIterator.ContentDocumentId).add(clIterator);
            } else {
                conDocToConDocLink.put(clIterator.ContentDocumentId, new List<ContentDocumentLink>{clIterator});
            }
		}

		// Get content document object for current set of files
		map<Id, ContentDocument> mapContentDocuments = new map<Id, ContentDocument>(ContentDocumentQueryUtil.fetchContentDocumentsByIDs(setCntDocIds));
		List<ContentVersion> cv = ContentVersionQueryUtil.fetchContentVersionsByIDs(setCntDocIds);

		List<Coverage__c> coverages = getCoverageByProducts(new List<String>{'MPL', 'Cyber','Private Company Combo'});


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
		List<String> urls = new List<String>();
		List<Coverage__c> updatedCov = new List<Coverage__c>();


        List<String> callOuts = new List<String>();
		List<ContentDistribution> contentDistributions = ContentDistributionQueryUtil.fetchContentDistributionByIDs(cds);
		for (ContentDistribution content : contentDistributions){
			urls.add(content.DistributionPublicUrl);
			Coverage__c cov = null;
			for (Coverage__c item : coverages){
				if(item.Form_Number__c.length() >= 16){
					String temp = item.Form_Number__c.substring(0, item.Form_Number__c.length()-6);
					System.debug('item '+ item.Name);
                    
					if (content.Name.contains(temp)){
                       	cov = item;
                        break;
					}
				}
                else if(item.Form_Number__c.length()>0 && item.Coverage_Product__c != null){
                    String temp = item.Form_Number__c;
		
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
        update updatedCov;
        System.enqueueJob(new ContentDocumentLinkQueueable(callOuts));
	}

	/*************************************************
    * Method Name: getCoverageByProducts
    * Author: 
    * Date: 
    * Params: List<String> productnames
    * Return: 
    * Description: get CELERITY coverages
     *************************************************/
	public static List<Coverage__c> getCoverageByProducts(List<String> productnames){
		List<Coverage__c> result = new List<Coverage__c>();

		try{
			result = CoverageQueryUtil.fetchCoveragesByProducts(productnames);
            
            //TS added filter to not include Endorsement Coverage records
		} catch (Exception ex){
			result = new List<Coverage__c>();
		}

		return result;
	}
}