set evidence D:/KV260_MFCC/33_fft2048_latest_9be89af_150mhz_20261124
set repo D:/Documents/ChatGPT/MFCC/mfcc_on_fpga_latest
set expected_commit 9be89af18ca9cf42e6f47990d7d1b781afb47615
set actual_commit [string trim [exec git -C $repo rev-parse HEAD]]
if {$actual_commit ne $expected_commit} {error "Git commit mismatch: $actual_commit"}
if {[string trim [exec git -C $repo status --porcelain]] ne ""} {error "Git working tree is not clean"}
file mkdir [file join $evidence temp]
set ::env(TEMP) [file join $evidence temp]
set ::env(TMP) $::env(TEMP)
set_param general.maxThreads 1

# Package only a test wrapper around the unmodified latest FFT hierarchy.
create_project package_latest [file join $evidence build package_latest] -part xck26-sfvc784-2LV-c -force
set fft_files [list \
    [file join $repo src work FFT512 WROM2048.v] \
    [file join $repo src work FFT512 fft_bram_1w1r.v] \
    [file join $repo src work FFT512 radix2_4_core complex_twiddle_mul.v] \
    [file join $repo src work FFT512 radix2_4_core fft_merge_kernel.v] \
    [file join $repo src work FFT512 radix2_4_core radix2_merge_stage.v] \
    [file join $repo src work FFT512 radix2_4_core radix4_merge_stage.v] \
    [file join $repo src work FFT512 radix_16_core mpuc541.v] \
    [file join $repo src work FFT512 radix_16_core mpuc1307.v] \
    [file join $repo src work FFT512 radix_16_core mpuc707.v] \
    [file join $repo src work FFT512 radix_16_core mpuc924_383.v] \
    [file join $repo src work FFT512 radix_16_core fft16.v] \
    [file join $repo src work FFT512 radix_16_256_core bufram256c.v] \
    [file join $repo src work FFT512 radix_16_256_core cnorm.v] \
    [file join $repo src work FFT512 radix_16_256_core ram256.v] \
    [file join $repo src work FFT512 radix_16_256_core ram2x256.v] \
    [file join $repo src work FFT512 radix_16_256_core rotator256_v.v] \
    [file join $repo src work FFT512 radix_16_256_core fft256_config.v] \
    [file join $repo src work FFT512 radix_16_256_core fft256.v] \
    [file join $repo src work FFT512 fft_16_64.v] \
    [file join $repo src work FFT512 fft256_1024.v] \
    [file join $repo src work FFT512 fft2x.v] \
    [file join $repo src work FFT512 fft_tree_bram_engine.v] \
    [file join $repo src work FFT512 fft512.v] \
    [file join $evidence src bench_transform_latest.v]]
add_files $fft_files
add_files [list [file join $repo WROM2048_cos.mem] [file join $repo WROM2048_sin.mem]]
set_property top bench_transform [current_fileset]
set ip_repo [file join $evidence packaged_ip]
ipx::package_project -root_dir $ip_repo -vendor kv260.local -library benchmark -taxonomy /UserIP -import_files -set_current true
set core [ipx::current_core]
set_property name transform_fft2048_latest $core
set_property display_name "FFT2048 latest Git 9be89af" $core
set_property version 1.0 $core
foreach {parameter value} [list KIND 0 N 2048] {
    set p [ipx::get_user_parameters $parameter -of_objects $core]
    if {[llength $p]} {set_property value $value $p}
    set p [ipx::get_hdl_parameters $parameter -of_objects $core]
    if {[llength $p]} {set_property value $value $p}
}
ipx::associate_bus_interfaces -busif S_AXIS -clock clk $core
ipx::associate_bus_interfaces -busif M_AXIS -clock clk $core
set freq [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk -of_objects $core]]
set_property value 149998501 $freq
ipx::check_integrity -quiet $core
ipx::save_core $core
close_project

# Create the KV260 JTAG harness. All benchmark logic is clocked by the same
# Clocking Wizard output: PS PL1 100 MHz multiplied by 3/2 to exact 150 MHz.
create_project latest_fft2048 [file join $evidence build latest_fft2048] -part xck26-sfvc784-2LV-c -force
set_property board_part xilinx.com:kv260_som:part0:1.4 [current_project]
set_property ip_repo_paths $ip_repo [current_project]
update_ip_catalog
add_files [list \
    D:/KV260_MFCC/32_fft2048_150mhz_board_20261123/project/bench_kv260/rtl/bench_engine.v \
    D:/KV260_MFCC/32_fft2048_150mhz_board_20261123/project/bench_kv260/rtl/kv260_bench_top.v]
set_property verilog_define [list "BENCH_SIGNATURE=32'h26000800" BENCH_LARGE BENCH_2048] [current_fileset]
create_bd_design bench_system
set ps [create_bd_cell -type ip -vlnv [lindex [get_ipdefs -all xilinx.com:ip:zynq_ultra_ps_e:*] end] ps]
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1"} $ps
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 0 CONFIG.PSU__USE__M_AXI_GP1 0 CONFIG.PSU__USE__M_AXI_GP2 0 \
    CONFIG.PSU__FPGA_PL1_ENABLE 1 CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ 100] $ps
set clkgen [create_bd_cell -type ip -vlnv [lindex [get_ipdefs -all xilinx.com:ip:clk_wiz:*] end] clkgen]
# Vivado's KV260 BD metadata rounds the register-proven 100 MHz PL1 source to
# 99.999001 MHz. Match that metadata for BD validation, but explicitly fix the
# hardware MMCM ratio to 12/8. On the board the actual register clock therefore
# remains exactly 100 * 12 / 8 = 150 MHz.
set_property -dict [list CONFIG.PRIM_IN_FREQ 99.999001 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 149.998501 \
    CONFIG.USE_RESET false CONFIG.OVERRIDE_MMCM true CONFIG.MMCM_DIVCLK_DIVIDE 1 \
    CONFIG.MMCM_CLKFBOUT_MULT_F 12.000 CONFIG.MMCM_CLKOUT0_DIVIDE_F 8.000] $clkgen
connect_bd_net [get_bd_pins ps/pl_clk1] [get_bd_pins clkgen/clk_in1]
set master [create_bd_cell -type ip -vlnv [lindex [get_ipdefs -all xilinx.com:ip:jtag_axi:*] end] usb_master]
set memory [create_bd_cell -type ip -vlnv [lindex [get_ipdefs -all xilinx.com:ip:axi_bram_ctrl:*] end] memory_controller]
set_property -dict [list CONFIG.DATA_WIDTH 32 CONFIG.SINGLE_PORT_BRAM 1 CONFIG.PROTOCOL AXI4 CONFIG.READ_LATENCY 2] $memory
set algorithm [create_bd_cell -type ip -vlnv kv260.local:benchmark:transform_fft2048_latest:1.0 algorithm]
set_property -dict [list CONFIG.KIND 0 CONFIG.N 2048] $algorithm
set bus_reset [create_bd_port -dir I -type rst bus_resetn]
set_property CONFIG.POLARITY ACTIVE_LOW $bus_reset
set core_reset [create_bd_port -dir I -type rst core_resetn]
set_property CONFIG.POLARITY ACTIVE_LOW $core_reset
connect_bd_net [get_bd_pins clkgen/clk_out1] [get_bd_pins usb_master/aclk] [get_bd_pins memory_controller/s_axi_aclk] [get_bd_pins algorithm/clk]
connect_bd_net $bus_reset [get_bd_pins usb_master/aresetn] [get_bd_pins memory_controller/s_axi_aresetn]
connect_bd_net $core_reset [get_bd_pins algorithm/resetn]
connect_bd_intf_net [get_bd_intf_pins usb_master/M_AXI] [get_bd_intf_pins memory_controller/S_AXI]
set ext [create_bd_port -dir O -type clk fabric_clk]
set_property -dict [list CONFIG.FREQ_HZ 149998501 CONFIG.ASSOCIATED_BUSIF S_AXIS_0:M_AXIS_0 CONFIG.ASSOCIATED_RESET bus_resetn:core_resetn] $ext
connect_bd_net $ext [get_bd_pins clkgen/clk_out1]
set ext [create_bd_port -dir O -from 31 -to 0 error_flags]
connect_bd_net $ext [get_bd_pins algorithm/error_flags]
set ext [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 memory]
set_property -dict [list CONFIG.MASTER_TYPE BRAM_CTRL CONFIG.READ_WRITE_MODE READ_WRITE] $ext
connect_bd_intf_net $ext [get_bd_intf_pins memory_controller/BRAM_PORTA]
set ext [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_0]
set_property -dict [list CONFIG.TDATA_NUM_BYTES 2 CONFIG.HAS_TREADY 1 CONFIG.HAS_TLAST 0 CONFIG.FREQ_HZ 149998501] $ext
connect_bd_intf_net $ext [get_bd_intf_pins algorithm/S_AXIS]
set ext [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_0]
set_property CONFIG.FREQ_HZ 149998501 $ext
connect_bd_intf_net $ext [get_bd_intf_pins algorithm/M_AXIS]
assign_bd_address -target_address_space [get_bd_addr_spaces usb_master/Data] -offset 0x00000000 -range 0x00010000 [get_bd_addr_segs memory_controller/S_AXI/Mem0]
validate_bd_design
save_bd_design
generate_target all [get_files bench_system.bd]
set wrappers [make_wrapper -files [get_files bench_system.bd] -top]
add_files $wrappers
set_property top kv260_bench_top [current_fileset]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 1
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed: $synth_status"}
open_run synth_1
report_utilization -file [file join $evidence synthesis_utilization.rpt]
report_utilization -hierarchical -file [file join $evidence synthesis_hierarchical.rpt]
report_timing_summary -file [file join $evidence synthesis_timing.rpt]
close_design

launch_runs impl_1 -to_step route_design -jobs 1
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed: $impl_status"}
open_run impl_1
report_utilization -file [file join $evidence utilization_post_route.rpt]
report_utilization -hierarchical -file [file join $evidence utilization_hierarchical_post_route.rpt]
report_timing_summary -delay_type min_max -max_paths 20 -file [file join $evidence timing_post_route.rpt]
report_timing -delay_type max -max_paths 50 -path_type full_clock_expanded -input_pins -file [file join $evidence setup_paths_post_route.rpt]
report_route_status -file [file join $evidence route_status.rpt]
report_drc -file [file join $evidence drc_post_route.rpt]
write_checkpoint -force [file join $evidence fft2048_latest_exact150_routed.dcp]
set setup [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
set wns [get_property SLACK $setup]
set whs [get_property SLACK $hold]
set f [open [file join $evidence result.txt] w]
puts $f "git_commit=$actual_commit"
puts $f "architecture=fft512_to_fft_tree_bram_engine_to_fft2x"
puts $f "frequency_hz=150000000"
puts $f "WNS_ns=$wns"
puts $f "WHS_ns=$whs"
puts $f "synthesis_status=$synth_status"
puts $f "implementation_status=$impl_status"
close $f
if {$wns < 0 || $whs < 0} {error "Latest architecture timing failed: WNS=$wns WHS=$whs"}
write_bitstream -force [file join $evidence kv260_fft2048_latest_exact150.bit]
puts "LATEST_ARCHITECTURE_EXACT150_PASS WNS=$wns WHS=$whs"
exit
