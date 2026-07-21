#==============================================================================
#  Project     : DLX Processor Implementation
#  File        : synthesis_template.tcl
#  Description : TCL file used to run the synthesis of the DLX processor
#
#  Group Name  : Group 02
#  Members     : Sabina Sarcuni
#                Leonadro Gallina
#                Francesco Mignone
#
#  Supervisor  : Mariagrazia Graziano, Giavanna Turvani
#  Institution : Polytechnic of Turin, Italy
#
#  Created     : 11 July 2025
#  Last Edited : 11 July 2025
#
#  Notes       : - 5-stage pipeline (IF, ID, EX, MEM, WB)
#                - Supports basic instruction set: R-type, I-type, J-type
#                - Hazard detection and forwarding implemented
#                - Designed for simulation in ModelSim/Questasim
#
#==============================================================================
# Available variables from the bash script
setMultiCpuUsage -localCpu 8 -cpuAutoAdjust true

# Set the environment
# Load the design
source ./scripts/scripts_templates/DLX.globals
init_design
getIoFlowFlag
setIoFlowFlag 0
floorPlan -coreMarginsBy die -site FreePDK45_38x28_10R_NP_162NW_34O -r 1.0 0.6 5 5 5 5
uiSetTool select
getIoFlowFlag
fit
saveDesign ./physical_design/1_stage_init.enc

# Power Rings creation
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
# Power ring creation
setAddRingMode -ring_target default -extend_over_row 0 -ignore_rows 0 -avoid_short 0 -skip_crossing_trunks none -stacked_via_top_layer metal10 -stacked_via_bottom_layer metal1 -via_using_exact_crossover_size 1 -orthogonal_only true -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape }

addRing -nets {vdd gnd} -type core_rings -follow core -layer {top metal9 bottom metal9 left metal10 right metal10} -width {top 0.8 bottom 0.8 left 0.8 right 0.8} -spacing {top 0.8 bottom 0.8 left 0.8 right 0.8} -offset {top 1.8 bottom 1.8 left 1.8 right 1.8} -center 1 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

# Stripe creation
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0

setAddStripeMode -ignore_block_check false -break_at none -route_over_rows_only false -rows_without_stripes_only false -extend_to_closest_target none -stop_at_last_wire_for_area false -partial_set_thru_domain false -ignore_nondefault_domains false -trim_antenna_back_to_shape none -spacing_type edge_to_edge -spacing_from_block 0 -stripe_min_length stripe_width -stacked_via_top_layer metal10 -stacked_via_bottom_layer metal1 -via_using_exact_crossover_size false -split_vias false -orthogonal_only true -allow_jog { padcore_ring  block_ring } -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape   }

addStripe -nets {vdd gnd} -layer metal10 -direction vertical -width 0.8 -spacing 0.8 -set_to_set_distance 20 -start_from left -start_offset 15 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit metal10 -padcore_ring_bottom_layer_limit metal1 -block_ring_top_layer_limit metal10 -block_ring_bottom_layer_limit metal1 -use_wire_group 0 -snap_wire_center_to_grid None

saveDesign ./physical_design/2_stage_route_placement.enc

# Placement and route
setSrouteMode -viaConnectToShape { noshape }

sroute -connect { blockPin padPin padRing corePin floatingStripe } -layerChangeRange { metal1(1) metal10(10) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin followpin } -allowJogging 1 -crossoverViaLayerRange { metal1(1) metal10(10) } -nets { vdd gnd } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { metal1(1) metal10(10) }

setPlaceMode -prerouteAsObs {1 2 3 4 5 6 7 8}
setRouteMode -earlyGlobalHonorMsvRouteConstraint false -earlyGlobalRoutePartitionPinGuide true

setEndCapMode -reset
setEndCapMode -boundary_tap false
setNanoRouteMode -quiet -droutePostRouteSpreadWire 1
setNanoRouteMode -quiet -timingEngine {}
setUsefulSkewMode -maxSkew false -noBoundary false -useCells {CLKBUF_X3 CLKBUF_X2 CLKBUF_X1 BUF_X32 BUF_X16 BUF_X8 BUF_X4 BUF_X2 BUF_X1 INV_X32 INV_X16 INV_X8 INV_X4 INV_X2 INV_X1} -maxAllowedDelay 1

setPlaceMode -reset
setPlaceMode -congEffort auto -timingDriven 1 -clkGateAware 1 -powerDriven 0 -ignoreScan 1 -reorderScan 1 -ignoreSpare 0 -placeIOPins 1 -moduleAwareSpare 0 -maxRouteLayer 6 -preserveRouting 1 -rmAffectedRouting 0 -checkRoute 0 -swapEEQ 0

setPlaceMode -fp false
place_design

saveDesign ./physical_design/3_stage_preCTS.enc
setDelayCalMode -siAware false

timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 10 -prefix DLX_preCTS_setup -outDir ./physical_design/timingReport
timeDesign -preCTS -hold -pathReports -slackReports -numPaths 10 -prefix DLX_preCTS_hold -outDir ./physical_design/timingReport

report_timing > ./physical_design/report_timing_preCTS.txt

# CLock tree

create_ccopt_clock_tree_spec
set_ccopt_property target_max_trans 0.05
set_ccopt_property target_skew 0.02
ccopt_design

timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 10 -prefix DLX_postCTS_setup -outDir ./physical_design/timingReport
timeDesign -postCTS -hold -pathReports -slackReports -numPaths 10 -prefix DLX_postCTS_hold -outDir ./physical_design/timingReport

saveDesign ./physical_design/4_stage_postCTS.enc

optDesign -postCTS
getFillerMode -quiet
addFiller -cell FILLCELL_X1 FILLCELL_X8 FILLCELL_X4 FILLCELL_X32 FILLCELL_X2 FILLCELL_X16 -prefix FILLER

saveDesign ./physical_design/5_stage_post_filler.enc

#Routing
setNanoRouteMode -quiet -routeTopRoutingLayer 6
setNanoRouteMode -quiet -routeBottomRoutingLayer default
setNanoRouteMode -quiet -drouteEndIteration default
setNanoRouteMode -quiet -routeWithTimingDriven false
setNanoRouteMode -quiet -routeWithSiDriven false
routeDesign -globalDetail

redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -pathReports -drvReports -slackReports -numPaths 10 -prefix DLX_preRoute_setup -outDir ./physical_design/timingReport
timeDesign -postRoute -hold -pathReports -slackReports -numPaths 10 -prefix DLX_preRoute_hold -outDir ./physical_design/timingReport

optDesign -postRoute
optDesign -postRoute -hold

saveDesign ./physical_design/5_stage_postRoute.enc

# Reports
win
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -pathReports -drvReports -slackReports -numPaths 10 -prefix DLX_postRoute_setup -outDir ./physical_design/timingReport
timeDesign -postRoute -hold -pathReports -slackReports -numPaths 10 -prefix DLX_postRoute_hold -outDir ./physical_design/timingReport

getAnalysisMode -checkType
report_timing -max_paths 10000 -max_slack 0.75 -path_exceptions all -late > ./physical_design/final_report_timing.txt
report_timing -machine_readable -max_paths 10000 -max_slack 0.75 -path_exceptions all -late > ./physical_design/top.mtarpt

## report clock trees and skew groups
report_ccopt_clock_trees -file ./physical_design/clock_trees.txt
report_ccopt_skew_groups -file ./physical_design/skew_groups.txt
report_clock > ./physical_design/final_clock_report.txt

load_timing_debug_report -name default_report ./physical_design/top.mtarpt
get_power_analysis_mode -leakage_power_view -quiet
get_power_analysis_mode -analysis_view -quiet
get_power_analysis_mode -state_dependent_leakage -quiet
get_power_analysis_mode -dynamic_power_view -quiet
get_power_analysis_mode -analysis_view -quiet
extractRC

rcOut -spef ./physical_design/DLX.spef
verifyConnectivity -type all -error 1000 -warning 50
report_power > ./physical_design/final_power_report.txt
report_area > ./physical_design/final_area_report.txt
report_constaints -all_violaters ./physical_design/final_constraint_report.txt
reportGateCount -level 5 -limit 100 -outfile ./physical_design/DLX.gateCount
saveNetlist ./physical_design/DLX.v
all_hold_analysis_views
all_setup_analysis_views
write_sdf  -ideal_clock_network ./physical_design/DLX.sdf

saveDesign ./physical_design/6_stage_afterAll.enc

# # Test to extract an image of the floorplan
# setDrawView -quiet -view floorplan
# setDrawMode -quiet -drawMode floorplan
# fit
# streamOut watever -mapFile ./physical_design/streamOut.map -libName DesignLib -structureName topmain -units 2000 -mode ALL

exit