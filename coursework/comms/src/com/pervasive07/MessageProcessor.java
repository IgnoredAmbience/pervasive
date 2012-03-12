package com.pervasive07;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class MessageProcessor {
	
	SerialMsg message;
	int offset;
	long timestamp;
	int nodeID;
	double temp;
	int lux;
	boolean fire;
	
	public MessageProcessor(SerialMsg m, long time) {
		message = m ;
		offset = message.baseOffset();
		timestamp = time;
		nodeID = message.get_srcid();
		temp = convertTemp(message.get_temperature());
		lux = message.get_light();
		fire = (0 != message.get_fire());
		
		setup();
	}
	
	private double convertTemp(int adc) {
		final int ADC_FS = 1023;
		final int r1 = 10000; // Ohms
		final double a = 0.001010024;
		final double b = 0.000242127;
		final double c = 0.000000146;
		
		double r_thr = r1*(ADC_FS-adc)/adc;
		
		double ln = Math.log(r_thr);
		double recip = a + b * ln + c * Math.pow(ln, 3);
		
		return 1/recip;
	}
	
	private void setup() {
	    JSONObject json = getJSON();
	    RestClient sendClient = new RestClient();
	    sendClient.sendJSON(json);
	}

	public JSONObject getJSON(){
		JSONObject json = new JSONObject();
		
		
		try{
		json.put("groupId", "7");
		json.put("key", "AWgbUdRae");
		json.put("groupName", "Keeley and friends");
		json.put("sensorData", getSensorIDList());
		}
		catch (JSONException e){
			e.printStackTrace();
		}
		return json;
	}

	private JSONArray getSensorIDList() {
		JSONArray sensorIDList = new JSONArray();
		JSONObject jsonInternalObject = new JSONObject();
		try{
			jsonInternalObject.put("sensorId", nodeToSensorID());
			jsonInternalObject.put("nodeId", nodeID);
			jsonInternalObject.put("timestamp", timestamp);
			jsonInternalObject.put("temp", temp);
			jsonInternalObject.put("lux", JSONObject.NULL);
		}
		catch (JSONException e){
			e.printStackTrace();
		}
		sensorIDList.put(jsonInternalObject);

		JSONObject jsonInternalObject2 = new JSONObject();
		try{
			jsonInternalObject2.put("sensorId", nodeToSensorID());
			jsonInternalObject2.put("nodeId", nodeID);
			jsonInternalObject2.put("timestamp", timestamp);
			jsonInternalObject2.put("temp", JSONObject.NULL);
			jsonInternalObject2.put("lux", lux);
		}
		catch (JSONException e){
			e.printStackTrace();
		}
		sensorIDList.put(jsonInternalObject2);
		
		return sensorIDList;
	}

	// Takes the nodeID and gives it a logical id of 0, 1 or 2
	public int nodeToSensorID(){
		// #TODO check these nodeIDs are right
		switch (nodeID) {
		case 25:
			return 0;
		case 26:
			return 1;
		case 27:
			return 2;
		default:
			return -1;

		}
	}

	public boolean getFire() {
		
		return fire;
	}

}
