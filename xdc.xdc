##=======================================================================
## Basys3-revB constraints for simon_game_top.v
##=======================================================================

## Clock
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}]

## Reset (active-high)
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports {reset}]

## Buttons (one-hot for Simon inputs)
set_property -dict { PACKAGE_PIN T18  IOSTANDARD LVCMOS33 } [get_ports {btn[0]}]  ;# BTNU
set_property -dict { PACKAGE_PIN W19  IOSTANDARD LVCMOS33 } [get_ports {btn[1]}]  ;# BTNL
set_property -dict { PACKAGE_PIN T17  IOSTANDARD LVCMOS33 } [get_ports {btn[2]}]  ;# BTNR
set_property -dict { PACKAGE_PIN U17  IOSTANDARD LVCMOS33 } [get_ports {btn[3]}]  ;# BTND

## LEDs for sequence feedback
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]  ;# LD0
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]  ;# LD1
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]  ;# LD2
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {led[3]}]  ;# LD3

## LED for error indicator
set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports {error_led}] ;# LD4

##— leave everything else commented unless you add more I/Os —

## Generic board settings
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO   [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33    [current_design]
set_property CONFIG_MODE SPIx4                 [current_design]
