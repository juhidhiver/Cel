/**************************************************************************************************
 * Class Name: ContentVersionQueryUtil
 * Author: Vinay
 * Date: Dec 23, 2021
 * Description: Class to keep content version queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class ContentVersionQueryUtil {
    /*************************************************
    * Method Name: fetchContentVersionsByIDs
    * Author: Vinay
    * Date: 23 Dec 2021
    * Params: List<Id>
    * Return: list<ContentVersion>
    * Exceptions:
    * Revision: 
    * Description: Fetch content versions by IDs
     *************************************************/
    public static List<ContentVersion> fetchContentVersionsByIDs(Set<Id> versionIds){
       return [SELECT Id, ContentDocument.Title FROM ContentVersion WHERE ContentDocumentId IN :versionIds];
    }
}