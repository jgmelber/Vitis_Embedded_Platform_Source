#
# (c) Copyright 2021 Xilinx, Inc. All rights reserved.
#
# This file contains confidential and proprietary information
# of Xilinx, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
#
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# Xilinx, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# 
# (2) Xilinx shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or Xilinx had been advised of the
# possibility of the same.
#
# CRITICAL APPLICATIONS
# Xilinx products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of Xilinx products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
#
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
#

set_param bd.addr.smcx_func.route_dfx_apertures true
file mkdir build 
cd build
source ../xsa_scripts/project.tcl
source ../xsa_scripts/dr.bd.tcl
source ../xsa_scripts/pfm_decls.tcl
#For Questa Simulator
source ../data/questa_sim.tcl

#Generating Wrapper
make_wrapper -files [get_files ./my_project/my_project.srcs/sources_1/bd/vitis_design/vitis_design.bd] -top
add_files -norecurse ./my_project/my_project.srcs/sources_1/bd/vitis_design/hdl/vitis_design_wrapper.v

#Generating Target
generate_target all [get_files ./my_project/my_project.srcs/sources_1/bd/vitis_design/vitis_design.bd]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
set_property top vitis_design_wrapper [current_fileset] 

# Ensure that your top of synthesis module is also set as top for simulation
set_property top vitis_design_wrapper [get_filesets sim_1]

# Generate simulation top for your entire design which would include
# aggregated NOC in the form of xlnoc.bd
generate_switch_network_for_noc
update_compile_order -fileset sim_1

# Set the auto-generated <rtl_top>_sim_wrapper as the sim top
set_property top vitis_design_wrapper_sim_wrapper [get_filesets sim_1]
import_files -fileset sim_1 -norecurse ./my_project/my_project.srcs/sources_1/common/hdl/vitis_design_wrapper_sim_wrapper.v
update_compile_order -fileset sim_1

#Generate the final simulation script which will compile
# the <syn_top>_sim_wrapper and xlnoc.bd modules also
launch_simulation -scripts_only
launch_simulation -step compile
launch_simulation -step elaborate

#Generating Emulation XSA
set_property platform.platform_state "pre_synth" [current_project]
file mkdir hw_emu
write_hw_platform -hw_emu -file hw_emu/hw_emu.xsa

#Calling Implementation for HW XSA
set_property platform.platform_state "impl" [current_project]
create_pr_configuration -name config_1 -partitions [list vitis_design_i/VitisRegion:VitisRegion_inst_0 ]
set_property PR_CONFIGURATION config_1 [get_runs impl_1]

launch_runs synth_1 -jobs 20
wait_on_run synth_1

launch_runs impl_1 -to_step write_device_image -jobs 10
wait_on_run impl_1
open_run impl_1
write_hw_platform -force -fixed -static -file static.xsa
file mkdir rp
write_hw_platform  -rp vitis_design_i/VitisRegion rp/rp.xsa

#generate README.hw
set board vck190

set fd [open README.hw w] 

set board [lindex $argv 0]

puts $fd "##########################################################################"
puts $fd "This is a brief document containing design specific details for : ${board}"
puts $fd "This is auto-generated by Petalinux ref-design builder created @ [clock format [clock seconds] -format {%a %b %d %H:%M:%S %Z %Y}]"
puts $fd "##########################################################################"

set board_part [get_board_parts [current_board_part -quiet]]
if { $board_part != ""} {
  puts $fd "BOARD: $board_part" 
}

set design_name [get_property NAME [get_bd_designs]]
puts $fd "BLOCK DESIGN: $design_name" 

set columns {%40s%30s%15s%50s}
puts $fd [string repeat - 150]
puts $fd [format $columns "MODULE INSTANCE NAME" "IP TYPE" "IP VERSION" "IP"]
puts $fd [string repeat - 150]
foreach ip [get_ips] {
  set catlg_ip [get_ipdefs -all [get_property IPDEF $ip]] 
  puts $fd [format $columns [get_property NAME $ip] [get_property NAME $catlg_ip] [get_property VERSION $catlg_ip] [get_property VLNV $catlg_ip]]
}
close $fd