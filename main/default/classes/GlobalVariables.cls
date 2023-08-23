/**
 * @description       : 
 * @author            : Maeran Shaikh
 * @group             : 
 * @last modified on  : 12-21-2021
 * @last modified by  : Maeran Shaikh
**/
public with sharing class GlobalVariables {
    // Product Name labels
    public static final String PROD_NAME_FOR_CYBER = System.Label.Product_Name_for_Cyber;
    public static final String PROD_NAME_FOR_MPL = System.Label.Product_Name_for_MPL;
    public static final String PROD_NAME_FOR_PI = System.Label.Product_Name_for_Professional_Indemnity;
    public static final String PROD_NAME_FOR_PCC = System.Label.Product_Name_for_PCC;
    public static final String PROD_NAME_FOR_DNO = 	System.Label.Product_Name_for_DNO;
    public static final String PROD_NAME_FOR_EPL = 	System.Label.Product_Name_for_EPL;
    public static final String PROD_NAME_FOR_CYBER_SHORT = 'Cyber';
    public static final String PROD_NAME_FOR_MPL_SHORT = 'MPL';
    public static final String PROD_NAME_FOR_SHOPX = System.Label.Shopping_X;


    //Quote Process Labels
    public static final String CELERITY = 'Celerity';
    public static final String AQUEOUS = 'Aqueous';
    public static final String OTHER = 'Other';
    //product list
    public static final Set<String> CEL_PRODUCTS = new Set<String>{PROD_NAME_FOR_CYBER_SHORT,PROD_NAME_FOR_MPL_SHORT,PROD_NAME_FOR_PCC, PROD_NAME_FOR_CYBER, PROD_NAME_FOR_MPL,PROD_NAME_FOR_DNO, PROD_NAME_FOR_EPL};
    public static final Set<String> AQ_PRODUCTS = new Set<String>{PROD_NAME_FOR_PI};


    //Common Recorrd Type Names
    public static final String RT_NAME_CELERITY = 'Celerity';
    public static final String RT_NAME_AQUEOUS = 'Aqueous';

    //Recorrd Type Name Agency Licenses
    public static final String RT_NAME_AGENCY_LICENSE_MRE = 'MRe Appointment';
    public static final String RT_NAME_AGENCY_LICENSE_GENERAL = 'General';
    
    //Recorrd Type Name Broker Licenses
    public static final String RT_NAME_BROKER_LICENSE_MRE = 'MRe Appointment';
    public static final String RT_NAME_BROKER_LICENSE_GENERAL = 'General';

    //Recorrd Type Name Account
    public static final String RT_NAME_ACCOUNT_BUSINESS = 'Business';
    public static final String RT_NAME_ACCOUNT_BROKER = 'Broker';
    public static final String RT_NAME_ACCOUNT_OTHER = 'Other';

    //Recorrd Type Name Contact
    public static final String RT_NAME_CONTACT_BUSINESS = 'Business';
    public static final String RT_NAME_CONTACT_BROKER = 'Broker';
    public static final String RT_NAME_CONTACT_OTHER = 'Other';

    //subjectivity record types
    public static final String RT_NAME_SUBJECTIVITY_CELERITY = 'Celerity Subjectivity'; 
    public static final String RT_NAME_SUBJECTIVITY_AQUEOUS = 'Aqueous Subjectivity';
}