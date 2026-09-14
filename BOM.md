# Bill of materials (excluding XIAO ESP32S3 Sense and MG90S servos)

Amazon links found 2026-09-10; listings change, so check quantity and specs before ordering.
Only the first six rows are required for a working turret; the rest are optional or convenience.

| # | Qty needed | Item | What it is for | Amazon |
|--:|-----------:|------|----------------|--------|
| 1 | 1 kg | FLASHFORGE PETG Pro 1.75 mm, black | all five printed parts (73 g per set, so one spool covers many iterations). Use the `Flashforge PETG Pro @FF C5P` filament preset in Flash Studio for this spool; the project ships with `PETG Basic`, swap it in the filament dropdown | [B07Y9S22P5](https://www.amazon.com/FLASHFORGE-Filament-Dimensional-Mechanical-Waterproof/dp/B07Y9S22P5) |
| 2 | M2x8: 2 base lid, 2 head lid; M2x6: 2 head-to-single-arm horn (an 8 would reach the servo boss), 2 disc-to-double-arm horn (servo ear screws come with the servos) | M2 flat-head self-tapping screw assortment, 800 pcs, 4 to 20 mm | every M2 pilot in the design is 1.75 mm for self-tapping M2 | [B0CY986CCR](https://www.amazon.com/Tapping-Woodworking-Fastener-Drilling-Assortment/dp/B0CY986CCR) |
| 3 | 1 | M3 x 8 button-head socket screw, 18-8 stainless, ISO 7380 (Fullerkreg, 100 pcs) | tilt pivot through arm B into the head; the 1.6 mm countersink in the arm is sized for a button head (5.7 dia x 1.65). 8 mm ends 0.35 mm short of the head cavity; a 12 mm would run 3.6 mm in and hit the XIAO edge | [B07H14B2XM](https://www.amazon.com/M3-0-50-Passivated-Stainless-Fullerkreg-Easy-use/dp/B07H14B2XM) |
| 4 | 1 (pack of 5) | 470 uF 16 V radial electrolytic capacitor, E-Projects | across servo 5 V / GND at the servo connector; stops brown-out resets when both servos start | [B07YN5MZBY](https://www.amazon.com/Projects-Radial-Electrolytic-Capacitor-470uF/dp/B07YN5MZBY) |
| 5 | 1 | 5 V 3 A USB-C power adapter, UL listed (Security-01) | main supply into the base inlet; 3 A covers two MG90S stalling plus the ESP32-S3 | [B09JW4QQJ2](https://www.amazon.com/Security-01-Supply-Adapter-Type-C-MLF-C060503000CU/dp/B09JW4QQJ2) |
| 6 | 1 (pack of 14) | Amabro USB-C panel-mount female socket breakout, 20.1 x 6.7 mm board, V/GND/D+/D-/CC pads, 2 mm screw hole | power inlet in the base rim notch. The socket passes through the 13 x 11.5 mm notch; the board sits inside against the wall (hot glue or M2 screw through its hole). Solder the servo/board 5 V and GND leads to the V and GND pads. Only V and GND are needed | [B0H9S9C73Q](https://www.amazon.com/Amabro-Connector-Female-Socket-Breakout/dp/B0H9S9C73Q) |
| 7 | 1 kit | 22 AWG silicone stranded hookup wire, 6 colors (BINNEKER) | riser harness from the base up arm A to the head: 5 V, GND, pan and tilt signals (solder to the XIAO 5V, GND, D0, D1 pads; in through the floor USB-C slot), servo power splice in the base | [B07WYYDBZP](https://www.amazon.com/BINNEKER-Silicone-Resistant-Electronic-Stranded/dp/B07WYYDBZP) |
| 8 | 4 (pack of 100) | 10 x 3 mm clear self-adhesive rubber feet (Alamic) | base lid foot recesses are 10.5 mm dia x 0.8 mm deep | [B07JFGW1XC](https://www.amazon.com/Bumpers-Alamic-Adhesive-Transparent-Dampening/dp/B07JFGW1XC) |
| 9 | 1 (pack of 10), optional | 650 nm 5 V 5 mW red dot laser module, 6 mm brass barrel (HiLetgo) | "fire" indicator in the 6.3 mm saddle on top of the head; fixed focus, ~20 mA at 5 V. Class 3R: not for pointing at faces | [B071FT9HSV](https://www.amazon.com/HiLetgo-10pcs-650nm-Diode-Laser/dp/B071FT9HSV) |
| 9b | 1 (pack of 3), optional | 650 nm 1 mW Class 2 mini dot module, 3 V, 6 x 10 mm (alternative to 9) | same 6 mm barrel, eye-safe class for a turret that points at people; run it from the 3V3 pin through the transistor below (<40 mA) | [B082CRKW5Z](https://www.amazon.com/Mini-Type-650nm-6x10mm-Module-Driver/dp/B082CRKW5Z) |
| 9c | 1, optional | Quarton VLM-650-03 LPT, Class 2 <1 mW, APC driver, 2.6 to 6 V, 7 x 21 mm | the quality option (regulated driver, made in Taiwan); 7 mm barrel, so set `laser_d = 7.3` in `turret.scad` before printing the head | [B00ZR80S9S](https://us.amazon.com/Quarton-Laser-Module-VLM-650-03-ECONOMICAL/dp/B00ZR80S9S) |
| 9d | 1 (pack of 100) | 2N2222 NPN transistor, TO-92 | laser driver: GPIO3 -> 1 k -> base, emitter to GND, laser (-) to collector, laser (+) to 5V (or 3V3 for 9b). Keeps the module's 20 to 40 mA off the ESP32 pin | [B07222XY81](https://www.amazon.com/2N2222-Plastic-Encapsulate-Power-Transistors-600mA/dp/B07222XY81) |
| 10 | 1 (pack of 6), optional | 12 mm momentary push button, pre-wired, panel mount (DaierTek) | trigger button on D3 (GPIO4) to GND; toggles the laser. Needs a 12 mm hole in the base wall (not in the CAD; add one or skip) | [B0C8HM4T24](https://www.amazon.com/DaierTek-Momentary-Button-Switch-Waterproof/dp/B0C8HM4T24) |
| 11 | 1 (2-pack), optional | Right-angle USB-C to USB-A cable, 1 ft (SUNGUY) | flashing/serial with the board in the head; the head floor slot takes a right-angle plug that runs backward. Not needed if you pull the lid to flash | [B0784F9JP2](https://www.amazon.com/SUNGUY-Braided-Charging-Samsung-OnePlus/dp/B0784F9JP2) |

## Not needed

- Servo horns and horn screws: included with the MG90S 4-pack (single, double and cross arms).
- Resistors for the laser: the 5 V modules have their own current limiting; the transistor is only there to keep 20 mA off the GPIO.
- Rubber feet adhesive, nuts, washers: none used.

## Notes

- Item 6 alternative: any USB-C female breakout with solder pads works; a 5 V barrel jack also fits the same notch (13 x 11.5 mm) if you prefer a wall-wart with a barrel plug.
- Item 2 alternative if you want machine screws instead of self-tapping: heat-set inserts are not designed in; the pilots are plain 1.75 mm holes.
- If you print PLA instead, any 1.75 mm PLA works with the `Flashforge PLA Basic @FF C5P` preset.
