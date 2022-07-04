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
        return this._models;
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
        const res = this._brands.find(e => e.value === this.brandValue)
        this._models = res.dependency;
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