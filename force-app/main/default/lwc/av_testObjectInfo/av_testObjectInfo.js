import { LightningElement, api, track, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class Av_testObjectInfo extends LightningElement {
	@api objectApiName;
	@track accountObject;

	@wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
	accountObject({error, data}){
        if(data){
            console.log(data);
        }else{
            
            console.log(error);
			
        }
    }

	get objectInfoStr() {
		return this.objectInfo ? JSON.stringify(this.objectInfo.data, null, 2) : "";
	}

	
}
