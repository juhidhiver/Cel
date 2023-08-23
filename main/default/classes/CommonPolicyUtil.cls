/**************************************************************************************************
 * Class Name: CommonPolicyUtil
 * Author: 
 * Date: 
 * Description: Class to keep Policy related  common methods
 **************************************************************************************************/
public class CommonPolicyUtil {

    /*************************************************
    * Method Name: setInitialPremiumValue
    * Author:
    * Date: 
    * Params: list<Policy__c>
    * Return: 
    * Exceptions:
    * Description: To set initial premium value
    * Revision: 
     *************************************************/
    //can be machived with flow
    public static void setInitialPremiumValue(List<Policy__c> newDataList) {
		for(Policy__c policy : newDataList) {
			if(policy.Total_Premium__c != null && policy.Initial_Premium__c == null) {
				policy.Initial_Premium__c = policy.Total_Premium__c;
			}
		}
	}

}