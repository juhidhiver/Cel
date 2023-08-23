/**************************************************************************************************
 * Class Name: Account Clearance Callout
 * Author: Sarthak Roy
 * Created date: 25-Nov-2020
 * Description: Callout API for Account Clearance Service
 **************************************************************************************************/
public with sharing class AccountClearanceCallout {
  // Define Custom Exception for LWC error Handling
  public class MyException extends Exception {
  }

  @AuraEnabled
  public static String sendSubmissionDetails(Id accId, Id productId) {
    HttpRequest req = new HttpRequest();
    HttpResponse res = new HttpResponse();
    Http https = new Http();
    //Opportunity oppObj = [Select Id,AccountId,Effective_Date__c FROM Opportunity WHERE ID =: oppId.Id];
    Account accObj = [
      SELECT
        Id,
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        BillingStateCode
      FROM Account
      WHERE Id = :accId
    ];
    Product2 prdObj = [
      SELECT Name, Model_ID__c, Id, IsActive
      FROM Product2
      WHERE ID = :productId AND IsActive = TRUE
    ];
    String accountClearance;
    API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration(
      'Munich_Clearance'
    );
    if (apiSetting == null)
      return '';

    try {
      req = Invsk_Callout.getHttpRequest(apiSetting);
      system.debug('123 Request--' + req);

      //Request Body
      AccountClearanceRequestWrapper accReqWrap = new AccountClearanceRequestWrapper();
      //QuoteLocation Wrapper
      QuotedRiskLocation quoteLocation = new QuotedRiskLocation();
      quoteLocation.ZipCode = accObj.BillingPostalCode;
      quoteLocation.State = accObj.BillingStateCode;
      quoteLocation.City = accObj.BillingCity;
      quoteLocation.StreetAddress = accObj.BillingStreet;

      //Account PWS insuredName
      PwsInsured accName = new PwsInsured();
      accName.name = accObj.Name;

      //Insureds
      Insureds ins = new Insureds();
      ins.PwsInsured = new List<PwsInsured>{ accName };

      //PwsSubmissionPackageToClear
      PwsSubmissionPackageToClear pwsSubPack = new PwsSubmissionPackageToClear();
      pwsSubPack.QuotedRiskLocation = quoteLocation;
      pwsSubPack.Insureds = ins;
      pwsSubPack.QuoteEffectiveDate = String.valueOf(Date.today() + 1);

      accReqWrap.pwsSubmissionPackageToClear = pwsSubPack;
      accReqWrap.ProductClassCd = prdObj.Model_ID__c;
      accReqWrap.Coverages = new List<String>(); // Added for empty array for MPL and Cyber
      System.debug('Request Wrapper' + JSon.serialize(accReqWrap));

      req.setBody(json.serialize(accReqWrap));
      res = https.send(req);

      if (res.getStatusCode() == 200) {
        AccountClearanceWrapper accClearanceWrapper = (AccountClearanceWrapper) JSON.deserialize(
          res.getBody(),
          AccountClearanceWrapper.class
        );
        system.debug('Response Wrapper' + accClearanceWrapper);

        if (
          accClearanceWrapper.submitPackageForAutoClearanceResult.succeded ==
          'True'
        ) {
          if (
            accClearanceWrapper.submitPackageForAutoClearanceResult.result.wasCleared ==
            'true'
          ) {
            accountClearance = Label.ACCOUNT_CLEARED;
            system.debug('accountClearance' + accountClearance);
          } else {
            accountClearance = Label.ACCOUNT_CLOSED_MARKET;
            system.debug('accountClearance' + accountClearance);
          }
        } else {
          accountClearance = Label.SERVICE_FAILED;
          system.debug('accountClearance' + accountClearance);
        }
      } else {
        accountClearance = Label.SERVICE_FAILED;
        system.debug('accountClearance' + accountClearance);
      }
    } catch (Exception ex) {
      System.debug(ex.getMessage());
    }
    ApiUtil.logAPICall(
      req,
      res,
      'AccountClearanceCallout',
      'sendSubmissionDetails',
      apiSetting.HeaderParams__c,
      'Outbound'
    );
    //
    return accountClearance;
  }

  /**
  * @description: Will be used to call MRE clearance call for each products selected on PCC Product Selection screen
  * @author Maeran Shaikh | 08-13-2021 
  * @param itemWrapper 
  * @return ResponseWrapper 
  **/
  @AuraEnabled
  public static ResponseWrapper getClearanceDetailsForPCC(
    ComboProductSelectionLwcController.ItemWrapper itemWrapper
  ) {

    Opportunity submissionDetails = [Select Id,Account.BillingCity, Account.BillingStreet,Account.BillingCountry, Account.BillingStateCode, Account.BillingPostalCode,Account.Name, Azure_ID__c,
     Effective_Date__c, Product__r.Model_ID__c, Product__r.Munich_LOB_Code__c  from Opportunity where Id = :itemWrapper.SubmissionId LIMIT 1];

    HttpRequest req = new HttpRequest();
    HttpResponse res = new HttpResponse();
    Http https = new Http();
    API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration(
      'Munich_Clearance'
    );
    try {
      // Iterate over multiple selected products for PCC

      req = Invsk_Callout.getHttpRequest(apiSetting);
      //Request Body
      AccountClearanceRequestWrapper accReqWrap = new AccountClearanceRequestWrapper();
      //QuoteLocation Wrapper
      QuotedRiskLocation quoteLocation = new QuotedRiskLocation();
      quoteLocation.ZipCode = submissionDetails.Account.BillingPostalCode;
      quoteLocation.State = submissionDetails.Account.BillingStateCode;
      quoteLocation.City = submissionDetails.Account.BillingCity;
      quoteLocation.StreetAddress = submissionDetails.Account.BillingStreet;

      //Account PWS insuredName
      PwsInsured accName = new PwsInsured();
      accName.name = submissionDetails.Account.Name;

      //Insureds
      Insureds ins = new Insureds();
      ins.PwsInsured = new List<PwsInsured>{ accName };

      //PwsSubmissionPackageToClear
      PwsSubmissionPackageToClear pwsSubPack = new PwsSubmissionPackageToClear();
      pwsSubPack.QuotedRiskLocation = quoteLocation;
      pwsSubPack.Insureds = ins;
      pwsSubPack.QuoteEffectiveDate = String.ValueOf(
        submissionDetails.Effective_Date__c
      );

      accReqWrap.pwsSubmissionPackageToClear = pwsSubPack;
      accReqWrap.ProductClassCd = submissionDetails.Product__r.Model_ID__c;
      accReqWrap.Coverages = itemWrapper.coverages;
      accReqWrap.SubmissionId = submissionDetails.Azure_ID__c;
      System.debug('Request Wrapper' + JSon.serialize(accReqWrap));

      req.setBody(json.serialize(accReqWrap));
      res = https.send(req);

      // Store response in API util
      ApiUtil.logAPICall(
        req,
        res,
        'AccountClearanceCallout',
        'getClearanceDetailsForPCC',
        apiSetting.HeaderParams__c,
        'Outbound'
      );

      // Create ResponseWrapper

      ResponseWrapper respWrap = new ResponseWrapper();
      // If Success
      if (res.getStatusCode() == 200) {
        AccountClearanceWrapper accClearanceWrapper = (AccountClearanceWrapper) JSON.deserialize(
          res.getBody(),
          AccountClearanceWrapper.class
        );
        system.debug('Response Wrapper' + accClearanceWrapper);
        respWrap.isSuccess = true;
        String responseStr = String.ValueOf(accClearanceWrapper);
        // If vallback response contains Clearance Date then associate it with return wrapper 
        if (
          responseStr.contains('clearanceDate') &&
          accClearanceWrapper.submitPackageForAutoClearanceResult.result.submissions.pwsSubmission[0]
            .submissionClearance.clearanceDate != null
        ) {
          // Assign clearanceDate
          String str1 = accClearanceWrapper.submitPackageForAutoClearanceResult.result.submissions.pwsSubmission[0]
            .submissionClearance.clearanceDate;
          String str = str1.replace('T', ' ').replace('Z', '');
          Date dt = date.valueOf(str);
          respWrap.clearanceDate = dt;
        }
        // If vallback response contains prodName then associate it with return wrapper 
        if (responseStr.contains('prodName')) {
          respWrap.prodName = accClearanceWrapper.submitPackageForAutoClearanceResult.result.submissions.pwsSubmission[0]
              .lineOfBusiness.name != null
            ? accClearanceWrapper.submitPackageForAutoClearanceResult.result.submissions.pwsSubmission[0]
                .lineOfBusiness.name
            : '';
        }
        // If vallback response contains prodLOBCode then associate it with return wrapper 
        if (responseStr.contains('prodLOBCode')) {
          respWrap.prodLOBCode = accClearanceWrapper.submitPackageForAutoClearanceResult.result.submissions.pwsSubmission[0]
              .lineOfBusiness.code != null
            ? accClearanceWrapper.submitPackageForAutoClearanceResult.result.submissions.pwsSubmission[0]
                .lineOfBusiness.code
            : '';
        }
        //isSuccessFromMRE
        if(responseStr.contains('succeded')){
            respWrap.isSuccessFromMRE = accClearanceWrapper.submitPackageForAutoClearanceResult.succeded!= null ? Boolean.ValueOf(accClearanceWrapper.submitPackageForAutoClearanceResult.succeded): false;
        }

        respWrap.wasCleared = accClearanceWrapper.submitPackageForAutoClearanceResult.result.wasCleared;
      } else {
        // In case of response failure
        System.debug('err msg is-->' + res.getBody());

        respWrap.isSuccess = false;
        String errorMsg = res.getStatusCode() + ' : ' + res.getBody();
        respWrap.errors = new List<String>{ errorMsg };
      }
      if (respWrap != null) {
       return respWrap;
      } 
      else {
        return null;
      }
    } catch (Exception e) {
      System.debug(e.getMessage());
      throw new MyException(e.getMessage());
    }
  }

  // Updated Wrapper by Maeran Shaikh for US:50155 on 4/8/2021
  public class AccountClearanceRequestWrapper {
    public PwsSubmissionPackageToClear pwsSubmissionPackageToClear;
    public String ProductClassCd;
    public String SubmissionId;
    public List<String> Coverages;
  }
  public class QuotedRiskLocation {
    public String ZipCode;
    public String State;
    public String City;
    public String StreetAddress;
  }

  public class PwsInsured {
    public String Name;
  }

  public class Insureds {
    public List<PwsInsured> PwsInsured;
  }

  // Updated Wrapper by Maeran Shaikh for US:50155 on 4/8/2021
  public class PwsSubmissionPackageToClear {
    public QuotedRiskLocation QuotedRiskLocation;
    public String QuoteEffectiveDate;
    public Insureds Insureds;
  }

  //
  public class AccountClearanceWrapper {
    public submitPackageForAutoClearanceResult submitPackageForAutoClearanceResult;
  }
  public class submitPackageForAutoClearanceResult {
    public result result;
    public string succeded;
  }
  // Updated Wrapper by Maeran Shaikh for US:50155 on 4/8/2021
  public class result {
    public String wasCleared;
    public submissions submissions;
  }

  public class submissions {
    public List<pwsSubmission> pwsSubmission;
  }
  // Updated Wrapper by Maeran Shaikh for US:50155 on 4/8/2021
  public class pwsSubmission {
    public submissionClearance submissionClearance;
    public lineOfBusiness lineOfBusiness;
  }
  // Updated Wrapper by Maeran Shaikh for US:50155 on 4/8/2021
  public class submissionClearance {
    public string clearanceDate;
  }
  public class lineOfBusiness {
    public string code;
    public string name;
  }

  // Response wrapper
  
  public class ResponseWrapper {
    @AuraEnabled public string wasCleared;
    @AuraEnabled public string prodName;
    @AuraEnabled public Date clearanceDate;
    @AuraEnabled public String prodLOBCode;
    @AuraEnabled public List<String> errors;
    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public Boolean isSuccessFromMRE;
  }
}