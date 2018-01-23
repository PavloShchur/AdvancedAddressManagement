trigger CountryTrigger on FIL_AAM__Country_Mapping__c( after insert ) {

    if( Trigger.isAfter ) {
        if( Trigger.isInsert ) {
            CountryServices.populateCountryMappingsOnAddress( Trigger.new );
        }
    }

}