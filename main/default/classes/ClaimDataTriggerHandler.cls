public with sharing class ClaimDataTriggerHandler extends TriggerHandler{
    
    private List<Claim_Data__c> oldDataList;
    private List<Claim_Data__c> newDataList;
    private Map<Id, Claim_Data__c> newDataMap;
    private Map<Id, Claim_Data__c> oldDataMap;
    
    public ClaimDataTriggerHandler (){  
        this.oldDataList = (List<Claim_Data__c>) Trigger.old;
        this.newDataList = (List<Claim_Data__c>) Trigger.new;
        this.newDataMap = (Map<Id, Claim_Data__c>) Trigger.newMap;
        this.oldDataMap = (Map<Id, Claim_Data__c>) Trigger.oldMap;
    }
    
    public override void beforeInsert(){
        claimAccountUpdate(newDataList);
    }
    
    public override void beforeUpdate(){
        claimAccountUpdate(newDataList);
    }
    
    public override void afterInsert(){
        
    }
    
    public override void afterUpdate(){
        
        
    }

    public static void claimAccountUpdate(list<Claim_Data__c> cdList){
        Set<Id> setOfPolicyIds = new Set<Id>();
        Map<Id, Policy__c> mapPolicy;
        for(Claim_Data__c cd : cdList){
            if(cd.Policy__c != null){
                setOfPolicyIds.add(cd.Policy__c);
            }
        }
        
        if(!setOfPolicyIds.isEmpty()){
            mapPolicy = new Map<Id, Policy__c>([Select id , 
                                                 Account__c 
                                                 from Policy__c 
                                                 where id IN: setOfPolicyIds]);
            
            if(!mapPolicy.isEmpty()){
                for(Claim_Data__c cd : cdList){
                    if(cd.Policy__c != null && mapPolicy.containsKey(cd.Policy__c) && mapPolicy.get(cd.Policy__c).Account__c != null){
                        cd.Account__c = mapPolicy.get(cd.Policy__c).Account__c;
                    }
                }
            }
        }
    }
    
}