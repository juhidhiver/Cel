/**************************************************************************************************
 * Class Name: LocationQueryUtil
 * Author: Vinay Vernekar
 * Date: 5th Dec 2021
 * Description: Query util class for location records
 **************************************************************************************************/
public with sharing class LocationQueryUtil {
    /*************************************************
    * Method Name: fetchAllLocations
    * Author: Vinay Vernekar
    * Date: 29th Nov 2021
    * Params: Set<String> streets, Set<String> cities, Set<String> states, Set<String> zipCodes, Set<String> countries
    * Return: list of locations
    * Exceptions:
    * Revision: 
    * Description: Fetch all locations by streets, cities, states, zip codes and countries
     *************************************************/
    public static List<Location__c> fetchAllLocations(Set<String> streets, Set<String> cities, Set<String> states, Set<String> zipCodes, Set<String> countries){
        return [Select Id, Name, Address__c, City__c, State_Province__c,
                Postal_Code__c, Country__c, County__c //Ly Long 06/21/2019
                From Location__c Where Address__c IN :streets
                And City__c IN :cities
                And State_Province__c IN :states
                And Postal_Code__c IN :zipCodes
                And Country__c IN :countries
                Limit 50000	];
    }
}