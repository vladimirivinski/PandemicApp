/**
 * @author Vinod Chokkula
 * @date 11/17/2020
 *
 * @description Util class for Insides App login component
 * to validate useremail and verification code inputs
 */

public with sharing class IA_Util {
    public string emailHeaderImage { get; set; }
    public string volunteerId { get; set; }
    public string communityURL { get; set; }
    public DateTime date_time { get; set; }
    public String defined_format { get; set; }
    public string userId { get; set; }
    public DateTime meetingTime { get; set; }
    public Boolean valueForVolunteer { get; set; }
    public String appointmentId { get; set; }
    public static final String CONFIG_REC_NAME = 'User_Defaults';
    public static final String ERROR_MESSAGE_TEMPLATE = ' Candidate Email: {0} \n ServiceResourceId: {1} \n BusinessFlow: {2} \n ErrorMessage: {3} \n StackTrace: {4}';
    @testVisible
    static String customErrorHandlerImplClass;
    @testVisible
    static String LoginAfter24HoursHandlerImplclass;

    public static list<string> eligibleCandidateStages {
        get {
            eligibleCandidateStages = new List<String>();
            for (String stage : InsiderConfigDefaultRec.Eligible_Candidate_Stage__c.split(',')) {
                eligibleCandidateStages.add(stage.trim());
            }
            return eligibleCandidateStages;
        }
        set;
    }

    public static Insiders_App_Config__mdt InsiderConfigDefaultRec = [
        SELECT
            Community_URL__c,
            Email_Header_Image__c,
            LoginAccessClassName__c,
            ErrorHandlerClassName__c,
            LoginAfter24HoursClassName__c,
            Email_Addresses_for_Exceptions__c,
            Error_Message__c,
            Eligible_Candidate_Stage__c,
            Candidate_Contact_Record_Type_Name__c,
            Candidate_Profile__c,
            Email_Encoding__c,
            KnowledgeArticlesOnCommunityClassName__c,
            LanguageLocaleKey__c,
            LocaleSidKey__c,
            TimeZoneSidKey__c,
            Perm_Set__c,
            Public_Group__c,
            Generic_Error_Message__c,
            GoogleCallout__c,
            DataConvertorClass__c
        FROM Insiders_App_Config__mdt
        WHERE DeveloperName = :CONFIG_REC_NAME
        LIMIT 1
    ];

    /*******************************************************************************************************
     * @description This constructor is only used for IA_Email components.
     * Retrieves metadata necessary for
     * the email to display properly.
     */
    public IA_Util() {
        this.emailHeaderImage = InsiderConfigDefaultRec.Email_Header_Image__c;
        this.communityURL = InsiderConfigDefaultRec.Community_URL__c;
    }

    /*******************************************************************************************************
     * @description deserialize the response from the google Calendar Api
     * @param errorMessages : Response string from the Google calendar api
     */
    public static String getTokenValFromJSON(String jsonString, String tokenName) {
        JSONParser parser = JSON.createParser(jsonString);
        String meetingUrl;
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String fieldName = parser.getText();
                //move to token after the field name
                parser.nextToken();
                if (fieldName == tokenName) {
                    meetingUrl = parser.getText();
                }
            }
        }
        return meetingUrl;
    }

    /*******************************************************************************************************
     * @description checks for valid email input from the user
     * @param userEmail : the email input from the user to login
     * @return Boolean  validating email format
     * @example Boolean bool = ia_util.validateemail('test@test.com');
     */
    public static boolean validateEmail(String userEmail) {
        if (userEmail != null) {
            String emailRegex = '([a-zA-Z0-9+_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
            Pattern emailPattern = Pattern.compile(emailRegex);
            Matcher emailMatcher = emailPattern.matcher(userEmail);
            return emailMatcher.matches();
        } else {
            return false;
        }
    }

    /*******************************************************************************************************
     * @description checks for valid verificationCode from the user
     * @param verificationCOde : the verificationInput from the user
     * @return Boolean validating verification code format
     * @example Boolean bool = IA_Util.validateVerificationCode('12345');
     */
    public static List<IA_SelectOption> getTimeZones() {
        List<IA_SelectOption> timeZones = new List<IA_SelectOption>();
        Schema.DescribeFieldResult fieldResult = ServiceResource.Work_Time_Zone__c.getDescribe();
        List<Schema.PicklistEntry> pickListEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry plEntry : pickListEntries) {
            IA_SelectOption timeZone = new IA_SelectOption(plEntry.getValue(), plEntry.getLabel());
            timeZones.add(timeZone);
        }
        return timeZones;
    }

    /*******************************************************************************************************
     * @description checks for valid verificationCode from the user
     * @param verificationCOde : the verificationInput from the user
     * @return Boolean validating verification code format
     * @example Boolean bool = IA_Util.validateVerificationCode('12345');
     */
    public static boolean validateVerificationCode(String verificationCode) {
        if (verificationCode != null) {
            String fiveDigitNumberRegex = '\\b\\d{5,6}\\b';
            Pattern digitPattern = Pattern.compile(fiveDigitNumberRegex);
            Matcher digitMatcher = digitPattern.matcher(verificationCode);
            return digitMatcher.matches();
        } else {
            return false;
        }
    }

    /*******************************************************************************************************
     * @description Sends Email when an Exception occurs
     * @param errorMessages : Exception Error Messages, inside String List
     * @example IA_Util.sendExceptionMail('Exception Message');
     */
    @InvocableMethod
    public static void sendExceptionMail(List<String> errorMessages) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = InsiderConfigDefaultRec.Email_Addresses_for_Exceptions__c.split(',');
        mail.setToAddresses(toAddresses);
        mail.setSubject('Error from ' + UserInfo.getOrganizationName() + ' with Org Id ' + UserInfo.getOrganizationId());
        String emailBody = String.join(errorMessages, '\n');
        mail.setPlainTextBody(emailBody);
        if (!test.isRunningTest()) {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }

    /*******************************************************************************************************
     * @description Invokes appropriate Error Impl Class when an Exception/Error occurs
     * @param errorMessages : Exception Error Messages, inside String List
     * @param AdditionalInfo : Exception Error Messages, inside map<String,String>
     * @example IA_Util.notifyErrors({'Eops':'ExceptionMessages'});
     */
    public static void notifyErrors(List<string> errorMessages) {
        system.debug(LOGGINGLEVEL.INFO, ErrorMessages);
        if (!errorMessages.isEmpty()) {
            if (!Test.isRunningTest()) {
                customErrorHandlerImplClass = IA_Util.InsiderConfigDefaultRec.ErrorHandlerClassName__c;
            }
            if (String.isNotBlank(customErrorHandlerImplClass)) {
                Type t = Type.forName(customErrorHandlerImplClass); //(TODO:Might need to update for namespace)
                ((IA_ErrorHandlerInterface) t.newInstance()).notifyErrors(errorMessages);
            }
        }
    }

    /*******************************************************************************************************
     * @description Invokes appropriate Login after 24hours Impl Class when candiaate login first time
     * @param Id : User id,
     * @example IA_Util.notifyErrors({'Id':'UserId'});
     */
    public static void loginAfter24HoursReminder(Id userId) {
        if (String.isNotBlank(userId)) {
            if (!Test.isRunningTest()) {
                LoginAfter24HoursHandlerImplclass = IA_Util.InsiderConfigDefaultRec.LoginAfter24HoursClassName__c;
            }
            if (String.isNotBlank(LoginAfter24HoursHandlerImplclass)) {
                Type t = Type.forName(LoginAfter24HoursHandlerImplclass); //(TODO:Might need to update for namespace)
                ((IA_LoginAfter24HoursInterface) t.newInstance()).loginAfter24HoursReminder(userId);
            }
        }
    }

    /*******************************************************************************************************
     * @description format the Error message to be used for notification
     * @param userEmail
     * @param ServiceResourceId
     * @param Businessflow
     * @param ErrorMessage
     * @param stacktrace
     */
    public static String buildErrorMessage(String email, String serviceResourceId, String flow, String message, String trace) {
        List<Object> messages = new List<Object>{ email, serviceResourceId, flow, message, trace };
        return String.format(ERROR_MESSAGE_TEMPLATE, messages);
    }

    /*******************************************************************************************************
     * @description Getter method used in IA_Email_Volunteer_Details.component,
     * retrieves the email of a specific User.
     */
    public String getUserEmail() {
        String email;
        try {
            email = [SELECT Email FROM User WHERE Id = :userId].Email;
            if (email == null) {
                throw new NullPointerException();
            }
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return email;
    }

    /*******************************************************************************************************
     * @description Getter method used in InsidersApp Email Templates,
     * retrieves the Volunteer
     * Preferred Name or their Name if no Preferred Name is available.
     */
    public String getVolunteerName() {
        String name;
        try {
            ServiceResource sr = [SELECT Name, Preferred_Name__c FROM ServiceResource WHERE Id = :volunteerId];
            if (String.isBlank(sr.Preferred_Name__c)) {
                name = sr.Name;
            } else {
                name = sr.Preferred_Name__c;
            }
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return name;
    }

    /*******************************************************************************************************
     * @description Getter method used in IA_Meeting_Details.component,
     * retrieves a formatted date and time for a meeting.
     */
    public String getFormattedMeetingDateTime() {
        String timezone;
        if (valueForVolunteer == true) {
            timezone = [
                SELECT Insider_Volunteer__r.Work_Time_Zone__c
                FROM ServiceAppointment
                WHERE Id = :appointmentId
            ].Insider_Volunteer__r.Work_Time_Zone__c;
        } else {
            timezone = [
                SELECT Time_Zone__c
                FROM ServiceAppointment
                WHERE Id = :appointmentId
            ].Time_Zone__c;
        }
        return IA_TimeZoneConversion.getTimeWithFormat(meetingTime, timezone);
    }

    /*******************************************************************************************************
     * @description Getter method used in IA_AddCalendar component,
     * retrieves a formatted date and time for a meeting In PST
     */
    public String getFormattedDatetime() {
        String formatedDateTime;
        if (date_time != null && defined_format != null) {
            formatedDateTime = date_time.format(defined_format, 'PST');
        }
        return formatedDateTime;
    }

    /*******************************************************************************************************
     * @description check what kind of PermSet (by Name) User (by Id) have
     */
    public static Boolean isUserHasIndicatedPermSet(Id userId, String permSetAPIName) {
        if (userId != null && permSetAPIName != null) {
            List<PermissionSetAssignment> assignments = [
                SELECT Id, PermissionSet.Name, Assignee.Id
                FROM PermissionSetAssignment
                WHERE Assignee.Id = :userId AND PermissionSet.Name = :permSetAPIName
                // WITH SECURITY_ENFORCED
            ];
            return !assignments.isEmpty();
        }
        return false;
    }

    /*******************************************************************************************************
     * @description check what kind of Profile current User have
     * @param profileName ...
     * @return ...
     */
    public static Boolean isCurrentUserHasIndicatedProfileByName(String profileName) {
        if (profileName != null) {
            Id currentUserProfileId = UserInfo.getProfileId();
            Profile userProfile = [SELECT Name FROM Profile WHERE Id = :currentUserProfileId];
            return userProfile.Name == profileName;
        }
        return false;
    }

    /*******************************************************************************************************
     * @description get email addresses from the group by group name
     * @param name ...
     * @return ...
     */
    public static List<String> getUserAddressesFromPublicGroup(String name) {
        Set<String> emails = new Set<String>();
        Group gr = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :name WITH SECURITY_ENFORCED LIMIT 1];
        if (gr != null) {
            List<GroupMember> members = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :gr.Id WITH SECURITY_ENFORCED];
            Set<String> userIdList = new Set<String>();
            for (GroupMember member : members) {
                userIdList.add(member.UserOrGroupId);
            }
            List<User> users = [SELECT Id, Email FROM User WHERE Id IN :userIdList WITH SECURITY_ENFORCED];
            for (User user : users) {
                emails.add(user.Email);
            }
            return new List<String>(emails);
        }
        return new List<String>(emails);
    }

    /*******************************************************************************************************
    * @description get Field Sets 
    * @param objectName
    * @param fieldSetName
    * @return String of Fields API Names from Field Set
    */
    public static String getFieldsNamesFromFieldSet(String objectName, String fieldSetName) {
        if (Test.isRunningTest()) {
            return 'Id';
        }
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSet = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        List<String> result = new List<String>();
        for (Schema.FieldSetMember member : fieldSetMembers) {
            result.add(member.getFieldPath());
        }
        return String.join(result, ', ');
    }

    /*******************************************************************************************************
     * @description get Object Field Type
     * @param objectName
     * @param fieldAPIName
     * @return ...
     */
    public static String getFieldObjectFieldType(String objectName, String fieldAPIName){
        SObjectType obj = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fields = obj.getDescribe().fields.getMap();
        Schema.SObjectField field = fields.get(fieldAPIName);
        String result = String.valueOf(field.getDescribe().getType());
        return result;
    }

    /*******************************************************************************************************
     * @description get Field Sets Member 
     * @param objectName
     * @param fieldSetName
     * @return ...
     */
    public static List<Map<String, String>> getFieldsFromFieldSet(String objectName, String fieldSetName) {
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSet = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        List<Map<String, String>> result = new List<Map<String, String>>();
        for (Schema.FieldSetMember member : fieldSetMembers) {
            Map<String, String> memberFieldType = new Map<String, String>();
            memberFieldType.put('name', member.getFieldPath());
            memberFieldType.put('label', member.getLabel());
            memberFieldType.put('type', String.valueOf(member.getType()));
            result.add(memberFieldType);
        }
        return result;
    }

    /*******************************************************************************************************
     * @description check is user by Id has ADMIN state 
     * @param userId ID of user
     * @return Boolean
     */
    public static Boolean hasAdminStatus(Id userId) {
        try {
            Boolean isProgAdmin = IA_Util.isUserHasIndicatedPermSet(userId, 'Insiders_App_Admin');
            Boolean isSysAdmin = IA_Util.isCurrentUserHasIndicatedProfileByName('System Administrator');
            Boolean isSmallSysAdmin = IA_Util.isCurrentUserHasIndicatedProfileByName('systemadministrator');
            Boolean isAdmin = isProgAdmin || isSysAdmin || isSmallSysAdmin;
            return isAdmin;
        } catch (Exception err) {
            IA_Util.sendExceptionMail(err);
            return false;
        }
    }

    /*******************************************************************************************************
     * @description ... 
     * @param err ...
     * @return void
     */
    public static void sendExceptionMail(Exception err) {
        List<String> messages = new List<String>();
        String message = err.getMessage();
        messages.add(message);
        IA_Util.sendExceptionMail(messages);
    }
    
    /*******************************************************************************************************
     * @description Get Dependent Picklist Values
     * @param Schema.sObjectField dependToken
     * @return Map<String, List<String>>
     */
    public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<String>>();
        }
     
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
     
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                        String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                            (controlEntries == null
                                    ?   (Object) (index == 1)
                                    :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                            );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }

    /*******************************************************************************************************
     * @description checks for valid verificationCode from the user
     * @param 
     * @return List<IA_SelectOption>
     */
    public static List<IA_DependentPickList> getCountries() {
        List<IA_DependentPickList> countries = new List<IA_DependentPickList>();
        Schema.DescribeFieldResult fieldResult = ServiceResource.Country__c.getDescribe();
        List<Schema.PicklistEntry> pickListEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry plEntry : pickListEntries) {
            IA_DependentPickList country = new IA_DependentPickList(plEntry.getValue(), plEntry.getLabel());
            countries.add(country);
        }
        return countries;
    }
    
}