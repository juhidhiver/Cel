import { LightningElement, track, api, wire } from 'lwc';
import getSubmissionId from '@salesforce/apex/SubmissionInfoLwcController.getSubmissionId';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, updateRecord, deleteRecord, createRecord } from 'lightning/uiRecordApi';
import getListSectionSetting from '@salesforce/apex/SubmissionInfoLwcController.getListSectionSetting';
import getOpp from '@salesforce/apex/SubmissionInfoLwcController.getOpp';
import getProductName from '@salesforce/apex/SubmissionInfoLwcController.getProductName';
import getListBrokerInfo from '@salesforce/apex/SubmissionInfoLwcController.getListBrokerInfo';
import getAccountDetails from '@salesforce/apex/SubmissionInfoLwcController.getAccountDetails';
import getStageNameSubmission from '@salesforce/apex/SubmissionInfoLwcController.getStageNameSubmission';
import makeAllQuotedQuotesRated from '@salesforce/apex/SubmissionInfoLwcController.makeAllQuotedQuotesRated';
import getSubmissionLossDetailBySubmission from '@salesforce/apex/SubmissionInfoLwcController.getSubmissionLossDetailBySubmission';
import checkRelatedBoundQuotesPresent from '@salesforce/apex/SubmissionInfoLwcController.checkRelatedBoundQuotesPresent';
import getSubmissionAdditionalInsuredDetails from '@salesforce/apex/SubmissionInfoLwcController.getSubmissionAdditionalInsuredDetails';
import updateAllQuoteStatusAndCloseReason from '@salesforce/apex/SubmissionInfoLwcController.updateAllQuoteStatusAndCloseReason';
import updateExistingReferredQuotes from '@salesforce/apex/SubmissionInfoLwcController.updateExistingReferredQuotes';
import { refreshApex } from '@salesforce/apex';
import ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE from '@salesforce/label/c.ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import CLOSED_REASON_FIELD from '@salesforce/schema/Opportunity.Loss_Reason__c';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import unDeclineUpdateSubmission from '@salesforce/apex/SubmissionInfoLwcController.unDeclineUpdateSubmission';
const QUOTE_PROCESS_STATUS_INSURED_INFO = 'Insured Info';
const QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS = 'Underwritting Analysis';
const QUOTE_PROCESS_STATUS_SUBMISSION_INFO = 'Submission Info';
const QUOTE_PROCESS_STATUS_CLEARANCE = "Clearance";
import updateQuoteStatusForAQ from "@salesforce/apex/InsureAccountController.updateQuoteStatusForAQ";
import ACCOUNTINSURED_OBJECT from "@salesforce/schema/Additional_Insured__c";


const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];
const additionalInsuredActions = [
    { label: 'Delete', name: 'delete' }
];
export default class SubmissionInfoLwc extends LightningElement {
    @api recordId;
    @api oppId;
    @track disableRelatedList = true;
    @track enableBrokerEdit = false;
    @track enableBrokerDelete = false;
    @track recordTypeId;
    @track sectionList;
    @track mainActiveSections;
    @track isEditForm = true;
    @track isDeclined = false;
    @track error;
    @track specialFieldMap = {};
    @track opp;
    @track productName;
    @track stageName;
    @track statusNavigate;
    @track isShowLossDetail = false;
    @track isShowAdditionalInsured = true;
    //Added by Vinayesh
    @track showClearance = false;
    subSectionChildFields = [];
    @api mainSectionBrokerTitle;
    @track isClosedLost = false;
    @track hideDeclineCloseBtn;
    @track isLoadingInit = false;
    @track nonEditable = false;
    @track isHavingAmendment = false;
    @api isAqueousPI;
    @track declineOtherTextDisplay = false;
    @track declineOtherText;

    @track recordInfo = {
        fields: [
            { name: "Name", value: null, initValue: false },
            { name: "Opportunity__c", value: this.oppId, initValue: true },
            { name: "Broker_Contact__c", value: null, initValue: false },
            { name: "IsPrimaryBroker__c", value: false, initValue: true },
            { name: "Relationship_Type__c", value: null, initValue: false },
            { name: "Broker_Block_Override__c", value: null, initValue: false }
        ]
    }
    @track actionCompactType;
    @track isCloseCompactAction = false;
    @track closeReason;
    @track oppRecordId;
    get recordInfoDefined() {
        return this.recordInfo !== undefined && this.recordInfo.fields !== undefined
    }

    get isClosedWonOrLost() {
        return (this.stageName == 'Closed Won' || this.stageName == 'Closed Lost' || this.stageName == 'Declined');
    }
    
    connectedCallback() {
        this.isLoadingInit = true;
        console.log('this.recordId:' + this.recordId);
        this.fetchData();


        var countryJson = [];
        countryJson = [
            { "isoCode": "GG", "label": "Guernsey" },
            { "isoCode": "IM", "label": "Isle of Man" },
            { "isoCode": "JE", "label": "Jersey" },
            { "isoCode": "IE", "label": "Northern Ireland" },
            { "isoCode": "GB", "label": "United Kingdom" },
        ];
        var countryState = { "US": [{ "label": "Armed Forces Americas", "value": "AA" }, { "label": "Armed Forces Europe", "value": "AE" }, { "label": "Alaska", "value": "AK" }, { "label": "Alabama", "value": "AL" }, { "label": "Armed Forces Pacific", "value": "AP" }, { "label": "Arkansas", "value": "AR" }, { "label": "American Samoa", "value": "AS" }, { "label": "Arizona", "value": "AZ" }, { "label": "California", "value": "CA" }, { "label": "Colorado", "value": "CO" }, { "label": "Connecticut", "value": "CT" }, { "label": "District of Columbia", "value": "DC" }, { "label": "Delaware", "value": "DE" }, { "label": "Florida", "value": "FL" }, { "label": "Federated Micronesia", "value": "FM" }, { "label": "Georgia", "value": "GA" }, { "label": "Guam", "value": "GU" }, { "label": "Hawaii", "value": "HI" }, { "label": "Iowa", "value": "IA" }, { "label": "Idaho", "value": "ID" }, { "label": "Illinois", "value": "IL" }, { "label": "Indiana", "value": "IN" }, { "label": "Kansas", "value": "KS" }, { "label": "Kentucky", "value": "KY" }, { "label": "Louisiana", "value": "LA" }, { "label": "Massachusetts", "value": "MA" }, { "label": "Maryland", "value": "MD" }, { "label": "Maine", "value": "ME" }, { "label": "Marshall Islands", "value": "MH" }, { "label": "Michigan", "value": "MI" }, { "label": "Minnesota", "value": "MN" }, { "label": "Missouri", "value": "MO" }, { "label": "Northern Mariana Islands", "value": "MP" }, { "label": "Mississippi", "value": "MS" }, { "label": "Montana", "value": "MT" }, { "label": "North Carolina", "value": "NC" }, { "label": "North Dakota", "value": "ND" }, { "label": "Nebraska", "value": "NE" }, { "label": "New Hampshire", "value": "NH" }, { "label": "New Jersey", "value": "NJ" }, { "label": "New Mexico", "value": "NM" }, { "label": "Nevada", "value": "NV" }, { "label": "New York", "value": "NY" }, { "label": "Ohio", "value": "OH" }, { "label": "Oklahoma", "value": "OK" }, { "label": "Oregon", "value": "OR" }, { "label": "Pennsylvania", "value": "PA" }, { "label": "Puerto Rico", "value": "PR" }, { "label": "Palau", "value": "PW" }, { "label": "Rhode Island", "value": "RI" }, { "label": "South Carolina", "value": "SC" }, { "label": "South Dakota", "value": "SD" }, { "label": "Tennessee", "value": "TN" }, { "label": "Texas", "value": "TX" }, { "label": "United States Minor Outlying Islands", "value": "UM" }, { "label": "Utah", "value": "UT" }, { "label": "Virginia", "value": "VA" }, { "label": "US Virgin Islands", "value": "VI" }, { "label": "Vermont", "value": "VT" }, { "label": "Washington", "value": "WA" }, { "label": "Wisconsin", "value": "WI" }, { "label": "West Virginia", "value": "WV" }, { "label": "Wyoming", "value": "WY" }], "CN": [{ "label": "Beijing", "value": "11" }, { "label": "Tianjin", "value": "12" }, { "label": "Hebei", "value": "13" }, { "label": "Shanxi", "value": "14" }, { "label": "Nei Mongol", "value": "15" }, { "label": "Liaoning", "value": "21" }, { "label": "Jilin", "value": "22" }, { "label": "Heilongjiang", "value": "23" }, { "label": "Shanghai", "value": "31" }, { "label": "Jiangsu", "value": "32" }, { "label": "Zhejiang", "value": "33" }, { "label": "Anhui", "value": "34" }, { "label": "Fujian", "value": "35" }, { "label": "Jiangxi", "value": "36" }, { "label": "Shandong", "value": "37" }, { "label": "Henan", "value": "41" }, { "label": "Hubei", "value": "42" }, { "label": "Hunan", "value": "43" }, { "label": "Guangdong", "value": "44" }, { "label": "Guangxi", "value": "45" }, { "label": "Hainan", "value": "46" }, { "label": "Chongqing", "value": "50" }, { "label": "Sichuan", "value": "51" }, { "label": "Guizhou", "value": "52" }, { "label": "Yunnan", "value": "53" }, { "label": "Xizang", "value": "54" }, { "label": "Shaanxi", "value": "61" }, { "label": "Gansu", "value": "62" }, { "label": "Qinghai", "value": "63" }, { "label": "Ningxia", "value": "64" }, { "label": "Xinjiang", "value": "65" }, { "label": "Chinese Taipei", "value": "71" }, { "label": "Hong Kong", "value": "91" }, { "label": "Macao", "value": "92" }], "AD": [], "AE": [], "AF": [], "AG": [], "AI": [], "AL": [], "AM": [], "AO": [], "AQ": [], "AR": [], "AT": [], "AU": [{ "label": "Australian Capital Territory", "value": "ACT" }, { "label": "New South Wales", "value": "NSW" }, { "label": "Northern Territory", "value": "NT" }, { "label": "Queensland", "value": "QLD" }, { "label": "South Australia", "value": "SA" }, { "label": "Tasmania", "value": "TAS" }, { "label": "Victoria", "value": "VIC" }, { "label": "Western Australia", "value": "WA" }], "AW": [], "AX": [], "AZ": [], "BA": [], "BB": [], "BD": [], "BE": [], "BF": [], "BG": [], "BH": [], "BI": [], "BJ": [], "BL": [], "BM": [], "BN": [], "BO": [], "BQ": [], "BR": [{ "label": "Acre", "value": "AC" }, { "label": "Alagoas", "value": "AL" }, { "label": "Amazonas", "value": "AM" }, { "label": "Amapá", "value": "AP" }, { "label": "Bahia", "value": "BA" }, { "label": "Ceará", "value": "CE" }, { "label": "Distrito Federal", "value": "DF" }, { "label": "Espírito Santo", "value": "ES" }, { "label": "Goiás", "value": "GO" }, { "label": "Maranhão", "value": "MA" }, { "label": "Minas Gerais", "value": "MG" }, { "label": "Mato Grosso do Sul", "value": "MS" }, { "label": "Mato Grosso", "value": "MT" }, { "label": "Pará", "value": "PA" }, { "label": "Paraíba", "value": "PB" }, { "label": "Pernambuco", "value": "PE" }, { "label": "Piauí", "value": "PI" }, { "label": "Paraná", "value": "PR" }, { "label": "Rio de Janeiro", "value": "RJ" }, { "label": "Rio Grande do Norte", "value": "RN" }, { "label": "Rondônia", "value": "RO" }, { "label": "Roraima", "value": "RR" }, { "label": "Rio Grande do Sul", "value": "RS" }, { "label": "Santa Catarina", "value": "SC" }, { "label": "Sergipe", "value": "SE" }, { "label": "São Paulo", "value": "SP" }, { "label": "Tocantins", "value": "TO" }], "BS": [], "BT": [], "BV": [], "BW": [], "BY": [], "BZ": [], "CA": [{ "label": "Alberta", "value": "AB" }, { "label": "British Columbia", "value": "BC" }, { "label": "Manitoba", "value": "MB" }, { "label": "New Brunswick", "value": "NB" }, { "label": "Newfoundland and Labrador", "value": "NL" }, { "label": "Nova Scotia", "value": "NS" }, { "label": "Northwest Territories", "value": "NT" }, { "label": "Nunavut", "value": "NU" }, { "label": "Ontario", "value": "ON" }, { "label": "Prince Edward Island", "value": "PE" }, { "label": "Quebec", "value": "QC" }, { "label": "Saskatchewan", "value": "SK" }, { "label": "Yukon Territories", "value": "YT" }], "CC": [], "CD": [], "CF": [], "CG": [], "CH": [], "CI": [], "CK": [], "CL": [], "CM": [], "CO": [], "CR": [], "CU": [], "CV": [], "CW": [], "CX": [], "CY": [], "CZ": [], "DE": [], "DJ": [], "DK": [], "DM": [], "DO": [], "DZ": [], "EC": [], "EE": [], "EG": [], "EH": [], "ER": [], "ES": [], "ET": [], "FI": [], "FJ": [], "FK": [], "FO": [], "FR": [], "GA": [], "GB": [{ "label": "England", "value": "ENGLAND" }], "GD": [], "GE": [], "GF": [], "GG": [], "GH": [], "GI": [], "GL": [], "GM": [], "GN": [], "GP": [], "GQ": [], "GR": [], "GS": [], "GT": [], "GW": [], "GY": [], "HM": [], "HN": [], "HR": [], "HT": [], "HU": [], "ID": [], "IE": [{ "label": "Clare", "value": "CE" }, { "label": "Cavan", "value": "CN" }, { "label": "Cork", "value": "CO" }, { "label": "Carlow", "value": "CW" }, { "label": "Dublin", "value": "D" }, { "label": "Donegal", "value": "DL" }, { "label": "Galway", "value": "G" }, { "label": "Kildare", "value": "KE" }, { "label": "Kilkenny", "value": "KK" }, { "label": "Kerry", "value": "KY" }, { "label": "Longford", "value": "LD" }, { "label": "Louth", "value": "LH" }, { "label": "Limerick", "value": "LK" }, { "label": "Leitrim", "value": "LM" }, { "label": "Laois", "value": "LS" }, { "label": "Meath", "value": "MH" }, { "label": "Monaghan", "value": "MN" }, { "label": "Mayo", "value": "MO" }, { "label": "Offaly", "value": "OY" }, { "label": "Roscommon", "value": "RN" }, { "label": "Sligo", "value": "SO" }, { "label": "Tipperary", "value": "TA" }, { "label": "Waterford", "value": "WD" }, { "label": "Westmeath", "value": "WH" }, { "label": "Wicklow", "value": "WW" }, { "label": "Wexford", "value": "WX" }], "IL": [], "IM": [], "IN": [{ "label": "Andaman and Nicobar Islands", "value": "AN" }, { "label": "Andhra Pradesh", "value": "AP" }, { "label": "Arunachal Pradesh", "value": "AR" }, { "label": "Assam", "value": "AS" }, { "label": "Bihar", "value": "BR" }, { "label": "Chandigarh", "value": "CH" }, { "label": "Chhattisgarh", "value": "CT" }, { "label": "Daman and Diu", "value": "DD" }, { "label": "Delhi", "value": "DL" }, { "label": "Dadra and Nagar Haveli", "value": "DN" }, { "label": "Goa", "value": "GA" }, { "label": "Gujarat", "value": "GJ" }, { "label": "Himachal Pradesh", "value": "HP" }, { "label": "Haryana", "value": "HR" }, { "label": "Jharkhand", "value": "JH" }, { "label": "Jammu and Kashmir", "value": "JK" }, { "label": "Karnataka", "value": "KA" }, { "label": "Kerala", "value": "KL" }, { "label": "Lakshadweep", "value": "LD" }, { "label": "Maharashtra", "value": "MH" }, { "label": "Meghalaya", "value": "ML" }, { "label": "Manipur", "value": "MN" }, { "label": "Madhya Pradesh", "value": "MP" }, { "label": "Mizoram", "value": "MZ" }, { "label": "Nagaland", "value": "NL" }, { "label": "Odisha", "value": "OR" }, { "label": "Punjab", "value": "PB" }, { "label": "Puducherry", "value": "PY" }, { "label": "Rajasthan", "value": "RJ" }, { "label": "Sikkim", "value": "SK" }, { "label": "Tamil Nadu", "value": "TN" }, { "label": "Tripura", "value": "TR" }, { "label": "Uttar Pradesh", "value": "UP" }, { "label": "Uttarakhand", "value": "UT" }, { "label": "West Bengal", "value": "WB" }], "IO": [], "IQ": [], "IR": [], "IS": [], "IT": [{ "label": "Agrigento", "value": "AG" }, { "label": "Alessandria", "value": "AL" }, { "label": "Ancona", "value": "AN" }, { "label": "Aosta", "value": "AO" }, { "label": "Ascoli Piceno", "value": "AP" }, { "label": "L'Aquila", "value": "AQ" }, { "label": "Arezzo", "value": "AR" }, { "label": "Asti", "value": "AT" }, { "label": "Avellino", "value": "AV" }, { "label": "Bari", "value": "BA" }, { "label": "Bergamo", "value": "BG" }, { "label": "Biella", "value": "BI" }, { "label": "Belluno", "value": "BL" }, { "label": "Benevento", "value": "BN" }, { "label": "Bologna", "value": "BO" }, { "label": "Brindisi", "value": "BR" }, { "label": "Brescia", "value": "BS" }, { "label": "Barletta-Andria-Trani", "value": "BT" }, { "label": "Bolzano", "value": "BZ" }, { "label": "Cagliari", "value": "CA" }, { "label": "Campobasso", "value": "CB" }, { "label": "Caserta", "value": "CE" }, { "label": "Chieti", "value": "CH" }, { "label": "Carbonia-Iglesias", "value": "CI" }, { "label": "Caltanissetta", "value": "CL" }, { "label": "Cuneo", "value": "CN" }, { "label": "Como", "value": "CO" }, { "label": "Cremona", "value": "CR" }, { "label": "Cosenza", "value": "CS" }, { "label": "Catania", "value": "CT" }, { "label": "Catanzaro", "value": "CZ" }, { "label": "Enna", "value": "EN" }, { "label": "Forlì-Cesena", "value": "FC" }, { "label": "Ferrara", "value": "FE" }, { "label": "Foggia", "value": "FG" }, { "label": "Florence", "value": "FI" }, { "label": "Fermo", "value": "FM" }, { "label": "Frosinone", "value": "FR" }, { "label": "Genoa", "value": "GE" }, { "label": "Gorizia", "value": "GO" }, { "label": "Grosseto", "value": "GR" }, { "label": "Imperia", "value": "IM" }, { "label": "Isernia", "value": "IS" }, { "label": "Crotone", "value": "KR" }, { "label": "Lecco", "value": "LC" }, { "label": "Lecce", "value": "LE" }, { "label": "Livorno", "value": "LI" }, { "label": "Lodi", "value": "LO" }, { "label": "Latina", "value": "LT" }, { "label": "Lucca", "value": "LU" }, { "label": "Monza and Brianza", "value": "MB" }, { "label": "Macerata", "value": "MC" }, { "label": "Messina", "value": "ME" }, { "label": "Milan", "value": "MI" }, { "label": "Mantua", "value": "MN" }, { "label": "Modena", "value": "MO" }, { "label": "Massa and Carrara", "value": "MS" }, { "label": "Matera", "value": "MT" }, { "label": "Naples", "value": "NA" }, { "label": "Novara", "value": "NO" }, { "label": "Nuoro", "value": "NU" }, { "label": "Ogliastra", "value": "OG" }, { "label": "Oristano", "value": "OR" }, { "label": "Olbia-Tempio", "value": "OT" }, { "label": "Palermo", "value": "PA" }, { "label": "Piacenza", "value": "PC" }, { "label": "Padua", "value": "PD" }, { "label": "Pescara", "value": "PE" }, { "label": "Perugia", "value": "PG" }, { "label": "Pisa", "value": "PI" }, { "label": "Pordenone", "value": "PN" }, { "label": "Prato", "value": "PO" }, { "label": "Parma", "value": "PR" }, { "label": "Pistoia", "value": "PT" }, { "label": "Pesaro and Urbino", "value": "PU" }, { "label": "Pavia", "value": "PV" }, { "label": "Potenza", "value": "PZ" }, { "label": "Ravenna", "value": "RA" }, { "label": "Reggio Calabria", "value": "RC" }, { "label": "Reggio Emilia", "value": "RE" }, { "label": "Ragusa", "value": "RG" }, { "label": "Rieti", "value": "RI" }, { "label": "Rome", "value": "RM" }, { "label": "Rimini", "value": "RN" }, { "label": "Rovigo", "value": "RO" }, { "label": "Salerno", "value": "SA" }, { "label": "Siena", "value": "SI" }, { "label": "Sondrio", "value": "SO" }, { "label": "La Spezia", "value": "SP" }, { "label": "Syracuse", "value": "SR" }, { "label": "Sassari", "value": "SS" }, { "label": "Savona", "value": "SV" }, { "label": "Taranto", "value": "TA" }, { "label": "Teramo", "value": "TE" }, { "label": "Trento", "value": "TN" }, { "label": "Turin", "value": "TO" }, { "label": "Trapani", "value": "TP" }, { "label": "Terni", "value": "TR" }, { "label": "Trieste", "value": "TS" }, { "label": "Treviso", "value": "TV" }, { "label": "Udine", "value": "UD" }, { "label": "Varese", "value": "VA" }, { "label": "Verbano-Cusio-Ossola", "value": "VB" }, { "label": "Vercelli", "value": "VC" }, { "label": "Venice", "value": "VE" }, { "label": "Vicenza", "value": "VI" }, { "label": "Verona", "value": "VR" }, { "label": "Medio Campidano", "value": "VS" }, { "label": "Viterbo", "value": "VT" }, { "label": "Vibo Valentia", "value": "VV" }], "JE": [], "JM": [], "JO": [], "JP": [], "KE": [], "KG": [], "KH": [], "KI": [], "KM": [], "KN": [], "KP": [], "KR": [], "KW": [], "KY": [], "KZ": [], "LA": [], "LB": [], "LC": [], "LI": [], "LK": [], "LR": [], "LS": [], "LT": [], "LU": [], "LV": [], "LY": [], "MA": [], "MC": [], "MD": [], "ME": [], "MF": [], "MG": [], "MK": [], "ML": [], "MM": [], "MN": [], "MO": [], "MQ": [], "MR": [], "MS": [], "MT": [], "MU": [], "MV": [], "MW": [], "MX": [{ "label": "Aguascalientes", "value": "AG" }, { "label": "Baja California", "value": "BC" }, { "label": "Baja California Sur", "value": "BS" }, { "label": "Chihuahua", "value": "CH" }, { "label": "Colima", "value": "CL" }, { "label": "Campeche", "value": "CM" }, { "label": "Coahuila", "value": "CO" }, { "label": "Chiapas", "value": "CS" }, { "label": "Federal District", "value": "DF" }, { "label": "Durango", "value": "DG" }, { "label": "Guerrero", "value": "GR" }, { "label": "Guanajuato", "value": "GT" }, { "label": "Hidalgo", "value": "HG" }, { "label": "Jalisco", "value": "JA" }, { "label": "Mexico State", "value": "ME" }, { "label": "Michoacán", "value": "MI" }, { "label": "Morelos", "value": "MO" }, { "label": "Nayarit", "value": "NA" }, { "label": "Nuevo León", "value": "NL" }, { "label": "Oaxaca", "value": "OA" }, { "label": "Puebla", "value": "PB" }, { "label": "Querétaro", "value": "QE" }, { "label": "Quintana Roo", "value": "QR" }, { "label": "Sinaloa", "value": "SI" }, { "label": "San Luis Potosí", "value": "SL" }, { "label": "Sonora", "value": "SO" }, { "label": "Tabasco", "value": "TB" }, { "label": "Tlaxcala", "value": "TL" }, { "label": "Tamaulipas", "value": "TM" }, { "label": "Veracruz", "value": "VE" }, { "label": "Yucatán", "value": "YU" }, { "label": "Zacatecas", "value": "ZA" }], "MY": [], "MZ": [], "NA": [], "NC": [], "NE": [], "NF": [], "NG": [], "NI": [], "NL": [], "NO": [], "NP": [], "NR": [], "NU": [], "NZ": [], "OM": [], "PA": [], "PE": [], "PF": [], "PG": [], "PH": [], "PK": [], "PL": [], "PM": [], "PN": [], "PS": [], "PT": [], "PY": [], "QA": [], "RE": [], "RO": [], "RS": [], "RU": [], "RW": [], "SA": [], "SB": [], "SC": [], "SD": [], "SE": [], "SG": [], "SH": [], "SI": [], "SJ": [], "SK": [], "SL": [], "SM": [], "SN": [], "SO": [], "SR": [], "SS": [], "ST": [], "SV": [], "SX": [], "SY": [], "SZ": [], "TC": [], "TD": [], "TF": [], "TG": [], "TH": [], "TJ": [], "TK": [], "TL": [], "TM": [], "TN": [], "TO": [], "TR": [], "TT": [], "TV": [], "TW": [], "TZ": [], "UA": [], "UG": [], "UY": [], "UZ": [], "VA": [], "VC": [], "VE": [], "VG": [], "VN": [], "VU": [], "WF": [], "WS": [], "YE": [], "YT": [], "ZA": [], "ZM": [], "ZW": [] }
        for (let index = 0; index < countryJson.length; index++) {
            const country = countryJson[index];
            this.countryOptions.push({ "label": country.label, "value": country.isoCode });
            console.log('country option: ' + this.countryOptions);
            const stateList = countryState[country.isoCode];
            this.countryProvinceMap[country.isoCode] = stateList;
        }
    }

    wireOppData = null;
    /**
     * Wire method being used to automatically refresh page when status changed from declined to new using quick action.
     */
    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Compact']})
    wiredRecord({ result }) {
        this.wireOppData = result;
    }

    fetchData() {
        getSubmissionId({
            recordId: this.recordId
        })
            .then((result) => {
                //tuan.d.nguyen added 24-Jun-2020
                console.log('getSubmissionId', result);
                this.oppId = result.data.Id;
                this.stageName = result.data.StageName;
                if (this.stageName == 'Closed Won' || this.stageName == 'Closed Lost' || this.stageName == 'Declined') {
                    
                    this.isEditForm = false;
                    this.disableRelatedList = true;
                    this.isDeclined = true;
                }
                //check if Amendment quote exists
                if( result.data.Quotes && result.data.Quotes.length > 0 ){
                    this.isEditForm = true;
                    this.disableRelatedList = true;
                    this.isDeclined = false;
                    this.isHavingAmendment = true;
                }
                console.log('@@@ oppId 1 ' + this.oppId);
                //Added by Vinayesh
                this.getProduct();
                this.getListSecSetting();
                this.recordInfo.fields.forEach(element => {
                    if (element.name == 'Opportunity__c') {
                        element.value = this.oppId;
                    }
                });

                getListBrokerInfo({ submissionId: this.oppId })
                    .then((result) => {
                        console.log('@@@databorker: ' + JSON.stringify(result));
                        this.subSectionChildFields = result;
                        if (result.length > 0) //Added by GP
                            this.mainSectionBrokerTitle = result[0].sourceMainSectionTitle;
                    })
                    .catch((error) => {
                        console.log('@@@error: ' + JSON.stringify(error));
                    })

                  

            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
            })

            
    }

    //Added by Vinayesh
    getProduct(){
          getProductName({ recordId: this.recordId})
          .then((result) => {
              console.log('@@@databorker: ' + JSON.stringify(result));
              this.productName = result;
              if (this.productName == 'Private Company Combo'){
                  this.showClearance = true;
              }
                  
          })
          .catch((error) => {
              console.log('@@@error: ' + JSON.stringify(error));
          })
    }

    getListSecSetting() {
        console.log('RecordId: ' + this.recordId);
        getListSectionSetting({ recordId: this.recordId })
            .then((result) => {
                console.log('Get Section: ' + JSON.stringify(result));
                this.sectionList = result.sections;
                this.mainActiveSections = result.activeSections;
                var fieldList = [];
                this.sectionList.forEach(section => {
                    section.mainSectionFields.forEach(field => {
                        fieldList.push(field.sourceFieldApi);
                        if( this.isHavingAmendment && (field.sourceFieldApi == 'Effective_Date__c' || field.sourceFieldApi == 'Expiration_Date__c')){
                            field.readOnly = true;
                        }
                    });
                });
                //console.log('@@@fieldList: ' + fieldList);
                this.getOpportunity(fieldList);
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
            })
    }

    

    getOpportunity(fieldList) {
        getOpp({
            oppId: this.oppId,
            fieldList: JSON.stringify(fieldList)
        })
            .then((result) => {

         /************** CD-169 ********/
                console.log('LOSS Reason');
                if(result['Loss_Reason__c'] != 'Other'){
                   for(var i=0;i< this.sectionList.length;i++){
                      for(var j=0;j<this.sectionList[i].mainSectionFields.length;j++){
                         if(this.sectionList[i].mainSectionFields[j].sourceFieldApi == 'Decline_Other_Reason__c'){
                            this.sectionList[i].mainSectionFields.splice(j,1);
                         }
                        }
                     }
            }
           this.sectionList = this.sectionList;
            /************** CD-169 End********/

                console.log("Return opp: " + JSON.stringify(result));
                var fieldValueMap = result;
                this.recordTypeId = fieldValueMap['RecordTypeId'];
                this.submissionType = fieldValueMap['Type'];
                const disAllowedQuoteStatus = ['Bound','Closed','Rejected','Correction','Cancelled'];
                const disAllowedQuoteTypes = ['Coverage Amendment', 'Policy Duration Change', 'Flat Cancellation', 'Midterm Cancellation'];
                /* START Implementation for CD-138 */
                //check for 'Coverage Amendment', 'Policy Duration Change', 'Flat Cancellation', 'Midterm Cancellation' types
                let isDisallowedQuoteType = false;
                if(result.Quotes && result.Quotes.length > 0){
                    for(var i = 0; i < result.Quotes.length; i++){
                        if(disAllowedQuoteTypes.includes(result.Quotes[i].Quote_Type__c)){
                            this.disableRelatedList = true;
                            this.enableBrokerEdit = false;
                            this.enableBrokerDelete = false;
                            isDisallowedQuoteType = true;
                            break;
                        }
                    }
                }
                if(!isDisallowedQuoteType){
                    if(result.Type == 'New Business'){
                        this.disableRelatedList = false;
                        this.enableBrokerEdit = true;
                        this.enableBrokerDelete = true;
                        if(result.Quotes && result.Quotes.length > 0){
                            let isOpenQuote = false;
                            for(var i = 0; i < result.Quotes.length; i++){
                                if(result.Quotes[i].Quote_Type__c == 'New Business' && !disAllowedQuoteStatus.includes(result.Quotes[i].Status)){
                                    isOpenQuote = true;
                                    break;
                                }
                            }
                            if(!isOpenQuote){
                                this.disableRelatedList = true;
                                this.enableBrokerEdit = false;
                                this.enableBrokerDelete = false;
                            }
                        }
                    }
                    else if(result.Type == 'Renewal'){
                        if(result.Quotes && result.Quotes.length > 0){
                            this.disableRelatedList = false;
                            this.enableBrokerEdit = true;
                            this.enableBrokerDelete = true;

                            let isOpenQuote = false;
                            for(var i = 0; i < result.Quotes.length; i++){
                                if(result.Quotes[i].Quote_Type__c == 'Renewal' && !disAllowedQuoteStatus.includes(result.Quotes[i].Status)){
                                    isOpenQuote = true;
                                    break;
                                }
                            }
                            if(!isOpenQuote){
                                this.disableRelatedList = true;
                                this.enableBrokerEdit = false;
                                this.enableBrokerDelete = false;
                            }
                        }
                    }
                    else if(result.Type == 'Full Amendment'){
                        this.enableBrokerDelete = false;
                        this.disableRelatedList = true;
                        if(result.Quotes && result.Quotes.length > 0){
                            this.enableBrokerEdit = true;
                            let isOpenQuote = false;
                            for(var i = 0; i < result.Quotes.length; i++){
                                if(result.Quotes[i].Quote_Type__c == 'Full Amendment' && !disAllowedQuoteStatus.includes(result.Quotes[i].Status)){
                                    isOpenQuote = true;
                                    break;
                                }
                            }
                            this.enableBrokerEdit = isOpenQuote;
                        }
                    }
                }

                /* END Implementation for CD-138 */

                // this.recordTypeId = null;
                // console.log('@@@this.recordTypeId: ' + this.recordTypeId);
                this.sectionList.forEach(section => {
                    section.mainSectionFields.forEach(field => {
                        if (fieldValueMap[field.sourceFieldApi]) {
                            field.value = fieldValueMap[field.sourceFieldApi];
                            if ((field.sourceFieldApi == 'Effective_Date__c' || field.sourceFieldApi == 'Received_Date__c') &&
                                (this.submissionType == 'Full Amendment' || this.submissionType == 'Coverage Amendment' || this.submissionType == 'Policy Duration Change')) {
                                field.readOnly = true;
                            }
                        }

                        if(field.sourceFieldApi == 'StageName' && fieldValueMap[field.sourceFieldApi] == 'Declined' && !this.isAqueousPI){
                            console.log('vinay stage declined: ' + this.stageName);
                            field.isDeclinedStageField = true;
                            this.isDeclined = true;
                        }
                        // //tuan.d.nguyen added 24-Jun-2020
                        // if(this.stageName == 'Closed Won')
                        //     field.readOnly = true;
                        // else field.readOnly = false;
                    });

                });
                this.isLoadingInit = false;
            })
            .catch((error) => {
                console.log('@@@error 2: ' + JSON.stringify(error));
            })
    }

    handleEditClick() {
        this.isEditForm = !this.isEditForm;
    }

    /**
     * 
     * @returns Updating opportunity for changing stage name form declined.
     */
    async saveOppForStageChange(){
        const fields = {};
        let currStage = '';
        fields['Id'] = this.oppId;
        this.template.querySelectorAll("lightning-input-field").forEach(element =>{
            if(element.fieldName == 'StageName'){
                currStage = element.value;
            }
        });
       if(!currStage || currStage == 'Declined') return;
       fields['StageName'] = currStage;
       fields['UW_Status__c'] = 'Awaiting Underwriting Review';
       const recordInput = { fields };
       await updateRecord(recordInput)
        .then(opp => {
            this.isDeclined = false;
            //this.updateQuoteProcess();
            refreshApex(this.wireOppData);
            this.fetchData();
            this.showToast('Success', 'Update records successfully!', "success");
        })
        .catch(error => {
            console.log('Error updating Opportunity: ' + error);
        });
    }
   
    @track isSubSaveSuccess;
    @api
    async handleSave() {
        if(this.isDeclined) {
            await this.saveOppForStageChange();
            return true;
        }
        this.isChangeOnSubmission = false;
        this.template
            .querySelectorAll("c-generate-element-lwc")
            .forEach(element => {
                if (!this.isChangeOnSubmission)
                    this.isChangeOnSubmission = element.checkChangesOnSubmission();
            });
        if(!this.isChangeOnSubmission) return true;
        const fields = {};
        const oldValueOfFields = {}
        console.log('Fields Before update: ' + JSON.stringify(fields));
        this.sectionList.forEach(section => {
            section.mainSectionFields.forEach(field => {
                console.log('Fields-> ' + field.sourceFieldApi + ' :' + field.value);
                fields[field.sourceFieldApi] = field.value;
                oldValueOfFields[field.sourceFieldApi] = field.value;
            });
        });
        console.log('oldValueOfFields -->' + JSON.stringify(oldValueOfFields));
        var isReadyToSave = false;
        console.log('inside');
        // this.template
        //     .querySelectorAll("c-generate-element-lwc")
        //     .forEach(element => {
        //         var tmp = element.validateRequiredField();
        //         if(!tmp) isReadyToSave = false;        
        //     });
        // this.template.querySelectorAll('.required-field').forEach(element => {
        //     // console.log("@@@element value: " + JSON.stringify(element.value));
        //     var value = element.value;
        //     if (!value || value == undefined || value === "") {
        //         isReadyToSave = false;
        //     }
        //     element.reportValidity(); 
        // });
        isReadyToSave = this.validateForm();
        if (isReadyToSave) {
            const updateFields = {};
            this.template
                .querySelectorAll("c-generate-element-lwc")
                .forEach(element => {
                    var tmp = element.getValuesOnForm();
                    console.log('Tmp: ' + JSON.stringify(tmp));
                    if (tmp != null) {
                        fields[tmp.key] = tmp.value;
                        //tuan.d.nguyen added 24-Jun-2020
                        if (tmp.key == 'StageName')
                            this.stageName = tmp.value;
                    }
                });

            if (fields['Professional_Business_Description__c']) {
                var professionalBusiness = fields['Professional_Business_Description__c'];
                if (professionalBusiness.length > 300) {
                    this.showToast('Error', 'Field limit 300: Professional Business Description', "error");
                    return;
                }
            }
            if (fields['Competing_Insurer__c']) {
                var competingInsured = fields['Competing_Insurer__c'];
                if (competingInsured.length > 255) {
                    this.showToast('Error', 'Field limit 255: Competing Insurer', "error");
                    return;
                }
            }

            console.log('Profesion value: ' + fields['Professional_Business_Description__c']);
            console.log('Competing value: ' + fields['Competing_Insurer__c']);

            ['LastModifiedById', 'CreatedById', 'LastModifiedDate', 'CreatedDate'].forEach(e => delete fields[e]);
            console.log('fields After delete ' + JSON.stringify(fields));
            fields['Id'] = this.oppId;
            console.log('Final Fields -->' + JSON.stringify(fields));

            console.log('old value of fields -->' + JSON.stringify(oldValueOfFields))
            var newValueFields = fields;
            const recordInput = { fields };
            console.log('vinay opp id:' + this.oppId);
            await updateExistingReferredQuotes({ recordId: this.oppId })
            .then(result => {
                console.log("Success");
                updateRecord(recordInput)
                .then(account => {
                    console.log('enter then@@@');
                    this.sectionList.forEach(section => {
                        section.mainSectionFields.forEach(
                            field => {
                                field.value = fields[field.sourceFieldApi];
                            });
                    });
                    
                    this.isEditForm = !this.isEditForm;

                    const event = new CustomEvent('savesuccess', {
                        detail: {
                            oppId: this.oppId
                        }
                    });
                    this.dispatchEvent(event);
                    this.showToast('Success', 'Update records successfully!', "success");
                    this.isSubSaveSuccess = 'true';
                    console.log('this.isSubSaveSuccess' + this.isSubSaveSuccess);
                    // const checkFields = ['Professional_Business_Description__c','Competing_Insurer__c','Competition_Target_Price__c'];
                    // const changedFields = [];
                    // let totalfields = 0;
                    // let newfields = 0;
                    for (let item in newValueFields) {
                        if (item != 'Id') {
                            if ((oldValueOfFields[item] != undefined && newValueFields[item] != oldValueOfFields[item]) ||
                                (oldValueOfFields[item] === undefined && newValueFields[item])) {
                                if (item == 'Professional_Business_Description__c' || item == 'Competing_Insurer__c' || item == 'Competition_Target_Price__c') {
                                    this.updateQuoteStatusforAQ();
                                    break;
                                }
                            }
                        }
                    }
                    //console.log("Total Fields -->" + totalfields);
                    //console.log('New Fields -->' + newfields);
                    // if(totalfields === newfields && totalfields!=0){
                    //     this.updateQuoteStatusforAQ();
                    // }
                    this.updateQuoteProcess();
                })
                .catch(error => {
                    console.log('this.oppId' + this.oppId);
                    console.log('enter error@@@' + error);
                    let obj = JSON.parse(JSON.stringify(error));
                    let fieldDataDoc = obj.body.output.fieldErrors;
                    if (fieldDataDoc.length > 0) {
                        Object.keys(fieldDataDoc).forEach(field => {
                            let msg = fieldDataDoc[field][0];
                            this.showToast('Error', msg.errorCode + ' at filed: ' + msg.fieldLabel, "error");
                        })
                    } else {
                        var errDetails = [];
                        if (error.body.output.errors) {
                            error.body.output.errors.forEach(element => {
                                errDetails.push(element.message);
                                console.log('error details::' + JSON.stringify(errDetails));
                            });
                        }
                        /*var message = errDetails.toString().includes('ENTITY_IS_LOCKED') ? ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE : ('Error received: code' + error.errorCode + ', ' +
                                        'message ' + error.body.message);*/
                        //console.log('error.message::'+error.body.message)
                        var message = '';
                        if (errDetails.toString().includes('ENTITY_IS_LOCKED')) {
                            message = ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE;
                        }
                        else if (errDetails.toString().includes('Expiration Date must be greater than the Effective Date')) {
                            message = 'Expiration Date must be greater than the Effective Date';
                        }
                        else if (errDetails.toString().includes('Cannot update the Submission Status of a Quoted Opportunity')) {
                            message = 'Cannot update the Submission Status of a Quoted Opportunity';
                        }
                        else {
                            message = ('Error received: code' + error.errorCode + ', ' + 'message ' + error.body.message);
                        }

                        this.showToast('Error', message, "error");
                    }
                });
            })
            .catch((error) => {
                var message = '';
                if (error.body.message.includes('ENTITY_IS_LOCKED')) {
                    message = ERROR_CANNOT_UPDATE_SUBMISSION_HAS_LOCKED_QUOTE;
                }
                this.showToast('Error', message, "error");
                return;
            });

        } else {

            this.showToast('Error', 'Please complete all required field!', "error");

        }
        console.log('return result-->',this.isReadyToSave);
        return isReadyToSave;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleLookUpChildSelection(event) {
        this.sectionList.forEach(section => {
            section.mainSectionFields.forEach(field => {
                if (field.sourceFieldApi === event.detail.fieldNameAPI)
                    field.value = event.detail.selectedId;
            });
        });
    }

    handlePreviousButton() {

        this.template
            .querySelectorAll("c-generate-element-lwc")
            .forEach(element => {
                if (!this.isChangeOnSubmission)
                    this.isChangeOnSubmission = element.checkChangesOnSubmission();
            });
        if (this.isChangeOnSubmission) {
            if(this.productName == 'Private Company Combo'){
                this.statusNavigate = QUOTE_PROCESS_STATUS_CLEARANCE;
            }
            else{
                this.statusNavigate = QUOTE_PROCESS_STATUS_INSURED_INFO;
            }
            
            console.log('statusNavigate==', status);
            this.isDialogVisible = true;
            return;
        }
        var status = QUOTE_PROCESS_STATUS_INSURED_INFO;
        if(this.productName == 'Private Company Combo'){
            status = QUOTE_PROCESS_STATUS_CLEARANCE;
        }
        var infos = { status: status };
        const event = new CustomEvent('changequoteprocessstatus', {
            detail: infos
        });
        this.dispatchEvent(event);
    }

    isChangeOnSubmission = false;
    isDialogVisible = false;

    validateForm() {
        var isReadyToSave = true;
        this.template
            .querySelectorAll("c-generate-element-lwc")
            .forEach(element => {
                var tmp = element.validateRequiredField();
                if (!tmp) isReadyToSave = false;
            });
        this.template.querySelectorAll('.required-field').forEach(element => {
            // console.log("@@@element value: " + JSON.stringify(element.value));
            var value = element.value;
            if (!value || value == undefined || value === "") {
                isReadyToSave = false;
            }
            element.reportValidity();
        });



        return isReadyToSave;
    }

    handleNextButton() {
        this.isChangeOnSubmission = false;
        //Check validation before go the NEXT
        if (!this.validateForm()) return;
        //Check Change
        this.template
            .querySelectorAll("c-generate-element-lwc")
            .forEach(element => {
                if (!this.isChangeOnSubmission)
                    this.isChangeOnSubmission = element.checkChangesOnSubmission();
            });
        if (this.isChangeOnSubmission) {
            this.statusNavigate = QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS;
            this.isDialogVisible = true;
            return;
        }
        //End

        //Check StageName Submission is not Qualified.
        getStageNameSubmission({ submissionId: this.oppId }).then(result => {
            if (result != 'Unqualified' && result != 'Closed Lost') {
                console.log("@@@Next");
                console.log('@@@result::' + result);
                var status = QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS;
                var infos = { status: status };
                const event = new CustomEvent('changequoteprocessstatus', {
                    detail: infos
                });
                this.dispatchEvent(event);
            }
            else {
                if (result == 'Unqualified') {
                    this.showToast('', 'Stage Submission is Unqualified. Please Qualify Submission', 'warning', 'dismissable');
                }
                else {
                    if (result == 'Closed Lost') {
                        this.showToast('', 'Submission is in ' + result + ' stage. You cannot move to the next stage.', 'warning', 'dismissable');
                    }
                }
            }
        })

    }


    handleChangeQuoteProcessStatus() {
        var infos = { status: QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS };
        const event = new CustomEvent('changequoteprocessstatus', {
            detail: infos
        });
        this.dispatchEvent(event);

    }
    handleChangeAddress(event){
        if(event.detail.street) this.address.street = event.detail.street
        if(event.detail.city)   this.address.city = event.detail.city;
        if(event.detail.province)   this.address.province = event.detail.province
        if(event.detail.country)    this.address.country = event.detail.country;
        if(event.detail.postalCode) this.address.postalCode = event.detail.postalCode;        
    }
    handleChange(event) {
        console.log("You selected an account: " + event.detail.value);
        console.log("You selected an account: " + event.target.fieldName + 'gg: ' + event.detail.fieldNameAPI);
        this.isChangeOnSubmission = true;
        this.sectionList.forEach(section => {
            section.mainSectionFields.forEach(field => {
                if (field.sourceFieldApi === event.target.fieldName)
                    field.value = event.detail.value;
            });
        });
    }

    async handleClick(event) {
        if (event.detail !== 1) {
            if (event.detail.status === 'confirm') {
                this.isLoadingInit = true;
                if(await this.handleSave()){   
                    if(this.isSubSaveSuccess == 'true'){
                        var status = this.statusNavigate;
                        var infos = { status: status, accountId: this.selectedAccountId };
                         const evt = new CustomEvent('changequoteprocessstatus', {
                             detail: infos
                         });
                        this.dispatchEvent(evt);
                   }
                   this.isLoadingInit = false;
                }
             
                
              
            } else if (event.detail.status === 'cancel') {
                // this.isChangeOnSubmission = false;
                /* this.statusNavigate = 'QUOTE_PROCESS_STATUS_SUBMISSION_INFO';
                 return;*/
            }
        }
        this.isDialogVisible = false;
        // var status = QUOTE_PROCESS_STATUS_UNDERWRITTING_ANALYSIS;
        /*  var status = this.statusNavigate;
          console.log('status===>',status);
        var infos = {status : status, accountId : this.selectedAccountId};
        const evt = new CustomEvent('changequoteprocessstatus', {
            detail: infos
        });
        this.dispatchEvent(evt);*/
    }

    //Submission Loss detail
    @track isLoading = true;
    @track saving = false;
    @track openSubmissionLossDetail = false;
    @track openAdditionalInsuredDetail = false;
    @track openModalCreateSubmissionLossDetail = false;
    @track modeEditSubmissionLossDetail = false;
    @track modeCreatedSubmissionLossDetail = false;
    @track openModalCreateAdditionalInsuredDetail = false;
    @track modeEditAdditionalInsuredDetail = false;
    @track modeCreatedAdditionalInsuredDetail = false;
    @api _data;
    @api _insureddata;

    get insuredData() {
        return this._insureddata;
    }
    set insuredData(value) {
        this._insureddata = value;
    }
    get data() {
        return this._data;
    }
    set data(value) {
        this._data = value;
    }
    @track insuredColumns = [
        {
            label: 'Additional Insured Name', fieldName: 'linkSubmissionAdditionalDetailName', type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
        },
        {
            label: 'Account', fieldName: 'accId', type: 'url',
            typeAttributes: { label: { fieldName: 'linkAdditionalDetailAccountName' }, target: '_blank' }
        },
        { label: 'Account Address', fieldName: 'linkAdditionalDetailAccountAddress', type: 'text' },
        { label: 'Sanction Status', fieldName: 'sanctionStatus', type: 'text' },
        { label: 'Sanction Date', fieldName: 'sanctionDate', type: 'date' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: additionalInsuredActions,
            }
        },
    ];
    @track columns = [
        {
            label: 'Submission Loss Detail ID', fieldName: 'linkSubmissionLossDetailName', type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
        },
        { label: 'Loss Amount', fieldName: 'lossAmount', type: 'text' },
        { label: 'Number of Losses', fieldName: 'numberOfLosses', type: 'text' },
        { label: 'Product', fieldName: 'product', type: 'text' },
        // { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Year', fieldName: 'year', type: 'text'  },
        {
            type: 'action',
            typeAttributes: {
                rowActions: actions,
            }
        },
    ];
    wireResults;
    additonalInsuredWiredResults;
    @wire(getSubmissionLossDetailBySubmission, { oppId: '$oppId' })
    wiredSubmissionLossDetail(result) {
        this.wireResults = result;
        const { data, error } = result;
        if (data) {
            console.log('@@@ mydata', JSON.stringify(data));
            this.data = data;
            this.isLoading = false;
        } else if (error) {
            console.log(JSON.stringify(error));
        }
    }
    @wire(getSubmissionAdditionalInsuredDetails, { oppId: '$oppId' })
    wiredSubmissionAdditionalInsured(result) {
        this.additonalInsuredWiredResults = result;
        const { data, error } = result;
        if (data) {
            this.insuredData = data;
            this.isLoading = false;
        } else if (error) {
            console.log(JSON.stringify(error));
        }
    }
    @track isAqueous = false;

    openSubmissionLossDetailModel() {
        this.openSubmissionLossDetail = true;
    }
    openSubmissionAdditionalInsuredModel(event) {
        if(event.detail.oppStageName == 'Declined' || event.detail.oppStageName == 'Closed Won' || event.detail.oppStageName == 'Closed Lost'){
            this.nonEditable = true;
        }else{
            this.nonEditable = false;
        }
        this.isAqueous = true;
        this.openAdditionalInsuredDetail = true;
    }
    handleCancelSubmissionAdditionalInsured() {
        this.openAdditionalInsuredDetail = false;
    }
    handleCancelSubmissionLossDetail() {
        this.openSubmissionLossDetail = false;
    }

    @track isShowCreateAccount = false;
    @track accountRecordTypeId;
    @track accountRecordTypeName;
    @track isnewAccountLoading = false;

    handleCreateAccount() {
        getAccountDetails()
            .then(result => {
                var value = result.split(';');
                this.accountRecordTypeName = value[0];
                this.accountRecordTypeId = value[1];
                this.address = {}; 
                this.address.country = '';               
                this._country = '';
                this.address.province = '';
                this.isShowCreateAccount = true;
                console.log('responseardasd', JSON.stringify(result));
            })
            .catch(error => {
                console.log('error->', error)
            })
    }

    @track accountNewId;
    handleCreateAccountSuccess(event) {
        console.log("Address-->",JSON.stringify(this.address));
        console.log("Address--Street-->",JSON.stringify(this.address.street));
        if(!this.address.street){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Address is Mandatory",
                    variant: "error"
                })
            );
            return;
        }
        this.isnewAccountLoading = true;
        console.log('account Id: ' + event.detail.id, 'sub:' + this.oppId);
        this.accountNewId = event.detail.id;
        var fields = {};

        fields["Id"] = this.accountNewId;
        fields["BillingStreet"] = this.address.street;
        fields["BillingCity"] = this.address.city;
        fields["BillingStateCode"] = this.address.province;
        fields["BillingCountryCode"] = this.address.country;
        fields["BillingPostalCode"] = this.address.postalCode;

        const recordInput = { fields };
        updateRecord(recordInput)
            .then((account) => {
                this.isnewAccountLoading = false;
                this.isShowCreateAccount = false;
                this.openModalCreateAdditionalInsuredDetail = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Account created Successfully !!",
                        variant: "success"
                    })
                );
            })
            .catch((error) => {
                console.log("Error: " + JSON.stringify(error));
                this.isnewAccountLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });


        /* createAdditionalInsured({ accountId: accId, opportunityId: this.oppId })
             .then(result => {
                 var returnValue = result.split(';');
                 console.log('returnValue: ' + returnValue);
                 var message = returnValue[0];
                 var additionalId = returnValue[1];
                 if (message == 'success') {
                     refreshApex(this.additonalInsuredWiredResults);
                     this.handleCancel();
 
                     getSubmissionAdditionalInsuredDetails({ oppId: this.oppId })
                         .then(result => {
                             this.insuredData = result;
                             console.log(' this.insuredData-->' + this.insuredData);
                             this.dispatchEvent(
                                 new ShowToastEvent({
                                     title: 'Success',
                                     message: 'Record saved successfully with id: ' + additionalId,
                                     variant: 'success',
                                 }),
                             )
                         })
                 }
             })
             .catch(error => {
                 console.log('error->', error)
             })*/
    }
    @track _country = '';
    @track address = {};
    @track countryOptions = [];

    get getProvinceOptions() {
        return this.countryProvinceMap[this._country];
    }
    get getCountryOptions() {
        return this.countryOptions;
    }

    @track countryProvinceMap = {
        US: [
            { label: 'California', value: 'CA' },
            { label: 'Texas', value: 'TX' },
            { label: 'Washington', value: 'WA' },
        ],
        CN: [
            { label: 'GuangDong', value: 'GD' },
            { label: 'GuangXi', value: 'GX' },
            { label: 'Sichuan', value: 'SC' },
        ],
        GB: [
            { label: 'England', value: 'England' },
        ]
    };

    handleSelectedAddress(event) {
        const e = new Event("change");
        const element = this.template.querySelector('.addressCmp')
        console.log('element-->' + element);
        // element.dispatchEvent(e);

        console.log('Address-->' + JSON.stringify(event.detail));
        if (event.detail) {
            this.address.street = '';
            if (event.detail.address) {
                this.address.street = event.detail.address;
            }
            this.address.city = '';
            if (event.detail.city) {
                this.address.city = event.detail.city;

            }
            this.address.postalCode = '';
            if (event.detail.postalCode) {
                this.address.postalCode = event.detail.postalCode;
            }
            this.address.country = '';
            if (event.detail.countryCode) {
                this.address.country = event.detail.countryCode;
                this._country = event.detail.countryCode;
            }
            setTimeout(() => {
                this.address.province = '';
                console.log('his.address', this.address);
                if (event.detail.stateCode) {
                    let filteredProvince = this.countryProvinceMap[this._country].filter(province => province.value == event.detail.stateCode.toUpperCase());
                    if (filteredProvince.length > 0) {
                        this.address.province = event.detail.stateCode.toUpperCase();
                    }
                }
            }, 0, this);
            console.log('final address', JSON.stringify(this.address));
        }
    }

    handleAddSuccess(event) {
        this.saving = true;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record saved successfully with id: ' + event.detail.id,
                variant: 'success',
            }),
        )
        this.handleCancel();
        this.isLoading = false;
        refreshApex(this.wireResults);
        setTimeout(() => {
            this.saving = false;
        }, 500);
    }

    handleAdditionalDetailSuccess(event) {
        if(!this.accountNewId){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Additional Insurer Account is Required',
                    variant: 'error',
                }))
                return;
        }
        var fields = {};
        fields["Submission__c"] = this.oppId;
        fields["Additional_Insured_Account__c"] = this.accountNewId;
        const recordInput = { apiName: ACCOUNTINSURED_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then((result) => {
                const insuredAccount = result.id;
                this.saving = true;
                this.handleCancel();
                this.isLoading = false;
                refreshApex(this.additonalInsuredWiredResults);
                getSubmissionAdditionalInsuredDetails({ oppId: this.oppId })
                    .then(result => {
                        this.insuredData = result;
                        makeAllQuotedQuotesRated({ submissionId: this.oppId })
                            .then(result => {
                                console.log("Success");
                            })
                            .catch((error) => {
                                console.log("Error: " + JSON.stringify(error));
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: "Error",
                                        message: error.body.message,
                                        variant: "error"
                                    })
                                );
                            })
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Additional Insured Account is added successfully',
                                variant: 'success',
                            }),
                        )
                        console.log('responseardasd', JSON.stringify(result));
                        setTimeout(() => {
                        const event1 = new CustomEvent("handlewarningrefresh", {
                            detail: this.oppId
                        });
                        this.dispatchEvent(event1);
                      },500);
                    })
                setTimeout(() => {
                    this.saving = false;
                }, 500);

            })
            .catch((error) => {
                console.log("Error: " + JSON.stringify(error));
                this.isLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
    }
    handleEditSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record updated successfully with id: ' + event.detail.id,
                variant: 'success',
            }),
        )
        this.handleCancel();
        refreshApex(this.wireResults);
        this.isLoading = false;
    }
    handleAdditionalInsuredEditSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Additional Insured Account is added successfully',
                variant: 'success',
            }),
        )
        this.handleCancel();
        refreshApex(this.additonalInsuredWiredResults);
        this.isLoading = false;
    }
    handleCancel() {
        this.isnewAccountLoading = false;
        this.isShowCreateAccount = false;
        this.openModalCreateSubmissionLossDetail = false;
        this.modeCreatedSubmissionLossDetail = false;
        this.modeEditSubmissionLossDetail = false;
        this.openModalCreateAdditionalInsuredDetail = false;
        this.modeCreatedAdditionalInsuredDetail = false;
        this.modeEditAdditionalInsuredDetail = false;
    }
    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = event.detail.fields;
        console.log('@@@ fields', JSON.stringify(fields));
        this.template.querySelector('lightning-record-form').submit(fields);
    }
    handleOnLoad(event) {
        const detail = JSON.parse(JSON.stringify(event.detail))
        const record = detail.record;
        this.recordTypeId = record.recordTypeId;
        const fields = record.fields;
        fields.Quote__c = this.quoteId;
        console.log('fields:' + JSON.stringify(fields));
    }

    handleOpenCreateModal() {
        this.openModalCreateSubmissionLossDetail = true;
        this.modeCreatedSubmissionLossDetail = true;
    }

    @track lookupFilter;
    handleOpenAdditionalInsuredCreateModal() {
        this.lookupFilter = 'RecordType.Name = \'Business\'';
        this.openModalCreateAdditionalInsuredDetail = true;
        this.modeCreatedAdditionalInsuredDetail = true;
        this.accountNewId = '';
    }
    handleRowClick(evt) {
        this.selectedRowId = evt.detail;
        console.log('@@@handleRowClick', JSON.stringify(e.detail));

    }

    handleSelectedRecord(event) {
        this.accountNewId = null;
        const selectedRecordId = event.detail;
        this.accountNewId = selectedRecordId.selectedId;
        console.log('accountNewId ' + JSON.stringify(this.accountNewId));
    }

    handleDeleteRowSelected(event) {
        this.isLoading = true;
        var rowId = event.detail;
        console.log('@@@ handleDeleteRowSelected', rowId);
        deleteRecord(rowId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted',
                        variant: 'success'
                    })
                );
                this.isLoading = false;
                refreshApex(this.wireResults);
                const event1 = new CustomEvent("refreshsanctionwarningbanner", {
                });
                this.dispatchEvent(event1);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });

    }
    handleDeleteRowAdditionalInsuredSelected(event) {
        this.isLoading = true;
        var rowId = event.detail;
        console.log('@@@ handleDeleteRowSelected', rowId);
        console.log('delete-->', rowId);
        deleteRecord(rowId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted',
                        variant: 'success'
                    })
                );
                this.isLoading = false;
                refreshApex(this.additonalInsuredWiredResults);
                const event1 = new CustomEvent("refreshsanctionwarningbanner", {
                });
                this.dispatchEvent(event1);
                makeAllQuotedQuotesRated({ submissionId: this.oppId })
                            .then(result => {
                                console.log("Success");
                            })
                            .catch((error) => {
                                console.log("Error: " + JSON.stringify(error));
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: "Error",
                                        message: error.body.message,
                                        variant: "error"
                                    })
                                );
                            })
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });

    }
    handleUpdateRowSelected(event) {
        this.openModalCreateSubmissionLossDetail = true;
        this.modeEditSubmissionLossDetail = true;
        this.selectedRowId = event.detail;
        console.log('@@@ handleUpdateRowSelected', this.selectedRowId);
    }
    handleAdditionalInsuredUpdateRowSelected(event) {
        this.openModalCreateAdditionalInsuredDetail = true;
        this.modeEditAdditionalInsuredDetail = true;
        this.selectedRowId = event.detail;
        console.log('@@@ handleAdditionalInsuredUpdateRowSelected', this.selectedRowId);
    }

    @track openNotesAndFiles = false;
    @track isLoadingNotesAndFiles = false;
    @track dataNote = [];
    @track dataFile = [];
    @track fieldsNote = [
        {
            label: 'Id', fieldName: 'linkNoteTitle', type: 'url',
            typeAttributes: { label: { fieldName: 'id' }, target: '_blank' }
        },
        { label: 'Title', fieldName: 'title', type: 'text' },
    ];
    @track fieldsFile = [
        {
            label: 'Id', fieldName: 'linkFileTitle', type: 'url',
            typeAttributes: { label: { fieldName: 'id' }, target: '_blank' }
        },
        { label: 'Title', fieldName: 'title', type: 'text' },
    ];

    openNotesAndFilesModel() {
        this.openNotesAndFiles = true;
        this.isLoadingNotesAndFiles = true;
        getContentNotes({ submissionId: this.oppId }).then(
            data => {
                console.log("getContentNotes -> data", data)
                this.dataNote = data;
            }
        ).catch(err => console.log('getContentNotes', err));
        getContentDocuments({ submissionId: this.oppId }).then(
            data => {
                console.log("getContentDocuments -> data", data)
                this.dataFile = data;
            }
        ).catch(err => console.log('getContentDocuments', err));
    }
    handleCancelNotesAndFiles() {
        this.openNotesAndFiles = false;
        this.openModalCreateNote = false;
        this.openModalUploadFile = false;
    }

    @track openModalCreateNote = false;
    @track contentNote;
    @track titleNote;
    handleOpenCreateNote() {
        this.openModalCreateNote = true;
    }
    @track openModalUploadFile = false;
    get acceptedFormats() {
        return ['.pdf', '.pptx', '.xlsx'];
    }
    handleOpenUploadFile() {
        this.openModalUploadFile = true;
    }
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        console.log("No. of files uploaded : " + uploadedFiles.length);
        getContentDocuments({ submissionId: this.oppId }).then(
            data => {
                console.log("getContentDocuments -> data", data)
                this.dataFile = data;
            }
        ).catch(err => console.log('getContentDocuments', err));
    }

    renderedCallback() {
        const style = document.createElement('style');
        style.innerText = `
        .customLossDetailCss .slds-grid:last-child .slds-col:nth-last-child(1) .slds-form-element:nth-last-child(1) {
            width: 49%;
        }
        `;
        if (this.template.querySelector('div')) {
            this.template.querySelector('div').appendChild(style);
        }
     
    }
    handleCompactAction(event) {
        console.log('handleCompactAction', JSON.stringify(event.detail.actionType));
        console.log('Record type from event -->' + JSON.stringify(event.detail.oppRecordId));
        this.oppRecordId = event.detail.oppRecordId;
        this.declineOtherTextDisplay = false;
        this.declineOtherText = '';
        this.actionCompactType = event.detail.actionType
        this.handleOpenCloseModal();
    }
    handleOpenCloseModal() {
        this.isCloseCompactAction = true;
        console.log('this.isCloseCompactAction-->' + this.isCloseCompactAction);
        console.log('this.oppId' + this.oppId);
    }
    handleCloseOpportunityModal() {
        this.isCloseCompactAction = false;
        this.actionCompactType = null;
        this.closeReason = null;
    }
    handleChangeReason(event) {
        this.declineOtherTextDisplay = false;
        this.closeReason = event.detail.value;
        /***** CD-169 *****/
        if(this.closeReason == 'Other'){
            this.declineOtherTextDisplay = true;
        }
    }
     /***** CD-169 *****/
    handleDeclineReason(event){
      this.declineOtherText = event.detail.value;
    }
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$oppRecordId', fieldApiName: CLOSED_REASON_FIELD })
    ClosedReasonPicklistValues;

    handleConfirmCloseModal() {
        if (!this.closeReason) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Please select a Reason",
                    variant: "error"
                })
            );
            return;
        }
        /**** CD-169 */
        if(this.declineOtherTextDisplay && this.declineOtherText==''){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Please enter Other Reason for declining this submission",
                    variant: "error"
                })
            );
            return;
        }
          /**** CD-169 End*/

        this.isLoading = true;
        checkRelatedBoundQuotesPresent({ submissionId: this.oppId })
            .then(
                data => {
                    console.log("Response Data-->", data);
                    this.isLoading = false;
                    if (data) {
                        this.isCloseCompactAction = false;
                        this.showToast('Error', 'You cannot Decline / Close the Submission when Quote is Bound.', 'error', 'dismissable');
                    } else {
                        if (!this.closeReason) {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: "Error",
                                    message: "Please select a Reason",
                                    variant: "error"
                                })
                            );
                            return;
                        }
                        // Both the Close and Decline should populate the Close Date with today()
                        const today = new Date().toISOString().slice(0, 10);
                        console.log('CloseDate', today);

                        let fields = {
                            Id: this.oppId,
                            CloseDate: today,
                            Loss_Reason__c: this.closeReason,
                            Decline_Other_Reason__c: this.declineOtherText
                        };
                        // Both should force the user to enter a Close Reason
                        if (this.actionCompactType === 'decline') {
                            // When Decline is clicked the Stage is set to Declined and the Workflow Status to Closed
                            fields.StageName = 'Declined';
                            this.stageName = 'Declined';
                            //When Submission is declined changing the Submission_Status__c field to Declined as well
                            fields.Submission_Status__c = 'Declined';
                            updateRecord({ fields }).then(
                                result => {
                                    this.hideDeclineCloseBtn = true;
                                    this.handleCloseOpportunityModal();
                                    this.fetchData();
                                    this.getListSecSetting();
                                    this.refreshCompact();
                                    this.updateQuoteProcess();
                                    this.template.querySelector('c-custom-compact-lwc').getStageNameSubmission();
                                    updateAllQuoteStatusAndCloseReason({ oppId: this.oppId }).catch((error) => {
                                        console.log('Error' + JSON.stringify(error));
                                        var err = this.handleError(error);
                                        this.showToast('Update fail!', err, "error");
                                    })
                                    this.showToast('', 'Submission is successfully declined', 'success', 'dismissable');
                                }
                            ).catch(error => this.showToast('', error.body.message, 'error', 'dismissable'));

                        } else {
                            // When Close is clicked the Stage is set to Closed Lost and the Workflow Status to Closed
                            fields.StageName = 'Closed Lost';
                            this.stageName = 'Closed Lost';
                            updateRecord({ fields }).then(
                                result => {
                                    this.hideDeclineCloseBtn = true;
                                    this.handleCloseOpportunityModal();
                                    this.fetchData();
                                    this.getListSecSetting();
                                    this.updateQuoteProcess();
                                    this.refreshCompact();
                                    this.template.querySelector('c-custom-compact-lwc').getStageNameSubmission();
                                    updateAllQuoteStatusAndCloseReason({ oppId: this.oppId }).catch((error) => {
                                        console.log('Error' + JSON.stringify(error));
                                        var err = this.handleError(error);
                                        this.showToast('Update fail!', err, "error");
                                    })
                                    this.showToast('', 'Submission is successfully closed', 'success', 'dismissable');
                                }
                            ).catch(error => this.showToast('', error.body.message, 'error', 'dismissable'));
                        }
                    }
                }
            )
            .catch(err => {
                this.isLoading = false;
                this.showToast('Error', err, 'error', 'dismissable');
            }
            );
    }

    updateQuoteProcess() {
        let fields = {
            Id: this.recordId
        };
        updateRecord({ fields }).then(
            result => {
                this.fetchData();
                //this.getListSecSetting();
                this.refreshCompact();
                console.log('success' + result);
            }
        ).catch(error => this.showToast('', error.body.message, 'error', 'dismissable'));
    }

    handleUnDecline(event) {
        this.oppRecordId = event.detail.oppRecordId;
        console.log('oppId: ' + this.oppRecordId);
        unDeclineUpdateSubmission({ oppId: this.oppRecordId })//oppId
            .then((result) => {
                console.log('Undecline result ->' + JSON.stringify(result));
                if (result.isSuccess) {
                    let fields = {
                        Id: this.oppRecordId,
                        Decline_Other_Reason__c: null
                    };
                    updateRecord({ fields }).then(
                        result => {
                            this.fetchData();
                            this.updateQuoteProcess();
                            this.getListSecSetting();
                            this.refreshCompact();
                            this.template.querySelector('c-custom-compact-lwc').handleAfterUnDecline();
                            console.log('success' + result);
                        }
                    ).catch(error => this.showToast('', error.body.message, 'error', 'dismissable'));
                }
            })
            .catch((error) => {
                console.log('@@@error: ' + JSON.stringify(error));
                this.showToast('Error', JSON.stringify(error), 'error');
                this.isCloneSubmission = false;
            })
    }

    handleError(error) {
        return getErrors(error).join(', ');
    }

    refreshCompact() {
        const compact = this.template.querySelector('c-custom-compact-lwc');
        //console.log('refreshCompact',JSON.stringify(compact.stageName));
        //compact.readOnlyBtn();
    }

    get modalName() {
        return this.actionCompactType == 'decline' ? 'Decline' : 'Close';
    }
    updateQuoteStatusforAQ() {
        updateQuoteStatusForAQ({ sObjectId: this.recordId })
            .then(() => console.log('Success in Quote Update'))
            .error(error => console.log('@@error' + JSON.stringify(error)))
    }
}