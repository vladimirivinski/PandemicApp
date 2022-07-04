import { LightningElement, track } from 'lwc';
import compareDependentPicklistvalues from "@salesforce/apex/AV_CarsController.compareDependentPicklistvalues";

export default class Va_CarViewer extends LightningElement {
    brandValue;
    modelValue;
    @track _brands = [];
    @track _models = [];

    //=====================GETTERS========================================
    get brands(){
        return this._brands;
    }
    get models(){
        return select;
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
        
        debugger
        console.log('selected:', selected);
        
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