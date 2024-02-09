import { LightningElement, wire} from 'lwc';
import getSesID from'@salesforce/apex/importTriggerBtnCtrl.getSesID';

export default class ImportTriggerBtnFetchAPI extends LightningElement {
    @wire(getSesID)
    ssid;

    handleFileUpload(event) {
        const files = event.detail.files;
    
        if (files.length > 0) {
          const file = files[0];
          console.log(file);
          // start reading the uploaded csv file
          //this.read(file);
          //console.log();
        }
      }
      
      async read(file) {
        try {
          const result = await this.load(file);
          console.log(result);
          // execute the logic for parsing the uploaded csv file
          console.log(this.parse(result));
        } catch (e) {
          this.error = e;
        }
      }
    
      async load(file) {
        return new Promise((resolve, reject) => {
          const reader = new FileReader();
    
          reader.onload = () => {
            resolve(reader.result);
          };
          reader.onerror = () => {
            reject(reader.error);
          };
          reader.readAsText(file);
        });
      }

      async handleClick(){
        console.log(this.ssid)
        fetch("https://deutschetelekom4.my.salesforce.com/services/data/v59.0/jobs/ingest", { method: "POST", headers: {'Content-Type' : "application/json", 'Authorization' : "Bearer " + this.ssid.data}, body: '{"externalIdFieldName":"Id","lineEnding":"CRLF","operation":"insert","object":"Account","contentType":"CSV"}' })
                .then((response) => response.json())
                .then((data) => {
                    console.log("🚀 ~ data", data);
                    this.imageURL = data[0].url;
                });
      }
}