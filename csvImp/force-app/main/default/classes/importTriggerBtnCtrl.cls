public without sharing class importTriggerBtnCtrl {

    public class SessionId {
        public string sessionId;
    }
    
	@AuraEnabled
    public static void importHandle(){
         String objectName = 'Account';
             String operation = 'insert';
             String contentDocumentId = '0690700000abmyDAAQ';
             ContentVersion cv = [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId =: contentDocumentId  order by createddate desc][0];
            
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v59.0/jobs/ingest');
            request.setHeader('content-type', 'application/json' );
        	SessionId sessionJson = new SessionId();
        	sessionJson = (SessionId)JSON.deserialize(Page.vfUtilities.getContent().toString(), SessionId.class);
        	String ssid = sessionJson.sessionId;
        	system.debug('ssid -> ' + ssid);
            request.setHeader('Authorization' ,'Bearer '+/*userInfo.getSessionId()*/ssid );  
                    String body = '{ '+
                                    '"externalIdFieldName": "Id",'+  
                                    '"lineEnding": "CRLF",'+ 
                                    '"operation": "'+operation+'",'+ 
                                    '"object": "'+objectName+'",'+ 
                                    '"contentType": "CSV"'+
                                  '}';
            
            request.setBody(body);
        	system.debug(request.getHeader('Authorization'));
            Http h = new Http();
            HttpResponse resp = h.send(request);
            system.debug(resp);
            
             if(resp.getStatusCode() <= 299) {
             Map<String, Object> respMap = (Map<String, Object>) Json.deserializeUntyped(resp.getBody());
             String jobId = (String)respMap.get('id');
                        
            //second request to store data
            HttpRequest request1 = new HttpRequest();
            request1.setMethod('PUT');
            request1.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v59.0/jobs/ingest/'+jobId+'/batches');
            request1.setHeader('content-type', 'text/csv' );
            request1.setHeader('Authorization' ,'Bearer '+/*userInfo.getSessionId()*/ssid );  
                        
            request1.setBody(cv.VersionData.toString());
            Http h1 = new Http();
            HttpResponse resp1 = h1.send(request1);
            
            
            if(resp1.getStatusCode() <= 299) {
                //third request to start processing
                HttpRequest request2 = new HttpRequest();
                request2.setMethod('PATCH');
                request2.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v59.0/jobs/ingest/'+jobId);
                request2.setHeader('content-type', 'application/json' );
                request2.setHeader('Authorization' ,'Bearer '+/*userInfo.getSessionId()*/ssid );  
                
                request2.setBody('{ "state" : "UploadComplete" }');
                Http h2 = new Http();
                HttpResponse resp2 = h2.send(request2);
               
                //Delete the uploaded file as we no longer need that
                //Delete [SELECT ID FROM contentDocument WHERE ID =: contentDocumentId];
                if(resp2.getStatusCode() <= 299) {
                    system.debug('Data processing Start '+jobId);
                } else {
                 system.debug('There was an error. Please contact your admin.');
                }
            }
        }
	
    }
    
    @AuraEnabled(cacheable=true)
    public static String getSesID(){
        //test
        SessionId sessionJson = new SessionId();
        sessionJson = (SessionId)JSON.deserialize(Page.vfUtilities.getContent().toString(), SessionId.class);
        String ssid = sessionJson.sessionId;
        return ssid;
    }
}