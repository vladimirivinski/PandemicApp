/**
 * @author VenkateswaraReddy Komireddy
 * @date 29/03/2021
 *
 * @description Controller class used for Create service Appointment
 * inside the Insider App community.
 */
public with sharing class IA_BookingAppointmentController {
    @testvisible
    static List<String> errorMessages;

    /*******************************************************************************************************
     * @description return list of available time slots from current date to 10 days 
     */
    @AuraEnabled
    public static IA_BookingAppointmentService.BookSlotInfoWrapper getTimeSlots(Id ServiceResourceId, String TimeZone) {
        ServiceAppointmentResult appointmentDetails;
        errorMessages = new List<string>();
        IA_BookingAppointmentService.BookSlotInfoWrapper bookslotInfo = new IA_BookingAppointmentService.BookSlotInfoWrapper();
        try {
            Date currentDate = System.today();
            List<SObject> queryResult = [SELECT id, Name, About_this_Insider__c, Top_3_Interests_ERGs__c, Job_Title__c, Equality_Groups__c, Affiliations__c, Job_Family__c, Profile_Picture__c, IsActive, Work_Time_Zone__c, Number_Of_Meetings_This_Month__c, Number_Of_Meetings_Next_Month__c, (SELECT id, Insider_Volunteer__c, Start_Date__c, End_Date__c FROM Time_Offs__r WHERE (Start_Date__c > :currentDate OR End_Date__c > :currentDate) AND Status__c != 'Canceled'), (SELECT id, OperatingHoursId, OperatingHours.TimeZone FROM ServiceTerritories LIMIT 1), (SELECT id, Insider_Volunteer__c, MeetingUrl__c, SchedStartTime, SchedEndTime, StartDate__c, Status FROM Insider_s_Meetings__r WHERE Status IN ('Scheduled', 'Rescheduled') AND (StartDate__c = THIS_MONTH OR StartDate__c = NEXT_MONTH) ORDER BY StartDate__c ASC) FROM ServiceResource WHERE id = :ServiceResourceId];
            ServiceResource serviceResoucerRecord = (ServiceResource) queryResult[0];
            list<IA_BookingAppointmentService.TimeSection> listTimeSection = IA_BookingAppointmentService.getTimeslotAvailability(serviceResoucerRecord, TimeZone, FALSE);
            bookslotInfo.serviceResource = serviceResoucerRecord;
            bookslotInfo.timeSections = listTimesection;
        } catch (Exception exp) {
            errorMessages.add(IA_Util.buildErrorMessage(UserInfo.getUserEmail(), ServiceResourceId, 'Retrieving Time Slots', exp.getMessage(), exp.getStackTraceString()));
            appointmentDetails = new ServiceAppointmentResult(false, 'Something went Wrong (get Time Slots)', null);
        } finally {
            IA_Util.notifyErrors(errorMessages);
        }
        return bookslotInfo;
    }

    /*******************************************************************************************************
     * @description create serviceAppointment
     */
    @AuraEnabled
    public static ServiceAppointmentResult createServiceAppointment(String serviceResourceId, Date slotdate, Time starttime, Time endtime, String message, Id contactId, string timezone) {
        // ---------------------------------------------
        // TODO: provide functionality to have message
        // on the appointment record level
        // expected param here "message"
        // ---------------------------------------------
        ServiceAppointmentResult appointmentDetails;
        errorMessages = new List<string>();
        try {
            string customDataConvertorclass = IA_Util.InsiderConfigDefaultRec.DataConvertorClass__c;
            Type t = Type.forName(customDataConvertorclass);
            IA_DateGenerator Dtgenerator = (IA_DateGenerator) t.newInstance();
            Datetime schStartTime = Dtgenerator.newInstanceTimeZone(slotdate, timezone, starttime);
            if (endtime.hour() == 0 && (endTime.minute() == 0 || endTime.minute() == 15)) {
                slotdate = slotdate.addDays(1);
            }
            Datetime schEndTime = Dtgenerator.newInstanceTimeZone(slotdate, timezone, endtime);
            Boolean isBooked = IA_BookingAppointmentService.beforeCreateServiceAppointment(serviceResourceId, schStartTime, schEndTime);
            if (isBooked) {
                appointmentDetails = new ServiceAppointmentResult(false, 'The selected time is no longer available.', null);
            } else if (!IA_ServiceResources.hasNoExistingAppointment()) {
                appointmentDetails = new ServiceAppointmentResult(false, 'You have already booked an Insiders Meeting. If you need to reschedule please refer to your confirmation email.', null);
            } else {
                if (String.isNotBlank(serviceResourceId)) {
                    Id recordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Insiders Meeting').getRecordTypeId();
                    Contact accountIdForCurrentLoggedInUser = [SELECT id, AccountId FROM Contact WHERE id = :contactId];
                    Id pacificTimeId = [SELECT Id FROM ServiceTerritory WHERE Name = 'Pacific Time']?.Id;
                    if (accountIdForCurrentLoggedInUser != null) {
                        ServiceAppointment serviceAppointmentRecord = new ServiceAppointment();

                        System.debug('::::::::: VKALASHNIKOV ::::::::: pacificTimeId ' + pacificTimeId);
                        System.debug('::::::::: VKALASHNIKOV ::::::::: contactId ' + contactId);

                        if (contactId != null) {
                            serviceAppointmentRecord.ContactId = contactId;
                        }

                        serviceAppointmentRecord.ParentRecordId = accountIdForCurrentLoggedInUser.AccountId;
                        serviceAppointmentRecord.Insider_Volunteer__c = serviceResourceId;
                        serviceAppointmentRecord.SchedStartTime = schStartTime;
                        serviceAppointmentRecord.SchedEndTime = schEndTime;
                        serviceAppointmentRecord.Status = 'Scheduled';
                        serviceAppointmentRecord.recordtypeid = recordTypeId;
                        serviceAppointmentRecord.ServiceTerritoryId = pacificTimeId;
                        serviceAppointmentRecord.Message_to_Insider__c = message;
                        serviceAppointmentRecord.Time_Zone__c = timezone;

                        try {
                            System.debug('::::::::: VKALASHNIKOV ::::::::: ' + serviceAppointmentRecord);
                            insert serviceAppointmentRecord;
                        } catch (Exception exp) {
                            appointmentDetails = new ServiceAppointmentResult(false, 'Something went Wrong (Create Appointment #1)', null);
                            errorMessages.add(IA_Util.buildErrorMessage(UserInfo.getUserEmail(), serviceResourceId, 'Insert Service Appointment', exp.getMessage(), exp.getStackTraceString()));
                        }

                        if (string.isNotBlank(serviceAppointmentRecord.Id)) {
                            appointmentDetails = new ServiceAppointmentResult(true, 'Success', serviceAppointmentRecord.Id);
                        }
                    } else {
                        appointmentDetails = new ServiceAppointmentResult(false, 'The Service Resource contact does not exist', null);
                        errorMessages.add(IA_Util.buildErrorMessage(UserInfo.getUserEmail(), serviceResourceId, 'Create Service Appointment', 'The Service Resource contact does not exist', null));
                    }
                } else {
                    appointmentDetails = new ServiceAppointmentResult(false, 'The Service Resource does not exist', null);
                    errorMessages.add(IA_Util.buildErrorMessage(UserInfo.getUserEmail(), serviceResourceId, 'Create Service Appointment', 'The Service Resource does not exist', null));
                }
            }
        } catch (Exception exp) {
            appointmentDetails = new ServiceAppointmentResult(false, 'Something went Wrong  (Create Appointment #2)', null);
            errorMessages.add(IA_Util.buildErrorMessage(UserInfo.getUserEmail(), serviceResourceId, 'Create Service Appointment', exp.getMessage(), exp.getStackTraceString()));
        } finally {
            IA_Util.notifyErrors(errorMessages);
        }
        return appointmentDetails;
    }

    /*******************************************************************************************************
     * @description Booking Appointment cancel logic
	 */
    @AuraEnabled
    public static ServiceAppointmentResult cancelAppointments(Id serviceAppointmentId) {
        errorMessages = new List<string>();
        ServiceAppointmentResult appointmentDetails;
        try {
            if (serviceAppointmentId != null) {
                List<ServiceAppointment> listOfServiceAppointemnt = [SELECT id, Status, Insider_Volunteer__c FROM ServiceAppointment WHERE id = :serviceAppointmentId];
                if (!listOfServiceAppointemnt.isEmpty() && Schema.sObjectType.ServiceAppointment.isUpdateable()) {
                    for (ServiceAppointment serviceAppointmentRec : listOfServiceAppointemnt) {
                        serviceAppointmentRec.Status = 'Canceled';
                    }

                    Database.SaveResult[] updateResults = Database.update(listOfServiceAppointemnt, false);
                    for (Integer i = 0; i < updateResults.size(); i++) {
                        if (!updateResults.get(i).isSuccess()) {
                            Database.Error error = updateResults.get(i).getErrors().get(0);
                            appointmentDetails = new ServiceAppointmentResult(false, 'Something went Wrong (Cancel Appointment #1)', null);
                            errorMessages.add(IA_Util.buildErrorMessage(UserInfo.getUserEmail(), listOfServiceAppointemnt[0].Insider_Volunteer__c, 'cancel Appointments', error.getMessage(), 'Class.IA_BookingAppointmentController \n  Method.cancelAppointments'));
                        } else {
                            appointmentDetails = new ServiceAppointmentResult(true, 'Success', null);
                        }
                    }
                }
            }
        } catch (Exception exp) {
            appointmentDetails = new ServiceAppointmentResult(false, 'Something went Wrong (Cancel Appointment #2)', null);
            errorMessages.add(IA_Util.buildErrorMessage(UserInfo.getUserEmail(), null, 'cancelAppointments', exp.getMessage(), exp.getStackTraceString()));
        } finally {
            IA_Util.notifyErrors(errorMessages);
        }
        return appointmentDetails;
    }

    /*******************************************************************************************************
     * @description RSVP closed
     */
    @AuraEnabled
    public static Boolean hasNoTimeSlotsAvailable(Id serviceResourceId, String timeZone) {
        errorMessages = new List<string>();
        IA_BookingAppointmentService.BookSlotInfoWrapper bookingWrapper;
        try {
            bookingWrapper = getTimeSlots(ServiceResourceId, TimeZone);
        } catch (Exception exp) {
            errorMessages.add(IA_Util.buildErrorMessage(UserInfo.getUserEmail(), serviceResourceId, 'No Time slot available', exp.getMessage(), exp.getStackTraceString()));
        } finally {
            IA_Util.notifyErrors(errorMessages);
        }
        return bookingWrapper.timesections.size() > 0 ? true : false;
    }

    /*******************************************************************************************************
     * @description service appointment success or failure wrapper class
     */
    public class ServiceAppointmentResult {
        @AuraEnabled
        public Boolean isSuccess { get; set; }
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public Id bookingAppointmentId { get; set; }
        ServiceAppointmentResult(Boolean isSuccess, String message, Id bookingAppointmentId) {
            this.isSuccess = isSuccess;
            this.message = message;
            this.bookingAppointmentId = bookingAppointmentId;
        }
    }

    /*******************************************************************************************************
     * @description ...
     * @return ...
     */
    @AuraEnabled
    public static List<IA_SelectOption> getTimeZones() {
        try {
            List<IA_SelectOption> timeZones = IA_Util.getTimeZones();
            return timeZones;
        } catch (Exception err) {
            IA_Util.sendExceptionMail(err);
            return null;
        }
    }
    /*******************************************************************************************************
     * @description Get Countries from SR
     * @return ...
     */
    @AuraEnabled
    public static List<IA_SelectOption> getCountries() {
        try {
            List<IA_SelectOption> countries = IA_Util.getCountries();
            return countries;
        } catch (Exception err) {
            IA_Util.sendExceptionMail(err);
            return null;
        }
    }

    public class IA_DependentPickList {
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public List<IA_DependentPickList> dependency {get;set;}
        
        public IA_DependentPickList(String name, String label, List<IA_DependentPickList> dependency) {
            this.name = name;
            this.label = label;
            this.dependency = new List<IA_DependentPickList>();
        }
    }

}