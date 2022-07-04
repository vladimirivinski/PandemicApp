import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import { getProfileMock, getSectionsMock, getTimeZonesMock, getCountriesMock } from "./BookingMock";
import { createAppointmentMock, cancelAppointmentMock } from "./BookingMock";
import { getServiceResourceMapping, serviceResourcesMappingHelper,  } from "c/ia_Utils";
import { getURLQueryParamsAsMap, checkArray } from "c/ia_Utils";
import { generateBookedAppointmentURLPayload } from "c/ia_Utils";
import { generateBookingLabel, formatBookingSlots } from "c/ia_Utils";

import queryResult from "@salesforce/apex/IA_ServiceResourceResults.queryResult";
import checkBookingStatus from '@salesforce/apex/IA_CandidateMeetingConfirmation.IA_CandidateAppoinmtnetConfirmation';
import cancelAppointments from "@salesforce/apex/IA_BookingAppointmentController.cancelAppointments";
import createServiceAppointment from "@salesforce/apex/IA_BookingAppointmentController.createServiceAppointment";
import getTimeSlots from "@salesforce/apex/IA_BookingAppointmentController.getTimeSlots";
import getTimeZones from "@salesforce/apex/IA_BookingAppointmentController.getTimeZones";
import getCountries from "@salesforce/apex/IA_BookingAppointmentController.getCountries";

import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from "@salesforce/user/Id";

import ia_VolunteerBooking from "./ia_VolunteerBooking.html";
import ia_VolunteerBookingSections from "./ia_VolunteerBookingSections.html";
import ia_VolunteerBookingConfirmation from "./ia_VolunteerBookingConfirmation.html";
import ia_VolunteerBookingDetails from "./ia_VolunteerBookingDetails.html";
import ia_VolunteerBookingRescheduling from "./ia_VolunteerBookingRescheduling.html";
import ia_VolunteerBookingCancelation from "./ia_VolunteerBookingCancelation.html";
import ia_VolunteerBookingComplete from "./ia_VolunteerBookingComplete.html";

export default class Ia_VolunteerBooking extends NavigationMixin(LightningElement) {
    // ===================================================
    // PROPS:
    @api devMode;
    isTileVertical = true; // tile helper
    selectedSlot = null;
    bookingVariation = ""; // render helper
    queryIsInAction = false;
    isTimeZoneAutoFocusable = false;
    isCountriesAutoFocusable = false;
    selectedTimeZone = { label:"Pacific Time (America/Los_Angeles)", value:"America/Los_Angeles" };
    selectedCountry = { label:"Australia", value:"Australia" };
    // backend:
    _timezones = [];
    _sections = [];
    _profile = [];
    _countries = [];
    // messages:
    confirmationMessagePlaceholder = "Want to send a note before your meeting? Enter it here. (optional)";
    bookAppointmentError = "";
    confirmationMessage = "";
    timeZoneLabel = "Show open times in:";
    genericError = "";
    countriesLabel = "Show Availeble Countries";


    // ===================================================
    // WIRE:
    @wire(getRecord, { recordId: USER_ID, fields: [ CONTACT_ID ] })
    user;
    @wire(getObjectInfo, { objectApiName: 'ServiceResource' })
    ServiceResource;
    @wire(getObjectInfo, { objectApiName: "ServiceAppointment" })
    ServiceAppointment;


    // ===================================================
    // GETTERS/SETTERS:
    get isConfirmationNotAvailable() {
        const message = this.confirmationMessage?.length || 0;
        const limit = this.messageCaracterLimit;
        return limit < message;
    }
    get serviceAppointmentMapping() {
        const fields = this.ServiceAppointment?.data?.fields;
        const copy = fields ? JSON.parse(JSON.stringify(fields)) : fields;
        return copy;
    }
    get messageCaracterLimit() {
        const limit = this.serviceAppointmentMapping?.Message_to_Insider__c?.length || 0;
        return limit;
    }
    get confirmationMessageLength () {
        return this.confirmationMessage?.length || 0;
    }
    get messageCaracterLimitError() {
        return `Oops! You’ve exceeded the maximum character limit.
        Please ensure your message is less than ${this.messageCaracterLimit} characters before proceeding.
        Thanks!`;
    }
    get isExperienceBuilder() {
        const cond1 = (this.url.app === "commeditor");
        const cond2 = (this.url.view === "editor");
        return cond1 || cond2;
    }
    get isSpinner() {
        return this.queryIsInAction;
    }
    get rootCssClassName() {
        const base = 'page page-booking';
        return `${base} ${this.devMode ? 'developer-mode': ''}`;
    }
    get url() {
        return getURLQueryParamsAsMap();
    }
    get serviceResQueryPayload() {
        const objectFieldsToCriteriaMap = {};
        const serviceResourceId = this.url.id || null;
        const payload = { serviceResourceId, objectFieldsToCriteriaMap };
        return payload;
    }
    get timeSlotsQueryPayload() {
        const ServiceResourceId = this.url.id;
        const TimeZone = this.selectedTimeZone.value;
        return { ServiceResourceId, TimeZone };
    }
    get createServiceAppointmentPayload() {
        const serviceResourceId = this.url.id;
        const slotdate = this.url.slotdate;
        const starttime = this.url.starttime*1;
        const endtime = this.url.endtime*1;
        const message = this.confirmationMessage;
        const timezone = this.url.timezoneRep;
        const contactId = getFieldValue(this.user.data, CONTACT_ID);
        const payload = { serviceResourceId, slotdate, starttime, endtime, message,contactId,timezone};
        return payload;
    }
    get cancelAppointmentQueryPayload() {
        const serviceAppointmentId = this.url.appointmentId;
        return { serviceAppointmentId };
    }
    get confirmationSelectedTimeSlotLabel() {
        const timestamp = parseInt(this.url.timestamp, 10);
        const timezone = this.url.timezone;
        const label = generateBookingLabel(timestamp, timezone);
        return label;
    }
    get isProfile() {
        return checkArray(this._profile);
    }
    get isSections() {
        return checkArray(this._sections);
    }
    get isTimezones() {
        return checkArray(this._timezones);
    }
    get isCountries() {
        return checkArray(this._countries);
    }
    get isTimeSlotsToDisplay() {
        return this.isProfile || this.isSections;
    }
    get isBookingActionDisabled() {
        return !this.selectedSlot;
    }
    get getServiceResourceMapping() {
        const source = this.ServiceResource;
        const mapping = getServiceResourceMapping(source);
        return mapping;
    }
    get profile() {
        const source = this._profile;
        const mapping = this.getServiceResourceMapping;
        const isReady = (checkArray(Object.keys(mapping)) && checkArray(source));
        const result = isReady ? serviceResourcesMappingHelper(source, mapping) : [{}];
        return result[0];
    }
    get timezones() {
        return this._timezones;
    }
    get countries() {
        return this._countries;
    }
    set sections(val) {
        this._sections = val;
    }
    get sections() {
        return this._sections;
    }
    get confirmationURL() {
        const timestamp = this.selectedSlot.info.start.timestamp;
        const timezone = this.selectedSlot.info.start.timeZone;
        const timezoneRep = this.selectedSlot.selectedTimeZone;
        const slotdate = this.selectedSlot.slotDate;
        const starttime = this.selectedSlot.startTime;
        const endtime = this.selectedSlot.endTime;
        const variation = 'confirmation';
        const id = this.url.id;
        const payload = { id, variation, timestamp, timezone, slotdate, starttime, endtime,timezoneRep };
        return payload;
    }


    // ===================================================
    // LIFECYCLE:
    render() {
        const params = getURLQueryParamsAsMap();
        this.bookingVariation = params.variation;
        switch(true) {
            case (this.bookingVariation === 'sections'):     return ia_VolunteerBookingSections;
            case (this.bookingVariation === 'confirmation'): return ia_VolunteerBookingConfirmation;
            case (this.bookingVariation === 'details'):      return ia_VolunteerBookingDetails;
            case (this.bookingVariation === 'rescheduling'): return ia_VolunteerBookingRescheduling;
            case (this.bookingVariation === 'cancelation'):  return ia_VolunteerBookingCancelation;
            case (this.bookingVariation === 'complete'):     return ia_VolunteerBookingComplete;
            default: return ia_VolunteerBooking;
        }
    }
    async connectedCallback() {
        if (this.url?.variation?.length) {
            await this.initialisation();
        } else {
            await this.checkBookingStatus();
        }
    }
    errorCallback(error, stack) {
        console.error("Ia_VolunteerBooking: errorCallback", error, stack);
    }


    // ===================================================
    // HANDLERS:
    handleNavigateBack() {
        const type = this.url.variation;
        switch (type) {
            case 'sections': history.back(); return;
            case 'confirmation': history.back(); return;
            case 'details': this.navigateToHelper({}, 'Home'); return;
            case 'rescheduling': this.navigateToHelper(this.postBookingUrlHelper('details')); return;
            case 'cancelation': this.navigateToHelper(this.postBookingUrlHelper('details')); return;
            case 'complete': this.navigateToHelper({}, 'Home'); return;
            default: history.back(); return;
        }
    }
    // slot selection UX/UI:
    handleSelectedTimeZone(event) {
        const detail = JSON.parse(JSON.stringify(event.detail.item));
        this.selectedTimeZone = detail;
        this.getTimeSlotsDataQuery();
    }
    handleSelectedCountry(event) {
        const detail = JSON.parse(JSON.stringify(event.detail.item));
        this.selectedCountry = detail;
        this.getTimeSlotsDataQuery();
    }
    handleSlotSelection(event) {
        const slotId = event.target.dataset.slotId;
        const slot = JSON.parse(event.target.dataset.raw);
        this.selectedSlot = slot;
        this._sections = this._sections.map(section => {
            const slots = section.slots.map(slot => {
                const active = (slot.Id===slotId);
                const className = `ia-slot ia-slot-booking ${active?'active':''}`;
                return Object.assign(slot, {active, className});
            });
            return Object.assign(section, {slots});
        });
    }
    handleConfirmSlotSelection() {
        this.navigateToHelper(this.confirmationURL);
    }
    // confirmation UX/UI:
    handleInputMessage(event) {
        const message = event.currentTarget?.value || '';
        this.confirmationMessage = message.trim();
    }
    handleAppointmentBooking(event) {
        this.bookAppointmentQuery();
    }
    // appointment details UX/UI:
    handleDetailsRescheduling(event) {
        const state = this.postBookingUrlHelper('rescheduling');
        this.navigateToHelper(state);
    }
    handleDetailsCancelation(event) {
        const state = this.postBookingUrlHelper('cancelation');
        this.navigateToHelper(state);
    }
    // rescheduling UX/UI:
    handleRescheduleCancel(event) {
        const state = this.postBookingUrlHelper('cancelation');
        this.navigateToHelper(state);
    }
    handleRescheduleGoBack(event) {
        const state = this.postBookingUrlHelper('details');
        this.navigateToHelper(state);
    }
    // cancelation UX/UI:
    handleCancelConfirm(event) {
        this.cancelAppointmentQuery();
    }
    handleCancelGoBack(event) {
        const state = this.postBookingUrlHelper('details');
        this.navigateToHelper(state);
    }
    // completed UX/UI:
    handleFindNewInsider() {
        this.navigateToHelper({}, 'Insiders__c');
    }


    // ===================================================
    // HELPERS:
    async initialisation() {
        const promise1 = this.getTimeSlotsDataQuery();
        const promise2 = this.getTimeZonesInfoQuery();
        const promise3 = this.getProfileInfoQuery();
        const promise4 = this.getCountriesInfoQuery();
        await promise1;
        await promise2;
        await promise3;
        await promise4;
        this.queryIsInAction=false;
    }
    postBookingUrlHelper(variation) {
        return {
            appointmentId: this.url.appointmentId,
            timestamp: this.url.timestamp,
            timezone: this.url.timezone,
            id: this.url.id,
            variation,
        };
    }
    navigateToHelper(state={}, name='IA_Booking__c') {
        const type = 'comm__namedPage';
        const attributes = { name };
        const payload = { type, attributes, state };
        this[NavigationMixin.Navigate](payload);
        setTimeout(() => {
            this.bookingVariation = this.url.variation;
        }, 100); // dirty hack for rendering of the page after URL change
    }
    navigateToErrorPage(title, message) {
        this.clear();
        const state = {title, message};
        this.navigateToHelper(state, 'Error');
    }
    clear() {
        this.selectedSlot = null;
        this._sections = [];
        this._profile = [];
    }


    // ===================================================
    // APEX INCORPARATION:
    async getProfileInfoQuery() {
        const payload = this.serviceResQueryPayload;
        this.queryIsInAction = true;
        this._profile = [];
        if (payload.serviceResourceId) {
            try {
                const result = this.devMode ? await getProfileMock() : await queryResult(payload);
                this._profile = result;
                setTimeout(()=> { this.queryIsInAction = false; });
                return {success: true};
            } catch (error) {
                console.error('ERROR | Ia_VolunteerBooking | getProfileInfoQuery:', error);
                const [title, message] = ['Booking: Profile Info','Not able to retrieve Profile Info'];
                this.isExperienceBuilder ? (this.queryIsInAction=false) : this.navigateToErrorPage(title, message);
                return {success: false};
            }
        } else {
            this._profile = [];
            return {success: false}
        }
    }
    async getTimeSlotsDataQuery() {
        const payload = this.timeSlotsQueryPayload;
        this.queryIsInAction = true;
        this.selectedSlot = null;
        this._sections = [];
        if (payload?.ServiceResourceId) {
            try {
                const result = this.devMode ? await getSectionsMock() : await getTimeSlots(payload);
                const timezone = this.selectedTimeZone.value;
                const sections = result.timesections;
                this._sections = formatBookingSlots(sections, timezone);
                this.queryIsInAction = false;
                return {success: true};
            } catch (error) {
                console.error('ERROR | Ia_VolunteerBooking | getTimeSlotsDataQuery:', error);
                const [title, message] = ['Booking: Time Slots', 'Not able to retrieve Slots Data'];
                this.isExperienceBuilder ? (this.queryIsInAction=false) : this.navigateToErrorPage(title, message);
                return {success: false};
            }
        } else {
            this._sections = [];
            return { success: false };
        }
    }
    async getTimeZonesInfoQuery() {
        // this.queryIsInAction = true;
        this._timezones = [];
        try {
            // NOTE: now hardcoded please replace to "customMetadata" or access from picklist
            // NOTE: request for the real data from the system rathern than "Promise.resolve([])" here
            const result = this.devMode ? await getTimeZonesMock() : await getTimeZones();
            //const result = await getTimeZonesMock();
            this._timezones = result;
            // this.queryIsInAction = false;
            return {success: true}
        } catch (error) {
            console.error('ERROR | Ia_VolunteerBooking | getTimeZonesInfoQuery:', error);
            const [title, message] = ['Booking: Time Zones', error.message];
            this.isExperienceBuilder ? (this.queryIsInAction=false) : this.navigateToErrorPage(title, message);
            return {success: false};
        }
    }

    //================================================================================================
    async getCountriesInfoQuery(){
        //NOTE: POC 
        this._countries = this.devMode ? await getCountriesMock() : await getCountries(); 
        console.log('this._countries: ', this._countries);
        // try {
        //     this._countries = this.devMode ? await getCountriesMock() : await getCountries(); 
        //     return {succes: true};   
        // } catch{
        //     console.error('ERROR | Ia_VolunteerBooking | getCountriesInfoQuery:', error);
        //     const [title, message] = ['Booking: Countries', error.message];
        //     this.isExperienceBuilder ? (this.queryIsInAction=false) : this.navigateToErrorPage(title, message);
        //     return {succes: false};   
        // }
    }

    //================================================================================================

    async bookAppointmentQuery() {
        this.queryIsInAction = true;
        try {
            const payload = this.createServiceAppointmentPayload;
            const result = this.devMode ? await createAppointmentMock() : await createServiceAppointment(payload);
            if (result.isSuccess) {
                const appointmentId = result.bookingAppointmentId;
                const variation = 'details';
                const timestamp = this.url.timestamp;
                const starttime = this.url.starttime*1;
                const timezone = this.url.timezone;
                const id = this.url.id;
                this.navigateToHelper({ appointmentId, id, variation, timestamp, timezone, starttime });
                this.queryIsInAction = false;
                return result;
            } else {
                throw new Error(result.message);
            }
        } catch (error) {
            console.error('ERROR | Ia_VolunteerBooking | bookAppointmentQuery:', error);
            const [title, message] = ['Booking: Appointment', error.message];
            this.isExperienceBuilder ? (this.queryIsInAction=false) : this.navigateToErrorPage(title, message);
            return {success: false};
        }
    }
    async cancelAppointmentQuery() {
        this.queryIsInAction = true;
        try {
            const payload = this.cancelAppointmentQueryPayload;
            const result = this.devMode ? await cancelAppointmentMock() : await cancelAppointments(payload);
            if (result.isSuccess) {
                this.navigateToHelper({ id:this.url.id, variation:'complete' });
                this.queryIsInAction = false;
                return result;
            } else {
                throw new Error(result.message);
            }
        } catch (error) {
            console.error('ERROR | Ia_VolunteerBooking | cancelAppointmentQuery:', error);
            const [title, message] = ['Booking: Cancelation', error.message];
            this.isExperienceBuilder ? (this.queryIsInAction=false) : this.navigateToErrorPage(title, message);
            return {success: false};
        }
    }
    async checkBookingStatus() {
        try {
            const details = await checkBookingStatus();
            const isBooked = (details?.isBooked);
            const state = isBooked ? generateBookedAppointmentURLPayload(details) : {};
            const name = isBooked ? 'IA_Booking__c' : 'Home';
            if (isBooked) {
                this.queryIsInAction=true;
                this.navigateToHelper(state, name);
                setTimeout(async() => { await this.initialisation(); }, 2000);
            }
        } catch (error) {
            console.error('error:', error);
        }
    }


    // ===================================================
    // EVENTS:
    // ...
}