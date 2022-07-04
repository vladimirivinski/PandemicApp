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
			WHERE Visit_Date__c = LAST_N_DAYS:10 AND Person__r.Id IN : personIds
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

	public static List<Location_Tracing__c> checkDuplicates(List<Location_Tracing__c> newLocationTraces) {
		//map of location id, set of person ids
		Map<Id, Set<Id>> mapExistingRecords = new Map<Id, Set<Id>>();
		// list of duplications
		List<Location_Tracing__c> duplicates = new List<Location_Tracing__c>();

		Set<Id> locationIds = new Set<Id>();
		Set<Id> personIds = new Set<Id>();

		for (Location_Tracing__c trace : newLocationTraces) {
			locationIds.add(trace.Location__c);
			personIds.add(trace.Person__c);
		}

		List<Location_Tracing__c> existingRecords = [
			SELECT Id, Person__c, Location__c
			FROM Location_Tracing__c
			WHERE Location__c IN :locationIds AND Person__c IN :personIds
			WITH SECURITY_ENFORCED
		];
		if (existingRecords != null && existingRecords.size() > 0) {
			for (Location_Tracing__c trace : existingRecords) {
				if (!mapExistingRecords.containsKey(trace.Location__c)) {
					mapExistingRecords.put(trace.Location__c, new Set<Id>());
				}
				// add person ids to map set
				mapExistingRecords.get(trace.Location__c).add(trace.Person__c);
			}
			for (Location_Tracing__c trace : newLocationTraces) {
				// check for location id
				// if item found in map, check for person in set
				if (
					mapExistingRecords.containsKey(trace.Location__c) &&
					mapExistingRecords.get(trace.Location__c).contains(trace.Person__c)
				) {
					duplicates.add(trace);
				}
			}
		}
		return duplicates;
	}
}
