/**************************************************************************************************
 * Class Name: ContentDocumentQueryUtil
 * Author: Vinay
 * Date: Dec 23, 2021
 * Description: Class to keep content document queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class ContentDocumentQueryUtil {
    /*************************************************
    * Method Name: fetchContentDocumentsByIDs
    * Author: Vinay
    * Date: 23 Dec 2021
    * Params: List<Id>
    * Return: list<ContentDocument>
    * Exceptions:
    * Revision: 
    * Description: Fetch content documents by IDs
     *************************************************/
    public static List<ContentDocument> fetchContentDocumentsByIDs(Set<Id> documentIds){
       return [SELECT Id, Title, FileExtension, OwnerId FROM ContentDocument WHERE Id IN :documentIds];
    }
}