import { LightningElement, wire} from 'lwc';

import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import compareDependentPicklistvalues from "@salesforce/apex/AV_CarsController.compareDependentPicklistvalues";
import Car from "@salesforce/schema/Car__c";

export default class Va_CarViewer extends LightningElement {
    brandValue;
    modelValue;
     _brands = [];
     _models = [];

	@wire(getObjectInfo, { objectApiName: Car })
	carObject({error, data}){
        if(data){
            console.log('OBJECT: ', data);
        }else{
            console.log('ERROR OBJECT: ',error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: 'Car__c.Model__c' })
    propertyOrFunction({error, data}){
        if(data){
            console.log('FIELDS: ', data);
        }else{
            console.log('ERROR FIELDS: ',error);
        }
    }

    
    //=====================GETTERS========================================
    get brands(){
        return this._brands;
    }
    get models(){
        return this._models;
    }
    get isModels() {
        return Array.isArray(this._models);
    }

    //====================================================================

    //=====================Callback=======================================
    async connectedCallback(){
        await this.getBrandsInfo();
    }
    errorCallback(error, stack) {
        console.error("Va_CarViewer: errorCallback", error, stack);
    }
    //====================================================================

    //====================FUNCTIONS=======================================
    async getBrandsInfo(){
        try{
            this._brands = await compareDependentPicklistvalues();
        } catch(err){
            console.error('ERROR | Va_CarViewer', err);
        }
    }
    getModelInfo(){
        const mod = this._brands.find(e => e.value === this.brandValue);
        this._models = mod.dependency;
    }
    //====================================================================

    //========================HANDLERS====================================
    handleBrandChange(event) {
        this.brandValue = event.detail.value;
        this.getModelInfo();
        }
    handleModelChange(event) {
        this.modelValue = event.detail.value;
    }
    //====================================================================
}