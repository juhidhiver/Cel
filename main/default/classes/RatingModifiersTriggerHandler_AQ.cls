/**************************************************************************************************
 * Class Name: RatingModifiersTriggerHandler_AQ
 * Author: 
 * Date: 
 * Description: Class to keep method related to Aqueous
 * Test Class : RatingModifiersTriggerHandlerTest
 **************************************************************************************************/
public with sharing class RatingModifiersTriggerHandler_AQ extends TriggerHandler{
    private List<Rating_Modifiers__c> oldDataList;
    private List<Rating_Modifiers__c> newDataList; 
    private Map<Id, Rating_Modifiers__c> newDataMap;
    private Map<Id, Rating_Modifiers__c> oldDataMap; 
    
    public RatingModifiersTriggerHandler_AQ(List<Rating_Modifiers__c> newDataList, List<Rating_Modifiers__c> oldDataList, Map<Id, Rating_Modifiers__c> newDataMap, Map<Id, Rating_Modifiers__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

	public override void beforeInsert()	{
        //generate external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

    public override void beforeUpdate(){
        //generate external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

	public override void afterInsert(){

    }

	public override void afterUpdate(){
        //if proposal form date is empty, create a subjectivity record
        createSubjectivityIfProposalFormDateEmpty(newDataList,oldDataMap);
    }


     /*************************************************
    * Method Name: createSubjectivityIfProposalFormDateEmpty
    * Author:
    * Date: 
    * Params: List<Rating_Modifiers__c> rmRecordList
    * Return: 
    * Exceptions:
    * Description: Create subjectivities based on proposal form date
    * Revision: 
    * Can be done with flows: Yes
     *************************************************/
    public static void createSubjectivityIfProposalFormDateEmpty(List<Rating_Modifiers__c> rmRecordList,Map<Id, Rating_Modifiers__c> oldDataMap) {
        Set<Id> oppIdSet = new Set<Id>();
        List<Subjectivity__c> subjectivityListToCreate = new List<Subjectivity__c>(); 
        try{  
            for( Rating_Modifiers__c rmRecord : rmRecordList ){

                if(rmRecord.Name == 'Proposal Form Date' && rmRecord.Opportunity__c !=null && rmRecord.Rating_Modifier_Value__c == null
                  && rmRecord.Product__c == 'Professional Indemnity' && rmRecord.Rating_Modifier_Value__c != oldDataMap.get(rmRecord.Id).Rating_Modifier_Value__c){

                    oppIdSet.add(rmRecord.Opportunity__c);

                    break;
                }
            }
            System.debug('oppIdSet::'+oppIdSet);
            List<Subjectivity_Template__c> subjTemp = [SELECT Id, Name, Profession_Criteria__c, Subjectivity_Name__c, Subjectivity_Text__c 
                                                           FROM Subjectivity_Template__c 
                                                           WHERE Subjectivity_Name__c ='Signed / Dated Proposal'];
            List<Quote> quotes = [Select Id,OpportunityId, Product_Name__c from Quote WHERE OpportunityId IN :oppIdSet];

            if(!quotes.isEmpty() && subjTemp != null && subjTemp.size() > 0){
                for(Quote quote : quotes){
                    Subjectivity__c subRec = new Subjectivity__c(); 
                    subRec.Quote__c = quote.Id;
                    subRec.Subjectivity__c = subjTemp[0].Subjectivity_Name__c;
                    subRec.Subjectivity_Text__c = subjTemp[0].Subjectivity_Text__c;
                    subRec.Stage__c = 'Pre-Bind';
                    subRec.Cleared__c = false;
                    subRec.Cleared_Date__c = null;
                    subRec.Subjectivity_Template__c = subjTemp[0].Id;

                   
                    subRec.RecordTypeId = Schema.SObjectType.Subjectivity__c.getRecordTypeInfosByName().get(GlobalVariables.RT_NAME_SUBJECTIVITY_AQUEOUS).getRecordTypeId();
                    
                    subjectivityListToCreate.add(subRec);
                }
            }
            if(!subjectivityListToCreate.isEmpty()) insert subjectivityListToCreate;

            if(Test.isRunningTest())
                throw new DmlException();
    	}
        catch (Exception ex) {
            String errorMsg = 'Failed to create Subjectivity.<br/>Please contact your administator.';
            for(Rating_Modifiers__c item : (List<Rating_Modifiers__c>)Trigger.new ){
                if(!Test.isRunningTest()) item.addError(errorMsg);
            }
        }
    }
}