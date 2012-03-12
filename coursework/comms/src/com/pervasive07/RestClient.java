package com.pervasive07;

import java.io.IOException;

import org.restlet.data.ChallengeResponse;
import org.restlet.data.ChallengeScheme;
import org.restlet.data.MediaType;
import org.restlet.data.Preference;
import org.restlet.data.Status;
import org.restlet.representation.Representation;
import org.restlet.representation.StringRepresentation;
import org.restlet.resource.ClientResource;
import org.restlet.resource.ResourceException;
import org.json.*;

public class RestClient implements RestInterface{


	ClientResource processingResource;
	ClientResource collectionResource;
	ClientResource fireResource;
	String couchDbLocation;
	

	public RestClient() {
		
		
		// Our CouchDB Instance
		couchDbLocation = new String("http://146.169.37.129:5984/sensor_data/");
		//processingResource = new ClientResource(); // #TODO FIX URI 5984
		
		// The data collection resource
		collectionResource = new ClientResource("http://146.169.37.102:8080/energy-data-service/energyInfo/dataSample");
		collectionResource.getRequest().getClientInfo().getAcceptedMediaTypes().add(new Preference<MediaType>(MediaType.APPLICATION_JSON));
		fireResource = new ClientResource("http://146.169.37.102:8080/energy-data-service/energyInfo/event");
	}

	public void sendJSON(JSONObject json) {

		sendProcessingJSON(json);
		sendCollectionJSON(json);
	}

	/*
	 * Sends the data for processing to CouchDB
	 */
	public void sendProcessingJSON(JSONObject json, long timestamp) {
		
	

		
		processingResource = new ClientResource(couchDbLocation + timestamp);
		System.out.println(processingResource.toString());
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
		processingResource.put(jsonStringRepresentation);
	}

	/*
	 * Sends the data for display to the energy data service
	 */
	public void sendCollectionJSON(JSONObject json){
		
		StringRepresentation jsonStringRepresentation = new StringRepresentation(json.toString());
		jsonStringRepresentation.setMediaType(MediaType.APPLICATION_JSON);
		Representation result = collectionResource.post(jsonStringRepresentation);
		try {
			System.out.println(result.getText());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
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
			
			fireJSON.put("groupId", "7");
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
}
