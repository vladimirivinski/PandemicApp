public with sharing class AV_CarsController {
    /*******************************************************************************************************
     * @description get picklist values from Car Brand
     * @param 
     * @return List<IA_SelectOption>
     */
    public static List<AV_DepWrapper> getBrands() {
        List<AV_DepWrapper> brands = new List<AV_DepWrapper>();
        Schema.DescribeFieldResult fieldResult = Car__c.Brand__c.getDescribe();
        List<Schema.PicklistEntry> pickListEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry plEntry : pickListEntries) {
            AV_DepWrapper brand = new AV_DepWrapper(plEntry.getLabel(), plEntry.getValue(), new List<Map<String, String>>());
            brands.add(brand);
        }
        return brands;
    }
    /*******************************************************************************************************
     * @description get picklist values from Car Brand
     * @param 
     * @return List<IA_SelectOption>
     */
    @AuraEnabled
    public static List<AV_DepWrapper> compareDependentPicklistvalues(){
        List<AV_DepWrapper> brands =  getBrands();
        Map<String, List<Map<String, String>>> models = AV_Utils.getDependentPicklistValues(Car__c.Model__c);
        List<AV_DepWrapper> result = new List<AV_DepWrapper>();
        for(String mod : models.keySet()){
            for(AV_DepWrapper br : brands){
                if(mod == br.value){
                    AV_DepWrapper brand = new AV_DepWrapper(br.label, br.value, models.get(mod));
                    result.add(brand);
                }
            }
        }
        return result;
    }

    public class AV_DepWrapper{
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public List<Map<String, String>> dependency { get; set; }

        public AV_DepWrapper(String value, String label, List<Map<String, String>> dependency){
            this.label = label;
            this.value = value;
            this.dependency = dependency;
        }
    }

}
