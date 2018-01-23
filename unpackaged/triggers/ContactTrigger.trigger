trigger ContactTrigger on Contact( after update, after insert, before insert, before update ) {
	//added by chris chen 2017/07/05
	
	if (Trigger.isBefore) {
		if( Trigger.isInsert ) {
			ContactServices.zeroActiveCount(Trigger.new);
			ContactServices.emptyContactStandardMailingAddress(Trigger.new);
		}
		if ( Trigger.isUpdate ){
			ContactServices.emptyContactStandardMailingAddress(ContactServices.filterContactsWithChangedAccount( Trigger.new, Trigger.oldMap ));
		}
	}
	
    if( Trigger.isAfter ) {
        if( Trigger.isUpdate ) {
            AddressMappingServices.rebaseAddressMappings( ContactServices.filterContactsWithChangedAccount( Trigger.new, Trigger.oldMap ), Trigger.oldMap );
            //added by chris chen 2017/07/05
            AddressMappingServices.pullAccountAddressOnReparentedContact(ContactServices.filterContactsWithChangedAccount( Trigger.new, Trigger.oldMap ));
        }
        
        //added by chris chen 2017/07/05
        
        if( Trigger.isInsert ) {
        	AddressMappingServices.pullAccountAddressOnCreationContact(Trigger.New);
        }
        
    }

}