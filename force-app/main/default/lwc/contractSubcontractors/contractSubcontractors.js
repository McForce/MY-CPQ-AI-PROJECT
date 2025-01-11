// contractSubcontractors.js
import { LightningElement, api, wire, track } from 'lwc';
import getSubcontractorDetails from '@salesforce/apex/ContractSubcontractorsController.getSubcontractorDetails';

export default class ContractSubcontractors extends LightningElement {
    @api recordId; // Contract Id passed from the parent
    @track subcontractors;
    @track error;
    @track isLoading = true;

    // Simplified columns to show only required fields
    columns = [
        {
            label: 'Subcontractor Name',
            fieldName: 'contactUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'contactName' },
                target: '_blank'
            }
        },
        { 
            label: 'Last Billed Date', 
            fieldName: 'lastBilledDate',
            type: 'date',
            typeAttributes: {
                year: "numeric",
                month: "long",
                day: "2-digit"
            }
        }
    ];

    // Wire the Apex method to get data
    @wire(getSubcontractorDetails, { contractId: '$recordId' })
    wiredSubcontractors({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.subcontractors = data.map(record => ({
                id: record.Id,
                contactName: record.Contact__r.Name,
                contactUrl: `/${record.Contact__c}`,
                lastBilledDate: record.Subcontractor_Invoices__r?.[0]?.Last_Billed_Up_To_Date__c
            }));
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading subcontractor details: ' + error.message;
            this.subcontractors = undefined;
        }
        this.isLoading = false;
    }

    get noData() {
        return !this.isLoading && !this.error && (!this.subcontractors || this.subcontractors.length === 0);
    }
}