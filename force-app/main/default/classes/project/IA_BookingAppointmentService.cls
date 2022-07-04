/**
 * @author VenkateswaraReddy Komireddy
 * @date 12/04/2021
 *
 * @description class used for Create service Appointment Services
 * inside the Insider App community.
 * Last Modified : Manish Pal (06/24/2022) --> Added RSVP logic
 */

public with sharing class IA_BookingAppointmentService {
    static String DATE_FORMAT = 'MM/dd/yyyy HH:mm:ss';
    Static String START_TIME='startTime';
    static String customLoginAccessImplClass;
    Static String END_TIME='endTime';
    Static final Integer SLOT_DAYS = 10;
                                                            

    /********* Gost mode functionality. 
    @description numberOfMeetingThisMonth, numberOfMeetingNextMonth greater than equal to 4 then don't show the  time slots 
    *******/
    public static list<TimeSection> getTimeslotAvailability(ServiceResource serviceResourceRecord, String timeZone, Boolean flagRSVP) {
        id operatingHoursId;
        Integer numberOfDays = 0;
        Boolean addDaysNextMonth = false;
        Date currentDate = Date.today();
        try{
            / getting OperatingHoursId /
            if (!serviceResourceRecord.ServiceTerritories.isEmpty()) {
                operatingHoursId = serviceResourceRecord.ServiceTerritories[0].operatingHoursId;
            }
            
            if (serviceResourceRecord.Number_Of_Meetings_This_Month__c >= 4 && serviceResourceRecord.Number_Of_Meetings_Next_Month__c >= 4) {
                numberOfDays = 0;
            } else if (serviceResourceRecord.Number_Of_Meetings_This_Month__c < 4 && serviceResourceRecord.Number_Of_Meetings_Next_Month__c < 4) {
                numberOfDays = SLOT_DAYS;
            } else if (serviceResourceRecord.Number_Of_Meetings_This_Month__c < 4 && serviceResourceRecord.Number_Of_Meetings_Next_Month__c >= 4) {
                Integer daysLeftInThisMonth = calculateNumberOfDaysLeftInThisMonth(currentDate,currentDate.year(), currentDate.month());
                if (daysLeftInThisMonth > SLOT_DAYS) {
                    numberOfDays = SLOT_DAYS;
                } else {
                    numberOfDays = daysLeftInThisMonth;
                }
            } else if (serviceResourceRecord.Number_Of_Meetings_This_Month__c >= 4 && serviceResourceRecord.Number_Of_Meetings_Next_Month__c < 4) {
                Integer daysLeftInThisMonth = calculateNumberOfDaysLeftInThisMonth(currentDate,currentDate.year(), currentDate.month());
                if (daysLeftInThisMonth > SLOT_DAYS) {
                    numberOfDays = 0;
                } else {
                    numberOfDays=(SLOT_DAYS - daysLeftInThisMonth);
                }
                addDaysNextMonth = true;
            }
        }catch(Exception exp){
            throw new IA_CustomException('The issue is related to time slot availability');
        } 
        return compareMeetingsAndTimeslots(numberOfDays, addDaysNextMonth,serviceResourceRecord, serviceResourceRecord.Insider_s_Meetings__r, operatinghoursId, timeZone, flagRSVP);
    }
    

    /****
     * Count the number of days left from current date to month ending
      ****/
    public static Integer calculateNumberOfDaysLeftInThisMonth(Date currentDate,Integer year, Integer month){
        Date endDayOfMonth;
        try{
            Integer currentMonthOfDays = Date.daysInMonth(year, month);
            endDayOfMonth = Date.newInstance(year, month, currentMonthOfDays);
        }catch(Exception exp){
            throw new IA_CustomException('The issue is related to calculate NumberOfDays Left In This Month');
        }
        return currentDate.daysBetween(endDayOfMonth);
    }

    /********** 
    @description serviceappointment and Timeslots convert into same Timezone and compate the timeslots and serviceappointment
    from current date+1 to 10 Days
    *************/
    public static list<TimeSection> compareMeetingsAndTimeslots(Integer numberOfDays, Boolean addDaysNextMonth,serviceResource serviceResourceRecord, list<ServiceAppointment> listOfServiceAppoinment, Id operatinghoursIds, String timeZone, Boolean flagCheck) {
        list<TimeSection> listOfTimeSections = new List<TimeSection>();
        List<TimeSlot> timeSlotList = new List<TimeSlot>();
        map<string, list<TimeSlot>> mapTimeSlots = new map<string, list<TimeSlot>>();
        string srvterTimZon;
        try{
            if(serviceResourceRecord.Work_Time_Zone__c != null){
                srvterTimZon = serviceResourceRecord.Work_Time_Zone__c;
            }else{
                srvterTimZon = 'PST';
            }
            / get Resource Absence /
            System.debug('Time_Offs__r'+serviceResourceRecord.Time_Offs__r.size());
            Map<Id, Time_Offs__c> mapTimeOffs= getTimeOffs(serviceResourceRecord.Time_Offs__r);
            / get Service Appointment /
            map<date, list<ServiceAppointment>> appointmentSchedules = getServiceAppointments(listOfServiceAppoinment);
            / get timeslots /
            if(flagCheck ==true){
                timeSlotList = IA_ServiceResourceResults.timeSlotmap.get(operatinghoursIds);
                mapTimeSlots = getTimeslotsRSVP(timeSlotList);
            }
            else{
                mapTimeSlots = getTimeslots(operatinghoursIds);
            }
            DateTime startDate;
            DateTime endDate;
            if (addDaysNextMonth) {
                startDate = system.now().addmonths(1).date().toStartOfMonth();
                startDate=startDate.addHours(10);
            } else {
                startDate = system.now().addHours(24);
            }
            endDate = startDate.addDays(numberOfDays);
            map<Date,list<TimeSlotWrapper>> mapConvertedTimeslotWrapper=new map<Date,list<TimeSlotWrapper>>();
            for (DateTime day = startDate; day < enddate; day = day.addDays(1)) {
                String weekDay = day.formatGMT('EEEE');
                list<TimeSlotWrapper> listOfTimeSlotWrapper = new List<TimeSlotWrapper>();
                if (mapTimeSlots.containsKey(weekDay)) {
                    for (TimeSlot timeSlot : mapTimeSlots.get(weekday)) {
                        String customDataConvertorClass = IA_Util.InsiderConfigDefaultRec.DataConvertorClass__c;
                        Type t = Type.forName(customDataConvertorClass);
                        IA_DateGenerator Dtgenerator = (IA_DateGenerator)t.newInstance();
                        Datetime  startTime = Dtgenerator.newInstanceTimeZone(day,srvterTimZon,timeSlot.startTime);
                        Datetime  endTime = Dtgenerator.newInstanceTimeZone(day,srvterTimZon,timeSlot.endTime);
                        if(timeSlot.endTime.hour() == 0 && (timeSlot.endTime.minute() == 0 || timeSlot.endTime.minute() == 15)){
                            endTime = endTime.addDays(1);
                        }
                        String timeslotStartdateTime = startTime.format(DATE_FORMAT, timeZone);
                        string timeSlotenddateTime = endTime.format(DATE_FORMAT, timeZone);
                        map<String,Time> startAndEndtimeStamps = startAndEndTimeIntoTimeZoneFormat(timeslotStartdateTime,timeSlotenddateTime);
                        String timeZoneConv=Datetime.newInstance(Date.parse(timeslotStartdateTime.split(' ')[0]), startAndEndtimeStamps.get(START_TIME)).format('z',timeZone);
                        Boolean isPTO= getCompareTimeslotsWithTimeOffs(Dtgenerator,startTime,mapTimeOffs,srvterTimZon,timeZone);
                        if(isPTO){
                            if (appointmentSchedules.containsKey(endTime.date())) {
                                set<String> concatenateStarttimeEndtime =new set<String>();
                                for (ServiceAppointment serviceAppointment : appointmentSchedules.get(endTime.date())) {
                                    string serviceAppointmentStartDateTime = serviceappointment.SchedStartTime.format(DATE_FORMAT, timeZone);
                                    string ServiceAppointmentEndDateTime = serviceappointment.SchedEndTime.format(DATE_FORMAT,timeZone);
                                    concatenateStarttimeEndtime.add(serviceAppointmentStartDateTime+','+ServiceAppointmentEndDateTime);
                                }
                                if(!concatenateStarttimeEndtime.contains(timeslotStartdateTime+','+timeSlotenddateTime)){
                                    if(startDate < Dtgenerator.newInstanceTimeZone(day,srvterTimZon,timeSlot.startTime)){
                                        TimeSlotWrapper timeSlotWrapper = new TimeSlotWrapper();
                                        timeslotwrapper.startTime = startAndEndtimeStamps.get(START_TIME);
                                        timeslotwrapper.endTime = startAndEndtimeStamps.get(END_TIME);
                                        timeslotwrapper.slotConvertedDate=Date.parse(timeslotStartdateTime.split(' ')[0]);
                                        timeslotwrapper.timeZoneConv=timeZoneConv;
                                        listOfTimeSlotWrapper.add(timeslotwrapper);
                                    }
                                }
                            }  
                            else {
                                if(startDate < Dtgenerator.newInstanceTimeZone(day,srvterTimZon,timeSlot.startTime)){
                                    TimeSlotWrapper timeSlotWrapper = new TimeSlotWrapper();
                                    timeslotwrapper.startTime = startAndEndtimeStamps.get(START_TIME);
                                    timeslotwrapper.endTime = startAndEndtimeStamps.get(END_TIME);
                                    timeslotwrapper.slotConvertedDate=Date.parse(timeslotStartdateTime.split(' ')[0]);
                                    timeslotwrapper.timeZoneConv=timeZoneConv;
                                    listOfTimeSlotWrapper.add(timeslotwrapper);
                                }
                            }
                        }
                    }
                }
                if ( !listOfTimeSlotWrapper.isEmpty() ){
                    for(TimeSlotWrapper tsw : listOfTimeSlotWrapper){
                        if(mapConvertedTimeslotWrapper.containsKey(tsw.slotConvertedDate)){
                            mapConvertedTimeslotWrapper.get(tsw.slotConvertedDate).add(tsw);
                        }else{
                            mapConvertedTimeslotWrapper.put(tsw.slotConvertedDate, new list<TimeSlotWrapper>{tsw});
                        }
                    }
                    
                }
            }
            if(!mapConvertedTimeslotWrapper.isEmpty()){
                for(Date convertedDate: mapConvertedTimeslotWrapper.keySet()){
                    TimeSection timeSection = new TimeSection();
                    timesection.slotDate = convertedDate;
                    timesection.selectedTimeZone = timeZone;
                    timesection.slots = mapConvertedTimeslotWrapper.get(convertedDate);
                    listOfTimeSections.add(timeSection);
                }
            }
        }catch(Exception exp){
            throw new IA_CustomException('The issue is related to Compare Meetings And display Timeslots');
        }
        return listOfTimeSections;
    }

     /* PTO Options Logic 
     * Each time slot compare with PTO options 
    */
    Public Static Boolean getCompareTimeslotsWithTimeOffs(IA_DateGenerator Dtgenerator, Datetime timeSlotDatetime, map<Id,Time_Offs__c> mapTimeOffs, String srvterTimZon, String Timezone){
        Boolean isPTO=true;
        for(Id timeOffsIds: mapTimeOffs.keyset()){
            Time_Offs__c timeOffsRec= mapTimeOffs.get(timeOffsIds);
            Time startTime= Time.newInstance(0,0,0,0);
            Time endTime= Time.newInstance(23,59,59,0);

            // convert timeoffs to candidate timezone
            Datetime  conStartTime = Dtgenerator.newInstanceTimeZone(DateTime.newInstance(timeOffsRec.Start_Date__c,startTime),srvterTimZon,startTime);
            Datetime  conEndTime = Dtgenerator.newInstanceTimeZone(DateTime.newInstance(timeOffsRec.End_Date__c, startTime),srvterTimZon,endTime);
            if(conStartTime <= timeSlotDatetime && conEndTime >= timeSlotDatetime){
                isPTO=false;
            }
        }
        return isPTO;
    }

    / Preparing stat time and end time based on the selected timezone  **/
    public static map<String,Time> startAndEndTimeIntoTimeZoneFormat(string  timeslotStartdateTime, string timeSlotenddateTime){
        map<String,Time> convertedTimestamps;
        try{
            String convertedStartTime = timeslotStartdateTime.split(' ')[1];
            String ConvertedEndTime = timeSlotenddateTime.split(' ')[1];        
            String[] listOfStartTime = convertedStartTime.split(':');
            Time formatedStartTime = Time.newInstance( Integer.valueOf(listOfStartTime[0]),
                                                    Integer.valueOf(listOfStartTime[1])
                                                    ,Integer.valueOf(listOfStartTime[2])                               
                                                    ,0); 
            
            String[] listOfEndTime = ConvertedEndTime.split(':');
            Time formatedEndTime = Time.newInstance( Integer.valueOf(listOfEndTime[0])
                                                ,Integer.valueOf(listOfEndTime[1])
                                                ,Integer.valueOf(listOfEndTime[2])                               
                                                ,0);
            convertedTimestamps = new map<String,Time>{START_TIME =>formatedStartTime, END_TIME=>formatedEndTime};
        }catch(Exception exp){
            throw new IA_CustomException('The issue is related to Start And EndTime Into TimeZone Format');
        }
        return convertedTimestamps;
    }
    
     / Get Resource Absence  records /
    public static map<Id, Time_Offs__c > getTimeOffs(list<Time_Offs__c > listOfTimeOffs) {
        map<Id, Time_Offs__c > timeOffsShedules = new Map<Id, Time_Offs__c >();
        try{
            if (!listOfTimeOffs.isEmpty()) {
                for (Time_Offs__c  timeOffsRec : listOfTimeOffs) {
                    timeOffsShedules.put( timeOffsRec.Id, timeOffsRec);
                }
            }
        }catch(Exception exp){
            throw new IA_CustomException('The issue is related to PTO');
        }
        return timeOffsShedules;
    }

    / Get service appointments records /
    public static map<date, list<ServiceAppointment>> getServiceAppointments(list<ServiceAppointment> listOfServiceAppointments) {
        map<date, list<ServiceAppointment>> appointmentSchedules = new Map<date, list<ServiceAppointment>>();
        try{
            if (!listOfServiceAppointments.isEmpty()) {
                for (ServiceAppointment serviceAppoitmentRec : listOfServiceAppointments) {
                    if (appointmentSchedules.containsKey(serviceAppoitmentRec.SchedStartTime.Date())) {
                        appointmentSchedules.get(serviceAppoitmentRec.SchedStartTime.Date()).add(serviceAppoitmentRec);
                    } else {
                        appointmentSchedules.put(serviceAppoitmentRec.SchedStartTime.Date(), new List<ServiceAppointment>{ serviceAppoitmentRec });
                    }
                }
            }
        }catch(Exception exp){
            throw new IA_CustomException('The issue is related to Retrieve Service Appointments');
        }
        return appointmentSchedules;
    }

    / getTimeSlots /
    public static map<string, list<TimeSlot>> getTimeslots(id operatingHoursId) {
        map<string, list<TimeSlot>> mapOfTimeSlot = new Map<string, list<TimeSlot>>();
        try{
            List<TimeSlot> timeSlots = [SELECT id, EndTime, TimeSlotNumber, StartTime, Type, OperatingHoursId, DayOfWeek FROM TimeSlot
                                                         WHERE OperatingHoursId =:operatingHoursId ORDER BY StartTime ASC];
            if (!timeslots.isEmpty()) {
                for (TimeSlot timeSlotRec : timeslots) {
                    if (mapOfTimeSlot.containsKey(timeSlotRec.DayOfWeek)) {
                        mapOfTimeSlot.get(timeSlotRec.DayOfWeek).add(timeSlotRec);
                    } else {
                        mapOfTimeSlot.put(timeSlotRec.DayOfWeek, new List<TimeSlot>{ timeSlotRec });
                    }
                }
            }
        }catch(Exception exp){
            throw new IA_CustomException('The issue is related to Retrieve Timeslots');
        }
        return mapOfTimeSlot;
    }


    /* getTimeSlots RSVP*/
    public static map<string, list<TimeSlot>> getTimeslotsRSVP(List<timeslot> timeslots) {
        map<string, list<TimeSlot>> mapOfTimeSlot = new Map<string, list<TimeSlot>>();
        try{
            if (timeslots != null && !timeslots.isEmpty()) {
                for (TimeSlot timeSlotRec : timeslots) {
                    if (mapOfTimeSlot.containsKey(timeSlotRec.DayOfWeek)) {
                        mapOfTimeSlot.get(timeSlotRec.DayOfWeek).add(timeSlotRec);
                    } else {
                        mapOfTimeSlot.put(timeSlotRec.DayOfWeek, new List<TimeSlot>{ timeSlotRec });
                    }
                }
            }
        }catch(Exception exp){
            throw new IA_CustomException('The issue is related to Retrieve Timeslots' + exp.getLineNumber() + exp.getMessage());
        }
        return mapOfTimeSlot;
    }
    
    /****************************
    @description service appointment and time slots data wrapper class
    *************/
    public with sharing class BookSlotInfoWrapper {
        @AuraEnabled public ServiceResource serviceResource { get; set; }
        @AuraEnabled public list<TimeSection> timesections { get; set; }
    }
    public class TimeSection {
        @AuraEnabled public Date slotDate { get; set; }
        @AuraEnabled public String selectedTimeZone { get; set;}
        @AuraEnabled public List<TimeSlotWrapper> slots { get; set; }
    }
    public class TimeSlotWrapper {
        @AuraEnabled public Time startTime { get; set; }
        @AuraEnabled public Time endTime { get; set; }
        @AuraEnabled public Date slotConvertedDate{ get; set; }
        @AuraEnabled public String timeZoneConv { get; set; }
    }

    /***********
    @description check before create service appointment slots available or not
    *************/
    public static boolean beforeCreateServiceAppointment(String serviceResourceId,datetime schStartTime,datetime schEndTime ) {
        Boolean isBooked = false;
        if(serviceResourceId!=null && schStartTime!=null && schEndTime!=null){
        list<ServiceAppointment> listOfServiceAppointments = [SELECT id, Insider_Volunteer__c FROM ServiceAppointment 
                                                            WHERE Insider_Volunteer__c = :serviceResourceId AND 
                                                            SchedStartTime = :schStartTime AND SchedEndTime = :schEndTime 
                                                            AND Status='Scheduled'];
        
        if (!listOfServiceAppointments.isEmpty()) {
            isBooked = true;
        }
      } 
        return isBooked;
    }
    

}