public class recordNavigationCmpCtrl {
    
    @AuraEnabled
    public static Quote fetchDetails(Id recordId){
        return [SELECT Status, OpportunityId FROM Quote WHERE Id =: recordId];
    }

}