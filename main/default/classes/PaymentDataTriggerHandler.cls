public class PaymentDataTriggerHandler extends TriggerHandler{

    private List<Payment_Data__c> oldDataList;
    private List<Payment_Data__c> newDataList;
    private Map<Id, Payment_Data__c> newDataMap;
    private Map<Id, Payment_Data__c> oldDataMap;
    
    public PaymentDataTriggerHandler() {
        this.oldDataList = (List<Payment_Data__c>) Trigger.old;
        this.oldDataMap = (Map<Id, Payment_Data__c>) Trigger.oldMap;
        
        this.newDataList = (List<Payment_Data__c>) Trigger.new;
        this.newDataMap = (Map<Id, Payment_Data__c>) Trigger.newMap;
    }

    public override void beforeInsert(){}

    public override void beforeUpdate(){
        updateLastModifiedDate(oldDataList ,newDataList );
    }

    public override void afterInsert(){}

    public override void afterUpdate(){
        
    }

    public static void updateLastModifiedDate(List<Payment_Data__c> oldDataList , List<Payment_Data__c> newDataList )
    {
            List<Payment_Data__c> listPayment = new List<Payment_Data__c>();
            List<Payment_Data__c> listPaymentToUpdate = new List<Payment_Data__c>();
            Datetime now = Datetime.now();
            Integer offset = UserInfo.getTimezone().getOffset(now);
            Datetime local = now.addSeconds(offset/1000);
           for(Payment_Data__c newPaymentData : newDataList) 
           {
            for(Payment_Data__c oldPaymentData : oldDataList){
                    if(newPaymentData.CurrencyIsoCode != oldPaymentData.CurrencyIsoCode || 
                        newPaymentData.OwnerId != oldPaymentData.OwnerId ||
                        newPaymentData.Quote_Type__c != oldPaymentData.Quote_Type__c ||
                        newPaymentData.Reference_Number__c != oldPaymentData.Reference_Number__c ||
                        newPaymentData.Premium__c != oldPaymentData.Premium__c ||
                        newPaymentData.IPT__c != oldPaymentData.IPT__c ||
                        newPaymentData.Fee__c != oldPaymentData.Fee__c ||
                        newPaymentData.Producing_Brokerage__c != oldPaymentData.Producing_Brokerage__c ||
                        newPaymentData.Due_from_Broker__c != oldPaymentData.Due_from_Broker__c ||
                        newPaymentData.Amount_Paid__c != oldPaymentData.Amount_Paid__c ||
                        newPaymentData.Paid_Status__c != oldPaymentData.Paid_Status__c ||
                        newPaymentData.Due_Date__c != oldPaymentData.Due_Date__c ||
                        newPaymentData.Policy__c != oldPaymentData.Policy__c ||
                        newPaymentData.Quote__c != oldPaymentData.Quote__c ){
                            //newPaymentData.Last_Modified_Date__c = Date.Today().format();
                            newPaymentData.Last_Modified_Date__c = System.now();
                            listPaymentToUpdate.add(newPaymentData);
                            system.debug('Date.Today();-------'+Date.Today());
                           
                        }
            }
                        system.debug('listPaymentToUpdate-------'+listPaymentToUpdate);
                        system.debug('Date.Today();-------'+Date.Today());
                        system.debug('newPaymentData.Last_Modified_Date__c-----'+newPaymentData.Last_Modified_Date__c);
                        system.debug('newPaymentData.Fee__c-----'+newPaymentData.Fee__c);
           }

         //  if(listPaymentToUpdate.size() > 0 ) update listPaymentToUpdate;
    }
    
}