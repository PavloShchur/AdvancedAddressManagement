public class BatchUpdateAddresses implements Database.Batchable<sObject> {

	String query = 'SELECT Id FROM Address__c';

	public BatchUpdateAddresses() {

	}

	public Database.QueryLocator start( Database.BatchableContext BC ) {
		return Database.getQueryLocator( query );
	}

   	public void execute( Database.BatchableContext BC, List<sObject> scope ) {
		UPDATE scope;
	}

	public void finish( Database.BatchableContext BC ) {

	}

}