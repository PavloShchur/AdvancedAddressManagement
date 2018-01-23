public without sharing class ContactServices {

    public static final String MAILING_ADDRESS = 'Mailing';
    public static final String OTHER_ADDRESS = 'Other';

    public static List<Contact> filterContactsWithChangedAccount( List<Contact> newContacts, Map<Id, Contact> oldContacts ) {
        List<Contact> result = new List<Contact>();
        for( Contact contact : newContacts ) {
            if( contact.AccountId == null || contact.AccountId == oldContacts.get( contact.Id ).AccountId ) continue;
            result.add( contact );
        }
        return result;
    }
    //added by chris chen 2017/07/07
    public static void emptyContactStandardMailingAddress(List<Contact> newContacts){
    	//system.debug('AddressMappingServices.isNewContactCreated is' + AddressMappingServices.isContactCreatedOrReparented);
        //if (AddressMappingServices.isNewContactCreated == true){
        	//List<Contact> consHasAccount = new List<Contact>();
        	//Set<Id> accIds = new Set<Id>();
        	Set<ID> conIds = new Set<Id>();
            for (Contact con : newContacts){
            	if (con.AccountId != null){
            		//accIds.add(con.AccountId);
            		//consHasAccount.add(con);
            		conIds.add(con.Id);
            	} 
            }
            //accIds.remove(null);
            /****
        	List<Address_Mapping__c> activeBillingAddressMappingsWithAccs = new List<Address_Mapping__c>();
        	activeBillingAddressMappingsWithAccs  = [Select Id, Contact__c,	Address_Type__c, Active__c, Account__c From Address_Mapping__c where Account__c != null and Account__c =: accIds and Active__c = true 
        	and Address_Type__c =: Utils.aamSettings.Acc_Billing_Addr_Source__c == null ? AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS : Utils.aamSettings.Acc_Billing_Addr_Source__c];
        		
        	Map<Id, List<Address_Mapping__c>> activeBillingAddressMappingsWithAccsMap = new Map<Id, List<Address_Mapping__c>>(); 
        	for (Address_Mapping__c addMapping : activeBillingAddressMappingsWithAccs){
        		if (activeBillingAddressMappingsWithAccsMap.get(addMapping.Account__c) != null){
        			activeBillingAddressMappingsWithAccsMap.get(addMapping.Account__c).add(addMapping);
        		}
        		else{
        			activeBillingAddressMappingsWithAccsMap.put(addMapping.Account__c, new List<Address_Mapping__c>{addMapping});
        		}
        	}
        	****/        		
            //system.debug('activeBillingAddressMappingsWithAccsMap is' + activeBillingAddressMappingsWithAccsMap);
        	/****
        	List<Address_Mapping__c> activeMailingAddressMappingsWithAccs = new List<Address_Mapping__c>();
        	activeMailingAddressMappingsWithAccs  = [Select Id, Contact__c,	Address_Type__c, Active__c, Account__c From Address_Mapping__c where Account__c != null and Account__c =: accIds  
        	and Active__c = true and Address_Type__c =: Utils.aamSettings.Cont_Mailing_Addr_Source__c == null ? AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS : Utils.aamSettings.Cont_Mailing_Addr_Source__c];
        		
        	Map<Id, List<Address_Mapping__c>> activeMailingAddressMappingsWithAccsMap = new Map<Id, List<Address_Mapping__c>>(); 
        	for (Address_Mapping__c addMapping : activeMailingAddressMappingsWithAccs){
       			if (activeMailingAddressMappingsWithAccsMap.get(addMapping.Account__c) != null){
       				activeMailingAddressMappingsWithAccsMap.get(addMapping.Account__c).add(addMapping);
       			}
       			else{
       				activeMailingAddressMappingsWithAccsMap.put(addMapping.Account__c, new List<Address_Mapping__c>{addMapping});
       			}
       		}
			****/
           	//system.debug('activeMailingAddressMappingsWithAccsMap is' + activeMailingAddressMappingsWithAccsMap);

        	List<Address_Mapping__c> activeMailingAddressMappingsWithCons = new List<Address_Mapping__c>();
        	activeMailingAddressMappingsWithCons  = [Select Id, Contact__c,	Address_Type__c, Active__c, Account__c From Address_Mapping__c where Contact__c != null and Contact__c =: conIds  
        	and Active__c = true and Address_Type__c =: Utils.aamSettings.Cont_Mailing_Addr_Source__c == null ? AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS : Utils.aamSettings.Cont_Mailing_Addr_Source__c];
        		
        	Map<Id, List<Address_Mapping__c>> activeMailingAddressMappingsWithConsMap = new Map<Id, List<Address_Mapping__c>>(); 
        	for (Address_Mapping__c addMapping : activeMailingAddressMappingsWithCons){
       			if (activeMailingAddressMappingsWithConsMap.get(addMapping.Contact__c) != null){
       				activeMailingAddressMappingsWithConsMap.get(addMapping.Contact__c).add(addMapping);
       			}
       			else{
       				activeMailingAddressMappingsWithConsMap.put(addMapping.Contact__c, new List<Address_Mapping__c>{addMapping});
       			}
       		}

       		List<Contact> updateContactswithEmptyMailingAddress = new List<Contact>();        		
           	for (Contact con :newContacts){
           		//if (activeBillingAddressMappingsWithAccsMap.get(con.AccountId) != null && activeMailingAddressMappingsWithAccsMap.get(con.AccountId) == null){
           		//if ( activeMailingAddressMappingsWithAccsMap.get(con.AccountId) == null ){
           		if ( activeMailingAddressMappingsWithConsMap.get(con.Id) == null ){
           			system.debug('chenxu is activeMailingAddressMappingsWithConsMap' + activeMailingAddressMappingsWithConsMap.get(con.Id));
           			con.MailingStreet = null;
           			con.MailingState = null;
           			con.MailingPostalCode = null;
           			con.MailingLongitude = null;
           			con.MailingLatitude = null;
           			con.MailingCountry = null;
           			con.MailingCity = null;
           			updateContactswithEmptyMailingAddress.add(con);
           		}
           	}
           	//update updateContactswithEmptyMailingAddress;
        //}
    	
    }
	public static void zeroActiveCount (List<Contact> newContacts){
		for (Contact con : newContacts){
			con.Address_Mappings_Active_Count__c = 0;
		}
	}
    

}