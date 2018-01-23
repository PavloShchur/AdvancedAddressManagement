public without sharing class RepairAddressService {

    private static final Set<Schema.SObjectField> ADDRESS_FIELDS_NEEDED_FOR_BATCH = new Set<Schema.SObjectField>{ Address__c.Account__c, Address__c.Hash__c, Address__c.LastModifiedDate };
    public static final String BATCH_ADDRESS_QUERY = 'SELECT ' + Utils.addFieldsToQuery( null, ADDRESS_FIELDS_NEEDED_FOR_BATCH ) + ' FROM Address__c WHERE Account__c != null AND Account__r.ParentId != null';

    List<Address__c> addresses;
    Map<Id, Id> accountIdToUltId; //account Id to its ultimate parent account Id
    Map<Id, Set<Id>> ultIdToAccountIds = new Map<Id, Set<Id>>(); //ultimate parent account id to all account ids in the hierarchy
    Map<Id, Map<String, List<Address__c>>> accIdToHashToAddresses; //holds info on which account has addresses having some hash - unique identifier of dupe addresses

    Map<Id, Id> addressIdToNewAddressId = new Map<Id, Id>(); //holds info for reparenting address mappings from old address to new one (and deletion of old address)

    List<Address__c> addressesToDelete = new List<Address__c>();
    List<Address__c> addressesToUpdate = new List<Address__c>();
    List<Address_Mapping__c> addressMappingsToUpdate = new List<Address_Mapping__c>();

	public RepairAddressService( List<Address__c> addresses ) {
        this.addresses = addresses;
	}

    public void start() {
        prepareData();
        reparentOrDeleteAddresses();
        reparentAddressMappings();
        saveAll();
    }

    private void prepareData() {
        this.accountIdToUltId = AccountHierarchyServices.getUltimateParentAccountIds( AccountServices.getAccountIds( this.addresses ) ); //account id to ultimate parent account id
        Set<Id> allHierarchyAccountIds = new Set<Id>(); //needed to query all addresses of all accounts
        Map<Id, HierarchyNode> ultIdToNodes = AccountHierarchyServices.getAccountHierarchies( new Set<Id>( this.accountIdToUltId.values() ) );
        for( Id ultId : ultIdToNodes.keySet() ) {
            Set<Id> hierarchyAccountIds = ultIdToNodes.get( ultId ).getAllHierarchyIds();
            this.ultIdToAccountIds.put( ultId, hierarchyAccountIds );
            allHierarchyAccountIds.addAll( hierarchyAccountIds );
        }
        this.accIdToHashToAddresses = AddressServices.getAccountIdToHashToAddresses( AddressServices.getAddressesByAccountIdsAndHashes( allHierarchyAccountIds, AddressServices.getAddressHashes( addresses ), ADDRESS_FIELDS_NEEDED_FOR_BATCH ) ); //account Id to hash to list of addresses having that hash
    }

    private void reparentOrDeleteAddresses() {
        for( Address__c addressItem : addresses ) {
            Id ultId = this.accountIdToUltId.get( addressItem.Account__c );
            if( addressItem.Account__c == ultId ) continue; //no need to do anything with address that's already on top
            String hash = addressItem.Hash__c;
            List<Address__c> dupeAddressesOnTop = getDupeAddressesOnTop( ultId, hash ); //get dupes on top of hierarchy
            if( !dupeAddressesOnTop.isEmpty() ) { //there is a dupe address on top of hierarchy
                this.addressIdToNewAddressId.put( addressItem.Id, dupeAddressesOnTop[0].Id ); //mark addres mappings for reparenting and address for deletion
            } else { //no dupes on top of hierarchy
                List<Address__c> dupeAddresses = getDupeAddresses( ultId, hash, addressItem.Id ); //list of addresses with same hash minus current address
                if( dupeAddresses.isEmpty() ) { //no other dupe addresses in the hierarchy
                    reparentAddressToTopOfHierarchy( ultId, hash, addressItem ); //move this address to the top of hierarchy
                } else { //there are other addresses in the hierarchy
                    Id latestAddressId = AddressServices.findAddressWithLatestLmd( addressItem, dupeAddresses );
                    if( latestAddressId == addressItem.Id ) { //if current dupe address is latest
                        reparentAddressToTopOfHierarchy( ultId, hash, addressItem ); //move this address to the top of hierarchy
                    } else { //if other dupe address is latest
                        this.addressIdToNewAddressId.put( addressItem.Id, latestAddressId ); //mark address for deletion and its addres mappings for reparenting to top dupe address
                    }
                }
            }
        }
    }

    private void reparentAddressMappings() {
        Map<Id, List<Address_Mapping__c>> addressIdToAddressMappings = AccountServices.getAddressIdToAddressMappings( this.addressIdToNewAddressId.keySet() ); //address Id to related address mappings
        for( Id addressId : this.addressIdToNewAddressId.keySet() ) {
            reparentAddressMappings( addressIdToAddressMappings.get( addressId ), this.addressIdToNewAddressId.get( addressId ) ); //reparent address mappings to new address
            deleteAddress( addressId ); //delete address with addressId since AMs were reparented to a new address
        }
    }

    private void saveAll() {
        UPDATE this.addressesToUpdate;
        UPDATE this.addressMappingsToUpdate;
        DELETE this.addressesToDelete;
    }

    private List<Address__c> getDupeAddressesOnTop( Id ultId, String hash ) {
        Map<String, List<Address__c>> hashToAddresses = this.accIdToHashToAddresses.get( ultId );
        if( hashToAddresses == null ) return new List<Address__c>();
        List<Address__c> addresses = hashToAddresses.get( hash );
        if( addresses == null ) return new List<Address__c>();
        return addresses;
    }

    private List<Address__c> getDupeAddresses( Id ultId, String hash, Id addressIdToExclude ) {
        List<Address__c> result = new List<Address__c>();
        for( Id accId : this.ultIdToAccountIds.get( ultId ) ) {
            Map<String, List<Address__c>> hashToAddresses = this.accIdToHashToAddresses.get( accId );
            if( hashToAddresses == null ) continue;
            List<Address__c> addresses = hashToAddresses.get( hash );
            if( addresses == null ) continue;
            Map<Id, Address__c> addressIdToAddress = new Map<Id, Address__c>( addresses );
            addressIdToAddress.remove( addressIdToExclude );
            result.addAll( addressIdToAddress.values() );
        }
        return result;
    }

    private void reparentAddressToTopOfHierarchy( Id ultId, String hash, Address__c addressItem ) {
        addressItem.Account__c = ultId; //reparent address to top account
        this.addressesToUpdate.add( addressItem );
        registerNewAddressOnTopOfHierarchy( ultId, hash, addressItem ); //modify maps for next iterations to see this address as being on top of hierarchy
    }

    private void registerNewAddressOnTopOfHierarchy( Id ultId, String hash, Address__c addressItem ) {
        Map<String, List<Address__c>> hashToAddressesOnTop = this.accIdToHashToAddresses.get( ultId );
        if( hashToAddressesOnTop == null ) {
            hashToAddressesOnTop = new Map<String, List<Address__c>>();
            this.accIdToHashToAddresses.put( ultId, hashToAddressesOnTop );
        }
        if( hashToAddressesOnTop.get( hash ) == null ) hashToAddressesOnTop.put( hash, new List<Address__c>() );
        hashToAddressesOnTop.get( hash ).add( addressItem );
    }

    private void reparentAddressMappings( List<Address_Mapping__c> addressMappings, Id newAddressId ) {
        if( addressMappings == null ) return;
        for( Address_Mapping__c addressMapping : addressMappings ) {
            addressMapping.Address__c = newAddressId;
            this.addressMappingsToUpdate.add( addressMapping );
        }
    }

    private void deleteAddress( Id oldAddressId ) {
        this.addressesToDelete.add( new Address__c( Id = oldAddressId ) );
    }

}