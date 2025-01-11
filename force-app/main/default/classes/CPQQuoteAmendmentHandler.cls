public with sharing class CPQQuoteAmendmentHandler {
    // Private constructor to prevent instantiation
    private CPQQuoteAmendmentHandler() {}
    
    // Main handler method for trigger
    public static void handleAfterInsert(List<SBQQ__Quote__c> newQuotes) {
        processAmendmentQuotes(newQuotes);
    }
    
    // Process amendment quotes and clone subcontractors
    private static void processAmendmentQuotes(List<SBQQ__Quote__c> quotes) {
        List<SBQQ__Quote__c> amendmentQuotes = new List<SBQQ__Quote__c>();
        
        // Filter for amendment quotes
        for(SBQQ__Quote__c quote : quotes) {
            if(quote.SBQQ__Type__c == 'Amendment' && quote.SBQQ__MasterContract__c != null) {
                amendmentQuotes.add(quote);
            }
        }
        
        if(!amendmentQuotes.isEmpty()) {
            cloneSubcontractorsForQuotes(amendmentQuotes);
        }
    }
    
    // Clone subcontractors for multiple quotes
    private static void cloneSubcontractorsForQuotes(List<SBQQ__Quote__c> amendmentQuotes) {
        // Create map of Contract Id to Quote Id for bulk processing
        Map<Id, Id> contractToQuoteMap = new Map<Id, Id>();
        for(SBQQ__Quote__c quote : amendmentQuotes) {
            contractToQuoteMap.put(quote.SBQQ__MasterContract__c, quote.Id);
        }
        
        try {
            // Query all subcontractors for all contracts in one query
            List<Subcontractor__c> originalSubcontractors = [
                SELECT Id, 
                       Contact__c,
                       Contact__r.Name,
                       Contract__c,
                       Allocation_Amount__c,
                       Allocation_Percent__c
                FROM Subcontractor__c
                WHERE Contract__c IN :contractToQuoteMap.keySet()
                WITH SECURITY_ENFORCED
            ];
            
            // Create new contractor records for the amendment quotes
            List<Contractor__c> newContractors = new List<Contractor__c>();
            
            for(Subcontractor__c sub : originalSubcontractors) {
                Id newQuoteId = contractToQuoteMap.get(sub.Contract__c);
                if(newQuoteId != null) {
                    Contractor__c newContractor = new Contractor__c(
                        Quote__c = newQuoteId,  // Assuming this is the correct field name
                        Contact__c = sub.Contact__c,
                        Allocation_Amount__c = sub.Allocation_Amount__c,
                        Allocation__c = sub.Allocation_Percent__c
                        // Removed fields that don't exist in your org
                    );
                    newContractors.add(newContractor);
                }
            }
            
            if(!newContractors.isEmpty()) {
                insert newContractors;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in CPQQuoteAmendmentHandler: ' + e.getMessage());
            throw new CPQQuoteAmendmentException('Error cloning subcontractors: ' + e.getMessage());
        }
    }
    
    // Custom exception class
    public class CPQQuoteAmendmentException extends Exception {}
}