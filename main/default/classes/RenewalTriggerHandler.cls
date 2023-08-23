public with sharing class RenewalTriggerHandler extends TriggerHandler{
    
    private List<Renewal__c> oldDataList;
	private List<Renewal__c> newDataList;
	private Map<Id, Renewal__c> newDataMap;
	private Map<Id, Renewal__c> oldDataMap;
	
    public RenewalTriggerHandler (){  
		this.oldDataList = (List<Renewal__c>) Trigger.old;
		this.newDataList = (List<Renewal__c>) Trigger.new;
		this.newDataMap = (Map<Id, Renewal__c>) Trigger.newMap;
		this.oldDataMap = (Map<Id, Renewal__c>) Trigger.oldMap;
    }

	public override void beforeInsert()	{
		
	}

    public override void beforeUpdate(){
		
    }
	//vivek 18-07-2022 
	public override void afterInsert(){
        UpdateRenewalDocuments(newDataList);        
    }

	public override void afterUpdate(){
        //updateRenewalRecords(newDataList);       
    }
	//vivek 18-07-2022   
	public static void UpdateRenewalDocuments(List<Renewal__c> RenewalDataList){       
        List<Renewal__c> renwalListtoUpdate = new List<Renewal__c>();   
        if(RenewalDataList != null && RenewalDataList.size() > 0){
            for(Renewal__c objRenewal : [Select Id,Documents_Required__c,RecordType.Name From Renewal__c Where Id IN : RenewalDataList]){
                String QuoteProductName = objRenewal.RecordType.Name == 'Aqueous' ? 'Professional Indemnity' : '';
                List<Document_Template__c> DocumentTempList = AssignmentMatrixUtil.GetDocumentsData(objRenewal.Id, QuoteProductName);          
                if(DocumentTempList != null && DocumentTempList.size() > 0){
                    Renewal__c ren = new Renewal__c();
                    ren.Id = objRenewal.Id;
                    String strDocuments;
                    for(Document_Template__c doc : DocumentTempList){
                        strDocuments = String.isNotBlank(strDocuments) ? strDocuments + ';' + doc.Document_Name__c : doc.Document_Name__c;
                    }
                    ren.Documents_Required__c = strDocuments;
                    renwalListtoUpdate.add(ren);
                }     
            }  
        }                  
        if(renwalListtoUpdate != null && renwalListtoUpdate.size() > 0){
            Update renwalListtoUpdate;
        }       
    }

    /*public static void updateRenewalRecords(List<Renewal__c> RenewalDataList){
        
        Map<String,String> policyRenewalMap = new Map<String,String>();
        Map<String,String> RenewalBrokerWarningMap = new Map<String,String>();
        Map<String,Boolean> RenewalPaymentWarningMap = new Map<String,Boolean>();
        
        for(Renewal__c renewalRec : [select id,Policy__c,RecordType.Name,Broker_Warning__c,Payment_Warning__c from Renewal__c where id IN: RenewalDataList]){
            if(renewalRec.RecordType.Name == 'Aqueous'){
                //******************************* Multiple Rewnwals for Policy is not considered for this logic ************************
                policyRenewalMap.put(renewalRec.Policy__c,renewalRec.Id);
                RenewalBrokerWarningMap.put(renewalRec.Id,renewalRec.Broker_Warning__c);
                RenewalPaymentWarningMap.put(renewalRec.Id,renewalRec.Payment_Warning__c);
            }
        }
       

     if(!policyRenewalMap.isEmpty()){

        List<Renewal__c> updateRenewalList = new List<Renewal__c>();
     
        List<Policy__c> policyRecords = [SELECT Id , Policy_Status__c , Product_Name__c , Renewal_Date__c , Account__c , Renewal_Completed__c,Account__r.Renewal_Warning__c,Account__r.Renewal_Warning_Reason__c,
        (Select id , status, Layer__c ,Quote_Type__c, Opportunity.Main_Profession__c , OpportunityId from Quotes__r where status = 'Bound'  
        ORDER BY CreatedDate DESC Limit 1) from Policy__c where id IN: policyRenewalMap.keySet()];

        List<Renewal__c> renewalList   =  RenewalServiceHandler_Common.createRenewalRecords(policyRecords,'Professional Indemnity');

        for( Renewal__c renewal :  renewalList){
            renewal.Id =   policyRenewalMap.containskey(renewal.Policy__c) ?  policyRenewalMap.get(renewal.Policy__c) : '';
            renewal.Broker_Warning__c =  RenewalBrokerWarningMap.containsKey(renewal.Id) && (RenewalBrokerWarningMap.get(renewal.Id) != null || String.isNotBlank(RenewalBrokerWarningMap.get(renewal.Id))) ?  RenewalBrokerWarningMap.get(renewal.Id) : renewal.Broker_Warning__c;
            renewal.Payment_Warning__c =  RenewalPaymentWarningMap.containsKey(renewal.Id) ? RenewalPaymentWarningMap.get(renewal.Id) : renewal.Payment_Warning__c;
            if(String.isNotBlank(renewal.Id)){
                updateRenewalList.add(renewal);
            }
        }

        if(updateRenewalList.size()>0){
            GlobalStaticVar.byPassRenewalTrigger = true;
            update updateRenewalList;
        }
   
    }



    }*/
}