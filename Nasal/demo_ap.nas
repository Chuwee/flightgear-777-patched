var demo_ap_enabled = props.globals.initNode("sim/model/demo-ap/enabled", 0, "BOOL");
var demo_ap_engage = props.globals.initNode("sim/model/demo-ap/engage-ap", 0, "BOOL");
var demo_ap_hdg = props.globals.initNode("sim/model/demo-ap/target-heading-deg", 0, "DOUBLE");
var demo_ap_alt = props.globals.initNode("sim/model/demo-ap/target-altitude-ft", 0, "DOUBLE");
var demo_ap_spd = props.globals.initNode("sim/model/demo-ap/target-speed-kt", 0, "DOUBLE");

var _state = {
    last_enabled: 0,
    last_airborne_ready: 0,
    last_hdg_target: nil,
    last_alt_target: nil,
    last_spd_target: nil,
    last_hdg_mode_request: 0,
    last_alt_mode_request: 0,
    last_spd_mode_request: 0,
};

var _normalize_hdg = func(hdg) {
    var h = hdg;
    while (h < 0) h += 360;
    while (h >= 360) h -= 360;
    if (h == 0) h = 360;
    return h;
}

var _abs_hdg_diff = func(a, b) {
    var d = a - b;
    while (d <= -180) d += 360;
    while (d > 180) d -= 360;
    return abs(d);
}

var _now = func {
    return getprop("sim/time/elapsed-sec") or 0;
}

var _is_airborne_ready = func {
    return !(getprop("gear/gear[1]/wow") == 1 or getprop("gear/gear[2]/wow") == 1)
        and (getprop("position/altitude-agl-ft") > 250);
}

var _ensure_guidance_ready = func {
    if (getprop("instrumentation/afds/inputs/FD") != 1) {
        setprop("instrumentation/afds/inputs/FD", 1);
        b777.afds.input(3,2);
    }
    if (getprop("instrumentation/afds/inputs/at-armed[0]") != 1) {
        setprop("instrumentation/afds/inputs/at-armed[0]", 1);
    }
    if (getprop("instrumentation/afds/inputs/at-armed[1]") != 1) {
        setprop("instrumentation/afds/inputs/at-armed[1]", 1);
    }
}

var _engage_ap_if_ready = func {
    if (!demo_ap_engage.getValue()) {
        return 0;
    }
    if (!_is_airborne_ready()) {
        return 0;
    }
    if (getprop("instrumentation/afds/inputs/AP") == 1) {
        return 0;
    }
    setprop("instrumentation/afds/inputs/AP-disengage", 0);
    setprop("instrumentation/afds/inputs/AP", 1);
    return 1;
}

var _apply_heading_target = func {
    var raw_target = demo_ap_hdg.getValue();
    if (raw_target <= 0) return;

    var target_hdg = _normalize_hdg(raw_target);
    var current_bug = _normalize_hdg(getprop("autopilot/settings/heading-bug-deg"));
    if ((_state.last_hdg_target == nil)
            or (_abs_hdg_diff(target_hdg, current_bug) > 0.5)) {
        setprop("autopilot/settings/heading-bug-deg", target_hdg);
        _state.last_hdg_target = target_hdg;
        _state.last_hdg_mode_request = 0;
    }

    var roll_mode = getprop("instrumentation/afds/ap-modes/roll-mode");
    var lateral_idx = getprop("instrumentation/afds/inputs/lateral-index");
    var reference_hdg = getprop("instrumentation/afds/inputs/reference-deg");
    if (reference_hdg == nil) {
        reference_hdg = getprop("orientation/heading-deg");
    }
    reference_hdg = _normalize_hdg(reference_hdg);
    var heading_error = _abs_hdg_diff(target_hdg, reference_hdg);
    var now = _now();
    # A commanded heading target is a "follow the bug" instruction, not
    # "freeze present heading". HDG HOLD can therefore make the heading bug
    # move with no corresponding turn. Force HDG SEL whenever the demo bridge
    # owns lateral guidance and there is still meaningful heading error left.
    if ((heading_error > 2.5)
            and ((roll_mode != "HDG SEL") or (lateral_idx != 1))
            and (_state.last_hdg_mode_request + 0.25 <= now)) {
        b777.afds.input(0,1);
        _state.last_hdg_mode_request = now;
    }
}

var _apply_altitude_target = func {
    var target_alt = int(demo_ap_alt.getValue() / 100 + 0.5) * 100;
    if (target_alt <= 0) return;

    if ((_state.last_alt_target == nil)
            or (_state.last_alt_target != target_alt)
            or (getprop("autopilot/settings/counter-set-altitude-ft") != target_alt)) {
        setprop("autopilot/settings/counter-set-altitude-ft", target_alt);
        _state.last_alt_target = target_alt;
    }
    if (getprop("autopilot/settings/actual-target-altitude-ft") != target_alt) {
        setprop("autopilot/settings/actual-target-altitude-ft", target_alt);
    }

    var current_alt = getprop("instrumentation/altimeter/indicated-altitude-ft");
    var desired_mode = (abs(target_alt - current_alt) > 200) ? "FLCH SPD" : "ALT";
    var pitch_mode = getprop("instrumentation/afds/ap-modes/pitch-mode");
    var now = _now();
    if ((pitch_mode != desired_mode) and (_state.last_alt_mode_request + 1.0 <= now)) {
        if (desired_mode == "FLCH SPD") {
            b777.afds.input(1,8);
        } else {
            b777.afds.input(1,1);
        }
        _state.last_alt_mode_request = now;
    }
}

var _apply_speed_target = func {
    var target_spd = int(demo_ap_spd.getValue() + 0.5);
    if (target_spd <= 0) return;

    if ((_state.last_spd_target == nil)
            or (_state.last_spd_target != target_spd)
            or (getprop("autopilot/settings/target-speed-kt") != target_spd)) {
        setprop("autopilot/settings/target-speed-kt", target_spd);
        _state.last_spd_target = target_spd;
    }

    var pitch_mode = getprop("instrumentation/afds/ap-modes/pitch-mode");
    var at_mode = getprop("instrumentation/afds/inputs/autothrottle-index");
    var now = _now();
    if ((pitch_mode != "FLCH SPD")
            and (at_mode == 0)
            and (_state.last_spd_mode_request + 1.0 <= now)) {
        setprop("instrumentation/afds/inputs/autothrottle-index", 5);
        _state.last_spd_mode_request = now;
    }
}

var _reset_demo_state = func {
    _state.last_enabled = 0;
    _state.last_airborne_ready = 0;
    _state.last_hdg_target = nil;
    _state.last_alt_target = nil;
    _state.last_spd_target = nil;
    _state.last_hdg_mode_request = 0;
    _state.last_alt_mode_request = 0;
    _state.last_spd_mode_request = 0;
}

var _demo_ap_update = func {
    if (!demo_ap_enabled.getValue()) {
        _reset_demo_state();
        settimer(_demo_ap_update, 0.2);
        return;
    }

    _ensure_guidance_ready();
    var airborne_ready = _is_airborne_ready();
    _engage_ap_if_ready();

    if (airborne_ready or demo_ap_engage.getValue()) {
        _apply_heading_target();
        _apply_altitude_target();
        _apply_speed_target();
    }

    _state.last_enabled = 1;
    _state.last_airborne_ready = airborne_ready;

    settimer(_demo_ap_update, 0.2);
}

setlistener("sim/signals/fdm-initialized", func {
    _reset_demo_state();
    settimer(_demo_ap_update, 2);
});
