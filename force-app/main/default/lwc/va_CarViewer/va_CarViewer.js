import { LightningElement } from 'lwc';
import compareDependentPicklistvalues from "@salesforce/apex/AV_CarsController.compareDependentPicklistvalues";

export default class Va_CarViewer extends LightningElement {
    brandValue;
    modelValue;
     _brands = [];
     _models = [];

    //=====================GETTERS========================================
    get brands(){
        return this._brands;
    }
    get models(){
        return _models;
    }
    //====================================================================

    //=====================Callback=======================================
    async connectedCallback(){
        await this.getBrandsInfo();
    }
    //====================================================================

    //====================FUNCTIONS=======================================
    async getBrandsInfo(){
        this._brands = await compareDependentPicklistvalues();
        console.log('this._brands:', this._brands);
    }
    getModelInfo(){
        
    }
    //====================================================================

    //========================HANDLERS====================================
    handleBrandChange(event) {
        this.brandValue = event.detail.value;
        console.log('this.brandValue:', this.brandValue);
    }
    handleModelChange(event) {
        this.modelValue = event.detail.value;
    }
    //====================================================================
}