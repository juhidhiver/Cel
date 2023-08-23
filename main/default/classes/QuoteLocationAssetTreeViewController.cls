/**************************************************************************************************
 * Class Name: QuoteLocationAssetTreeViewController
 * Author:
 * Date:
 * Description:
 * Revision: Ly Long
 **************************************************************************************************/
public with sharing class QuoteLocationAssetTreeViewController {
	@AuraEnabled
    public static InitObject initData(String quoteId){
    	try {
	        InitObject initObject = new InitObject();

	        // Get quote
	        Quote currentQuote = [SELECT Id, Name, OpportunityId, AccountId, Opportunity.Product__c, Opportunity.Product__r.Name
	        				      FROM Quote 
	        					  WHERE Id = :quoteId];
	        initObject.accountId = currentQuote.AccountId;
	        initObject.productId = currentQuote.Opportunity.Product__c;
	        initObject.opportunityId = currentQuote.OpportunityId;
	        
	        // Get quote location map
	        Map<Id, Quote_Location__c> mapQuoteLocation = new Map<Id, Quote_Location__c>([SELECT Id, Name,
	        																Primary_Location__c,
	                                                                        Locations__c, 
	                                                                        Locations__r.Name,
	                                                                        Locations__r.Address__c,
	                                                                        Locations__r.City__c,
	                                                                        Locations__r.State_Province__c,
	                                                                        Locations__r.Postal_Code__c,
	                                                                        Locations__r.Country__c,
                                                                            Usage_Type__c//Long Ly - 05/07/2019 - Add Usage Type to the UI
	                                                                FROM Quote_Location__c 
	                                                                WHERE Quote__c = :quoteId]);
	       
	        for(Id key : mapQuoteLocation.keySet()){
	            LocationAssetWrapper locationAssetsItem = new LocationAssetWrapper();
	            Quote_Location__c quoteLocation = mapQuoteLocation.get(key);
	            locationAssetsItem.quoteLocation = quoteLocation;

	            List<String> addressList = new List<String>();

	            if(!String.isBlank(quoteLocation.Locations__r.Address__c)){
	                addressList.add(quoteLocation.Locations__r.Address__c);
	            }
	            if(!String.isBlank(quoteLocation.Locations__r.State_Province__c)){
	                addressList.add(quoteLocation.Locations__r.State_Province__c);
	            }
	            if(!String.isBlank(quoteLocation.Locations__r.City__c)){
	                addressList.add(quoteLocation.Locations__r.City__c);
	            }
	            if(!String.isBlank(quoteLocation.Locations__r.Postal_Code__c)){
	                addressList.add(quoteLocation.Locations__r.Postal_Code__c);
	            }
	            if(!String.isBlank(quoteLocation.Locations__r.Country__c)){
	                addressList.add(quoteLocation.Locations__r.Country__c);
	            }

                //Long Ly - 05/07/2019 - Add Usage Type to the UI
                addressList.add(quoteLocation.Usage_Type__c);
                //End

	            locationAssetsItem.address = String.join(addressList, ', ');
	            initObject.listLocationAsset.add(locationAssetsItem);
	        }
	        return initObject;
    	
    	} catch (Exception ex) {
    		throw new AuraHandledException(CommonUtil.getExceptionMessage(ex));	
    	}
    }

    public class InitObject {
        @AuraEnabled public String accountId 								{get; set;}
        @AuraEnabled public String productId 								{get; set;}
        @AuraEnabled public String opportunityId 							{get; set;}
        @AuraEnabled public String iconName 								{get; set;}
        @AuraEnabled public List<LocationAssetWrapper> listLocationAsset 	{get; set;}
        
        public InitObject() {
            listLocationAsset = new List<LocationAssetWrapper>();
            iconName = getIconName();
        }

        private String getIconName() {
            String u;
            String sObjectName = 'Quote_Location__c';
            List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
            List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
            List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

            for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }

            for(Schema.DescribeTabResult tr : tabDesc) {
                if( sObjectName == tr.getSobjectName() ) {
                    if( tr.isCustom() == true ) {
                        iconDesc.addAll(tr.getIcons());
                    } else {
                        u = 'standard:' + sObjectName.toLowerCase();
                    }
                }
            }
            for (Schema.DescribeIconResult ir : iconDesc) {
                if (ir.getContentType() == 'image/svg+xml'){
                    u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                    break;
                }
            }
            return u;
        }
    }

    public class LocationAssetWrapper {
        @AuraEnabled public Quote_Location__c quoteLocation 	{get; set;}
        @AuraEnabled public String address 						{get; set;}
        public LocationAssetWrapper() {
            this.quoteLocation = new Quote_Location__c();
            this.address = '';
        }
    }
}