public class ReferralApprovalController {
public static boolean EmailFlag = true;
	@AuraEnabled
	public static ResultResponse submitSubmissionToApprovalProcess(String quoteId,String userId,String comment,String referType){
		EmailFlag = false;
        ResultResponse resultResponse = new ResultResponse();
		Savepoint savePoint = Database.setSavepoint();
		try{
			System.debug('OppId ' + quoteId + ' UserId ' + userId + ' Comments ' + comment);
			if(String.isBlank(quoteId) || String.isBlank(userId)){
				return resultResponse;
			}
			List<Approval.ProcessSubmitRequest> requestList = new List<Approval.ProcessSubmitRequest>();
			Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
			req1.setComments(comment);
			req1.setObjectId(quoteId);
			req1.setSubmitterId(UserInfo.getUserId());
			req1.setNextApproverIds(new List<Id>{userId});
			// Submit the record to specific process and skip the criteria evaluation
			req1.setProcessDefinitionNameOrId('Celerity_Manual_Referral_Process');
			requestList.add(req1);
			System.debug('Request' + req1);
			// Submit the approval request for the account
			Quote quote = new Quote(Id = quoteId, Refer_Type__c = referType,Referral_Approver__c = userId );
			update quote;
			Approval.ProcessResult approvalResult = Approval.process(req1);
			System.debug('==approvalResult== '+ approvalResult);
			// First, get the ID of the newly created item
			List<Id> newWorkItemIds = approvalResult.getNewWorkitemIds();
			if(approvalResult.isSuccess()){
				resultResponse.isSuccess  = true;
				return resultResponse;
			}else{
				Database.rollback(savePoint);
			}
			return resultResponse;
		}catch (Exception ex){
			Database.rollback(savePoint);
			//Process failed. First exception on row 0; first error: ALREADY_IN_PROCESS, : [] 24 Class.UnderWriterWReferralLwcController.submitSubmissionToApprovalProcess: line 24, column 1
			String errorMessage ='';
			if(ex.getMessage().contains('NO_APPLICABLE_PROCESS')) errorMessage = 'No applicable approval process was found';
			if(ex.getMessage().contains('ALREADY_IN_PROCESS')) errorMessage = 'This record is currently in an approval process. A record can be in only one approval process at a time.';
			if(ex.getMessage().contains('REQUIRED_FIELD_MISSING')) errorMessage = 'Missing required field.';
			if(String.isBlank(errorMessage)) errorMessage = ex.getMessage();
			System.debug('Exception ' + ex.getCause() + ex.getStackTraceString());
			resultResponse.errors.add(errorMessage);
			return resultResponse;
		}
	}


}