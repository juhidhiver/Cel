/**
 * @File Name          : ResultResponse.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 5/5/2020, 6:08:13 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/5/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public class ResultResponse {
    @AuraEnabled
    public Boolean isSuccess;
    @AuraEnabled
    public List<String> errors;
    @AuraEnabled
    public Object data;
    @AuraEnabled
    public Object extraData;

    public ResultResponse() {
        this.isSuccess = false;
        errors = new List<String>();
        data = null;
		extraData = null;
    }
}