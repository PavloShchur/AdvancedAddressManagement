public class BatchRepairAddressMappings implements Database.Batchable<sObject> {

    public static final String JOB_NAME = BatchRepairAddressMappings.class.getName().substringAfterLast( '.' );
    public static final Integer CHUNK_SIZE_DEFAULT = 200;

    String query = RepairAddressMappingsService.BATCH_ADDRESS_QUERY;

    public BatchRepairAddressMappings() {
    }

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        if( Utils.aamSettings.Disable_Account_Move_Delete_Function__c ) query = 'SELECT Id FROM Address_Mapping__c LIMIT 0';
        return Database.getQueryLocator( query );
    }

    public void execute( Database.BatchableContext bc, List<sObject> scope ) {
        RepairAddressMappingsService service = new RepairAddressMappingsService( scope );
        service.start();
    }

    public void finish( Database.BatchableContext bc ) {

    }

}