import { LightningElement,api,track,wire } from 'lwc';
import getPicklistValues from '@salesforce/apex/InsureAccountController.getPicklistValues';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import checkProfileIsAdmin  from '@salesforce/apex/SubmissionInfoLwcController.checkProfileIsAdmin';
export default class GenerateElementLwc extends LightningElement {

    @api objectName;
    @api isAqueous;
    //Added By Vinayesh for not repeating address label.
    //This check field is equivalent to saying product is PCC.
    @api showAddressLabelOnce;
    //@api recordTypeId;    
    recordTypeId_;// required in case you don't have the value it's must be set as blank value("")
    set recordTypeId(value) {
        this.recordTypeId_ = value;
        if(value == '' || this.recordTypeId == null) {
            if(this.isPicklist) {
                getPicklistValues({objectName: this.objectName, fieldName: this.fieldName, firstValue : null})
                .then(result => {
                    this.options = result;
                    if (this.selectedOption) {
                        let optionIsValid = this.options.some(function(item) {
                            return item.value === this.selectedOption;
                        }, this);
                        if (!optionIsValid) {
                            this.selectedOption = data.defaultValue;
                        }
                    } else {
                        this.selectedOption = data.defaultValue;
                    }
                })
                .catch(error => {
                    console.log(' connectedCallback error :' + JSON.stringify(error));
                });
            }
        }
    }
    @api filter = '';
    @api get recordTypeId() {
       return this.recordTypeId_;
    }
    @api objectLookupTo;
    @api fieldName;
    @api label;
    _fieldValue;
    @api readOnly;
    @api _required = false;
    @track inputClass = 'inputCmp';
    @api isChangeOnAccount;
    @track isKYCStatusField;
    @api isChangeOnSubmission;
    @track countryJsonState;
    @track address = {
        /*street: '121 Spear St.',
        city: 'San Francisco',
        province: 'CA',
        postalCode: '94105',
        country: 'US',*/
    };
    @track searchTermAcc;
    @api get fieldValue() {
        return this._fieldValue;
    }
    set fieldValue(value) {
        if(this.objectLookupTo && !value){
            this._fieldValue = null;
        } else  {
            this._fieldValue = value;
        }
        
        //console.log('this.this.fieldValue:' + this.fieldValue+ ' objectLookupTo='+this.objectLookupTo+ ' fieldName='+this.fieldName);
        this.address = {};
        if(this.isAddress) {
            //value":{"street":"123 New York 303","city":"Orangeburg","state":"New York",
            //"postalCode":"10962","country":"United States","stateCode":"NY","countryCode":"US"}
            //console.log('this.this.fieldValue:' + JSON.stringify(this.fieldValue));
            if(this.fieldValue) {
                if(this.fieldValue.street) {
                    this.address.street = this.fieldValue.street;
                }
                if(this.fieldValue.city) {
                    this.address.city = this.fieldValue.city;
                }
                if(this.fieldValue.postalCode) {
                    this.address.postalCode = this.fieldValue.postalCode;
                }
                if(this.fieldValue.country) {                 
                    this.address.country = this.fieldValue.countryCode;
                    this._country = this.fieldValue.countryCode;
                }
                if(this.fieldValue.state) {
                    this.address.province = this.fieldValue.stateCode;
                }
                this.addressInfo = this.address;  
                this.validateAddressFields();
            }
        }
        if(this.isMutliSelectPicklist && value) {
            var tmp = [];
            if(value.indexOf(';') != -1) {
                tmp = value.split(';');
            } else {
                tmp.push(value);
            }
            this._fieldValue = tmp;
            this.selectedMultiSelectPicklist = tmp;
            
        }
        this.isChangeOnAccount = false;
    }

    @api get required(){
        return this._required;
    }
    set required(value){
        if(value === true || value === false){
            this._required = value;
        }else{
            this._required = false;
        }
        if(value === true){
            this.inputClass += ' required-field';
        }
    }

    @api options;

    @api isText;
    @api isLongText;
    @api isPicklist;
    @api isMutliSelectPicklist;
    @api isAddress;
    @api isLookup;
    @api isDate;
    @api isDateTime;
    @api isNumber;
    @api isCheckbox;
    @api isCurrency;
    @api isPercent;
    @api createRecord;

    _format;
    set format(value) {
        this._format = value;
        if(this._format == 'Text') {
            this.isText = true;
        }
        if(this._format == 'Long Text') {
            this.isLongText = true;
        }
        if(this._format == 'Picklist') {
            this.isPicklist = true;
        }
        if(this._format == 'MultiSelectPicklist') {
            this.isMutliSelectPicklist = true;
        }
        if(this._format == 'Lookup') {
            this.isLookup = true;
        }
        if(this._format == 'Address') {
            this.isAddress = true;
        }
        if(this._format == 'Date') {
            this.isDate = true;
        }
        if(this._format == 'DateTime') {
            this.isDateTime = true;
        }
        
        if(this._format == 'Number') {
            this.isNumber = true;
        }
        //Added by Vinayesh
        if(this._format == 'Checkbox') {
            this.isCheckbox = true;
            this.inputClass += ' check-box';
        }
        if(this._format == 'Currency') {
            this.isCurrency = true;
        }
        if(this._format == 'Percent') {
            this.isPercent = true;
        }
    }

    @api get format() {
        return this._format;
    }

    @track _country   = '';
    @track addressInfo;

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
    
    @track countryOptions = [];

    get getProvinceOptions() {
            return this.countryProvinceMap[this._country];    
    }
    get getCountryOptions() {
        return this.countryOptions;
    }

    /*
    @wire(getCountryStateMap)
    wiredContacts({ error, data }) {
        console.log('tessssssssssssssssssssss:' + this.isAddress + ' label:' + this.label + ' this:' + this.fieldName);
        if (data) {
            console.log("@@@ data: " + JSON.stringify(data.data));
            this.countryOptions = [];
            for (let index = 0; index < data.data.length; index++) {
                const country = data.data[index];
                
                this.countryOptions.push({"label" : country.label, "value" : country.isoCode});
                const stateList = [];
                if(country.states != null && country.states.length > 0){
                    country.states.forEach(state => {
                        stateList.push({"label" : state.label, "value" : state.isoCode});
                    });
                }
                this.countryProvinceMap[country.isoCode] = stateList;
            }
            console.log('Country obtions:' + JSON.stringify(this.countryProvinceMap));
            //refreshApex(data);
        } else if (error) {
            console.log("@@@ error message: " + error);
        }
    }*/

    connectedCallback() {
        if(this.isPicklist){
            if(this.fieldName == 'KYC_Status__c' && this.isAqueous){
                this.isKYCStatusField = true;
                console.log("Inside KYC");
            }
        }
        if(this.isAddress) {
            var countryJson = [];
            if(this.isAqueous){
                countryJson = [
                    { "isoCode": "GG" ,"label": "Guernsey"},                                        
                    { "isoCode": "IM" ,"label": "Isle of Man"},                    
                    { "isoCode": "JE" ,"label": "Jersey"},
                    { "isoCode": "IE" , "label": "Northern Ireland"},
                    { "isoCode": "GB" , "label": "United Kingdom"},
                ];
            }else{
                countryJson = [{"isoCode":"AD","label":"Andorra"},{"isoCode":"AE","label":"United Arab Emirates"},{"isoCode":"AF","label":"Afghanistan"},{"isoCode":"AG","label":"Antigua and Barbuda"},{"isoCode":"AI","label":"Anguilla"},{"isoCode":"AL","label":"Albania"},{"isoCode":"AM","label":"Armenia"},{"isoCode":"AO","label":"Angola"},{"isoCode":"AQ","label":"Antarctica"},{"isoCode":"AR","label":"Argentina"},{"isoCode":"AT","label":"Austria"},{"isoCode":"AU","label":"Australia"},{"isoCode":"AW","label":"Aruba"},{"isoCode":"AX","label":"Aland Islands"},{"isoCode":"AZ","label":"Azerbaijan"},{"isoCode":"BA","label":"Bosnia and Herzegovina"},{"isoCode":"BB","label":"Barbados"},{"isoCode":"BD","label":"Bangladesh"},{"isoCode":"BE","label":"Belgium"},{"isoCode":"BF","label":"Burkina Faso"},{"isoCode":"BG","label":"Bulgaria"},{"isoCode":"BH","label":"Bahrain"},{"isoCode":"BI","label":"Burundi"},{"isoCode":"BJ","label":"Benin"},{"isoCode":"BL","label":"Saint Barthélemy"},{"isoCode":"BM","label":"Bermuda"},{"isoCode":"BN","label":"Brunei Darussalam"},{"isoCode":"BO","label":"Bolivia, Plurinational State of"},{"isoCode":"BQ","label":"Bonaire, Sint Eustatius and Saba"},{"isoCode":"BR","label":"Brazil"},{"isoCode":"BS","label":"Bahamas"},{"isoCode":"BT","label":"Bhutan"},{"isoCode":"BV","label":"Bouvet Island"},{"isoCode":"BW","label":"Botswana"},{"isoCode":"BY","label":"Belarus"},{"isoCode":"BZ","label":"Belize"},{"isoCode":"CA","label":"Canada"},{"isoCode":"CC","label":"Cocos (Keeling) Islands"},{"isoCode":"CD","label":"Congo, the Democratic Republic of the"},{"isoCode":"CF","label":"Central African Republic"},{"isoCode":"CG","label":"Congo"},{"isoCode":"CH","label":"Switzerland"},{"isoCode":"CI","label":"Cote d'Ivoire"},{"isoCode":"CK","label":"Cook Islands"},{"isoCode":"CL","label":"Chile"},{"isoCode":"CM","label":"Cameroon"},{"isoCode":"CN","label":"China"},{"isoCode":"CO","label":"Colombia"},{"isoCode":"CR","label":"Costa Rica"},{"isoCode":"CU","label":"Cuba"},{"isoCode":"CV","label":"Cape Verde"},{"isoCode":"CW","label":"Curaçao"},{"isoCode":"CX","label":"Christmas Island"},{"isoCode":"CY","label":"Cyprus"},{"isoCode":"CZ","label":"Czech Republic"},{"isoCode":"DE","label":"Germany"},{"isoCode":"DJ","label":"Djibouti"},{"isoCode":"DK","label":"Denmark"},{"isoCode":"DM","label":"Dominica"},{"isoCode":"DO","label":"Dominican Republic"},{"isoCode":"DZ","label":"Algeria"},{"isoCode":"EC","label":"Ecuador"},{"isoCode":"EE","label":"Estonia"},{"isoCode":"EG","label":"Egypt"},{"isoCode":"EH","label":"Western Sahara"},{"isoCode":"ER","label":"Eritrea"},{"isoCode":"ES","label":"Spain"},{"isoCode":"ET","label":"Ethiopia"},{"isoCode":"FI","label":"Finland"},{"isoCode":"FJ","label":"Fiji"},{"isoCode":"FK","label":"Falkland Islands (Malvinas)"},{"isoCode":"FO","label":"Faroe Islands"},{"isoCode":"FR","label":"France"},{"isoCode":"GA","label":"Gabon"},{"isoCode":"GB","label":"United Kingdom"},{"isoCode":"GD","label":"Grenada"},{"isoCode":"GE","label":"Georgia"},{"isoCode":"GF","label":"French Guiana"},{"isoCode":"GG","label":"Guernsey"},{"isoCode":"GH","label":"Ghana"},{"isoCode":"GI","label":"Gibraltar"},{"isoCode":"GL","label":"Greenland"},{"isoCode":"GM","label":"Gambia"},{"isoCode":"GN","label":"Guinea"},{"isoCode":"GP","label":"Guadeloupe"},{"isoCode":"GQ","label":"Equatorial Guinea"},{"isoCode":"GR","label":"Greece"},{"isoCode":"GS","label":"South Georgia and the South Sandwich Islands"},{"isoCode":"GT","label":"Guatemala"},{"isoCode":"GW","label":"Guinea-Bissau"},{"isoCode":"GY","label":"Guyana"},{"isoCode":"HM","label":"Heard Island and McDonald Islands"},{"isoCode":"HN","label":"Honduras"},{"isoCode":"HR","label":"Croatia"},{"isoCode":"HT","label":"Haiti"},{"isoCode":"HU","label":"Hungary"},{"isoCode":"ID","label":"Indonesia"},{"isoCode":"IE","label":"Ireland"},{"isoCode":"IL","label":"Israel"},{"isoCode":"IM","label":"Isle of Man"},{"isoCode":"IN","label":"India"},{"isoCode":"IO","label":"British Indian Ocean Territory"},{"isoCode":"IQ","label":"Iraq"},{"isoCode":"IR","label":"Iran, Islamic Republic of"},{"isoCode":"IS","label":"Iceland"},{"isoCode":"IT","label":"Italy"},{"isoCode":"JE","label":"Jersey"},{"isoCode":"JM","label":"Jamaica"},{"isoCode":"JO","label":"Jordan"},{"isoCode":"JP","label":"Japan"},{"isoCode":"KE","label":"Kenya"},{"isoCode":"KG","label":"Kyrgyzstan"},{"isoCode":"KH","label":"Cambodia"},{"isoCode":"KI","label":"Kiribati"},{"isoCode":"KM","label":"Comoros"},{"isoCode":"KN","label":"Saint Kitts and Nevis"},{"isoCode":"KP","label":"Korea, Democratic People's Republic of"},{"isoCode":"KR","label":"Korea, Republic of"},{"isoCode":"KW","label":"Kuwait"},{"isoCode":"KY","label":"Cayman Islands"},{"isoCode":"KZ","label":"Kazakhstan"},{"isoCode":"LA","label":"Lao People's Democratic Republic"},{"isoCode":"LB","label":"Lebanon"},{"isoCode":"LC","label":"Saint Lucia"},{"isoCode":"LI","label":"Liechtenstein"},{"isoCode":"LK","label":"Sri Lanka"},{"isoCode":"LR","label":"Liberia"},{"isoCode":"LS","label":"Lesotho"},{"isoCode":"LT","label":"Lithuania"},{"isoCode":"LU","label":"Luxembourg"},{"isoCode":"LV","label":"Latvia"},{"isoCode":"LY","label":"Libyan Arab Jamahiriya"},{"isoCode":"MA","label":"Morocco"},{"isoCode":"MC","label":"Monaco"},{"isoCode":"MD","label":"Moldova, Republic of"},{"isoCode":"ME","label":"Montenegro"},{"isoCode":"MF","label":"Saint Martin (French part)"},{"isoCode":"MG","label":"Madagascar"},{"isoCode":"MK","label":"Macedonia, the former Yugoslav Republic of"},{"isoCode":"ML","label":"Mali"},{"isoCode":"MM","label":"Myanmar"},{"isoCode":"MN","label":"Mongolia"},{"isoCode":"MO","label":"Macao"},{"isoCode":"MQ","label":"Martinique"},{"isoCode":"MR","label":"Mauritania"},{"isoCode":"MS","label":"Montserrat"},{"isoCode":"MT","label":"Malta"},{"isoCode":"MU","label":"Mauritius"},{"isoCode":"MV","label":"Maldives"},{"isoCode":"MW","label":"Malawi"},{"isoCode":"MX","label":"Mexico"},{"isoCode":"MY","label":"Malaysia"},{"isoCode":"MZ","label":"Mozambique"},{"isoCode":"NA","label":"Namibia"},{"isoCode":"NC","label":"New Caledonia"},{"isoCode":"NE","label":"Niger"},{"isoCode":"NF","label":"Norfolk Island"},{"isoCode":"NG","label":"Nigeria"},{"isoCode":"NI","label":"Nicaragua"},{"isoCode":"NL","label":"Netherlands"},{"isoCode":"NO","label":"Norway"},{"isoCode":"NP","label":"Nepal"},{"isoCode":"NR","label":"Nauru"},{"isoCode":"NU","label":"Niue"},{"isoCode":"NZ","label":"New Zealand"},{"isoCode":"OM","label":"Oman"},{"isoCode":"PA","label":"Panama"},{"isoCode":"PE","label":"Peru"},{"isoCode":"PF","label":"French Polynesia"},{"isoCode":"PG","label":"Papua New Guinea"},{"isoCode":"PH","label":"Philippines"},{"isoCode":"PK","label":"Pakistan"},{"isoCode":"PL","label":"Poland"},{"isoCode":"PM","label":"Saint Pierre and Miquelon"},{"isoCode":"PN","label":"Pitcairn"},{"isoCode":"PS","label":"Palestinian Territory, Occupied"},{"isoCode":"PT","label":"Portugal"},{"isoCode":"PY","label":"Paraguay"},{"isoCode":"QA","label":"Qatar"},{"isoCode":"RE","label":"Reunion"},{"isoCode":"RO","label":"Romania"},{"isoCode":"RS","label":"Serbia"},{"isoCode":"RU","label":"Russian Federation"},{"isoCode":"RW","label":"Rwanda"},{"isoCode":"SA","label":"Saudi Arabia"},{"isoCode":"SB","label":"Solomon Islands"},{"isoCode":"SC","label":"Seychelles"},{"isoCode":"SD","label":"Sudan"},{"isoCode":"SE","label":"Sweden"},{"isoCode":"SG","label":"Singapore"},{"isoCode":"SH","label":"Saint Helena, Ascension and Tristan da Cunha"},{"isoCode":"SI","label":"Slovenia"},{"isoCode":"SJ","label":"Svalbard and Jan Mayen"},{"isoCode":"SK","label":"Slovakia"},{"isoCode":"SL","label":"Sierra Leone"},{"isoCode":"SM","label":"San Marino"},{"isoCode":"SN","label":"Senegal"},{"isoCode":"SO","label":"Somalia"},{"isoCode":"SR","label":"Suriname"},{"isoCode":"SS","label":"South Sudan"},{"isoCode":"ST","label":"Sao Tome and Principe"},{"isoCode":"SV","label":"El Salvador"},{"isoCode":"SX","label":"Sint Maarten (Dutch part)"},{"isoCode":"SY","label":"Syrian Arab Republic"},{"isoCode":"SZ","label":"Swaziland"},{"isoCode":"TC","label":"Turks and Caicos Islands"},{"isoCode":"TD","label":"Chad"},{"isoCode":"TF","label":"French Southern Territories"},{"isoCode":"TG","label":"Togo"},{"isoCode":"TH","label":"Thailand"},{"isoCode":"TJ","label":"Tajikistan"},{"isoCode":"TK","label":"Tokelau"},{"isoCode":"TL","label":"Timor-Leste"},{"isoCode":"TM","label":"Turkmenistan"},{"isoCode":"TN","label":"Tunisia"},{"isoCode":"TO","label":"Tonga"},{"isoCode":"TR","label":"Turkey"},{"isoCode":"TT","label":"Trinidad and Tobago"},{"isoCode":"TV","label":"Tuvalu"},{"isoCode":"TW","label":"Chinese Taipei"},{"isoCode":"TZ","label":"Tanzania, United Republic of"},{"isoCode":"UA","label":"Ukraine"},{"isoCode":"UG","label":"Uganda"},{"isoCode":"US","label":"United States"},{"isoCode":"UY","label":"Uruguay"},{"isoCode":"UZ","label":"Uzbekistan"},{"isoCode":"VA","label":"Holy See (Vatican City State)"},{"isoCode":"VC","label":"Saint Vincent and the Grenadines"},{"isoCode":"VE","label":"Venezuela, Bolivarian Republic of"},{"isoCode":"VG","label":"Virgin Islands, British"},{"isoCode":"VN","label":"Viet Nam"},{"isoCode":"VU","label":"Vanuatu"},{"isoCode":"WF","label":"Wallis and Futuna"},{"isoCode":"WS","label":"Samoa"},{"isoCode":"YE","label":"Yemen"},{"isoCode":"YT","label":"Mayotte"},{"isoCode":"ZA","label":"South Africa"},{"isoCode":"ZM","label":"Zambia"},{"isoCode":"ZW","label":"Zimbabwe"}];
            }            
            var countryState = {"US":[{"label":"Alaska","value":"AK"},{"label":"Alabama","value":"AL"},{"label":"Arkansas","value":"AR"},{"label":"Arizona","value":"AZ"},{"label":"California","value":"CA"},{"label":"Colorado","value":"CO"},{"label":"Connecticut","value":"CT"},{"label":"District of Columbia","value":"DC"},{"label":"Delaware","value":"DE"},{"label":"Florida","value":"FL"},{"label":"Georgia","value":"GA"},{"label":"Hawaii","value":"HI"},{"label":"Iowa","value":"IA"},{"label":"Idaho","value":"ID"},{"label":"Illinois","value":"IL"},{"label":"Indiana","value":"IN"},{"label":"Kansas","value":"KS"},{"label":"Kentucky","value":"KY"},{"label":"Louisiana","value":"LA"},{"label":"Massachusetts","value":"MA"},{"label":"Maryland","value":"MD"},{"label":"Maine","value":"ME"},{"label":"Michigan","value":"MI"},{"label":"Minnesota","value":"MN"},{"label":"Missouri","value":"MO"},{"label":"Mississippi","value":"MS"},{"label":"Montana","value":"MT"},{"label":"North Carolina","value":"NC"},{"label":"North Dakota","value":"ND"},{"label":"Nebraska","value":"NE"},{"label":"New Hampshire","value":"NH"},{"label":"New Jersey","value":"NJ"},{"label":"New Mexico","value":"NM"},{"label":"Nevada","value":"NV"},{"label":"New York","value":"NY"},{"label":"Ohio","value":"OH"},{"label":"Oklahoma","value":"OK"},{"label":"Oregon","value":"OR"},{"label":"Pennsylvania","value":"PA"},{"label":"Puerto Rico","value":"PR"},{"label":"Palau","value":"PW"},{"label":"Rhode Island","value":"RI"},{"label":"South Carolina","value":"SC"},{"label":"South Dakota","value":"SD"},{"label":"Tennessee","value":"TN"},{"label":"Texas","value":"TX"},{"label":"Utah","value":"UT"},{"label":"Virginia","value":"VA"},{"label":"Vermont","value":"VT"},{"label":"Washington","value":"WA"},{"label":"Wisconsin","value":"WI"},{"label":"West Virginia","value":"WV"},{"label":"Wyoming","value":"WY"}],"CN":[{"label":"Beijing","value":"11"},{"label":"Tianjin","value":"12"},{"label":"Hebei","value":"13"},{"label":"Shanxi","value":"14"},{"label":"Nei Mongol","value":"15"},{"label":"Liaoning","value":"21"},{"label":"Jilin","value":"22"},{"label":"Heilongjiang","value":"23"},{"label":"Shanghai","value":"31"},{"label":"Jiangsu","value":"32"},{"label":"Zhejiang","value":"33"},{"label":"Anhui","value":"34"},{"label":"Fujian","value":"35"},{"label":"Jiangxi","value":"36"},{"label":"Shandong","value":"37"},{"label":"Henan","value":"41"},{"label":"Hubei","value":"42"},{"label":"Hunan","value":"43"},{"label":"Guangdong","value":"44"},{"label":"Guangxi","value":"45"},{"label":"Hainan","value":"46"},{"label":"Chongqing","value":"50"},{"label":"Sichuan","value":"51"},{"label":"Guizhou","value":"52"},{"label":"Yunnan","value":"53"},{"label":"Xizang","value":"54"},{"label":"Shaanxi","value":"61"},{"label":"Gansu","value":"62"},{"label":"Qinghai","value":"63"},{"label":"Ningxia","value":"64"},{"label":"Xinjiang","value":"65"},{"label":"Chinese Taipei","value":"71"},{"label":"Hong Kong","value":"91"},{"label":"Macao","value":"92"}],"AD":[],"AE":[],"AF":[],"AG":[],"AI":[],"AL":[],"AM":[],"AO":[],"AQ":[],"AR":[],"AT":[],"AU":[{"label":"Australian Capital Territory","value":"ACT"},{"label":"New South Wales","value":"NSW"},{"label":"Northern Territory","value":"NT"},{"label":"Queensland","value":"QLD"},{"label":"South Australia","value":"SA"},{"label":"Tasmania","value":"TAS"},{"label":"Victoria","value":"VIC"},{"label":"Western Australia","value":"WA"}],"AW":[],"AX":[],"AZ":[],"BA":[],"BB":[],"BD":[],"BE":[],"BF":[],"BG":[],"BH":[],"BI":[],"BJ":[],"BL":[],"BM":[],"BN":[],"BO":[],"BQ":[],"BR":[{"label":"Acre","value":"AC"},{"label":"Alagoas","value":"AL"},{"label":"Amazonas","value":"AM"},{"label":"Amapá","value":"AP"},{"label":"Bahia","value":"BA"},{"label":"Ceará","value":"CE"},{"label":"Distrito Federal","value":"DF"},{"label":"Espírito Santo","value":"ES"},{"label":"Goiás","value":"GO"},{"label":"Maranhão","value":"MA"},{"label":"Minas Gerais","value":"MG"},{"label":"Mato Grosso do Sul","value":"MS"},{"label":"Mato Grosso","value":"MT"},{"label":"Pará","value":"PA"},{"label":"Paraíba","value":"PB"},{"label":"Pernambuco","value":"PE"},{"label":"Piauí","value":"PI"},{"label":"Paraná","value":"PR"},{"label":"Rio de Janeiro","value":"RJ"},{"label":"Rio Grande do Norte","value":"RN"},{"label":"Rondônia","value":"RO"},{"label":"Roraima","value":"RR"},{"label":"Rio Grande do Sul","value":"RS"},{"label":"Santa Catarina","value":"SC"},{"label":"Sergipe","value":"SE"},{"label":"São Paulo","value":"SP"},{"label":"Tocantins","value":"TO"}],"BS":[],"BT":[],"BV":[],"BW":[],"BY":[],"BZ":[],"CA":[{"label":"Alberta","value":"AB"},{"label":"British Columbia","value":"BC"},{"label":"Manitoba","value":"MB"},{"label":"New Brunswick","value":"NB"},{"label":"Newfoundland and Labrador","value":"NL"},{"label":"Nova Scotia","value":"NS"},{"label":"Northwest Territories","value":"NT"},{"label":"Nunavut","value":"NU"},{"label":"Ontario","value":"ON"},{"label":"Prince Edward Island","value":"PE"},{"label":"Quebec","value":"QC"},{"label":"Saskatchewan","value":"SK"},{"label":"Yukon Territories","value":"YT"}],"CC":[],"CD":[],"CF":[],"CG":[],"CH":[],"CI":[],"CK":[],"CL":[],"CM":[],"CO":[],"CR":[],"CU":[],"CV":[],"CW":[],"CX":[],"CY":[],"CZ":[],"DE":[],"DJ":[],"DK":[],"DM":[],"DO":[],"DZ":[],"EC":[],"EE":[],"EG":[],"EH":[],"ER":[],"ES":[],"ET":[],"FI":[],"FJ":[],"FK":[],"FO":[],"FR":[],"GA":[],"GB":[{"label":"England","value":"ENGLAND"}],"GD":[],"GE":[],"GF":[],"GG":[],"GH":[],"GI":[],"GL":[],"GM":[],"GN":[],"GP":[],"GQ":[],"GR":[],"GS":[],"GT":[],"GW":[],"GY":[],"HM":[],"HN":[],"HR":[],"HT":[],"HU":[],"ID":[],"IE":[{"label":"Clare","value":"CE"},{"label":"Cavan","value":"CN"},{"label":"Cork","value":"CO"},{"label":"Carlow","value":"CW"},{"label":"Dublin","value":"D"},{"label":"Donegal","value":"DL"},{"label":"Galway","value":"G"},{"label":"Kildare","value":"KE"},{"label":"Kilkenny","value":"KK"},{"label":"Kerry","value":"KY"},{"label":"Longford","value":"LD"},{"label":"Louth","value":"LH"},{"label":"Limerick","value":"LK"},{"label":"Leitrim","value":"LM"},{"label":"Laois","value":"LS"},{"label":"Meath","value":"MH"},{"label":"Monaghan","value":"MN"},{"label":"Mayo","value":"MO"},{"label":"Offaly","value":"OY"},{"label":"Roscommon","value":"RN"},{"label":"Sligo","value":"SO"},{"label":"Tipperary","value":"TA"},{"label":"Waterford","value":"WD"},{"label":"Westmeath","value":"WH"},{"label":"Wicklow","value":"WW"},{"label":"Wexford","value":"WX"}],"IL":[],"IM":[],"IN":[{"label":"Andaman and Nicobar Islands","value":"AN"},{"label":"Andhra Pradesh","value":"AP"},{"label":"Arunachal Pradesh","value":"AR"},{"label":"Assam","value":"AS"},{"label":"Bihar","value":"BR"},{"label":"Chandigarh","value":"CH"},{"label":"Chhattisgarh","value":"CT"},{"label":"Daman and Diu","value":"DD"},{"label":"Delhi","value":"DL"},{"label":"Dadra and Nagar Haveli","value":"DN"},{"label":"Goa","value":"GA"},{"label":"Gujarat","value":"GJ"},{"label":"Himachal Pradesh","value":"HP"},{"label":"Haryana","value":"HR"},{"label":"Jharkhand","value":"JH"},{"label":"Jammu and Kashmir","value":"JK"},{"label":"Karnataka","value":"KA"},{"label":"Kerala","value":"KL"},{"label":"Lakshadweep","value":"LD"},{"label":"Maharashtra","value":"MH"},{"label":"Meghalaya","value":"ML"},{"label":"Manipur","value":"MN"},{"label":"Madhya Pradesh","value":"MP"},{"label":"Mizoram","value":"MZ"},{"label":"Nagaland","value":"NL"},{"label":"Odisha","value":"OR"},{"label":"Punjab","value":"PB"},{"label":"Puducherry","value":"PY"},{"label":"Rajasthan","value":"RJ"},{"label":"Sikkim","value":"SK"},{"label":"Tamil Nadu","value":"TN"},{"label":"Tripura","value":"TR"},{"label":"Uttar Pradesh","value":"UP"},{"label":"Uttarakhand","value":"UT"},{"label":"West Bengal","value":"WB"}],"IO":[],"IQ":[],"IR":[],"IS":[],"IT":[{"label":"Agrigento","value":"AG"},{"label":"Alessandria","value":"AL"},{"label":"Ancona","value":"AN"},{"label":"Aosta","value":"AO"},{"label":"Ascoli Piceno","value":"AP"},{"label":"L'Aquila","value":"AQ"},{"label":"Arezzo","value":"AR"},{"label":"Asti","value":"AT"},{"label":"Avellino","value":"AV"},{"label":"Bari","value":"BA"},{"label":"Bergamo","value":"BG"},{"label":"Biella","value":"BI"},{"label":"Belluno","value":"BL"},{"label":"Benevento","value":"BN"},{"label":"Bologna","value":"BO"},{"label":"Brindisi","value":"BR"},{"label":"Brescia","value":"BS"},{"label":"Barletta-Andria-Trani","value":"BT"},{"label":"Bolzano","value":"BZ"},{"label":"Cagliari","value":"CA"},{"label":"Campobasso","value":"CB"},{"label":"Caserta","value":"CE"},{"label":"Chieti","value":"CH"},{"label":"Carbonia-Iglesias","value":"CI"},{"label":"Caltanissetta","value":"CL"},{"label":"Cuneo","value":"CN"},{"label":"Como","value":"CO"},{"label":"Cremona","value":"CR"},{"label":"Cosenza","value":"CS"},{"label":"Catania","value":"CT"},{"label":"Catanzaro","value":"CZ"},{"label":"Enna","value":"EN"},{"label":"Forlì-Cesena","value":"FC"},{"label":"Ferrara","value":"FE"},{"label":"Foggia","value":"FG"},{"label":"Florence","value":"FI"},{"label":"Fermo","value":"FM"},{"label":"Frosinone","value":"FR"},{"label":"Genoa","value":"GE"},{"label":"Gorizia","value":"GO"},{"label":"Grosseto","value":"GR"},{"label":"Imperia","value":"IM"},{"label":"Isernia","value":"IS"},{"label":"Crotone","value":"KR"},{"label":"Lecco","value":"LC"},{"label":"Lecce","value":"LE"},{"label":"Livorno","value":"LI"},{"label":"Lodi","value":"LO"},{"label":"Latina","value":"LT"},{"label":"Lucca","value":"LU"},{"label":"Monza and Brianza","value":"MB"},{"label":"Macerata","value":"MC"},{"label":"Messina","value":"ME"},{"label":"Milan","value":"MI"},{"label":"Mantua","value":"MN"},{"label":"Modena","value":"MO"},{"label":"Massa and Carrara","value":"MS"},{"label":"Matera","value":"MT"},{"label":"Naples","value":"NA"},{"label":"Novara","value":"NO"},{"label":"Nuoro","value":"NU"},{"label":"Ogliastra","value":"OG"},{"label":"Oristano","value":"OR"},{"label":"Olbia-Tempio","value":"OT"},{"label":"Palermo","value":"PA"},{"label":"Piacenza","value":"PC"},{"label":"Padua","value":"PD"},{"label":"Pescara","value":"PE"},{"label":"Perugia","value":"PG"},{"label":"Pisa","value":"PI"},{"label":"Pordenone","value":"PN"},{"label":"Prato","value":"PO"},{"label":"Parma","value":"PR"},{"label":"Pistoia","value":"PT"},{"label":"Pesaro and Urbino","value":"PU"},{"label":"Pavia","value":"PV"},{"label":"Potenza","value":"PZ"},{"label":"Ravenna","value":"RA"},{"label":"Reggio Calabria","value":"RC"},{"label":"Reggio Emilia","value":"RE"},{"label":"Ragusa","value":"RG"},{"label":"Rieti","value":"RI"},{"label":"Rome","value":"RM"},{"label":"Rimini","value":"RN"},{"label":"Rovigo","value":"RO"},{"label":"Salerno","value":"SA"},{"label":"Siena","value":"SI"},{"label":"Sondrio","value":"SO"},{"label":"La Spezia","value":"SP"},{"label":"Syracuse","value":"SR"},{"label":"Sassari","value":"SS"},{"label":"Savona","value":"SV"},{"label":"Taranto","value":"TA"},{"label":"Teramo","value":"TE"},{"label":"Trento","value":"TN"},{"label":"Turin","value":"TO"},{"label":"Trapani","value":"TP"},{"label":"Terni","value":"TR"},{"label":"Trieste","value":"TS"},{"label":"Treviso","value":"TV"},{"label":"Udine","value":"UD"},{"label":"Varese","value":"VA"},{"label":"Verbano-Cusio-Ossola","value":"VB"},{"label":"Vercelli","value":"VC"},{"label":"Venice","value":"VE"},{"label":"Vicenza","value":"VI"},{"label":"Verona","value":"VR"},{"label":"Medio Campidano","value":"VS"},{"label":"Viterbo","value":"VT"},{"label":"Vibo Valentia","value":"VV"}],"JE":[],"JM":[],"JO":[],"JP":[],"KE":[],"KG":[],"KH":[],"KI":[],"KM":[],"KN":[],"KP":[],"KR":[],"KW":[],"KY":[],"KZ":[],"LA":[],"LB":[],"LC":[],"LI":[],"LK":[],"LR":[],"LS":[],"LT":[],"LU":[],"LV":[],"LY":[],"MA":[],"MC":[],"MD":[],"ME":[],"MF":[],"MG":[],"MK":[],"ML":[],"MM":[],"MN":[],"MO":[],"MQ":[],"MR":[],"MS":[],"MT":[],"MU":[],"MV":[],"MW":[],"MX":[{"label":"Aguascalientes","value":"AG"},{"label":"Baja California","value":"BC"},{"label":"Baja California Sur","value":"BS"},{"label":"Chihuahua","value":"CH"},{"label":"Colima","value":"CL"},{"label":"Campeche","value":"CM"},{"label":"Coahuila","value":"CO"},{"label":"Chiapas","value":"CS"},{"label":"Federal District","value":"DF"},{"label":"Durango","value":"DG"},{"label":"Guerrero","value":"GR"},{"label":"Guanajuato","value":"GT"},{"label":"Hidalgo","value":"HG"},{"label":"Jalisco","value":"JA"},{"label":"Mexico State","value":"ME"},{"label":"Michoacán","value":"MI"},{"label":"Morelos","value":"MO"},{"label":"Nayarit","value":"NA"},{"label":"Nuevo León","value":"NL"},{"label":"Oaxaca","value":"OA"},{"label":"Puebla","value":"PB"},{"label":"Querétaro","value":"QE"},{"label":"Quintana Roo","value":"QR"},{"label":"Sinaloa","value":"SI"},{"label":"San Luis Potosí","value":"SL"},{"label":"Sonora","value":"SO"},{"label":"Tabasco","value":"TB"},{"label":"Tlaxcala","value":"TL"},{"label":"Tamaulipas","value":"TM"},{"label":"Veracruz","value":"VE"},{"label":"Yucatán","value":"YU"},{"label":"Zacatecas","value":"ZA"}],"MY":[],"MZ":[],"NA":[],"NC":[],"NE":[],"NF":[],"NG":[],"NI":[],"NL":[],"NO":[],"NP":[],"NR":[],"NU":[],"NZ":[],"OM":[],"PA":[],"PE":[],"PF":[],"PG":[],"PH":[],"PK":[],"PL":[],"PM":[],"PN":[],"PS":[],"PT":[],"PY":[],"QA":[],"RE":[],"RO":[],"RS":[],"RU":[],"RW":[],"SA":[],"SB":[],"SC":[],"SD":[],"SE":[],"SG":[],"SH":[],"SI":[],"SJ":[],"SK":[],"SL":[],"SM":[],"SN":[],"SO":[],"SR":[],"SS":[],"ST":[],"SV":[],"SX":[],"SY":[],"SZ":[],"TC":[],"TD":[],"TF":[],"TG":[],"TH":[],"TJ":[],"TK":[],"TL":[],"TM":[],"TN":[],"TO":[],"TR":[],"TT":[],"TV":[],"TW":[],"TZ":[],"UA":[],"UG":[],"UY":[],"UZ":[],"VA":[],"VC":[],"VE":[],"VG":[],"VN":[],"VU":[],"WF":[],"WS":[],"YE":[],"YT":[],"ZA":[],"ZM":[],"ZW":[]}
            for (let index = 0; index < countryJson.length; index++) {
                const country = countryJson[index];
                this.countryOptions.push({"label" : country.label, "value" : country.isoCode});
                const stateList = countryState[country.isoCode];
                this.countryProvinceMap[country.isoCode] = stateList;
            }

            //Set default country to US for PCC
            if(this.showAddressLabelOnce && !this.address.country){
                this.address.country = 'US';
                this._country = 'US';
            }
        }

        /*
        readJSON()
            .then(result => {
                this.countryJsonState = JSON.parse(result);
                console.log(this.countryJsonState);
                    this.countryOptions = [];
                    for (let index = 0; index < this.countryJsonState.length; index++) {
                        let item = JSON.parse(JSON.stringify(this.countryJsonState));
                        let country = item[index];
                        
                        this.countryOptions.push({"label" : country.label, "value" : country.isoCode});

                        const stateList = item[index].state;
                        this.countryProvinceMap[country.isoCode] = stateList;
                    }
            })
            .catch(error => {
                console.log('7777777777:' + JSON.stringify(error));
            });
        */

    }

    renderedCallback() {
        console.log("address label check " + this.showAddressLabelOnce);
         //Set default country to US for PCC
         if(this.showAddressLabelOnce && !this.address.country){
            this.address.country = 'US';
            this._country = 'US';
        }
        if(this.showAddressLabelOnce && this.isAddress){
            const address = this.template.querySelector('lightning-input-address');
            address.setAttribute('autocomplete','off')
            if(address.province) {
                address.setCustomValidityForField('','province');
                address.reportValidity(); 
                
            }          
        }
        if(this.fieldName == 'Effective_Date__c'){
            var inputCmp = this.template.querySelector(".inputCmp");
            if(inputCmp.name == 'Effective_Date__c'){
               if(inputCmp.value){
                    inputCmp.setCustomValidity("");
                    inputCmp.reportValidity();
               }
            }
        }

        if(!this.isAqueous && this.objectName == 'Opportunity' && this.fieldName == 'StageName'){
            if(this.options){
                let tempOptions = JSON.parse(JSON.stringify(this.options));
                let currValue = this.fieldValue;
                let hasValue = false;
                this.options.forEach(stage => {
                    if(stage.value == currValue){
                        hasValue = true;
                    }
                });
                if(!hasValue){
                    tempOptions.push({label: this.fieldValue, value: this.fieldValue});
                    this.options = tempOptions;
                }              
            }           
        } 
    }
    get getProvinceOptions() {
        return this.countryProvinceMap[this._country];
    }
    /*
    get getCountryOptions() {
        return this.countryOptions;
    }*/

    handleChange(event) {
        this._country = event.detail.country;
        this.addressInfo = event.detail;
        console.log('handleChangeInput:' + this.objectName);
        // added by Jai on 11-Nov-2021 for User Story - 52958---code start----
        let selectedId = this.addressInfo.province ? this.addressInfo.province : '';
        let fieldNameAPI = 'Insured State';
        const event1 = new CustomEvent('handlelookupchildselection', {
            detail: { selectedId, fieldNameAPI },
        });
        this.dispatchEvent(event1);
        // added by Jai on 11-Nov-2021 for User Story - 52958---code end----
        //console.log('event detail:' + JSON.stringify(event.detail));
        if(this.objectName == 'Account') {this.isChangeOnAccount = true;}
        if(this.objectName == 'Opportunity') {this.isChangeOnSubmission = true;}
        if(this.showAddressLabelOnce && this.isAddress){
            const address = this.template.querySelector('lightning-input-address');
            if(address.province) {
                address.setCustomValidityForField('','province');
                address.reportValidity(); 
            }          
        }
        
    }
    handleSelection(event) {
        console.log('222222222222222222222:' + event.detail.selectedId);
        console.log('@@@event field Name:' + event.detail.fieldNameAPI);
        let selectedId = event.detail.selectedId;
        let fieldNameAPI = event.detail.fieldNameAPI;
        this.isChangeOnSubmission = true;
        //Added by Vinayesh
        if(this.showAddressLabelOnce){
            console.log('@@@event field Name:' + this.fieldName);
            fieldNameAPI = this.fieldName;
        }
        const event1 = new CustomEvent('handlelookupchildselection', {
            detail: { selectedId, fieldNameAPI },
        });
        // const event1 = new CustomEvent('handlelookupchildselection', {
        //     detail: event.detail.selectedId,
        //     fieldName : event.detail.fieldNameAPI
        // });
        // Fire the event from c-tile
        this.dispatchEvent(event1);
    }

    handleChangeInput(event) {
        this.value = event.target.value;
        console.log('handleChangeInput:' + this.objectName);
        if(this.objectName == 'Account') {this.isChangeOnAccount = true;}
        if(this.objectName == 'Opportunity') {this.isChangeOnSubmission = true;}
    }

    selectedMultiSelectPicklist = [];
    handleChangeMultiSelectPicklist(e) {
        this.selectedMultiSelectPicklist = e.detail.value;
    }

    @api checkValidity() {     
        if(this.label == 'Account Name' || this.fieldName == 'Broker_Contact__c') {
            this.template.querySelectorAll('c-look-up-lwc').forEach(element => {
                element.checkValidity();
            });
        }
        if(this.fieldName == 'Effective_Date__c'){
            var inputCmp = this.template.querySelector(".inputCmp");
            if(inputCmp.name == 'Effective_Date__c'){
               if(!inputCmp.value){
                   inputCmp.reportValidity();
               }
            }
        }

        if(this.showAddressLabelOnce && this.isAddress){
            const address = this.template.querySelector('lightning-input-address');
            if(!address.province) {
                address.setCustomValidityForField('Please enter value.','province');
                address.reportValidity(); 
            }          
        }
    }

    @api getValuesOnForm() {
        var inputCmp = this.template.querySelector(".inputCmp");
        var infos = {objectName : '', key : '', value: '', type : ''};

        if(inputCmp) {
            var value = inputCmp.value;
            infos = {objectName : this.objectName, key : inputCmp.name, value: value, type : 'textfield'};
            return infos;
        }
        var chkCmp = this.template.querySelector(".chkBox");
        if(chkCmp) {
            var value = chkCmp.checked;
            infos = {objectName : this.objectName, key : chkCmp.name, value: value, type : 'checkbox'};
            return infos;
        }   
        var addressCmp = this.template.querySelector(".addressCmp");
        //console.log('Not change :' + JSON.stringify(this.addressInfo));
        if(addressCmp) {
            console.log('Not change :' + JSON.stringify(addressCmp));
            infos = {objectName : this.objectName, key : addressCmp.name, value: this.addressInfo, type : 'address'};
            return infos;
        }
        var lookUpCmp = this.template.querySelector('c-look-up-lwc');
        if(lookUpCmp) {
            infos = lookUpCmp.getSelectedIdReturned();
            if(this.showAddressLabelOnce){
                infos = {objectName : this.objectName, key : infos.key, value: infos.value, Name: infos.Name, type : infos.type};
            }
            return infos;
        }
        var multiSelectCmp = this.template.querySelector(".multiSelectCmp");
        if(multiSelectCmp) {
            var result = '';
            if(this.selectedMultiSelectPicklist) {
                this.selectedMultiSelectPicklist.forEach(item => {
                    result += item + ';'
                });
            }
            if(result) {
                result = result.substr(0, result.length - 1);
            }
            infos = {objectName : this.objectName, key : multiSelectCmp.name, value: result, type : 'multiselect'};
            return infos;
        }
        return null;
      }

    @api resetValuesOnForm() {
        var inputCmp = this.template.querySelector(".inputCmp");
        if(inputCmp) {
            inputCmp.value = null;
        }
        var addressCmp = this.template.querySelector(".addressCmp");
        if(addressCmp) {
            addressCmp.value = null;
        }
        var lookupCmp = this.template.querySelector('c-lookup');
        if(lookupCmp) lookupCmp.resetSelectedIdReturned();
    }
      
    @api checkChangesOnAccount() {  
        console.log('checkChangesOnAccount==>',this.isChangeOnAccount);      
        return this.isChangeOnAccount;
    }

    @api checkChangesOnSubmission() {        
        return this.isChangeOnSubmission;
    }

    handleSelectedAddress(event) {
        const e = new Event("change");
        const element = this.template.querySelector('.addressCmp')
        console.log('element-->'+element);
       // element.dispatchEvent(e);
        
        console.log('Address-->'+JSON.stringify(event.detail));
        if(event.detail){
            this.isChangeOnAccount = true;
            var tmp = {};
            tmp.county = '';
            if(event.detail.county){
                tmp.county = event.detail.county;
            }
            this.address.street = '';
            console.log('isChangeOnAccount==>',this.isChangeOnAccount);
            if(event.detail.address) {
                this.address.street = event.detail.address;
                tmp.street = event.detail.address;
            }
            this.address.city = '';
            if(event.detail.city) {
                this.address.city = event.detail.city;
                tmp.city = event.detail.city;
              
            }
            this.address.postalCode = '';
            if(event.detail.postalCode) {
                this.address.postalCode = event.detail.postalCode;
                tmp.postalCode = event.detail.postalCode;
            }
            this.address.country = '';
            if(event.detail.countryCode) {
                this.address.country =  event.detail.countryCode;
                tmp.country = event.detail.countryCode;
                this._country = event.detail.countryCode;
            }
            // added by Jai on 22-Nov-2021 for User Story - 52958---code start----
            let selectedId = event.detail.stateCode ? event.detail.stateCode : '';
            let fieldNameAPI = 'Insured State';
            const event1 = new CustomEvent('handlelookupchildselection', {
                detail: { selectedId, fieldNameAPI },
            });
            this.dispatchEvent(event1);
            // added by Jai on 22-Nov-2021 for User Story - 52958---code end----     
            setTimeout(()=>{
                this.address.province = '';
                if(event.detail.stateCode) {
                    let filteredProvince = this.countryProvinceMap[this._country].filter(province=>province.value==event.detail.stateCode.toUpperCase());
                    if(filteredProvince.length > 0){
                        this.address.province = event.detail.stateCode.toUpperCase();
                        tmp.province = event.detail.stateCode.toUpperCase();
                    }                  
                }
                this.addressInfo = tmp;
            },0,this);
            this.validateAddressFields();
        }
    }
    handleSearchTermAccount(event){
        this.searchTermAcc = event.detail.searchTerm;
        console.log('this.searchTermAcc '+ JSON.stringify(this.searchTermAcc));
        
    }
    validateAddressFields(){
        if(!this.showAddressLabelOnce){
            setTimeout(()=>{
                const address = this.template.querySelector('lightning-input-address');   
                address.province.setCustomValidity("");
                address.reportValidity();
                },0,this);
        }     
    }

    @api validateRequiredField(event){
        var result = true;
        this.template.querySelectorAll('.required-field').forEach(element => {
            // console.log("@@@element value: " + JSON.stringify(element.value));
            var value = element.value;
            if (!value || value == undefined || value === "") {
                element.setCustomValidity("Complete this field.");
                result = false;
            }
            else{
                element.setCustomValidity("");
            }
            element.reportValidity(); 
        });
        return result;
    }
    
   
    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$objectName',
        recordTypeId: '$recordTypeId'
    })
    wiredValues({ error, data }) {
        if (data) {
            var picklistValues = data.picklistFieldValues;
            //console.log('data.picklistFieldValues MS:' + JSON.stringify(picklistValues));
            Object.keys(picklistValues).forEach((picklist) => {
                if(this.fieldName.localeCompare(picklist) == 0) {
                    this.options = picklistValues[picklist].values.map((item) => ({
                        label: item.label,
                        value: item.value
                    }));
                } 
            });
            if(this.objectName == 'Opportunity' && this.fieldName == 'Submission_Status__c'){
                console.log('this.objectName ',this.objectName, 'this.fieldName ',this.fieldName);
                checkProfileIsAdmin().then(data => {
                    if(!data) this.options = this.options.filter(Status => Status.label != 'Declined');
                }) 
            }          
            if (this.selectedOption) {
                let optionIsValid = this.options.some(function(item) {
                    return item.value === this.selectedOption;
                }, this);
                if (!optionIsValid) {
                    this.selectedOption = data.defaultValue;
                }
            } else {
                this.selectedOption = data.defaultValue;
            }

        } else {
            
            console.log('get error :' + error);
        }
    }
}