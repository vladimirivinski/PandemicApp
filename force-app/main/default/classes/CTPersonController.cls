public with sharing class CTPersonController {
	
    public static String getToken(String mobile) {
		Blob targetBlob = Blob.valueOf(mobile);
		Blob hash = Crypto.generateDigest('MD5', targetBlob);
		String strHash = EncodingUtil.base64Encode(hash);
		return strHash;
	}

	public static List<Person__c> getRecentHealthChanges() {
		List<Person__c> personsList = [
			SELECT Id, Name, Mobile__c, Health_Status__c, Status_Update_Date__c, Token__c, CreatedDate, CreatedBy
			FROM Person__c
			WITH SECURITY_ENFORCED
			ORDER BY Status_Update_Date__c DESC
			LIMIT 100
		];
		return personsList;
	}

	public static List<Person__c> searchPeople(String searchTerm) {
		List<Person__c> matchPeople = [
			SELECT Id, Name, Mobile__c, Health_Status__c, Status_Update_Date__c, Token__c, CreatedDate, CreatedBy
			FROM Person__c
			WHERE Name = :searchTerm OR Mobile__c = :searchTerm OR Token__c = :searchTerm
			WITH SECURITY_ENFORCED
			ORDER BY Status_Update_Date__c DESC
		];
        return matchPeople;
	}

	public static Person__c getPersonById(String personId) {
		Person__c person = [
			SELECT Id, Name, Mobile__c, Health_Status__c, Status_Update_Date__c, Token__c, CreatedDate, CreatedBy
			FROM Person__c
            WHERE Id = :personId
            WITH SECURITY_ENFORCED
		];
        return person;
	}
}
