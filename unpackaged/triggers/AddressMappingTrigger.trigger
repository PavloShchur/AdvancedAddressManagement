trigger AddressMappingTrigger on FIL_AAM__Address_Mapping__c( before insert, before update,
                                                               after insert,  after update,  after delete ) {

    if( Trigger.isBefore ) {
        if( Trigger.isInsert || Trigger.isUpdate ) {
            //update Removed Date and Removed By for inactive AM in Trigger.new
            AddressMappingServices.updateRemovedFields( AddressMappingServices.filterInactiveRecords( Trigger.new, Trigger.oldMap ) );
            //leave Primary = true only for one oldest AM with same Account/Contact and Type in Trigger.new (set Primary = false for newer ones)
            AddressMappingServices.unsetPrimaryForNewerAddresses( AddressMappingServices.filterPrimaryRecordsByDate( Trigger.new, Trigger.oldMap ) );
            //set Primary = true for AMs in Trigger.new if there are no other Active Primary AMs in DB with same Account/Contact and Type
            AddressMappingServices.setPrimaryAddressesIfNoOtherPrimaryExists( AddressMappingServices.filterNotPrimaryMappings( Trigger.new ) );
        }
    }

    if( Trigger.isAfter ) {
        if( Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete ) {
            //count Active Address Mappings on Account or Contact
            AddressMappingServices.countActiveAddressMappings( AddressMappingServices.filterActiveAddressMappings( Trigger.new, Trigger.oldMap ) );
        }
        if( Trigger.isInsert || Trigger.isUpdate ) {
            //set Primary = false for AMs in DB with the same Type and Account/Contact if current AM is set to Primary = true
            AddressMappingServices.resetPrimaryForOldAddresses( AddressMappingServices.filterPrimaryRecords( Trigger.new, Trigger.oldMap ) );
            if( Trigger.isUpdate ) {
                if( Utils.aamSettings.Enforce_Contact_Address_Deactivation__c ) {
                    //deactivate Contact's AMs having the same Address as Account on Account's AM deactivation
                    AddressMappingServices.deactivateAddressMappings( AddressMappingServices.getContactAddressMappingIds( AddressMappingServices.filterInactiveRecords( Trigger.new, Trigger.oldMap ) ) );
                }
                //set Primary = true to another AM in DB for some Account/Contact having the same Type at AM deactivation
                AddressMappingServices.setPrimaryToAnotherAddressAtDeactivation( AddressMappingServices.filterDeactivatedPrimaryMappings( Trigger.new, Trigger.oldMap ) );
            }
            //set standard fields on Account/Contact based on AM values
            AddressServices.setStandardAddresses( AddressMappingServices.filterChangedAddressMappings( Trigger.new, Trigger.oldMap ), false );
        }
    }

}