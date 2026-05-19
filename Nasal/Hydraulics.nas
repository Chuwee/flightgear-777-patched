####    jet engine hydraulics system    ####
####    Hyde Yamakawa    ####
####	Overhauled by Isaak Dieleman	####
####	Isaak 20251203: Hydraulic non-normals has unfinished states. Things that are not implemented yet because they rely on other systems are marked with TODO ####

var HYDR = {
    new : func(prop1){
        var m = { parents : [HYDR]};
        m.hydr = props.globals.getNode(prop1);
		
		# Pump states
        m.LEDP = m.hydr.initNode("system[0]/m-pump[0]/LEDP", 0, "BOOL");
        m.REDP = m.hydr.initNode("system[2]/m-pump[0]/REDP", 0, "BOOL");
        m.C1ACMP = m.hydr.initNode("system[1]/m-pump[0]/C1ACMP", 0, "BOOL");
        m.C2ACMP = m.hydr.initNode("system[1]/m-pump[2]/C2ACMP", 0, "BOOL");
        m.LACMP = m.hydr.initNode("system[0]/m-pump[1]/LACMP", 0, "BOOL");
        m.RACMP = m.hydr.initNode("system[2]/m-pump[1]/RACMP", 0, "BOOL");
        m.C1ADP = m.hydr.initNode("system[1]/m-pump[1]/C1ADP", 0, "BOOL");
        m.C2ADP = m.hydr.initNode("system[1]/m-pump[3]/C2ADP", 0, "BOOL");
        m.RAT = m.hydr.initNode("system[1]/m-pump[4]/RAT", 0, "BOOL");
		
		# Pump button light states
        m.LEDP_fine = m.hydr.initNode("system[0]/m-pump[0]/LEDP-NORMAL", 0, "BOOL");
        m.REDP_fine = m.hydr.initNode("system[2]/m-pump[0]/REDP-NORMAL", 0, "BOOL");
        m.C1ACMP_fine = m.hydr.initNode("system[1]/m-pump[0]/C1ACMP-NORMAL", 0, "BOOL");
        m.C2ACMP_fine = m.hydr.initNode("system[1]/m-pump[2]/C2ACMP-NORMAL", 0, "BOOL");
        m.LACMP_fine = m.hydr.initNode("system[0]/m-pump[1]/LACMP-NORMAL", 0, "BOOL");
        m.RACMP_fine = m.hydr.initNode("system[2]/m-pump[1]/RACMP-NORMAL", 0, "BOOL");
        m.C1ADP_fine = m.hydr.initNode("system[1]/m-pump[1]/C1ADP-NORMAL", 0, "BOOL");
        m.C2ADP_fine = m.hydr.initNode("system[1]/m-pump[3]/C2ADP-NORMAL", 0, "BOOL");
		m.RAT_fine = m.hydr.initNode("system[1]/m-pump[4]/RAT-NORMAL", 0, "BOOL");
		
		# Pump MFD Hyd panel states
        m.LEDP_MFD = m.hydr.getNode("system[0]/m-pump[0]/running", 0, "INT");
        m.REDP_MFD = m.hydr.getNode("system[2]/m-pump[0]/running", 0, "INT");
        m.C1ACMP_MFD = m.hydr.getNode("system[1]/m-pump[0]/running", 0, "INT");
        m.C2ACMP_MFD = m.hydr.getNode("system[1]/m-pump[2]/running", 0, "INT");
        m.LACMP_MFD = m.hydr.getNode("system[0]/m-pump[1]/running", 0, "INT");
        m.RACMP_MFD = m.hydr.getNode("system[2]/m-pump[1]/running", 0, "INT");
        m.C1ADP_MFD = m.hydr.getNode("system[1]/m-pump[1]/running", 0, "INT");
        m.C2ADP_MFD = m.hydr.getNode("system[1]/m-pump[3]/running", 0, "INT");
        m.RAT_MFD = m.hydr.getNode("system[1]/m-pump[4]/running", 0, "INT");
		
		# Pump hydraulic fluid sypply available states
		m.LEDP_supply = m.hydr.initNode("system[0]/m-pump[0]/LEDP-supply", 0, "BOOL");
        m.REDP_supply = m.hydr.initNode("system[2]/m-pump[0]/REDP-supply", 0, "BOOL");
        m.C1ACMP_supply = m.hydr.initNode("system[1]/m-pump[0]/C1ACMP-supply", 0, "BOOL");
        m.C2ACMP_supply = m.hydr.initNode("system[1]/m-pump[2]/C2ACMP-supply", 0, "BOOL");
        m.LACMP_supply = m.hydr.initNode("system[0]/m-pump[1]/LACMP-supply", 0, "BOOL");
        m.RACMP_supply = m.hydr.initNode("system[2]/m-pump[1]/RACMP-supply", 0, "BOOL");
        m.C1ADP_supply = m.hydr.initNode("system[1]/m-pump[1]/C1ADP-supply", 0, "BOOL");
        m.C2ADP_supply = m.hydr.initNode("system[1]/m-pump[3]/C2ADP-supply", 0, "BOOL");
		m.RAT_supply = m.hydr.initNode("system[1]/m-pump[4]/RAT-supply", 0, "BOOL");
		
		# Pump and reservoir states
		m.LEDP_press = m.hydr.initNode("system[0]/m-pump[0]/press-psi", 0, "DOUBLE");
        m.REDP_press = m.hydr.initNode("system[2]/m-pump[0]/press-psi", 0, "DOUBLE");
        m.C1ACMP_press = m.hydr.initNode("system[1]/m-pump[0]/press-psi", 0, "DOUBLE");
        m.C2ACMP_press = m.hydr.initNode("system[1]/m-pump[2]/press-psi", 0, "DOUBLE");
        m.LACMP_press = m.hydr.initNode("system[0]/m-pump[1]/press-psi", 0, "DOUBLE");
        m.RACMP_press = m.hydr.initNode("system[2]/m-pump[1]/press-psi", 0, "DOUBLE");
        m.C1ADP_press = m.hydr.initNode("system[1]/m-pump[1]/press-psi", 0, "DOUBLE");
        m.C2ADP_press = m.hydr.initNode("system[1]/m-pump[3]/press-psi", 0, "DOUBLE");
		m.RAT_press = m.hydr.initNode("system[1]/m-pump[4]/press-psi", 0, "DOUBLE");
		m.Brake_Accum_press = m.hydr.getNode("system[2]/brake-accumulator/press-raw");
		m.Brake_Accum_Drop = m.hydr.getNode("system[2]/brake-accumulator/Parking-Brake-Drop");
		
		# System pressure variables
		m.PressDiffLeft = m.hydr.initNode("system[0]/PressDiff-psi", 0, "DOUBLE");
		m.PressDiffCenter = m.hydr.initNode("system[1]/PressDiff-psi", 0, "DOUBLE");
		m.PressDiffRight = m.hydr.initNode("system[2]/PressDiff-psi", 0, "DOUBLE");
		
		m.LEDP_lowpress = m.hydr.initNode("system[0]/m-pump[0]/press-low", 0, "BOOL");
        m.REDP_lowpress = m.hydr.initNode("system[2]/m-pump[0]/press-low", 0, "BOOL");
        m.C1ACMP_lowpress = m.hydr.initNode("system[1]/m-pump[0]/press-low", 0, "BOOL");
        m.C2ACMP_lowpress = m.hydr.initNode("system[1]/m-pump[2]/press-low", 0, "BOOL");
        m.LACMP_lowpress = m.hydr.initNode("system[0]/m-pump[1]/press-low", 0, "BOOL");
        m.RACMP_lowpress = m.hydr.initNode("system[2]/m-pump[1]/press-low", 0, "BOOL");
        m.C1ADP_lowpress = m.hydr.initNode("system[1]/m-pump[1]/press-low", 0, "BOOL");
        m.C2ADP_lowpress = m.hydr.initNode("system[1]/m-pump[3]/press-low", 0, "BOOL");
		m.RAT_lowpress = m.hydr.initNode("system[1]/m-pump[4]/press-low", 0, "BOOL");
		
		m.LEDP_ovht = m.hydr.initNode("system[0]/m-pump[0]/overheat", 0, "BOOL");
        m.REDP_ovht = m.hydr.initNode("system[2]/m-pump[0]/overheat", 0, "BOOL");
        m.C1ACMP_ovht = m.hydr.initNode("system[1]/m-pump[0]/overheat", 0, "BOOL");
        m.C2ACMP_ovht = m.hydr.initNode("system[1]/m-pump[2]/overheat", 0, "BOOL");
        m.LACMP_ovht = m.hydr.initNode("system[0]/m-pump[1]/overheat", 0, "BOOL");
        m.RACMP_ovht = m.hydr.initNode("system[2]/m-pump[1]/overheat", 0, "BOOL");
        m.C1ADP_ovht = m.hydr.initNode("system[1]/m-pump[1]/overheat", 0, "BOOL");
        m.C2ADP_ovht = m.hydr.initNode("system[1]/m-pump[3]/overheat", 0, "BOOL");
		m.RAT_ovht = m.hydr.initNode("system[1]/m-pump[4]/overheat", 0, "BOOL");
		
		m.LEDP_emptyrun = m.hydr.initNode("system[0]/m-pump[0]/emptyrun", 0, "INT");
        m.REDP_emptyrun = m.hydr.initNode("system[2]/m-pump[0]/emptyrun", 0, "INT");
        m.C1ACMP_emptyrun = m.hydr.initNode("system[1]/m-pump[0]/emptyrun", 0, "INT");
        m.C2ACMP_emptyrun = m.hydr.initNode("system[1]/m-pump[2]/emptyrun", 0, "INT");
        m.LACMP_emptyrun = m.hydr.initNode("system[0]/m-pump[1]/emptyrun", 0, "INT");
        m.RACMP_emptyrun = m.hydr.initNode("system[2]/m-pump[1]/emptyrun", 0, "INT");
        m.C1ADP_emptyrun = m.hydr.initNode("system[1]/m-pump[1]/emptyrun", 0, "INT");
        m.C2ADP_emptyrun = m.hydr.initNode("system[1]/m-pump[3]/emptyrun", 0, "INT");
		m.RAT_emptyrun = m.hydr.initNode("system[1]/m-pump[4]/emptyrun", 0, "INT");
		
		m.Left_press = props.globals.getNode("systems/hydraulics/system[0]/press-psi");
		m.Ctr_press = props.globals.getNode("systems/hydraulics/system[1]/press-psi");
		m.Right_press = props.globals.getNode("systems/hydraulics/system[2]/press-psi");
		
		m.LeftReservoirLvl = props.globals.getNode("consumables/hydraulics/reservoir[0]/level-gal");
		m.CenterReservoirLvl = props.globals.getNode("consumables/hydraulics/reservoir[1]/level-gal");
		m.RightReservoirLvl = props.globals.getNode("consumables/hydraulics/reservoir[2]/level-gal");
		m.LeftReservoirLvlNorm = props.globals.getNode("consumables/hydraulics/reservoir[0]/level-norm");
		m.CenterReservoirLvlNorm = props.globals.getNode("consumables/hydraulics/reservoir[1]/level-norm");
		m.RightReservoirLvlNorm = props.globals.getNode("consumables/hydraulics/reservoir[2]/level-norm");
		
		m.FluidLeaksEnabled = props.globals.getNode("aircraft/settings/hydr_consumption");
		
		# Pump availability states (an available pump can be selected by the auto logic, but isn't necessarily running.
		m.LEDP_avail = m.hydr.initNode("system[0]/m-pump[0]/LEDP-avail", 0, "INT");
        m.REDP_avail = m.hydr.initNode("system[2]/m-pump[0]/REDP-avail", 0, "INT");
        m.C1ACMP_avail = m.hydr.initNode("system[1]/m-pump[0]/C1ACMP-avail", 0, "INT");
        m.C2ACMP_avail = m.hydr.initNode("system[1]/m-pump[2]/C2ACMP-avail", 0, "INT");
        m.LACMP_avail = m.hydr.initNode("system[0]/m-pump[1]/LACMP-avail", 0, "INT");
        m.RACMP_avail = m.hydr.initNode("system[2]/m-pump[1]/RACMP-avail", 0, "INT");
        m.C1ADP_avail = m.hydr.initNode("system[1]/m-pump[1]/C1ADP-avail", 0, "INT");
        m.C2ADP_avail = m.hydr.initNode("system[1]/m-pump[3]/C2ADP-avail", 0, "INT");
		m.RAT_avail = m.hydr.initNode("system[1]/m-pump[4]/RAT-avail", 0, "INT");
		
		# Hydraulic valve states 0 = closed, 1 = open, >1 = blocked
		m.LeftSOV = m.hydr.initNode("system[0]/ShutOffValve/opened", 1, "INT");
		m.NoseGearIsln = m.hydr.initNode("system[1]/IslnValve[0]/opened", 1, "INT");
		m.C1ElecIsln = m.hydr.initNode("system[1]/IslnValve[1]/opened", 1, "INT");
		m.RightSOV = m.hydr.initNode("system[2]/ShutOffValve/opened", 1, "INT");
		
		# Switch states
        m.leng_primary_switch = props.globals.initNode("controls/hydraulics/system/LENG_switch", 0, "BOOL");
        m.reng_primary_switch = props.globals.initNode("controls/hydraulics/system[2]/RENG_switch", 0, "BOOL");
        m.c1elec_switch = props.globals.initNode("controls/hydraulics/system[1]/C1ELEC-switch", 0, "BOOL");
        m.c2elec_switch = props.globals.initNode("controls/hydraulics/system[1]/C2ELEC-switch", 0, "BOOL");
        m.lacmp_switch = props.globals.initNode("controls/hydraulics/system/LACMP-switch", 0, "INT");
        m.racmp_switch = props.globals.initNode("controls/hydraulics/system[2]/RACMP-switch", 0, "INT");
        m.c1adp_switch = props.globals.initNode("controls/hydraulics/system[1]/C1ADP-switch", 0, "INT");
        m.c2adp_switch = props.globals.initNode("controls/hydraulics/system[1]/C2ADP-switch", 0, "INT");
		
		# Fault light input timers
		m.LEDP_Fault = props.globals.initNode("controls/switches/LENGFaultTimer/position-norm");
		m.REDP_Fault = props.globals.initNode("controls/switches/RENGFaultTimer/position-norm");
		m.C1ACMP_Fault = props.globals.initNode("controls/switches/C1ELECFaultTimer/position-norm");
		m.C2ACMP_Fault = props.globals.initNode("controls/switches/C2ELECFaultTimer/position-norm");
		m.LACMP_Fault = props.globals.initNode("controls/switches/LACMPFaultTimer/position-norm");
		m.RACMP_Fault = props.globals.initNode("controls/switches/RACMPFaultTimer/position-norm");
		m.C1ADP_Fault = props.globals.initNode("controls/switches/C1ADPFaultTimer/position-norm");
		m.C2ADP_Fault = props.globals.initNode("controls/switches/C2ADPFaultTimer/position-norm");
		
		# Power sources
		m.leng_running = props.globals.getNode("engines/engine/run", 1);
		m.reng_running = props.globals.getNode("engines/engine[1]/run", 1);
        m.APUrun = props.globals.initNode("controls/APU/run", 0, "BOOL");
        m.APUgen = props.globals.initNode("controls/APU/apu-gen-switch", 0, "BOOL");
        m.GP1 = props.globals.getNode("systems/electrical/PRI-EPC");
        m.GP2 = props.globals.getNode("systems/electrical/SEC-EPC");
        m.APUP = m.hydr.initNode("APUP-NORMAL", 0 , "BOOL");
		
		# Bleed Air sources TO IMPROVE WHEN AIR SYSTEM GETS IMPLEMENTED
		# Air Isolation valve operation is not implemented yet and should be implemented in the air system.
		# In the Air System, a property "C1Hydr" and "C2Hydr" should be provided as inputs to the hydraulics system, and be active based on bleed air status and isolation valve position.
		m.BleedAirL = props.globals.getNode("controls/air/bleedengl");
		m.BleedAirR = props.globals.getNode("controls/air/bleedengr");
		m.BleedAPU = props.globals.getNode("controls/air/bleedapu");
		m.BleedAir = m.hydr.initNode("BleedAirAvail", 0, "BOOL");
		
		# Pushback override (allows nosegear steering when pushback connected)
		m.PushConn = props.globals.getNode("sim/model/autopush/connected", 0, "BOOL");
		
		# Demand Sensors
		m.WOW = props.globals.getNode("gear/gear[0]/wow");
		m.AirSpeed = props.globals.getNode("instrumentation/airspeed-indicator/indicated-speed-kt");
		m.GearSet = props.globals.getNode("controls/gear/gear-down");
		m.NoseGearPos = props.globals.getNode("gear/gear[0]/position-norm");
		m.LeftGearPos = props.globals.getNode("gear/gear[1]/position-norm");
		m.RightGearPos = props.globals.getNode("gear/gear[2]/position-norm");
		m.LeftRev = props.globals.getNode("controls/engines/engine[0]/reverser");
		m.RightRev = props.globals.getNode("controls/engines/engine[1]/reverser");
		m.LeftThrottle = props.globals.getNode("controls/engines/engine[0]/throttle");
		m.RightThrottle = props.globals.getNode("controls/engines/engine[1]/throttle");
		m.BrakeL = props.globals.getNode("controls/gear/brake-left-cmd");
		m.BrakeR = props.globals.getNode("controls/gear/brake-right-cmd");
		m.Brake = props.globals.getNode("controls/gear/brake-comb");
		m.ParkingBrake = props.globals.getNode("controls/gear/brake-parking");
		m.ParkingBrakeSet = props.globals.getNode("controls/gear/brake-parking-set");
		m.ParkingBrakeState = props.globals.getNode("controls/gear/brake-parking-prev");
		m.AltnBrakeL = props.globals.getNode("controls/gear/brake-left-reserve");
		m.AltnBrakeR = props.globals.getNode("controls/gear/brake-right-reserve");
		m.AutoBrakeL = props.globals.getNode("autopilot/autobrake/left-brake-output");
		m.AutoBrakeR = props.globals.getNode("autopilot/autobrake/right-brake-output");
		m.FlapPos = props.globals.getNode("surface-positions/flap-pos-norm");
		m.FlapSet = props.globals.getNode("controls/flight/flaps");
		m.CurrentTime = props.globals.getNode("sim/time/elapsed-sec");
		m.EnvironmentPress = props.globals.getNode("environment/pressure-psi");
		m.AltitudeAGL = props.globals.getNode("autopilot/settings/radio-altimeter-indication");
		
		# Brake system properties to be able to calculate fluid transfer between center and right system if incorrectly used.
		m.BrakeSysLeft_lvl = m.hydr.getNode("brakesystem/left-level-gal");
		m.BrakeSysRight_lvl = m.hydr.getNode("brakesystem/right-level-gal");
		m.BrakeSysLeft_norm = m.hydr.getNode("brakesystem/left-level-norm");
		m.BrakeSysRight_norm = m.hydr.getNode("brakesystem/right-level-norm");
		m.BrakeSource = m.hydr.getNode("brakesystem/brakesource");
		m.BrakesCapacity = m.hydr.initNode("brakesystem/capacity", 0.05, "DOUBLE");
		
		# Gear retraction system properties to calculate fluid transfer from/to center system
		m.GearCapacityL = m.hydr.initNode("system[1]/gear/left-capacity-gal", 0.1, "DOUBLE");
		m.GearCapacityR = m.hydr.initNode("system[1]/gear/right-capacity-gal", 0.1, "DOUBLE");
		m.GearCapacityN = m.hydr.initNode("system[1]/gear/nose-capacity-gal", 0.06, "DOUBLE");
		m.GearCylinderL = m.hydr.initNode("system[1]/gear/left-level-gal", 0, "DOUBLE");
		m.GearCylinderR = m.hydr.initNode("system[1]/gear/right-level-gal", 0, "DOUBLE");
		m.GearCylinderN = m.hydr.initNode("system[1]/gear/nose-level-gal", 0, "DOUBLE");
		
		# Hydraulic demand variables
		m.DemandTakeOff = m.hydr.initNode("Demand/TakeOff", 0, "BOOL");
		m.DemandLanding = m.hydr.initNode("Demand/Landing", 0, "BOOL");
		m.DemandMainGear = m.hydr.initNode("system[1]/Demand/MainGearMotion", 0, "BOOL");
		m.DemandNoseGear = m.hydr.initNode("system[1]/Demand/NoseGearMotion", 0, "BOOL");
		m.DemandFlaps = m.hydr.initNode("system[1]/Demand/FlapsMotion", 0, "BOOL");
		m.FlapsMovementTime = m.hydr.initNode("system[1]/Demand/FlapsTimer", 0, "INT");
		m.DemandBrakes = m.hydr.initNode("system[2]/Demand/Brakes", 0, "BOOL");
		m.DemandAltnBrake = m.hydr.initNode("system[1]/Demand/AltnBrakes", 0, "BOOL");
		m.DemandRevL = m.hydr.initNode("system[0]/Demand/Rev_L", 0, "BOOL");
		m.DemandRevR = m.hydr.initNode("system[2]/Demand/Rev_R", 0, "BOOL");
		m.DemandLeft = m.hydr.initNode("Demand/Left", 0, "BOOL");
		m.DemandC1 = m.hydr.initNode("Demand/C1", 0, "BOOL");
		m.DemandC2 = m.hydr.initNode("Demand/C2", 0, "BOOL");
		m.DemandRight = m.hydr.initNode("Demand/Right", 0, "BOOL");
		m.DemandTakeOffTime = m.hydr.initNode("Demand/TakeOffTime-sec", 0, "DOUBLE");
		m.DemandTakeOffRejectedDuration = m.hydr.initNode("Demand/RejectedDuration", 180, "DOUBLE"); # Disable takeoff demand after 3 minutes if not airborne and no takeoff thrust is set.
		m.DemandTakeOffDuration = m.hydr.initNode("Demand/TakeOffDuration", 600, "DOUBLE"); # Disable takeoff demand after 10 minutes if gear is still down.
		m.DemandLandingTime = m.hydr.initNode("Demand/LandingTime-sec", 0, "DOUBLE");
		m.DemandLandingDuration = m.hydr.initNode("Demand/LandingDuration", 120, "DOUBLE"); # Disable Landing demand 2 minutes after touch down.
		
		# Hydraulic leak variables
		m.DemandLeftLeak = m.hydr.initNode("system[0]/Demand/Leak", 0, "INT");
		m.DemandC1Leak = m.hydr.initNode("system[1]/Demand/C1-Leak", 0, "INT");
		m.DemandC2Leak = m.hydr.initNode("system[1]/Demand/C2-Leak", 0, "INT");
		m.DemandNoseLeak = m.hydr.initNode("system[1]/Demand/Nose-Leak", 0, "INT");
		m.DemandRightLeak = m.hydr.initNode("system[2]/Demand/Leak", 0, "INT");		
		m.DemandFltctrlLeft_Press = m.hydr.initNode("system[0]/Demand/Fltctrl-demand-psi", 0, "DOUBLE");
		m.DemandFltctrlCntr_Press = m.hydr.initNode("system[1]/Demand/Fltctrl-demand-psi", 0, "DOUBLE");
		m.DemandFltctrlRight_Press = m.hydr.initNode("system[2]/Demand/Fltctrl-demand-psi", 0, "DOUBLE");
		m.DemandRevL_Press = m.hydr.initNode("system[0]/Demand/Rev_L-demand-psi", 0, "DOUBLE");
		m.DemandRevR_Press = m.hydr.initNode("system[2]/Demand/Rev_R-demand-psi", 0, "DOUBLE");
		m.DemandLeftLeak_Press = m.hydr.initNode("system[0]/Demand/Leak-demand-psi", 0, "DOUBLE");
		m.DemandC1Leak_Press = m.hydr.initNode("system[1]/Demand/C1-Leak-demand-psi", 0, "DOUBLE");
		m.DemandC2Leak_Press = m.hydr.initNode("system[1]/Demand/C2-Leak-demand-psi", 0, "DOUBLE");
		m.DemandNoseLeak_Press = m.hydr.initNode("system[1]/Demand/Nose-Leak-demand-psi", 0, "DOUBLE");
		m.DemandRightLeak_Press = m.hydr.initNode("system[2]/Demand/Leak-demand-psi", 0, "DOUBLE");
		
		# Control surfaces
		# TODO: this list is incomplete. The flight control surfaces are split into multiple circuits per control surface for redundancy.
		# The only way to model this is to separate these control surfaces and tie them to the correct hydraulics circuit. TODO when we upgrade the 3D model.
		m.reverserL = props.globals.initNode("surface-positions/reverser-norm");
		m.reverserR = props.globals.initNode("surface-positions/reverser-norm[1]");
		m.elevatorpos = props.globals.initNode("surface-positions/elevator-pos-norm");
        m.stabilizerpos = props.globals.initNode("surface-positions/stabilizer-pos-norm");
        m.leftaileronpos = props.globals.initNode("surface-positions/left-aileron-pos-norm");
        m.rightaileronpos = props.globals.initNode("surface-positions/right-aileron-pos-norm");
        m.rudderpos = props.globals.initNode("surface-positions/rudder-pos-norm");
        m.speedbkpos = props.globals.initNode("surface-positions/speedbrake-pos-norm");
		m.flappos = props.globals.initNode("surface-positions/flap-pos-norm");
        m.NoseGearSteering =  props.globals.initNode("controls/gear/nosegear-steering-cmd-norm");
        m.MainGearSteering =  props.globals.initNode("controls/gear/maingear-steering-cmd-norm");
		
        return m;
    },
    update : func{
        
		### Check which electrical power sources and engines are available
		
		var NrPwrSrcs = 0;
		
		# These variables add up during one update cycle and remove a small amount of the hydraulic fluid. Fluid is only effectively removed if fluid consumption is enabled.
		var FluidLeakedLeft = 0;
		var FluidLeakedRight = 0;
		var FluidLeakedC1 = 0;
		var FluidLeakedC2 = 0;
		var FluidLeakedCNose = 0;
		
		var singledrop = 0.002; # 1 big drop, about 7.57 ml (used after the system has been in DemandLanding or DemandTakeOff state)
		var continuousdrop = 0.00001; # about 37.85 µl, equals to ± 11.356 ml per minute of use (full braking, flaps movement, gear retraction...)
		var LeakQuantity = 0.0001; # When a leak occurs, this quantity leaks, multiplied with the leak size and scaled with the system pressure
		# Leaks are implemented in the main portions of the Left, Right, NoseGear, C1 and C2 systems.
		# LeakQuantity of 0.0001 leads to a spill of about 5.4 gal of fluid per hour in normal conditions.
		# TODO: allow leaks to occur randomly when implementing a fault system.
		
		if(me.APUrun.getValue() and me.APUgen.getValue())
        {
            me.APUP.setValue(1);
			NrPwrSrcs += 1;
        }
        else
        {
            me.APUP.setValue(0);
        }
		
		if (me.GP1.getValue()) {
			NrPwrSrcs += 1;
		}
		
		if (me.GP2.getValue()) {
			NrPwrSrcs += 1;
		}
		
		if (me.leng_running.getValue()) {
			NrPwrSrcs += 1;
		}
		
		if (me.reng_running.getValue()) {
			NrPwrSrcs += 1;
		}
		
		# Todo: Add RAT power source
		
		### Check if Bleed air is available
		### TODO: improve when a proper Air System is available (see comments above)
		
		if (me.BleedAirL.getValue() == 1 or me.BleedAirR.getValue() == 1 or (me.BleedAPU.getValue() == 1 and me.APUP.getValue() == 1)) {
			me.BleedAir.setValue(1);
		} else {
			me.BleedAir.setValue(0);
		}
		
		### Check reservoir levels and define which pumps have access to hydraulic fluid
		
		if (me.LeftReservoirLvl.getValue() > 0) {
			me.LACMP_supply.setValue(1);
		} else {
			me.LACMP_supply.setValue(0);
		}
		if (me.LeftReservoirLvl.getValue() >= 2.0) {
			me.LEDP_supply.setValue(1);
		} else {
			me.LEDP_supply.setValue(0);
		}
		
		if (me.CenterReservoirLvl.getValue() > 0) {
			me.C1ACMP_supply.setValue(1);
		} else {
			me.C1ACMP_supply.setValue(0);
		}
		if (me.CenterReservoirLvl.getValue() > 1.2) {
			me.C2ACMP_supply.setValue(1);
			me.C1ADP_supply.setValue(1);
			me.C2ADP_supply.setValue(1);
			me.RAT_supply.setValue(1);
		} else {
			me.C2ACMP_supply.setValue(0);
			me.C1ADP_supply.setValue(0);
			me.C2ADP_supply.setValue(0);
			me.RAT_supply.setValue(0);
		}
		
		if (me.RightReservoirLvl.getValue() > 0) {
			me.RACMP_supply.setValue(1);
		} else {
			me.RACMP_supply.setValue(0);
		}
		if (me.RightReservoirLvl.getValue() >= 2.0) {
			me.REDP_supply.setValue(1);
		} else {
			me.REDP_supply.setValue(0);
		}
		
		### Check which pumps are available based on button states, power states, Hydraulic fluid and/or Bleed Air availability.
		
			# Left Primary Pump
        if(me.leng_running.getValue() and me.leng_primary_switch.getValue() and me.LEDP_supply.getValue())
        {
            me.LEDP_avail.setValue(1);
            if ((me.LEDP.getValue() and me.LEDP_press.getValue() > 2500) or (!me.LEDP.getValue() and me.LEDP_Fault.getValue() == 1)) { # Causes a delay in light being extinguished
				me.LEDP_fine.setValue(1);       #FAULT light off
			}
        }
		elsif (me.leng_running.getValue() and me.leng_primary_switch.getValue() and !me.LEDP_supply.getValue() and !me.LEDP_ovht.getValue())
		{
			if (me.LEDP_emptyrun.getValue() <= 50 and me.LEDP.getValue()) { # if running less than 10 seconds without fluid, allow the pump to keep operating
				me.LEDP_avail.setValue(1); # Keep pump available
				me.LEDP_fine.setValue(1);  # FAULT light off
				me.LEDP_emptyrun.setValue(me.LEDP_emptyrun.getValue() + 1); # Add to running empty timer
			} elsif (me.LEDP_emptyrun.getValue() > 50) { # if running more than 10 seconds without fluid, overheat the pump and block it.
				me.LEDP_ovht.setValue(1);  # Overheat pump
				me.LEDP_avail.setValue(5); # 5 = Pump overheated
				me.LEDP_fine.setValue(0);  # FAULT light on
			} else { # no fluid available but pump was not running.
				me.LEDP_avail.setValue(3); # 3 = Blocked NoSupply
				me.LEDP_fine.setValue(0);  #FAULT light on
			}
		}
		elsif (me.LEDP_ovht.getValue()) # Pump is in overheated state
		{
			if (me.LEDP_emptyrun.getValue() < 3000) { # Pump has been in overheated state for less than 10 minutes
				me.LEDP_emptyrun.setValue(me.LEDP_emptyrun.getValue() + 1);
				me.LEDP_avail.setValue(5);
			} elsif (!me.leng_primary_switch.getValue()) { # Pump has cooled down and was switched off. Remove overheat warning.
				me.LEDP_ovht.setValue(0);
				me.LEDP_emptyrun.setValue(0);
				if (!me.LEDP_supply.getValue()) { # If pump doesn't have access to fluid, keep it blocked.
					me.LEDP_avail.setValue(3); # 3 = Blocked NoSupply
				}
			} else { # Pump was not switched off.
				# TODO: set fire to the pump?
			}
		}
		elsif (!me.leng_running.getValue() and me.leng_primary_switch.getValue())
		{
			me.LEDP_avail.setValue(4); 		# 4 = Blocked engine off
			me.LEDP_fine.setValue(0); 		# FAULT light on
		}
        else
        {
            me.LEDP_avail.setValue(0);
            if(cpt_flt_inst.getValue() > 24)
            {
                me.LEDP_fine.setValue(0);   #FAULT light on

            }
            else
            {
                me.LEDP_fine.setValue(1);   #FAULT light off
				
            }
        }
		
			# Right primary pump
        if(me.reng_running.getValue() and me.reng_primary_switch.getValue() and me.REDP_supply.getValue())
        {
            me.REDP_avail.setValue(1);
			if ((me.REDP.getValue() and me.REDP_press.getValue() > 2500) or (!me.REDP.getValue() and me.REDP_Fault.getValue() == 1)) { # Causes a delay in light being extinguished
				me.REDP_fine.setValue(1);
			}
        }
		elsif (me.reng_running.getValue() and me.reng_primary_switch.getValue() and !me.REDP_supply.getValue() and !me.REDP_ovht.getValue())
		{
			
			if (me.REDP_emptyrun.getValue() <= 50 and me.REDP.getValue()) { # if running less than 10 seconds without fluid, allow the pump to keep operating
				me.REDP_avail.setValue(1); # Keep pump available
				me.REDP_fine.setValue(1);  # FAULT light off
				me.REDP_emptyrun.setValue(me.REDP_emptyrun.getValue() + 1); # Add to running empty timer
			} elsif (me.REDP_emptyrun.getValue() > 50) { # if running more than 10 seconds without fluid, overheat the pump and block it.
				me.REDP_ovht.setValue(1);  # Overheat pump
				me.REDP_avail.setValue(5); # 5 = Pump overheated
				me.REDP_fine.setValue(0);  # FAULT light on
			} else { # no fluid available but pump was not running.
				me.REDP_avail.setValue(3); # 3 = Blocked NoSupply
				me.REDP_fine.setValue(0);  #FAULT light on
			}
		}
		elsif (me.REDP_ovht.getValue()) # Pump is in overheated state
		{
			if (me.REDP_emptyrun.getValue() < 3000) { # Pump has been in overheated state for less than 10 minutes
				me.REDP_emptyrun.setValue(me.REDP_emptyrun.getValue() + 1);
				me.REDP_avail.setValue(5);
			} elsif (!me.reng_primary_switch.getValue()) { # Pump has cooled down and was switched off. Remove overheat warning.
				me.REDP_ovht.setValue(0);
				me.REDP_emptyrun.setValue(0);
				if (!me.REDP_supply.getValue()) { # If pump doesn't have access to fluid, keep it blocked.
					me.REDP_avail.setValue(3); # 3 = Blocked NoSupply
				}
			} else { # Pump was not switched off.
				# TODO: set fire to the pump?
			}
		}
        elsif (!me.reng_running.getValue() and me.reng_primary_switch.getValue())
		{
			me.REDP_avail.setValue(4); 		# 4 = Blocked engine off
			me.REDP_fine.setValue(0); 		# FAULT light on
		}
		else
        {
            me.REDP_avail.setValue(0);
            if(cpt_flt_inst.getValue() > 24)
            {
                me.REDP_fine.setValue(0);
            }
            else
            {
                me.REDP_fine.setValue(1);
            }
        }
		
			# C1 Primary pump
        if(NrPwrSrcs >= 1 and me.c1elec_switch.getValue() and me.C1ACMP_supply.getValue())
        {
            me.C1ACMP_avail.setValue(1);
			if ((me.C1ACMP.getValue() and me.C1ACMP_press.getValue() > 2500) or (!me.C1ACMP.getValue() and me.C1ACMP_Fault.getValue() == 1)) { # Causes a delay in light being extinguished
				me.C1ACMP_fine.setValue(1);
			}
        }
        elsif ((lidg.get_output_volts() > 80 or ridg.get_output_volts() > 80 or me.APUP.getValue() or me.GP1.getValue() or me.GP2.getValue()) and me.c1elec_switch.getValue() and !me.C1ACMP_supply.getValue() and !me.C1ACMP_ovht.getValue())
		{
			
			if (me.C1ACMP_emptyrun.getValue() <= 50 and me.C1ACMP.getValue()) { # if running less than 10 seconds without fluid, allow the pump to keep operating
				me.C1ACMP_avail.setValue(1); # Keep pump available
				me.C1ACMP_fine.setValue(1);  # FAULT light off
				me.C1ACMP_emptyrun.setValue(me.C1ACMP_emptyrun.getValue() + 1); # Add to running empty timer
			} elsif (me.C1ACMP_emptyrun.getValue() > 50) { # if running more than 10 seconds without fluid, overheat the pump and block it.
				me.C1ACMP_ovht.setValue(1);  # Overheat pump
				me.C1ACMP_avail.setValue(5); # 5 = Pump overheated
				me.C1ACMP_fine.setValue(0);  # FAULT light on
			} else { # no fluid available but pump was not running.
				me.C1ACMP_avail.setValue(3); # 3 = Blocked NoSupply
				me.C1ACMP_fine.setValue(0);  #FAULT light on
			}
		}
		elsif (me.C1ACMP_ovht.getValue()) # Pump is in overheated state
		{
			if (me.C1ACMP_emptyrun.getValue() < 3000) { # Pump has been in overheated state for less than 10 minutes
				me.C1ACMP_emptyrun.setValue(me.C1ACMP_emptyrun.getValue() + 1);
				me.C1ACMP_avail.setValue(5);
			} elsif (!me.c1elec_switch.getValue()) { # Pump has cooled down and was switched off. Remove overheat warning.
				me.C1ACMP_ovht.setValue(0);
				me.C1ACMP_emptyrun.setValue(0);
				if (!me.C1ACMP_supply.getValue()) { # If pump doesn't have access to fluid, keep it blocked.
					me.C1ACMP_avail.setValue(3); # 3 = Blocked NoSupply
				}
			} else { # Pump was not switched off.
				# TODO: set fire to the pump?
			}
		}
		else
        {
            me.C1ACMP_avail.setValue(0);
            if(cpt_flt_inst.getValue() > 24)
            {
                me.C1ACMP_fine.setValue(0);
            }
            else
            {
                me.C1ACMP_fine.setValue(1);
            }
        }
		
			# C2 Primary pump
        if (NrPwrSrcs >= 1 and me.c2elec_switch.getValue() and me.C2ACMP_supply.getValue())
        {
			if ((me.C2ACMP.getValue() and me.C2ACMP_press.getValue() > 2500) or (!me.C2ACMP.getValue() and me.C2ACMP_Fault.getValue() == 1)) { # Causes a delay in light being extinguished
				me.C2ACMP_fine.setValue(1);
			}
			# On the ground, with only a single external power source, or the APU only, the PRIMARY C2 pump will not run if the PRIMARY C1 pump is selected. The PRIMARY C2 pump will
			# not be load shed if one engine generator is operating.
			if (me.WOW.getValue() and me.C1ACMP_avail.getValue() and NrPwrSrcs <= 1 and !me.leng_running.getValue() and !me.reng_running.getValue()) {
				me.C2ACMP_avail.setValue(0);
			# in flight the C2 primary pump may be load shed by the electrical load management system when the following conditions exist:
			# - All other electric pumps are running
			# - There is a single source of electrical power
			# - Generator capacity is exceeded (TODO when electrical system is overhauled)
			} elsif (!me.WOW.getValue() and me.C1ACMP.getValue() and me.RACMP.getValue() and me.LACMP.getValue() and NrPwrSrcs == 1) {
				me.C2ACMP_avail.setValue(0);
			} else {
				me.C2ACMP_avail.setValue(1);
			}
        }
        elsif ((lidg.get_output_volts() > 80 or ridg.get_output_volts() > 80 or me.APUP.getValue() or me.GP1.getValue() or me.GP2.getValue()) and me.c2elec_switch.getValue() and !me.C2ACMP_supply.getValue() and !me.C2ACMP_ovht.getValue())
		{			
			if (me.C2ACMP_emptyrun.getValue() <= 50 and me.C2ACMP.getValue()) { # if running less than 10 seconds without fluid, allow the pump to keep operating
				me.C2ACMP_avail.setValue(1); # Keep pump available
				me.C2ACMP_fine.setValue(1);  # FAULT light off
				me.C2ACMP_emptyrun.setValue(me.C2ACMP_emptyrun.getValue() + 1); # Add to running empty timer
			} elsif (me.C2ACMP_emptyrun.getValue() > 50) { # if running more than 10 seconds without fluid, overheat the pump and block it.
				me.C2ACMP_ovht.setValue(1);  # Overheat pump
				me.C2ACMP_avail.setValue(5); # 5 = Pump overheated
				me.C2ACMP_fine.setValue(0);  # FAULT light on
			} else { # no fluid available but pump was not running.
				me.C2ACMP_avail.setValue(3); # 3 = Blocked NoSupply
				me.C2ACMP_fine.setValue(0);  #FAULT light on
			}
		}
		elsif (me.C2ACMP_ovht.getValue()) # Pump is in overheated state
		{
			if (me.C2ACMP_emptyrun.getValue() < 3000) { # Pump has been in overheated state for less than 10 minutes
				me.C2ACMP_emptyrun.setValue(me.C2ACMP_emptyrun.getValue() + 1);
				me.C2ACMP_avail.setValue(5);
			} elsif (!me.c2elec_switch.getValue()) { # Pump has cooled down and was switched off. Remove overheat warning.
				me.C2ACMP_ovht.setValue(0);
				me.C2ACMP_emptyrun.setValue(0);
				if (!me.C2ACMP_supply.getValue()) { # If pump doesn't have access to fluid, keep it blocked.
					me.C2ACMP_avail.setValue(3); # 3 = Blocked NoSupply
				}
			} else { # Pump was not switched off.
				# TODO: set fire to the pump?
			}
		}
		else
        {
            me.C2ACMP_avail.setValue(0);
            if(cpt_flt_inst.getValue() > 24)
            {
                me.C2ACMP_fine.setValue(0);
            }
            else
            {
                me.C2ACMP_fine.setValue(1);
            }
        }
        
			# Left Demand pump
		if (NrPwrSrcs >= 1 and me.lacmp_switch.getValue() > 0 and me.LACMP_supply.getValue())
        {
            me.LACMP_avail.setValue(me.lacmp_switch.getValue()); # 1 = auto; 2 = on.
            if ((me.LACMP.getValue() and me.LACMP_press.getValue() > 2500) or (!me.LACMP.getValue() and me.LACMP_Fault.getValue() == 1)) { # Causes a delay in light being extinguished
				me.LACMP_fine.setValue(1);
			}
        }
		elsif ((lidg.get_output_volts() > 80 or ridg.get_output_volts() > 80) and me.lacmp_switch.getValue() > 0 and !me.LACMP_supply.getValue() and !me.LACMP_ovht.getValue())
		{			
			if (me.LACMP_emptyrun.getValue() <= 50 and me.LACMP.getValue()) { # if running less than 10 seconds without fluid, allow the pump to keep operating
				me.LACMP_avail.setValue(1); # Keep pump available
				me.LACMP_fine.setValue(1);  # FAULT light off
				me.LACMP_emptyrun.setValue(me.LACMP_emptyrun.getValue() + 1); # Add to running empty timer
			} elsif (me.LACMP_emptyrun.getValue() > 50) { # if running more than 10 seconds without fluid, overheat the pump and block it.
				me.LACMP_ovht.setValue(1);  # Overheat pump
				me.LACMP_avail.setValue(5); # 5 = Pump overheated
				me.LACMP_fine.setValue(0);  # FAULT light on
			} else { # no fluid available but pump was not running.
				me.LACMP_avail.setValue(3); # 3 = Blocked NoSupply
				me.LACMP_fine.setValue(0);  #FAULT light on
			}
		}
		elsif (me.LACMP_ovht.getValue()) # Pump is in overheated state
		{
			if (me.LACMP_emptyrun.getValue() < 3000) { # Pump has been in overheated state for less than 10 minutes
				me.LACMP_emptyrun.setValue(me.LACMP_emptyrun.getValue() + 1);
				me.LACMP_avail.setValue(5);
			} elsif (me.lacmp_switch.getValue() == 0) { # Pump has cooled down and was switched off. Remove overheat warning.
				me.LACMP_ovht.setValue(0);
				me.LACMP_emptyrun.setValue(0);
				if (!me.LACMP_supply.getValue()) { # If pump doesn't have access to fluid, keep it blocked.
					me.LACMP_avail.setValue(3); # 3 = Blocked NoSupply
				}
			} else { # Pump was not switched off.
				# TODO: set fire to the pump?
			}
		}
        else
        {
            me.LACMP_avail.setValue(0);
            if(cpt_flt_inst.getValue() > 24)
            {
                me.LACMP_fine.setValue(0);
            }
            else
            {
                me.LACMP_fine.setValue(1);
            }
        }
		
			#Right Demand pump
        if(NrPwrSrcs >= 1 and me.racmp_switch.getValue() > 0 and me.RACMP_supply.getValue())
        {
            me.RACMP_avail.setValue(me.racmp_switch.getValue()); # 1 = auto; 2 = on.
			if ((me.RACMP.getValue() and me.RACMP_press.getValue() > 2500) or (!me.RACMP.getValue() and me.RACMP_Fault.getValue() == 1)) { # Causes a delay in light being extinguished
				me.RACMP_fine.setValue(1);
			}
        }
        elsif ((lidg.get_output_volts() > 80 or ridg.get_output_volts() > 80) and me.racmp_switch.getValue() > 0 and !me.RACMP_supply.getValue() and !me.RACMP_ovht.getValue())
		{
			
			if (me.RACMP_emptyrun.getValue() <= 50 and me.RACMP.getValue()) { # if running less than 10 seconds without fluid, allow the pump to keep operating
				me.RACMP_avail.setValue(1); # Keep pump available
				me.RACMP_fine.setValue(1);  # FAULT light off
				me.RACMP_emptyrun.setValue(me.RACMP_emptyrun.getValue() + 1); # Add to running empty timer
			} elsif (me.RACMP_emptyrun.getValue() > 50) { # if running more than 10 seconds without fluid, overheat the pump and block it.
				me.RACMP_ovht.setValue(1);  # Overheat pump
				me.RACMP_avail.setValue(5); # 5 = Pump overheated
				me.RACMP_fine.setValue(0);  # FAULT light on
			} else { # no fluid available but pump was not running.
				me.RACMP_avail.setValue(3); # 3 = Blocked NoSupply
				me.RACMP_fine.setValue(0);  #FAULT light on
			}
		}
		elsif (me.RACMP_ovht.getValue()) # Pump is in overheated state
		{
			if (me.RACMP_emptyrun.getValue() < 3000) { # Pump has been in overheated state for less than 10 minutes
				me.RACMP_emptyrun.setValue(me.RACMP_emptyrun.getValue() + 1);
				me.RACMP_avail.setValue(5);
			} elsif (me.racmp_switch.getValue() == 0) { # Pump has cooled down and was switched off. Remove overheat warning.
				me.RACMP_ovht.setValue(0);
				me.RACMP_emptyrun.setValue(0);
				if (!me.RACMP_supply.getValue()) { # If pump doesn't have access to fluid, keep it blocked.
					me.RACMP_avail.setValue(3); # 3 = Blocked NoSupply
				}
			} else { # Pump was not switched off.
				# TODO: set fire to the pump?
			}
		}
		else
        {
            me.RACMP_avail.setValue(0);
            if(cpt_flt_inst.getValue() > 24)
            {
                me.RACMP_fine.setValue(0);
            }
            else
            {
                me.RACMP_fine.setValue(1);
            }
        }
		
			# C1 Demand pump
        if(me.c1adp_switch.getValue() > 0 and me.C1ADP_supply.getValue() and me.BleedAir.getValue())
        {
            me.C1ADP_avail.setValue(me.c1adp_switch.getValue()); # 1 = auto; 2 = on.
			if ((me.C1ADP.getValue() and me.C1ADP_press.getValue() > 2500) or (!me.C1ADP.getValue() and me.C1ADP_Fault.getValue() == 1)) { # Causes a delay in light being extinguished
				me.C1ADP_fine.setValue(1);
			}
        }
		elsif(me.c1adp_switch.getValue() > 0 and !me.C1ADP_supply.getValue() and me.BleedAir.getValue() and !me.C1ADP_ovht.getValue())
        {
			if (me.C1ADP_emptyrun.getValue() <= 50 and me.C1ADP.getValue()) { # if running less than 10 seconds without fluid, allow the pump to keep operating
				me.C1ADP_avail.setValue(1); # Keep pump available
				me.C1ADP_fine.setValue(1);  # FAULT light off
				me.C1ADP_emptyrun.setValue(me.C1ADP_emptyrun.getValue() + 1); # Add to running empty timer
			} elsif (me.C1ADP_emptyrun.getValue() > 50) { # if running more than 10 seconds without fluid, overheat the pump and block it.
				me.C1ADP_ovht.setValue(1);  # Overheat pump
				me.C1ADP_avail.setValue(5); # 5 = Pump overheated
				me.C1ADP_fine.setValue(0);  # FAULT light on
			} else { # no fluid available but pump was not running.
				me.C1ADP_avail.setValue(3); # 3 = Blocked NoSupply
				me.C1ADP_fine.setValue(0);  #FAULT light on
			}
		}
		elsif (me.C1ADP_ovht.getValue()) # Pump is in overheated state
		{
			if (me.C1ADP_emptyrun.getValue() < 3000) { # Pump has been in overheated state for less than 10 minutes
				me.C1ADP_emptyrun.setValue(me.C1ADP_emptyrun.getValue() + 1);
				me.C1ADP_avail.setValue(5);
			} elsif (me.c1adp_switch.getValue() == 0) { # Pump has cooled down and was switched off. Remove overheat warning.
				me.C1ADP_ovht.setValue(0);
				me.C1ADP_emptyrun.setValue(0);
				if (!me.C1ADP_supply.getValue()) { # If pump doesn't have access to fluid, keep it blocked.
					me.C1ADP_avail.setValue(3); # 3 = Blocked NoSupply
				}
			} else { # Pump was not switched off.
				# TODO: set fire to the pump?
			}
		}
		elsif(me.c1adp_switch.getValue() > 0 and me.C1ADP_supply.getValue() and !me.BleedAir.getValue())
        {
            me.C1ADP_avail.setValue(4); # 4 = No Bleed Air
            me.C1ADP_fine.setValue(0);
        }
		elsif(me.c1adp_switch.getValue() > 0 and !me.C1ADP_supply.getValue() and !me.BleedAir.getValue())
        {
            me.C1ADP_avail.setValue(6); # 6 = No Fluid Supply & No Bleed Air
            me.C1ADP_fine.setValue(0);
        }
        else
        {
            me.C1ADP_avail.setValue(0);
            if(cpt_flt_inst.getValue() > 24)
            {
                me.C1ADP_fine.setValue(0);
            }
            else
            {
                me.C1ADP_fine.setValue(1);
            }
        }
		
			#C2 Demand pump
        if(me.c2adp_switch.getValue() > 0 and me.C2ADP_supply.getValue() and me.BleedAir.getValue())
        {
            me.C2ADP_avail.setValue(me.c2adp_switch.getValue()); # 1 = auto; 2 = on.
			if ((me.C2ADP.getValue() and me.C2ADP_press.getValue() > 2500) or (!me.C2ADP.getValue() and me.C2ADP_Fault.getValue() == 1)) { # Causes a delay in light being extinguished
				me.C2ADP_fine.setValue(1);
			}
        }
		elsif(me.c1adp_switch.getValue() > 0 and !me.C2ADP_supply.getValue() and me.BleedAir.getValue() and !me.C2ADP_ovht.getValue())
        {
			if (me.C2ADP_emptyrun.getValue() <= 50 and me.C2ADP.getValue()) { # if running less than 10 seconds without fluid, allow the pump to keep operating
				me.C2ADP_avail.setValue(1); # Keep pump available
				me.C2ADP_fine.setValue(1);  # FAULT light off
				me.C2ADP_emptyrun.setValue(me.C2ADP_emptyrun.getValue() + 1); # Add to running empty timer
			} elsif (me.C2ADP_emptyrun.getValue() > 50) { # if running more than 10 seconds without fluid, overheat the pump and block it.
				me.C2ADP_ovht.setValue(1);  # Overheat pump
				me.C2ADP_avail.setValue(5); # 5 = Pump overheated
				me.C2ADP_fine.setValue(0);  # FAULT light on
			} else { # no fluid available but pump was not running.
				me.C2ADP_avail.setValue(3); # 3 = Blocked NoSupply
				me.C2ADP_fine.setValue(0);  #FAULT light on
			}
		}
		elsif (me.C2ADP_ovht.getValue()) # Pump is in overheated state
		{
			if (me.C2ADP_emptyrun.getValue() < 3000) { # Pump has been in overheated state for less than 10 minutes
				me.C2ADP_emptyrun.setValue(me.C2ADP_emptyrun.getValue() + 1);
				me.C2ADP_avail.setValue(5);
			} elsif (me.c2adp_switch.getValue() == 0) { # Pump has cooled down and was switched off. Remove overheat warning.
				me.C2ADP_ovht.setValue(0);
				me.C2ADP_emptyrun.setValue(0);
				if (!me.C2ADP_supply.getValue()) { # If pump doesn't have access to fluid, keep it blocked.
					me.C2ADP_avail.setValue(3); # 3 = Blocked NoSupply
				}
			} else { # Pump was not switched off.
				# TODO: set fire to the pump?
			}
		}
		elsif(me.c2adp_switch.getValue() > 0 and me.C2ADP_supply.getValue() and !me.BleedAir.getValue())
        {
            me.C2ADP_avail.setValue(4); # 4 = No Bleed Air
            me.C2ADP_fine.setValue(0);
        }
		elsif(me.c2adp_switch.getValue() > 0 and !me.C2ADP_supply.getValue() and !me.BleedAir.getValue())
        {
            me.C2ADP_avail.setValue(6); # 6 = No Fluid Supply & No Bleed Air
            me.C2ADP_fine.setValue(0);
        }
        else
        {
            me.C2ADP_avail.setValue(0);
            if(cpt_flt_inst.getValue() > 24)
            {
                me.C2ADP_fine.setValue(0);
            }
            else
            {
                me.C2ADP_fine.setValue(1);
            }
        }
		
		### Calculate the anticipated demand per system, as per FCOM.
		
		if (me.WOW.getValue()) {
			me.DemandRight.setValue(1); # Right demand pump is always running on the ground to prevent fluid transfer and to have ample power for the brakes.
			
			if (!me.DemandTakeOff.getValue() and (me.LeftThrottle.getValue() > 0.25 or me.RightThrottle.getValue() > 0.25)) { # Detect possible new takeoff based on WOW and thrust setting.
				me.DemandTakeOff.setValue(1);
				me.DemandTakeOffTime.setValue(me.CurrentTime.getValue());
				me.DemandLeft.setValue(1);
				me.DemandC1.setValue(1);
				me.DemandC2.setValue(1);
			} elsif (me.DemandTakeOff.getValue() and (me.CurrentTime.getValue() - me.DemandTakeOffTime.getValue() > me.DemandTakeOffRejectedDuration.getValue()) and (me.LeftThrottle.getValue() < 0.25 and me.RightThrottle.getValue() < 0.25)) {
				# Takeoff is aborted and sufficient time has passed.
				me.DemandTakeOffTime.setValue(0);
				me.DemandTakeOff.setValue(0);
				if (!me.DemandMainGear.getValue() and !me.DemandNoseGear.getValue() and !me.DemandFlaps.getValue()) {
					me.DemandC1.setValue(0);
					me.DemandC2.setValue(0);
					FluidLeakedC1 = FluidLeakedC1 + singledrop;
					FluidLeakedC2 = FluidLeakedC2 + singledrop;
				}
				
				if (!me.DemandRevL.getValue()) {
					me.DemandLeft.setValue(0);
					FluidLeakedLeft = FluidLeakedLeft + singledrop;
				}
				if (!me.DemandRevR.getValue()) {
					me.DemandRight.setValue(0);
					FluidLeakedRight = FluidLeakedRight + singledrop;
				}
			} elsif (me.DemandLanding.getValue() and me.DemandLandingTime.getValue() == 0) {
				#Touch down
				me.DemandLandingTime.setValue(me.CurrentTime.getValue());
			} elsif (me.DemandLanding.getValue() and (me.CurrentTime.getValue() - me.DemandLandingTime.getValue() > me.DemandLandingDuration.getValue())) {
				# Disable Landing Demand State
				me.DemandLanding.setValue(0);
				me.DemandLandingTime.setValue(0);
				if (!me.DemandMainGear.getValue() and !me.DemandNoseGear.getValue() and !me.DemandFlaps.getValue()) {
					me.DemandC1.setValue(0);
					FluidLeakedC1 = FluidLeakedC1 + singledrop;
				}
				
				if (!me.DemandRevL.getValue()) {
					me.DemandLeft.setValue(0);
					FluidLeakedLeft = FluidLeakedLeft + singledrop;
				}
				if (!me.DemandRevR.getValue()) {
					me.DemandRight.setValue(0);
					FluidLeakedRight = FluidLeakedRight + singledrop;
				}
			} elsif(!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandLeft.setValue(0);
				me.DemandC1.setValue(0);
				me.DemandC2.setValue(0);
			}
		} else { # In Air
			if (me.DemandTakeOff.getValue() and ((me.CurrentTime.getValue() - me.DemandTakeOffTime.getValue() > me.DemandTakeOffDuration.getValue()) or (me.LeftGearPos.getValue() == 0 and me.RightGearPos.getValue() == 0 and me.NoseGearPos.getValue() == 0))) {
			# Gear is up or we are in the air for at least 10 minutes
				me.DemandTakeOff.setValue(0);
				if (!me.DemandMainGear.getValue() and !me.DemandNoseGear.getValue() and !me.DemandFlaps.getValue()) {
					me.DemandC1.setValue(0);
					me.DemandC2.setValue(0);
					me.DemandLeft.setValue(0);
					me.DemandRight.setValue(0);
				}
			} elsif (!me.DemandTakeOff.getValue() and me.DemandTakeOffTime.getValue() != 0 and me.FlapPos.getValue() < 0.50 and me.AltitudeAGL.getValue() > 1000) {
				# Only set DemandTakeOff time to 0 when the flaps retracted enough and the altitude AGL is high enough to prevent DemandLanding activation.
				me.DemandTakeOffTime.setValue(0);
				FluidLeakedLeft = FluidLeakedLeft + singledrop;
				FluidLeakedRight = FluidLeakedRight + singledrop;
				FluidLeakedC1 = FluidLeakedC1 + singledrop;
				FluidLeakedC2 = FluidLeakedC2 + singledrop;				
			} elsif (me.DemandTakeOffTime.getValue() == 0 and !me.DemandLanding.getValue() and (me.FlapPos.getValue() >= 0.5 or me.GearSet.getValue() or me.AltitudeAGL.getValue() < 1000)) { # Flaps 15 or greater, gear commanded down or altitude AGL < 1000
				# Initiate landing demand state
				me.DemandLanding.setValue(1);
				me.DemandC1.setValue(1); # Demand C1 is activated in landing state.
				me.DemandLeft.setValue(1);
				me.DemandRight.setValue(1);
			} elsif (me.DemandLanding.getValue() and me.FlapPos.getValue() < 0.5 and !me.LeftGearPos.getValue() and !me.RightGearPos.getValue() and !me.NoseGearPos.getValue()) {
				# Disable Landing demand state if none of the landing criteria are active anymore (e.g. after a go around)
				me.DemandLanding.setValue(0);
				FluidLeakedLeft = FluidLeakedLeft + singledrop;
				FluidLeakedRight = FluidLeakedRight + singledrop;
				FluidLeakedC1 = FluidLeakedC1 + singledrop;
			} elsif (me.DemandLanding.getValue() and (me.LeftGearPos.getValue() > me.GearSet.getValue() or me.RightGearPos.getValue() > me.GearSet.getValue())) { # Go Around
				me.DemandLanding.setValue(0);
				FluidLeakedLeft = FluidLeakedLeft + singledrop;
				FluidLeakedRight = FluidLeakedRight + singledrop;
				FluidLeakedC1 = FluidLeakedC1 + singledrop;
				me.DemandTakeOff.setValue(1);
				me.DemandTakeOffTime.setValue(me.CurrentTime.getValue());
				me.DemandLeft.setValue(1);
				me.DemandC1.setValue(1);
				me.DemandC2.setValue(1);
				me.DemandRight.setValue(1);
			} elsif (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandLeft.setValue(0);
				me.DemandRight.setValue(0);
				me.DemandC1.setValue(0);
				me.DemandC2.setValue(0);
			}
		}
		
		### Analyse current demand per system.
		
		# Left system: Flight Controls, Left Reverser
	
		if (me.LeftRev.getValue()) {
			if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandRevL.setValue(1);
			}
			FluidLeakedLeft = FluidLeakedLeft + continuousdrop / 10; # Reversers leak less fluid (and are always fully extended)
		} else {
			me.DemandRevL.setValue(0);
		}
		
		# Right system: Flight controls, Right Reverser, Normal Brakes
		
		if (me.RightRev.getValue()) {
			if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandRevR.setValue(1);
			}
			FluidLeakedRight = FluidLeakedRight + continuousdrop / 10; # Reversers leak less fluid (and are always fully extended)
		} else {
			me.DemandRevR.setValue(0);
		}
		
		if (me.Brake.getValue() > 0 or me.AutoBrakeL.getValue() > 0 or me.AutoBrakeR.getValue() > 0) {
			if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandBrakes.setValue(1);
			}
			# Fluid leak is proportional to brake demand
			FluidLeakedRight = FluidLeakedRight + continuousdrop * me.BrakeL.getValue() + continuousdrop * me.BrakeR.getValue() + continuousdrop * me.AutoBrakeL.getValue() + continuousdrop * me.AutoBrakeR.getValue();
		} else {
			me.DemandBrakes.setValue(0);
		}
		
		if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
			if (me.DemandRevR.getValue() and me.DemandBrakes.getValue()) {
				me.DemandRight.setValue(1);
				FluidLeakedRight = FluidLeakedRight + continuousdrop; # use some extra if the demandpump is running.
			}
		}
		
		# Center system: Flight controls, Nose Gear steering-retraction-extention, flaps/slats, Altn/reserve brakes, Main gear retraction/extention
		
		if (me.NoseGearPos.getValue() != me.GearSet.getValue()) {
			if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandNoseGear.setValue(1);
			}
			FluidLeakedCNose = FluidLeakedCNose + continuousdrop;
		} else {
			me.DemandNoseGear.setValue(0);
		}
		
		if (me.LeftGearPos.getValue() != me.GearSet.getValue() or me.RightGearPos.getValue() != me.GearSet.getValue()) {
			if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandMainGear.setValue(1);
			}
			FluidLeakedC2 = FluidLeakedC2 + continuousdrop * 2;
		} else {
			me.DemandMainGear.setValue(0);
		}
		
		if (abs(me.FlapPos.getValue() - me.FlapSet.getValue()) > 0.1) { # When there is a large enough difference between requested flap setting and current flap setting
			if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandFlaps.setValue(1);
			}
			FluidLeakedC2 = FluidLeakedC2 + continuousdrop * 3; # Flap fairings allow a little more fluid to leak
		} else { # When flaps were operating but are (almost) in the required position
			if (me.DemandFlaps.getValue() and me.FlapsMovementTime.getValue() < 75) {  # if less than 15 seconds
				me.FlapsMovementTime.setValue(me.FlapsMovementTime.getValue() + 1);
				if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
					me.DemandFlaps.setValue(1);
				}
			} else {
				me.DemandFlaps.setValue(0);
				me.FlapsMovementTime.setValue(0);
			}
		}
		
		if ((me.AltnBrakeL.getValue() != 0) or (me.AltnBrakeR.getValue() != 0)) {
			if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandAltnBrake.setValue(1);
			}
			FluidLeakedC1 = FluidLeakedC1 + me.AltnBrakeL.getValue() * continuousdrop + me.AltnBrakeR.getValue() * continuousdrop; # Fluid leak is proportional to brake demand
		} else {
			me.DemandAltnBrake.setValue(0);
		}
		
		if (me.DemandNoseGear.getValue() or me.DemandMainGear.getValue() or me.DemandFlaps.getValue() or me.DemandAltnBrake.getValue()) {
			if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
				me.DemandC1.setValue(1);
			}
			FluidLeakedC1 = FluidLeakedC1 + continuousdrop; # use some extra if C1 demandpump is running.
			if ((me.DemandNoseGear.getValue and me.DemandMainGear.getValue()) and (me.DemandFlaps.getValue() or me.DemandAltnBrake.getValue())) {
				if (!me.DemandTakeOff.getValue() and !me.DemandLanding.getValue()) {
					me.DemandC2.setValue(1);
				}
				FluidLeakedC1 = FluidLeakedC1 + continuousdrop; # use some extra if C2 demandpump is running.
			}
		}
		
		if (me.leng_running.getValue() and me.PressDiffLeft.getValue() < 2500 and !me.DemandLeft.getValue()) {
			me.DemandLeft.setValue(1);
		}
		
		if ((me.leng_running.getValue() or me.reng_running.getValue()) and me.PressDiffCenter.getValue() < 2500 and !me.DemandC1.getValue()) {
			me.DemandC1.setValue(1);
		} elsif ((me.leng_running.getValue() or me.reng_running.getValue()) and me.PressDiffCenter.getValue() < 2500 and !me.DemandC2.getValue()) {
			me.DemandC2.setValue(1);
		}
		
		if (me.reng_running.getValue() and me.PressDiffRight.getValue() < 2500 and !me.DemandRight.getValue()) {
			me.DemandRight.setValue(1);
		}
		
		### Configure current valve state (default: all valves open)
		
		me.LeftSOV.setValue(1); 		# Only shut off by the left Engine Fire switch - TODO
		me.RightSOV.setValue(1);		# Only shut off by the right Engine Fire switch - TODO
		
		# Nosegear Isolation valve closes when center reservoir quantity is low, but opens when:
		# - airspeed lower than 60 knots
		# - or Hydraulic pressure to the center system flight controls goes low
		# - or The landing gear is selected down, both engines are normal and both engine-driven pumps are providing pressure
		if (me.CenterReservoirLvlNorm.getValue() <= 0.40) {
			if (
					(me.AirSpeed.getValue() <= 60)
					or (me.C2ACMP_press.getValue() < 500 and me.C1ADP_press.getValue() < 500 and me.C2ADP_press.getValue() < 500 and me.RAT_press.getValue() < 500)
					or (me.LEDP_press.getValue() >= 1500 and me.REDP_press.getValue() >= 1500 and me.leng_running.getValue() == 1 and me.reng_running.getValue() == 1 and me.GearSet.getValue() == 1)
		  ) {
				me.NoseGearIsln.setValue(1);
			} else {
				me.NoseGearIsln.setValue(0);
			}		
		} else {
			me.NoseGearIsln.setValue(1);
		}
		
		# Center System C1 Isolation Valve closes when center reservoir quantity is low,
		# to make sure alt/reserve brakes (and nosegear steering) stay operational in case of a leak in the center system.
		if (me.CenterReservoirLvlNorm.getValue() <= 0.40) {
			me.C1ElecIsln.setValue(0);
		} else {
			me.C1ElecIsln.setValue(1);
		}
		
		### Add logic to configure which pumps are actively running, including hydraulic pressure.
		### Take into acount which demand pumps are in "auto" or "on" state
		
	# Left System pumps
		# Primary pump is always running if available
		if (me.LeftSOV.getValue() and me.LEDP_avail.getValue() == 1) {
			me.LEDP.setValue(1);
			me.LEDP_MFD.setValue(1);
		} else {
			me.LEDP.setValue(0);
			me.LEDP_MFD.setValue(me.LEDP_avail.getValue());
		}
		if (!me.LEDP_fine.getValue() and me.LEDP_press.getValue() < 2500) {
			me.LEDP_lowpress.setValue(1);
		} else {
			me.LEDP_lowpress.setValue(0);
		}
		
		# Demand pump is running when switched to on, or if in high demand state and in auto mode, or if LEDP is off and in auto mode.
		if ((me.LACMP_avail.getValue() == 2) or ((me.DemandLeft.getValue() or me.DemandRevL.getValue() or me.LEDP_press.getValue() < 2500) and me.LACMP_avail.getValue() == 1)) {
			me.LACMP.setValue(1);
			me.LACMP_MFD.setValue(1);
		} else {
			me.LACMP.setValue(0);
			if (me.LACMP_avail.getValue() == 1) {
				me.LACMP_MFD.setValue(0);
			} else {
				me.LACMP_MFD.setValue(me.LACMP_avail.getValue()); # 0 = off, 3 or more = blocked
			}
		}
		if (!me.LACMP_fine.getValue() and me.LACMP_press.getValue() < 2500) {
			me.LACMP_lowpress.setValue(1);
		} else {
			me.LACMP_lowpress.setValue(0);
		}
		
		# No fluid is leaked when no pumps are running
		if (!me.LEDP.getValue() and !me.LACMP.getValue()) {
			FluidLeakedLeft = 0;
		}
		
	# Right System pumps
		# Primary pump is always running if available
		if (me.RightSOV.getValue() and me.REDP_avail.getValue() == 1) {
			me.REDP.setValue(1);
			me.REDP_MFD.setValue(1);
		} else {
			me.REDP.setValue(0);
			me.REDP_MFD.setValue(me.REDP_avail.getValue());
		}
		if (!me.REDP_fine.getValue() and me.REDP_press.getValue() < 2500) {
			me.REDP_lowpress.setValue(1);
		} else {
			me.REDP_lowpress.setValue(0);
		}
		
		# Demand pump is running when switched to on, or if in high demand state and in auto mode, or if LEDP is off and in auto mode.
		if ((me.RACMP_avail.getValue() == 2) or ((me.DemandRight.getValue() or me.DemandBrakes.getValue() or me.DemandRevR.getValue() or me.REDP.getValue() == 0) and me.RACMP_avail.getValue() == 1)) {
			me.RACMP.setValue(1);
			me.RACMP_MFD.setValue(1);
		} else {
			me.RACMP.setValue(0);
			if (me.RACMP_avail.getValue() == 1) {
				me.RACMP_MFD.setValue(0);
			} else {
				me.RACMP_MFD.setValue(me.RACMP_avail.getValue()); # 0 = off, 3 or more = blocked
			}
		}
		if (!me.RACMP_fine.getValue() and me.RACMP_press.getValue() < 2500) {
			me.RACMP_lowpress.setValue(1);
		} else {
			me.RACMP_lowpress.setValue(0);
		}
		
		# No fluid is leaked when no pumps are running
		if (!me.REDP.getValue() and !me.RACMP.getValue()) {
			FluidLeakedRight = 0;
		}

	# Center System pumps
	
		# Primary pumps are always running if available
		
		if (me.C1ACMP_avail.getValue() == 1) {
			me.C1ACMP.setValue(1);
			me.C1ACMP_MFD.setValue(1);
		} else {
			me.C1ACMP.setValue(0);
			if (me.C1ACMP_avail.getValue() == 1) {
				me.C1ACMP_MFD.setValue(0);
			} else {
				me.C1ACMP_MFD.setValue(me.C1ACMP_avail.getValue());
			}
		}
		if (!me.C1ACMP_fine.getValue() and me.C1ACMP_press.getValue() < 2500) {
			me.C1ACMP_lowpress.setValue(1);
		} else {
			me.C1ACMP_lowpress.setValue(0);
		}
		
		if (me.C2ACMP_avail.getValue() == 1) {
			me.C2ACMP.setValue(1);
			me.C2ACMP_MFD.setValue(1);
		} else {
			me.C2ACMP.setValue(0);
			if (me.C2ACMP_avail.getValue() == 1) {
				me.C2ACMP_MFD.setValue(0);
			} else {
				me.C2ACMP_MFD.setValue(me.C2ACMP_avail.getValue());
			}
		}
		if (!me.C2ACMP_fine.getValue() and me.C2ACMP_press.getValue() < 2500) {
			me.C2ACMP_lowpress.setValue(1);
		} else {
			me.C2ACMP_lowpress.setValue(0);
		}
		
		# Demand pumps are running based on demand and primary pump state
		# C1ADP: If C1ADP is "on", or C1ADP is "auto" and either C1 demand is high, C1 Elec pump is off, C2 demand is high and C2ADP is off or both C2 Elec and C2ADP are off
		if (	(me.C1ADP_avail.getValue() == 2) 
			or 	(me.C1ADP_avail.getValue() == 1 and (me.DemandC1.getValue() or me.C1ACMP.getValue() == 0 or (me.DemandC2.getValue() and me.C2ADP.getValue() == 0) or (me.C2ACMP.getValue() == 0 and me.C2ADP.getValue() == 0 and NrPwrSrcs > 1)))) {
			me.C1ADP.setValue(1);
			me.C1ADP_MFD.setValue(1);
		} else {
			me.C1ADP.setValue(0);
			if (me.C1ADP_avail.getValue() == 1) {
				me.C1ADP_MFD.setValue(0);
			} else {
				me.C1ADP_MFD.setValue(me.C1ADP_avail.getValue());
			}
		}
		if (!me.C1ADP_fine.getValue() and me.C1ADP_press.getValue() < 2500) {
			me.C1ADP_lowpress.setValue(1);
		} else {
			me.C1ADP_lowpress.setValue(0);
		}
		
		# C2ADP: If C2ADP is "on" (but C1ADP is not on), or C2ADP is "auto" and either C2 demand is high, C2 Elec pump is off or C1 demand is high and C1ADP is off
		if (!(me.C1ADP_avail.getValue() == 2 and me.C2ADP_avail.getValue() == 2) and ((me.C2ADP_avail.getValue() == 2) or ((me.DemandC2.getValue() or (me.C2ACMP.getValue() == 0 and NrPwrSrcs > 1) or(me.DemandC1.getValue() and !me.C1ADP.getValue())) and me.C2ADP_avail.getValue() == 1))) {
			me.C2ADP.setValue(1);
			me.C2ADP_MFD.setValue(1);
		} else {
			me.C2ADP.setValue(0);
			if (me.C2ADP_avail.getValue() == 1 or (me.C1ADP_avail.getValue() == 2 and me.C2ADP_avail.getValue() == 2)) {
				me.C2ADP_MFD.setValue(0);
			} else {
				me.C2ADP_MFD.setValue(me.C2ADP_avail.getValue());
			}
		}
		if (!me.C2ADP_fine.getValue() and me.C2ADP_press.getValue() < 2500) {
			me.C2ADP_lowpress.setValue(1);
		} else {
			me.C2ADP_lowpress.setValue(0);
		}
		
		# No fluid is leaked when no pumps are running or when the shutoff valve is closed and no pump is available
		if (!me.C1ACMP.getValue() and (me.C1ElecIsln.getValue() != 1 or (!me.C2ACMP.getValue() and !me.C1ADP.getValue() and !me.C2ADP.getValue()))) {
			FluidLeakedC1 = 0;
			FluidLeakedCNose = 0;
		} elsif (me.NoseGearIsln.getValue() != 1) {
			FluidLeakedCNose = 0;
		}
		
		if ((!me.C1ACMP.getValue() or me.C1ElecIsln.getValue() != 1) and !me.C2ACMP.getValue() and !me.C1ADP.getValue() and !me.C2ADP.getValue()) {
			FluidLeakedC2 = 0;
		}
		
		### Translate output states to systems

        me.elevatorpos.setAttribute("writable",0);
        me.stabilizerpos.setAttribute("writable",0);
        me.leftaileronpos.setAttribute("writable",0);
        me.rightaileronpos.setAttribute("writable",0);
        me.rudderpos.setAttribute("writable",0);
        me.speedbkpos.setAttribute("writable",0);
		
        # Left hydraulic system
        # flight controls, left engine thrust reverser
		
		# TODO Flight controls must be split in Left, Right, Center system later (see above)
		
        if(me.LEDP.getValue() or me.LACMP.getValue())
        {
            me.reverserL.setAttribute("writable",1);
            me.elevatorpos.setAttribute("writable",1);
            me.stabilizerpos.setAttribute("writable",1);
            me.leftaileronpos.setAttribute("writable",1);
            me.rightaileronpos.setAttribute("writable",1);
            me.rudderpos.setAttribute("writable",1);
            me.speedbkpos.setAttribute("writable",1);
        }
        else
        {
            me.reverserL.setAttribute("writable",0);
        }
        # right hydraulic system
        # flight controls, normal brakes, right thrust reverser
        
        if(me.REDP.getValue() or me.RACMP.getValue())
        {
            me.reverserR.setAttribute("writable",1);
            me.elevatorpos.setAttribute("writable",1);
            me.leftaileronpos.setAttribute("writable",1);
            me.rightaileronpos.setAttribute("writable",1);
            me.rudderpos.setAttribute("writable",1);
            me.speedbkpos.setAttribute("writable",1);
			me.BrakeL.setAttribute("writable",1);
			me.BrakeR.setAttribute("writable",1);
			me.AutoBrakeL.setAttribute("writable",1);
			me.AutoBrakeR.setAttribute("writable",1);
        }
        else
        {
            me.reverserR.setAttribute("writable",0);
			if (me.Brake_Accum_press.getValue() < 1000.0) {
				me.BrakeL.setValue(0);
				me.BrakeL.setAttribute("writable",0);
				me.BrakeR.setValue(0);
				me.BrakeR.setAttribute("writable",0);
				me.AutoBrakeL.setValue(0);
				me.AutoBrakeL.setAttribute("writable",0);
				me.AutoBrakeR.setValue(0);
				me.AutoBrakeR.setAttribute("writable",0);
			}
		}
		
        # center hydraulic system
        # flight controls, leading edge slats, trailing edge flaps, landing gear actuation, alternate brakes, nose gear and main gear steering

        # Nose Gear steering and extention/retraction
		# Pseudopilot patch: the hydraulic pressure check below intermittently
		# flips NoseGearPos writable=0 mid-transit (NoseGearIsln is false at
		# cruise speed with pumps still spooling), which freezes the gear
		# halfway through deploy/retract. Keep NoseGearPos always writable
		# so external gear commands take effect regardless of transient
		# hydraulic state.
		me.NoseGearPos.setAttribute("writable", 1);
		if (me.NoseGearIsln.getValue() == 1 and (me.C1ACMP.getValue() or (me.C1ElecIsln.getValue() and (me.C2ACMP.getValue() or me.C1ADP.getValue() or me.C2ADP.getValue())))) {
			me.NoseGearSteering.setAttribute("writable", 1);
		} else {
			me.NoseGearSteering.setAttribute("writable", 0);
		}
		
		# Alternate/Reserve brakes
		if (me.C1ACMP.getValue() or (me.C1ElecIsln.getValue() and (me.C2ACMP.getValue() or me.C1ADP.getValue() or me.C2ADP.getValue()))) {
			# Enable reserve brakes
			me.AltnBrakeL.setAttribute("writable", 1);
			me.AltnBrakeR.setAttribute("writable", 1);
			if (!me.REDP.getValue() and !me.RACMP.getValue()) {
				me.BrakeSource.setValue(1); # If right system is off and center system is on, center system is pressurizing the brakes.
			} else {
				me.BrakeSource.setValue(2); # If right system is on, it pressurizes the brakes.
			}
		} else {
			# Disable reserve brakes
			me.AltnBrakeL.setValue(0);
			me.AltnBrakeL.setAttribute("writable", 0);
			me.AltnBrakeR.setValue(0);
			me.AltnBrakeR.setAttribute("writable", 0);
			
			me.BrakeSource.setValue(2); # If both right and center system are off, brake accumulator (system 2) is pressurizing the brakes
		}
		
		# Flaps, Main Gear Steering/Extention/Retraction

		# Pseudopilot patch: same reasoning as NoseGearPos — keep LeftGearPos
		# and RightGearPos always writable so external gear commands are not
		# silently dropped when the hydraulic pump chain fails its pressure
		# check for a frame during spool-up or transition.
		me.LeftGearPos.setAttribute("writable", 1);
		me.RightGearPos.setAttribute("writable", 1);
		if ((me.C1ACMP.getValue() and me.C1ElecIsln.getValue()) or me.C2ACMP.getValue() or me.C1ADP.getValue() or me.C2ADP.getValue()) {
			me.flappos.setAttribute("writable", 1);
			me.MainGearSteering.setAttribute("writable", 1);
		} else {
			me.flappos.setAttribute("writable", 0);
			me.MainGearSteering.setAttribute("writable", 0);
		}
		
		# Flight controls
		
		if ((me.C1ACMP.getValue() and me.C1ElecIsln.getValue()) or me.C2ACMP.getValue() or me.C1ADP.getValue() or me.C2ADP.getValue() or me.RAT.getValue()) {
            me.elevatorpos.setAttribute("writable",1);
            me.leftaileronpos.setAttribute("writable",1);
            me.rightaileronpos.setAttribute("writable",1);
            me.rudderpos.setAttribute("writable",1);
            me.speedbkpos.setAttribute("writable",1);
		}

		# Pushback connected: steering override
		
        if(me.PushConn.getValue()) {
			me.NoseGearSteering.setAttribute("writable",1);
			me.MainGearSteering.setAttribute("writable" ,1); # TODO: Main Gear is passively steering when pushing back - not simulated yet but allow main gear steering to be operated.
		}
		
		### Tell FCS if the Hydraulics are available or not - JD
		setprop("/fcs/left-out-aileron/hyd-avail", me.leftaileronpos.getAttribute("writable"));
		setprop("/fcs/left-in-aileron/hyd-avail", me.leftaileronpos.getAttribute("writable"));
		setprop("/fcs/right-in-aileron/hyd-avail", me.rightaileronpos.getAttribute("writable"));
		setprop("/fcs/right-out-aileron/hyd-avail", me.rightaileronpos.getAttribute("writable"));
		setprop("/fcs/left-elevator/hyd-avail", me.elevatorpos.getAttribute("writable"));
		setprop("/fcs/right-elevator/hyd-avail", me.elevatorpos.getAttribute("writable"));
		setprop("/fcs/stabilizer/hyd-avail", me.elevatorpos.getAttribute("writable"));
		setprop("/fcs/rudder/hyd-avail", me.rudderpos.getAttribute("writable"));
		setprop("/fcs/spoilers/hyd-avail", me.	speedbkpos.getAttribute("writable"));
		
		### Apply hydraulic fluid loss (due to wear, leaks...)
		
		if (me.DemandLeftLeak.getValue() > 0) {		
			FluidLeakedLeft += LeakQuantity * me.DemandLeftLeak.getValue() * ((me.Left_press.getValue() + 1000) / 1000);
		}
		
		if (me.DemandC1Leak.getValue() > 0) {
			if (me.C1ElecIsln.getValue()) {
				FluidLeakedC1 += LeakQuantity * me.DemandC1Leak.getValue() * ((me.Ctr_press.getValue() + 1000) / 1000);
			} else {
				FluidLeakedC1 += LeakQuantity * me.DemandC1Leak.getValue() * ((me.C1ACMP_press.getValue() + 1000) / 1000);
			}
		}
		
		if (me.DemandNoseLeak.getValue() > 0) {
			if (me.NoseGearIsln.getValue()) {
				if (me.C1ElecIsln.getValue()) {
					FluidLeakedCNose += LeakQuantity * me.DemandNoseLeak.getValue() * ((me.Ctr_press.getValue() + 1000) / 1000);
				} else {
					FluidLeakedCNose += LeakQuantity * me.DemandNoseLeak.getValue() * ((me.C1ACMP_press.getValue() + 1000) / 1000);
				}
			} else {
				FluidLeakedCNose += LeakQuantity * me.DemandNoseLeak.getValue();
			}
		}
		
		if (me.DemandC2Leak.getValue() > 0) {
			FluidLeakedC2 += LeakQuantity * me.DemandC2Leak.getValue() * ((me.Ctr_press.getValue() + 1000) / 1000);
		}
		
		if (me.DemandRightLeak.getValue() > 0) {
			FluidLeakedRight += LeakQuantity * me.DemandRightLeak.getValue() * ((me.Right_press.getValue() + 1000) / 1000);
		}
		
		if (me.FluidLeaksEnabled.getValue() == 1) {
			if (FluidLeakedLeft < me.LeftReservoirLvl.getValue()) {
				me.LeftReservoirLvl.setValue(me.LeftReservoirLvl.getValue() - FluidLeakedLeft);
			} else {				
				me.LeftReservoirLvl.setValue(0);
			}
			if (FluidLeakedC1 + FluidLeakedC2 + FluidLeakedCNose < me.CenterReservoirLvl.getValue()) {
				me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() - FluidLeakedC1 - FluidLeakedC2 - FluidLeakedCNose);
			} else {
				me.CenterReservoirLvl.setValue(0);
			}
			if (FluidLeakedRight < me.RightReservoirLvl.getValue()) {
				me.RightReservoirLvl.setValue(me.RightReservoirLvl.getValue() - FluidLeakedRight);
			} else {
				me.RightReservoirLvl.setValue(0);
			}
		}
		
		### Calculate brakesystem fluid transfer between center and right system
		
		var CylinderDiffNorm = me.BrakeSysLeft_norm.getValue() - math.max(me.BrakeL.getValue(), me.AutoBrakeL.getValue(), me.AltnBrakeL.getValue(), me.ParkingBrakeSet.getValue());
		var CylinderDiffGal = CylinderDiffNorm * me.BrakesCapacity.getValue();
		var CurrentSource = me.BrakeSource.getValue();
		
		# If CylinderDiffNorm > 0 then fluid is added to the brake system and removed from the active fluid reservoir
		# If CylinderDiffNorm < 0 then fluid is removed from the brake system and added to the active fluid reservoir
		
		me.BrakeSysLeft_norm.setValue(me.BrakeSysLeft_norm.getValue() - CylinderDiffNorm);
		me.BrakeSysLeft_lvl.setValue(me.BrakeSysLeft_lvl.getValue() - CylinderDiffGal);
		if (CurrentSource == 1) {
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() + CylinderDiffGal);
		} elsif (CurrentSource == 2) {
			me.RightReservoirLvl.setValue(me.RightReservoirLvl.getValue() + CylinderDiffGal);
		}
		
		CylinderDiffNorm = me.BrakeSysRight_norm.getValue() - math.max(me.BrakeR.getValue(), me.AutoBrakeR.getValue(), me.AltnBrakeR.getValue(), me.ParkingBrakeSet.getValue());
		CylinderDiffGal = CylinderDiffNorm * me.BrakesCapacity.getValue();
		
		me.BrakeSysRight_norm.setValue(me.BrakeSysRight_norm.getValue() - CylinderDiffNorm);
		me.BrakeSysRight_lvl.setValue(me.BrakeSysRight_lvl.getValue() - CylinderDiffGal);
		if (CurrentSource == 1) {
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() + CylinderDiffGal);
		} elsif (CurrentSource == 2) {
			me.RightReservoirLvl.setValue(me.RightReservoirLvl.getValue() + CylinderDiffGal);
		}
		
		### Calculate gear retraction fluid drop because it is noticable on the hyd synoptics screen
		### After gear retraction, the gear is mechanically locked and hydraulic fluid is removed from the system so the center system fills back to full
		### Gear extension doesn't require as much hydraulic fluid because gear extension mainly relies on gravity
		
		var GearDiffGal = 0;
		
		# Left Main Gear operation
		if (me.LeftGearPos.getAttribute("writable") and me.LeftGearPos.getValue() > me.GearSet.getValue()) { # 1 = gear down; gear retraction: system moves from 1 to 0.
			GearDiffGal = me.GearCapacityL.getValue() - me.GearCapacityL.getValue() * me.LeftGearPos.getValue() - me.GearCylinderL.getValue();
			me.GearCylinderL.setValue(me.GearCylinderL.getValue() + GearDiffGal);
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() - GearDiffGal);
		} elsif (me.LeftGearPos.getAttribute("writable") and me.LeftGearPos.getValue() < me.GearSet.getValue()) { # 1 = gear down; gear extension: system moves from 0 to 1.
			GearDiffGal = me.GearCapacityL.getValue() / 4 * me.LeftGearPos.getValue() - me.GearCylinderL.getValue();
			me.GearCylinderL.setValue(me.GearCylinderL.getValue() + GearDiffGal);
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() - GearDiffGal);			
		} elsif (me.GearCylinderL.getValue() > 0) {
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() + me.GearCylinderL.getValue());
			me.GearCylinderL.setValue(0);
		}
		
		# Right Main Gear operation
		if (me.RightGearPos.getAttribute("writable") and me.NoseGearPos.getValue() > me.GearSet.getValue()) { # 1 = gear down; gear retraction: system moves from 1 to 0.
			GearDiffGal = me.GearCapacityR.getValue() - me.GearCapacityR.getValue() * me.RightGearPos.getValue() - me.GearCylinderR.getValue();
			me.GearCylinderR.setValue(me.GearCylinderR.getValue() + GearDiffGal);
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() - GearDiffGal);
		} elsif (me.RightGearPos.getAttribute("writable") and me.RightGearPos.getValue() < me.GearSet.getValue()) { # 1 = gear down; gear extension: system moves from 0 to 1.
			GearDiffGal = me.GearCapacityR.getValue() / 4 * me.RightGearPos.getValue() - me.GearCylinderR.getValue();
			me.GearCylinderR.setValue(me.GearCylinderR.getValue() + GearDiffGal);
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() - GearDiffGal);			
		} elsif (me.GearCylinderR.getValue() > 0) {
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() + me.GearCylinderR.getValue());
			me.GearCylinderR.setValue(0);
		}
		
		# Nosegear operation
		if (me.NoseGearPos.getAttribute("writable") and me.NoseGearPos.getValue() > me.GearSet.getValue()) { # 1 = gear down; gear retraction: system moves from 1 to 0.
			GearDiffGal = me.GearCapacityN.getValue() - me.GearCapacityN.getValue() * me.NoseGearPos.getValue() - me.GearCylinderN.getValue();
			me.GearCylinderN.setValue(me.GearCylinderN.getValue() + GearDiffGal);
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() - GearDiffGal);
		} elsif (me.NoseGearPos.getAttribute("writable") and me.NoseGearPos.getValue() < me.GearSet.getValue()) { # 1 = gear down; gear extension: system moves from 0 to 1.
			GearDiffGal = me.GearCapacityN.getValue() / 4 * me.NoseGearPos.getValue() - me.GearCylinderN.getValue();
			me.GearCylinderN.setValue(me.GearCylinderN.getValue() + GearDiffGal);
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() - GearDiffGal);			
		} elsif (me.GearCylinderN.getValue() > 0) {
			me.CenterReservoirLvl.setValue(me.CenterReservoirLvl.getValue() + me.GearCylinderN.getValue());
			me.GearCylinderN.setValue(0);
		}
		
		# Parking Brake state when powered by Brake Accumulator and no hydraulic power. (Brake Accumulator pressure loss is simulated in Systems/777-autobrake.xml)
		if (me.ParkingBrake.getValue() and me.Right_press.getValue() < 1000 and me.Ctr_press.getValue() < 1000) {
			if (me.Brake_Accum_press.getValue() <= 1000) {
				me.ParkingBrakeSet.setValue(0);
			} else {
				me.ParkingBrakeSet.setValue(1);
			}
		}
		
    },
	
	parking : func{
		# Simulate brake accumulator parking brake drop. (listener on parking brake)
		if (me.ParkingBrakeSet.getValue()) {
			if (me.Right_press.getValue() < 1000 and me.Ctr_press.getValue() < 1000 and !me.ParkingBrakeState.getValue()) {
				# The Pressure Drop in the Brake Accum. is dependent on the pressure in the accum. The parking brake can be succesfully set as long as there is more than about 1000-1200 psi in the accum.
				if (me.Brake_Accum_Drop.getValue() >= me.Brake_Accum_press.getValue() - 50) {
					me.Brake_Accum_press.setValue(50); # Will be overwritten by property rule to environment pressure.
				} else {
					me.Brake_Accum_press.setValue(me.Brake_Accum_press.getValue() - me.Brake_Accum_Drop.getValue());
				}
			}
			me.ParkingBrakeState.setValue(1)
		} elsif (!me.ParkingBrakeSet.getValue()) {
			me.ParkingBrakeState.setValue(0);
		}
	},
	
	refill : func{
		me.LeftReservoirLvl.setValue(me.LeftReservoirCapacity.getValue());
		me.CenterReservoirLvl.setValue(me.CenterReservoirCapacity.getValue());
		me.RightReservoirLvl.setValue(me.RightReservoirCapacity.getValue());
		me.HydrRefill.setValue(0);
	}
};

var Hydr = HYDR.new("systems/hydraulics");

var update_hyderaulics = func {
    Hydr.update();
    settimer(update_hyderaulics, 0.2);
}

#####################################
    setlistener("sim/signals/fdm-initialized", func {
    settimer(update_hyderaulics,5);
});

	setlistener("controls/gear/brake-parking-set", func {
	Hydr.parking();
});
