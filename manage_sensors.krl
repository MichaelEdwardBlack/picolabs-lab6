ruleset com.blacklite.krl.manage_sensors {
 meta {
   shares __testing, showChildren, sensors, temperatures

   use module io.picolabs.wrangler alias wrangler
 }
 global {
   __testing = { "queries":
     [ { "name": "__testing" }
     , { "name": "showChildren" }
     , { "name": "sensors" }
     , { "name": "temperatures" }
     ] , "events":
     [ { "domain": "sensor", "type": "new_sensor", "attrs": [ "name" ] }
     , { "domain": "sensor", "type": "unneeded_sensor", "attrs": [ "name" ] }
     ]
   }

   showChildren = function() {
     wrangler:children()
   }

   sensors = function() {
     ent:sensors
   }

   temperatures = function(child) {
     result = ent:sensors.map(function(x) {
       eci = x{"eci"}.klog("eci: ");
       url = "http://localhost:8080/sky/cloud/" + eci + "/com.blacklite.krl.temperature_store/temperatures";
       response = http:get(url);
       response{"content"}
     });

     result
   }
 }

 rule add_sensor {
   select when sensor new_sensor
   pre {
     name = event:attr("name")
     exists = ent:sensors >< name
     eci = meta:eci
   }
   if exists then
     send_directive("new_sensor", {"status":"not added", "message":"this sensor already exists"})
   notfired {
     raise wrangler event "child_creation"
       attributes {
         "name": name,
         "color": "#ffff00",
         "rids": [
           "com.blacklite.krl.temperature_store",
           "com.blacklite.krl.wovyn_base",
           "com.blacklite.krl.sensor_profile" ]
       }
   }
 }

 rule store_new_sensor {
   select when wrangler child_initialized
   pre {
     sensor_name = event:attrs{"name"}
     pico_ids = {"id": event:attrs{"id"}, "eci": event:attr("eci") }
   }

   if sensor_name.klog("sensor to add: ") then
   event:send(
       { "eci": pico_ids{"eci"}, "eid": "update-profile",
         "domain": "sensor", "type": "profile_updated",
         "attrs": { "name": sensor_name }
       }
   )

   fired {
     ent:sensors := ent:sensors.defaultsTo({});
     ent:sensors{[sensor_name]} := pico_ids
   }
 }

 rule delete_sensor {
   select when sensor unneeded_sensor
   pre {
     sensor_name = event:attrs{"name"}
     exists = ent:sensors >< sensor_name
   }

   if exists then
     send_directive("deleting_sensor", {"name": sensor_name})

   fired {
     raise wrangler event "child_deletion"
       attributes {"name": sensor_name};
   }
 }

 rule remove_stored_sensor {
   select when wrangler delete_child
   pre {
     sensor_name = event:attrs{"name"}
   }

   if sensor_name.klog("sensor to delete: ") then noop()

   fired {
     ent:sensors := ent:sensors.delete([sensor_name])
   }
 }
}
