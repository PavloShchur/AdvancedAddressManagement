global without sharing class AddressServices {

    //prevents re-parenting of new addresses to their ultimate parents; this is needed on before delete trigger
    public static Boolean preventAddressReparentingToUltAccountOnInsert = false;

    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_INACTIVE = 'Inactive';

    public static final List<Schema.SObjectField> ADDRESS_LINES_FIELDS = new List<Schema.SObjectField>{
        Address__c.Address_Line_1__c,
        Address__c.Address_Line_2__c,
        Address__c.City__c,
        Address__c.State_County__c,
        Address__c.Country__c,
        Address__c.Postcode__c
    };

    public static final List<Schema.SObjectField> STATUS_FIELD = new List<Schema.SObjectField>{
        Address__c.Status__c
    };

    public static final List<Schema.SObjectField> FIELDS_FOR_ADDRESS_MATCHING = new List<Schema.SObjectField>{
        Address__c.Address_Line_1__c,
        Address__c.Address_Line_2__c,
        Address__c.Address_Line_3__c,
        Address__c.Address_Line_4__c,
        Address__c.City__c,
        Address__c.Country__c,
        Address__c.Postcode__c,
        Address__c.State_County__c
    };

    public static final List<Schema.SObjectField> FIELDS_NEEDED_RELATED_ADDRESSES = new List<Schema.SObjectField>{
        Address_Mapping__c.Address__c,
        Address_Mapping__c.Primary__c
    };

    public static final List<Schema.SObjectField> UNIQUENESS_DESCRIPTION_FIELDS_LIST = new List<Schema.SObjectField>{
        Address__c.Address_Line_1__c, Address__c.Address_Line_2__c, Address__c.Address_Line_3__c, Address__c.Address_Line_4__c,
        Address__c.City__c, Address__c.Country__c, Address__c.Postcode__c, Address__c.State_County__c
    };

    public static final Set<Schema.SObjectField> UNIQUENESS_DESCRIPTION_FIELDS = new Set<Schema.SObjectField>( UNIQUENESS_DESCRIPTION_FIELDS_LIST );

    public static final Set<Schema.SObjectField> CLONE_ADDRESS_FIELDS = new Set<Schema.SObjectField>{
        Address__c.Address_Line_1__c, Address__c.Address_Line_2__c, Address__c.Address_Line_3__c, Address__c.Address_Line_4__c,
        Address__c.City__c, Address__c.Country__c, Address__c.Postcode__c, Address__c.State_County__c,
        Address__c.Status__c, Address__c.Verified__c, Address__c.Verified_By__c, Address__c.Verified_Date__c
    };

    public static final List<Schema.SObjectField> FIELDS_FOR_ADDRESS_MERGE_DISPLAY = new List<Schema.SObjectField>{
        Address__c.Address_Line_1__c,
        Address__c.Address_Line_2__c,
        Address__c.Address_Line_3__c,
        Address__c.Address_Line_4__c,
        Address__c.City__c,
        Address__c.State_County__c,
        Address__c.Postcode__c,
        Address__c.Country_Name__c
    };

    public static void generateHash( List<Address__c> addresses ) {
        for( Address__c addressItem : addresses ) {
            addressItem.Hash__c = Utils.generateHash( addressItem, UNIQUENESS_DESCRIPTION_FIELDS_LIST );
        }
    }

    public static List<Address__c> filterAddressesWithUniqueFieldsChanged( List<Address__c> newList, Map<Id, Address__c> oldMap ) {
        List<Address__c> filteredRecords = new List<Address__c>();
        for( Address__c addressItem : newList ) {
            if( addressItem.Hash__c != null && oldMap != null && !uniqueFieldsChanged( addressItem, oldMap.get( addressItem.Id ) ) ) continue;
            filteredRecords.add( addressItem );
        }
        return filteredRecords;
    }

    public static Boolean uniqueFieldsChanged( Address__c newAddress, Address__c oldAddress ) {
        for( Schema.SObjectField fieldItem : UNIQUENESS_DESCRIPTION_FIELDS ) {
            if( newAddress.get( fieldItem ) == oldAddress.get( fieldItem ) ) continue;
            return true;
        }
        return false;
    }

    public static List<Address__c> filterUnverifiedRecords( List<Address__c> newList, Map<Id, Address__c> oldMap ) {
        List<Address__c> filteredRecords = new List<Address__c>();
        for( Address__c addressItem : newList ) {
            if( !addressItem.Verified__c ) continue;
            if( oldMap == null || addressItem.Verified__c != oldMap.get( addressItem.Id ).Verified__c ) {
                filteredRecords.add( addressItem );
            }
        }
        return filteredRecords;
    }

    public static void updateVerifiedFields( List<Address__c> addresses ) {
        for( Address__c addressItem : addresses ) {
            if( addressItem.Verified_Date__c == null ) {
                addressItem.Verified_Date__c = Date.today();
            }
            if( addressItem.Verified_By__c == null ) {
                addressItem.Verified_By__c = UserInfo.getUserId();
            }
        }
    }

    public static Integer getNumFieldsEntered( Address__c address ) {
        Integer result = 0;
        if( address == null ) return result;
        for( String fieldToFilter : Utils.getFieldsFromFieldSet(
                                        SObjectType.Address__c.FieldSets.New_Address_Address_Fields.getFields(),
                                        null,
                                        false ) ) {
            String fieldDataToFilter = (String)address.get( fieldToFilter );
            if( fieldDataToFilter == null ) continue;
            result++;
        }
        return result;
    }

    public static List<Address__c> getRelatedAddressesInHierarchy( Id accountId, Address__c address, Integer minFieldsEntered, Boolean doFullMatch ) {
        return getRelatedAddressesInHierarchy( accountId, address, minFieldsEntered, null, null, doFullMatch );
    }

    public static List<Address__c> getRelatedAddressesInHierarchy( Id accountId, Address__c address, Integer minFieldsEntered, List<Schema.SObjectField> fieldsToQuery, List<Schema.SObjectField> fieldsToMatch, Boolean doFullMatch ) {
        List<Address__c> addressesFound = new List<Address__c>();
        if( accountId == null || address == null ) return addressesFound;
        if( minFieldsEntered != null && getNumFieldsEntered( address ) < minFieldsEntered ) return addressesFound;
        Set<Id> accountIds = AccountHierarchyServices.getAccountIds( accountId );
        String query = 'SELECT ' + String.join(
                                       Utils.getFieldsFromFieldSet(
                                           SObjectType.Address__c.FieldSets.New_Address_Address_Search_Result_Fields.getFields(),
                                           Utils.addFieldsToList( Utils.addFieldsToList( null, fieldsToQuery ), fieldsToMatch )
                                        ), ', '
                                    ) + ' ';
        query += 'FROM Address__c ';
        query += 'WHERE Account__c IN :accountIds ';

        for( String fieldToFilter : Utils.getFieldsFromFieldSet(
                                        SObjectType.Address__c.FieldSets.New_Address_Address_Fields.getFields(),
                                        Utils.addFieldsToList( null, fieldsToMatch ),
                                        false
                                    ) ) {
            String fieldDataToFilter = (String)address.get( fieldToFilter );
            if( !doFullMatch && String.isEmpty( fieldDataToFilter ) ) continue;
            if( fieldToFilter == 'Country__c' || fieldToFilter == 'FIL_AAM__Country__c' ) {
                query += 'AND ' + fieldToFilter + ( !String.isEmpty( fieldDataToFilter ) ? ' = \'' + String.escapeSingleQuotes( fieldDataToFilter ) + '\' ' : ' = null ' );
            } else {
                query += 'AND ' + fieldToFilter + ( !String.isEmpty( fieldDataToFilter ) ? ' LIKE \'' + ( doFullMatch ? '' : '%' ) + String.escapeSingleQuotes( fieldDataToFilter ) + ( doFullMatch ? '' : '%' ) + '\' ' : ' = null ' );
            }
        }
        query += 'ORDER BY Address_Line_1__c ASC';
        addressesFound = Database.query( query );
        return addressesFound;
    }

    public static Address__c getAddressRecord( Id addressId, List<Schema.FieldSetMember> fields ) {
        return getAddressRecord( addressId, fields, null );
    }

    public static Address__c getAddressRecord( Id addressId, List<Schema.FieldSetMember> fields, Aam_Settings__c settingsInstance ) {
        Address__c result = new Address__c();
        if( settingsInstance != null ) {
            Set<String> countryIsoCodes = new Set<String>();
            for( Schema.PicklistEntry ple : Address__c.Country__c.getDescribe().getPicklistValues() ) {
                countryIsoCodes.add( ple.getValue() );
            }
            if( countryIsoCodes.contains( settingsInstance.Default_Country_ISO_Code__c ) ) {
                result.Country__c = settingsInstance.Default_Country_ISO_Code__c;
            }
        }
        if( addressId == null ) return result;
        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               fields,
                                               Utils.addFieldsToList( Utils.addFieldsToList( null, ADDRESS_LINES_FIELDS ), STATUS_FIELD )
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Address__c ';
        query += 'WHERE Id = \'' + addressId + '\' ';
        List<Address__c> addressesFound = Database.query( query );
        if( !addressesFound.isEmpty() ) {
            result = addressesFound[0];
        }
        return result;
    }

    public static String getAddressLines( Address__c addressRecord ) {
        String result = '';
        List<String> fieldDataList = new List<String>();
        for( Schema.SObjectField fieldItem : ADDRESS_LINES_FIELDS ) {
            String fieldName = fieldItem.getDescribe().getName();
            String fieldData = (String)addressRecord.get( fieldItem.getDescribe().getName() );
            if( fieldName == 'Country__c' || fieldName == 'FIL_AAM__Country__c' ) {
                Utils.addField( fieldDataList, CountryServices.countryIsoCodeToName.get( fieldData ) != null ? CountryServices.countryIsoCodeToName.get( fieldData ) : fieldData );
            } else {
                Utils.addField( fieldDataList, fieldData );
            }
        }
        return String.join( fieldDataList, ', ' );
    }

    public static List<Address__c> filterAddressesWithCountries( List<Address__c> newList, Map<Id, Address__c> oldMap ) {
        List<Address__c> result = new List<Address__c>();
        for( Address__c address : newList ) {
            if( oldMap == null || address.Country__c != oldMap.get( address.Id ).Country__c ) {
                result.add( address );
            }
        }
        return result;
    }

    public static Boolean addressWasUpdated( Address__c newAddress, Address__c oldAddress ) {
        return Utils.isFieldChanged( newAddress, oldAddress, Address__c.Address_Line_1__c ) ||
               Utils.isFieldChanged( newAddress, oldAddress, Address__c.Address_Line_2__c ) ||
               Utils.isFieldChanged( newAddress, oldAddress, Address__c.Address_Line_3__c ) ||
               Utils.isFieldChanged( newAddress, oldAddress, Address__c.Address_Line_4__c ) ||
               Utils.isFieldChanged( newAddress, oldAddress, Address__c.City__c ) ||
               Utils.isFieldChanged( newAddress, oldAddress, Address__c.State_County__c ) ||
               Utils.isFieldChanged( newAddress, oldAddress, Address__c.Postcode__c ) ||
               Utils.isFieldChanged( newAddress, oldAddress, Address__c.Country_Name__c ) ||
               Utils.isFieldChanged( newAddress, oldAddress, Address__c.Country__c );
    }

    global static void setStandardAddresses( Set<Id> accountOrContactOrAddressIds ) {
        if( accountOrContactOrAddressIds == null ) return;
        accountOrContactOrAddressIds.remove( null );
        Set<Id> accountOrContactIds = new Set<Id>();
        Set<Id> addressIds = new Set<Id>();
        for( Id idItem : accountOrContactOrAddressIds ) {
            Schema.SObjectType objectType = idItem.getSObjectType();
            if( objectType == Contact.SObjectType || objectType == Account.SObjectType ) {
                accountOrContactIds.add( idItem );
            }
            if( objectType == Address__c.SObjectType ) {
                addressIds.add( idItem );
            }
        }
        if( !accountOrContactIds.isEmpty() ) {
            UPDATE populateAddresses( accountOrContactIds, false, false );
        }
        if( !addressIds.isEmpty() ) {
            UPDATE populateAddresses( addressIds, true, false );
        }

    }

    public static void setStandardAddresses( List<Address_Mapping__c> addressMappings, Boolean isDelete ) {
        Set<Id> recordIds = new Set<Id>();
        for( Address_Mapping__c addressMapping : addressMappings ) {
            recordIds.add( addressMapping.Contact__c );
            recordIds.add( addressMapping.Account__c );
        }
        recordIds.remove( null );
        UPDATE populateAddresses( recordIds, false, isDelete );
    }

    public static void setStandardAddresses( List<Address__c> addresses, Boolean isDelete ) {
        UPDATE populateAddresses( new Map<Id, Address__c>( addresses ).keySet(), true, isDelete );
    }

    public static List<SObject> populateAddresses( Set<Id> parentOrAddressIds, Boolean addressIdsProvided, Boolean isDelete ) {
        List<SObject> result = new List<SObject>();
        if( parentOrAddressIds == null || parentOrAddressIds.isEmpty() ) return result;

        Set<String> addressTypesContact = new Set<String>( AddressMappingServices.getAddressTypeMapping( Contact.SObjectType ).values() );
        addressTypesContact.remove( null );
        Set<String> addressTypesAccount = new Set<String>( AddressMappingServices.getAddressTypeMapping( Account.SObjectType ).values() );
        addressTypesAccount.remove( null );

        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> addressIds = new Set<Id>();
        for( Id idItem : parentOrAddressIds ) {
            if( idItem.getSObjectType() == Contact.SObjectType ) {
                contactIds.add( idItem );
            } else if( idItem.getSObjectType() == Account.SObjectType ) {
                accountIds.add( idItem );
            } else if( idItem.getSObjectType() == Address__c.SObjectType ) {
                addressIds.add( idItem );
            }
        }

        String query = '';
        query += 'SELECT Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Address_Line_4__c, ';
        query +=        'City__c, Country_Name__c, Country__c, Postcode__c, State_County__c, ';
        query +=        'Address__r.Country_Mapping__c, Address_Type__c, Contact__c, Account__c ';
        query += ' FROM Address_Mapping__c ';
        query += ' WHERE Primary__c = true ';
        query +=   ' AND Active__c = true ';
        if( addressIdsProvided ) {
            query += 'AND Address__c IN :addressIds ';
            query += 'AND ( ( Contact__c != null AND Address_Type__c IN :addressTypesContact ) OR ( Account__c != null AND Address_Type__c IN :addressTypesAccount ) ) ';
        } else {
            query += 'AND ( ( Contact__c IN :contactIds AND Address_Type__c IN :addressTypesContact ) OR ( Account__c IN :accountIds AND Address_Type__c IN :addressTypesAccount ) ) ';
        }

        Map<Id, List<Address_Mapping__c>> parentIdToAddressMappings = new Map<Id, List<Address_Mapping__c>>();
        for( Address_Mapping__c addressMapping : Database.query( query ) ) {
            Id parentId = addressMapping.Contact__c != null ? addressMapping.Contact__c : addressMapping.Account__c;
            if( parentId == null ) continue;
            if( parentIdToAddressMappings.get( parentId ) == null ) {
                parentIdToAddressMappings.put( parentId, new List<Address_Mapping__c>() );
            }
            parentIdToAddressMappings.get( parentId ).add( addressMapping );
        }

        result.addAll( getParentsWithUpdatedAddresses( parentOrAddressIds, parentIdToAddressMappings, isDelete, addressIdsProvided ) );
        result.sort();
        return result;
    }

    private static List<SObject> getParentsWithUpdatedAddresses( Set<Id> parentIds, Map<Id, List<Address_Mapping__c>> parentIdToAddressMappings, Boolean isDelete, Boolean addressIdsProvided ) {
        List<SObject> result = new List<SObject>();
        if( addressIdsProvided ) {
            parentIds = parentIdToAddressMappings.keySet();
        }
        for( Id parentId : parentIds ) {
            Schema.SObjectType objectType = parentId.getSObjectType();
            SObject record = objectType.newSObject( parentId );
            Map<String, String> addressNameToType = AddressMappingServices.getAddressTypeMapping( objectType );
            for( String addressName : addressNameToType.keySet() ) {
                if( !addressIdsProvided ) {
                    Utils.populateAddressFields( record, new Address_Mapping__c(), addressName ); //clear address
                }
                String addressType = addressNameToType.get( addressName );
                List<Address_Mapping__c> addressMappings = parentIdToAddressMappings.get( parentId );
                if( addressMappings == null ) continue;
                for( Address_Mapping__c addressMapping : addressMappings ) {
                    if( addressIdsProvided && addressMapping.Address_Type__c == addressType ) {
                        Utils.populateAddressFields( record, new Address_Mapping__c(), addressName ); //clear address
                        if( isDelete ) continue;
                    }
                    if( addressMapping.Address_Type__c != addressType ) continue;
                    Utils.populateAddressFields( record, addressMapping, addressName ); //populate address
                }
            }
            result.add( record );
        }
        return result;
    }

    public static List<Address__c> filterChangedAddresses( List<Address__c> newAddresses, Map<Id, Address__c> oldAddresses ) {
        List<Address__c> result = new List<Address__c>();
        if( Utils.aamSettings.Disable_Standard_Address_Population__c ) return result;
        if( newAddresses == null ) {
            result.addAll( oldAddresses.values() );
        } else {
            for( Address__c newAddress : newAddresses ) {
                if( !addressWasUpdated( newAddress, oldAddresses.get( newAddress.Id ) ) ) continue;
                result.add( newAddress );
            }
        }
        return result;
    }

    public static List<Address__c> getFilteredAddresses( List<Address__c> allAddresses, String filterText, List<Schema.FieldSetMember> fields ) {
        List<Address__c> result = new List<Address__c>();
        String fieldData;
        if( String.isEmpty( filterText ) ) return allAddresses;
        for( Address__c addressItem : allAddresses ) {
            for( Schema.FieldSetMember fieldItem : fields ) {
                if( fieldItem.getType() == Schema.DisplayType.BOOLEAN ) continue;
                fieldData = Utils.getFieldDataForSearch( addressItem, fieldItem );
                if( fieldData == null || !fieldData.containsIgnoreCase( filterText ) ) continue;
                result.add( addressItem );
                break;
            }
        }
        return result;
    }

    public static List<Address__c> filterAddressesWithChangedAccount( List<Address__c> newAddresses, Map<Id, Address__c> oldAddresses ) {
        List<Address__c> result = new List<Address__c>();
        for( Address__c address : newAddresses ) {
            if( address.Account__c == null ) continue;
            if( oldAddresses != null && address.Account__c == oldAddresses.get( address.Id ).Account__c ) continue;
            result.add( address );
        }
        return result;
    }

    public static void reparentAddressToTopLevelAccount( List<Address__c> addresses ) {
        Map<Id, Id> accountIdToUltimateParentAccountId = new Map<Id, Id>();
        for( Address__c address : addresses ) {
            accountIdToUltimateParentAccountId.put( address.Account__c, null );
        }
        accountIdToUltimateParentAccountId = AccountHierarchyServices.getUltimateParentAccountIds( accountIdToUltimateParentAccountId.keySet() );
        for( Address__c address : addresses ) {
            reparentAddresses( new List<Address__c>{ address }, accountIdToUltimateParentAccountId.get( address.Account__c ) );
        }
    }

    public static Map<Id, Map<String, List<Address__c>>> getAccountIdToHashToAddresses( List<Address__c> addresses ) {
        Map<Id, Map<String, List<Address__c>>> accIdToHashToAddresses = new Map<Id, Map<String, List<Address__c>>>();
        for( Address__c addressItem : addresses ) {
            Id accId = addressItem.Account__c;
            if( !accIdToHashToAddresses.containsKey( accId ) ) accIdToHashToAddresses.put( accId, new Map<String, List<Address__c>>() );
            Map<String, List<Address__c>> hashToAddresses = accIdToHashToAddresses.get( accId );
            String hash = addressItem.Hash__c;
            if( !hashToAddresses.containsKey( hash ) ) hashToAddresses.put( hash, new List<Address__c>() );
            hashToAddresses.get( hash ).add( addressItem );
        }
        return accIdToHashToAddresses;
    }

    public static Map<Id, Map<String, List<Address__c>>> getUltAccountIdToHashToAddresses( List<Address__c> addresses, Map<Id, Id> accountIdToUltId ) {
        Map<Id, Map<String, List<Address__c>>> ultIdToHashToAddresses = new Map<Id, Map<String, List<Address__c>>>();
        for( Address__c addressItem : addresses ) {
            Id ultId = accountIdToUltId.get( addressItem.Account__c );
            if( !ultIdToHashToAddresses.containsKey( ultId ) ) ultIdToHashToAddresses.put( ultId, new Map<String, List<Address__c>>() );
            Map<String, List<Address__c>> hashToAddresses = ultIdToHashToAddresses.get( ultId );
            String hash = addressItem.Hash__c;
            if( !hashToAddresses.containsKey( hash ) ) hashToAddresses.put( hash, new List<Address__c>() );
            hashToAddresses.get( hash ).add( addressItem );
        }
        return ultIdToHashToAddresses;
    }

    public static List<Address__c> getAddressesByAccountIdsAndHashes( Set<Id> accountIds, Set<String> hashes, Set<Schema.SObjectField> fields ) {
        String query = 'SELECT ' + Utils.addFieldsToQuery( null, fields ) + ' FROM Address__c';
        List<String> queryWhere = new List<String>();
        if( accountIds != null ) {
            queryWhere.add( 'Account__c IN :accountIds' );
        }
        if( hashes != null ) {
            queryWhere.add( 'Hash__c IN :hashes' );
        }
        if( !queryWhere.isEmpty() ) {
            query += ' WHERE ' + String.join( queryWhere, ' AND ' );
        }
        return Database.query( query );
    }

    public static Set<String> getAddressHashes( List<Address__c> addresses ) {
        Set<String> hashes = new Set<String>();
        for( Address__c addressItem : addresses ) {
            hashes.add( addressItem.Hash__c );
        }
        return hashes;
    }

    public static Set<String> getAddressHashes( List<Address_Mapping__c> mappings ) {
        Set<String> hashes = new Set<String>();
        for( Address_Mapping__c mapping : mappings ) {
            hashes.add( mapping.Address__r.Hash__c );
        }
        return hashes;
    }

    public static Id findAddressWithLatestLmd( Address__c addressItem, List<Address__c> otherAddresses ) {
        Id latestAddressId = addressItem.Id; //first supposing that current address is the latest one
        Datetime latestLmd = addressItem.LastModifiedDate; //first supposing that current address is the latest one
        for( Address__c otherAddress : otherAddresses ) { //find the latest address
            if( otherAddress.LastModifiedDate <= latestLmd ) continue;
            latestLmd = otherAddress.LastModifiedDate;
            latestAddressId = otherAddress.Id;
        }
        return latestAddressId;
    }

    public static void reparentAddressesOnDelete( Map<Id, Account> oldMap ) {
        if( Utils.aamSettings.Disable_Account_Move_Delete_Function__c ) return;
        List<Address__c> addressesToUpdate = new List<Address__c>();
        Map<Id, Id> accIdToDeleteToOldUltId = AccountHierarchyServices.getUltimateParentAccountIds( oldMap.keySet() ); //account id that is deleted to its account on top of old hierarchy (can be itself)
        Map<Id, List<Address__c>> accIdToDeleteToAddresses = getAccountIdToAddresses( getAddressesByAccountIdsAndHashes( oldMap.keySet(), null, new Set<Schema.SObjectField>{ Address__c.Account__c } ) ); //account that is deleted to its direct addresses

        for( Id accIdToDelete : accIdToDeleteToOldUltId.keySet().clone() ) { //first, try to reparent addresses to ultimate parent account if it's not being deleted (this is an optimization: no need to query all related accounts)
            Id oldUltId = accIdToDeleteToOldUltId.get( accIdToDelete );
            if( accIdToDeleteToOldUltId.containsKey( oldUltId ) ) continue; //if we are deleting the Ultimate Parent Account, skip reassignment to Ultimate Parent Acoount (will assign to other account afterwards)
            List<Address__c> addressesToReparent = accIdToDeleteToAddresses.get( accIdToDelete );
            addressesToUpdate.addAll( reparentAddresses( addressesToReparent, oldUltId ) );
            accIdToDeleteToOldUltId.remove( accIdToDelete ); //reduce the map to list of accounts that still don't have their addresses reparented
        }

        if( !accIdToDeleteToOldUltId.isEmpty() ) { //second, if still some accounts exist (means that ultimate parent account is removed also)
            Map<Id, HierarchyNode> oldUltIdToNodes = AccountHierarchyServices.getAccountHierarchies( new Set<Id>( accIdToDeleteToOldUltId.values() ) ); //account on top of old hierarchy to its whole old hierarchy (including accs that will be deleted)
            Map<Id, Set<Id>> oldUltIdToRemainingAccountIds = new Map<Id, Set<Id>>();
            for( Id accIdToDelete : accIdToDeleteToOldUltId.keySet() ) { //determine which accounts remain in the hierarchy
                Id oldUltId = accIdToDeleteToOldUltId.get( accIdToDelete );
                if( !oldUltIdToRemainingAccountIds.containsKey( oldUltId ) ) { //we haven't already determined which accounts remain
                    HierarchyNode oldHierarchy = oldUltIdToNodes.get( oldUltId ); //get full old hierarchy starting from the hierarchy top
                    oldUltIdToRemainingAccountIds.put( oldUltId, oldHierarchy.getAllHierarchyIds( oldMap.keySet() ) ); //add all accounts in old hierarchy excluding ones that are removed
                }
                Set<Id> remainingAccIds = oldUltIdToRemainingAccountIds.get( oldUltId );
                if( remainingAccIds.isEmpty() ) continue; //no accounts left in hierarchy
                addressesToUpdate.addAll( reparentAddresses( accIdToDeleteToAddresses.get( accIdToDelete ), new List<Id>( remainingAccIds )[0] ) );
            }
        }

        UPDATE addressesToUpdate;
    }

    public static Map<Id, List<Address__c>> getAccountIdToAddresses( List<Address__c> addresses ) {
        Map<Id, List<Address__c>> result = new Map<Id, List<Address__c>>();
        for( Address__c address : addresses ) {
            Id accountId = address.Account__c;
            if( !result.containsKey( accountId ) ) result.put( accountId, new List<Address__c>() );
            result.get( accountId ).add( address );
        }
        return result;
    }

    public static List<Address__c> reparentAddresses( List<Address__c> addresses, Id newAccountId ) {
        List<Address__c> result = new List<Address__c>();
        if( addresses == null ) return result;
        for( Address__c address : addresses ) {
            if( address.Account__c == newAccountId ) continue;
            address.Account__c = newAccountId;
            result.add( address );
        }
        return result;
    }

}