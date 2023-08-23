public class ContentDocumentLinkQueueable implements Queueable,Database.AllowsCallouts {
    
    private List<String> contentDocs;

    public ContentDocumentLinkQueueable(List<String> contentDocs) {
        this.contentDocs = contentDocs;
    }
  	public void execute(QueueableContext context) {
			try {

			API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Google_API_Nearby');

			String baseUri = apiSetting.Base_Url__c + apiSetting.Endpoint__c;
			String baseUriParams = '';  
            
			baseUriParams += '&key=' + apiSetting.API_Key__c;

	        String baseUriFull = baseUri + baseUriParams;
	        
			HttpRequest req = new HttpRequest();
	        req.setEndpoint(baseUriFull);
	        req.setMethod(apiSetting.Method__c);
	        req.setTimeout(Integer.valueOf(Label.ApiTimeOut));

	        Http h = new Http();
	        HttpResponse res = h.send(req);
	       
	        if(res.getStatusCode() == 200) {
                if(!contentDocs.isEmpty()) {
                    List<ContentDocumentLink> lst = new List<ContentDocumentLink>();
                    for(String contentDoc : contentDocs) {
                        String[] tmp = contentDoc.split('_');
                        lst.add(new ContentDocumentLink(ContentDocumentId = tmp[0],
                                                                                    LinkedEntityId = tmp[1]));
                    }
                    if(!lst.isEmpty())  {
                        system.debug('lst :' + lst);
                        try{
                      	TriggerHandler.bypass('ContentDocumentLinkTriggerBaseHandler');
                            insert lst;
        				TriggerHandler.clearBypass('ContentDocumentLinkTriggerBaseHandler');
                            
                        } catch(Exception ex) {
                            system.debug(ex.getMessage());
                        }
                        
                    }
                }
	        }    
        } catch (Exception ex) {
        }       
    }
}