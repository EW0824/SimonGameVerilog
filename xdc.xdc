##=======================================================================
## Basys3-revB constraints for simon_game_top.v
## Using DIP switches (SW[3:0]) as the player inputs
## and LEDs (LD0–LD3) to display the Simon sequence
##=======================================================================

## Clock
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}]

## Reset (active-high)
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports {reset}]

## Player inputs via switches (one-hot, SW0→input[0], SW1→input[1], etc.)
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports {btn[0]}]  ;# SW0
set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports {btn[1]}]  ;# SW1
set_property -dict { PACKAGE_PIN W16  IOSTANDARD LVCMOS33 } [get_ports {btn[2]}]  ;# SW2
set_property -dict { PACKAGE_PIN W17  IOSTANDARD LVCMOS33 } [get_ports {btn[3]}]  ;# SW3

## Sequence display LEDs (led[0] lights LD0, etc.)
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]  ;# LD0
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]  ;# LD1
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]  ;# LD2
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {led[3]}]  ;# LD3

## 7-segment segments (a…g)
set_property -dict { PACKAGE_PIN W7  IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]  ;# a
set_property -dict { PACKAGE_PIN W6  IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]  ;# b
set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]  ;# c
set_property -dict { PACKAGE_PIN V8  IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]  ;# d
set_property -dict { PACKAGE_PIN U5  IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]  ;# e
set_property -dict { PACKAGE_PIN V5  IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]  ;# f
set_property -dict { PACKAGE_PIN U7  IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]  ;# g

## Digit-enable anodes (active low)
set_property -dict { PACKAGE_PIN U2  IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4  IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4  IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4  IOSTANDARD LVCMOS33 } [get_ports {an[3]}]

## Error indicator LED
set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports {error_led}] ;# LD4

##— leave everything else commented unless you add more I/Os —

## Generic board settings
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO   [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33    [current_design]
set_property CONFIG_MODE SPIx4                 [current_design]
