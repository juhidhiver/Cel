/**************************************************************************************************
 * Class Name: RatingModifiersTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: Class to keep method related to celerity
 * Test Class : RatingModifiersTriggerHandlerTest
 **************************************************************************************************/
public with sharing class RatingModifiersTriggerHandler_CEL extends TriggerHandler{
    private List<Rating_Modifiers__c> oldDataList;
    private List<Rating_Modifiers__c> newDataList; 
    private Map<Id, Rating_Modifiers__c> newDataMap;
    private Map<Id, Rating_Modifiers__c> oldDataMap; 
    
    public RatingModifiersTriggerHandler_CEL(List<Rating_Modifiers__c> newDataList, List<Rating_Modifiers__c> oldDataList, Map<Id, Rating_Modifiers__c> newDataMap, Map<Id, Rating_Modifiers__c> oldDataMap){
        this.oldDataList = oldDataList;
        this.newDataList = newDataList;
        this.newDataMap = newDataMap;
        this.oldDataMap = oldDataMap;
    } 

    //Description: To execute functionalities in before insert context
	public override void beforeInsert()	{
        //generate external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }


    //Description: To execute functionalities in before update context
    public override void beforeUpdate(){
        //generate external id
        CommonUtil.generateExternalID('Azure_ID__c', newDataList);
    }

	//Description: To execute functionalities in after insert context
	public override void afterInsert(){

    }


    // Description: To execute functionalities in after update context
	public override void afterUpdate(){
        //create subjectivity if proposal form date is empty
        //CommonRatingModifiersUtil.createSubjectivityIfProposalFormDateEmpty(newDataList);
        
        //Update Active Quotes to In Progress when Rating modifier with Rating check is updated
        updateStatusOfActiveStatus(oldDataMap,newDataList); 
    }


	/*************************************************
    * Method Name: afterUpdate
    * Author:Maeran Shaikh
    * Date: 20/12/2021
    * Params: 
    * Return: 
    * Exceptions:
    * Description: Update all Active Quotes status to In Progress
    * Revision: 
     *************************************************/
    public static void updateStatusOfActiveStatus(Map<Id, Rating_Modifiers__c> oldDataMap,List<Rating_Modifiers__c> newDataList){
        
        //store submission Ids of RMs where Option value is changed
        Set<Id> subIds = new Set<Id>();
        for(Rating_Modifiers__c eachRm : newDataList){
            if(eachRm.Rating__c && eachRm.Rating_Modifier_Value__c != oldDataMap.get(eachRm.Id).Rating_Modifier_Value__c && String.isNotBlank(oldDataMap.get(eachRm.Id).Rating_Modifier_Value__c)){
                subIds.add(eachRm.Opportunity__c);
            }
        }

        // Fetch all Active Quotes of this submissions
        List<String> statuses = new List<String>{'Quoted','Referred','Rated'};
        List<Quote> lstUpdateQuotes = new List<Quote>();
        for(Quote q: QuoteQueryUtil.fetchQuoteMapByOpportunity(subIds,statuses).values()){
            q.Status = 'In Progress';
            lstUpdateQuotes.add(q);
        }
        
        if(!lstUpdateQuotes.isEmpty() && Schema.sObjectType.Quote.fields.Status.isUpdateable()){
            TriggerHandler.bypass('QuoteTriggerBaseHandler');
            update lstUpdateQuotes;
        	TriggerHandler.clearBypass('QuoteTriggerBaseHandler');  
        }
    }
}