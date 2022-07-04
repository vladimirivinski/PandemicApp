public with sharing class CTLocationController {
	//Search Locations
	// @return List<Location__c>
	public static List<Location__c> getRecentStatusChanges() {
		return [
			SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status__c, Status_Update_Date__c
			FROM Location__c
			WITH SECURITY_ENFORCED
			ORDER BY Status_Update_Date__c DESC NULLS LAST
			LIMIT 100
		];
	}

	//Search Locations by Name, Pincode, Adress
	// @return List<Location__c>
	public static List<Location__c> searchLocations(String searchTerm) {
		searchTerm = searchTerm + '%';
		return [
			SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status__c, Status_Update_Date__c
			FROM Location__c
			WHERE Name LIKE :searchTerm OR Pincode__c LIKE :searchTerm OR Address__c LIKE :searchTerm
			WITH SECURITY_ENFORCED
			ORDER BY Status_Update_Date__c DESC
		];
	}

    // Search Location by Id
    // @return Location
	public static Location__c getLocationById (String locationId) {
		List<Location__c> location = [
			SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status__c, Status_Update_Date__c
			FROM Location__c
            WHERE Id = :locationId
            WITH SECURITY_ENFORCED
		];
		if (location != null && location.size() > 0) {
			return location[0];
		}
		return null;
	}
}
