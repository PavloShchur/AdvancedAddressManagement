global class BatchRepairAddresses implements Database.Batchable<sObject>, Schedulable {

    public static final String JOB_NAME = BatchRepairAddresses.class.getName().substringAfterLast( '.' );
    public static final Integer CHUNK_SIZE_DEFAULT = 200;

    global static void schedule() {
        schedule( Utils.SCHEDULE_HOURLY );
    }

    global static void schedule( String cronExpression ) {
        cancel();
        System.schedule( JOB_NAME, cronExpression, new BatchRepairAddresses() );
    }

    global static void cancel() {
        for( CronTrigger cronTrigger : [ SELECT Id
                                         FROM CronTrigger
                                         WHERE CronJobDetail.Name LIKE : '%' + BatchRepairAddresses.JOB_NAME + '%' ] ) {
            System.abortJob( cronTrigger.Id );
        }
    }

    global void execute( SchedulableContext sc ) {
        if( jobIsInProgress() ) return;
        Database.executebatch( new BatchRepairAddresses(), (Integer)Utils.aamSettings.Chunk_Size_For_Address_Batch__c );
    }


    String query = RepairAddressService.BATCH_ADDRESS_QUERY;

    global BatchRepairAddresses() {
    }

    global Database.QueryLocator start( Database.BatchableContext bc ) {
        if( Utils.aamSettings.Disable_Account_Move_Delete_Function__c ) query = 'SELECT Id FROM Address__c LIMIT 0';
        return Database.getQueryLocator( query );
    }

    global void execute( Database.BatchableContext bc, List<sObject> scope ) {
        RepairAddressService service = new RepairAddressService( scope );
        service.start();
    }

    global void finish( Database.BatchableContext bc ) {
        if( Utils.aamSettings.Disable_Account_Move_Delete_Function__c ) return;
        Database.executebatch( new BatchRepairAddressMappings(), (Integer)Utils.aamSettings.Chunk_Size_For_Address_Mapping_Batch__c );
    }

    private static Boolean jobIsInProgress() {
        return !Database.query( 'SELECT Id ' +
                                'FROM AsyncApexJob ' +
                                'WHERE JobType != \'ScheduledApex\' ' +
                                  'AND ( ApexClass.Name LIKE \'%' + BatchRepairAddresses.JOB_NAME + '%\' OR ApexClass.Name LIKE \'%' + BatchRepairAddressMappings.JOB_NAME + '%\' ) ' +
                                  'AND ( Status = \'Holding\' OR Status = \'Queued\' OR Status = \'Preparing\' OR Status = \'Processing\' )' ).isEmpty();
    }

}