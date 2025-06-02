## Clock
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}]

## Reset (active-high)
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports {reset}]

## Push-buttons (one-hot inputs to btn[3:0])
# set_property -dict { PACKAGE_PIN T18  IOSTANDARD LVCMOS33 } [get_ports {btn[0]}]  ;# BTNU
# set_property -dict { PACKAGE_PIN W19  IOSTANDARD LVCMOS33 } [get_ports {btn[1]}]  ;# BTNL
# set_property -dict { PACKAGE_PIN T17  IOSTANDARD LVCMOS33 } [get_ports {btn[2]}]  ;# BTNR
# set_property -dict { PACKAGE_PIN U17  IOSTANDARD LVCMOS33 } [get_ports {btn[3]}]  ;# BTND

## Slide-switches (SW0–SW3)
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN W16  IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN W17  IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]

## Sequence LEDs (LD0–LD3)
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

## Error LED (LD4)
set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports {error_led}]

## 7-seg segments (a…g), active-LOW
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]

## Digit-enable anodes (AN[0]…AN[3]), active-LOW
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {an[3]}]

## Board configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO   [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE     [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33      [current_design]
set_property CONFIG_MODE SPIx4                   [current_design]
