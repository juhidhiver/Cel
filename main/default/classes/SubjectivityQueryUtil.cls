/**************************************************************************************************
 * Class Name: SubjectivityQueryUtil
 * Author: Jai
 * Date: Dec 16, 2021
 * Description: Class to keep Subjectivity queries
 * Test Class :  SubjectivityQueryUtilTest
 **************************************************************************************************/
public with sharing class SubjectivityQueryUtil {
    
    
    /*************************************************
    * Method Name: fetchSubjectivitiesForSubjectivityIds
    * Author: Jai
    * Date: 9 Dec 2021
    * Params: Set<id>
    * Return: list of Sujectivity
    * Exceptions:
    * Revision: 
    * Description: Fetch all Subjectivities for Ids
     *************************************************/
    public static List<Subjectivity__c> fetchSubjectivitiesForSubjectivityIds(Set<id> subjIds, String fields){
        String query = 'Select '+fields+ ' From Subjectivity__c where Id IN :subjIds';
        return (list<Subjectivity__c>)database.query(query);
    }

    /*************************************************
    * Method Name: fetchSubjectivitiesForQuote
    * Author: 
    * Date: 6th Jan 2022
    * Params: String quoteId
    * Return: list of subjectivities
    * Exceptions:
    * Revision: 
    * Description: Fetch all Subjectivities for quote
     *************************************************/
    public static List<Subjectivity__c> fetchSubjectivitiesForQuote(String quoteId){
        return  [select Id, Cleared__c from Subjectivity__c where Quote__c =:quoteId];
    }

}