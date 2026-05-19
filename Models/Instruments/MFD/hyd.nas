#
# Hydraulics Synoptic panel
# Isaak Dieleman (based on Fuel Panel by jylebleu)
#
var LvlLabel = {
        DefaultColor:"rgba(255,255,255,1)",
        WarnColor:"rgba(255,215,87,1)",
		new : func(elt,format,ratio) {
            var m = { parents: [LvlLabel]};
            m.svgelt = elt;
            m.format = format;
            m.ratio = ratio;
            return m;
        },
        update : func(value) {
            
			me.svgelt.setText(sprintf(me.format,value*me.ratio));
			if (value <= 0.4) {
				me.svgelt.setColor(me.WarnColor);
			} else {
				me.svgelt.setColor(me.DefaultColor);
			}
        }
};

var PressLabel = {
        DefaultColor:"rgba(255,255,255,1)",
        WarnColor:"rgba(255,215,87,1)",
		new : func(elt,format,ratio) {
            var m = { parents: [PressLabel]};
            m.svgelt = elt;
            m.format = format;
            m.ratio = ratio;
            return m;
        },
        update : func(value) {
            
			me.svgelt.setText(sprintf(me.format,value*me.ratio));
			if (value >= 2500) {
				me.svgelt.setColor(me.DefaultColor);
			} else {
				me.svgelt.setColor(me.WarnColor);
			}
        }
};

var OvhtLabel = {
		new : func(elt) {
            var m = { parents: [OvhtLabel]};
            m.elt = elt;
            return m;
        },
        update : func(value) {
            if (value == 1) {
                me.elt.show();
            } else {
                me.elt.hide();
            }
        }
};

var ReservoirLvlText = {
		DefaultColor:"rgba(255,255,255,1)",
        WarnColor:"rgba(255,215,87,1)",
		new : func(elt) {
            var m = { parents: [ReservoirLvlText]};
            m.elt = elt;
            return m;
        },
        update : func(value) {
            if (value > 0.75 and value <= 1.00) {
				me.elt.hide();
			} elsif (value <= 0.40) {
				me.elt.show();
				me.elt.setText("LO");
				me.elt.setColor(me.WarnColor);
			} else { #only use the getprop if really needed
				var wow = getprop("gear/gear[0]/wow");
				if (value <= 0.75 and value > 0.40 and wow) {
					me.elt.show();
					me.elt.setText("RF");
					me.elt.setColor(me.DefaultColor);
				} elsif (wow) {
					me.elt.show();
					me.elt.setText("OF");
					me.elt.setColor(me.DefaultColor);
				} else {
					me.elt.hide();
				}
			}
        }
};

var ReservoirLvlLbl = {
		new : func(elt) {
            var m = { parents: [ReservoirLvlLbl]};
            m.elt = elt;
            return m;
        },
        update : func(value) {
            if (value > 0.75 and value <= 1.00) {
				me.elt.hide();
			} elsif (getprop("gear/gear[0]/wow") or value <= 0.40) {
                me.elt.show();
			} else {
				me.elt.hide();
            }
        }
};
	

var HydrPipe = {
        feeder : [],
        fillColor:"rgba(0,255,0,1)",
        emptyColor:"rgba(255,255,255,1)",
        new : func(elt) {
            var m = {parents : [HydrPipe]};
            m.feeder=[];
            m.overridePump = nil;
            m.elt = elt;
            m.HydrValves = [];
			m.HydrCombinationValves = [];
            return m;
        },
        feededBy : func(feeder) {
            append(me.feeder,feeder);
        },
        overridedBy : func(overridePump) {#if this pump is running, the pipe will not be used because it has lower priority.
            me.overridePump = overridePump;
        },
        openedBy : func(HydrValve) { # use if pipe is always open when this valve is open (valves in parallel to each other)
            append(me.HydrValves,HydrValve);
        },
		openedByComb : func(HydrValve) { # use if pipe is only open if a combination of at least 4 valves must be open (can be one valve checked multiple times)
			append(me.HydrCombinationValves, HydrValve);
		},
        oneValveOpened : func {
            if (size(me.HydrValves) == 0 and size(me.HydrCombinationValves) == 0) {
                return 1;
            }
            var valveStatus = 0;
            
			if (size(me.HydrCombinationValves) > 0) {
				for(var i=0; i<size(me.HydrCombinationValves); i+=1) {
					if (getprop(me.HydrCombinationValves[i]) == 1) {
						valveStatus += 1;
					}
				}
				if (valveStatus >= 4) {
					valveStatus = 1;
				} else {
					valveStatus = 0;
				}
					
			}
			
			var curValve = 0;
			if (size(me.HydrValves) > 0) {
				for(var i=0; i<size(me.HydrValves); i+=1) {
					if (getprop(me.HydrValves[i]) == 1) {
						curValve = 1;
					} else {
						curValve = 0;
					}
					if (valveStatus == 1 or curValve == 1) {
						valveStatus = 1;
					}
				}
			}
            return valveStatus;
        },
        opened : func() {
            var feederStatus = 0;
            for(var i=0; i<size(me.feeder); i+=1) {
                var CurrentFeeder = 0;
				if (getprop(me.feeder[i]) == 1) {
					CurrentFeeder = 1;
				}
				feederStatus = feederStatus or CurrentFeeder;
            }
            if (me.overridePump != nil and getprop(me.overridePump) == 1) {
                feederStatus = 0;
            }
            if (me.oneValveOpened() == 1 and feederStatus == 1) {
                return 1;
            }
            else return 0;
        },
        update : func() {
            if (me.opened()) {
                me.elt.show();
            }
            else {
                me.elt.hide();
            }
        }
};
var HydrValve = {
        new : func(symbClosed,symbOpened,symbBlocked) {
            var m = { parents: [HydrValve]};
            m.symbClosed = symbClosed;
            m.symbOpened = symbOpened;
            m.symbBlocked = symbBlocked;
            return m;
        },
        update : func(value) {
            if(value == 0) {
                me.symbClosed.show();
                me.symbOpened.hide();
                me.symbBlocked.hide();
            }
            elsif (value == 1) {
                me.symbClosed.hide();
                me.symbOpened.show();
                me.symbBlocked.hide();
            } else {
                me.symbClosed.hide();
                me.symbOpened.hide();
                me.symbBlocked.show();
            }
        }
};

var HydrPump = {
        new : func(PumpOpen,PumpBlocked) {
            var m = { parents: [HydrPump]};
            m.HydrPump = PumpOpen;
			m.HydrBlockPump = PumpBlocked;
            return m;
        },
        started : func() {
			me.HydrPump.show();
			me.HydrBlockPump.hide();
        },
        stopped : func() {
			me.HydrPump.hide();
			me.HydrBlockPump.hide();
        },
        blocked : func() {
			me.HydrPump.hide();
			me.HydrBlockPump.show();
        },
        update : func(value) {
            if(value == 0) {
                me.stopped();
            } elsif (value == 1) {
                me.started();
            } else {
                me.blocked();
            }
        }
};

    var HydPanel = {
        new : func(canvas_group)
        {
            var m = { parents: [HydPanel, MfDPanel.new("hyd",canvas_group,"Aircraft/777/Models/Instruments/MFD/hyd.svg",HydPanel.update)] };
            m.context = m;
            m.initSvgIds(m.group);
            return m;
        },
        initSvgIds: func(group)
        {
                              
            var lbl = LvlLabel.new(group.getElementById("Reservoir_L_Vol_txt"),"%.2f",1.00);
            me.registry.add("consumables/hydraulics/reservoir[0]/level-norm-cmd",lbl);
            lbl = LvlLabel.new(group.getElementById("Reservoir_C_Vol_txt"),"%.2f",1.00);
            me.registry.add("consumables/hydraulics/reservoir[1]/level-norm-cmd",lbl);
            lbl = LvlLabel.new(group.getElementById("Reservoir_R_Vol_txt"),"%.2f",1.00);
            me.registry.add("consumables/hydraulics/reservoir[2]/level-norm-cmd",lbl);
            lbl = PressLabel.new(group.getElementById("Reservoir_L_Press_txt"),"%.0f",1);
            me.registry.add("systems/hydraulics/system[0]/press-psi",lbl);
            lbl = PressLabel.new(group.getElementById("Reservoir_C_Press_txt"),"%.0f",1);
            me.registry.add("systems/hydraulics/system[1]/press-psi",lbl);
            lbl = PressLabel.new(group.getElementById("Reservoir_R_Press_txt"),"%.0f",1);
            me.registry.add("systems/hydraulics/system[2]/press-psi", lbl);
			
            me.initOvhtLabels();
			me.initReservoirLabels();
			me.initHydrPumps();
            me.initHydrValves();
            me.buildHydrCircuits();
        },
		
		initOvhtLabels : func() {
            var Ovhtlbls = {"L_PRI_Overheat_lbl":[0,0],"L_DEM_Overheat_lbl":[0,1],
                    "C1_Elec_Overheat_lbl":[1,0],"C1_Air_Overheat_lbl":[1,1],
                    "C2_Elec_Overheat_lbl":[1,2],"C2_Air_Overheat_lbl":[1,3],
                    "R_PRI_Overheat_lbl":[2,0],"R_DEM_Overheat_lbl":[2,1]};
            foreach(var labelId;keys(Ovhtlbls)) {
                var (systemNb,pumpNb) = Ovhtlbls[labelId];
                var OvhtLabel = OvhtLabel.new(me.group.getElementById(labelId));
                me.registry.add("systems/hydraulics/system["~systemNb~"]/m-pump["~pumpNb~"]/overheat",OvhtLabel);
            }
        },
		
		initReservoirLabels : func () {
			#TextLabels
			var Faultlbl = ReservoirLvlText.new(me.group.getElementById("Reservoir_L_Vol_Fault_txt"));
            me.registry.add("consumables/hydraulics/reservoir[0]/level-norm",Faultlbl);
            Faultlbl = ReservoirLvlText.new(me.group.getElementById("Reservoir_C_Vol_Fault_txt"));
            me.registry.add("consumables/hydraulics/reservoir[1]/level-norm",Faultlbl);
            Faultlbl = ReservoirLvlText.new(me.group.getElementById("Reservoir_R_Vol_Fault_txt"));
            me.registry.add("consumables/hydraulics/reservoir[2]/level-norm",Faultlbl);
			
			#Background
			Faultlbl = ReservoirLvlLbl.new(me.group.getElementById("Reservoir_L_Fault_Label"));
            me.registry.add("consumables/hydraulics/reservoir[0]/level-norm",Faultlbl);
            Faultlbl = ReservoirLvlLbl.new(me.group.getElementById("Reservoir_C_Fault_Label"));
            me.registry.add("consumables/hydraulics/reservoir[1]/level-norm",Faultlbl);
            Faultlbl = ReservoirLvlLbl.new(me.group.getElementById("Reservoir_R_Fault_Label"));
            me.registry.add("consumables/hydraulics/reservoir[2]/level-norm",Faultlbl);
		},
        
        initHydrPumps : func() {
            var HydrPumps = {	"L_Eng_Pump":"systems/hydraulics/system[0]/m-pump[0]/running",
								"L_Elec_DemandPump":"systems/hydraulics/system[0]/m-pump[1]/running",
								"C1_Elec_Pump":"systems/hydraulics/system[1]/m-pump[0]/running",
								"C1_Dem_Pump":"systems/hydraulics/system[1]/m-pump[1]/running",
								"C2_Elec_Pump":"systems/hydraulics/system[1]/m-pump[2]/running",
								"C2_Dem_Pump":"systems/hydraulics/system[1]/m-pump[3]/running",
								"C_RAT_Pump":"systems/hydraulics/system[1]/m-pump[4]/running",
								"R_Eng_Pump":"systems/hydraulics/system[2]/m-pump[0]/running",
								"R_Elec_DemandPump":"systems/hydraulics/system[2]/m-pump[1]/running"};
            foreach(var pumpId;keys(HydrPumps)) {
                var HydrPump = HydrPump.new(me.group.getElementById(pumpId~"_on"),me.group.getElementById(pumpId~"_Blocked"));
				me.registry.add(HydrPumps[pumpId],HydrPump);
			}
        },
        
        initHydrValves : func() {
            var HydrValves = {  "L_SOV_Valve_":"systems/hydraulics/system[0]/ShutOffValve/opened",
                            "C_NoseGear_Valve_":"systems/hydraulics/system[1]/IslnValve[0]/opened",
                            "C_Top_Valve_":"systems/hydraulics/system[1]/IslnValve[1]/opened",
                            "R_SOV_Valve_":"systems/hydraulics/system[2]/ShutOffValve/opened"};
            foreach(var rootId;keys(HydrValves)) {
                var HydrValve = HydrValve.new(me.group.getElementById(rootId~"Closed"),me.group.getElementById(rootId~"Open"),me.group.getElementById(rootId~"Blocked"));
                me.registry.add(HydrValves[rootId],HydrValve);
            }
        },
        
        buildHydrCircuits : func() {
			
			#Left Circuit
			var PrimaryPump = "systems/hydraulics/system[0]/m-pump[0]/running"; #int
            var DemandPump = "systems/hydraulics/system[0]/m-pump[1]/running"; #int
            var ShutOffValve = "systems/hydraulics/system[0]/ShutOffValve/opened"; #int
			var Reservoir = "systems/hydraulics/system[0]/Reservoir/active"; #bool
			
			 var addPipe = func(pipe) {
                me.registry.add(Reservoir,pipe);
            }
			
            var pipe = HydrPipe.new(me.group.getElementById("L_Prim_Pipe_on"));
            pipe.feededBy(PrimaryPump);
            pipe.openedBy(ShutOffValve);
            addPipe(pipe);
			
            pipe = HydrPipe.new(me.group.getElementById("L_Dem_Pipe_on"));
            pipe.feededBy(DemandPump);
            addPipe(pipe);
			
			#Right Circuit
			PrimaryPump = "systems/hydraulics/system[2]/m-pump[0]/running"; #int
            DemandPump = "systems/hydraulics/system[2]/m-pump[1]/running"; #int
            ShutOffValve = "systems/hydraulics/system[2]/ShutOffValve/opened"; #int
			Reservoir = "systems/hydraulics/system[2]/Reservoir/active"; #bool
			
			pipe = HydrPipe.new(me.group.getElementById("R_Prim_Pipe_on"));
            pipe.feededBy(PrimaryPump);
            pipe.openedBy(ShutOffValve);
            addPipe(pipe);
			
            pipe = HydrPipe.new(me.group.getElementById("R_Dem_Pipe_on"));
            pipe.feededBy(DemandPump);
            addPipe(pipe);
			
			#Center Circuit
			var C1ElecPump = "systems/hydraulics/system[1]/m-pump[0]/running"; #int
            var C1AirPump = "systems/hydraulics/system[1]/m-pump[1]/running"; #int
			var C2ElecPump = "systems/hydraulics/system[1]/m-pump[2]/running"; #int
            var C2AirPump = "systems/hydraulics/system[1]/m-pump[3]/running"; #int
			var RATPump = "systems/hydraulics/system[1]/m-pump[4]/running"; #int
            var NoseGearValve = "systems/hydraulics/system[1]/IslnValve[0]/opened"; #int
			var TopValve = "systems/hydraulics/system[1]/IslnValve[1]/opened"; #int
			Reservoir = "systems/hydraulics/system[1]/Reservoir/active"; #bool
			
			# Add feeder pipes
            pipe = HydrPipe.new(me.group.getElementById("C1_Elec_Pipe_on"));
            pipe.feededBy(C1ElecPump);
            addPipe(pipe);
			
            pipe = HydrPipe.new(me.group.getElementById("C_Standpipe_on"));
            pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.feededBy(C2ElecPump);
			pipe.feededBy(RATPump);
            addPipe(pipe);
			
			pipe = HydrPipe.new(me.group.getElementById("C_Standpipe_left_on"));
            pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
            addPipe(pipe);
			
			pipe = HydrPipe.new(me.group.getElementById("C1_Dem_Pipe_on"));
            pipe.feededBy(C1AirPump);
            addPipe(pipe);
			
			pipe = HydrPipe.new(me.group.getElementById("C2_Dem_Pipe_on"));
            pipe.feededBy(C2AirPump);
            addPipe(pipe);
			
			pipe = HydrPipe.new(me.group.getElementById("C_Standpipe_right_on"));
			pipe.feededBy(C2ElecPump);
			pipe.feededBy(RATPump);
            addPipe(pipe);
			
			pipe = HydrPipe.new(me.group.getElementById("C2_Elec_Pipe_on"));
			pipe.feededBy(C2ElecPump);
            addPipe(pipe);
			
			pipe = HydrPipe.new(me.group.getElementById("C_RAT_Pipe_on"));
			pipe.feededBy(RATPump);
            addPipe(pipe);
			
			#Add top pipes
			
			#C_Top_C1_Pipe is active:
			# - If C1Elec, C1Air, C2Air or C2Elec is on and IslnValve[1] is open
			
			pipe = HydrPipe.new(me.group.getElementById("C_Top_C1_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.feededBy(C2ElecPump);
			pipe.openedBy(TopValve);
            addPipe(pipe);
			
			#C_Top_Center_Pipe is active:
			# - If C1Elec, C2Air or C2Elec is on and IslnValve[1] is open
			# - If C1Air is on
			
			pipe = HydrPipe.new(me.group.getElementById("C_Top_Center_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.feededBy(C2AirPump);
			pipe.feededBy(C2ElecPump);
			#TopValve needs to be open to open if any of the above pumps is running, therefore is checked 3 times.
			pipe.openedByComb(TopValve);
			pipe.openedByComb(TopValve);
			pipe.openedByComb(TopValve);
			pipe.openedByComb(C1ElecPump);
			pipe.openedByComb(C2AirPump);
			pipe.openedByComb(C2ElecPump);
			#Top_Center_Pipe is always on if C1AirPump is running.
			pipe.feededBy(C1AirPump);
			pipe.openedBy(C1AirPump);
			addPipe(pipe);
			
			#C_Top_C2_Pipe is active:
			# - If C1Elec or C2Elec is on and IslnValve[1] is open
			# - If C1Air or C2Air is on
			
			pipe = HydrPipe.new(me.group.getElementById("C_Top_C2_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.feededBy(C2ElecPump);
			pipe.openedByComb(TopValve);
			pipe.openedByComb(TopValve);
			pipe.openedByComb(TopValve);
			# TopValve needs to be open if any of the above pumps is running, therefore is checked 3 times.
			pipe.openedByComb(C1ElecPump);
			pipe.openedByComb(C2ElecPump);
			pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.openedBy(C1AirPump);
			pipe.openedBy(C2AirPump);
			addPipe(pipe);
			
			#C_Top_C2_Right_Pipe is active:
			# - If C1Elec is on and IslnValve[1] is open
			# - If C1Air, C2Air or C2Elec is on
			
			pipe = HydrPipe.new(me.group.getElementById("C_Top_C2_Right_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.openedBy(TopValve);
			pipe.feededBy(C2ElecPump);
			pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.openedBy(C2ElecPump);
			pipe.openedBy(C1AirPump);
			pipe.openedBy(C2AirPump);
			addPipe(pipe);
						
			#C_Top_C_RAT_Pipe is active:
			# - If C1Elec is on and IslnValve[1] is open
			# - If C1Air or C2Air or C2Elec is on
			
			pipe = HydrPipe.new(me.group.getElementById("C_Top_C2_RAT_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.openedBy(TopValve);
			pipe.feededBy(C2ElecPump);
			pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.openedBy(C2ElecPump);
			pipe.openedBy(C1AirPump);
			pipe.openedBy(C2AirPump);
			addPipe(pipe);
			
			
			#Add Outputpipes.
			
			#C_Output_Nosegr_Pipe is active:
			# - If C1ElecPump is on and IslnValve[0] is open
			# - or if C1Air, C2Air or C2Elec is on and both IslnValves are Open
			
			pipe = HydrPipe.new(me.group.getElementById("C_Output_Nosegr_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.feededBy(C2ElecPump);
			pipe.openedByComb(TopValve);
			pipe.openedByComb(NoseGearValve);
			pipe.openedByComb(NoseGearValve);
			pipe.openedByComb(NoseGearValve);
			pipe.openedByComb(C1ElecPump);
			addPipe(pipe);
			
			#C_Output_C_Altnbrk_Pipe is active:
			# - If C1ElecPump is on
			# - or if C1Air, C2Air or C2Elec is on and IslnValve[1] is open
			
			pipe = HydrPipe.new(me.group.getElementById("C_Output_C_Altnbrk_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.openedBy(C1ElecPump);
			pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.feededBy(C2ElecPump);
			pipe.openedBy(TopValve);
			addPipe(pipe);
			
			#C_Output_C_Flaps_Pipe is active:
			# - if C1ElecPump is on and IslnValve[1] is Open
			# - or if C1Air, C2Air or C2Elec is on
			
			pipe = HydrPipe.new(me.group.getElementById("C_Output_C_Flaps_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.openedBy(TopValve);
			pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.feededBy(C2ElecPump);
			pipe.openedBy(C1AirPump);
			pipe.openedBy(C2AirPump);
			pipe.openedBy(C2ElecPump);
			addPipe(pipe);
			
			#C_Output_R_Fltctrl_Pipe is active:
			# - if C1ElecPump is on and IslnValve[1] is Open
			# - or if C1Air, C2Air, C2Elec or RAT is on
			
			pipe = HydrPipe.new(me.group.getElementById("C_Output_R_Fltctrl_Pipe_on"));
			pipe.feededBy(C1ElecPump);
			pipe.openedBy(TopValve);
			pipe.feededBy(C1AirPump);
			pipe.feededBy(C2AirPump);
			pipe.feededBy(C2ElecPump);
			pipe.feededBy(RATPump);
			pipe.openedBy(C1AirPump);
			pipe.openedBy(C2AirPump);
			pipe.openedBy(C2ElecPump);
			pipe.openedBy(RATPump);
			addPipe(pipe);
            
        },
		
        update: func()
        {
            me.updateAll();
        }
    };