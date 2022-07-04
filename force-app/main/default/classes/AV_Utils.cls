public with sharing class AV_Utils {

    public static List<Schema.PicklistEntry> getControleToken(Schema.sObjectField dependToken){
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController(); 
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries= control.getPicklistValues();
        return controlEntries;
    }

    public static List<Schema.PicklistEntry> getDependentToken(Schema.sObjectField dependToken){
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        List<Schema.PicklistEntry> dependEntries = depend.getPicklistValues();
        return dependEntries;
    }

    /*******************************************************************************************************
     * @description Get Dependent Picklist Values
     * @param Schema.sObjectField dependToken
     * @return Map<String, List<Map<String, String>>>
     */
    public static Map<String, List<Map<String, String>>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        List<Schema.PicklistEntry> dependEntries = getDependentToken(dependToken);
        List<Schema.PicklistEntry> controlEntries = getControleToken(dependToken);

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String, List<Map<String, String>>> dependentPicklistValues = new Map<String, List<Map<String, String>>>();
        for (Schema.PicklistEntry entry : dependEntries) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                    for (Integer i = 0; i < (controlEntries != null ? controlEntries.size() : 2); i++) {
                        Object controlValue = (controlEntries == null ? (Object) (i == 1) : (Object) (controlEntries[i].isActive() ? controlEntries[i].getLabel() : null));
                        Integer bitIndex = i / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(i, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<Map<String, String>>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(new Map<String, String>{'label' => entry.getLabel(), 'value' => entry.getValue()});
                }
            }
        }
        System.debug('::::::::::::::::RESULT::::::::::::::::' + dependentPicklistValues);
        return dependentPicklistValues;
    }

}
