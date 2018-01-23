trigger AddressTrigger on FIL_AAM__Address__c( before insert, before update, before delete,
                                                               after update ) {

    if( Trigger.isBefore ) {
        if( Trigger.isInsert ) {
            if( !AddressServices.preventAddressReparentingToUltAccountOnInsert ) {
                AddressServices.reparentAddressToTopLevelAccount( AddressServices.filterAddressesWithChangedAccount( Trigger.new, Trigger.oldMap ) );
            }
        }
        if( Trigger.isInsert || Trigger.isUpdate ) {
            AddressServices.generateHash( AddressServices.filterAddressesWithUniqueFieldsChanged( Trigger.new, Trigger.oldMap ) );
            AddressServices.updateVerifiedFields( AddressServices.filterUnverifiedRecords( Trigger.new, Trigger.oldMap ) );
            CountryServices.populateCountryMapping( AddressServices.filterAddressesWithCountries( Trigger.new, Trigger.oldMap ) );
        }
        if( Trigger.isDelete ) {
            AddressMappingServices.countActiveAddressMappings( AddressMappingServices.getActiveAddressMappings( Trigger.oldMap ), Trigger.oldMap.keySet() );
            AddressServices.setStandardAddresses( AddressServices.filterChangedAddresses( Trigger.new, Trigger.oldMap ), true );
        }
    }
    if( Trigger.isAfter ) {
        if( Trigger.isUpdate ) {
            AddressServices.setStandardAddresses( AddressServices.filterChangedAddresses( Trigger.new, Trigger.oldMap ), false );
        }
    }
}