public without sharing class RepairAddressMappingsService {

    private static final Set<Schema.SObjectField> ADDRESS_FIELDS_NEEDED_FOR_BATCH = new Set<Schema.SObjectField>{ Address__c.Account__c, Address__c.Hash__c };
    public static final String BATCH_ADDRESS_QUERY = 'SELECT Address__c, Address__r.Account__c, Address__r.Hash__c,' +
                                                           ' Account__c, Contact__c, Contact__r.AccountId' +
                                                    ' FROM Address_Mapping__c' +
                                                    ' WHERE Address__r.Account__c != null';

    List<Address_Mapping__c> mappings;
    Map<Id, Id> accountIdToUltId; //account Id to its ultimate parent account Id
    //Map<Id, Set<Id>> ultIdToAccountIds = new Map<Id, Set<Id>>(); //ultimate parent account id to all account ids in the hierarchy
    Map<Id, Map<String, List<Address__c>>> ultIdToHashToAddresses; //holds info on which account has addresses having some hash - unique identifier of dupe addresses

    List<Address_Mapping__c> mappingsToDelete = new List<Address_Mapping__c>();
    List<Address_Mapping__c> mappingsToUpdate = new List<Address_Mapping__c>();
    Map<Id, Map<Id, List<Address_Mapping__c>>> ultIdToAddressIdToAddressMappings = new Map<Id, Map<Id, List<Address_Mapping__c>>>(); //address mapping that need to be reparented to new address with ultId from old addresses with AddressId
    Map<Id, Address__c> oldAddressIdToNewAddress = new Map<Id, Address__c>();

	public RepairAddressMappingsService( List<Address_Mapping__c> mappings ) {
		this.mappings = mappings;
	}

    public void start() {
        deleteOrphanedMappings();
        prepareData();
        reparentMappingsOrMarkForAddressCreation();
        createNewAddresses();
        reparentMappingsToNewAddresses();
        saveAll();
    }

    private void deleteOrphanedMappings() {
        if( mappings.isEmpty() ) return;
        for( Integer i = mappings.size() - 1; i >= 0; i-- ) {
            Address_Mapping__c mapping = mappings[i];
            if( mapping.Account__c != null || mapping.Contact__c != null ) continue;
            mappingsToDelete.add( mapping );
            mappings.remove( i );
        }
    }

    private void prepareData() {
        Set<Id> allAccountIds = new Set<Id>(); //all account ids mentioned in AM (AM.Address.Account, plus AM.Account or AM.Contact.Account)
        Set<Id> mappingAccountIds = new Set<Id>(); //only mapping's account ids mentioned in AMs (AM.Address.Account)
        for( Address_Mapping__c mapping : this.mappings ) {
            allAccountIds.add( mapping.Account__c );
            allAccountIds.add( mapping.Contact__r.AccountId );
            mappingAccountIds.add( mapping.Address__r.Account__c );
        }
        allAccountIds.addAll( mappingAccountIds );
        allAccountIds.remove( null );
        mappingAccountIds.remove( null );

        this.accountIdToUltId = AccountHierarchyServices.getUltimateParentAccountIds( allAccountIds ); //account id to ultimate parent account id for all accounts mentioned

        Set<Id> mappingUltAccountIds = new Set<Id>(); //account Ids of mapping's Accounts to AMs (it can be different, since Account is moved together with AM to a new Account Hierarchy, but related AM's Account's address stays in old hierarchy)
        for( Id mappingAccountId : mappingAccountIds ) {
            mappingUltAccountIds.add( this.accountIdToUltId.get( mappingAccountId ) ); //topmost AccountIds of Accounts related to AMs
        }

        /*Set<Id> allHierarchyAccountIds = new Set<Id>(); //is needed for querying addresses of all accounts in hierarchies of related accounts of AMs
        Map<Id, HierarchyNode> ultIdToNodes = AccountHierarchyServices.getAccountHierarchies( mappingUltAccountIds ); //hierarchies of AM's account ids (needed for getting addresses)
        for( Id ultId : ultIdToNodes.keySet() ) {
            Set<Id> hierarchyAccountIds = ultIdToNodes.get( ultId ).getAllHierarchyIds();
            this.ultIdToAccountIds.put( ultId, hierarchyAccountIds );
            allHierarchyAccountIds.addAll( hierarchyAccountIds );
        }
        this.ultIdToHashToAddresses = AddressServices.getUltAccountIdToHashToAddresses( AddressServices.getAddressesByAccountIdsAndHashes( allHierarchyAccountIds, AddressServices.getAddressHashes( mappings ), ADDRESS_FIELDS_NEEDED_FOR_BATCH ), accountIdToUltId ); //ult Account Id to hash to list of addresses having that hash*/

        //after the firat batch we can assume that all addresses are at the top of hierarchy, so no other accounts that are lower are needed
        this.ultIdToHashToAddresses = AddressServices.getUltAccountIdToHashToAddresses( AddressServices.getAddressesByAccountIdsAndHashes( mappingUltAccountIds, AddressServices.getAddressHashes( mappings ), ADDRESS_FIELDS_NEEDED_FOR_BATCH ), accountIdToUltId ); //ult Account Id to hash to list of addresses having that hash
    }

    private void reparentMappingsOrMarkForAddressCreation() {
        for( Address_Mapping__c mapping : this.mappings ) {
            Id relatedAccountId = getRelatedAccountId( mapping );
            if( this.accountIdToUltId.get( mapping.Address__r.Account__c ) == this.accountIdToUltId.get( relatedAccountId ) ) continue; //skip if AM is related to account in the same hierarchy as its address' account
            String hash = mapping.Address__r.Hash__c;
            Id ultId = this.accountIdToUltId.get( relatedAccountId );
            List<Address__c> dupeAddresses = getDupeAddresses( ultId, hash ); //list of addresses with same hash
            if( !dupeAddresses.isEmpty() ) { //there is a dupe address in hierarchy of related Account
                updateMappingAddress( mapping, dupeAddresses[0].Id );
            } else { //no dupe address in hierarchy of related Account
                addMappingForAddressCreation( mapping, ultId );
            }
        }
    }

    private void createNewAddresses() {
        Set<Id> addressIdsToClone = this.oldAddressIdToNewAddress.keySet();
        String query = 'SELECT ' + Utils.addFieldsToQuery( null, AddressServices.CLONE_ADDRESS_FIELDS );
        query += ' FROM Address__c';
        query += ' WHERE Id IN :addressIdsToClone';
        Map<Id, Address__c> addressIdToAddress = new Map<Id, Address__c>( (List<Address__c>)Database.query( query ) );

        List<Address__c> addressesToCreate = new List<Address__c>();
        for( Id ultId : this.ultIdToAddressIdToAddressMappings.keySet() ) {
            Map<Id, List<Address_Mapping__c>> addressIdToAddressMappings = this.ultIdToAddressIdToAddressMappings.get( ultId );
            for( Id oldAddressId : addressIdToAddressMappings.keySet() ) {
                Address__c oldAddress = addressIdToAddress.get( oldAddressId );
                Address__c clonedAddress = oldAddress.clone( false );
                clonedAddress.Account__c = ultId;
                addressesToCreate.add( clonedAddress );
                this.oldAddressIdToNewAddress.put( oldAddressId, clonedAddress );
            }
        }
        AddressServices.preventAddressReparentingToUltAccountOnInsert = true;
        INSERT addressesToCreate;
        AddressServices.preventAddressReparentingToUltAccountOnInsert = false;
    }

    private void reparentMappingsToNewAddresses() {
        for( Id ultId : this.ultIdToAddressIdToAddressMappings.keySet() ) {
            Map<Id, List<Address_Mapping__c>> addressIdToAddressMappings = this.ultIdToAddressIdToAddressMappings.get( ultId );
            for( Id oldAddressId : addressIdToAddressMappings.keySet() ) {
                for( Address_Mapping__c mapping : addressIdToAddressMappings.get( oldAddressId ) ) {
                    updateMappingAddress( mapping, this.oldAddressIdToNewAddress.get( oldAddressId ).Id );
                }
            }
        }
    }

    private void saveAll() {
        DELETE this.mappingsToDelete;
        UPDATE this.mappingsToUpdate;
    }

    private void updateMappingAddress( Address_Mapping__c mapping, Id ultId ) {
        mapping.Address__c = ultId;
        this.mappingsToUpdate.add( mapping );
    }

    private void addMappingForAddressCreation( Address_Mapping__c mapping, Id ultId ) {
        Id oldAddressId = mapping.Address__c;
        this.oldAddressIdToNewAddress.put( oldAddressId, null );
        if( this.ultIdToAddressIdToAddressMappings.get( ultId ) == null ) this.ultIdToAddressIdToAddressMappings.put( ultId, new Map<Id, List<Address_Mapping__c>>() );
        Map<Id, List<Address_Mapping__c>> addressIdToAddressMappings = this.ultIdToAddressIdToAddressMappings.get( ultId );
        if( addressIdToAddressMappings.get( oldAddressId ) == null ) addressIdToAddressMappings.put( oldAddressId, new List<Address_Mapping__c>() );
        this.ultIdToAddressIdToAddressMappings.get( ultId ).get( oldAddressId ).add( mapping );
    }

    private List<Address__c> getDupeAddresses( Id ultId, String hash ) {
        List<Address__c> result = new List<Address__c>();
        Map<String, List<Address__c>> hashToAddresses = this.ultIdToHashToAddresses.get( ultId );
        if( hashToAddresses == null ) return result;
        List<Address__c> addresses = hashToAddresses.get( hash );
        if( addresses == null ) return result;
        result.addAll( addresses );
        return result;
    }

    private static Id getRelatedAccountId( Address_Mapping__c mapping ) {
        return mapping.Account__c != null ? mapping.Account__c : mapping.Contact__r.AccountId;
    }

}