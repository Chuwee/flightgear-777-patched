var _globals = {};

load_nasal(narcissedir~"mockproputil.nas");
load_nasal(narcissedir~"mockflightplan.nas");
load_nasal(narcissedir~"mockprops.nas","props");
load_nasal(narcissedir~"mocksvg.nas","canvas");
load_nasal("../AFDS.nas","b777");
load_nasal(narcissedir~"nasmine.nas","nsm");

nsm.describe("an Auto Pilot Flight Director System",func() {
    nsm.it("should be able to be created",func(){
        var afds = b777.AFDS.new();;
        nsm.expect(1).toBe(1);
    });
});

nsm.describe("on calculate top of descent",func() {
   
    var afds = b777.AFDS.new();

    var destination_elevation = 2000;
    setprop("autopilot/route-manager/destination/field-elevation-ft",destination_elevation);

    nsm.it("should calculate on altitude  more than 35000 ft",func(){

        afds.FMC_cruise_alt.setValue(45000);

        afds._calculateTopOfDescent();

        nsm.expect(afds.top_of_descent.getValue()).toBe(141.9);

    });
    nsm.it("should calculate on altitude between 35000 and 25000",func(){

        afds.FMC_cruise_alt.setValue(34000);

        afds._calculateTopOfDescent();

        nsm.expect(afds.top_of_descent.getValue()).toBe(102.4);

    });
    nsm.it("should calculate on altitude between 15000 and 25000",func(){

        afds.FMC_cruise_alt.setValue(24000);

        afds._calculateTopOfDescent();

        nsm.expect(afds.top_of_descent.getValue()).toBe(68.2);

    });
    nsm.it("should calculate on altitude less than 15000",func(){

        afds.FMC_cruise_alt.setValue(14000);

        afds._calculateTopOfDescent();

        nsm.expect(afds.top_of_descent.getValue()).toBe(36);

    });

    nsm.it("should get the first restriction altitude below",func(){

        createFlightplan();
        var f = flightplan();
        f.destination_runway = "36";
         f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'below'),
            3 : WP.new(12,3000,'above'),
            4 : WP.new(55,20000,'below'),
            5 : WP.new(80,4000,'at'),
            6 : "36"

        };
        f.size = 7;

        var total_distance = 100;
        var wp = afds._getFirstAltitudeRestrictionOnDescent(total_distance);

        nsm.expect(wp.alt_cstr).toBe(20000);

    });

    nsm.it("should get the first restriction altitude at",func(){

        createFlightplan();
        var f = flightplan();
        f.destination_runway = "36";
         f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'below'),
            3 : WP.new(12,3000,'at'),
            4 : WP.new(60,10000,'at'),
            5 : WP.new(80,4000,'at'),
            6 : "36"

        };
        f.size = 7;

        var total_distance = 100;
        var wp = afds._getFirstAltitudeRestrictionOnDescent(total_distance);

        nsm.expect(wp.alt_cstr).toBe(10000);

    });

    nsm.it("should ignore all restrictions 200 miles before end of descent",func(){

        createFlightplan();
        var total_distance = 600;

        var f = flightplan();
        f.destination_runway = "36";
         f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'below'),
            3 : WP.new(12,3000,'at'),
            4 : WP.new(220,35000,'at'),
            5 : WP.new(320,37000,'at'),
            6 : WP.new(410,20000,'at'),
            7 : "36"

        };
        f.size = 8;

        var wp = afds._getFirstAltitudeRestrictionOnDescent(total_distance);

        nsm.expect(wp.alt_cstr).toBe(20000);

    });

    nsm.it("should get no wp if no altitude restriction found",func(){

        createFlightplan();
        var f = flightplan();
        f.destination_runway = "36";
         f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'below'),
            3 : WP.new(12,3000,'at'),
            4 : WP.new(55,0),
            5 : WP.new(85,0),
            6 : "36"

        };
        f.size = 7;

        var total_distance = 100;
        var wp = afds._getFirstAltitudeRestrictionOnDescent(total_distance);

        nsm.expect(wp).toBeUnDefined();

    });


    nsm.it("should get nil if the flight plan is empty",func(){

        createFlightplan();

        var total_distance = 100;
        var wp = afds._getFirstAltitudeRestrictionOnDescent(total_distance);

        nsm.expect(wp).toBeUnDefined();

    });

    nsm.it("should use flight plan altitude restrication to calculate top of descent",func(){

        var destination_elevation = 2000;
        setprop("autopilot/route-manager/destination/field-elevation-ft",destination_elevation);
        setprop("autopilot/route-manager/total-distance",90);

        createFlightplan();
        var f = flightplan();
        f.destination_runway = "36";
        f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'below'),
            3 : WP.new(12,3000,'above'),
            4 : WP.new(60,20000,'below'),
            5 : WP.new(80,4000,'at'),
            6 : "36"

        };
        f.size = 7;

        afds.FMC_cruise_alt.setValue(34000);

        afds._calculateTopOfDescent();

        nsm.expect(afds.top_of_descent.getValue()).floatToBe(74.8);

    });


});



nsm.describe("on getting next restriction",func() {

    var afds = b777.AFDS.new();


    nsm.it("should no nothing if no wp is found",func(){
        

        createFlightplan();
        var f = flightplan();
        f.destination_runway = WP.new(90);
        f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'below'),
            3 : WP.new(12,3000,'above'),
            4 : WP.new(60,20000),
            5 : WP.new(80,4000),
            6 : WP.new(90),

        };
        f.size = 7;

        afds.altitude_restriction_idx.setValue(2);
        
        afds.getNextRestriction(4);

        nsm.expect(afds.altitude_restriction_idx.getValue()).toBe(2);

    });

    nsm.it("should not take into account deleted resrictions",func(){
        setprop("autopilot/route-manager/total-distance",90);
        setprop("autopilot/route-manager/route/wp[2]/distance-along-route-nm",11);
        setprop("autopilot/route-manager/route/wp[3]/distance-along-route-nm",12);
        setprop("autopilot/route-manager/route/wp[4]/distance-along-route-nm",15);
        createFlightplan();
        var f = flightplan();
        f.destination_runway = WP.new(90);
        f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'below'),
            3 : WP.new(12,3000,'delete'),
            4 : WP.new(15,20000,'at'),
            5 : WP.new(80,4000),
            6 : WP.new(90),

        };
        f.size = 7;

        afds.altitude_restriction_idx.setValue(2);
        
        afds.getNextRestriction(3);

        nsm.expect(afds.altitude_restriction_idx.getValue()).toBe(4);
    });
});


nsm.describe("on removing next restriction",func() {

    var tAfds = b777.AFDS.new();


    nsm.it("should  remove a restriction",func(){
        

        var f = flightplan();
        var toBeDeleted = WP.new(13,5000,'at');
        f.destination_runway = WP.new(90);
        f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'above'),
            3 : WP.new(12,3000,'below'),
            4 : toBeDeleted,
            5 : WP.new(60,20000),
            6 : WP.new(80,4000),
            7 : WP.new(90),

        };
        f.size = 8;

        tAfds.top_of_descent.setValue(12);

        var currentAltitude = 3500;
        var mcpAltitude = 10000;
        setprop("autopilot/route-manager/total-distance",90);        

        tAfds.clearRestictionOnClimb(currentAltitude, mcpAltitude);


        nsm.expect(toBeDeleted.alt_cstr_type).toBe("delete");

        
    });

    nsm.it("should not remove a restriction after the T/D",func(){
        

        var f = flightplan();
        var toRemain = WP.new(80,4000,'at');
        f.destination_runway = WP.new(90);
        f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,0),
            3 : WP.new(12,0),
            4 : WP.new(50,0),
            5 : WP.new(60,0),
            6 : toRemain,
            7 : WP.new(90),

        };
        f.size = 8;

        tAfds.top_of_descent.setValue(45);

        var currentAltitude = 3500;
        var mcpAltitude = 10000;        

        tAfds.clearRestictionOnClimb(currentAltitude, mcpAltitude);


        nsm.expect(toRemain.alt_cstr_type).toBe("at");

        
    });

    nsm.it("should not remove restriction if current altitude is almost equal to current restriction altitude",func(){
        

        var f = flightplan();
        var toBeDelted = WP.new(12,5000,'at');
        f.destination_runway = WP.new(90);
        f.wps = {
            0 : WP.new(0,100),
            1 : WP.new(9,0),
            2 : WP.new(11,2000,'below'),
            3 : toBeDelted,
            4 : WP.new(50,0),
            5 : WP.new(60,0),
            6 : WP.new(80,4000,'at'),
            7 : WP.new(90),

        };
        f.size = 8;

        tAfds.top_of_descent.setValue(45);

        var currentAltitude = 5001;
        var mcpAltitude = 10000;        

        tAfds.clearRestictionOnClimb(currentAltitude, mcpAltitude);


        nsm.expect(toBeDelted.alt_cstr_type).toBe("delete");

        
    });

});
      
