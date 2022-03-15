public with sharing class CTLocationTracingController {
	public static List<Location_Tracing__c> getVisitors(String locationId) {
		return [
			SELECT
				Id,
				Person__c,
				Location__c,
				Visit_Date__c,
				Person__r.Status_Update_Date__c,
				Person__r.Token__c,
				Person__r.Health_Status__c
			FROM Location_Tracing__c
			WHERE Id = :locationId
			WITH SECURITY_ENFORCED
			ORDER BY Visit_Date__c DESC
		];
	}

	public static List<Location_Tracing__c> getLocationByPersonIds(Set<Id> personIds) {
		return [
			SELECT Id, Person__c, Location__c
			FROM Location_Tracing__c
			WHERE Visit_Date__c = LAST_N_DAYS:10 AND Person__r.Id IN :personIds
			WITH SECURITY_ENFORCED
		];
	}

	public static List<Location_Tracing__c> getLocationsByLocationIds(Set<Id> locationIds) {
		return [
			SELECT Id, Person__c, Location__c
			FROM Location_Tracing__c
			WHERE Location__c IN :locationIds AND Person__r.Health_Status__c = 'Green'
			WITH SECURITY_ENFORCED
		];
	}
}
