public without sharing class AddressMappingServices {

    public static final String ADDRESS_TYPE_BILLING_ADDRESS = 'Billing Address';
    public static final String ADDRESS_TYPE_SHIPPING_ADDRESS = 'Shipping Address';
    public static final String ADDRESS_TYPE_MAILING_ADDRESS = 'Mailing Address';
    public static final String ADDRESS_TYPE_OTHER_ADDRESS = 'Other Address';
    public static final String ADDRESS_TYPE_VISITING_ADDRESS = 'Visiting Address';

    public static final String ADDRESS_REFERENCE_FIELD = 'Address__r';
    public static final String ADDRESS_MAPPING_ACTIVE_COUNT_FIELD_NAME = 'Address_Mappings_Active_Count__c';

    public static List<Address_Mapping__c> filterInactiveRecords( List<Address_Mapping__c> newList, Map<Id, Address_Mapping__c> oldMap ) {
        List<Address_Mapping__c> filteredRecords = new List<Address_Mapping__c>();
        for( Address_Mapping__c addressMappingItem : newList ) {
            if( addressMappingItem.Active__c ) continue;
            if( oldMap == null || addressMappingItem.Active__c != oldMap.get( addressMappingItem.Id ).Active__c ) {
                filteredRecords.add( addressMappingItem );
            }
        }
        return filteredRecords;
    }

    public static void updateRemovedFields( List<Address_Mapping__c> addresses ) {
        for( Address_Mapping__c addressMappingItem : addresses ) {
            addressMappingItem.Removed_Date__c = Date.today();
            addressMappingItem.Removed_By__c = UserInfo.getUserId();
        }
    }

    public static String getAddress( Address_Mapping__c record ) {
        if( record == null ) return '';
        String address = Utils.joinFieldValues(
            record,
            new List<Schema.SObjectField>{ Address_Mapping__c.Address_Line_1__c,
                                           Address_Mapping__c.Address_Line_2__c,
                                           Address_Mapping__c.City__c,
                                           Address_Mapping__c.State_County__c,
                                           Address_Mapping__c.Postcode__c }
        );
        List<String> addressParts = new List<String>{ address };
        String countryName = CountryServices.countryIsoCodeToName.get( record.Country__c ) != null
                             ? CountryServices.countryIsoCodeToName.get( record.Country__c )
                             : record.Country__c;
        Utils.addAddressPart( countryName, addressParts );
        return String.join( addressParts, ', ' );
    }

    public static Address_Mapping__c getAddressMappingRecord( Id addressMappingId, List<Schema.FieldSetMember> fields, List<Schema.SObjectField> additionalFields ) {
        Address_Mapping__c result = new Address_Mapping__c();
        if( addressMappingId == null ) return result;
        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               fields,
                                               Utils.addFieldsToList( null, additionalFields )
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Address_Mapping__c ';
        query += 'WHERE Id = \'' + addressMappingId + '\' ';
        List<Address_Mapping__c> addressesFound = Database.query( query );
        if( !addressesFound.isEmpty() ) {
            result = addressesFound[0];
        }
        return result;
    }

    public static List<Address_Mapping__c> getAddressMappingRecords( Address__c addressRecord, Address_Mapping__c addressMappingRecord, List<Schema.FieldSetMember> fields, List<Schema.SObjectField> additionalFields ) {
        List<Address_Mapping__c> result = new List<Address_Mapping__c>();
        if( addressRecord == null || addressRecord.Id == null || addressMappingRecord == null ) return result;
        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               fields,
                                               Utils.addFieldsToList( null, additionalFields )
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Address_Mapping__c ';
        query += 'WHERE Contact__c != null ';
        query +=   'AND Address__c = \'' + addressRecord.Id + '\'';
        query +=   'AND Active__c = true ';
        query +=   'AND Address_Type__c = \'' + addressMappingRecord.Address_Type__c + '\'';
        result = Database.query( query );
        return result;
    }

    public static void deactivateAddressMappings( Set<Id> mappingIds ) {
        if( mappingIds == null ) return;
        List<Address_Mapping__c> mappings = new List<Address_Mapping__c>();
        for( Id mappingId : mappingIds ) {
            mappings.add( new Address_Mapping__c( Id = mappingId, Active__c = false/*,
                                                  Removed_By__c = UserInfo.getUserId(), //done in trigger
                                                  Removed_Date__c = Date.today() //done in trigger*/ ) );
        }
        UPDATE mappings;
    }

    public static Map<String, Map<Datetime, List<Address_Mapping__c>>> filterPrimaryRecordsByDate( List<Address_Mapping__c> newAddresses, Map<Id, Address_Mapping__c> oldAddresses ) {
        Map<String, Map<Datetime, List<Address_Mapping__c>>> keyToDateToAddresses = new Map<String, Map<Datetime, List<Address_Mapping__c>>>();
        Datetime currentTime = Datetime.now();
        for( Address_Mapping__c address : newAddresses ) {
            if( !isPrimaryRecord( address, oldAddresses ) ) continue;
            String key = address.Address_Type__c + address.Contact__c + address.Account__c;
            if( keyToDateToAddresses.get( key ) == null ) {
                keyToDateToAddresses.put( key, new Map<Datetime, List<Address_Mapping__c>>() );
            }
            Map<Datetime, List<Address_Mapping__c>> dateToAddresses = keyToDateToAddresses.get( key );
            Datetime createdDate = oldAddresses == null ? currentTime : address.CreatedDate;
            if( dateToAddresses.get( createdDate ) == null ) {
                dateToAddresses.put( createdDate, new List<Address_Mapping__c>() );
            }
            dateToAddresses.get( createdDate ).add( address );
        }
        return keyToDateToAddresses;
    }

    public static void unsetPrimaryForNewerAddresses( Map<String, Map<Datetime, List<Address_Mapping__c>>> keyToDateToAddresses ) {
        for( Map<Datetime, List<Address_Mapping__c>> dateToAddresses : keyToDateToAddresses.values() ) {
            List<Datetime> dateTimesSorted = new List<Datetime>( dateToAddresses.keySet() );
            dateTimesSorted.sort();
            Boolean firstElementAlreadySkipped = false;
            for( Integer i = 0; i < dateTimesSorted.size(); i++ ) {
                for( Address_Mapping__c address : dateToAddresses.get( dateTimesSorted[i] ) ) {
                    if( firstElementAlreadySkipped ) {
                        address.Primary__c = false;
                    } else {
                        firstElementAlreadySkipped = true;
                    }
                }
            }
        }
    }

    public static void setPrimaryAddressesIfNoOtherPrimaryExists(List<Address_Mapping__c> addressMappings){
        if ( addressMappings.isEmpty() ){
            return;
        }
        Set<String> existingPrimaryMappingsKeys = getUniqueKeyToMapping( selectExistingPrimaryMappings( addressMappings ) ).keySet();
        for (Address_Mapping__c mapping : addressMappings){
            if ( !existingPrimaryMappingsKeys.contains( getAddressMappingKey(mapping) ) ){
                mapping.Primary__c = true;
            }
        }
    }

    private static List<Address_Mapping__c> selectExistingPrimaryMappings(List<Address_Mapping__c> mappings){
        Set<String> addressTypes = Utils.getStringFieldValues( mappings, Address_Mapping__c.Address_Type__c );
        addressTypes.remove( null );
        Set<String> accountIds = Utils.getStringFieldValues( mappings, Address_Mapping__c.Account__c );
        accountIds.remove( null );
        Set<String> contactIds = Utils.getStringFieldValues( mappings, Address_Mapping__c.Contact__c );
        contactIds.remove( null );
        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>();
        addressMappings.addAll( [ SELECT Address_Type__c, Account__c, Contact__c
                                  FROM Address_Mapping__c
                                  WHERE Primary__c = true
                                    AND Active__c = true
                                    AND Address_Type__c IN :addressTypes
                                    AND Contact__c = null
                                    AND Account__c IN :accountIds
                                    AND Id NOT IN :mappings ] );
        addressMappings.addAll( [ SELECT Address_Type__c, Account__c, Contact__c
                                  FROM Address_Mapping__c
                                  WHERE Primary__c = true
                                    AND Active__c = true
                                    AND Address_Type__c IN :addressTypes
                                    AND Account__c = null
                                    AND Contact__c IN :contactIds
                                    AND Id NOT IN :mappings ] );
        return addressMappings;
    }

    public static List<Address_Mapping__c> filterNotPrimaryMappings(List<Address_Mapping__c> newMappings){
        Set<String> addressesWithPrimaryMappings = new Set<String>();
        Map<String, Address_Mapping__c> filteredAddressToMapping = new Map<String, Address_Mapping__c>();
        for ( Address_Mapping__c mapping : newMappings ){
            if (!mapping.Active__c){
                continue;
            }
            String key = getAddressMappingKey(mapping);
            if (mapping.Primary__c){
                addressesWithPrimaryMappings.add( key );
            }
            if ( addressesWithPrimaryMappings.contains( key ) ){
                continue;
            }
            Address_Mapping__c existingMapping = filteredAddressToMapping.get(key);
            if ( isMappingOlder(mapping, existingMapping) ){
                filteredAddressToMapping.put(key, mapping);
            }
        }
        return filteredAddressToMapping.values();
    }

    private static String getAddressMappingKey(Address_Mapping__c mapping){
        return Utils.createStringKey(mapping, new Set<Schema.SObjectField>{
            Address_Mapping__c.Address_Type__c,
            Address_Mapping__c.Account__c,
            Address_Mapping__c.Contact__c
        });
    }

    private static Boolean isMappingOlder(Address_Mapping__c mapping, Address_Mapping__c existingMapping){
        return existingMapping == null || Utils.getCreatedDate(mapping) < Utils.getCreatedDate(existingMapping);
    }

    public static List<Address_Mapping__c> filterDeactivatedPrimaryMappings(List<Address_Mapping__c> newAddresses, Map<Id, Address_Mapping__c> oldAddresses){
        List<Address_Mapping__c> deactivatedPrimaryMappings = new List<Address_Mapping__c>();
        for (Address_Mapping__c newMapping : newAddresses){
            if (newMapping.Active__c){
                continue;
            }
            Address_Mapping__c oldMapping = oldAddresses.get(newMapping.Id);
            if (oldMapping.Active__c && oldMapping.Primary__c){
                deactivatedPrimaryMappings.add(newMapping);
            }
        }
        return deactivatedPrimaryMappings;
    }

    public static void setPrimaryToAnotherAddressAtDeactivation(List<Address_Mapping__c> mappings){
        if ( mappings.isEmpty() ){
            return;
        }
        Map<String, Address_Mapping__c> uniqueKeyToMapping = getUniqueKeyToMapping( selectOtherActiveMappings(mappings) );
        for (Address_Mapping__c mapping : mappings){
            String key = getAddressMappingKey(mapping);
            if ( uniqueKeyToMapping.containsKey(key) ){
                uniqueKeyToMapping.get(key).Primary__c = true;
            }
        }
        update uniqueKeyToMapping.values();
    }

    private static Map<String, Address_Mapping__c> getUniqueKeyToMapping(List<Address_Mapping__c> mappings){
        Map<String, Address_Mapping__c> uniqueKeyToMapping = new Map<String, Address_Mapping__c>();
        for (Address_Mapping__c mapping : mappings){
            String key = getAddressMappingKey(mapping);
            uniqueKeyToMapping.put(key, mapping);
        }
        return uniqueKeyToMapping;
    }

    private static List<Address_Mapping__c> selectOtherActiveMappings(List<Address_Mapping__c> mappings){
        Set<String> addressTypes = Utils.getStringFieldValues( mappings, Address_Mapping__c.Address_Type__c );
        addressTypes.remove( null );
        Set<String> accountIds = Utils.getStringFieldValues( mappings, Address_Mapping__c.Account__c );
        accountIds.remove( null );
        Set<String> contactIds = Utils.getStringFieldValues( mappings, Address_Mapping__c.Contact__c );
        contactIds.remove( null );
        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>();
        addressMappings.addAll( [ SELECT Address_Type__c, Account__c, Contact__c
                                  FROM Address_Mapping__c
                                  WHERE Active__c = true
                                    AND Address_Type__c IN :addressTypes
                                    AND Contact__c = null
                                    AND Account__c IN :accountIds
                                    AND Id NOT IN :mappings
                                  ORDER BY CreatedDate DESC ] );
        addressMappings.addAll( [ SELECT Address_Type__c, Account__c, Contact__c
                                  FROM Address_Mapping__c
                                  WHERE Active__c = true
                                    AND Address_Type__c IN :addressTypes
                                    AND Account__c = null
                                    AND Contact__c IN :contactIds
                                    AND Id NOT IN :mappings
                                  ORDER BY CreatedDate DESC ] );
        return addressMappings;
    }

    public static List<Address_Mapping__c> filterPrimaryRecords( List<Address_Mapping__c> newAddresses, Map<Id, Address_Mapping__c> oldAddresses ) {
        List<Address_Mapping__c> result = new List<Address_Mapping__c>();
        for( Address_Mapping__c address : newAddresses ) {
            if( !isPrimaryRecord( address, oldAddresses ) ) continue;
            result.add( address );
        }
        return result;
    }

    public static Boolean isPrimaryRecord( Address_Mapping__c address, Map<Id, Address_Mapping__c> oldAddresses ) {
        return address.Primary__c &&
               ( address.Contact__c != null || address.Account__c != null ) &&
               ( oldAddresses == null || oldAddresses.get( address.Id ).Primary__c != address.Primary__c );
    }

    public static void resetPrimaryForOldAddresses( List<Address_Mapping__c> filteredAddresses ) {
        if( filteredAddresses.isEmpty() ) return;
        Set<Id> excludedRecordIds = new Map<Id, Address_Mapping__c>( filteredAddresses ).keySet();
        String query = 'SELECT Primary__c FROM Address_Mapping__c ';
        query +=       'WHERE Primary__c = true';
        query +=        ' AND Id NOT IN :excludedRecordIds';
        query +=        ' AND ( ';
        List<String> whereq = new List<String>();
        for( Address_Mapping__c address : filteredAddresses ) {
            if( address.Contact__c != null ) {
                whereq.add( '( Contact__c = \'' + address.Contact__c + '\' AND Address_Type__c = \'' + address.Address_Type__c + '\' )' );
            } else if( address.Account__c != null ) {
                whereq.add( '( Account__c = \'' + address.Account__c + '\' AND Address_Type__c = \'' + address.Address_Type__c + '\' )' );
            }
        }
        if( whereq.isEmpty() ) return;
        query += String.join( whereq, ' OR ' );
        query += ' )';
        List<Address_Mapping__c> addressesInDb = Database.query( query );
        for( Address_Mapping__c address : addressesInDb ) {
            address.Primary__c = false;
        }
        UPDATE addressesInDb;
    }

    public static List<Address_Mapping__c> filterChangedAddressMappings( List<Address_Mapping__c> newAddresses, Map<Id, Address_Mapping__c> oldAddresses ) {
        List<Address_Mapping__c> result = new List<Address_Mapping__c>();
        if( Utils.aamSettings.Disable_Standard_Address_Population__c ) return result;
        for( Address_Mapping__c newAddress : newAddresses ) {
            if( oldAddresses == null ) { //insert
                if( newAddress.Primary__c && newAddress.Active__c && addressTypeIsSupported( newAddress ) ) {
                    result.add( newAddress );
                }
            } else { //update
                Address_Mapping__c oldAddress = oldAddresses.get( newAddress.Id );
                Boolean newAddressTypeSupported = addressTypeIsSupported( newAddress );
                Boolean oldAddressTypeSupported = addressTypeIsSupported( oldAddress );
                if( (  newAddress.Primary__c && !oldAddress.Primary__c && newAddress.Active__c  && newAddressTypeSupported ) ||
                    (  newAddress.Active__c  && !oldAddress.Active__c  && newAddress.Primary__c && newAddressTypeSupported ) || //business flow does not allow reactivation, nevertheless adding
                    ( !newAddress.Primary__c &&  oldAddress.Primary__c && oldAddress.Active__c  && oldAddressTypeSupported ) ||
                    ( !newAddress.Active__c  &&  oldAddress.Active__c  && oldAddress.Primary__c && oldAddressTypeSupported ) ||
                    (  newAddress.Address__c !=  oldAddress.Address__c && newAddress.Primary__c && newAddress.Active__c && ( newAddressTypeSupported || oldAddressTypeSupported ) ) ) {
                    result.add( newAddress );
                }
            }
        }
        return result;
    }

    public static Boolean addressTypeIsSupported( Address_Mapping__c address ) {
        if( address.Contact__c != null ) {
            return addressTypeIsSupported( Contact.SObjectType, address.Address_Type__c );
        } else if( address.Account__c != null ) {
            return addressTypeIsSupported( Account.SObjectType, address.Address_Type__c );
        }
        return false;
    }

    public static Boolean addressTypeIsSupported( Schema.SObjectType objectType, String addressType ) {
        Map<String, String> fieldToAddressType = getAddressTypeMapping( objectType );
        if( fieldToAddressType == null ) return false;
        Set<String> supportedAddressTypes = new Set<String>( fieldToAddressType.values() );
        supportedAddressTypes.remove( null );
        return supportedAddressTypes.contains( addressType );
    }

    public static Map<Schema.SObjectType, Map<String, String>> objectNameToFieldToAddressType;
    public static Map<String, String> getAddressTypeMapping( Schema.SObjectType objectType ) {
        if( objectNameToFieldToAddressType == null ) {
            objectNameToFieldToAddressType = new Map<Schema.SObjectType, Map<String, String>>{
                Contact.SObjectType => new Map<String, String>{ ContactServices.MAILING_ADDRESS  => Utils.aamSettings.Cont_Mailing_Addr_Source__c,
                                                                ContactServices.OTHER_ADDRESS    => Utils.aamSettings.Cont_Other_Addr_Source__c },
                Account.SObjectType => new Map<String, String>{ AccountServices.BILLING_ADDRESS  => Utils.aamSettings.Acc_Billing_Addr_Source__c,
                                                                AccountServices.SHIPPING_ADDRESS => Utils.aamSettings.Acc_Shipping_Addr_Source__c }
            };
        }
        return objectNameToFieldToAddressType.get( objectType );
    }

    public static void rebaseAddressMappings( List<Contact> contacts, Map<Id, Contact> oldContacts ) {
        if( Utils.aamSettings.Disable_Contact_Reparenting_Function__c ) return;
        Map<Id, Contact> contactIdToContact = new Map<Id, Contact>( contacts );
        Set<Id> accountIds = new Set<Id>();
        for( Contact contact : contactIdToContact.values() ) {
            accountIds.add( contact.AccountId );
        }

        Map<Id, List<Address__c>> hierarchyAccountIdToAddresses = new Map<Id, List<Address__c>>();
        Map<Id, Set<Id>> contactIdToHierarchyAccountIds = new Map<Id, Set<Id>>();

        Map<Id, Id> newAccountIdToUltimateParentId = AccountHierarchyServices.getUltimateParentAccountIds( accountIds );
        Map<Id, HierarchyNode> ultimateParentIdToNodes = AccountHierarchyServices.getAccountHierarchies( new Set<Id>( newAccountIdToUltimateParentId.values() ) );
        for( Contact contact : contactIdToContact.values() ) {
            Set<Id> hierarchyAccountIds = ultimateParentIdToNodes.get( newAccountIdToUltimateParentId.get( contact.AccountId ) ).getAllHierarchyIds();
            if( !hierarchyAccountIds.contains( oldContacts.get( contact.Id ).AccountId ) ) { //only if moved outside of hierarchy
                for( Id hierarchyAccountId : hierarchyAccountIds ) {
                    hierarchyAccountIdToAddresses.put( hierarchyAccountId, new List<Address__c>() );
                }
                contactIdToHierarchyAccountIds.put( contact.Id, hierarchyAccountIds );
            }
        }
        if( contactIdToHierarchyAccountIds.isEmpty() ) return;

        Set<Id> hierarchyAccountIds = hierarchyAccountIdToAddresses.keySet();
        String query = 'SELECT ' + Utils.addFieldsToQuery( null, AddressServices.UNIQUENESS_DESCRIPTION_FIELDS ) + ', Account__c ';
        query += 'FROM Address__c ';
        query += 'WHERE Account__c IN :hierarchyAccountIds';
        for( Address__c hierarchyAccountAddress : Database.query( query ) ) {
            hierarchyAccountIdToAddresses.get( hierarchyAccountAddress.Account__c ).add( hierarchyAccountAddress );
        }

        List<Address_Mapping__c> addressMappingsToUpdate = new List<Address_Mapping__c>();
        Map<String, Address__c> addressKeyToAddressToCreate = new Map<String, Address__c>();
        Map<String, List<Address_Mapping__c>> addressKeyToAddressMappingsToUpdate = new Map<String, List<Address_Mapping__c>>();

        Set<Id> contactIds = contactIdToHierarchyAccountIds.keySet();
        query = 'SELECT ' + Utils.addFieldsToQuery( ADDRESS_REFERENCE_FIELD, Utils.joinFields( AddressServices.CLONE_ADDRESS_FIELDS, AddressServices.UNIQUENESS_DESCRIPTION_FIELDS ) ) + ', Contact__c ';
        query += 'FROM Address_Mapping__c ';
        query += 'WHERE Contact__c IN :contactIds';
        for( Address_Mapping__c addressMappingContact : Database.query( query ) ) {
            SObject refAddress = addressMappingContact.getSobject( ADDRESS_REFERENCE_FIELD );
            List<Address__c> hierarchyAddresses = new List<Address__c>();
            for( Id hierarchyAccountId : contactIdToHierarchyAccountIds.get( addressMappingContact.Contact__c ) ) {
                hierarchyAddresses.addAll( hierarchyAccountIdToAddresses.get( hierarchyAccountId ) );
            }
            Boolean addressWasFound = false;
            for( Address__c address : hierarchyAddresses ) {
                if( Utils.recordsAreEqual( address, refAddress, AddressServices.UNIQUENESS_DESCRIPTION_FIELDS ) ) {
                    addressMappingContact.Address__c = address.Id;
                    addressMappingsToUpdate.add( addressMappingContact );
                    addressWasFound = true;
                    break;
                }
            }
            if( !addressWasFound ) {
                String addressKey = Utils.createStringKey( refAddress, AddressServices.UNIQUENESS_DESCRIPTION_FIELDS );
                if( !addressKeyToAddressToCreate.containsKey( addressKey ) ) {
                    Address__c clonedAddress = (Address__c)refAddress.clone();
                    //clonedAddress.Account__c = contactIdToContact.get( addressMappingContact.Contact__c ).AccountId; // - GW-154
                    clonedAddress.Account__c = newAccountIdToUltimateParentId.get( contactIdToContact.get( addressMappingContact.Contact__c ).AccountId ); // + GW-154
                    addressKeyToAddressToCreate.put( addressKey, clonedAddress );
                    addressKeyToAddressMappingsToUpdate.put( addressKey, new List<Address_Mapping__c>() );
                }
                addressKeyToAddressMappingsToUpdate.get( addressKey ).add( addressMappingContact );
            }
        }
        INSERT addressKeyToAddressToCreate.values();
        for( String key : addressKeyToAddressToCreate.keySet() ) {
            Id addressId = addressKeyToAddressToCreate.get( key ).Id;
            for( Address_Mapping__c addressMappingContact : addressKeyToAddressMappingsToUpdate.get( key ) ) {
                addressMappingContact.Address__c = addressId;
                addressMappingsToUpdate.add( addressMappingContact );
            }
        }
        UPDATE addressMappingsToUpdate;
    }

    public static Set<Id> getContactAddressMappingIds( List<Address_Mapping__c> addressMappings ) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> addressIds = new Set<Id>();
        for( Address_Mapping__c addressMapping : addressMappings ) {
            if( addressMapping.Contact__c != null ) {
                contactIds.add( addressMapping.Contact__c );
            } else {
                accountIds.add( addressMapping.Account__c );
                addressIds.add( addressMapping.Address__c );
            }
        }
        accountIds.remove( null );
        addressIds.remove( null );
        return new Map<Id, Address_Mapping__c>( [ SELECT Id
                                                  FROM Address_Mapping__c
                                                  WHERE Active__c = true
                                                    AND Address__c IN :addressIds
                                                    AND Contact__r.AccountId != null
                                                    AND Contact__r.AccountId IN :accountIds
                                                    AND Contact__c != null
                                                    AND Contact__c NOT IN :contactIds ] ).keySet();
    }

    public static void createOrUpdateAddressMappingContact( Id addressId, List<ContactWrapper> contacts ) {
        Map<String, ContactWrapper> keyToContacts = new Map<String, ContactWrapper>();
        String query = 'SELECT Primary__c, Contact__c, Address_Type__c ';
        query +=       'FROM Address_Mapping__c ';
        query +=       'WHERE Address__c = \'' + addressId + '\' ';
        query +=         'AND Active__c = true ';
        if( !contacts.isEmpty() ) {
            query +=     'AND ( ';
            for( ContactWrapper contact : contacts ) {
                String key = contact.record.Id + contact.addressMapping.Address_Type__c;
                keyToContacts.put( key, contact );
                query += ' ( Contact__c = \'' + contact.record.Id + '\' AND Address_Type__c = \'' + contact.addressMapping.Address_Type__c + '\' ) OR ';
            }
            query = query.removeEnd( ' OR ' );
            query += ' )';
        }

        Map<String, List<Address_Mapping__c>> keyToAddresses = new Map<String, List<Address_Mapping__c>>();
        for( Address_Mapping__c addressMapping : Database.query( query ) ) {
            String key = addressMapping.Contact__c + addressMapping.Address_Type__c;
            if( keyToAddresses.get( key ) == null ) {
                keyToAddresses.put( key, new List<Address_Mapping__c>() );
            }
            keyToAddresses.get( key ).add( addressMapping );
        }

        List<Address_Mapping__c> addressMappingsToUpsert = new List<Address_Mapping__c>();
        for( String key : keyToContacts.keySet() ) {
            if( keyToAddresses.get( key ) == null ) {
                addressMappingsToUpsert.add(
                    new Address_Mapping__c(
                        Address__c = addressId,
                        Contact__c = keyToContacts.get( key ).record.Id,
                        Address_Type__c = keyToContacts.get( key ).addressMapping.Address_Type__c,
                        Primary__c = keyToContacts.get( key ).addressMapping.Primary__c,
                        Active__c = true
                    )
                );
            } else {
                for( Address_Mapping__c addressMappingItem : keyToAddresses.get( key ) ) {
                    if( !addressMappingItem.Primary__c && keyToContacts.get( key ).addressMapping.Primary__c ) {
                        addressMappingsToUpsert.add(
                            new Address_Mapping__c(
                                Id = addressMappingItem.Id,
                                Primary__c = true
                            )
                        );
                    }
                }
            }
        }
        UPSERT addressMappingsToUpsert;
    }

    public static List<Address_Mapping__c> filterActiveAddressMappings( List<Address_Mapping__c> newAddresses, Map<Id, Address_Mapping__c> oldAddresses ) {
        List<Address_Mapping__c> result = new List<Address_Mapping__c>();
        for( Address_Mapping__c addressMapping : ( newAddresses != null ? newAddresses : oldAddresses.values() ) ) {
            if( ( ( newAddresses == null || oldAddresses == null ) && addressMapping.Active__c ) || //insert or delete
                ( ( newAddresses != null && oldAddresses != null ) && addressMapping.Active__c != oldAddresses.get( addressMapping.Id ).Active__c ) ) { //update
                result.add( addressMapping );
            }
            if( newAddresses != null && oldAddresses != null && //update with change of lookup
                ( addressMapping.Active__c &&
                  ( addressMapping.Contact__c != oldAddresses.get( addressMapping.Id ).Contact__c ||
                    addressMapping.Account__c != oldAddresses.get( addressMapping.Id ).Account__c ) ) ) {
                    result.add( addressMapping );
                    result.add( oldAddresses.get( addressMapping.Id ) );
            }
        }
        return result;
    }

    public static void countActiveAddressMappings( List<Address_Mapping__c> addressMappings ) {
        countActiveAddressMappings( addressMappings, null );
    }

    public static void countActiveAddressMappings( List<Address_Mapping__c> addressMappings, Set<Id> addressesToIgnore ) {
        Map<Id, SObject> recordIdToRecord = new Map<Id, SObject>();
        countActiveAddressMappingsForField( Address_Mapping__c.Contact__c, addressMappings, recordIdToRecord, addressesToIgnore );
        countActiveAddressMappingsForField( Address_Mapping__c.Account__c, addressMappings, recordIdToRecord, addressesToIgnore );
        List<SObject> recordsToUpdate = recordIdToRecord.values();
        recordsToUpdate.sort();
        UPDATE recordsToUpdate;
    }

    private static void countActiveAddressMappingsForField( Schema.SObjectField field, List<Address_Mapping__c> addressMappings, Map<Id, SObject> recordIdToRecord, Set<Id> addressesToIgnore ) {
        Set<Id> recordIdsToQuery = new Set<Id>();
        String fieldName = field.getDescribe().getName();
        Schema.sObjectType objectType = field.getDescribe().getReferenceTo()[0];
        for( Address_Mapping__c addressMapping : addressMappings ) {
            Id recordId = (Id)addressMapping.get( fieldName );
            if( recordId == null ) continue;
            SObject record = recordIdToRecord.get( recordId );
            if( record == null ) {
                record = objectType.newSObject( recordId );
            }
            record.put( ADDRESS_MAPPING_ACTIVE_COUNT_FIELD_NAME, 0 );
            recordIdToRecord.put( recordId, record );
            recordIdsToQuery.add( recordId );
        }

        if( recordIdsToQuery.isEmpty() ) return;
        String query = 'SELECT ' + fieldName + ' field, COUNT(Id) number ' +
                       'FROM Address_Mapping__c ' +
                       'WHERE Active__c = true ' +
                         'AND ' + fieldName + ' IN :recordIdsToQuery ' +
                       ( addressesToIgnore != null && !addressesToIgnore.isEmpty() ? 'AND Address__c NOT IN :addressesToIgnore ' : '' ) +
                       'GROUP BY ' + fieldName;
        for( AggregateResult ag : Database.query( query ) ) {
            recordIdToRecord.get( (Id)ag.get( 'field' ) ).put( ADDRESS_MAPPING_ACTIVE_COUNT_FIELD_NAME, (Integer)ag.get( 'number' ) );
        }
    }

    public static List<Address_Mapping__c> getActiveAddressMappings( Map<Id, Address__c> addresses ) {
        List<Address_Mapping__c> addressMappings = [ SELECT Contact__c, Account__c
                                                     FROM Address_Mapping__c
                                                     WHERE Active__c = true
                                                       AND Address__c IN :addresses.keySet() ];
        return addressMappings;
    }

	//added by chris chen 2017/07/06
	public static void pullAccountAddressOnCreationContact(List<Contact> contacts){
		if( !Utils.aamSettings.Pull_Account_Address_Creation_Contact__c ) return;
		List<Address_Mapping__c> updateAddressMappings = pullAccountAddressOnContact(contacts);
		if (updateAddressMappings != null && !updateAddressMappings.isEmpty()){
			INSERT updateAddressMappings;
		}
	}
	public static void pullAccountAddressOnReparentedContact(List<Contact> contacts){
		if( !Utils.aamSettings.Pull_Account_Addresses_Re_Parent_Contact__c ) return;
		deactivateAddressMappingOnReparentedContact(contacts);
		List<Address_Mapping__c> updateAddressMappings = pullAccountAddressOnContact(contacts);
		if (updateAddressMappings != null && !updateAddressMappings.isEmpty()){
			INSERT updateAddressMappings;
		}
	}

	public static List<Address_Mapping__c> pullAccountAddressOnContact(List<Contact> contacts){
		if (contacts == null || contacts.size() == 0 ) return null;
        Set<Id> accIds = new Set<Id>();
        Map<Id, Contact> consHasAccount = new Map<Id, Contact>();
        for (Contact con : contacts){
        	accIds.add(con.AccountId);
            consHasAccount.put(con.Id, con);
        }
        accIds.remove(null);
		consHasAccount.remove(null);

        List<Address_Mapping__c> activeAddressMappingsWithAccs = new List<Address_Mapping__c>();
        activeAddressMappingsWithAccs  = [Select Id, Primary__c, Contact__c, Address__c, Address_Type__c, Active__c, Account__c From Address_Mapping__c where Account__c != null and Account__c =: accIds and Active__c = true];

        Map<Id, List<Address_Mapping__c>> activeAddressMappingsWithAccsMap = new Map<Id, List<Address_Mapping__c>>();

        for (Address_Mapping__c addMapping : activeAddressMappingsWithAccs){
        	if (activeAddressMappingsWithAccsMap.get(addMapping.Account__c) != null){
        		activeAddressMappingsWithAccsMap.get(addMapping.Account__c).add(addMapping);
        	}
        	else{
        		activeAddressMappingsWithAccsMap.put(addMapping.Account__c, new List<Address_Mapping__c>{addMapping});
        	}
        }

        List<Address_Mapping__c> insertAddressMappingsForCon = new List<Address_Mapping__c> ();
        for (Id conId :consHasAccount.KeySet()){
        	if (activeAddressMappingsWithAccsMap.get(consHasAccount.get(conId).AccountId) != null){
        		list<Address_Mapping__c> tempAddressMappings = activeAddressMappingsWithAccsMap.get(consHasAccount.get(conId).AccountId);
        		for (Address_Mapping__c tempAddressMapping : tempAddressMappings){
        			Address_Mapping__c insertAddressMapping = tempAddressMapping.clone();
        			insertAddressMapping.Account__c = null;
        			insertAddressMapping.Contact__c = conId;
        			insertAddressMappingsForCon.add(insertAddressMapping);
        		}
        	}
        }
        return insertAddressMappingsForCon;

	}
	public static void deactivateAddressMappingOnReparentedContact(List<Contact> contacts){
		if (contacts == null || contacts.size() == 0 ) return;
        Set<Id> accIds = new Set<Id>();
        Map<Id, Contact> consHasAccount = new Map<Id, Contact>();
        for (Contact con : contacts){
        	accIds.add(con.AccountId);
            consHasAccount.put(con.Id, con);
        }
        Map<Id, Address_Mapping__c> addressMappingsWithCons  = new Map<Id, Address_Mapping__c>([Select Id From Address_Mapping__c where Contact__c != null and Contact__c =: consHasAccount.KeySet()]);
        if (addressMappingsWithCons.KeySet() != null && addressMappingsWithCons.KeySet().size() != 0){
        	deactivateAddressMappings(addressMappingsWithCons.KeySet());
        }
	}
}