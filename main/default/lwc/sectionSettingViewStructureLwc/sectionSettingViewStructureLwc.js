import { LightningElement, track, api, wire } from 'lwc';
import getSectionSettingStructure from '@salesforce/apex/SectionSettingViewStructureLwcController.getSectionSettingStructure';

export default class SectionSettingViewStructureLwc extends LightningElement {
    @api recordTypeName;
    @api componentName;
    @track data;

    @wire(getSectionSettingStructure, { recordTypeName: '$recordTypeName', componentName: '$componentName' })
    wiredGetRatModForRiskHealth({error, data}) {
        if(data){
            this.data = data;
            console.log('@@@data: ' + JSON.stringify(data));
        }else if(error){
            console.log('##error :' + JSON.stringify(error));
        }
    }
    closeModal(){
        this.dispatchEvent(new CustomEvent('closeviewstructure'));
    }
}