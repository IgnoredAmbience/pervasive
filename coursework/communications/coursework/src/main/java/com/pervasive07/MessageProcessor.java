package com.pervasive07;

import java.util.Collection;

import org.json.JSONArray;
import org.json.JSONObject;

import net.tinyos.message.*;


public class MessageProcessor {
	
	Messsage message;
	int offset;
	long timestamp;
	int nodeID;
	int temp;
	int lux;
	boolean fire;
	
	public MessageProcessor(Message m, long time) {
		message = m ;
		offset = message.baseOffset();
		timestamp = time;
		nodeID = Integer.parseInt(getUIntElement(offset + 8, 16));
		temp = Integer.parseInt(getUIntElement(offset + 56, 16));
		lux = Integer.parseInt(getUIntElement(offset + 72, 16));
		fire = (1 == getUIntElement(offset + 88, 1));
		
		setup();
	}
	
	private void setup() {
	    JSONObject json = getJSON();
	    RestClient sendClient = new RestClient();
	    sendClient.sendJSON(json);
	}

	private JSONObject getJSON(){
		JSONObject json = new JSONObject();
		
		json.put("groupID", "7");
		json.put("key", "AWgbUdRae");
		json.put("groupName", "Keeley and friends");
		json.put("sensorData", getSensorIDList());
		
		return json;
	}

	private JSONArray getSensorIDList() {
		
		JSONArray sensorIDList = new JSONArray();
		JSONObject jsonInternalObject = new JSONObject();
		
		jsonInternalObject.put("sensorId", nodeToSensorID());
		jsonInternalObject.put("nodeId", nodeID);
		jsonInternalObject.put("timestamp", timestamp);
		jsonInternalObject.put("temp", temp);
		jsonInternalObject.put("lux", lux);
		
		sensorIDList.put(jsonInternalObject);
		
		return sensorIDList;
	}
	
	// Takes the nodeID and gives it a logical id of 0, 1 or 2
	public int nodeToSensorID(){
		// #TODO check these nodeIDs are right
		switch (nodeID) {
		case 26:
			return 0;
		case 27:
			return 1;
		case 28:
			return 2;
		default:
			return -1;

		}
	}

	public boolean getFire() {
		
		return fire;
	}

}
