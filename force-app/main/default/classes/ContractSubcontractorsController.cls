public with sharing class ContractSubcontractorsController {
    
    @AuraEnabled(cacheable=true)
    public static List<Subcontractor__c> getSubcontractorDetails(Id contractId) {
        try {
            // Add debug for contract ID
            System.debug('Querying for Contract ID: ' + contractId);

            List<Subcontractor__c> subcontractors = [
                SELECT Id, 
                       Contact__c,
                       Contact__r.Name,
                       Allocation_Amount__c,
                       Allocation_Percent__c,
                       (
                           SELECT Id, Last_Billed_Up_To_Date__c 
                           FROM Subcontractor_Invoices__r 
                           WHERE Last_Billed_Up_To_Date__c != null
                           ORDER BY Last_Billed_Up_To_Date__c DESC 
                           LIMIT 1
                       )
                FROM Subcontractor__c
                WHERE Contract__c = :contractId
                WITH SECURITY_ENFORCED
            ];

            // Add debug for results
            System.debug('Found ' + subcontractors.size() + ' subcontractors');
            for(Subcontractor__c sub : subcontractors) {
                System.debug('Subcontractor: ' + sub.Contact__r.Name);
                System.debug('Invoice count: ' + (sub.Subcontractor_Invoices__r != null ? sub.Subcontractor_Invoices__r.size() : 0));
                if(sub.Subcontractor_Invoices__r != null && !sub.Subcontractor_Invoices__r.isEmpty()) {
                    System.debug('Latest billed date: ' + sub.Subcontractor_Invoices__r[0].Last_Billed_Up_To_Date__c);
                }
            }

            return subcontractors;

        } catch (Exception e) {
            System.debug('Error in getSubcontractorDetails: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving subcontractor details: ' + e.getMessage());
        }
    }
}