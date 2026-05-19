
 var f = flightplan();
var wp = f.getWP(6);
print("wp :"~wp.alt_cstr_type~" "~wp.alt_cstr);
wp2.setAltitude(2000,"below");
print("wp :"~wp.alt_cstr_type~" "~wp.alt_cstr);


var f = flightplan();
var wp = f.getWP(21);
print("wp :"~wp.wp_name);
print("leg_bearing :"~wp.leg_bearing);
var o = getprop("orientation/heading-deg");
print("heading "~o);

print("wp :"~wp.alt_cstr_type~" "~wp.alt_cstr~" role "~wp.wp_role);


print (b777.verticalMode.VNAV_PTH);

b777.afdsReload();

io.load_nasal(getprop("/sim/aircraft-dir") ~ "/Nasal/AFDS.nas","b777");


var path = "/home/jylebleu/Documents/fg/default_fp.xml";
var f = flightplan(path);
f.activate();


var f = flightplan();
var current_wp = b777.afds.FMC_current_wp.getValue();
var nextWpHdg = getprop("autopilot/route-manager/route/wp["~(current_wp + 1)~"]/leg-bearing-true-deg");
print(nextWpHdg);
var wp = f.getWP(current_wp+1);
print(wp.id);

io.load_nasal(getprop("/sim/aircraft-dir") ~ "/Nasal/AFDS.nas","b777");
b777.afds._calculateTopOfDescent();