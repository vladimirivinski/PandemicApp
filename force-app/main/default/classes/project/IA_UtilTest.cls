/**
 * @author Vinod Chokkula
 * @date 11/17/2020
 *
 * @description Test Class for IA_Util
 *
 */
@isTest
private class IA_UtilTest {
    @testSetup
    static void setup() {
        User thisUser = IA_TestDataFactory.createUserForRunAs();
        System.runAs(thisUser) {
            // Accounts
            List<Account> testAccountList = IA_TestDataFactory.createTestAccounts(1);
            insert testAccountList;
            // Contacts
            List<Contact> testContacts = IA_TestDataFactory.createTestContacts(testAccountList[0], 5);
            insert testContacts;
            // Users
            List<User> testUsers = IA_TestDataFactory.createTestPortalUsers(testContacts);
            insert testUsers;
            // Service Resources
            List<ServiceResource> testServiceResources = IA_TestDataFactory.createTestServiceResources(testUsers);
            testServiceResources[0].Preferred_Name__c = 'Testie0';
            insert testServiceResources;
        }
        
        // Groups
        Group testGroup = new Group(Name='Test Class Group', DeveloperName='Test_Class_Group');
        insert testGroup;
        
        GroupMember testMember = new GroupMember(UserOrGroupId=thisUser.Id ,GroupId=testGroup.Id);
        insert testMember;
    }

    /********************************************************************
     * @description Test getter method for eligibleCandidateStages
     */
    @isTest
    static void getEligibleCandidateStagesTest() {
        String candidateStage = IA_Util.eligibleCandidateStages[0];
        
        test.startTest();
        System.assertEquals('Offer', candidateStage, 'Incorrect Candidate Stage.');
        test.stopTest();
    }
    
    /********************************************************************
     * @description Test for getTokenValFromJSON
    */
    @isTest
    static void getTokenValFromJSONTest() {
        String testJSON = '{"meetingUrl":"www.test.com"}';
        
        test.startTest();
        String testValueFromJSON = IA_Util.getTokenValFromJSON(testJSON, 'meetingUrl');
        test.stopTest();
        
        System.assertEquals('www.test.com', testValueFromJSON, 'The value from the JSON should be www.test.com');
    }

    /********************************************************************
     * @description Test for email validation - invalidformat
     */
    @isTest
    static void invalidEmailTest() {
        test.startTest();
        // Invalid Email Case
        boolean bool = IA_Util.validateEmail('test1test.com');
        System.assertequals(false, bool, 'invalidEmailTest: Invalid Email Case');
        // Null Value Case
        boolean bool2 = IA_Util.validateEmail(null);
        System.assertequals(false, bool, 'invalidEmailTest: Null Value Case');
        test.stopTest();
    }

    /********************************************************************
     * @description Test for email validation - valid format
     */
    @isTest
    static void validEmailTest() {
        test.startTest();
        boolean bool = ia_util.validateemail('test1@test.com');
        System.assertequals(true, bool, 'validEmailTest');
        test.stopTest();
    }

    /********************************************************************
     * @description Test for Verification Code - invalid format
     */
    @isTest
    static void invalidVerificationCodeTest() {
        test.startTest();
        // Invalid Case
        boolean bool = IA_Util.validateVerificationCode('test1test.com');
        System.assertequals(false, bool, 'invalidVerificationCodeTest: Invalid Case');
        // Null Case
        boolean bool2 = IA_Util.validateVerificationCode(null);
        System.assertequals(false, bool2, 'invalidVerificationCodeTest: Null Case');
        test.stopTest();
    }

    /********************************************************************
     * @description Test for Verification Code - Valid Format
     */
    @isTest
    static void validVerificationCodeTest() {
        test.startTest();
        boolean bool = IA_Util.validateVerificationCode('123456');
        System.assertequals(true, bool, 'validVerificationCodeTest');
        test.stopTest();
    }

    /********************************************************************
     * @description Test for Exception Email
     */
    @isTest
    static void exceptionEmail() {
        test.startTest();
        List<String> errorMessages = new List<String>();
        errorMessages.add('test Exception Email');
        IA_Util util = new IA_Util();
        IA_Util.sendExceptionMail(errorMessages);
        test.stopTest();
    }

    /********************************************************************
     * @description Test for buildErrorMessage and notifyErrors methods
     */
    @isTest
    static void buildErrorMessageAndNotifyErrorsTest() {
        List<String> testErrors = new List<String>();
        testerrors.add(ia_util.builderrormessage('testemail@test.com', null, 'Test Flow', 'This is just a Test Error', 'IA_UtilTest'));

        test.startTest();
        IA_Util.notifyErrors(testErrors);
        test.stopTest();

        // IA_Util.notifyErrors() is a void method, so we can't make any assertions
    }

    /********************************************************************
     * @description Test getUserEmail().
     * Retrieves User's email.
     */
    @isTest
    static void getUserEmailTest() {
        User testUser = [SELECT Id FROM User LIMIT 1];
        IA_Util instance = new IA_Util();
        instance.userId = testUser.Id;
        Test.startTest();
        String userEmail;
        System.runAs(testUser) {
            userEmail = instance.getUserEmail();
        }
        System.assertNotEquals('', userEmail, 'The User does not have an Email to retrieve.');
        Test.stopTest();
    }

    /********************************************************************
     * @description Test getVolunteerName().
     * Retrieves PreferredName when it exists,
     * otherwise retrieves Name.
     */
    @isTest
    static void getVolunteerNameTest() {
        List<ServiceResource> srvRes = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Test Service Resource%' LIMIT 2];
        IA_Util instance = new IA_Util();
        Test.startTest();
        // Case 1: ServiceResource has a PreferredName
        instance.volunteerId = srvRes[0].Id;
        String name0 = instance.getVolunteerName();
        // Case 2: ServiceResource does not have a PreferredName
        instance.volunteerId = srvRes[1].Id;
        String name1 = instance.getVolunteerName();
        Test.stopTest();
        System.assertequals('Testie0', name0, 'The retrieved record should have the PreferredName.');
        System.assertequals('Test Service Resource 1', name1, 'The retrieved record should not have a PreferredName.');
    }

    /********************************************************************
     * @description Test getFormattedMeetingDateTime()
     * retrieves a formatted DateTime String.
     */
    @isTest
    static void getFormattedMeetingDateTimeTest() {
        // Data Setup necessary for the tests
        Date slotDate = Date.today().adddays(2);
        Time startTime = Time.newInstance(10, 0, 0, 0);
        Time endTime = Time.newInstance(10, 30, 0, 0);

        Datetime startdateTime = Datetime.newInstance(slotDate, startTime);
        Datetime enddateTime = Datetime.newInstance(slotDate, endTime);

        List<contact> contacts = [SELECT Id FROM Contact WHERE LastName = 'Test Contact Last Name 0'];
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Account 0'];
        List<ServiceResource> srvRes = [SELECT Id FROM ServiceResource WHERE Name = 'Test Service Resource 0'];

        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for (Integer i = 0; i < 4; i++) {
            ServiceAppointment svApt = new ServiceAppointment(ContactId = contacts[0].Id, ParentRecordId = accounts[0].Id, SchedStartTime = startdateTime, SchedEndTime = enddateTime, Status = 'Scheduled', Insider_Volunteer__c = srvRes[0].id);
            saList.add(svApt);
        }
        saList[0].Time_Zone__c = 'America/New_York';
        saList[1].Time_Zone__c = 'America/Chicago';
        saList[2].Time_Zone__c = 'America/Denver';
        saList[3].Time_Zone__c = 'America/Los_Angeles';
        insert saList;

        String datetimeString = '2021-01-01T12:00:00.000Z';
        DateTime resultDateTime = DateTime.ValueofGmt(datetimeString.replace('T', ' '));

        Test.startTest();
        IA_Util instance = new IA_Util();
        instance.meetingTime = resultDateTime;
        String timezone;

        // Case 1: ServiceAppointment with Eastern Time Zone
        timezone = IA_TimeZoneConversion.getTimezoneDaylightSavings(resultDateTime, saList[0].Time_Zone__c);
        instance.appointmentId = saList[0].Id;
        String formattedDateTime = instance.getFormattedMeetingDateTime();
        System.assertequals('Friday, January 01 2021 07:00 AM ' + timezone, formattedDateTime, 'The formatted DateTime value was not correct.');

        // Case 2: ServiceAppointment with Central Time Zone
        timezone = IA_TimeZoneConversion.getTimezoneDaylightSavings(resultDateTime, saList[1].Time_Zone__c);
        instance.appointmentId = saList[1].Id;
        formattedDateTime = instance.getFormattedMeetingDateTime();
        System.assertequals('Friday, January 01 2021 06:00 AM ' + timezone, formattedDateTime, 'The formatted DateTime value was not correct.');

        // Case 3: ServiceAppointment with Mountain Time Zone
        timezone = IA_TimeZoneConversion.getTimezoneDaylightSavings(resultDateTime, saList[2].Time_Zone__c);
        instance.appointmentId = saList[2].Id;
        formattedDateTime = instance.getFormattedMeetingDateTime();
        System.assertequals('Friday, January 01 2021 05:00 AM ' + timezone, formattedDateTime, 'The formatted DateTime value was not correct.');

        // Case 4: ServiceAppointment with Pacific Time Zone
        timezone = IA_TimeZoneConversion.getTimezoneDaylightSavings(resultDateTime, saList[3].Time_Zone__c);
        instance.appointmentId = saList[3].Id;
        formattedDateTime = instance.getFormattedMeetingDateTime();
        System.assertequals('Friday, January 01 2021 04:00 AM ' + timezone, formattedDateTime, 'The formatted DateTime value was not correct.');

        Test.stopTest();
    }

    /********************************************************************
     * @description Test getFormatedTimeForThe
     * Ics Calendar retrieves a formatted DateTime String.
     */
    @isTest
    static void getFormattedDateTimeForIcs() {
        String datetimeString = '2021-01-01T12:00:00.000Z';
        DateTime resultDateTime = DateTime.ValueofGmt(datetimeString.replace('T', ' '));
        String defined_format = 'yyyyMMddHHmmss';
        IA_Util instance = new IA_Util();
        Test.startTest();
        instance.date_time = resultDateTime;
        instance.defined_format = defined_format;
        String formattedDateTime = instance.getFormattedDatetime();
        Test.stopTest();
        System.assertequals('20210101040000', formattedDateTime, 'The formatted DateTime value was not correct.');
    }

    /********************************************************************
     * @description Test for getUserAddressesFromPublicGroup method
     */
    @isTest
    static void getUserAddressesFromPublicGroupTest() {
        Test.startTest();
        List<String> case1 = IA_Util.getUserAddressesFromPublicGroup('Test_Class_Group');
        Test.stopTest();
        System.assertNotEquals(0, case1.size(), 'Case 1 should not be empty.');
    }



    /********************************************************************
     * @description Test for getFieldObjectField method
     */
    @isTest
    static void getFieldObjectFieldType(){
        Test.startTest();
        String result = IA_Util.getFieldObjectFieldType('ServiceResource', 'Name');
        Test.stopTest();
        System.assertEquals('STRING', result, 'Wrong Field type.');
    }

    @isTest
    static void hasAdminStatusTest(){
        User testUser = [SELECT Id FROM User LIMIT 1];
        Id userId = testUser.Id;
        Test.startTest();
        try{
            Boolean result = IA_Util.hasAdminStatus(userId);
            System.assertEquals(true, result, 'Result should be true.');
            Boolean result1 = IA_Util.hasAdminStatus('');
        } catch(System.StringException e){
            IA_Util.sendExceptionMail(e);
        }
        Test.stopTest();
    }

    // // Method doesn't support with packaging
    // //  * @description Test for getFieldsFromFieldSet method
    // //  */
    // @isTest
    // static void getFieldsFromFieldSetTest(){
    //     String fieldSet = IA_ServiceResourceResults.FIELDS_TO_RERIEVE;
    //     Test.startTest();
    //     List<Map<String, String>> result = IA_Util.getFieldsFromFieldSet('ServiceResource', fieldSet);
    //     Test.stopTest();
    //     System.assertNotEquals(null, result.isEmpty(), 'Result should not be null.');
    // }

    // // Method doesn't support with packaging
    // // /********************************************************************
    // //  * @description Test for getFieldsNamesFromFieldSet method
    // //  */
    // @isTest
    // static void getFieldsNamesFromFieldSetTest(){
    //     String fieldSet = IA_ServiceResourceResults.FIELDS_TO_RERIEVE;
    //     Test.startTest();
    //     String result = IA_Util.getFieldsNamesFromFieldSet('ServiceResource', fieldSet);
    //     Test.stopTest();
    //     System.assertEquals(true, String.isNotEmpty(result), 'Result should not be empty.');
    // }
}