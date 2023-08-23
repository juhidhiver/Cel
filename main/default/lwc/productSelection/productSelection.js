import { LightningElement,wire } from 'lwc';
import getProductsForSelection from '@salesforce/apex/productSelectionController.getProductsForSelection';
export default class ProductSelection extends LightningElement {
    //Store all Product details
    prodList =[]
    @wire(getProductsForSelection)
    prodListFunc({data,error}){
        if(data){
            console.log('Data',data)
            this.prodList = data
        }
        if(error){
            console.error('Metadata extract error',error)
        }
    }
}