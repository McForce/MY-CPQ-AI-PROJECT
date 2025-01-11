trigger CPQQuoteTrigger on SBQQ__Quote__c (after insert) {
    // Call handler for after insert event
    if(Trigger.isAfter && Trigger.isInsert) {
        CPQQuoteAmendmentHandler.handleAfterInsert(Trigger.new);
    }
}