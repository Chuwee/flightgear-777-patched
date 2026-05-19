#############################################################################
# 777 Autopilot Flight Director System
# Originally written by Syd Adams
# Modified and Refactored by Sidi Liang
#
# speed modes: THR, THR REF, IDLE, HOLD, SPD;
# roll modes : TO/GA, HDG SEL, HDG HOLD, LNAV, LOC, ROLLOUT, TRK SEL, TRK HOLD, ATT;
# pitch modes: TO/GA, ALT, V/S, VNAV PTH, VNAV SPD, VNAV ALT, G/S, FLARE, FLCH SPD, FPA;
# FPA range  : -9.9 ~ 9.9 degrees
# VS range   : -8000 ~ 6000
# ALT range  : 0 ~ 50,000
# KIAS range : 100 ~ 399
# MACH range : 0.40 ~ 0.95
#
#############################################################################

#Usage : var afds = AFDS.new();

var afdsReload= func() {
    print("afds reload request\n");
    afds.del();
    io.load_nasal(getprop("/sim/aircraft-dir") ~ "/Nasal/AFDS.nas","b777");
}


# Todo:
# - Further refactor the code
# - LNAV is now relying on FG route manager for flightplan management, but this
#   code is doing sequencing and turn anticipation. This might conflict with the 
#   route manager's own sequencing.
# - Turn anticipation needs to be improved - Sidi Liang, 20250808
# - Check VNAV thrust mode logic - Sidi Liang, 20240818


# Constants
var KT2FPS = 1.68781;  # Knots to feet per second
var MAX_VS = 6000;     # Maximum vertical speed (ft/min)
var MIN_VS = -8000;    # Minimum vertical speed (ft/min)
var MIN_KIAS = 100;    # Minimum indicated airspeed (knots)
var MAX_KIAS = 399;    # Maximum indicated airspeed (knots)
var MIN_MACH = 0.40;   # Minimum mach number
var MAX_MACH = 0.95;   # Maximum mach number
var CLIMB_CROSSOVER_MACH = 0.840;   # Trigger only (do not force target to this exact Mach)
var DESCENT_CROSSOVER_IAS = 310;    # Trigger only (do not force target to this exact IAS)
var SWITCH_HYSTERESIS_MACH = 0.005; # ~0.005 Mach (~3 kt) hysteresis to avoid chatter
var SWITCH_HYSTERESIS_IAS = 2;      # 2 kt hysteresis to avoid chatter

# Altitude constants
var MIN_AP_ENGAGE_ALT = 200;           # Minimum altitude for AP engagement (ft)
var MIN_AT_ENGAGE_ALT = 400;           # Minimum altitude for AT engagement (ft)
var FLARE_THRESHOLD_ALT = 50;          # Altitude threshold for flare mode (ft)
var ROLLOUT_THRESHOLD_ALT = 30;        # Altitude threshold for rollout mode (ft)
var GS_CAPTURE_THRESHOLD_ALT = 1500;   # Altitude threshold for G/S capture (ft)

# Speed constants
var MIN_INDICATOR_SPEED = 30;          # Minimum speed to display on indicator (kt)
var TOGA_MAX_SPEED = 50;               # Maximum speed for TO/GA engagement (kt)
var GROUND_SPEED_THRESHOLD = 5;        # Minimum ground speed for track calculations (kt)
var ROLLOUT_SPEED_THRESHOLD = 50;      # Speed threshold for rollout exit (kt)

# Angle and deflection constants
var LOCALIZER_PRECISION_THRESHOLD = 0.5233;  # Threshold for precision localizer
var LOCALIZER_DEFLECTION_FACTOR = 1.728;     # Factor for localizer deflection
var GS_DEFLECTION_THRESHOLD = 0.1;           # Glideslope deflection threshold
var LOCALIZER_CAPTURE_DEFLECTION = 9.5;      # Max deflection for LOC capture

# Bank angle constants
var BANK_ANGLE_30 = 30;    # 30 degree bank limit
var BANK_ANGLE_5 = 5;      # 5 degree bank threshold
var BANK_ANGLE_3 = 3;      # 3 degree bank threshold for mode switch

# Physical constants
var SEA_LEVEL_PRESSURE_PA = 101325;    # Standard sea level pressure (Pa)
var SEA_LEVEL_DENSITY = 1.225;         # Standard sea level air density (kg/m³)
var INHG_TO_PA = 3386.388640341;       # Conversion factor from inHg to Pa
var MS_TO_KNOTS = 1.94384449;          # Conversion factor from m/s to knots
var AIR_GAMMA_EXP = 0.285714286;       # (γ-1)/γ for air, where γ is ~1.4

var verticalMode = {
    ALT:  1,
    VS:   2,
    VNAV_PTH: 3,
    VNAV_SPD: 4,
    VNAV_ALT: 5,
    GS: 6,
    FLARE: 7,
    FLCH: 8,
    FPA: 9,
    TOGA: 10,
    UNKNOWN: 0,
};

# Message system
var copilot_msg_enabled = props.globals.initNode("systems/afds-copilot-msg-enabled", 1, "BOOL");
var copilot = func(msg) {
    if (copilot_msg_enabled.getValue())
        setprop("sim/messages/copilot", msg);
}

var setCDUScratchpad = func(msg) {
    setprop("/instrumentation/cdu/input", msg);
    setprop("/instrumentation/fmc/isMsg", 1);
}

var AFDS = {
    new: func{
        var m = {parents:[AFDS]};

        m.initConstants();
        m.initProperties();
        m.initListeners();
        m.registerTimers();

        m.ND_symbols = props.globals.getNode("autopilot/route-manager/vnav", 1);


        return m;
    },

    setDebug: func() {

        setprop("sim/autostart", 1);

        me.input(3,2);
        me.input(0,3);
        me.input(1,5);
        me.input(0,2);
        controls.flapsDown(2);

    },

    console: func(string) {
        if (me.AFDS_internal_console.getValue()) {
            print(string);
        }
    },

    # Clean up listeners on deletion
    del: func {
        foreach (var listener; me.listeners) {
            removelistener(listener);
        }
    },

    # Initialization
    initConstants: func() {
        me.spd_list=["","THR","THR REF","HOLD","IDLE","SPD"];
        me.roll_list=["","HDG SEL","HDG HOLD","LNAV","LOC","ROLLOUT",
        "TRK SEL","TRK HOLD","ATT","TO/GA"];
        me.pitch_list=["","ALT","V/S","VNAV PTH","VNAV SPD",
        "VNAV ALT","G/S","FLARE","FLCH SPD","FPA","TO/GA"];

        me.step = 0;
        me.descent_step = 0;
        me.heading_change_rate = 0;
        me.optimal_alt = 0;
        #me.intervention_alt = 0;
        me.altitude_restriction_idx = 0;
        me.altitude_restriction = -9999.99;
        me.altitude_restriction_type = "";
        me.altitude_restriction_descent = 0;
        me.waypoint_type = 'basic';
        me.altitude_alert_from_out = 0;
        me.altitude_alert_from_in = 0;
        me.top_of_descent = 0;
        me.vorient = 0;
        me.listeners = [];
    },

    initProperties: func() {
        me.current_alt_node = props.globals.getNode("instrumentation/altimeter/indicated-altitude-ft", 1);
        me.current_vs_node = props.globals.getNode("velocities/vertical-speed-fps", 1);
        me.current_gs_node = props.globals.getNode("velocities/groundspeed-kt", 1);
        me.latitude_node = props.globals.getNode("position/latitude-deg", 1);
        me.current_tas_node = props.globals.getNode("instrumentation/airspeed-indicator/true-speed-kt", 1);
        me.indicator_speed_node = props.globals.getNode("instrumentation/airspeed-indicator/indicator-speed-kt", 1); # Airspeed on the PFD
        me.current_airspeed_node = props.globals.getNode("instrumentation/airspeed-indicator/indicated-speed-kt", 1); # Actual airspeed
        me.indicator_alt_node = props.globals.getNode("instrumentation/altimeter/indicator-altitude-ft", 1);
        me.indicated_mach_node = props.globals.getNode("instrumentation/airspeed-indicator/indicated-mach", 1);

        me.hdg_trk_selected = props.globals.initNode("instrumentation/efis/hdg-trk-selected", 0, "BOOL");
        me.heading_reference = props.globals.initNode("systems/navigation/hdgref/reference", 0, "BOOL");
        me.crab_angle = props.globals.initNode("orientation/crab-angle", 0, "DOUBLE");
        me.crab_angle_total = props.globals.initNode("orientation/crab-angle-total", 0, "DOUBLE");
        me.rwy_align_limit = props.globals.initNode("orientation/rwy-align-limit", 0, "DOUBLE");
        me.mfd_display_mode = props.globals.getNode("instrumentation/efis/mfd/display-mode", 1);

        me.weu = props.globals.getNode("instrumentation/weu/state", 1);
        me.flap1_speed = me.weu.getNode("fl1", 1);
        me.flap5_speed = me.weu.getNode("fl5", 1);
        me.flap15_speed = me.weu.getNode("fl15", 1);

        me.AFDS_node = props.globals.getNode("instrumentation/afds", 1);
        me.AFDS_inputs = me.AFDS_node.getNode("inputs", 1);
        me.AFDS_apmodes = me.AFDS_node.getNode("ap-modes", 1);
        me.AFDS_settings = me.AFDS_node.getNode("settings", 1);
        me.AFDS_internal = me.AFDS_node.getNode("internal", 1);
        me.AFDS_internal_console = me.AFDS_internal.initNode("console",0,"BOOL");
        me.AFDS_internal_altitude = me.AFDS_internal.getNode("altitude", 1);

        me.intervention_alt = me.AFDS_internal_altitude.initNode("intervention_alt",0, "DOUBLE");
        me.altitude_restriction_idx = me.AFDS_internal_altitude.initNode("altitude_restriction_idx",0, "INT");
        me.altitude_restriction = me.AFDS_internal_altitude.initNode("altitude_restriction",-9999.99, "DOUBLE");
        me.altitude_restriction_type = me.AFDS_internal_altitude.initNode("altitude_restriction_type","", "STRING");
        me.top_of_descent = me.AFDS_internal_altitude.initNode("top_of_descent",0, "DOUBLE");
        me.altitude_restriction_descent = me.AFDS_internal_altitude.initNode("altitude_restriction_descent",0, "INT");
        me.optimal_alt = me.AFDS_internal_altitude.initNode("optimal_alt",-9999.99, "DOUBLE");

        me.AP_settings = props.globals.getNode("autopilot/settings", 1);
        me.AP = me.AFDS_inputs.initNode("AP", 0, "BOOL");
        me.AP_disengaged = me.AFDS_inputs.initNode("AP-disengage", 0, "BOOL");
        me.AP_passive = props.globals.initNode("autopilot/locks/passive-mode", 1, "BOOL");
        me.AP_pitch_engaged = props.globals.initNode("autopilot/locks/pitch-engaged", 1, "BOOL");
        me.AP_roll_engaged = props.globals.initNode("autopilot/locks/roll-engaged", 1, "BOOL");
        me.AP_internal = props.globals.getNode("autopilot/internal", 1);
        me.ap_trans_node = me.AP_internal.initNode("autopilot-transition", 0, "BOOL");
        me.pitch_trans_node = me.AP_internal.initNode("pitch-transition", 0, "BOOL");
        me.roll_trans_node = me.AP_internal.initNode("roll-transition", 0, "BOOL");
        me.speed_trans_node = me.AP_internal.initNode("speed-transition", 0, "BOOL");
        me.AP_internal.initNode("presision-loc", 0, "INT");
        me.AP_internal.initNode("heading-bug-error-deg", 0, "INT");
        me.AP_internal.initNode("waypoint-bearing-error-deg", 0, "INT");
        me.airport_height = me.AP_internal.getNode("airport-height", 1);

        me.FMC = props.globals.getNode("autopilot/route-manager", 1);
        me.FMC_max_cruise_alt = me.FMC.initNode("cruise/max-altitude-ft", 10000, "DOUBLE");
        me.FMC_cruise_alt = me.FMC.initNode("cruise/altitude-ft", 10000, "DOUBLE");
        me.FMC_cruise_ias = me.FMC.initNode("cruise/speed-kts", 320, "DOUBLE");
        me.FMC_cruise_mach = me.FMC.initNode("cruise/speed-mach", 0.840, "DOUBLE");
        me.FMC_descent_ias = me.FMC.initNode("descent/speed-kts", 280, "DOUBLE");
        me.FMC_descent_mach = me.FMC.initNode("descent/speed-mach", 0.780, "DOUBLE");
        me.FMC_active = me.FMC.initNode("active", 0, "BOOL");
        me.FMC_current_wp = me.FMC.initNode("current-wp", 0, "INT");
        me.FMC_destination_ils = me.FMC.initNode("destination-ils", 0, "BOOL");
        me.FMC_landing_rwy_elevation = me.FMC.initNode("landing-rwy-elevation", 0, "DOUBLE");
        me.FMC_last_distance = me.FMC.initNode("last-distance", 0, "DOUBLE");
        me.FMC_distance_remaining = me.FMC.initNode("distance-remaining-nm", 99999, "DOUBLE");

        me.FD = me.AFDS_inputs.initNode("FD", 0, "BOOL");
        me.at1 = me.AFDS_inputs.initNode("at-armed[0]", 0, "BOOL");
        me.at2 = me.AFDS_inputs.initNode("at-armed[1]", 0, "BOOL");
        me.alt_knob = me.AFDS_inputs.initNode("alt-knob", 0, "BOOL");
        me.autothrottle_mode = me.AFDS_inputs.initNode("autothrottle-index", 0, "INT");
        me.lateral_mode = me.AFDS_inputs.initNode("lateral-index", 0, "INT");
        me.vertical_mode = me.AFDS_inputs.initNode("vertical-index", 0, "INT");
        me.gs_armed = me.AFDS_inputs.initNode("gs-armed", 0, "BOOL");
        me.loc_armed = me.AFDS_inputs.initNode("loc-armed", 0, "BOOL");
        me.vor_armed = me.AFDS_inputs.initNode("vor-armed", 0, "BOOL");
        me.lnav_armed = me.AFDS_inputs.initNode("lnav-armed", 0, "BOOL");
        me.vnav_armed = me.AFDS_inputs.initNode("vnav-armed", 0, "BOOL");
        me.rollout_armed = me.AFDS_inputs.initNode("rollout-armed", 0, "BOOL");
        me.flare_armed = me.AFDS_inputs.initNode("flare-armed", 0, "BOOL");
        me.ias_mach_selected = me.AFDS_inputs.initNode("ias-mach-selected", 0, "BOOL");
        me.vs_fpa_selected = me.AFDS_inputs.initNode("vs-fpa-selected", 0, "BOOL");
        me.bank_switch = me.AFDS_inputs.initNode("bank-limit-switch", 0, "INT");
        me.vnav_path_mode = me.AFDS_inputs.initNode("vnav-path-mode", 0, "INT");
        me.vnav_mcp_reset = me.AFDS_inputs.initNode("vnav-mcp-reset", 0, "BOOL");
        me.vnav_descent = me.AFDS_inputs.initNode("vnav-descent", 0, "BOOL");
        me.climb_continuous = me.AFDS_inputs.initNode("climb-continuous", 0, "BOOL");
        me.indicated_vs_fpm = me.AFDS_inputs.initNode("indicated-vs-fpm", 0, "DOUBLE");
        me.estimated_time_arrival = me.AFDS_inputs.initNode("estimated-time-arrival", 0, "INT");
        me.reference_deg = me.AFDS_inputs.initNode("reference-deg", 0, "DOUBLE");
        me.speed_set_after_toga = me.AFDS_inputs.initNode("speed-set-after-toga", 0, "DOUBLE");

        me.ias_setting = me.AP_settings.initNode("target-speed-kt", 200);# 100 - 399 #
        me.mach_setting = me.AP_settings.initNode("target-speed-mach", 0.40);# 0.40 - 0.95 #
        me.vs_setting = me.AP_settings.initNode("vertical-speed-fpm", 0); # -8000 to +6000 #
        me.hdg_setting = me.AP_settings.initNode("heading-bug-deg", 360, "INT"); # 1 to 360
        me.hdg_setting_last = me.AP_settings.initNode("heading-bug-last", 360, "INT"); # 1 to 360
        me.hdg_setting_active = me.AP_settings.initNode("heading-bug-active", 0, "BOOL");
        me.fpa_setting = me.AP_settings.initNode("flight-path-angle", 0); # -9.9 to 9.9 #
        me.alt_setting = me.AP_settings.initNode("counter-set-altitude-ft", 10000, "DOUBLE");
        me.alt_setting_FL = me.AP_settings.initNode("counter-set-altitude-FL", 10, "INT");
        me.alt_setting_100 = me.AP_settings.initNode("counter-set-altitude-100", 000, "INT");
        me.target_alt = me.AP_settings.initNode("actual-target-altitude-ft", 10000, "DOUBLE");
        me.radio_alt_ind = me.AP_settings.initNode("radio-altimeter-indication", 000, "INT");
        me.pfd_mach_ind = me.AP_settings.initNode("pfd-mach-indication", 000, "INT");
        me.pfd_mach_target = me.AP_settings.initNode("pfd-mach-target-indication", 000, "INT");
        me.auto_brake_setting = me.AP_settings.initNode("autobrake", 0.000, "DOUBLE");
        me.flare_constant_setting = me.AP_settings.initNode("flare-constant", 0.000, "DOUBLE");
        me.thrust_lmt = me.AP_settings.initNode("thrust-lmt", 1, "DOUBLE");
        me.flight_idle = me.AP_settings.initNode("flight-idle", 0, "DOUBLE");

        me.vs_display = me.AFDS_settings.initNode("vs-display", 0);
        me.fpa_display = me.AFDS_settings.initNode("fpa-display", 0);
        me.bank_min = me.AFDS_settings.initNode("bank-min", -25);
        me.bank_max = me.AFDS_settings.initNode("bank-max", 25);
        me.pitch_min = me.AFDS_settings.initNode("pitch-min", -10);
        me.pitch_max = me.AFDS_settings.initNode("pitch-max", 15);
        me.auto_popup = me.AFDS_settings.initNode("auto-pop-up", 0, "BOOL");
        me.heading = me.AFDS_settings.initNode("heading", 360, "INT");
        me.manual_intervention = me.AFDS_settings.initNode("manual-intervention", 0, "BOOL");

        me.AP_roll_mode = me.AFDS_apmodes.initNode("roll-mode", "TO/GA");
        me.AP_roll_arm = me.AFDS_apmodes.initNode("roll-mode-arm", " ");
        me.AP_pitch_mode = me.AFDS_apmodes.initNode("pitch-mode", "TO/GA");
        me.AP_pitch_arm = me.AFDS_apmodes.initNode("pitch-mode-arm", " ");
        me.AP_speed_mode = me.AFDS_apmodes.initNode("speed-mode", "");
        me.AP_annun = me.AFDS_apmodes.initNode("mode-annunciator", " ");

        me.gear_agl_ft_node = props.globals.getNode("position/gear-agl-ft", 1);
		
		me.hydr_PressSysL = props.globals.getNode("systems/hydraulics/warnsystem/PressSysLeft", 0);

        me.controls = props.globals.getNode("controls", 1);
        me.flap_position = me.controls.getNode("flight/flaps", 1);
        me.engines = me.controls.getNode("engines", 1);
        me.engine0_throttle = me.engines.getNode("engine[0]/throttle", 1);
        me.engine1_throttle = me.engines.getNode("engine[1]/throttle", 1);
        me.engine0_throttle_act = me.engines.getNode("engine[0]/throttle-act", 1);
        me.engine1_throttle_act = me.engines.getNode("engine[1]/throttle-act", 1);
        me.engine_rev_act = me.engines.getNode("engine/reverser-act", 1);
    },

    # Initialize listeners
    initListeners: func() {
        me.listeners = [];
        append(me.listeners, setlistener(me.AP, func me.setAP(), 0, 0));
        append(me.listeners, setlistener(me.AP_disengaged, func me.setAP(), 0, 0));
        append(me.listeners, setlistener(me.bank_switch, func me._setBank(), 0, 0));
        append(me.listeners, setlistener(me.autothrottle_mode, func me.updateATMode(), 0, 0));
        append(me.listeners, setlistener(me.FMC.getNode("wp/id",1), func me.wpChanged(), 0, 0));
        append(me.listeners, setlistener(me.FMC.getNode("active",1), func me.wpChanged(), 0, 0));
        append(me.listeners, setlistener(me.FMC_current_wp, func me.wpChanged(), 0, 0));
    },

    registerTimers: func(){
        me.hdg_setting_timer = maketimer(10, func {
            me.hdg_setting_active.setValue(0);
        });
        me.hdg_setting_timer.singleShot = 1;
        me.hdg_setting_timer.simulatedTime = 1;

        me.speed_trans_timer = maketimer(10, func {
            me.speed_trans_node.setValue(0);
        });
        me.speed_trans_timer.singleShot = 1;
        me.speed_trans_timer.simulatedTime = 1;

        me.pitch_trans_timer = maketimer(10, func {
            me.pitch_trans_node.setValue(0);
        });
        me.pitch_trans_timer.singleShot = 1;
        me.pitch_trans_timer.simulatedTime = 1;

        me.roll_trans_timer = maketimer(10, func {
            me.roll_trans_node.setValue(0);
        });
        me.roll_trans_timer.singleShot = 1;
        me.roll_trans_timer.simulatedTime = 1;

        me.ap_trans_timer = maketimer(10, func {
            me.ap_trans_node.setValue(0);
        });
        me.ap_trans_timer.singleShot = 1;
        me.ap_trans_timer.simulatedTime = 1;

    },

    isClimbing: func() {
        return !me.vnav_descent.getValue();
    },

    # Mode related Helpers
    # These aren't used in the original code due to the 
    # lack of time for sufficient testing,
    # but should be used for any newly written code

    _isVNAV: func() {
        var v = me.vertical_mode.getValue();
        return (v == 3 or v == 4 or v == 5); # VNAV PTH / VNAV SPD / VNAV ALT
    },
    _isVerticalMode: func(mode) {
        # pitch modes: TO/GA, ALT, V/S, VNAV PTH, VNAV SPD, VNAV ALT, G/S, FLARE, FLCH SPD, FPA;
        if (mode == "TOGA") return me.vertical_mode.getValue() == 10; 
        else if (mode == "ALT") return me.vertical_mode.getValue() == 1;
        else if (mode == "VS") return me.vertical_mode.getValue() == 2;
        else if (mode == "VNAV_PTH") return me.vertical_mode.getValue() == 3;
        else if (mode == "VNAV_SPD") return me.vertical_mode.getValue() == 4;
        else if (mode == "VNAV_ALT") return me.vertical_mode.getValue() == 5;
        else if (mode == "GS") return me.vertical_mode.getValue() == 6;
        else if (mode == "FLARE") return me.vertical_mode.getValue() == 7;
        else if (mode == "FLCH") return me.vertical_mode.getValue() == 8;
        else if (mode == "FPA") return me.vertical_mode.getValue() == 9;
        else return 0; # Unknown mode
    },
    _setVerticalMode: func(mode) {
        # pitch modes: TO/GA, ALT, V/S, VNAV PTH, VNAV SPD, VNAV ALT, G/S, FLARE, FLCH SPD, FPA;
        if (mode == "TOGA") me.vertical_mode.setValue(10);
        else if (mode == "ALT") me.vertical_mode.setValue(1);
        else if (mode == "VS") me.vertical_mode.setValue(2);
        else if (mode == "VNAV_PTH") me.vertical_mode.setValue(3);
        else if (mode == "VNAV_SPD") me.vertical_mode.setValue(4);
        else if (mode == "VNAV_ALT") me.vertical_mode.setValue(5);
        else if (mode == "GS") me.vertical_mode.setValue(6);
        else if (mode == "FLARE") me.vertical_mode.setValue(7);
        else if (mode == "FLCH") me.vertical_mode.setValue(8);
        else if (mode == "FPA") me.vertical_mode.setValue(9);
        else return 0; # Unknown mode, do nothing
        return 1; # Mode set successfully
    },

    _isLateralMode: func(mode) {
        # roll modes : TOGA, HDG SEL, HDG HOLD, LNAV, LOC, ROLLOUT, TRK SEL, TRK HOLD, ATT;
        if (mode == "TOGA") return me.lateral_mode.getValue(0);
        else if (mode == "HDG_SEL") return me.lateral_mode.getValue(1);
        else if (mode == "HDG_HOLD") return me.lateral_mode.getValue(2);
        else if (mode == "LNAV") return me.lateral_mode.getValue(3);
        else if (mode == "LOC") return me.lateral_mode.getValue(4);
        else if (mode == "ROLLOUT") return me.lateral_mode.getValue(5);
        else if (mode == "TRK_SEL") return me.lateral_mode.getValue(6);
        else if (mode == "TRK_HOLD") return me.lateral_mode.getValue(7);
        else if (mode == "ATT") return me.lateral_mode.getValue(8);
        else return 0; # Unknown mode
    },
    _setLateralMode: func(mode) {
        # set roll modes : TOGA, HDG SEL, HDG HOLD, LNAV, LOC, ROLLOUT, TRK SEL, TRK HOLD, ATT;
        if (mode == "TOGA") me.lateral_mode.setValue(0);
        else if (mode == "HDG_SEL") me.lateral_mode.setValue(1);
        else if (mode == "HDG_HOLD") me.lateral_mode.setValue(2);
        else if (mode == "LNAV") me.lateral_mode.setValue(3);
        else if (mode == "LOC") me.lateral_mode.setValue(4);
        else if (mode == "ROLLOUT") me.lateral_mode.setValue(5);
        else if (mode == "TRK_SEL") me.lateral_mode.setValue(6);
        else if (mode == "TRK_HOLD") me.lateral_mode.setValue(7);
        else if (mode == "ATT") me.lateral_mode.setValue(8);
        else return 0; # Unknown mode, do nothing
        return 1; # Mode set successfully
    },

    _isATMode: func(mode) {
        # speed modes: OFF, THR, THR REF, HOLD, IDLE, SPD;
        if (mode == "OFF") return me.autothrottle_mode.getValue() == 0;
        else if (mode == "THR") return me.autothrottle_mode.getValue() == 1;
        else if (mode == "THR_REF") return me.autothrottle_mode.getValue() == 2;
        else if (mode == "HOLD") return me.autothrottle_mode.getValue() == 3;
        else if (mode == "IDLE") return me.autothrottle_mode.getValue() == 4;
        else if (mode == "SPD") return me.autothrottle_mode.getValue() == 5;
        else return 0; # Unknown mode
    },
    _setATMode: func(mode) {
        if(mode == "OFF") me.autothrottle_mode.setValue(0);
        else if (mode == "THR") me.autothrottle_mode.setValue(1);
        else if (mode == "THR_REF") me.autothrottle_mode.setValue(2);
        else if (mode == "HOLD") me.autothrottle_mode.setValue(3);
        else if (mode == "IDLE") me.autothrottle_mode.setValue(4);
        else if (mode == "SPD") me.autothrottle_mode.setValue(5);
        else return 0; # Unknown mode, do nothing
        return 1; # Mode set successfully
    },

    # IAS equivalent of whatever is currently in the MCP window
    _currentMcpIAS: func() {
        return (me.ias_mach_selected.getValue() == 1)
            ? int(me._calculateCalibratedAirspeed(me.mach_setting.getValue()) + 0.5)
            : int(me.ias_setting.getValue() + 0.5);
    },

    # VFE−5 using WEU speeds across detents (conservative minimum); 250 if flaps up/unknown
    _vfeMinus5Or250: func() {
        if (me.flap_position.getValue() <= 0) return 250;
        var vfe = nil;
        foreach (var v; [me.flap1_speed.getValue(), me.flap5_speed.getValue(), me.flap15_speed.getValue()]) {
            if (v != nil and v > 0) vfe = (vfe == nil) ? v : math.min(vfe, v);
        }
        if (vfe == nil) return 250;
        return int(math.max(MIN_KIAS, vfe - 5));
    },

    # Apply the FCOM rule exactly when leaving TO/GA into ALT/V/S/FPA
    _applyTogaExitMcpRule: func() {
        me.console("applyTogaExitMcpRule");
        # If MCP already shows a sensible speed and it's set after TOGA, respect it and do nothing.
        var spdIAS = me._currentMcpIAS();
        if (spdIAS >= MIN_KIAS and spdIAS <= MAX_KIAS and me.speed_set_after_toga.getValue() == 1) 
            return; # Currently speed_set_after_toga is not implemented, so this will do nothing. - LIANG Sidi, 20250827

        # Fallback per FCOM bullets
        spdIAS = me._vfeMinus5Or250();

        # Fallback is in knots -> select IAS and set it
        me.ias_mach_selected.setValue(0);
        me.ias_setting.setValue(math.clamp(spdIAS, MIN_KIAS, MAX_KIAS));
    },

    # Handling of input
    _isRouteManagerActive: func() {
        return me.FMC_active.getValue() and
            me.FMC_current_wp.getValue() >= 0 and
            (getprop("autopilot/route-manager/wp/id") != "");
    },

    _isOnGround: func() {
        return (me.gear_agl_ft_node.getValue() < 50);
    },

    _handleHorizontalControls: func(btn, current_alt) {
        var newMode = 0;
        # horizontal AP controls
        if (btn == 1) {
            # Heading Sel button
            # The 1 comes from the old code logic (btn value),
            # not sure what that means. - Sidi Liang, 20240718
            newMode = me._isOnGround() ? me.lateral_mode.getValue() : 1;
        } elsif (btn == 2) {
            # Heading Hold button
            newMode = me._handleHeadingHoldButton();
        } elsif (btn == 3) {
            # LNAV button
            # Todo: Check logic. - Sidi Liang, 20240718
            newMode = me._handleLNAVButton();
        }
        me.lateral_mode.setValue(newMode);
    },

    _handleHeadingHoldButton: func() {
        # set target to current heading
        var targetHdg = me.heading.getValue();
        me.hdg_setting.setValue(targetHdg);
        if (me.gear_agl_ft_node.getValue() < 50) {
            return me.lateral_mode.getValue();
        } else {
            return me.hdg_trk_selected.getValue() ? 6 : 1; # TRK SEL or HDG SEL
        }
    },

    _handleLNAVButton: func() {
        var currentLateralMode = me.lateral_mode.getValue();
        if (!me._isRouteManagerActive()) {
            # Route manager isn't active. Keep current mode.
            copilot("Captain, LNAV doesn't engage. We forgot to program or activate the route manager!");
            setCDUScratchpad("NO ACTIVE ROUTE");
            return currentLateralMode;
        }

        if (currentLateralMode == 3) {  # Current mode is LNAV
            return currentLateralMode;
        }

        if (me.lnav_armed.getValue()) {
            # LNAV armed, then disarm
            me.lnav_armed.setValue(0);
        } else {
            # LNAV arm
            me.lnav_armed.setValue(1);
        }

        return currentLateralMode;
    },

    _handleVerticalControls: func(btn, current_alt) {
        me.console("_handleVerticalControls");
        var newMode = 1;
        var fromTOGA = me._isVerticalMode("TOGA");
        # vertical AP controls
        if (btn == 1) {
            # hold current altitude
            if (fromTOGA) me._applyTogaExitMcpRule();
            newMode = me._handleAltitudeHold(current_alt);
        } elsif (btn == 2) {
            # hold current vertical speed
            if (fromTOGA) me._applyTogaExitMcpRule();
            newMode = me._holdCurrentVS();
        } elsif (btn == 255) {
            # V/S adjust; only run rule if we are actually switching into V/S out of TO/GA
            if (me.vertical_mode.getValue() != 2) {
                if (fromTOGA) me._applyTogaExitMcpRule();
                newMode = me._holdCurrentVS();
            } else {
                newMode = 2; # V/S but no change
            }
        } elsif (btn == 4) {
            # Altitude Intervention
            newMode = me._altitudeIntervention();
        } elsif (btn == 5) {
            # VNAV button
            newMode = me._handleVNAVButton();
        } elsif (btn == 8) {
            # FLCH button
            newMode = me._handleFLCHSPDButton(current_alt);
        }
        me.vertical_mode.setValue(newMode);
    },

    _handleFLCHSPDButton: func(current_alt) {
        # If TO/GA is the active pitch mode and FLCH is pressed, the IAS/MACH window
        # must show the HIGHER of (present IAS) and (speed set in MCP).
        if (me._isVerticalMode("TOGA")) {
            var presentIAS = int(me.current_airspeed_node.getValue() + 0.5);
            var mcpIAS = me._currentMcpIAS();
            var chosenIAS  = math.clamp(math.max(presentIAS, mcpIAS), MIN_KIAS, MAX_KIAS);

            # Spec speaks in knots; put the window on IAS and load the chosen value.
            me.ias_mach_selected.setValue(0);
            me.ias_setting.setValue(chosenIAS);
        }
        # FLCH SPD button, change flight level
        var airport_height = me.airport_height.getValue();
        if (((current_alt - airport_height) < 400) or !me._isBothATArmed()) {
            # below 400ft, or A/T not armed
            return 0; # NO MODE
        } elsif (current_alt < me.alt_setting.getValue()) {
            # climb
            me.autothrottle_mode.setValue(1);   # A/T THR
            return 8; # FLCH SPD
        } else {
            # descent
            me.autothrottle_mode.setValue(4);   # A/T IDLE
            return 8; # FLCH SPD
        }
        setprop("autopilot/internal/current-pitch-deg", getprop("orientation/pitch-deg"));
    },

    _isBothATArmed: func() {
        return me.at1.getValue() and me.at2.getValue();
    },

    _handleAltitudeHold: func(current_alt) {
        if (me.AP.getValue() or me.FD.getValue()) {
            var alt = int((current_alt + 50) / 100) * 100;
            me.target_alt.setValue(alt);
            me.autothrottle_mode.setValue(5);   # A/T SPD
            return 1; # ALT
        } else {
            return 0; # NO MODE
        }
    },

    _holdCurrentVS: func() {
        # Convert from ft/s to ft/min and round to nearest 100
        var vs = me.current_vs_node.getValue() * 60;
        vs = int(vs / 100) * 100;
        vs = math.clamp(vs, MIN_VS, MAX_VS);
        me.vs_setting.setValue(vs);

        # Set autothrottle to SPD if engaged
        if (me.autothrottle_mode.getValue() != 0) {
            me.autothrottle_mode.setValue(5);   # A/T SPD
        }
        return 2; # V/S mode
    },



    _altitudeIntervention: func() {
        if (me.alt_setting.getValue() == me.intervention_alt.getValue()) {
            if (me._isVNAV() and me.isClimbing()) {
                me.console("clearing restriction on climb");
                var clearedWpIdx = me.clearRestictionOnClimb(me.current_alt_node.getValue(),me.alt_setting.getValue());
                if (clearedWpIdx == me.altitude_restriction_idx.getValue()) {
                    me.console("cleared restriction is current restriction");
                    me.getNextRestriction(clearedWpIdx);
                }
            }
            else {
                # clear current restriction
                #
                # this is the old code, does not seems to work (JYL 8-Dec-2025)
                var temp_wpt = me.FMC_current_wp.getValue() + 1;
                me.altitude_restriction.setValue(getprop("autopilot/route-manager/route/wp["~temp_wpt~"]/altitude-ft"));
                if (me.altitude_restriction.getValue() > 0){
                    me.altitude_restriction.setValue(int((me.altitude_restriction.getValue() + 50) / 100 ) * 100);
                }
            }
        }
        else {
           me.intervention_alt.setValue(me.alt_setting.getValue());
        }

        return me.vertical_mode.getValue();
    },

    _handleVNAVButton: func() {
        var currentVerticalMode = me.vertical_mode.getValue();
        if (!me._isRouteManagerActive()) {
            # Route manager isn't active. Keep current mode.
            copilot("Captain, VNAV doesn't engage. We forgot to program or activate the route manager!");
            return currentVerticalMode;
        }

        if (me._isVNAV()) {
            # Current mode is VNAV PTH, VNAV SPD, or VNAV ALT
            return currentVerticalMode;
        }

        if (me.vnav_armed.getValue()) {
            # VNAV armed, then disarm
            me.vnav_armed.setValue(0);
        } else {
            # VNAV arm
            me.vnav_armed.setValue(1);
            me.vnav_path_mode.setValue(0);      # VNAV PTH HOLD
            me.vnav_mcp_reset.setValue(0);
            me.vnav_descent.setValue(0);
            me.descent_step = 0;
            me.manual_intervention.setValue(0);
        }

        return currentVerticalMode;
    },

    _handleThrottleControls: func(btn, current_alt) {
        if (!me._canEngageAutoThrottle()) {
            return 0;  # Auto throttle cannot engage, return mode 0
        }

        if (btn == 2) {
            # TO/GA button
            if (!me._canEngageTOGA()) {
                return 0;  # Conditions for TO/GA are not met, return mode 0
            }
            me.auto_popup.setValue(1);
            setprop("autopilot/locks/takeoff-mode", 1);
            me.speed_set_after_toga.setValue(0);
            return 2;  # TO/GA mode set
        }

        if (me._isBelowMinimumAltitude(current_alt)) {
            copilot("Captain, auto-throttle won't engage below 400ft.");
            return 0;  # Below minimum altitude for auto throttle engagement
        }

        return btn;  # Return the unchanged button if none of the above conditions apply
    },

    _canEngageAutoThrottle: func() {
        return me.autothrottle_mode.getValue() == 0 and
            me.at1.getValue() != 0 and
            me.at2.getValue() != 0;  # Ensures auto throttle is off and both ATs are armed
    },

    _canEngageTOGA: func() {
        var airspeed = me.current_airspeed_node.getValue();
        var flap_position = me.flap_position.getValue();
        return airspeed <= TOGA_MAX_SPEED and flap_position != 0; # True if airspeed is below 50kts and flaps are not retracted
    },

    _isBelowMinimumAltitude: func(current_alt) {
        var airport_height = me.airport_height.getValue();
        return current_alt - airport_height < MIN_AT_ENGAGE_ALT;  # True if aircraft is below 400ft above the airport height
    },

    _handleFDControls: func(btn, current_alt) {
        # FD, LOC, G/S button
        var lateralMode = me.lateral_mode.getValue();
        var verticalMode = me.vertical_mode.getValue();
        var gearAglFt = me.gear_agl_ft_node.getValue();

        if (btn == 2) {
            # FD button toggle
            me._handleFDButton();
        } elsif (btn == 3) {
            # AP button toggle
            me._handleAPButton();
        } elsif (btn == 0) {
            # Handle LOC arm/disarm logic
            me._handleLOCLogic(lateralMode, verticalMode, gearAglFt);
        } elsif (btn == 1) {
            # APP button logic
            me._handleAPPButton(lateralMode, verticalMode, gearAglFt);
        }
    },

    _handleFDButton: func() {
        if (me.FD.getValue()) {
            if (!getprop("controls/flight/air-sensing-sw")) {
                me.lateral_mode.setValue(9);        # TOGA
                me.vertical_mode.setValue(10);      # TOGA
            }
        } elsif (!me.AP.getValue()) {
            me.lateral_mode.setValue(0);        # Clear
            me.vertical_mode.setValue(0);       # Clear
            setprop("autopilot/internal/roll-transition", 0);
            setprop("autopilot/internal/pitch-transition", 0);
        }
    },

    _handleLOCLogic: func(lateralMode, verticalMode, gearAglFt) {
        if (me.loc_armed.getValue()) {
            if (me.gs_armed.getValue()) {
                # GS armed but not captured yet
                me.gs_armed.setValue(0);
            }
            # Disarm LOC since it's either armed or
            # already in LOC mode and needs disarming
            me.loc_armed.setValue(0);
        } elsif (lateralMode == 4) {
            # Already in LOC mode
            me._disarmGSIfNecessary(verticalMode, gearAglFt);
        } else {
            # Arm LOC if not already armed or in LOC mode
            me.loc_armed.setValue(1);
        }
    },

    _disarmGSIfNecessary: func(verticalMode, gearAglFt) {
        if (me.gs_armed.getValue()) {
            me.gs_armed.setValue(0);
        } elsif (verticalMode != 6 and gearAglFt > 1500) {
            me.lateral_mode.setValue(8); # Default roll mode (ATT)
        }
    },

    _handleAPPButton: func(lateralMode, verticalMode, gearAglFt) {
        if (lateralMode == 4
            and (me.gs_armed.getValue(1) or verticalMode == 6)
            and gearAglFt > 1500) {
            # Already in LOC mode and conditions are met to switch to default modes
            me.lateral_mode.setValue(8); # Default roll mode (ATT)
            me.vertical_mode.setValue(2); # Default pitch mode (V/S)
            me.gs_armed.setValue(0); # Disarm G/S
        } elsif (me.loc_armed.getValue()) {
            # LOC armed but not captured yet
            me.gs_armed.setValue(0); # Disarm G/S
            me.loc_armed.setValue(0); # Disarm LOC
        } else {
            me.gs_armed.setValue(1); # Arm G/S
            me.loc_armed.setValue(1); # Arm LOC
        }
    },

    _handleAPButton: func() {
        if (!me.AP.getValue()) {
            me.rollout_armed.setValue(0);
            me.flare_armed.setValue(0);
            me.loc_armed.setValue(0); # Disarm
            me.gs_armed.setValue(0); # Disarm
            if (!me.FD.getValue()) {
                me.lateral_mode.setValue(0); # NO MODE
                me.vertical_mode.setValue(0); # NO MODE
                setprop("autopilot/internal/roll-transition", 0);
                setprop("autopilot/internal/pitch-transition", 0);
            } else {
                if (me.hdg_trk_selected.getValue()) {
                    me.lateral_mode.setValue(7); # TRK HOLD
                } else {
                    me.lateral_mode.setValue(2); # HDG HOLD
                }
                me.vertical_mode.setValue(1); # ALT
            }
        } else {
            if (!me.FD.getValue()
                and !me.lnav_armed.getValue()
                and (me.lateral_mode.getValue() != 3)) {
                me.lateral_mode.setValue(8); # ATT
            }
            if (!me.vnav_armed.getValue()
                and (me.vertical_mode.getValue() == 0)) {
                # hold current vertical speed
                var vs = me.current_vs_node.getValue() * 60;
                vs = int(vs / 100) * 100;
                math.clamp(vs, -8000, 6000);
                me.vs_setting.setValue(vs);
                me.vertical_mode.setValue(2); # V/S
            }
        }
    },

    _handleOtherModes: func(btn) {
        var currentLateralMode = me.lateral_mode.getValue();
        if (btn == 0) {
            me.referenceChange();
            me.hdg_setting.setValue(me.heading.getValue());
            if (me.hdg_trk_selected.getValue()) {
                if (currentLateralMode == 1 or currentLateralMode == 2) {
                    me.lateral_mode.setValue(6);    # TRK SEL
                }
            } else {
                if (currentLateralMode == 6 or currentLateralMode == 7) {
                    me.lateral_mode.setValue(1);    # HDG SEL
                }
            }
        }
    },

    input: func(mode, btn) {
        me.console("input mode "~mode~" btn "~btn);
        if (!getprop("systems/electrical/outputs/avionics")) {
            return; # Exit if avionics power is off
        }

        var current_alt = me.current_alt_node.getValue();

        # Process input based on mode
        if (mode == 0) {
            me._handleHorizontalControls(btn, current_alt);
        } elsif (mode == 1) {
            me._handleVerticalControls(btn, current_alt);
        } elsif (mode == 2) {
            # throttle AP controls
            var newMode = me._handleThrottleControls(btn, current_alt);
            me.autothrottle_mode.setValue(newMode);
        } elsif (mode == 3) {
            me._handleFDControls(btn, current_alt);
        } elsif (mode == 4) {
            # Other (HDG REF button, TRK-HDG)
            me._handleOtherModes(btn);
        }
    },

    # Disarm all armed modes
    disarmAllModes: func() {
        me.rollout_armed.setValue(0);
        me.flare_armed.setValue(0);
        me.loc_armed.setValue(0);
        me.gs_armed.setValue(0);
    },

    # Clear all modes and transitions
    clearAllModes: func() {
        me.lateral_mode.setValue(0);
        me.vertical_mode.setValue(0);
        setprop("autopilot/internal/roll-transition", 0);
        setprop("autopilot/internal/pitch-transition", 0);
    },

    # Set default modes when AP is engaged
    setDefaultModesOnAPEngage: func() {
        if (!me.FD.getValue() and !me.lnav_armed.getValue() and !me._isLateralMode("LNAV")) {
            me._setLateralMode("ATT");
        }

        if (!me.vnav_armed.getValue() and me._isVerticalMode("TOGA")) {
            me._holdCurrentVS();
        }
    },

    setAP: func() {
        # Initialize heading if not set
        if (me.heading.getValue() == nil) {
            me.heading.setValue(getprop("sim/presets/heading-deg"));
        }

        var output = 1 - me.AP.getValue();
        var disabled = me.AP_disengaged.getValue();

        # Check minimum engagement altitude
        if (output == 0 and me.gear_agl_ft_node.getValue() < 200) {
            disabled = 1;
            copilot("Captain, autopilot won't engage below 200ft.");
        }

        # Handle disengaged state
        if (disabled and (output == 0)) {
            output = 1;
            me.AP.setValue(0);
        }

        if (output == 1) {
            # AP is disengaged
            copilot("Captain, autopilot disengaged.");
            me.disarmAllModes();

            if (!me.FD.getValue()) {
                me.clearAllModes();
            } else {
                if (me.lateral_mode.getValue() == 0) {
                    me.lateral_mode.setValue(2); # HDG HOLD
                }
                if (me._isVerticalMode("TOGA")) {
                    me.vertical_mode.setValue(1); # ALT
                }
            }
        } else {
            # AP is engaged
            me.setDefaultModesOnAPEngage();
        }
    },

    # Set bank limits based on bank switch position
    _setBank: func() {
        var banklimit = me.bank_switch.getValue();
        var lmt = (banklimit > 0) ? (banklimit * 5) : 25;
        me.bank_max.setValue(lmt);
        me.bank_min.setValue(-1 * lmt);
    },

    setbank: func() {
        # Deprecated, use _setBank instead
        me._setBank();
    },

    referenceChange: func() {
        var hdgRefButton = getprop("systems/navigation/hdgref/button");
        var latitudeDeg = me.latitude_node.getValue();
        var groundspeedKt = me.current_gs_node.getValue();

        # Heading reference selection
        if (hdgRefButton or (abs(latitudeDeg) > 82.0)) {
            me.heading_reference.setValue(1);
        } else {
            me.heading_reference.setValue(0);
        }

        var headingReferenceValue = me.heading_reference.getValue();
        setprop("instrumentation/efis/mfd/true-north", headingReferenceValue);
        setprop("instrumentation/efis[1]/mfd/true-north", headingReferenceValue);
        var crabAngleHdg = 0;
        var crabAngleTrk = 0;
        if (groundspeedKt > 5) {
            var headingDeg = getprop("orientation/heading-deg");
            var trackDeg = getprop("orientation/track-deg");
            var vheading = headingDeg - trackDeg;

            # Normalize vheading to (-180, 180)
            if (vheading < -180) vheading += 360;
            else if (vheading > 180) vheading -= 360;

            var isMFDInMap = me.mfd_display_mode.getValue() == "MAP";
            crabAngleHdg = isMFDInMap ? vheading : 0;
            crabAngleTrk = isMFDInMap ? 0 : vheading;
        }
        setprop("autopilot/internal/crab-angle-hdg", crabAngleHdg);
        setprop("autopilot/internal/crab-angle-trk", crabAngleTrk);

        var hdgTrkSelected = me.hdg_trk_selected.getValue();
        if (headingReferenceValue) {
            var trackDeg = getprop("orientation/track-deg");
            var headingDeg = getprop("orientation/heading-deg");
            vheading = (hdgTrkSelected and groundspeedKt > 5) ? trackDeg : headingDeg;
            me.vorient = 0;
        } else {
            var trackMagneticDeg = getprop("orientation/track-magnetic-deg");
            var headingMagneticDeg = getprop("orientation/heading-magnetic-deg");
            vheading = (hdgTrkSelected and groundspeedKt > 5) ? trackMagneticDeg : headingMagneticDeg;
            me.vorient = getprop("environment/magnetic-variation-deg");
        }
        me.reference_deg.setValue(vheading);

        me._calculateRadioDirections(vheading, crabAngleHdg);

        vheading = int(vheading + 0.5);
        if (vheading < 0.5) vheading += 360;
        me.heading.setValue(vheading);
    },

    updateATMode: func() {
        var idx = me.autothrottle_mode.getValue();
        var targetSpeedMode = me.spd_list[idx];
        if ((me.AP_speed_mode.getValue() != targetSpeedMode) and (idx > 0)) {
            me.speed_trans_node.setValue(1);
            me.speed_trans_timer.start();
        }
        me.AP_speed_mode.setValue(targetSpeedMode);
    },

    wpChanged: func() {
        if ((getprop("autopilot/route-manager/wp/id") == "") or
            !me.FMC_active.getValue() and
            (me.lateral_mode.getValue() == 3) and
            me.AP.getValue())
        {
            # LNAV active, but route manager is disabled now => switch to HDG HOLD (current heading)
            me.input(0, 2);
        } else if (me.FMC_active.getValue()) {
            me._calculateTopOfDescent();
            # Route manager is active, update waypoint type
            var f = flightplan();
            var current_wp = me.FMC_current_wp.getValue();
            if (current_wp < f.getPlanSize()) {
                var wp = f.getWP(current_wp);
                if (wp != nil) {
                    me.waypoint_type = wp.wp_type;
                    me.getNextRestriction(current_wp);
                }
            }
        }
    },


    getNextRestriction: func(curWp) {
        me.console("getNextRestriction: curWp : "~curWp~"\n");
        var f= flightplan();
        var legWP = f.getWP(curWp);
        var destinationRunwayIdx = f.indexOfWP(f.destination_runway);
        while((legWP.alt_cstr_type == nil or legWP.alt_cstr_type == "delete" ) and (curWp < destinationRunwayIdx)) {
            curWp += 1;
            legWP = f.getWP(curWp);
        }
        if (legWP.alt_cstr_type != nil and legWP.alt_cstr_type != "delete") {
                me.altitude_restriction_idx.setValue(curWp);
                me.altitude_restriction_type.setValue(legWP.alt_cstr_type);
                var restriction = int((legWP.alt_cstr + 50) / 100 ) * 100;
                me.altitude_restriction.setValue(restriction);
                if ((getprop("autopilot/route-manager/total-distance")
                    - getprop("autopilot/route-manager/route/wp["~curWp~"]/distance-along-route-nm")) < me.top_of_descent.getValue()) {
                    me.altitude_restriction_descent.setValue(1);
                } else {
                    me.altitude_restriction_descent.setValue(0);
            }
        }
    },

    # former VCal
    _calculateCalibratedAirspeed: func(M) {
        # The original Author did not provide any documentation for this
        # I *think* this is the calculation of the calibrated airspeed
        # based on the Mach number - Sidi Liang, 20240721

        # The original code is as follows:
        # var p = getprop("environment/pressure-inhg") * 3386.388640341;
        # var pt = p * math.pow(1 + 0.2 * M * M, 3.5);
        # var Vc =  math.sqrt((math.pow((pt - p) / 101325 + 1, 0.285714286) - 1) * 7 * 101325 / 1.225) / 0.5144;
        # return (Vc);

        # Constants
        var SOME_VELOCITY_FACTOR = 579000;    # m²/s², 7 * 101325 / 1.225, I'm not sure about it's physical meaning

        # Get current static pressure and convert to Pa
        var p = getprop("environment/pressure-inhg") * INHG_TO_PA;

        # Calculate total pressure
        var pt = p * math.pow(1 + 0.2 * M * M, 3.5);

        # Calculate pressure ratio
        var pressure_ratio = (pt - p) / SEA_LEVEL_PRESSURE_PA + 1;

        # Calculate calibrated airspeed
        var Vc = math.sqrt((math.pow(pressure_ratio, AIR_GAMMA_EXP) - 1) * SOME_VELOCITY_FACTOR) * MS_TO_KNOTS;

        return Vc;
    },

    _getSchedClimbMach: func() {
        # Get scheduled climb Mach from FMC 
        # with fallback for IAS/MACH crossover
        var m = me.FMC_cruise_mach.getValue();
        if (m < 0.30 or m > 0.95) m = CLIMB_CROSSOVER_MACH; # fallback
        return m;
    },
    _getSchedDescentIAS: func() {
        # Get scheduled descent IAS from FMC
        # with fallback for IAS/MACH crossover
        var v = me.FMC_descent_ias.getValue();
        if (v < 100 or v > 399) v = DESCENT_CROSSOVER_IAS;  # fallback
        return v;
    },

    # Calculate IAS/Mach crossover altitude and handle switching
    _shouldSwitchToMach: func(currentMach, planMach) {
        # Revised per manual: in FLCH, crossover at .84 mach
        return (currentMach >= (planMach - SWITCH_HYSTERESIS_MACH));
    },

    _shouldSwitchToIAS: func(currentIAS, planIAS) {
        # Revised per manual: in FLCH, crossover at 310 KIAS
        # In descent IAS rises
        return (currentIAS >= (planIAS + SWITCH_HYSTERESIS_IAS));
    },

    # Automatic IAS/Mach switching 
    _autoIASMachSwitch: func(current_alt, currentIAS) {
        var curM = me.indicated_mach_node.getValue();
        var isClimb = (current_alt < me.target_alt.getValue() - 10); # leave 10 ft room to avoid false triggers
        var isDesc = (current_alt > me.target_alt.getValue() + 10);
        # --- FLCH (manual): fixed crossover 310/.84 ---
        if (me._isVerticalMode("FLCH") or me._isVerticalMode("VS")) {
            if (isClimb and (me.ias_mach_selected.getValue() == 0)) {
                if (me._shouldSwitchToMach(curM, CLIMB_CROSSOVER_MACH)) {
                    me.ias_mach_selected.setValue(1);
                    # keep target close to current, but prefer FMC cruise Mach if reasonable
                    var planM = me.FMC_cruise_mach.getValue();
                    me.mach_setting.setValue((planM > 0.3 and abs(planM - curM) < 0.05) ? planM : curM);
                }
            } elsif (isDesc and (me.ias_mach_selected.getValue() == 1)) {
                if (me._shouldSwitchToIAS(currentIAS, DESCENT_CROSSOVER_IAS)) {
                    me.ias_mach_selected.setValue(0);
                    me.ias_setting.setValue(DESCENT_CROSSOVER_IAS);
                }
            }
            return;
        }

        # --- VNAV (managed): dynamic changeover against scheduled VNAV speeds ---
        if (!me._isVNAV()) return;

        if (isClimb and (me.ias_mach_selected.getValue() == 0)) {
            var planM = me._getSchedClimbMach();
            if (me._shouldSwitchToMach(curM, planM)) {
                me.ias_mach_selected.setValue(1);
                me.mach_setting.setValue(planM); # use scheduled Mach
            }
        } elsif (isDesc and (me.ias_mach_selected.getValue() == 1)) {
            var planIAS = me._getSchedDescentIAS();
            if (me._shouldSwitchToIAS(currentIAS, planIAS)) {
                me.ias_mach_selected.setValue(0);
                me.ias_setting.setValue(planIAS); # use scheduled IAS
            }
        }
    },

    # Calculate and set radio directions for ND
    _calculateRadioDirections: func(vheading, crabAngleHdg) {
        # Get nav and ADF bearings
        var nav0 = getprop("instrumentation/nav/heading-deg");
        var nav1 = getprop("instrumentation/nav[1]/heading-deg");
        var adf0 = getprop("instrumentation/adf/indicated-bearing-deg");
        var adf1 = getprop("instrumentation/adf[1]/indicated-bearing-deg");

        # Set VOR directions
        setprop("instrumentation/efis/mfd/lvordirection", nav0 - vheading - me.vorient);
        setprop("instrumentation/efis/mfd/rvordirection", nav1 - vheading - me.vorient);

        # Set ADF directions
        setprop("instrumentation/efis/mfd/ladfdirection", adf0 + crabAngleHdg);
        setprop("instrumentation/efis/mfd/radfdirection", adf1 + crabAngleHdg);

        # Calculate wind direction and bearing
        var windFromHeadingDeg = getprop("environment/wind-from-heading-deg");
        var windDirection = windFromHeadingDeg - vheading - me.vorient;
        setprop("instrumentation/efis/mfd/winddirection", windDirection);

        var windBearing = windFromHeadingDeg - me.vorient;
        windBearing = int(windBearing + 0.5);
        if (windBearing < 0.5) windBearing += 360;
        setprop("instrumentation/efis/mfd/windbearing", windBearing);
    },

    # Update basic display values
    _updateBasicDisplays: func(VS, indicated_speed, current_alt, TAS) {
        me.indicated_vs_fpm.setValue(int((abs(VS) * 60 + 50) / 100) * 100);
        if (indicated_speed < MIN_INDICATOR_SPEED) {
            me.indicator_speed_node.setValue(MIN_INDICATOR_SPEED);
        } else {
            me.indicator_speed_node.setValue(indicated_speed);
        }

        # This value is used for displaying negative altitude
        if (current_alt < 0) {
            me.indicator_alt_node.setValue(abs(current_alt) + 90000);
        } else {
            me.indicator_alt_node.setValue(current_alt);
        }

        # This code was here in the original code, but the variable TAS and VS were not used anywhere else,
        # thus commenting it out.
        # if (TAS < 10) TAS = 10;
        # if (VS < -200) VS = -200;
    },

    # Update autopilot annunciator message
    _updateAutopilotAnnunciator: func() {
        var msg = " ";
        if (me.FD.getValue()) msg = "FLT DIR";

        if (me.AP.getValue()) {
            msg = "A/P";
            if (me.rollout_armed.getValue()) {
                msg = "LAND 3";
            }
        }
        if (msg == " ") {
            me.ap_trans_node.setValue(0);
        } elsif (me.AP_annun.getValue() != msg) {
            me.ap_trans_node.setValue(1);
            me.ap_trans_timer.start();
        }
        me.AP_annun.setValue(msg);
    },

    # Update MCP display values for VS and FPA
    _updateMCPDisplay: func() {
        var tmp = abs(me.vs_setting.getValue());
        me.vs_display.setValue(tmp);
        tmp = abs(me.fpa_setting.getValue());
        me.fpa_display.setValue(tmp);
    },

    # Update heading bug position
    _updateHeadingBug: func() {
        var hdgoffset = me.hdg_setting.getValue() - me.reference_deg.getValue();
        if (hdgoffset < -180) hdgoffset += 360;
        if (hdgoffset > 180) hdgoffset -= 360;
        setprop("autopilot/internal/heading-bug-error-deg", hdgoffset);
    },

    # Update localizer pointer deflection
    _updateLocalizerPointer: func() {
        var deflection = getprop("instrumentation/nav/heading-needle-deflection-norm");
        if ((abs(deflection) < 0.5233) and (getprop("instrumentation/nav/signal-quality-norm") > 0.99)) {
            setprop("autopilot/internal/presision-loc", 1);
            setprop("instrumentation/nav/heading-needle-deflection-ptr", (deflection * 1.728));
        } else {
            setprop("autopilot/internal/presision-loc", 0);
            setprop("instrumentation/nav/heading-needle-deflection-ptr", deflection);
        }
    },

    # Step 0: Check glideslope armed status
    _updateStepGlideslopeArmed: func() {
        var gear_agl_ft = me.gear_agl_ft_node.getValue();
        if (gear_agl_ft > 500) {
            gear_agl_ft = int(gear_agl_ft / 20) * 20;
        } elsif (gear_agl_ft > 100) {
            gear_agl_ft = int(gear_agl_ft / 10) * 10;
        }
        me.radio_alt_ind.setValue(gear_agl_ft);
        
        var msg = "";
        if (me.gs_armed.getValue()) {
            msg = "G/S";
            if (me.lateral_mode.getValue() == 4) { # LOC already captured
                var vradials = getprop("instrumentation/nav[0]/radials/target-radial-deg") - getprop("orientation/heading-deg");
                if (vradials < -180) vradials += 360;
                elsif (vradials >= 180) vradials -= 360;
                
                if (abs(vradials) < 80) {
                    var gsdefl = getprop("instrumentation/nav/gs-needle-deflection-deg");
                    var gsrange = getprop("instrumentation/nav/gs-in-range");
                    if ((gsdefl < 0.1 and gsdefl > -0.1) and gsrange) {
                        me.vertical_mode.setValue(6);
                        me.gs_armed.setValue(0);
                    }
                }
            }
        } elsif (me.flare_armed.getValue()) {
            msg = "FLARE";
        } elsif (me.vnav_armed.getValue()) {
            msg = "VNAV";
        }
        me.AP_pitch_arm.setValue(msg);
    },

    # Step 1: Check localizer armed status
    _updateStepLocalizerArmed: func() {
        var msg = "";
        if (me.loc_armed.getValue()) {
            msg = "LOC";
            if (getprop("instrumentation/nav/in-range")) {
                if (getprop("instrumentation/nav/nav-loc")) {
                    var vradials = getprop("instrumentation/nav[0]/radials/target-radial-deg") - getprop("orientation/heading-deg");
                    if (vradials < -180) vradials += 360;
                    elsif (vradials >= 180) vradials -= 360;
                    
                    if (abs(vradials) < 120) {
                        var hddefl = getprop("instrumentation/nav/heading-needle-deflection");
                        if (abs(hddefl) < 9.5 and abs(getprop("instrumentation/nav/signal-quality-norm")) >= 0.99) {
                            me.lateral_mode.setValue(4);
                            me.loc_armed.setValue(0);
                            vradials = getprop("instrumentation/nav[0]/radials/target-radial-deg") - me.vorient + 0.5;
                            if (vradials < 0.5) vradials += 360;
                            elsif (vradials >= 360.5) vradials -= 360;
                            me.hdg_setting.setValue(vradials);
                            setprop("instrumentation/nav/radials/selected-deg", vradials);
                        } else {
                            setprop("autopilot/internal/presision-loc", 0);
                        }
                    }
                }
            } else {
                setprop("autopilot/internal/presision-loc", 0);
            }
        } elsif (me.lnav_armed.getValue()) {
            if (me.gear_agl_ft_node.getValue() > 50) {
                msg = "";
                me.lnav_armed.setValue(0);      # Clear
                me.lateral_mode.setValue(3);    # LNAV
            } else {
                msg = "LNAV";
            }
        } elsif (me.rollout_armed.getValue()) {
            msg = "ROLLOUT";
        }
        me.AP_roll_arm.setValue(msg);
    },

    _updateInterventionAltitude: func() {
        var FMC_distance_remaining = me.FMC_distance_remaining.getValue();
        var cruise_alt = me.FMC_cruise_alt.getValue();
        if ((me.alt_setting.getValue() > 24000)
                    and (me.alt_setting.getValue() >= cruise_alt)) {
            if ((FMC_distance_remaining < (me.top_of_descent.getValue() + 10)) and (me.vnav_mcp_reset.getValue() != 1)) {
                me.vnav_mcp_reset.setValue(1);
                copilot("RESET MCP ALT");
                setCDUScratchpad("RESET MCP ALT");
            }
        } else {
            me.vnav_mcp_reset.setValue(0);
            if (FMC_distance_remaining < me.top_of_descent.getValue()) {
                me.vnav_descent.setValue(1);
                me.intervention_alt.setValue(me.alt_setting.getValue());
            }
        }

    },

    _clearCurrentRestictionOnClimb: func() {
        # we are climbing ?
        if (me.isClimbing()) {
            # current retriction is below the mcp altitude 
            if(me.altitude_restriction.getValue() < me.alt_setting.getValue() ) {
                var f = flightplan();
                me.console("restriction to be clared "~me.altitude_restriction_idx.getValue());
                var wp = f.getWP(me.altitude_restriction_idx.getValue());
                wp.setAltitude(0,"delete");
                me.console("restriction deleted for wp : "~wp.index~" "~wp.alt_cstr_type~" "~wp.alt_cstr);
                       }   
        }
    },

    clearRestictionOnClimb: func(currentAltitude, mcpAltitude) {
        var f = flightplan();
        var destinationRunwayIdx = f.indexOfWP(f.destination_runway);
        var tod = me.top_of_descent.getValue();
        var foundIdx = -999;
        var total_distance = getprop("autopilot/route-manager/total-distance");
        var tod_distance_along_route = total_distance - tod;

        me.console("clearRestictionOnClimb: currentAltitude : "~currentAltitude~" mcpAltitude : "~mcpAltitude~" tod : "~tod~"\n");
        for (var wptIdx = 1; wptIdx < destinationRunwayIdx; wptIdx = wptIdx + 1) {
            var wp = f.getWP(wptIdx);
            if ( wp.alt_cstr_type == 'below' or wp.alt_cstr_type == 'at') {
                me.console("Checking wp "~wptIdx~" alt_cstr_type: "~wp.alt_cstr_type~" alt_cstr: "~wp.alt_cstr~" distance_along_route: "~wp.distance_along_route~"\n");
                if (wp.alt_cstr > currentAltitude-100 and wp.alt_cstr < mcpAltitude and wp.distance_along_route < tod_distance_along_route) {
				    foundIdx = wptIdx;
				    break;
                }
			}
		}
        if (foundIdx != -999) {
            me.console("Clearing wp restriction: "~wp.alt_cstr_type~" "~wp.distance_along_route~"\n");
            wp.setAltitude(0,"delete");
        }
        return foundIdx;

    },

    _getNextAltitudeRestrictionOnClimb: func(lastRestIdx) {
        me._clearCurrentRestictionOnClimb();
        var f = flightplan();
        if (f.getPlanSize() == 0) {
            return nil;
        }
        var destinationRunwayIdx = f.indexOfWP(f.destination_runway);
        var curWp = lastRestIdx + 1;
        var wp = f.getWP(curWp);
        while(( (wp.alt_cstr_type != 'below') and (wp.alt_cstr_type != 'at')) and curWp+1 < destinationRunwayIdx) {
             curWp += 1;
             wp = f.getWP(curWp);
        }
        return wp.alt_cstr_type ? wp : nil;
    },

    _getFirstAltitudeRestrictionOnDescent: func(total_distance) {
        var END_OF_DISTANCE_THRESHOLD = 200;
        var f = flightplan();
        if (f.getPlanSize() == 0) {
            return nil;
        }
        # Avoid calculating top of climb by starting search from a distance threshold
        var start_to_look_at_distance = (total_distance / 2 < END_OF_DISTANCE_THRESHOLD) ? total_distance / 2 : total_distance - END_OF_DISTANCE_THRESHOLD;
        var destinationRunwayIdx = f.indexOfWP(f.destination_runway);
        for (var curWp = 1; curWp < destinationRunwayIdx; curWp += 1) {
            var wp = f.getWP(curWp);
            if ((wp.alt_cstr_type == 'below' or wp.alt_cstr_type == 'at') and wp.distance_along_route >= start_to_look_at_distance) {
                return wp;
            }
        }
        return nil;
    },

    _calculateTopOfDescent: func() {   
        var destination_elevation = getprop("autopilot/route-manager/destination/field-elevation-ft");
        var total_distance = getprop("autopilot/route-manager/total-distance");
        var cruise_alt = me.FMC_cruise_alt.getValue();
        var restricted_wp = me._getFirstAltitudeRestrictionOnDescent(total_distance);

        var tod_constant = 3.3;
        if (cruise_alt < 35000) tod_constant = 3.2;
        if (cruise_alt < 25000) tod_constant = 3.1;
        if (cruise_alt < 15000) tod_constant = 3.0;

        if (restricted_wp != nil) {
            var tod = ((cruise_alt - restricted_wp.alt_cstr) / 1000 * tod_constant) + (total_distance - restricted_wp.distance_along_route);
            me.top_of_descent.setValue(tod);
        } else {
            me.top_of_descent.setValue(((cruise_alt - destination_elevation) / 1000 * tod_constant));
        }


    },

    # Step 5: Update LNAV and VNAV calculations
    _updateStepLNAVVNAV: func(current_alt) {
        var f = flightplan();
        var total_distance = getprop("autopilot/route-manager/total-distance");
        var FMC_distance_remaining = me.FMC_distance_remaining.getValue();
        var distance = total_distance - FMC_distance_remaining;
        var destination_elevation = getprop("autopilot/route-manager/destination/field-elevation-ft");

        if (me.FMC_active.getValue()) {
            if (me.FMC_last_distance.getValue() == nil) {
                me.FMC_last_distance.setValue(total_distance);
            }
            if (me._isVNAV()) {
                if (me.vnav_descent.getValue() == 0) {   
                    me._calculateTopOfDescent();
                    me._updateInterventionAltitude();
                }
            }
            var max_wpt = (getprop("autopilot/route-manager/route/num") - 1);

            # LNAV calculations
            var leg = f.currentWP();
            var current_wp = me.FMC_current_wp.getValue();
            
            if (leg == nil) {
                me.step += 1;
                if (me.step > 6) me.step = 0;
                return;
            }
            
            # Update waypoint type when needed
            if (current_wp < f.getPlanSize()) {
                var wp = f.getWP(current_wp);
                if (wp != nil) {
                    me.waypoint_type = wp.wp_type;
                }
            }
            var groundspeed = me.current_gs_node.getValue();
            var log_distance = getprop("instrumentation/gps/wp/wp[1]/distance-nm");
            var along_route = total_distance - me.FMC_distance_remaining.getValue();

            var geocoord = geo.aircraft_position();
            var referenceCourse = f.pathGeod(f.indexOfWP(f.destination_runway), -me.FMC_distance_remaining.getValue());
            var courseCoord = geo.Coord.new().set_latlon(referenceCourse.lat, referenceCourse.lon);

            var final_track_error = (geocoord.distance_to(courseCoord) / 1852) + 1;

            var change_wp = abs(getprop("autopilot/route-manager/wp/bearing-deg") - me.heading.getValue());
            if (change_wp > 180) change_wp = (360 - change_wp);
            final_track_error += (change_wp / 20);
            var targetCourse = f.pathGeod(f.indexOfWP(f.destination_runway), (-me.FMC_distance_remaining.getValue() + final_track_error));
            courseCoord = geo.Coord.new().set_latlon(targetCourse.lat, targetCourse.lon);
            final_track_error = (geocoord.course_to(courseCoord) - getprop("orientation/heading-deg"));
            if (final_track_error < -180) final_track_error += 360;
            elsif (final_track_error > 180) final_track_error -= 360;
            setprop("autopilot/internal/course-error-deg", final_track_error);

            # var topClimb = f.pathGeod(0, 100);
            var topDescent = f.pathGeod(f.indexOfWP(f.destination_runway), -me.top_of_descent.getValue());

            # var tcNode = me.ND_symbols.getNode("tc", 1);
            # tcNode.getNode("longitude-deg", 1).setValue(topClimb.lon);
            # tcNode.getNode("latitude-deg", 1).setValue(topClimb.lat);

            var tdNode = me.ND_symbols.getNode("td", 1);
            tdNode.getNode("longitude-deg", 1).setValue(topDescent.lon);
            tdNode.getNode("latitude-deg", 1).setValue(topDescent.lat);

            if(log_distance != nil and groundspeed > 50 ) {
                me.handleNextWPoint(log_distance, current_wp, total_distance, current_alt);
            }

            # Auto-tune ILS frequency
            if ((me.FMC_destination_ils.getValue() == 0) and 
                (me.lateral_mode.getValue() == 3)) { # When ILS not autotuned and LNAV engaged
                if ((FMC_distance_remaining < 150)
                    or (FMC_distance_remaining < (me.top_of_descent.getValue() + 50))
                    or (me.vnav_descent.getValue() == 1)) {
                    var dist_run = f.destination_runway;
                    if (dist_run != nil) {
                        var freq = dist_run.ils_frequency_mhz;
                        if (freq != nil) {
                            setprop("instrumentation/nav/frequencies/selected-mhz", freq);
                            me.FMC_destination_ils.setValue(1);
                        }
                    }
                }
            }
            if ((distance > 400) or (distance > (total_distance / 2))) {
                me.FMC_landing_rwy_elevation.setValue(destination_elevation);
            } else {
                me.FMC_landing_rwy_elevation.setValue(getprop("autopilot/route-manager/departure/field-elevation-ft"));
            }
        } else {
            if ((distance == nil) or (total_distance == nil)) {
                # Reset flag when not active
                if (me.FMC_destination_ils.getValue() == 1) me.FMC_destination_ils.setValue(0);
                me.FMC_landing_rwy_elevation.setValue(getprop("position/ground-elev-ft"));
            } else {
                if ((distance > 400) or (distance > (total_distance / 2))) {
                    me.FMC_landing_rwy_elevation.setValue(destination_elevation);
                } elsif (total_distance == 0) {
                    # Reset flag when not active
                    if (me.FMC_destination_ils.getValue() == 1) me.FMC_destination_ils.setValue(0);
                    me.FMC_landing_rwy_elevation.setValue(getprop("position/ground-elev-ft"));
                } else {
                    if (me.FMC_destination_ils.getValue() == 1) me.FMC_destination_ils.setValue(0);
                    me.FMC_landing_rwy_elevation.setValue(getprop("autopilot/route-manager/departure/field-elevation-ft"));
                }
                me.FMC_last_distance.setValue(total_distance);
            }
        }
    },

    handleNextWPoint : func(log_distance, current_wp, total_distance, current_alt) {

 
        var f = flightplan();
        var groundspeed = me.current_gs_node.getValue();
        var max_wpt = (getprop("autopilot/route-manager/route/num") - 1);
        var wpt_eta = (log_distance / groundspeed * 3600);
        var gmt = getprop("instrumentation/clock/indicated-sec");


        gmt += (wpt_eta + 30);
        var gmt_hour = int(gmt / 3600);
        if (gmt_hour > 24) {
            gmt_hour -= 24;
            gmt -= 86400; # 24 * 3600
        }
        me.estimated_time_arrival.setValue(gmt_hour * 100 + int((gmt - gmt_hour * 3600) / 60));
        if (current_wp < (max_wpt - 2)) {
            if (getprop("autopilot/route-manager/route/wp["~(current_wp + 1)~"]/leg-bearing-true-deg") == nil) {
                setprop("autopilot/route-manager/route/wp["~(current_wp + 1)~"]/leg-bearing-true-deg", getprop("instrumentation/gps/wp/wp[1]/bearing-deg"));
            }
            if (getprop("autopilot/route-manager/route/wp["~(current_wp + 1)~"]/leg-distance-nm") > 1.0) {
                var change_wp = abs(getprop("autopilot/route-manager/route/wp["~(current_wp + 1)~"]/leg-bearing-true-deg")
                                 - getprop("orientation/heading-deg"));
            } else {
                var change_wp = abs(getprop("autopilot/route-manager/route/wp["~(current_wp + 2)~"]/leg-bearing-true-deg")
                    - getprop("orientation/heading-deg"));
            }
        } else {
            change_wp = 0;
        }

        var alignment = abs(getprop("autopilot/route-manager/wp/true-bearing-deg")
                        - getprop("orientation/heading-deg"));
        if (alignment > 180) alignment = (360 - alignment);
        if (change_wp > 180) change_wp = (360 - change_wp);

        var timeToNextTurn = me.heading_change_rate * change_wp;

        var enoughTimeToTurn = (timeToNextTurn/2 > wpt_eta);
        var headingToWp = (alignment < 85);
        var wpIsBehind = (alignment > 95) and (change_wp < 85);
        var closedToWp = (log_distance < 0.6);
    
        var should_advance = (
                (me.waypoint_type != 'hdgToAlt') and
                (
                    ((f.currentWP().fly_type == 'flyBy') and enoughTimeToTurn and headingToWp) 
                    or closedToWp
                    or wpIsBehind
                )
            ) or (
                (me.waypoint_type == 'hdgToAlt') and (current_alt > me.altitude_restriction.getValue())
            );


        if ( should_advance and (current_wp < max_wpt)) {
            current_wp += 1;
            me.FMC_current_wp.setValue(current_wp);
            me.waypoint_type = f.getWP(current_wp).wp_type;
            me.getNextRestriction(current_wp);
            me.FMC_last_distance.setValue(total_distance);
        } else {
            me.FMC_last_distance.setValue(log_distance);
        }
    },

    # Calculate optimal altitude based on weight
    _calculateOptimalAltitude: func() {
        var payload_ratio = (
            getprop("consumables/fuel/total-fuel-lbs") + 
            getprop("sim/weight[0]/weight-lb") + 
            getprop("sim/weight[1]/weight-lb")) / 
            getprop("sim/max-payload");
        
        if (payload_ratio > 0.95) return 29000;
        elsif (payload_ratio > 0.89) return 30000;
        elsif (payload_ratio > 0.83) return 31000;
        elsif (payload_ratio > 0.74) return 32000;
        elsif (payload_ratio > 0.65) return 33000;
        elsif (payload_ratio > 0.59) return 34000;
        elsif (payload_ratio > 0.53) return 35000;
        elsif (payload_ratio > 0.47) return 36000;
        elsif (payload_ratio > 0.41) return 37000;
        elsif (payload_ratio > 0.35) return 38000;
        elsif (payload_ratio > 0.23) return 40000;
        elsif (payload_ratio > 0.16) return 41000;
        else return 43000;
    },

    # Update AFDS
    ap_update: func() {
        var current_alt = me.current_alt_node.getValue();
        var VS = me.current_vs_node.getValue();
        var TAS = me.current_tas_node.getValue() * KT2FPS; # keeping TAS as fps
        var airspeed = me.current_airspeed_node.getValue(); # indicated airspeed in knots

        # Update displays and MCP
        me._updateBasicDisplays(VS, airspeed, current_alt, TAS);
        me._updateAutopilotAnnunciator();
        me._updateMCPDisplay();

        # Update heading reference and bug
        me.referenceChange();
        me._updateHeadingBug();
        
        # Update localizer pointer
        me._updateLocalizerPointer();

        # Execute step-based updates
        if (me.step == 0) {
            me._updateStepGlideslopeArmed();
        } elsif (me.step == 1) {
            me._updateStepLocalizerArmed();
        } elsif (me.step == 2) { # check lateral modes 
            var gear_agl_ft = me.gear_agl_ft_node.getValue();
            # Heading bug line enable control
            var vsethdg = me.hdg_setting.getValue();
            if (me.hdg_setting_last.getValue() != vsethdg) {
                me.hdg_setting_last.setValue(vsethdg);
                me.hdg_setting_active.setValue(1);
            } else {
                if (me.mfd_display_mode.getValue() == "MAP") {
                    if (me.lateral_mode.getValue() == 3
                        or me.lateral_mode.getValue() == 4
                        or me.lateral_mode.getValue() == 5) {
                        if (me.hdg_setting_active.getValue() == 1
                            and me.hdg_setting_last.getValue() == vsethdg
                            and !me.hdg_setting_timer.isRunning) {
                            me.hdg_setting_timer.start();
                        }
                    } else {
                        me.hdg_setting_active.setValue(1);
                    }
                }
            }
            var idx = me.lateral_mode.getValue();
            if (gear_agl_ft > 50) {
                if ((idx == 1) or (idx == 2)) {
                    # switch between HDG SEL and HDG HOLD
                    if (abs(me.reference_deg.getValue() - me.hdg_setting.getValue()) < 2) {
                        idx = 2; # HDG HOLD
                    } else {
                        idx = 1; # HDG SEL
                    }
                }
                if ((idx == 6) or (idx == 7)) {
                    # switch between TRK SEL and TRK HOLD
                    if (abs(me.reference_deg.getValue() - me.hdg_setting.getValue()) < 2) {
                        idx = 7; # TRK HOLD
                    } else {
                        idx = 6; # TRK SEL
                    }
                }
            }
            if (idx == 4) { # LOC
                if ((me.rollout_armed.getValue())
                    and (gear_agl_ft < 30)) {
                    me.rollout_armed.setValue(0);
                    idx = 5; # ROLLOUT
                }
                me.crab_angle.setValue(me.heading.getValue() - getprop("instrumentation/nav[0]/radials/target-radial-deg") + me.vorient);
                me.crab_angle_total.setValue(abs(me.crab_angle.getValue() + getprop("orientation/side-slip-deg")));
                if (me.crab_angle.getValue() > 0) {
                    me.rwy_align_limit.setValue(5.0);
                } else {
                    me.rwy_align_limit.setValue(-5.0);
                }
            } elsif (idx == 5) { # ROLLOUT
                if (me.current_gs_node.getValue() < 50) {
                    setprop("controls/flight/aileron", 0);  # Aileron set neutral
                    setprop("controls/flight/rudder", 0);   # Rudder set neutral
                    me.FMC_destination_ils.setValue(0);     # Clear destination ILS set
                    if (!me.FD.getValue()) {
                        idx = 0;    # NO MODE
                    } else {
                        idx = 1;    # HDG SEL
                    }
                }
            } elsif (idx == 8) {    # ATT
                var current_bank = getprop("orientation/roll-deg");
                if (current_bank > 30) {
                    setprop("autopilot/internal/target-roll-deg", 30);
                } elsif (current_bank < -30) {
                    setprop("autopilot/internal/target-roll-deg", -30);
                } elsif ((abs(current_bank) > 5) and (abs(current_bank) <= 30)) {
                    setprop("autopilot/internal/target-roll-deg", current_bank);
                } elsif (abs(current_bank) <= 5) {
                    setprop("autopilot/internal/target-roll-deg", 0);
                }
                if (abs(current_bank) <= 3) {
                    var tgtHdg = int(me.reference_deg.getValue());
                    me.hdg_setting.setValue(tgtHdg);
                    if (me.hdg_trk_selected.getValue()) {
                        idx = 7;    # TRK HOLD
                    } else {
                        idx = 2;    #  HDG HOLD
                    }
                }
            }
            me.lateral_mode.setValue(idx);
            if ((me.AP_roll_mode.getValue() != me.roll_list[idx])
                    and (idx > 0)) {
                me.roll_trans_node.setValue(1);
                me.roll_trans_timer.start();
            }
            me.AP_roll_mode.setValue(me.roll_list[idx]);
            me.AP_roll_engaged.setBoolValue(idx > 0);

        } elsif (me.step == 3) { # check vertical modes 
            # This is only for Canvas ND pridiction circle indication, not used inside
            # Comment added 20240721 by Sidi Liang: What does 'This' refer to? The property?
            setprop("autopilot/settings/target-altitude-ft", me.target_alt.getValue());
            var gear_agl_ft = me.gear_agl_ft_node.getValue();
            me.alt_setting_FL.setValue(me.alt_setting.getValue() / 1000);
            me.alt_setting_100.setValue(me.alt_setting.getValue() - (me.alt_setting_FL.getValue() * 1000));
            if (airspeed < 100) {
                me.airport_height.setValue(current_alt);
            }
            ### altitude alert ###
            var alt_deviation = abs(me.alt_setting.getValue() - current_alt);
            if ((alt_deviation > 900)
                    or (me.vertical_mode.getValue() == 6)           # G/S mode
                    or (getprop("gear/gear/position-norm") == 1)) { # Gear down and locked
                me.altitude_alert_from_out = 0;
                me.altitude_alert_from_in = 0;
                setprop("autopilot/internal/alt-alert", 0);
            } elsif (alt_deviation > 200) {
                if ((me.altitude_alert_from_out == 0)
                        and (me.altitude_alert_from_in == 0)) {
                    me.altitude_alert_from_out = 1;
                    setprop("autopilot/internal/alt-alert", 1);
                } elsif ((me.altitude_alert_from_out == 1)
                        and (me.altitude_alert_from_in == 1)) {
                    me.altitude_alert_from_out = 0;
                    setprop("autopilot/internal/alt-alert", 2);
                }
            } else {
                me.altitude_alert_from_out = 1;
                me.altitude_alert_from_in = 1;
                setprop("autopilot/internal/alt-alert", 0);
            }

            var idx = me.vertical_mode.getValue();
            var test_fpa = me.vs_fpa_selected.getValue();
			var vsnow = getprop("/autopilot/internal/vert-speed-fpm");
			var offset = math.clamp(math.round(abs(vsnow) / 5, 100), 50, 2500); # Capture limits, gain is tied to the control loop, so DO NOT CHANGE the 5!
            me.optimal_alt.setValue(me._calculateOptimalAltitude());
            me.FMC_max_cruise_alt.setValue(me.optimal_alt.getValue());
            if (idx == 2 and test_fpa) idx = 9;
            if (idx == 9 and !test_fpa) idx = 2;
            if ((idx == 8) or (idx == 1) or (idx == 2) or (idx == 9)) {
                if (idx != 1) { # Follow the setting altitude except for ALT mode
                    var alt = me.alt_setting.getValue();
                    me.target_alt.setValue(alt);
                }
                # flight level change mode
                if (abs(current_alt - me.alt_setting.getValue()) < offset) {
                    # within MCP altitude: switch to ALT HOLD mode
                    idx = 1;    # ALT
                    if (me.autothrottle_mode.getValue() != 0) {
                        me.autothrottle_mode.setValue(5);   # A/T SPD
                    }
                    me.vs_setting.setValue(0);
                }
                me._autoIASMachSwitch(current_alt, airspeed);
            } elsif (idx == verticalMode.VNAV_PTH) { # VNAV PTH
                idx = me._handleVNAV_PTH(idx, current_alt, airspeed);
            } elsif (idx == 4) { # VNAV SPD
                if (me.flap_position.getValue() > 0) { # flaps down
                    me.ias_setting.setValue(getprop("instrumentation/weu/state/target-speed"));
                } elsif ((current_alt < 10000) and !me.manual_intervention.getValue()) {
                    me.ias_setting.setValue(250);
                } else {
                    me._autoIASMachSwitch(current_alt, airspeed);
                    
                    if (me.ias_mach_selected.getValue() == 0) {
                        if ((current_alt < 10000) and !me.manual_intervention.getValue()) {
                            me.ias_setting.setValue(250);
                        } else {
                            me.ias_setting.setValue(me.FMC_cruise_ias.getValue());
                        }
                    }
                }
                me.manageVnavSpeedRestriction(current_alt);
              
                var offset = (abs(me.current_vs_node.getValue() * 60) / 8);
                if (offset < 20) offset = 20;
                if (abs(current_alt - me.target_alt.getValue()) < offset) {
                    if (abs(current_alt - me.FMC_cruise_alt.getValue()) < offset) {
                        # within target altitude: switch to VANV PTH mode
                        idx = 3;
                    } else {
                        idx = 5; # VNAV ALT
                    }
                    if (me.autothrottle_mode.getValue() != 0) {
                        me.autothrottle_mode.setValue(5); # A/T SPD
                    }
                    me.vs_setting.setValue(0);
                }
                
            } elsif (idx == verticalMode.VNAV_ALT) { # VNAV ALT
                if (me.vnav_descent.getValue()) {
                    if (me.intervention_alt.getValue() < (current_alt - 400)) {
                        idx = 3; # VNAV PTH
                        me.descent_step = 0;
                    }
                } elsif (((me.altitude_restriction_type.getValue() == 'below')
                    or (me.altitude_restriction_type.getValue() == 'at'))
                    and (me.altitude_restriction_descent.getValue() == 0)
                    and (me.altitude_restriction.getValue() < me.intervention_alt.getValue())
                    ) {
                    if (current_alt < me.altitude_restriction.getValue() - 400) {
                        me.target_alt.setValue(me.altitude_restriction.getValue());
                        idx = verticalMode.VNAV_SPD; # VNAV SPD
                    }
                } elsif ((me.altitude_restriction_type.getValue() == 'above')
                    and (me.altitude_restriction_descent.getValue() == 1)
                    and me.vnav_descent.getValue()) {
                    if (current_alt > me.altitude_restriction.getValue() + 400) {
                        me.target_alt.setValue(me.altitude_restriction.getValue());
                        idx = verticalMode.VNAV_PTH; # VNAV PTH
                    }
                } elsif ((current_alt < (me.optimal_alt.getValue() - 400))
                    and (current_alt < (me.intervention_alt.getValue() - 400))) {
                    if (me.optimal_alt.getValue() < me.intervention_alt.getValue()) {
                        me.target_alt.setValue(me.optimal_alt.getValue());
                    } else {
                        me.target_alt.setValue(me.intervention_alt.getValue());
                    }
                    idx = verticalMode.VNAV_SPD; # VNAV SPD
                }
            } elsif (idx == 6) { # G/S
                var f_angle = getprop("autopilot/constant/flare-base") * 135 / airspeed;
                me.flare_constant_setting.setValue(f_angle);
                if (gear_agl_ft < 50 and me.flare_armed.getValue()) {
                    me.flare_armed.setValue(0);
                    idx = 7; # FLARE
                } elsif (me.AP.getValue() and (gear_agl_ft < 1500) and !me.hydr_PressSysL.getValue()) {
                    me.rollout_armed.setValue(1); # ROLLOUT
                    me.flare_armed.setValue(1); # FLARE
                    setprop("autopilot/settings/flare-speed-fps", 5);
                }
            } else {
                if (me.autothrottle_mode.getValue() == 5) { # SPD
                    if (gear_agl_ft < 50) {
                        me.autothrottle_mode.setValue(4); # A/T IDLE
                    }
                    if (me.current_gs_node.getValue() < 30) {
                        if (!me.FD.getValue()) idx = 0; # NO MODE
                        else idx = 1; # ALT
                    }
                }
            }
            if ((current_alt - getprop("autopilot/internal/airport-height")) > 400) {
                # Take off mode and above baro 400 ft
                if (me.vnav_armed.getValue()) {
                    if (me.target_alt.getValue() == int(current_alt)) {
                        if (me.FMC_cruise_alt.getValue() == int(current_alt)) {
                            idx = 3; # VNAV PTH
                        } else {
                            idx = 5; # VNAV ALT
                        }
                    } else {
                        idx = 4; # VNAV SPD
                    }
                    me.intervention_alt.setValue(me.alt_setting.getValue());
                    if (me.intervention_alt.getValue() > me.FMC_cruise_alt.getValue()) {
                        me.target_alt.setValue(me.FMC_cruise_alt.getValue());
                    } else {
                        me.target_alt.setValue(me.intervention_alt.getValue());
                    }
                    me.vnav_armed.setValue(0);
                }
            }
            me.vertical_mode.setValue(idx);
            if ((me.AP_pitch_mode.getValue() != me.pitch_list[idx]) and (idx > 0)) {
                me.pitch_trans_node.setValue(1);
                me.pitch_trans_timer.start();
            }
            me.AP_pitch_mode.setValue(me.pitch_list[idx]);
            me.AP_pitch_engaged.setBoolValue(idx>0);

        } elsif (me.step == 4) { # Auto Throttle mode control
            var flap_position = me.flap_position.getValue();
            # Thrust reference rate calculation. This should be provided by FMC
            var vflight_idle = 0;
            var payload = getprop("consumables/fuel/total-fuel-lbs") + getprop("sim/weight[0]/weight-lb") + getprop("sim/weight[1]/weight-lb");
            var derate = 0.3 - payload * 0.00000083;
            if (current_alt > 12000) {
                if (me.ias_setting.getValue() < 241) {
                    vflight_idle = (getprop("autopilot/constant/descent-profile-low-base")
                        + (getprop("autopilot/constant/descent-profile-low-rate") * payload / 1000));
                } else {
                    vflight_idle = (getprop("autopilot/constant/descent-profile-high-base")
                        + (getprop("autopilot/constant/descent-profile-high-rate") * payload / 1000));
                }
            }
            if (vflight_idle < 0.00) vflight_idle = 0.00;
            me.flight_idle.setValue(vflight_idle);
            # Thurst limit varis on altitude
            var thrust_lmt = 0.96;
            if (current_alt < 25000) {
                if ((me.vertical_mode.getValue() == 8)          # FLCH SPD mode
                    or(me.vertical_mode.getValue() == 4)) {     # VNAV SPD mode
                    if (me.vertical_mode.getValue() == 4) {     # VNAV SPD mode
                        thrust_lmt = derate / 25000 * abs(current_alt) + (0.95 - derate);
                    }
                    if (flap_position == 0) {
                        if (me.ias_mach_selected.getValue()) {
                            thrust_lmt *= (me.mach_setting.getValue() / 0.84);
                        } else {
                            thrust_lmt *= (me.ias_setting.getValue() / 320);
                        }
                    } else {
                        thrust_lmt *= 0.78125;
                    }
                } elsif (me.vertical_mode.getValue() != 2) { # not V/S mode
                    thrust_lmt = derate / 25000 * abs(current_alt) + (0.95 - derate);
                }
            }
            me.thrust_lmt.setValue(thrust_lmt);
            # IAS and MACH number update in back ground
            var temp = 0;
            var indicated_mach = me.indicated_mach_node.getValue();
            if (me.ias_mach_selected.getValue() == 1) {
                me.ias_setting.setValue(me._calculateCalibratedAirspeed(me.mach_setting.getValue()));
            } else {
                temp = (int(indicated_mach * 1000 + 0.5) / 1000);
                me.mach_setting.setValue(temp);
            }

            var throttle_act_0 = me.engine0_throttle_act.getValue();
            var throttle_act_1 = me.engine1_throttle_act.getValue();
            var reverser_act = me.engine_rev_act.getValue();
            var airport_height = me.airport_height.getValue();
            var vertical_mode = me.vertical_mode.getValue();
            var at_mode = me.autothrottle_mode.getValue();
            
            if ((me.at1.getValue() == 0) or (me.at2.getValue() == 0)) { # Auto throttle arm switch is offed
                me.autothrottle_mode.setValue(0);
                me.speed_trans_node.setValue(0);
            } elsif (reverser_act) { # auto-throttle disengaged when reverser is enabled
                me.autothrottle_mode.setValue(0);
                setprop("autopilot/internal/speed-transition", 0);
            } elsif (at_mode == 2) { # THR REF
                if (airspeed > 80 and ((current_alt - airport_height) < 400)) {
                    me.autothrottle_mode.setValue(3); # HOLD
                } elsif ((vertical_mode != 3) and (vertical_mode != 5)) { # not VNAV PTH and not VNAV ALT
                    if ((flap_position == 0) and (vertical_mode != 4)) { # FLAPs up and not VNAV SPD
                        me.autothrottle_mode.setValue(5); # SPD
                    } else {
                        me.engine0_throttle.setValue(thrust_lmt);
                        me.engine1_throttle.setValue(thrust_lmt);
                    }
                }
            } elsif ((at_mode == 4) # Auto throttle mode IDLE
                and ((vertical_mode == 8) or (vertical_mode == 3)) # FLCH SPD mode or VNAV PTH mode
                and (int(me.flight_idle.getValue() * 1000) == int(throttle_act_0 * 1000))
                and (int(me.flight_idle.getValue() * 1000) == int(throttle_act_1 * 1000))) {
                # Both thrust is actual flight idle
                me.autothrottle_mode.setValue(3); # HOLD
            } elsif ((current_alt - airport_height) > 400) {
                # Take off mode or above baro 400 ft
                setprop("autopilot/locks/takeoff-mode", 0);
                if (at_mode == 1) { # THR
                    me.engine0_throttle.setValue(thrust_lmt);
                    me.engine1_throttle.setValue(thrust_lmt);
                } elsif ((vertical_mode == 10) # TO/GA 
                        or ((at_mode == 3)  # HOLD
                        and (vertical_mode != 8) # not FLCH
                        and (vertical_mode != 3) # not VNAV PTH
                        and (vertical_mode != 5))) { # not VNAV ALT
                    if ((flap_position == 0)
                        or (vertical_mode== 6)) { # G/S
                        me.autothrottle_mode.setValue(5); # SPD
                    } else {
                        me.autothrottle_mode.setValue(2); # THR REF
                    }
                } elsif (vertical_mode == 4) { # VNAV SPD
                    me.autothrottle_mode.setValue(2); # THR REF
                } elsif (vertical_mode == 3) { # VNAV PTH
                    if (me.vnav_path_mode.getValue() == 2) {
                        if (at_mode != 3) me.autothrottle_mode.setValue(4); # IDLE
                    } else {
                        me.autothrottle_mode.setValue(5); # SPD
                    }
                } elsif (vertical_mode == 5) { # VNAV ALT
                    me.autothrottle_mode.setValue(5); # SPD
                }
            } elsif ((me.gear_agl_ft_node.getValue() > 100) and (vertical_mode == 6)) { # Approach mode and above 100 ft
                me.autothrottle_mode.setValue(5); # SPD
            }
            idx = me.autothrottle_mode.getValue();
            if ((me.AP_speed_mode.getValue() != me.spd_list[idx])
                    and (idx > 0)) {
                me.speed_trans_node.setValue(1);
                me.speed_trans_timer.start();
            }
            me.AP_speed_mode.setValue(me.spd_list[idx]);
        } elsif (me.step == 5) { # LNAV/VNAV calculation
            me._updateStepLNAVVNAV(current_alt);
        } elsif (me.step == 6) { # TODO: check what is this. Github Copilot says this is ND display
            if (me.flap_position.getValue() == 0) {
                me.auto_popup.setValue(0);
            }
            var ma_spd = getprop("instrumentation/airspeed-indicator/indicated-mach");
            var lim = 0;
            me.pfd_mach_ind.setValue(ma_spd * 1000);
            me.pfd_mach_target.setValue(getprop("autopilot/settings/target-speed-mach") * 1000);
            var true_air_speed = me.current_tas_node.getValue();
            var banklimit = getprop("instrumentation/afds/inputs/bank-limit-switch");
            if (me.bank_switch.getValue() == 0) {
                if (true_air_speed > 420) lim = 15;
                elsif (true_air_speed > 360) lim = 20;
                else lim = 25;

                me.bank_max.setValue(lim);
                me.bank_min.setValue(-1 * lim);
            }
            lim = me.bank_max.getValue();

            if (lim == 25) me.heading_change_rate = 0.67;
            elsif (lim == 20) me.heading_change_rate = 1.1;
            elsif (lim == 15) me.heading_change_rate = 2.0;
            elsif (lim == 10) me.heading_change_rate = 2.53;
            else me.heading_change_rate = 5.2;
           
        }

        me.step += 1;
        if (me.step > 6) me.step = 0;
    },
    _handleVNAV_PTH: func(idx, current_alt, airspeed) {
        if (me.vnav_descent.getValue()) {
            var TargetAlt = me.intervention_alt.getValue();

            if (((me.altitude_restriction_type.getValue() == 'above')
                or (me.altitude_restriction_type.getValue() == 'at'))
                and (me.altitude_restriction.getValue() >  me.intervention_alt.getValue())) {
                TargetAlt = me.altitude_restriction.getValue();
            }
            
            if ((me.altitude_restriction_type.getValue() == 'below')
                and (me.altitude_restriction_descent.getValue() == 1)
                and (me.altitude_restriction.getValue() > me.intervention_alt.getValue())
            ) {
                if (current_alt < me.altitude_restriction.getValue() - 400) {
                    me.getNextRestriction(me.altitude_restriction_idx.getValue() + 1);
                }
            }

            if ((me.target_alt.getValue() != TargetAlt) and (me.descent_step > 1)) {
                me.descent_step = 0;
            }
            if (me.descent_step == 0) {
                if (me.ias_mach_selected.getValue() == 1) {
                    if (me._calculateCalibratedAirspeed(me.FMC_descent_mach.getValue())
                            > (getprop("instrumentation/weu/state/stall-speed") + 5)) {
                        me.mach_setting.setValue(me.FMC_descent_mach.getValue());
                    }
                } else {
                    if ((current_alt > 12000) and !me.manual_intervention.getValue()) {
                        me.ias_setting.setValue(me.FMC_descent_ias.getValue());
                    }
                }
                me.descent_step += 1;
            } elsif (me.descent_step == 1) {
                if (me.ias_mach_selected.getValue() == 1) {
                    if (me.mach_setting.getValue() == me.FMC_descent_mach.getValue()) {
                        if (getprop("instrumentation/airspeed-indicator/indicated-mach")
                            < (me.FMC_descent_mach.getValue() + 0.025)) {
                            me.vnav_path_mode.setValue(1); # VNAV PTH DESCEND VS
                            me.target_alt.setValue(TargetAlt);
                            me.vs_setting.setValue(-2000);
                            me.descent_step += 1;
                        }
                    } else {
                        me.vnav_path_mode.setValue(1); # VNAV PTH DESCEND VS
                        me.target_alt.setValue(TargetAlt);
                        me.vs_setting.setValue(-2000);
                        me.descent_step += 1;
                    }
                } else {
                    if (airspeed < (me.FMC_descent_ias.getValue() + 25)) {
                        me.vnav_path_mode.setValue(1); # VNAV PTH DESCEND VS
                        me.target_alt.setValue(TargetAlt);
                        me.vs_setting.setValue(-2000);
                        me.descent_step += 1;
                    }
                }
            } elsif (me.descent_step == 2) {
                if (me.ias_mach_selected.getValue() == 1) {
                    me._autoIASMachSwitch(current_alt, airspeed);
                    if(me.ias_mach_selected.getValue() == 0) {
                        # we switched to IAS
                        me.descent_step += 1;

                    }
                    elsif ((me.mach_setting.getValue() != me.FMC_descent_mach.getValue())
                            and (me._calculateCalibratedAirspeed(me.FMC_descent_mach.getValue())
                            > (getprop("instrumentation/weu/state/stall-speed") + 5))) {
                                # still mach but need to update
                        me.mach_setting.setValue(me.FMC_descent_mach.getValue());
                    }

                } else {
                    me.descent_step += 1;
                }
            } elsif (me.descent_step == 3) {
                if (current_alt < 29000) {
                    me.vnav_path_mode.setValue(2); # VNAV PTH DESCEND FLCH
                    me.descent_step += 1;
                }
            } elsif (me.descent_step == 4) {
                if ((current_alt < 12000) or (current_alt < (getprop("autopilot/route-manager/destination/field-elevation-ft") + 8000))) {
                    if ((me.ias_setting.getValue() > 240) and !me.manual_intervention.getValue()) {
                        me.ias_setting.setValue(240);
                    }
                    me.descent_step += 1;
                }
            }
            if (abs(current_alt - me.target_alt.getValue()) < 400) {
                if (me.autothrottle_mode.getValue() != 0) {
                    me.autothrottle_mode.setValue(5); # A/T SPD
                }
                me.vs_setting.setValue(0);
                me.vnav_path_mode.setValue(0);
                # if (me.intervention_alt != me.altitude_restriction)
                # {
                #   idx = 5;    # VNAV ALT
                # }
            }
        } else {
            if (me.intervention_alt.getValue() != me.FMC_cruise_alt.getValue()) {
                me.FMC_cruise_alt.setValue(me.intervention_alt.getValue());
                if (me.intervention_alt.getValue() <= me.optimal_alt.getValue()) {
                    me.target_alt.setValue(me.intervention_alt.getValue());
                } else {
                    me.target_alt.setValue(me.optimal_alt.getValue());
                }
                idx = 4;    # VNAV SPD
            }
            me._autoIASMachSwitch(current_alt, airspeed);
            
            if (me.ias_mach_selected.getValue() == 0) {
                if ((current_alt < 10000) and !me.manual_intervention.getValue()) {
                    me.ias_setting.setValue(240);
                } else {  
                    me.ias_setting.setValue(me.FMC_cruise_ias.getValue());
                }
            }
        }
        return idx;
    },

    manageVnavSpeedRestriction: func(current_alt) {
        if ((me.altitude_restriction_type.getValue() == 'above')
                and (current_alt > (me.altitude_restriction.getValue() + 400))
                and (me.altitude_restriction_descent.getValue() == 0)) {
            me.console("manageVnavSpeedRestriction above, get next one");
            me.getNextRestriction(me.altitude_restriction_idx.getValue() + 1);
        }
        if ((me.altitude_restriction_type.getValue() == 'above')
                and (current_alt < (me.altitude_restriction.getValue() + 400))
                and (me.altitude_restriction_descent.getValue() == 1)) {
            me.getNextRestriction(me.altitude_restriction_idx.getValue() + 1);
        }
        if ((me.altitude_restriction_type.getValue() == 'above')
                and (current_alt > (me.altitude_restriction.getValue() + 400))
                and (me.altitude_restriction_descent.getValue() == 0)) {
            me.console("manageVnavSpeedRestriction above, get next one");
            me.getNextRestriction(me.altitude_restriction_idx.getValue() + 1);
        }
        if (((me.altitude_restriction_type.getValue() == 'below')
                or (me.altitude_restriction_type.getValue() == 'at'))
                and (current_alt < (me.altitude_restriction.getValue() + 400))
                and (me.altitude_restriction_descent.getValue() == 0)
                and (me.altitude_restriction.getValue() < me.intervention_alt.getValue())
                ) {
                    me.target_alt.setValue(me.altitude_restriction.getValue());

        } elsif (me.intervention_alt.getValue() >= me.optimal_alt.getValue()) {
            if (me.FMC_cruise_alt.getValue() >= me.optimal_alt.getValue()) {
                me.target_alt.setValue(me.optimal_alt.getValue());
            } else {
                me.target_alt.setValue(me.intervention_alt.getValue());
            }
        } else {
            me.target_alt.setValue(me.intervention_alt.getValue());
        }
    },
};


var afds = AFDS.new();

setlistener("sim/signals/fdm-initialized", func {
    settimer(update_afds, 6);
    # settimer(benchmark_update_afds, 6);
});

_setlistener("/sim/signals/reinit", func {
    if (afds) {
        afds.del();
    }
});

var benchmark_update_afds = func {
    var result = debug.benchmark("ap_update()", func afds.ap_update());
    debug.dump(result);
    settimer(benchmark_update_afds, 0.01);
};

var update_afds = func {
    afds.ap_update();
    settimer(update_afds, 0.01);
}


var enableOSD = func {
    

    var afdsInternal = "instrumentation/afds/internal/altitude/";
    var afdsInput = "instrumentation/afds/inputs/";
    var autoPilotSettings = "/autopilot/settings/";
    var left  = screen.display.new(20, 10);

    left.add(autoPilotSettings~"actual-target-altitude-ft");
    left.add(autoPilotSettings~"counter-set-altitude-ft");

    left.add(afdsInput~"vnav-descent");
    left.add(afdsInput~"vnav-armed");
    left.add(afdsInput~"vnav-path-mode");
    left.add(afdsInput~"vertical-index");

    # left.add(afdsInternal~"altitude_restriction");
    # left.add(afdsInternal~"altitude_restriction_descent");
    # left.add(afdsInternal~"altitude_restriction_idx");
    # left.add(afdsInternal~"altitude_restriction_type");
    # left.add(afdsInternal~"intervention_alt");
    # left.add(afdsInternal~"optimal_alt");
    # left.add(afdsInternal~"top_of_descent");
    left.add("instrumentation/altimeter/indicated-altitude-ft");
    left.add("velocities/vertical-speed-fps");
    left.add("autopilot/route-manager/wp/true-bearing-deg");
    left.add("orientation/heading-deg");
    left.add("instrumentation/airspeed-indicator/indicated-speed-kt");
    left.add("instrumentation/airspeed-indicator/indicated-mach");
    left.add(afdsInput~"ias-mach-selected");
    left.add("autopilot/route-manager/descent/speed-kts");
    left.add("autopilot/route-manager/cruise/speed-mach");    
}
