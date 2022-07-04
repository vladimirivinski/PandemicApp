public with sharing class AV_Utils {

    /*******************************************************************************************************
     * @description Get Dependent Picklist Values
     * @param Schema.sObjectField dependToken
     * @return Map<String, List<String>>
     */
    public static Map<String, List<Map<String, String>>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        System.debug('1 !!!!!:::::::::::::::::::::::::::::::::: depend: ' + depend);
        Schema.sObjectField controlToken = depend.getController();
        System.debug('2 !!!!!:::::::::::::::::::::::::::::::::: controlToken: ' + controlToken);
        if (controlToken == null) {
            return new Map<String, List<Map<String, String>>>();
        }
     
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        System.debug('3 !!!!!:::::::::::::::::::::::::::::::::: control: ' + control);
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        System.debug('4 !!!!!:::::::::::::::::::::::::::::::::: controlEntries: ' + controlEntries);
     
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String, List<Map<String, String>>> dependentPicklistValues = new Map<String, List<Map<String, String>>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            System.debug('5 !!!!! 1st FOR loop:::::::::::::::::::::::::::::::::: entry: ' + entry);
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                        String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                        System.debug('6 !!!!! :::::::::::::::::::::::::::::::::: base64chars: ' + base64chars);
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    System.debug('7 !!!!! 2nd FOR loop:::::::::::::::::::::::::::::::::: controlEntries: ' + controlEntries);
                    Object controlValue =
                            (controlEntries == null
                                    ?   (Object) (index == 1)
                                    :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                            );
                            System.debug('8 !!!!! :::::::::::::::::::::::::::::::::: controlValue: ' + controlValue);
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
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
