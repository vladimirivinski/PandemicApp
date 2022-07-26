public with sharing class AV_Test {

    public static Schema.sObjectField getControlFieldInfo(Schema.sObjectField dependToken){
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController(); 
        if (controlToken == null) {
            return new Schema.sObjectField();
        }
        return controlToken;
    }

    public static List<Schema.PicklistEntry> getPicklistEntries(Schema.sObjectField controlToken){
        List<Schema.PicklistEntry> controlEntries = new List<Schema.PicklistEntry>();
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        return controlEntries;
    }

}
        // Schema.DescribeFieldResult depend = dependToken.getDescribe();
        // Schema.sObjectField controlToken = depend.getController(); 
        // // Schema.sObjectField = Brand__c
        // if (controlToken == null) {
        //     return new Map<String, List<Map<String, String>>>();
        // }
        // Schema.DescribeFieldResult control = controlToken.getDescribe();
        // System.debug('3 !!!!!:::::::::::::::::::::::::::::::::: control: ' + control);
        // List<Schema.PicklistEntry> controlEntries;
        // if(control.getType() != Schema.DisplayType.Boolean) {
        //     controlEntries = control.getPicklistValues();
        // }
        // System.debug('4 !!!!!:::::::::::::::::::::::::::::::::: controlEntries: ' + controlEntries);
        // /* 
        //     Schema.PicklistEntry[getLabel=Audi;getValue=Audi;isActive=true;isDefaultValue=false;], 
        //     Schema.PicklistEntry[getLabel=BMW;getValue=BMW;isActive=true;isDefaultValue=false;], 
        //     Schema.PicklistEntry[getLabel=Mersedes-Bens;getValue=Mersedes-Bens;isActive=true;isDefaultValue=false;], 
        //     Schema.PicklistEntry[getLabel=Volkswagen;getValue=Volkswagen;isActive=true;isDefaultValue=false;]
        //  */