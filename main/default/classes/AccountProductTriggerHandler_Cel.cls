public class AccountProductTriggerHandler_Cel extends TriggerHandler{
    private List<Account_Product__c> oldDataList;
    private List<Account_Product__c> newDataList;
    private Map<Id, Account_Product__c> newDataMap;
    private Map<Id, Account_Product__c> oldDataMap;
    
    public List<Account_Commission_Template__c> acp = new List<Account_Commission_Template__c>();
    public List<Account_Product__c> accprod = new List<Account_Product__c>();
    public Map<String,Decimal> mappingAccountComm = new Map<String,Decimal>();
    public Map<Id,Account> accountmap = new Map<Id,Account>();
    public List<String> acclist = new List<String>();  
    public Map<Id,Product2> prodmap = new Map<Id,Product2>();


 public AccountProductTriggerHandler_Cel(List<Account_Product__c> newDataList, List<Account_Product__c> oldDataList, 
                                         Map<Id, Account_Product__c> newDataMap, Map<Id, Account_Product__c> oldDataMap, 
                                         Map<Id,Product2> prodmap){
   this.oldDataList = oldDataList;
   this.newDataList = newDataList;
   this.newDataMap = newDataMap;
   this.oldDataMap = oldDataMap;
   this.prodmap = prodmap; 
                                             
   acp =  AccountCommissionQueryUtil.fetchAccountCommissionByAccounts();  
   system.debug('prodmap-->'+prodmap);
   system.debug('newDataList 2 -->'+newDataList);
   //Fetching Commission Template Table
    for(Account_Commission_Template__c acplist: acp){
            mappingAccountComm.put((acplist.Wholesaler__c).toLowerCase(),acplist.Cyber_Default__c);
    }
  } 
   /*************************************************
    * Method Name: beforeInsert
    * Author: 
    * Date: 
    * Params: List<Account_Product> newDataList coming from BaseHandler Class
    * Return: 
    * Exceptions:
    * Description: To insert Account product commission based on Account Commission template
    * Revision: 
     *************************************************/   
    public override void beforeInsert(){
        system.debug(' ####  PERFORMING BEFORE INSERT In ACCOUNTPRODUCTTRIGGERHANDLER_Cel #### ');
        // Map<Id,Account_Product__c> accprodmap = new Map<Id,Account_Product__c>();
        //Fetching Account from AccountProduct **Required since we do not have Name in NewDataList
        system.debug('NewDataList --> New->'+NewDataList);
        if(NewDataList != NULL){
             for(Account_Product__c acc: NewDataList){
             acclist.add(acc.Account_Id__c);
          }
        for(Account acc:[Select Id,Name from Account where Id IN:acclist]){
            accountmap.put(acc.Id,acc);
        }
        for(Account_Product__c ap : newDataList){
                if(ap.Account_Id__c != NULL && accountmap.containsKey(ap.Account_Id__c)){
                   String name = accountmap.get(ap.Account_Id__c).Name.toLowerCase();
                   String product = prodmap.get(ap.Product_Id__c).Name;
                     if(mappingAccountComm.get(name) != NULL && product == 'Cyber Standalone'){ 
                            ap.Commission_percentage__c = mappingAccountComm.get(name);
                     }
                }
         }    
        }
                
    }
    
    /*************************************************
    * Method Name: beforeUpdate
    * Author: 
    * Date: 
    * Params: List<Opportunity> opps
    * Return: 
    * Exceptions:
    * Description: To update Account product commission based on Account Commission template
    * Revision: 
     *************************************************/

    public override void beforeUpdate(){
     system.debug('---- PERFORMING BEFORE UPDATE In ACCOUNTPRODUCTTRIGGERHANDLER_Cel -----');
        accprod = AccountProductQueryUtil.getAllAcountProductsByIds(newDataList); 
        Map<Id,Account_Product__c> accprodmap = new Map<Id,Account_Product__c>();
        //Fetching Account from AccountProduct **Required since we do not have Name in NewDataList
        for(Account_Product__c acc : accprod){          
            accprodmap.put(acc.Id, acc);
        }

        for(Account_Product__c ap : newDataList){
                if(ap.Account_Id__c != NULL ){
                   String name = accprodmap.get(ap.Id).Account_Id__r.Name.toLowerCase();
                   String product = accprodmap.get(ap.Id).Product_Id__r.Name;
                   if(mappingAccountComm.get(name) !=NULL && product == 'Cyber Standalone'){ 
                            ap.Commission_percentage__c = mappingAccountComm.get(name);
                        }
            }
        }     
    }
        
    public override void afterInsert(){}
    public override void afterUpdate(){}
    
   
    
}