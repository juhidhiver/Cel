/*************************************************
* Class Name: GeneratePolicyDocumentController
* Author: 
* Updated: 
* Description: 
* Revison : 
*************************************************/
public with sharing class GeneratePolicyDocumentController {
    
    /*************************************************
* Method Name: getListTypeDocument
* Author: 
* Date: 
* Params:
* Return: Picklist
* Exceptions:
* Revision: 
**************************************************/
    @AuraEnabled
    public static List<PicklistOption> getListTypeDocument(){
        system.debug('@@@ -------------------- GeneratePolicyDocumentController.getListTypeDocument --------------------');
        return CommonUtil.getPicklistValueByRecordType('Document_Revision__c', 'Document_Type__c','Policy');
    }
    
    /*************************************************
* Method Name: generateDocumentId
* Author: 
* Date: 
* Params: String policyId, String docType
* Return:
* Exceptions:
* Revision: 
*************************************************/
    @AuraEnabled
    public static GenerateDocumentApiHandler.GenerateResult generateDocumentId(String quoteId, String policyId, String docType) {
        system.debug('@@@ -------------------- GeneratePolicyDocumentController.generateDocumentId --------------------');    	
        GenerateDocumentApiHandler.GenerateResult result = new GenerateDocumentApiHandler.GenerateResult();
        system.debug('quoteId :'+quoteId);
        try {
            String  productClassCd ;
            String  productName;
            String  accountId;
            String quoteAzureId;
            String include='quoteDataOnly';
            String submissionId;
            String lobName='Celerity' ;
            List<Quote> quotes;

            if(quoteId != null && String.isNotBlank(quoteId)){
                quotes = [SELECT Id, Status, Rating_Status__c, Azure_Id__c,Opportunity.Product__r.Model_ID__c,
                                  Product_Name__c,AccountId,OpportunityId
                                  FROM Quote 
                                  WHERE id =: quoteId]; 
            }else{
                quotes = [SELECT Id, Status, Rating_Status__c, Azure_Id__c,Opportunity.Product__r.Model_ID__c,
                            Product_Name__c,AccountId,OpportunityId
                            FROM Quote 
                            WHERE Policy__c =: policyId
                            And (Status = 'Bound' OR Status = 'Bound Pending')
                            ORDER BY CreatedDate DESC]; 
            }
            System.debug('@@@@@quotes= '+quotes);                                 
            if (!quotes.isEmpty()) {
                productClassCd = quotes[0].Opportunity.Product__r.Model_ID__c;
                productName=quotes[0].Product_Name__c;
                accountId=quotes[0].AccountId;
                quoteAzureId = quotes[0].Azure_ID__c;
                submissionId= quotes[0].OpportunityId;

                system.debug('quoteaz'+quoteAzureId);
                List<Policy__c> policyList = new List<Policy__c>();
                if(string.isNotBlank(policyId)){
                    policyList = [Select Id,Azure_Id__c,Layer__c From Policy__c Where Id = :policyId]; 
                }
                if(policyList.isEmpty()){
                    result.errMsg = 'Policy does not exist';
                    return result;
                }
                String policyAzureId;
                if(string.isNotBlank(policyList[0].Azure_Id__c)){
                    policyAzureId = policyList[0].Azure_Id__c;
                }
                
                if(docType == 'ChangeEndorsement' && policyList[0].Layer__c == 'Primary'){
                    docType = 'ChangeEndorsementPolicy';
                }
                if(docType == 'ChangeEndorsement' && policyList[0].Layer__c == 'Excess'){
                    docType = 'ExcessChangeEndorsementPolicy';
                }
                if(docType == 'Binder' && policyList[0].Layer__c == 'Excess'){
                    docType = 'CelerityExcessBinder';
                }
                if(docType == 'PolicyForm' && policyList[0].Layer__c == 'Excess'){
                    docType = 'CelerityExcessPolicy';
                }
                String outputFileName = docType +'.pdf';
                // String bodyRequest = '{"documentType":"' + docType + '","quoteId":"' + quoteAzureId + '"}';
                
                
               
                
				                
                GenerateQuoteDocumentController.DocManagementWrapper docManagement = new GenerateQuoteDocumentController.DocManagementWrapper(submissionId,policyId, lobName, accountId); 
                GenerateQuoteDocumentController.DocumentV2Wrapper docV2Wrapper = new GenerateQuoteDocumentController.DocumentV2Wrapper(quotes, productClassCd,outputFileName,include,docType,docManagement);
                String v2bodyRequest = JSON.serialize(docV2Wrapper); 
                
                System.debug('@@@@@bodyRequest= '+v2bodyRequest);
                result = GenerateDocumentApiHandler.generateDocId('Policy__c', policyId, policyAzureId, docType, v2bodyRequest);                
                
            } else {
                result.errMsg = Label.CONTRACT_POLICY_AND_SOA_DOC_VALIDATION_MSG;
            }
            
        } catch (Exception ex) {
            result.errMsg = CommonUtil.getExceptionMessage(ex);
        }    	
        return result;
    }

    /**************
     * Description: To retrieve the list of quotes which are bound except New Business and Renewal
     * Developer: Vinay Vernekar
     */
    @AuraEnabled
    public static List<Quote> getBoundQuotes(id policyId){
        return [SELECT id,Name,Quote_Type__c,Endorsement_Effective_Date__c,Transaction_Premium__c,QuoteNumber,Policy__c from Quote where Status = 'Bound' and Quote_Type__c != 'New Business' and Quote_Type__c != 'Renewal' and Policy__c =: policyId];
    }
}