public without sharing class AccountServices {

    public static final String BILLING_ADDRESS = 'Billing';
    public static final String SHIPPING_ADDRESS = 'Shipping';

    public static Set<Id> getAccountIds( List<Address__c> addresses ) {
        Set<Id> accountIds = new Set<Id>();
        for( Address__c addressItem : addresses ) {
            accountIds.add( addressItem.Account__c );
        }
        return accountIds;
    }

    // + 05/05/2017 added in scope of GW-159; modified for SF selectivity issues workaround for 200K records and huge hierarchy containing 20K+ records
    // * 30/08/2017 modified by chris chen
    public static Map<Id, List<Address_Mapping__c>> getAddressIdToAddressMappings( Set<Id> addressIds ) {
        Map<Id, List<Address_Mapping__c>> accountIdToAddressMappings = new Map<Id, List<Address_Mapping__c>>();
        if( addressIds == null ) return accountIdToAddressMappings;
        addressIds.remove( null );
        if( addressIds.isEmpty() ) return accountIdToAddressMappings;

        Set<Id> addressIdsClone = new Set<Id>();
        addressIdsClone = addressIds.clone();

        Integer BatchCount = 2;
        if (Utils.aamSettings.Address_Query_Batch_Count__c != null
            && (Integer)Utils.aamSettings.Address_Query_Batch_Count__c > 0 ){
            BatchCount = (Integer)Utils.aamSettings.Address_Query_Batch_Count__c;
        }
        if (addressIds.size() < BatchCount){
             BatchCount = 1;
        }

        Integer numberOfOneBatch  = addressIds.Size()/BatchCount;
        if (BatchCount > 1 && math.mod(addressIds.Size(), BatchCount) > 0) BatchCount = BatchCount + 1;


        for (Integer i = 0; i < BatchCount; i++){
            Integer icount = 0;
            Set<Id> tempAddressIds = new Set<Id>();

            for (Id aid : addressIdsClone){
                if (icount < numberOfOneBatch) {
                    tempAddressIds.add(aid);
                    addressIdsClone.remove(aid);
                    icount++;
                }

            }
            if (tempAddressIds.size() > 0){
                addRecordsToAccountIdToAddressMappings( accountIdToAddressMappings, [ SELECT FIL_AAM__Address__c, FIL_AAM__Account__c, FIL_AAM__Contact__r.AccountId
                                                                                      FROM FIL_AAM__Address_Mapping__c
                                                                                      WHERE FIL_AAM__Address__c IN :tempAddressIds
                                                                                        AND ((FIL_AAM__Account__c != null AND FIL_AAM__Contact__c = null) OR (FIL_AAM__Account__c = null AND FIL_AAM__Contact__c != null))
                                                                                        AND IsDeleted = false ] );
            }
        }
        return accountIdToAddressMappings;
    }

    private static void addRecordsToAccountIdToAddressMappings( Map<Id, List<Address_Mapping__c>> accountIdToAddressMappings, List<Address_Mapping__c> addressMappings ) {
        for( Address_Mapping__c addressMapping : addressMappings ) {
            if( !accountIdToAddressMappings.containsKey( addressMapping.Address__c ) ) {
                accountIdToAddressMappings.put( addressMapping.Address__c, new List<Address_Mapping__c>() );
            }
            accountIdToAddressMappings.get( addressMapping.Address__c ).add( addressMapping );
        }
    }

    public static List<Account> findAccounts( String accountName ) {
        List<Account> result = new List<Account>();
        if( String.isEmpty( accountName ) ) return result;
        String query = 'SELECT Name ' +
                       'FROM Account ' +
                       'WHERE Name LIKE \'%' + String.escapeSingleQuotes( accountName ) + '%\' ' +
                       'ORDER BY Name ' +
                       'LIMIT 10000';
        List<Account> startsWith = new List<Account>();
        List<Account> other = new List<Account>();
        for( Account account : Database.query( query ) ) {
            if( account.Name.startsWithIgnoreCase( accountName ) ) {
                startsWith.add( account );
            } else {
                other.add( account );
            }
        }
        result.addAll( startsWith );
        result.addAll( other );
        return result;
    }

}