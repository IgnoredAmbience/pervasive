package com.pervasive07;

import java.io.IOException;

import org.restlet.data.ChallengeResponse;
import org.restlet.data.ChallengeScheme;
import org.restlet.data.MediaType;
import org.restlet.data.Status;
import org.restlet.representation.StringRepresentation;
import org.restlet.resource.ClientResource;
import org.json.*;

public class RestClient implements RestInterface{


	ClientResource processingResource;
	ClientResource collectionResource;
	ClientResource fireResource;
	

	public RestClient() {
		
		
		// Our CouchDB Instance
		processingResource = new ClientResource("http://146.169.37.129/"); // #TODO FIX URI
		
		// The data collection resource
		collectionResource = new ClientResource("http://146.169.37.102:8080/energy-data-service/energyInfo/dataSample");
		fireResource = new ClientResource("http://146.169.37.102:8080/energy-data-service/energyInfo/event");
	}

	public void sendJSON(JSONObject json) {

		sendProcessingJSON(json);
		sendCollectionJSON(json);
	}

	/*
	 * Sends the data for processing to CouchDB
	 */
	private void sendProcessingJSON(JSONObject json){
		// # TODO split up the json

		StringRepresentation jsonStringRepresentation;  


		// Add the client authentication to the call 
		ChallengeScheme scheme = ChallengeScheme.HTTP_BASIC; 
		ChallengeResponse authentication = new ChallengeResponse(scheme, "admin", "AWgbUdRae"); 
		processingResource.setChallengeResponse(authentication); 

		// Send the HTTP GET request 
		processingResource.get(); 

		if (processingResource.getStatus().isSuccess()) { 
			// Output the response entity on the JVM console 
			try {
				processingResource.getResponseEntity().write(System.out);
			} 
			catch (IOException e) {
				e.printStackTrace();
			} 
		} else if (processingResource.getStatus().equals(Status.CLIENT_ERROR_UNAUTHORIZED)) { 
			// Unauthorized access 
			System.out.println("Access authorized by the server, check your credentials"); 
		} else { 
			// Unexpected status 
			System.out.println("An unexpected status was returned: " + processingResource.getStatus()); 
		} 

		// Create a Representation from the json  
		jsonStringRepresentation = new StringRepresentation(json.toString());
		jsonStringRepresentation.setMediaType(MediaType.APPLICATION_JSON);
		processingResource.post(jsonStringRepresentation);
	}

	/*
	 * Sends the data for display to the energy data service
	 */
	private void sendCollectionJSON(JSONObject json){
		// # TODO split up the JSON
		
		StringRepresentation jsonStringRepresentation = new StringRepresentation(json.toString());
		jsonStringRepresentation.setMediaType(MediaType.APPLICATION_JSON);
		collectionResource.post(jsonStringRepresentation);

	}

	public void sendFireRepresentation(boolean[] fireStatus){
		JSONObject fireJSON = new JSONObject();
		JSONArray sensorIDList = new JSONArray();
		
		for (int index = 0; index < fireStatus.length; index++) {
			if (fireStatus[index]){
				sensorIDList.put(index);
			}
		}
		try {
			
			fireJSON.put("groupID", "7");
			fireJSON.put("key", "AWgbUdRae");
			fireJSON.put("groupName", "Keeley and friends");
			fireJSON.put("eventType", "FIRE");
			fireJSON.put("eventMessage", "There is a fire");
			fireJSON.put("sensorData", sensorIDList);


		} catch (JSONException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		fireResource.post(fireJSON);
		
		
	}

	public static void main(String[] args0) throws JSONException, IOException{
		RestClient rc = new RestClient();
		JSONObject js = new JSONObject();
		rc.sendJSON(js);
	}

}
