import { LightningElement } from 'lwc';
import compareDependentPicklistvalues from "@salesforce/apex/AV_CarsController.compareDependentPicklistvalues";

export default class Va_CarViewer extends LightningElement {
    brandValue = "Audi";
    modelValue = "A-3";
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
        await this.getModelInfo();
    }
    //====================================================================

    //====================FUNCTIONS=======================================
    async getBrandsInfo(){
        this._brands = await compareDependentPicklistvalues();
        console.log('this._brands:', this._brands);
    }
    async getModelInfo(){
        const selected = this._brands.find(e => e.value === this.brandValue);
        this._models = selected.dependency;
        console.log('this._models:', this._models);
    }
    //====================================================================

    //========================HANDLERS====================================
    handleBrandChange(event) {
        this.brandValue = event.detail.value;
    }
    handleModelChange(event) {
        this.modelValue = event.detail.value;
    }
    //====================================================================
}