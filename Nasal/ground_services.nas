#Ground Services added by Isaak Dieleman - 20190405

var icecrane = aircraft.door.new("services/deicing_truck/crane", 20);
var icecrane1 = aircraft.door.new("services/deicing_truck/crane[1]", 20);
var icecrane2 = aircraft.door.new("services/deicing_truck/crane[2]", 20);
var icecrane3 = aircraft.door.new("services/deicing_truck/crane[3]", 20);
var icecrane4 = aircraft.door.new("services/deicing_truck/crane[4]", 20);
var icetruck = aircraft.door.new("services/deicing_truck/truck[0]", 100);
var icetruck1 = aircraft.door.new("services/deicing_truck/truck[1]", 100);
var icetruck2 = aircraft.door.new("services/deicing_truck/truck[2]", 100);
var icetruck3 = aircraft.door.new("services/deicing_truck/truck[3]", 100);
var icetruck4 = aircraft.door.new("services/deicing_truck/truck[4]", 100);
var icedeicing = aircraft.door.new("services/deicing_truck/deicing", 70);
var icedeicing1 = aircraft.door.new("services/deicing_truck/deicing[1]", 80);
var icedeicing2 = aircraft.door.new("services/deicing_truck/deicing[2]", 75);
var icedeicing3 = aircraft.door.new("services/deicing_truck/deicing[3]", 78);
var icedeicing4 = aircraft.door.new("services/deicing_truck/deicing[4]", 77);
var StartTimeText = "";

#Autoconnect variables:

var OnBlocksTime = "";
var CurrentSecond = 0;
var PreviousSecond = 0;
var OnBlocksSecond = 0;
var DeboardingFinished = 0;
var DeboardingStarted = 0;
var BoardingStatus = 0;
var DeBoardingTime = 0;
var CateringStatus = 0;
var CateringStartUnloadingT = 0;
var AutoJetways = getprop("aircraft/settings/gnd_autojetways");

#Autoconnect Connection variables
var GPU1 = 0;
var GPU2 = 0;
var GPUBox = 0;
var ChockL = 0;
var ChockR = 0;
var ChockN = 0;
var ConeL = 0;
var ConeR = 0;
var ConeLW = 0;
var ConeRW = 0;
var ConeTailL = 0;
var ConeTailR = 0;
var Bus1 = 0;
var Bus2 = 0;
var Jetway1 = 0;
var Jetway2 = 0;
var Stairs1 = 0;
var Stairs2 = 0;
var Stairs3 = 0;
var Stairs4 = 0;
var Baggage1 = 0;
var Baggage2 = 0;
var Catering1 = 0;
var Catering2 = 0;
var Catering3 = 0;
var Catering4 = 0;
var FuelTruck = 0;
var FuelTruckPipe = 0;

#Autoconnect Connection Time Variables
var GPU1T = 0;
var GPU2T = 0;
var GPUBoxT = 0;
var ChockLT = 0;
var ChockRT = 0;
var ChockNT = 0;
var ConeLT = 0;
var ConeRT = 0;
var ConeLWT = 0;
var ConeRWT = 0;
var ConeTailLT = 0;
var ConeTailRT = 0;
var Bus1T = 0;
var Bus2T = 0;
var Jetway1T = 0;
var Jetway2T = 0;
var Stairs1T = 0;
var Stairs2T = 0;
var Stairs3T = 0;
var Stairs4T = 0;
var Baggage1T = 0;
var Baggage2T = 0;
var Catering1T = 0;
var Catering2T = 0;
var Catering3T = 0;
var Catering4T = 0;
var FuelTruckT = 0;
var FuelTruckPipeT = 0;

var StatusUpdate = 0;

var ground_services = {
    init : func {
    
    # Fuel Truck
    
    setprop("services/fuel-truck/enable", 0);
    setprop("services/fuel-truck/connect", 0);
    setprop("services/fuel-truck/transfer", 0);
    setprop("services/fuel-truck/clean", 0);
    setprop("services/fuel-truck/request-lbs", getprop("consumables/fuel/total-fuel-lbs"));
    setprop("services/fuel-truck/extra-lbs", 0);
    setprop("services/fuel-truck/speed-text", " ");
    setprop("services/fuel-truck/finished", 0);
    
    # Payload System
    
    if (getprop("sim/aero") != "777-200F") {
        # The 777-200F has its own payload dialog. For the other types, the max number of first/business/economy pax and catering has to be defined, so we
        # overwrite the dialog with the values specified in their respective -set files.
        var payload = gui.Dialog.new("sim/gui/dialogs/payload/dialog", "gui/dialogs/payload-dlg.xml");
        setprop("sim/gui/dialogs/payload/dialog/group[1]/slider/max", getprop("services/payload/first-max-nr"));
        setprop("sim/gui/dialogs/payload/dialog/group[1]/slider[1]/max", getprop("services/payload/business-max-nr"));
        setprop("sim/gui/dialogs/payload/dialog/group[1]/slider[2]/max", getprop("services/payload/economy-max-nr"));
        setprop("sim/gui/dialogs/payload/dialog/group[1]/slider[3]/max", getprop("services/catering/weight-max-lbs"));
        setprop("sim/gui/dialogs/payload/dialog/group[1]/button[1]/binding/max", getprop("services/payload/first-max-nr"));
        setprop("sim/gui/dialogs/payload/dialog/group[1]/button[3]/binding/max", getprop("services/payload/business-max-nr"));
        setprop("sim/gui/dialogs/payload/dialog/group[1]/button[5]/binding/max", getprop("services/payload/economy-max-nr"));
        setprop("sim/gui/dialogs/payload/dialog/group[1]/button[7]/binding/max", getprop("services/catering/weight-max-lbs"));
    }
    setprop("services/stairs/flaps-jammed", 0);
        
    # External Power
    
    setprop("services/ext-pwr/enable", 0);
    setprop("services/ext-pwr/primary", 0);
    setprop("services/ext-pwr/secondary", 0);
    
    # Chocks
    
    setprop("services/chocks/nose", 0);
    setprop("services/chocks/left", 0);
    setprop("services/chocks/right", 0);
    
    # De-Icing
    setprop("services/deicing_truck/truck/position-norm", 0);
    setprop("services/deicing_truck/crane/position-norm", 0);
    setprop("services/deicing_truck/deicing/position-norm", 0);
    setprop("services/deicing_truck/enable", 0);
    setprop("services/deicing_truck/de-ice", 0);
    setprop("services/deicing_truck/truck/direction", 0);    

    _startstop_gsv();
    
    },
    update : func {
        
        #Autoconnect: Enable services based on assigned connection time.
        
        if (OnBlocksTime != "") {
            
            #Keep track of current time
            CurrentSecond = getprop("sim/time/elapsed-sec");
            
            if (CurrentSecond != PreviousSecond) {
                BoardingStatus = getprop("services/payload/pax-boarding");
                CateringStatus = getprop("services/catering/loading");
                
                if (BoardingStatus == 2) {
                    DeboardingStarted = 1;
                } elsif (DeboardingStarted == 1 and BoardingStatus == 0) {
                    DeboardingFinished = 1;
                    DeboardingStarted = 0;
                }
            }
            
            
            #### Ground Power Unit autoconnection
            
            #Connect GPUBox if required
            if (GPUBox == 0 and GPUBoxT != 0) {
                if (GPUBoxT <= CurrentSecond) {
                    GPUBox = 1;
                    setprop("services/ext-pwr/enable", 1);
                }
            }
            #Connect GPU 1 if required
            if (GPU1 == 0 and GPU1T != 0) {
                if (GPU1T <= CurrentSecond) {
                    GPU1 = 1;
                    setprop("services/ext-pwr/primary", 1);
                    
                    if ((GPU2T != 0 and GPU2 == 1) or GPU2T == 0) {
                        screen.log.write("Ground Power available", 0, 0.584, 1);
                    }
                }
            }
            #Connect GPU 2 if required
            if (GPU2 == 0 and GPU2T != 0) {
                if (GPU2T <= CurrentSecond) {
                    GPU2 = 1;
                    setprop("services/ext-pwr/secondary", 1);
                    
                    if ((GPU1T != 0 and GPU1 == 1) or GPU1T == 0) {
                        screen.log.write("Ground Power available", 0, 0.584, 1);
                    }
                }
            }
            
            #### Chocks
            
            if (ChockL == 0 and ChockLT != 0) {
                if (ChockLT <= CurrentSecond) {
                    ChockL = 1;
                    setprop("services/chocks/left", 1);
                }
                
                if (ChockL == 1 and ChockR == 1 and ChockN == 1) {
                    screen.log.write("Chocks in place, cleared to release Parking Brake", 0, 0.584, 1);
                }
            }
            
            if (ChockR == 0 and ChockRT != 0) {
                if (ChockRT <= CurrentSecond) {
                    ChockR = 1;
                    setprop("services/chocks/right", 1);
                }
                
                if (ChockL == 1 and ChockR == 1 and ChockN == 1) {
                    screen.log.write("Chocks in place, cleared to release Parking Brake", 0, 0.584, 1);
                }
            }
            
            if (ChockN == 0 and ChockNT != 0) {
                if (ChockNT <= CurrentSecond) {
                    ChockN = 1;
                    setprop("services/chocks/nose", 1);
                }
                
                if (ChockL == 1 and ChockR == 1 and ChockN == 1) {
                    screen.log.write("Chocks in place, cleared to release Parking Brake", 0, 0.584, 1);
                }
            }
            
            #### Safety Cones
            
            if (ConeL == 0 and ConeLT != 0) {
                if (ConeLT <= CurrentSecond) {
                    ConeL = 1;
                    setprop("services/cones/cone1-enable", 1);
                }
            }
            
            if (ConeR == 0 and ConeRT != 0) {
                if (ConeRT <= CurrentSecond) {
                    ConeR = 1;
                    setprop("services/cones/cone2-enable", 1);
                }
            }
			
			if (ConeLW == 0 and ConeLWT != 0) {
                if (ConeLWT <= CurrentSecond) {
                    ConeLW = 1;
                    setprop("services/cones/coneLW-enable", 1);
                }
            }
            
            if (ConeRW == 0 and ConeRWT != 0) {
                if (ConeRWT <= CurrentSecond) {
                    ConeRW = 1;
                    setprop("services/cones/coneRW-enable", 1);
                }
            }
            
			if (ConeTailL == 0 and ConeTailLT != 0) {
				if (ConeTailLT <= CurrentSecond) {
                    ConeTailL = 1;
                    setprop("services/cones/coneTailL-enable", 1);
                }
            }
			
			if (ConeTailR == 0 and ConeTailRT != 0) {
				if (ConeTailRT <= CurrentSecond) {
                    ConeTailR = 1;
                    setprop("services/cones/coneTailR-enable", 1);
                }
            }
            
            #### Busses
            
            if (Bus1 == 0 and Bus1T != 0) {
                if (Bus1T <= CurrentSecond) {
                    Bus1 = 1;
                    setprop("services/bus/bus1-enable", 1);
                }
            }
            
            if (Bus2 == 0 and Bus2T != 0) {
                if (Bus2T <= CurrentSecond) {
                    Bus2 = 1;
                    setprop("services/bus/bus2-enable", 1);
                }
            }
            
            ####Jetways
            
            if (Jetway1 == 0 and Jetway1T != 0) {
                if (Jetway1T <= CurrentSecond) {
                    Jetway1 = 1;
                    setprop("services/payload/jetway1_enable", 1);
                    
                    # Connect 3D Jetway to door 1L (if available)
                    if (AutoJetways) {
                        JetwayConnect(0);
                    }
                    
                    if (DeBoardingTime == 0 and DeboardingStarted != 1 and DeboardingFinished != 1) {
                        DeBoardingTime = CurrentSecond + 60 + rand() * 60;
                    }
                }
            }
            
            if (Jetway2 == 0 and Jetway2T != 0) {
                if (Jetway2T <= CurrentSecond) {
                    Jetway2 = 1;
                    setprop("services/payload/jetway2_enable", 1);
                    
                    # Connect 3D Jetway to door 2L (if available)
                    if (AutoJetways) {
                        JetwayConnect(1);
                    }
                    
                    if (DeBoardingTime == 0 and DeboardingStarted != 1 and DeboardingFinished != 1) {
                        DeBoardingTime = CurrentSecond + 60 + rand() * 60;
                    }
                }
            }
            
            ####Stairs
            
            if (Stairs1 == 0 and Stairs1T != 0) {
                if (Stairs1T <= CurrentSecond) {
                    Stairs1 = 1;
                    setprop("services/stairs/stairs1_enable", 1);
                    if (DeBoardingTime == 0 and DeboardingStarted != 1 and DeboardingFinished != 1) {
                        DeBoardingTime = CurrentSecond + 10 + rand() * 60;
                    }
                }
            }
            
            if (Stairs2 == 0 and Stairs2T != 0) {
                if (Stairs2T <= CurrentSecond) {
                    Stairs2 = 1;
                    setprop("services/stairs/stairs2_enable", 1);
                    if (DeBoardingTime == 0 and DeboardingStarted != 1 and DeboardingFinished != 1) {
                        DeBoardingTime = CurrentSecond + 10 + rand() * 60;
                    }
                }
            }
            
            if (Stairs3 == 0 and Stairs3T != 0) {
                if (Stairs3T <= CurrentSecond) {
                    Stairs3 = 1;
                    setprop("services/stairs/stairs3_enable", 1);
                    if (DeBoardingTime == 0 and DeboardingStarted != 1 and DeboardingFinished != 1) {
                        DeBoardingTime = CurrentSecond + 10 + rand() * 60;
                    }
                }
            }
            
            if (Stairs4 == 0 and Stairs4T != 0) {
                if (Stairs4T <= CurrentSecond) {
                    Stairs4 = 1;
                    setprop("services/stairs/stairs4_enable", 1);
                    if (DeBoardingTime == 0 and DeboardingStarted != 1 and DeboardingFinished != 1) {
                        DeBoardingTime = CurrentSecond + 10 + rand() * 60;
                    }
                }
            }
            
            #### Baggage Trucks
            
            if (Baggage1 == 0 and Baggage1T != 0) {
                if (Baggage1T <= CurrentSecond) {
                    Baggage1 = 1;
                    setprop("services/payload/baggage-truck1-enable", 1);
                    
                    # If there is baggage on board, start unloading if that hasn't started yet.
                    if (getprop("services/payload/baggage-loading") != 2 and getprop("services/payload/belly-onboard-lbs") > 0) {
                        setprop("services/payload/baggage-loading", 2);
                        screen.log.write("Baggage unloading started.", 0, 0.584, 1);
                        setprop("services/payload/loadingtime_remaining", "Start unloading...");
                    }
                }
            }
            
            if (Baggage2 == 0 and Baggage2T != 0) {
                if (Baggage2T <= CurrentSecond) {
                    Baggage2 = 1;
                    setprop("services/payload/baggage-truck2-enable", 1);
                    
                    # If there is baggage on board, start unloading if that hasn't started yet.
                    if (getprop("services/payload/baggage-loading") != 2 and getprop("services/payload/belly-onboard-lbs") > 0) {
                        setprop("services/payload/baggage-loading", 2);
                        screen.log.write("Baggage unloading started.", 0, 0.584, 1);
                        setprop("services/payload/loadingtime_remaining", "Start unloading...");
                    }
                }
            }
            
            #### Catering Trucks
            
            if (Catering1 == 0 and Catering1T != 0) {
                if ((Stairs1T == 0 and Jetway1T == 0) or DeboardingFinished == 1) {
                    Catering1 = 1;
                    setprop("services/catering/truck[0]/connect", 1);
                    if (OnBlocksTime != "" and CateringStatus != 2 and getprop("services/catering/truck[0]/weight-lbs") > 0) {
                        CateringLogic();
                    }
                }
            }
            
            if (Catering2 == 0 and Catering2T != 0) {
                if (DeboardingFinished == 1) {
                    Catering2 = 1;
                    setprop("services/catering/truck[1]/connect", 1);
                    if (OnBlocksTime != "" and CateringStatus != 2 and getprop("services/catering/truck[1]/weight-lbs") > 0) {
                        CateringLogic();
                    }
                }
            }
            
            if (Catering3 == 0 and Catering3T != 0) {
                if (DeboardingFinished == 1) {
                    Catering3 = 1;
                    setprop("services/catering/truck[2]/connect", 1);
                    if (OnBlocksTime != "" and CateringStatus != 2 and getprop("services/catering/truck[2]/weight-lbs") > 0) {
                        CateringLogic();
                    }
                }
            }
            
            if (Catering4 == 0 and Catering4T != 0) {
                if (Stairs4T == 0 or DeboardingFinished == 1) {
                    Catering4 = 1;
                    setprop("services/catering/truck[3]/connect", 1);
                    if (OnBlocksTime != "" and CateringStatus != 2 and getprop("services/catering/truck[3]/weight-lbs") > 0) {
                        CateringLogic();
                    }
                }
            }
            
            #### Fuel Truck
            
            if (FuelTruck == 0 and FuelTruckT != 0) {
                if (FuelTruckT <= CurrentSecond) {
                    FuelTruck = 1;
                    setprop("services/fuel-truck/enable", 1);
                }
            }
            
            if (FuelTruckPipe == 0 and FuelTruckPipeT != 0) {
                if (FuelTruckPipeT <= CurrentSecond) {
                    FuelTruckPipe = 1;
                    setprop("services/fuel-truck/connect", 1);
                }
            }
            
            if (OnBlocksTime != "" and CateringStartUnloadingT != 0 and CateringStartUnloadingT <= CurrentSecond and CateringStatus != 2 and getprop("services/catering/weight-lbs") > 0) {
                CateringLogic();
            }
            
            if (DeBoardingTime != 0 and DeBoardingTime <= CurrentSecond) {
                DeBoardingTime = 0;
                
                # If there are passengers on board and deboarding has not yet started, start deboarding
                if (BoardingStatus != 2 and getprop("services/payload/pax-onboard-nr") > 0 and getprop("controls/cabin/SeatBelt-status") == -1) {
                    setprop("services/payload/pax-boarding", 2);
                    screen.log.write("Passenger deboarding started.", 0, 0.584, 1);
                    setprop("services/payload/boardingtime_remaining", "Start deboarding...");
                } elsif (BoardingStatus != 2 and getprop("services/payload/pax-onboard-nr") > 0 and getprop("controls/cabin/SeatBelt-status") != -1 and (Stairs1 == 1 or Stairs2 == 1 or Stairs3 == 1 or Stairs4 == 1)) {
                    screen.log.write("Stairs connected. Please switch off the Seatbelt sign and manually start deboarding.", 1, 0.4, 0);
                } elsif (BoardingStatus != 2 and getprop("services/payload/pax-onboard-nr") > 0 and getprop("controls/cabin/SeatBelt-status") != -1 and (Jetway1 == 1 or Jetway2 == 1)) {
                    screen.log.write("Jetway connected. Please switch off the Seatbelt sign and manually start deboarding.", 1, 0.4, 0);
                }
            }
            
            if (OnBlocksTime != "" and StatusUpdate == 0
				and (GPU1T == 0 or GPU1 == 1) and (GPU2T == 0 or GPU2 == 1) and (GPUBoxT == 0 or GPUBox == 1)
				and (ChockLT == 0 or ChockL == 1) and (ChockRT == 0 or ChockR == 1) and (ChockNT == 0 or ChockN == 1)
				and (ConeLT == 0 or ConeL == 1) and (ConeRT == 0 or ConeR == 1) and (ConeLWT == 0 or ConeLW == 1)
				and (ConeRWT == 0 or ConeRW == 1) and (ConeTailLT == 0 or ConeTailL == 1) and (ConeTailRT == 0 or ConeTailR == 1)
				and (Bus1T == 0 or Bus1 == 1) and (Bus2T == 0 or Bus2 == 1)
				and (Jetway1T == 0 or Jetway1 == 1) and (Jetway2T == 0 or Jetway2 == 1)
				and (Stairs1T == 0 or Stairs1 == 1) and (Stairs2T == 0 or Stairs2 == 1)
				and (Stairs3T == 0 or Stairs3 == 1) and (Stairs4T == 0 or Stairs4 == 1)
				and (Baggage1T == 0 or Baggage1 == 1) and (Baggage2T == 0 or Baggage2 == 1)
				and (Catering1T == 0 or Catering1 == 1) and (Catering2T == 0 or Catering2 == 1)
				and (Catering3T == 0 or Catering3 == 1) and (Catering4T == 0 or Catering4 == 1)
				and (FuelTruckT == 0 or FuelTruck == 1) and (FuelTruckPipeT == 0 or FuelTruckPipe == 1)				
			) {
				setprop("aircraft/settings/autoconnect/status", "Active: Requested services connected");
				StatusUpdate = 1;
            }
			
			if (OnBlocksTime != "" and DeboardingFinished == 1 and getprop("services/payload/belly-onboard-lbs") == 0 and getprop("services/catering") == 0) {
                OnBlocksTime = "";
				StatusUpdate = 0;
				setprop("aircraft/settings/autoconnect/status", "Finished");
            }
            
            PreviousSecond = CurrentSecond;
        }
    
        # Fuel Truck Controls
        # Fuel Transfer Rate is based on a 1000 US Gal flow per minute, which is at the fast side of real life operations, but not unrealistic.
        
        if (getprop("services/fuel-truck/enable") and getprop("services/fuel-truck/connect")) {
        
            if (getprop("services/fuel-truck/transfer")) {
            
                if (getprop("consumables/fuel/total-fuel-lbs") < getprop("services/fuel-truck/request-lbs")) {
                    if (getprop("consumables/fuel/tank/level-gal_us") < getprop("consumables/fuel/tank[2]/capacity-gal_us")) {
                        if (getprop("consumables/fuel/tank/level-lbs") + 6 > getprop("services/fuel-truck/request-lbs") - getprop("consumables/fuel/tank[2]/level-lbs") - getprop("consumables/fuel/tank[1]/level-lbs")) {
                            setprop("consumables/fuel/tank/level-lbs", getprop("consumables/fuel/tank/level-lbs") + 0.1);
                        } else {
                            setprop("consumables/fuel/tank/level-lbs", getprop("consumables/fuel/tank/level-lbs") + 5.55);
                        }
                    }
                    if (getprop("consumables/fuel/tank[2]/level-gal_us") < getprop("consumables/fuel/tank[2]/capacity-gal_us")) {
                        if (getprop("consumables/fuel/tank[2]/level-lbs") + 6 > getprop("services/fuel-truck/request-lbs") - getprop("consumables/fuel/tank/level-lbs") - getprop("consumables/fuel/tank[1]/level-lbs")) {
                            setprop("consumables/fuel/tank[2]/level-lbs", getprop("consumables/fuel/tank[2]/level-lbs") + 0.1);
                        } else {
                            setprop("consumables/fuel/tank[2]/level-lbs", getprop("consumables/fuel/tank[2]/level-lbs") + 5.55);
                        }
                    }
                    if ((getprop("consumables/fuel/tank/capacity-gal_us") <= getprop("consumables/fuel/tank/level-gal_us")) and (getprop("consumables/fuel/tank[2]/capacity-gal_us") <= getprop("consumables/fuel/tank[2]/level-gal_us"))) {
                        if (getprop("consumables/fuel/tank/level-gal_us") > getprop("consumables/fuel/tank/capacity-gal_us")) {
                            setprop("consumables/fuel/tank[1]/level-gal_us", (getprop("consumables/fuel/tank[1]/level-gal_us") + getprop("consumables/fuel/tank/level-gal_us") - getprop("consumables/fuel/tank/capacity-gal_us")));
                            setprop("consumables/fuel/tank/level-gal_us", getprop("consumables/fuel/tank/capacity-gal_us"));
                        }
                        if (getprop("consumables/fuel/tank[2]/level-gal_us") > getprop("consumables/fuel/tank[2]/capacity-gal_us")) {
                            setprop("consumables/fuel/tank[1]/level-gal_us", (getprop("consumables/fuel/tank[1]/level-gal_us") + getprop("consumables/fuel/tank[2]/level-gal_us") - getprop("consumables/fuel/tank[2]/capacity-gal_us")));
                            setprop("consumables/fuel/tank[2]/level-gal_us", getprop("consumables/fuel/tank[2]/capacity-gal_us"));
                        }
                        if (getprop("consumables/fuel/tank[1]/level-lbs") + 12 > getprop("services/fuel-truck/request-lbs") - getprop("consumables/fuel/tank/level-lbs") - getprop("consumables/fuel/tank[2]/level-lbs")) {
                            setprop("consumables/fuel/tank[1]/level-lbs", getprop("consumables/fuel/tank[1]/level-lbs") + 0.1);
                        } else {
                            setprop("consumables/fuel/tank[1]/level-lbs", getprop("consumables/fuel/tank[1]/level-lbs") + 11.1);
                        }
                    }
                setprop("services/fuel-truck/speed-text", math.round((getprop("services/fuel-truck/request-lbs")-getprop("consumables/fuel/total-fuel-lbs")) / 6660) ~ " min remaining");
                } else {
                    setprop("services/fuel-truck/transfer", 0);
                    setprop("services/fuel-truck/speed-text", " ");
                    setprop("services/fuel-truck/finished", 1);
                    screen.log.write("Refueling complete. " ~ math.round(getprop("consumables/fuel/total-fuel-lbs")) ~" Lbs. of fuel loaded.", 0, 0.584, 1);
                    if (getprop("aircraft/settings/gnd_autodisconnect") == 1) {
                        setprop("services/fuel-truck/connect", 0);
                        setprop("services/fuel-truck/enable", 0);
						if (getprop("services/payload/boardingcomplete") == 1 and getprop("services/payload/loadingcomplete") == 1 and getprop("services/catering/complete") == 1) {
							setprop("services/cones/cone1-enable", 0);
							setprop("services/cones/cone2-enable", 0);
							setprop("services/cones/coneLW-enable", 0);
							setprop("services/cones/coneRW-enable", 0);
							setprop("services/cones/coneTailL-enable", 0);
							setprop("services/cones/coneTailR-enable", 0);
						}
                    }
                }
            }
            
            if (getprop("services/fuel-truck/clean")) {
            
                if (getprop("consumables/fuel/total-fuel-lbs") > 200) {
                
                    setprop("consumables/fuel/tank/level-lbs", getprop("consumables/fuel/tank/level-lbs") - 3.7);
                    setprop("consumables/fuel/tank[1]/level-lbs", getprop("consumables/fuel/tank[1]/level-lbs") - 3.7);
                    setprop("consumables/fuel/tank[2]/level-lbs", getprop("consumables/fuel/tank[2]/level-lbs") - 3.7);
                    setprop("services/fuel-truck/speed-text", math.round(getprop("consumables/fuel/total-fuel-lbs") / 6660) ~ " min remaining");
                } else {
                    setprop("services/fuel-truck/clean", 0);
                    setprop("services/fuel-truck/speed-text", " ");
                    screen.log.write("Fuel tanks drained.", 0, 0.584, 1);
                    if (getprop("aircraft/settings/gnd_autodisconnect") == 1) {
                        setprop("services/fuel-truck/connect", 0);
                        setprop("services/fuel-truck/enable", 0);
                    }
                }	
            
            }
        } elsif (!(getprop("services/fuel-truck/enable")) and (getprop("services/fuel-truck/connect"))) {
            setprop("services/fuel-truck/connect", 0);
        }
        
        # External Ground Power controls
        # External power logic is controlled in Systems/Groundops/Groundservices.xml
        
        # Chocks
        # Chocks are controlling Yasim control inputs directly to apply the brakes of the associated gear. Brake properties are set in 777/Systems/Groundops/Groundservices.xml

        # De-icing Truck
		
		if (getprop("/services/deicing_truck/enable") and getprop("/services/deicing_truck/de-ice"))
		{		
			if (me.ice_time == 2){
				StartTimeText = getprop("sim/time/gmt");
                setprop("services/deicing_truck/truck/direction", 1);
                setprop("services/deicing_truck/truck[1]/direction", 1);
                setprop("services/deicing_truck/truck[2]/direction", 1);
                setprop("services/deicing_truck/truck[3]/direction", 1);
                setprop("services/deicing_truck/truck[4]/direction", 1);
                icetruck.move(1);
                icetruck1.move(1);
                icetruck2.move(1);
                icetruck3.move(1);
                icetruck4.move(1);
                icecrane1.move(1);
			}
            
            if (me.ice_time == 22){
                icecrane3.move(1);
            }
            
            if (me.ice_time == 32){
                icecrane4.move(1);
            }
            
            if (me.ice_time == 52) {
                icecrane2.move(1);
            }
            
            if (me.ice_time == 102) {
                icecrane.move(1);
            }
            
            if (me.ice_time == 202) {
                icedeicing.move(1);
                icedeicing1.move(1);
                icedeicing4.move(1);
            }
            
            if (me.ice_time == 222) {
                icedeicing3.move(1);
            }
            
            if (me.ice_time == 252) {
                icedeicing2.move(1);
            }
            
            if (me.ice_time == 1002){
                
                
                setprop("services/deicing_truck/truck/direction", -1);                
				icedeicing.move(0);
                icetruck.move(0);
                
                setprop("services/deicing_truck/truck[1]/direction", -1);
                icedeicing1.move(0);
                icetruck1.move(0);
                
                setprop("services/deicing_truck/truck[2]/direction", -1);
                icedeicing2.move(0);
                icetruck2.move(0);
                
                setprop("services/deicing_truck/truck[3]/direction", -1);
                icedeicing3.move(0);
                icetruck3.move(0);
                
                setprop("services/deicing_truck/truck[4]/direction", -1);
                icedeicing4.move(0);
                icetruck4.move(0);
			}
            
            if (me.ice_time == 1702){
				icecrane.move(0);
			}
				
			if (me.ice_time == 1752){
                icecrane2.move(0);
                icecrane1.move(0);
			}
            
            if (me.ice_time == 1772){
                icecrane4.move(0);
			}
            
            if (me.ice_time == 1782){
                icecrane3.move(0);
			}

			if (me.ice_time == 2002) {
				screen.log.write("De-icing on aircraft complete. Propylene glycol, type IV fluid applied at 75%.", 0.5, 0.9, 1.0);
                screen.log.write("De-icing started at " ~ StartTimeText ~ "UTC. Holdover time is 0 hours 45 minutes.", 0.5, 0.9, 1.0);
				setprop("services/deicing_truck/de-ice", 0);
                setprop("services/deicing_truck/truck/direction", 0);
                setprop("services/deicing_truck/truck[1]/direction", 0);
                setprop("services/deicing_truck/truck[2]/direction", 0);
                setprop("services/deicing_truck/truck[3]/direction", 0);
                setprop("services/deicing_truck/truck[4]/direction", 0);
                if (getprop("aircraft/settings/gnd_autodisconnect") == 1) {
                    setprop("services/deicing_truck/enable", 0);
                }
                #Enter true icing props here
			}
		
		} else {
			me.ice_time = 0;
		}
		
	me.ice_time += 1;
        
    }

};

var CateringLogic = func {
    if (OnBlocksTime != "") {
        if (       (getprop("services/catering/truck[0]/cargo/position-norm") == 1 and getprop("services/catering/truck[0]/weight-lbs") > 0)
                or (getprop("services/catering/truck[1]/cargo/position-norm") == 1 and getprop("services/catering/truck[1]/weight-lbs") > 0)
                or (getprop("services/catering/truck[2]/cargo/position-norm") == 1 and getprop("services/catering/truck[2]/weight-lbs") > 0)
                or (getprop("services/catering/truck[3]/cargo/position-norm") == 1 and getprop("services/catering/truck[3]/weight-lbs") > 0)
        ){
            setprop("services/catering/complete", 0);
            setprop("services/catering/loading", 2);
            if (getprop("services/catering/truck[0]/cargo/position-norm") == 1) {
                setprop("services/catering/truck[0]/complete", 0);
            } else {
                setprop("services/catering/truck[0]/complete", 1);
            }
            if (getprop("services/catering/truck[1]/cargo/position-norm") == 1) {
                setprop("services/catering/truck[1]/complete", 0);
            } else {
                setprop("services/catering/truck[1]/complete", 1);
            }
            if (getprop("services/catering/truck[2]/cargo/position-norm") == 1) {
                setprop("services/catering/truck[2]/complete", 0);
            } else {
                setprop("services/catering/truck[2]/complete", 1);
            }
            if (getprop("services/catering/truck[3]/cargo/position-norm") == 1) {
                setprop("services/catering/truck[3]/complete", 0);
            } else {
                setprop("services/catering/truck[3]/complete", 1);
            }
            var loadingtime = math.round(getprop("services/catering/weight-lbs") / 80 / 60 * getprop("services/payload/speed"));
            screen.log.write("Waste unloading started. Estimated time remaining: " ~ loadingtime ~ " minutes.", 0, 0.584, 1);
            setprop("services/catering/time_remaining", loadingtime ~ " min remaining");  
        } elsif (getprop("services/catering/weight-lbs") != 0) {
            #Try again in 10 seconds
            CateringStartUnloadingT = CurrentSecond + 10;
        } else {
            CateringStartUnloadingT = 0;
        }
    }
}

var JetwayConnect = func(door) {
    #This function uses the ability to connect the nearest animated jetway(s) to the aircraft. See fgdata/Nasal/Jetways.nas for full explanation.

    var coord = geo.aircraft_position();
    var jetwayhdg = getprop("orientation/heading-deg");
    var jetwaydoor = door;
    var jetwaylat = coord.apply_course_distance(jetwayhdg, -getprop("sim/model/door[" ~ door ~ "]/position-x-m"));
    var jetwaylon = coord.apply_course_distance(jetwayhdg + 90, getprop("sim/model/door[" ~ door ~ "]/position-y-m"));
    var jetwayhood = getprop("sim/model/door[" ~ door ~ "]/jetway-hood-deg");
    jetways.toggle_jetway_from_coord(jetwaydoor, jetwayhood, jetwayhdg, jetwaylat, jetwaylon);

}

var autoconnect = func {

    #Check if autoconnect is enabled in Aircraft Settings
    
    if (getprop("aircraft/settings/gnd_autoconnect") == 1) {
        #Function fires from listener when cutoff switches have been moved. Only proceed to autoconnect groundservices when below conditions are met.
        #To prevent unwanted firing after sim startup, autoconnect will only enable if more than 20 seconds have passed.
        if (getprop("aircaft/settings/autoconnect/force-start") or (getprop("controls/engines/engine[0]/cutoff") == 1 and getprop("controls/engines/engine[1]/cutoff") == 1 and getprop("controls/gear/brake-parking") == 1 and getprop("sim/time/elapsed-sec") > 20)) {
        
            #detect On Blocks Time
            
            OnBlocksTime = getprop("sim/time/gmt-string");
            OnBlocksSecond = getprop("sim/time/elapsed-sec");
            print("On Blocks Time detected at " ~ OnBlocksTime);
            setprop("sim/time/OnBlocksTime", OnBlocksTime);
			setprop("aircraft/settings/autoconnect/status", "Active: Connecting services");
			if (getprop("aircraft/settings/autoconnect/force-start") == 1) {
				setprop("aircraft/settings/autoconnect/force-start", 0);
			}
            
            #detect which services are available (based on in flight config or on default profile) and assign connection times (with a little randomisation)
            
            var GPU1Sel = getprop("aircraft/settings/autoconnect/GPU1");
            var GPU2Sel = getprop("aircraft/settings/autoconnect/GPU2");
            var ChockSel = getprop("aircraft/settings/autoconnect/Chocks");
            var ConeSel = getprop("aircraft/settings/autoconnect/Cones");
            var Jetway1Sel = getprop("aircraft/settings/autoconnect/Jetway1");
            var Jetway2Sel = getprop("aircraft/settings/autoconnect/Jetway2");
            var Stairs1Sel = getprop("aircraft/settings/autoconnect/Stairs1");
            var Stairs2Sel = getprop("aircraft/settings/autoconnect/Stairs2");
            var Stairs3Sel = getprop("aircraft/settings/autoconnect/Stairs3");
            var Stairs4Sel = getprop("aircraft/settings/autoconnect/Stairs4");
            var Catering1Sel = getprop("aircraft/settings/autoconnect/Catering1");
            var Catering2Sel = getprop("aircraft/settings/autoconnect/Catering2");
            var Catering3Sel = getprop("aircraft/settings/autoconnect/Catering3");
            var Catering4Sel = getprop("aircraft/settings/autoconnect/Catering4");
            var FuelTruckSel = getprop("aircraft/settings/autoconnect/FuelTruck");
            var FuelTruckPipeSel = getprop("aircraft/settings/autoconnect/FuelTruckPipe");
            var Bus1Sel = getprop("aircraft/settings/autoconnect/Bus1");
            var Bus2Sel = getprop("aircraft/settings/autoconnect/Bus2");
            var Baggage1Sel = getprop("aircraft/settings/autoconnect/Baggage1");
            var Baggage2Sel = getprop("aircraft/settings/autoconnect/Baggage2");
            var RealisticTiming = getprop("aircraft/settings/gnd_autoconnect_delay");
            
            #GPU
            
            if (GPU1Sel or GPU2Sel) {
                GPUBox = getprop("services/ext-pwr/enable");
                if (!RealisticTiming) {
                    GPUBoxT = OnBlocksSecond;
                } else {
                    GPUBoxT = math.round(OnBlocksSecond + 0 + rand() * 15); #Enable GPU box between 0" and 15" after OBT
                }
                
                if (GPU1Sel) {
                    GPU1 = getprop("services/ext-pwr/primary");
                    if (!RealisticTiming) {
                        GPU1T = OnBlocksSecond;
                    } else {
                        GPU1T = math.round(OnBlocksSecond + 15 + rand() * 45); #Enable GPU1 between 15" and 60" after on blocks time
                    }
                }
                
                if (GPU2Sel) {
                    GPU2 = getprop("services/ext-pwr/secondary");
                    if (GPU1T != 0) {
                        if (!RealisticTiming) {
                            GPU2T = OnBlocksSecond;
                        } else {
                            GPU2T = math.round(GPU1T + 5 + rand() * 15); #Enable GPU2 between 5" and 20" after GPU1T
                        }
                    } else {
                        if (!RealisticTiming) {
                            GPU2T = OnBlocksSecond;
                        } else {
                            GPU2T = math.round(OnBlocksSecond + 15 + rand() * 45); #Enable GPU2 between 15" and 60" after OBT
                        }
                    }
                }
            }
            
            # Chocks
            
            if (ChockSel) {
                ChockN = getprop("services/chocks/nose");
                if (!RealisticTiming) {
                    ChockNT = OnBlocksSecond;
                } else {
                    ChockNT = math.round(OnBlocksSecond + 10 + rand() * 50); #Enable Nose Chock between 10" and 1' after on blocks time
                }
                ChockL = getprop("services/chocks/left");
                if (!RealisticTiming) {
                    ChockLT = OnBlocksSecond;
                } else {
                    ChockLT = math.round(OnBlocksSecond + 30 + rand() * 90); #Enable Left Chock between 30" and 2' after OBT
                }
                ChockR = getprop("services/chocks/right");
                if (!RealisticTiming) {
                    ChockTT = OnBlocksSecond;
                } else {
                    ChockRT = math.round(OnBlocksSecond + 30 + rand() * 90); #Enable Right Chock between 30" and 2' after OBT
                }
            }
            
            # Cones
            
            if (ConeSel) {
                ConeL = getprop("services/cones/cone1-enable");
                if (!RealisticTiming) {
                    ConeLT = OnBlocksSecond;
                } else {
                    ConeLT = math.round(OnBlocksSecond + 60 + rand() * 180); #Enable Left Cones between 1' and 4' after OBT
                }
                ConeR = getprop("services/cones/cone2-enable");
                if (!RealisticTiming) {
                    ConeRT = OnBlocksSecond;
                } else {
                    ConeRT = math.round(OnBlocksSecond + 60 + rand() * 180); #Enable Right Cones between 1' and 4' after OBT
                }
				ConeLW = getprop("services/cones/coneLW-enable");
                if (!RealisticTiming) {
                    ConeLWT = OnBlocksSecond;
                } else {
                    ConeLWT = math.round(OnBlocksSecond + 30 + rand() * 210); #Enable Left Wing Cones between 30" and 4' after OBT
                }
                ConeRW = getprop("services/cones/coneRW-enable");
                if (!RealisticTiming) {
                    ConeRWT = OnBlocksSecond;
                } else {
                    ConeRWT = math.round(OnBlocksSecond + 30 + rand() * 240); #Enable Right Cones between 30" and 4'30" after OBT
                }
				ConeTailL = getprop("services/cones/coneTailL-enable");
                if (!RealisticTiming) {
                    ConeTailLT = OnBlocksSecond;
                } else {
                    ConeTailLT = math.round(OnBlocksSecond + 60 + rand() * 240); #Enable Left Tail Cone between 1' and 5' after OBT
                }
				
				ConeTailR = getprop("services/cones/coneTailR-enable");
                if (!RealisticTiming) {
                    ConeTailRT = OnBlocksSecond;
                } else {
                    ConeTailRT = math.round(ConeTailLT + 20 + rand() * 40); #Enable Right Tail Cone between 20" and 1' after Left Tail Cone
                }
            }
            
            # Jetways
            
            if (Jetway1Sel) {
                Jetway1 = getprop("services/payload/jetway1_enable");
                if (!RealisticTiming) {
                    Jetway1T = OnBlocksSecond;
                } else {
                    Jetway1T = math.round(OnBlocksSecond + 15 + rand() * 105); #Enable Front Jetway between 15" and 2' after OBT
                }
            }
            if (Jetway2Sel) {
                Jetway2 = getprop("services/payload/jetway2_enable");
                if (!RealisticTiming) {
                    Jetway2T = OnBlocksSecond;
                } else {
                    Jetway2T = math.round(Jetway1T + 15 + rand() * 75); #Enable Rear Jetway between 15" and 1'30" after the first jetway has connected (to make sure the first is out of the way before moving)
                }
            }
            
            # Stairs
            
            if (Stairs1Sel) {
                Stairs1 = getprop("services/stairs/stairs1_enable");
                if (!RealisticTiming) {
                    Stairs1T = OnBlocksSecond;
                } else {
                    Stairs1T = math.round(OnBlocksSecond + 120 + rand() * 240); #Enable Stairs 1L between 2' and 6' after OBT
                }
            }
            if (Stairs2Sel) {
                Stairs2 = getprop("services/stairs/stairs2_enable");
                if (Stairs1T != 0) {
                    if (!RealisticTiming) {
                        Stairs2T = OnBlocksSecond;
                    } else {
                        Stairs2T = math.round(Stairs1T + 10 + rand() * 90); #Enable Rear Stairs between 10" and 1'40" after Stairs 1L has connected
                    }
                } else {
                    if (!RealisticTiming) {
                        Stairs2T = OnBlocksSecond;
                    } else {
                        Stairs2T = math.round(OnBlocksSecond + 120 + rand() * 240); #Enable Stairs 2L between 2' and 6' after OBT. (if stairs 1L is not selected)
                    }
                }
            }
            
            if (Stairs3Sel) {
                Stairs3 = getprop("services/stairs/stairs3_enable");
                if (!RealisticTiming) {
                    Stairs3T = OnBlocksSecond;
                } else {
                    Stairs3T = math.round(OnBlocksSecond + 180 + rand() * 240); #Enable Stairs 4L between 3' and 7' after OBT
                }
            }
            
            if (Stairs4Sel) {
                Stairs4 = getprop("services/stairs/stairs4_enable");
                if (!RealisticTiming) {
                    Stairs4T = OnBlocksSecond;
                } else {
                    Stairs4T = math.round(OnBlocksSecond + 180 + rand() * 240); #Enable Stairs 4L between 3' and 6' after OBT
                }
            }
            
            # Busses - time is calculated on expected deboarding time
            
            if (Jetway1T != 0 or Jetway2T != 0) {
            
                if (Bus1Sel) {
                    Bus1 = getprop("services/bus/bus1-enable");
                    if (!RealisticTiming) {
                        Bus1T = OnBlocksSecond;
                    } else {
                        Bus1T = math.round(math.avg(Jetway1T, Jetway2T) + 10 + rand() * 60);
                    }
                }
                
                if (Bus2Sel) {
                    Bus2 = getprop("services/bus/bus2-enable");
                    if (!RealisticTiming) {
                        Bus2T = OnBlocksSecond;
                    } else {
                        Bus2T = math.round(math.avg(Jetway1T, Jetway2T) + 30 + rand() * 60);
                    }
                }
            
            } elsif (Stairs1T != 0 or Stairs2T != 0) {
                if (Bus1Sel) {
                    Bus1 = getprop("services/bus/bus1-enable");
                    if (!RealisticTiming) {
                        Bus1T = OnBlocksSecond;
                    } else {
                        Bus1T = math.round(math.avg(Stairs1T, Stairs2T) + rand() * 60);
                    }
                }
                
                if (Bus2Sel) {
                    Bus2 = getprop("services/bus/bus2-enable");
                    if (!RealisticTiming) {
                        Bus2T = OnBlocksSecond;
                    } else {
                        Bus2T = math.round(math.avg(Stairs1T, Stairs2T, Stairs3T, Stairs4T) + rand() * 90);
                    }
                }
            } else {
                if (Bus1Sel) {
                    Bus1 = getprop("services/bus/bus1-enable");
                    if (!RealisticTiming) {
                        Bus1T = OnBlocksSecond;
                    } else {
                        Bus1T = math.round(OnBlocksSecond + 120 + rand() * 60);
                    }
                }
                
                if (Bus2Sel) {
                    Bus2 = getprop("services/bus/bus2-enable");
                    if (!RealisticTiming) {
                        Bus2T = OnBlocksSecond;
                    } else {
                        Bus2T = math.round(OnBlocksSecond + 150 + rand() * 60);
                    }
                }
            }
            
            # Baggage trucks
            
            if (Baggage1Sel) {
                Baggage1 = getprop("services/payload/baggage-truck1-enable");
                if (!RealisticTiming) {
                    Baggage1T = OnBlocksSecond;
                } else {
                    Baggage1T = math.round(OnBlocksSecond + 60 + rand() * 360); #Enable Front Baggage Truck between 1' and 7' after OBT
                }
            }
            if (Baggage2Sel) {
                Baggage2 = getprop("services/payload/baggage-truck2-enable");
                if (!RealisticTiming) {
                    Baggage2T = OnBlocksSecond;
                } else {
                    Baggage2T = math.round(OnBlocksSecond + 60 + rand() * 360); #Enable Rear Baggage Truck between 1' and 7' after OBT
                }
            }
            
            # Catering trucks
            
            #Set all catering trucks to enabled immediately, connection comes when deboarding is finished (see code above).
            if (Catering1Sel) {
                setprop("services/catering/truck[0]/enabled", 1);
                Catering1T = 5 + rand() * 55;
            }
            
            if (Catering2Sel) {
                setprop("services/catering/truck[1]/enabled", 1);
                Catering2T = 5 + rand() * 55;
            }
            
            if (Catering3Sel) {
                setprop("services/catering/truck[2]/enabled", 1);
                Catering3T = 5 + rand() * 55;
            }
            
            if (Catering4Sel) {
                setprop("services/catering/truck[3]/enabled", 1);
                Catering4T = 5 + rand() * 55;
            }
            
            # Fuel Truck
            
            if (FuelTruckSel) {
                FuelTruck = getprop("services/fuel-truck/enable");
                if (!RealisticTiming) {
                    FuelTruckT = OnBlocksSecond;
                } else {
                    FuelTruckT = math.round(OnBlocksSecond + 300 + rand() * 600); #Connect Fuel Truck between 5' and 15' after OBT
                }
                if (FuelTruckPipeSel) {
                    FuelTruckPipe = getprop("services/fuel-truck/connect");
                    if (!RealisticTiming) {
                        FuelTruckPipeT = OnBlocksSecond + 1;
                    } else {
                        FuelTruckPipeT = math.round(FuelTruckT + 60 + rand() * 120); #Connect Fuel Pipe between 1' and 3' after truck placement.
                    }
                }
            }
        }
    }
}

var stopautoconnect = func {
	GPU1T = 0;
	GPU2T = 0;
	GPUBoxT = 0;
	ChockLT = 0;
	ChockRT = 0;
	ChockNT = 0;
	ConeLT = 0;
	ConeRT = 0;
	ConeLWT = 0;
	ConeRWT = 0;
	ConeTailLT = 0;
	ConeTailRT = 0;
	Bus1T = 0;
	Bus2T = 0;
	Jetway1T = 0;
	Jetway2T = 0;
	Stairs1T = 0;
	Stairs2T = 0;
	Stairs3T = 0;
	Stairs4T = 0;
	Baggage1T = 0;
	Baggage2T = 0;
	Catering1T = 0;
	Catering2T = 0;
	Catering3T = 0;
	Catering4T = 0;
	FuelTruckT = 0;
	FuelTruckPipeT = 0;
	DeBoardingTime = 0;
	CateringStartUnloadingT = 0;
	OnBlocksTime = "";
	StatusUpdate = 0;
	setprop("aircraft/settings/autoconnect/force-stop", 0);
	setprop("aircraft/settings/autoconnect/status", "Stopped");
	print("Autoconnection of ground services stopped.");
}

var _timer_gsv = maketimer(0.1, func{ground_services.update()});

var _startstop_gsv = func() {
    if (getprop("gear/gear[0]/wow") == 1) {
        _timer_gsv.start();
    } else {
        _timer_gsv.stop();
    }
}

setlistener("sim/signals/fdm-initialized", func {
    ground_services.init();
    print("Ground Services ..... Initialized");
});

setlistener("aircraft/settings/autoconnect/launch", func{
    setlistener("controls/engines/engine/cutoff", func{
        if (getprop("controls/engines/engine/cutoff")) {
			if (OnBlocksTime == "") {
				autoconnect();
			}
		} elsif (!getprop("controls/engines/engine[1]/cutoff")) { # Reset the on blocks time if both engines are started again.
			OnBlocksTime = "";
			setprop("aircraft/settings/autoconnect/status", "Inactive");
		}
    });
    setlistener("controls/engines/engine[1]/cutoff", func{
		if (getprop("controls/engines/engine[1]/cutoff")) {
			if (OnBlocksTime == "") {
				autoconnect();
			}
		} elsif (!getprop("controls/engines/engine/cutoff")) { # Reset the on blocks time if both engines are started again.
			OnBlocksTime = "";
			setprop("aircraft/settings/autoconnect/status", "Inactive");
		}
    });
    setlistener("aircraft/settings/autoconnect/force-start", func{
		if (getprop("aircraft/settings/autoconnect/force-start") == 1) {
			autoconnect();
		}
	});
	setlistener("aircraft/settings/autoconnect/force-stop", func{
		if (getprop("aircraft/settings/autoconnect/force-stop") == 1) {
			stopautoconnect();
		}
	});
    print("Autoconnect ..... Ready");
});

setlistener("gear/gear[0]/wow", func {_startstop_gsv()});