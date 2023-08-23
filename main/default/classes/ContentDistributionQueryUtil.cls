/**************************************************************************************************
 * Class Name: ContentDistributionQueryUtil
 * Author: Vinay
 * Date: Dec 23, 2021
 * Description: Class to keep content distribution queries
 * Test Class : 
 **************************************************************************************************/
public with sharing class ContentDistributionQueryUtil {
    /*************************************************
    * Method Name: fetchContentDistributionByIDs
    * Author: Vinay
    * Date: 23 Dec 2021
    * Params: List<ContentDistribution>
    * Return: list<ContentDistribution>
    * Exceptions:
    * Revision: 
    * Description: Fetch content distribution by IDs
     *************************************************/
    public static List<ContentDistribution> fetchContentDistributionByIDs(List<ContentDistribution> distributions){
       return [SELECT Id,Name, DistributionPublicUrl, ContentVersion.ContentDocument.Id FROM ContentDistribution WHERE ID IN : distributions];
    }
}