public with sharing class CTPersonController {
	public static String getToken(String mobile) {
		Blob targetBlob = Blob.valueOf(mobile);
		Blob hash = Crypto.generateDigest('MD5', targetBlob);
		String strHash = EncodingUtil.base64Encode(hash);
		return strHash;
	}

	public static List<Person__c> getRecentHealthChanges() {
		return [
			SELECT Id, Name, Mobile__c, Health_Status__c, Status_Update_Date__c, Token__c
			FROM Person__c
			WITH SECURITY_ENFORCED
			ORDER BY Status_Update_Date__c DESC NULLS LAST
			LIMIT 100
		];
	}

	public static List<Person__c> searchPeople(String searchTerm) {
		searchTerm = searchTerm + '%';
		List<Person__c> matchPeople = [
			SELECT Id, Name, Mobile__c, Health_Status__c, Status_Update_Date__c, Token__c
			FROM Person__c
			WHERE Name LIKE :searchTerm OR Mobile__c LIKE :searchTerm OR Token__c LIKE :searchTerm
			WITH SECURITY_ENFORCED
			ORDER BY Status_Update_Date__c DESC NULLS LAST
		];
		return matchPeople;
	}

	public static Person__c getPersonById(String personId) {
		List<Person__c> person = [
			SELECT Id, Name, Mobile__c, Health_Status__c, Status_Update_Date__c, Token__c
			FROM Person__c
			WHERE Id = :personId
			WITH SECURITY_ENFORCED
		];
		if (person == null & person.size() > 0) {
			return person[0];
		}
		return null;
	}
}
