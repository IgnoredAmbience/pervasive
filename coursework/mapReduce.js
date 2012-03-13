//MAP
function(doc) {
	emit(Math.round(doc.timestamp / 10000) * 10000, {"temp": doc.temp, "lux" : doc.lux, "sensorId" : doc.sensorId});
}

//REDUCE
function(keys, values, rereduce) {

/* Accumulators for JSON temp, lux, readings per sensor*/
	var acc_t = [0, 0, 0];
	var acc_l = [0, 0, 0];
	var acc_i = [0, 0, 0];

	for (var i = 0; i < values.length ; i++) {


		acc_t[values[i].sensorId] += values[i].temp;
		acc_l[values[i].sensorId] += values[i].lux;
		acc_i[values[i].sensorId]++;
	}
	ave_temp_0 = Math.round(acc_t[0] / acc_i[0] * 100) / 100;
	ave_lux_0 = Math.round(acc_l[0] / acc_i[0] * 100) / 100;
	ave_temp_1 = Math.round(acc_t[1] / acc_i[1] * 100) / 100;
	ave_lux_1 = Math.round(acc_l[1]/ acc_i[1] * 100) / 100;
	ave_temp_2 = Math.round(acc_t[2] / acc_i[2] * 100) / 100;
	ave_lux_2 = Math.round(acc_l[2] / acc_i[2] * 100) / 100;

	return ({"sensor0" : {"temp" : ave_temp_0, "lux" : ave_lux_0}, "sensor1" : {"temp" : ave_temp_1, "lux" : ave_lux_1}, "sensor2" : {"temp" : ave_temp_2, "lux" : ave_lux_2} } );
}