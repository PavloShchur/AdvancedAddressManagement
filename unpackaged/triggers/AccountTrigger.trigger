trigger AccountTrigger on Account( before delete ) {

    if( Trigger.isBefore ) {
        if( Trigger.isDelete ) {
            AddressServices.reparentAddressesOnDelete( Trigger.oldMap );
        }
    }

}