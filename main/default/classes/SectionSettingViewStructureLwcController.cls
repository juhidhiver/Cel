/**
 * @File Name          : SectionSettingViewStructureLwcController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 5/18/2020, 5:54:40 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/18/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class SectionSettingViewStructureLwcController {

    /*************************************************
    * Method Name: getSectionSettingStructure
    * Author: Hang Lam
    * Date: 18/05/2020
    * Params: recordTypeName - record type name get from component
    * Params: componentName - component name get from component
    * Return: list TreeStructure
    * Exceptions:
    * Revision: 
    *************************************************/
    @AuraEnabled(cacheable=true)
    public static List<TreeStructure> getSectionSettingStructure(String recordTypeName, String componentName){
        // get all Main section
        List<SectionSetting__c> mainSections = [SELECT Id,Name,Record_Type__c,Component__c,Main_Section__c,Sub_Section__c,
                                                        Source_Field_API__c, Source_Field_Label__c, Source_Object__c,Format__c,
                                                        DisplayType__c, Order__c,Active__c,Criteria__c,Lookup_To__c
                                                FROM SectionSetting__c
                                                WHERE Record_Type__c =: recordTypeName
                                                AND Component__c =: componentName 
                                                AND Type_Of_Section__c='MainSection']; 
        // get all Sub section
        List<SectionSetting__c> subSections = [SELECT Id,Name,Record_Type__c,Component__c,Main_Section__c,Sub_Section__c,
                                                        Source_Field_API__c, Source_Field_Label__c, Source_Object__c,Format__c,
                                                        DisplayType__c, Order__c,Active__c,Criteria__c,Lookup_To__c
                                                FROM SectionSetting__c
                                                WHERE Record_Type__c =: recordTypeName
                                                AND Component__c =: componentName 
                                                AND Type_Of_Section__c='SubSection'];             
        Map<String, SectionSetting__c> mainSectionMap = new Map<String, SectionSetting__c>();                                                                               
        for(SectionSetting__c secSet : mainSections){
            mainSectionMap.put(secSet.Main_Section__c, secSet);
        } 
        Map<String, SectionSetting__c> subSectionMap = new Map<String, SectionSetting__c>(); 
        for(SectionSetting__c subsecSet : subSections){
            subSectionMap.put(subsecSet.Sub_Section__c, subsecSet);
        }
        if(!mainSectionMap.isEmpty()){
            Map<String, TreeStructure> parentStructure = getAllSectionSettingInfo(mainSectionMap, subSectionMap);
            return parentStructure.values();
        }
        return null;
    }

    /*************************************************
    * Method Name: getAllSectionSettingInfo
    * Author: Hang Lam
    * Date: 18/05/2020
    * Params: mainSectionMap
    * Params: subSectionMap
    * Return: Map TreeStructure
    * Exceptions:
    * Revision: 
    *************************************************/
    private static Map<String, TreeStructure> getAllSectionSettingInfo(Map<String, SectionSetting__c> mainSectionMap, Map<String, SectionSetting__c> subSectionMap){
        Map<String, TreeStructure> result = new Map<String, TreeStructure>();
        Map<String, List<SectionSetting__c>> mainSectionFieldMap = new  Map<String, List<SectionSetting__c>>();
        Map<String, List<SectionSetting__c>> subMainSectionMap = new  Map<String, List<SectionSetting__c>>();
        Map<String, List<SectionSetting__c>> subSectionFieldMap = new  Map<String, List<SectionSetting__c>>();

        System.debug('@@@mainSectionMap: ' + mainSectionMap);
        System.debug('>>>subSectionMap>>>'+subSectionMap);
        //get main section fields
        for(SectionSetting__c mainSecField : [ SELECT Id, Sub_Section__c, Main_Section__c, Source_Field_Label__c 
                                        FROM SectionSetting__c 
                                        WHERE Type_Of_Section__c = 'Field'  
                                        AND Sub_Section__c = Null
                                        AND Main_Section__c IN: mainSectionMap.keySet()]){
            if(!String.isBlank(mainSecField.Main_Section__c)) {
                if(mainSectionFieldMap.containsKey(mainSecField.Main_Section__c)){
                    mainSectionFieldMap.get(mainSecField.Main_Section__c).add(mainSecField);
                }else{
                    mainSectionFieldMap.put(mainSecField.Main_Section__c, new List<SectionSetting__c> {mainSecField});
                }
            }
        }
        System.debug('@@@mainSectionFieldMap: ' + mainSectionFieldMap);
        

        //get sub section
        for(SectionSetting__c subSec : [ SELECT Id, Sub_Section__c, Main_Section__c 
                                        FROM SectionSetting__c 
                                        WHERE Type_Of_Section__c = 'SubSection' AND 
                                        Main_Section__c IN: mainSectionMap.keySet()]){
            if(!String.isBlank(subSec.Main_Section__c)) {
                if(subMainSectionMap.containsKey(subSec.Main_Section__c)){
                    subMainSectionMap.get(subSec.Main_Section__c).add(subSec);
                }else{
                    subMainSectionMap.put(subSec.Main_Section__c, new List<SectionSetting__c> {subSec});
                }
            }
        }

        //get sub section fields
        for(SectionSetting__c subSecField : [ SELECT Id, Sub_Section__c, Main_Section__c, Source_Field_Label__c
                                        FROM SectionSetting__c 
                                        WHERE Type_Of_Section__c = 'Field' AND 
                                        Sub_Section__c IN: subSectionMap.keySet()]){
            if(!String.isBlank(subSecField.Sub_Section__c)) {
                if(subSectionFieldMap.containsKey(subSecField.Sub_Section__c)){
                    subSectionFieldMap.get(subSecField.Sub_Section__c).add(subSecField);
                }else{
                    subSectionFieldMap.put(subSecField.Sub_Section__c, new List<SectionSetting__c> {subSecField});
                }
            }
        }

        for(String mainSecName : mainSectionMap.keySet()){
            SectionSetting__c mainSec = mainSectionMap.get(mainSecName);
            TreeStructure mainSecStructure = new TreeStructure(mainSec.Main_Section__c, mainSec.Id, false, null);
            
            // add main section fields
            if(mainSectionFieldMap.containsKey(mainSecName)){
                for(SectionSetting__c mainSecField : mainSectionFieldMap.get(mainSecName)){
                    TreeStructure mainSecFieldStructure = new TreeStructure(mainSecField.Source_Field_Label__c, mainSecField.Id, false, null);
                    mainSecStructure.items.add(mainSecFieldStructure);
                }
                
            }
            //add Sub Section
            if(subMainSectionMap.containsKey(mainSecName)){
                for(SectionSetting__c subSec : subMainSectionMap.get(mainSecName)){
                    TreeStructure subSecStructure = new TreeStructure(subSec.Sub_Section__c, subSec.Id, false, null);
                    if(subSectionFieldMap.containsKey(subSec.Sub_Section__c)){
                        for(SectionSetting__c subSecField : subSectionFieldMap.get(subSec.Sub_Section__c)){
                            TreeStructure subSecFieldStructure = new TreeStructure(subSecField.Source_Field_Label__c, subSecField.Id, false, null);
                            subSecStructure.items.add(subSecFieldStructure);
                        }
                    }
                    mainSecStructure.items.add(subSecStructure);
                }
            }
            result.put(mainSecName, mainSecStructure);
        }
        return result;
    }
}