public with sharing class CTPersonController {

    public static String getToken(String mobile){
        
        Blob targetBlob = Blob.valueOf(mobile);
        Blob hash = Crypto.generateDigest('MD5', targetBlob);
        String strHash = EncodingUtil.base64Encode(hash);
        return strHash;
    }

}
