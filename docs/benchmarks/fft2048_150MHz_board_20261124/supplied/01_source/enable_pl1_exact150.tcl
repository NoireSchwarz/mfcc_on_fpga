# Enable the PS-to-PL boundary and verify the dedicated 100 MHz PL1 source.
# The implemented design multiplies this clock by 12/8 in an MMCM, yielding
# exactly 150 MHz. No processor, DDR, QSPI or boot-firmware state is changed.
set record_path [lindex $argv 0]
connect -url tcp:localhost:45678
targets -set -filter {name == "PSU"}

# Request PL power-up / isolation removal, matching the exported PS init flow.
mwr 0xFFD80118 0x00800000
mwr 0xFFD80120 0x00800000
set deadline [expr {[clock milliseconds] + 5000}]
after 20
while {1} {
    set pending [lindex [mrd -value 0xFFD80110] 0]
    if {($pending & 0x00800000) == 0} {break}
    if {[clock milliseconds] > $deadline} {error "PL power-up/isolation request was not acknowledged"}
    after 10
}

# PL1_REF_CTRL: active, IOPLL source, divisor0=10, divisor1=1 => 100 MHz.
set expected 0x01010A00
set mask     0x013F3F07
set before [lindex [mrd -value 0xFF5E00C4] 0]
if {($before & $mask) != ($expected & $mask)} {
    mwr 0xFF5E00C4 $expected
}
set actual [lindex [mrd -value 0xFF5E00C4] 0]
set iopll_control [lindex [mrd -value 0xFF5E0020] 0]
set iopll_fraction [lindex [mrd -value 0xFF5E0028] 0]
if {($actual & $mask) != ($expected & $mask)} {error "PL1_REF_CTRL readback is not the verified 100 MHz setting"}
if {($iopll_control & 0x00017F00) != 0x00013C00 || ($iopll_fraction & 0x80000000) != 0} {
    error "IOPLL configuration differs from the verified integer 1 GHz source"
}
set record [format "PL1_REF_CTRL_before=0x%08x PL1_REF_CTRL_after=0x%08x IOPLL_CTRL=0x%08x IOPLL_FRAC_CFG=0x%08x PL1_Hz=100000000 MMCM_MULT=12 MMCM_DIV=8 fabric_Hz=150000000 pending=0x%08x" $before $actual $iopll_control $iopll_fraction $pending]
puts $record
if {$record_path ne ""} {
    set f [open $record_path w]
    puts $f $record
    close $f
}
disconnect
