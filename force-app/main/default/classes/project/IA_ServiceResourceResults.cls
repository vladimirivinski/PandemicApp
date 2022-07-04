
public with sharing class IA_ServiceResourceResults {
    public static final String OBJECT_NAME = 'ServiceResource'; // TODO: use custom settings instead this hardcoded value
    public static final String FIELDS_TO_RERIEVE = 'Insiders_Filtration_Fields'; // TODO: use custom settings instead
    public static final String PICKLIST_FIELD_TYPE = 'PICKLIST';
    public static final String MULTIPICKLIST_FIELD_TYPE = 'MULTIPICKLIST';
    public static final String IS_ACTIVE = ' WHERE IsActive = true AND Ghost_Mode_Car__c = false'; 
    public static final String ORDER_BY = ' ORDER BY Number_Of_Meetings_This_Month__c ';
    public static final String WITH_SECURITY = ' WITH SECURITY_ENFORCED ';
    public static Map<Id,list<TimeSlot>> timeSlotmap;
    public static List<TimeSlot> timeSlots;
    /*******************************************************************************************************
     * @description queryFields
     * @param String objectName
     * @return Map<String, Field>
     */
    @AuraEnabled
    public static Map<String, Field> queryFields(String objectName) {
        Map<String, Field> fields = new Map<String, Field>();
        try {
            fields = IA_ServiceResourceResults.getFields(objectName);
            if (Test.isRunningTest()) {
                throw new TypeException();
            }
        } catch (Exception err) {
            IA_Util.sendExceptionMail(err);
        }
        return fields;
    }

    /*******************************************************************************************************
     * @description queryResult
     * @param Map<String,List<String>> objectFieldsToCriteriaMap
     * @param Id serviceResourceId
     * @return List<ServiceResource>
     */
    @AuraEnabled
    public static List<ServiceResource> queryResult(Map<String, List<String>> objectFieldsToCriteriaMap, Id serviceResourceId) {
        // -----------------------------------------------------------------------------
        String fieldsToDisplay = IA_Util.getFieldsNamesFromFieldSet(OBJECT_NAME, FIELDS_TO_RERIEVE);
        // -----------------------------------------------------------------------------
        // TODO: filtration for existing fields optoins based on crirteria content
        Map<String, Field> fields = IA_ServiceResourceResults.getFields('ServiceResource');
        Map<String, List<String>> criteria = filterCriteria(fields, objectFieldsToCriteriaMap);
        // -----------------------------------------------------------------------------
        if (serviceResourceId != null) {
            return IA_ServiceResourceResults.getDataById(serviceResourceId, fieldsToDisplay);
        } else if (!criteria.isEmpty()) {
            return IA_ServiceResourceResults.getDataByCryteria(criteria, fieldsToDisplay);
        }
        return IA_ServiceResourceResults.getData(fieldsToDisplay);
    }

    /*******************************************************************************************************
     * @description filterCriteria
     * @param Map<String,Field> fields
     * @param Map<String,List<String>> criteria
     * @return Map<String, List<String>>
     * @example ...
     */
    public static Map<String, List<String>> filterCriteria(Map<String, Field> fields, Map<String, List<String>> criteria) {
        Set<String> criteriaKeySet = criteria.keySet();
        Map<String, List<String>> result = new Map<String, List<String>>();
        if (!criteriaKeySet.isEmpty()) {
            for (String name : criteriaKeySet) {
                Field field = fields.get(name); // object info field representation
                List<String> values = criteria.get(name); // optoins from criteria
                List<String> options = new List<String>();
                // gather options from criteria based on real options from object field
                for (Option option : field.options) {
                    if (values.contains(option.name)) {
                        options.add(option.name);
                    }
                }
                // do not put criteria in case no options in list
                if (!options.isEmpty()) {
                    result.put(name, options);
                }
            }
            return result;
        } else {
            return criteria;
        }
    }

    /*******************************************************************************************************
     * @description getFields
     * @param String objectName
     * @return Map<String, Field>
     * @example IA_ServiceResourceResults.getFields('ServiceResource');
     */
    public static Map<String, Field> getFields(String objectName) {
        // if (Test.isRunningTest()) {
        //     return new Map<String, Field>();
        // }
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeSObjectResultObj.fields.getMap();
        Set<String> fieldKeySet = fieldsMap.keySet();
        Map<String, Field> result = new Map<String, Field>();
        for (String fieldName : fieldKeySet) {
            Schema.DescribeFieldResult field = fieldsMap.get(fieldName).getDescribe();
            Field item = new Field(field);
            String name = field.getName();
            result.put(name, item);
        }
        return result;
    }

    /*******************************************************************************************************
     * @description getDataById
     * @param Id serviceResourceId,
     * @param String fields
     * @return List<ServiceResource>
     * @example ...
     */
    public static List<ServiceResource> getDataById(Id serviceResourceId, String fields) {
        String identifierMatch = ' AND Id = \'' + serviceResourceId + '\'';
        String payload = IS_ACTIVE + identifierMatch + WITH_SECURITY + ORDER_BY;
        String query = 'SELECT ' + fields + ' FROM ' + OBJECT_NAME + payload;
        List<ServiceResource> result = Database.query(query);
        return result;
    }

    /*******************************************************************************************************
    * @description returnDataFilteringRSPV : Filter out and return all the service resource whose RSPV is False. Modified as part of W-11226837
    * @param List of Result from getData
    * @return List<ServiceResource>
    * @example ......
    */
    public static List<ServiceResource> returnDataFilteringRSPV(List<ServiceResource> result) 
    {
        //Variable Initialize
        IA_BookingAppointmentService.BookSlotInfoWrapper bookslotInfo = new IA_BookingAppointmentService.BookSlotInfoWrapper();
        List<ServiceResource> resultAllRSPVFalseServiceResourceList = new List<ServiceResource>();
        Map<id,ServiceResource> serviceResourceResultMap = new Map<id,ServiceResource>();        
        Date currentDate = System.today();
        Boolean flagRSPV = True;
        //converting list into map which is used while comparision.
        for(ServiceResource resource:result)
        {
            serviceResourceResultMap.put(resource.id,resource);
        }
        
        Map<Id,ServiceResource> queryResultMap = new Map<Id,ServiceResource>(
            [SELECT id,
             Name,
             About_this_Insider__c,
             Top_3_Interests_ERGs__c,
             Job_Title__c,
             Equality_Groups__c,
             Affiliations__c,
             Job_Family__c,
             Profile_Picture__c,
             IsActive,
             Work_Time_Zone__c,
             Number_Of_Meetings_This_Month__c,
             Number_Of_Meetings_Next_Month__c, 
             (SELECT id,
              Insider_Volunteer__c,
              Start_Date__c,
              End_Date__c 
              FROM Time_Offs__r 
              WHERE (Start_Date__c > :currentDate OR End_Date__c > :currentDate) 
              AND Status__c != 'Canceled'), 
             (SELECT id,
              OperatingHoursId,
              OperatingHours.TimeZone 
              FROM ServiceTerritories LIMIT 1), 
             (SELECT id,
              Insider_Volunteer__c,
              MeetingUrl__c,
              SchedStartTime,
              SchedEndTime,
              StartDate__c,
              Status 
              FROM Insider_s_Meetings__r 
              WHERE Status IN ('Scheduled', 'Rescheduled') 
              AND (StartDate__c = THIS_MONTH OR StartDate__c = NEXT_MONTH) 
              ORDER BY StartDate__c ASC) 
             FROM ServiceResource WHERE id  IN : result]);
        
        Set<Id> operatingHoursId = new Set<Id>();
        for(ServiceResource serviceRes:queryResultMap.Values()){
             if (!serviceRes.ServiceTerritories.isEmpty()) {
                operatingHoursId.add(serviceRes.ServiceTerritories[0].operatingHoursId);
            }
        }
        timeSlotmap = new Map<Id,list<TimeSlot>>();
        timeSlots = [SELECT id, EndTime, TimeSlotNumber, StartTime, Type, OperatingHoursId, DayOfWeek FROM TimeSlot
                     WHERE OperatingHoursId IN :operatingHoursId ORDER BY StartTime ASC];
        
        for(TimeSlot ts : timeSlots){
            if (timeSlotmap.containsKey(ts.OperatingHoursId)) {
                timeSlotmap.get(ts.OperatingHoursId).add(ts);
            } else {
                timeSlotmap.put(ts.OperatingHoursId, new List<TimeSlot>{ ts });
            }
        }
        
        for(ServiceResource serviceRes:queryResultMap.Values())
        {
            list<IA_BookingAppointmentService.TimeSection> listTimeSection = IA_BookingAppointmentService.getTimeslotAvailability(serviceRes, 'PST', flagRSPV);
            bookslotInfo.timeSections = listTimesection;
            if(bookslotInfo.timeSections.size() > 0)
            {
                if(serviceResourceResultMap.containsKey(serviceRes.id))
                {
                    resultAllRSPVFalseServiceResourceList.add(serviceResourceResultMap.get(serviceRes.id));
                }
            }
        }
        if(IA_ServiceResources.hasMeetingInCompletedStatus()== True)
        {
            resultAllRSPVFalseServiceResourceList = new List<ServiceResource>();
        }
        return resultAllRSPVFalseServiceResourceList;        
    }
    
    
    
    /*******************************************************************************************************
     * @description getData
     * @param String fields
     * @return List<ServiceResource>
     * @example ...
     */
    public static List<ServiceResource> getData(String fields) {
        String payload = IS_ACTIVE + WITH_SECURITY + ORDER_BY;
        String query = 'SELECT ' + fields + ' FROM ' + OBJECT_NAME + ' ' + payload;
        List<ServiceResource> result = Database.query(query);
        return IA_ServiceResourceResults.returnDataFilteringRSPV(result);
    }

    /*******************************************************************************************************
     * @description getDataByCryteria
     * @param Map<String, List<String>> objectFieldsToCriteriaMap
     * @param String fields
     * @return List<ServiceResource>
     * @example ...
     */
    public static List<ServiceResource> getDataByCryteria(Map<String, List<String>> objectFieldsToCriteriaMap, String fields) {
        String whereStr = '';
        for (String q : objectFieldsToCriteriaMap.Keyset()) {
            String fillStr = '';
            String qField = String.escapeSingleQuotes(q);
            String fieldType = IA_Util.getFieldObjectFieldType(OBJECT_NAME, qField);
            Boolean isPicklists = fieldType == PICKLIST_FIELD_TYPE || fieldType == MULTIPICKLIST_FIELD_TYPE;
            if (isPicklists) {
                String operator = (fieldType == PICKLIST_FIELD_TYPE) ? ' IN ' : ' INCLUDES ';
                String initOperator = qField + operator;
                String incrementOperator = (whereStr + ' AND ' + initOperator);
                whereStr = (whereStr == '') ? initOperator : incrementOperator;
                for (String fv : objectFieldsToCriteriaMap.get(qField)) {
                    String fVal = String.escapeSingleQuotes(fv);
                    String init = ('(\'' + fVal + '\'');
                    String increment = (fillStr + ', ' + '\'' + fVal + '\'');
                    fillStr = (fillStr == '') ? init : increment;
                }
                whereStr += fillStr + ')';
            }
        }
        String payload = IS_ACTIVE + ' AND ' + whereStr + WITH_SECURITY + ORDER_BY;
        String query = 'SELECT ' + fields + ' FROM ' + OBJECT_NAME + ' ' + payload;
        List<ServiceResource> result = Database.query(query);
        return IA_ServiceResourceResults.returnDataFilteringRSPV(result);
    }

    public class Field {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String inlineHelpText { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public List<Option> options { get; set; }
        public Field(Schema.DescribeFieldResult field) {
            String type = String.valueOf(field.getType());
            this.type = type;
            this.name = field.getName();
            this.label = field.getLabel();
            this.inlineHelpText = field.getInlineHelpText();
            this.options = new List<Option>();
            if (type == PICKLIST_FIELD_TYPE || type == MULTIPICKLIST_FIELD_TYPE) {
                for (Schema.PicklistEntry entry : field.getPicklistValues()) {
                    if (entry.isActive()) {
                        Option option = new Option(entry);
                        options.add(option);
                    }
                }
            }
        }
    }

    public class Option {
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String label { get; set; }
        public Option(Schema.PicklistEntry entry) {
            this.name = entry.getValue();
            this.label = entry.getLabel();
        }
    }
}