public without sharing class MergeServices {
    
    /**
    	Merges Address Mappings related to the passed Addresses by fields: Account__c, Contact__c, Address__c, Address_Type__c, Active__c, Primary__c, CreatedDate, Removed_Date__c
    */
    public static MappingsMergeResult mergeMappings( Address__c addressToUpdate, List<Address__c>addressesToDelete ){
    	List<Address_Mapping__c> addressMappings = selectAddressMappingsForMerging(addressToUpdate, addressesToDelete);
    	checkAddressMappingsBeforeMerging(addressMappings);
        MergeServices.MappingsMergeResult mergeResult = mergeSelectedMappings( addressMappings );
        for( Address_Mapping__c mapping : mergeResult.mappingsToUpdate ) { //reparent address mappings from addresses that will be removed to address that is left
            mapping.Address__c = addressToUpdate.Id;
        }
        return mergeResult;
    }
    
    private static List<Address_Mapping__c> selectAddressMappingsForMerging(Address__c addressToUpdate, List<Address__c>addressesToDelete){
        return [ 
        		SELECT Account__c, Contact__c, Address_Type__c, Active__c, Primary__c, CreatedDate, Removed_Date__c
                FROM Address_Mapping__c
                WHERE 
                 		Address__c IN :addressesToDelete 
                 		OR Address__c = :addressToUpdate.Id
                ORDER BY 
                		Primary__c Desc,
                		CreatedDate Asc
        ];
    }
    
    private static void checkAddressMappingsBeforeMerging(List<Address_Mapping__c> addressMappings){
    	for (Address_Mapping__c mapping : addressMappings){
    		if (mapping.Account__c != null && mapping.Contact__c != null){
    			throw new AamException(Label.Address_Mapping_instance_has_both_Contact_and_Account_fields_populated + ' (' + mapping.Id + ')');
    		}
    	}
    }
    
    private static MappingsMergeResult mergeSelectedMappings( List<Address_Mapping__c> addressMappings ){
    	Map<String, Address_Mapping__c> mappingsToUpdate = new Map<String, Address_Mapping__c>();
    	List<Address_Mapping__c> mappingsToDelete = new List<Address_Mapping__c>();
    	for (Address_Mapping__c mapping : addressMappings){
    		String keyValue = getKeyFromMapping(mapping);
    		if ( mappingsToUpdate.containsKey(keyValue) ){
    			mappingsToDelete.add(mapping);
    		}else{
   				mappingsToUpdate.put(keyValue, mapping);
    		}
    	}
    	return new MappingsMergeResult(mappingsToUpdate.values(), mappingsToDelete);
    }
    
    private static String getKeyFromMapping(Address_Mapping__c mapping){
    	List<String> keyValues = new List<String>{
    			mapping.Account__c, 
    			mapping.Contact__c, 
    			mapping.Address_Type__c, 
    			String.valueOf(mapping.Active__c),
    			mapping.Active__c != true ? String.valueOf( mapping.CreatedDate.date() ) : '',
    			mapping.Active__c != true ? String.valueOf( mapping.Removed_Date__c ) : ''
    	};
    	return String.join(keyValues, '-');
    }
	
	public class MappingsMergeResult{
		
		public List<Address_Mapping__c> mappingsToUpdate { get; private set; }
		public List<Address_Mapping__c> mappingsToDelete { get; private set; }
		
		private MappingsMergeResult(List<Address_Mapping__c> mappingsToUpdate, List<Address_Mapping__c> mappingsToDelete){
			this.mappingsToUpdate = mappingsToUpdate;
			this.mappingsToDelete = mappingsToDelete;
		}
	}
	
}