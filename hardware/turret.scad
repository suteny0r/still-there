// =============================================================================
//  Tracking turret enclosure for Seeed Studio XIAO ESP32S3 Sense + 2x MG90S (SupSeek)
//  OpenSCAD 2021.01
//
//  Parts (select with -D part="<name>"):
//    base       pan servo housing, open bottom
//    base_lid   bottom cover for the base (4x M2 screws, rubber-foot recesses)
//    yoke       pan platform: disc on the pan horn + two arms carrying the tilt axis
//    head       camera housing for the XIAO + Sense board (open back)
//    head_lid   back cover for the head (friction lip + 2x M2)
//    assembly   everything in place with mock servos / board, for preview
//    plate      all printable parts laid out flat
//
//  Coordinate convention (assembly): Z up, camera window on the -X face (camera looks along -X).
//  Every part module is authored in assembly position; print_* transforms
//  reorient for the bed. Dimensions in mm.
// =============================================================================

part = "assembly";          // base | base_lid | yoke | head | head_lid | assembly | plate
$fn = 64;

// ---------------------------------------------------------------- tolerances
clr      = 0.30;            // general clearance around inserted parts
lip_clr  = 0.25;            // friction-fit lip clearance
m2_pilot = 1.75;            // M2 self-tapping pilot hole in PLA/PETG
m2_free  = 2.30;            // M2 through hole
m3_pilot = 2.60;
m3_free  = 3.30;

// ------------------------------------------------------------- MG90S servo
// Target servo: MG90S (SupSeek 4-pack, TowerPro-compatible). TowerPro config table:
// A 32.5 (ear span), B 22.8 (body), C 28.4 (bottom to spline top), D 12.4 (width),
// F 18.5 (bottom to ear top). Clones run up to 23.9 x 12.7, so the body cut below is
// deliberately loose; the ear screws locate the servo.
// Local servo frame: shaft axis = +Z through (0,0); Z=0 at flange BOTTOM face.
sv_l        = 22.8;         // body length (along local X)
sv_w        = 12.4;         // body width  (along local Y)
sv_cut_l    = 23.6;         // body through-cut envelope before clearance (covers clones)
sv_cut_w    = 12.8;
sv_h        = 22.7;         // body height, bottom of body to top of body (below the boss)
sv_flange_z = 16.0;         // body bottom to flange bottom (F 18.5 - flange_t)
sv_flange_t = 2.5;
sv_flange_l = 32.5;         // MEASURED 32.2 (H)
sv_hole_d   = 2.0;
sv_hole_sp  = 27.9;         // MEASURED 27.8 / 28.0; pilots are slotted +-0.6 (27.3 .. 28.5)
sv_shaft_off= 5.9;          // shaft axis from the near body end (along X)
sv_boss_d   = 12.0;         // round gear-head boss; must be < sv_cut_w + 2*clr to pass the arm
sv_boss_h   = 3.2;          // MEASURED K (ear top -> boss top) 7.3 / 7.5: 4.2 body above ears + 3.2
sv_spline_d = 4.8;          // 20T spline
sv_spline_h = 3.2;
// Horns (MEASURED on the kit, 2026-09-11). The cross horn is asymmetric (~31 mm long axis) and
// does not fit the head, so the head uses the SINGLE arm (vertical, pointing down) and the pan
// disc the DOUBLE arm. Each horn seats differently on the spline, so hub heights are per horn.
sv_hub_d    = 6.8;          // hub outer diameter (both horns)
sv_horn_t   = 2.0;          // arm plate thickness (E)
sv_arm_w    = 5.1;          // arm width (D)
sv_single_l = 18.0;         // single arm, hub center -> tip (C)
sv_double_l = 31.2;         // double arm, tip -> tip (J)
sv_horn_h_s = 3.8;          // single arm: boss top -> outer face of the arm plate (A1s)
sv_hub_top_s= 6.4;          // single arm: boss top -> top of the hub (A2s), 2.6 proud of the arm
sv_horn_h_d = 5.85;         // double arm: boss top -> outer face of the arm plate (A1)
sv_hub_top_d= 6.26;         // double arm: boss top -> top of the hub (A2), 0.41 proud of the arm
gap_margin  = 0.8;          // extra head-to-arm clearance; a short hub seat beats a rubbing head
sv_seat_extra_s = 2.0;      // AS ASSEMBLED 2026-09-17: the single-arm horn sits 2 mm higher on the tilt servo's
                            // spline than the bench-measured hub height, so the whole head is 2 mm further
                            // from arm A. Goes into gap_a only; the horn itself (and the head's pocket and
                            // hub counterbore) is unchanged.
sv_cx       = sv_shaft_off - sv_l/2;            // body center X in the local frame (-5.5)
sv_top      = sv_h - sv_flange_z;               // body top above flange bottom (6.7)
sv_boss_top = sv_top + sv_boss_h;               // 9.2
sv_horn_face= sv_boss_top + sv_horn_h_d;        // double arm outer face above the flange bottom (pan)
horn_pocket = sv_horn_t + 0.6;                  // recess depth for the horn arm plate (2.6)
hub_relief_s= horn_pocket + (sv_hub_top_s - sv_horn_h_s) + 0.6;  // head counterbore for the single-arm hub (5.8)
hub_relief_d= horn_pocket + (sv_hub_top_d - sv_horn_h_d) + 0.6;  // disc counterbore for the double-arm hub (3.6)

// ----------------------------- XIAO ESP32S3 Plus + camera board stack (MEASURED 2026-09-13)
// Stack, front to back: lens barrel -> 8 x 8 module housing (on a short flex, folded over the
// USB end) -> camera board (18 x 15, wider than the XIAO, sits over the far/antenna end) ->
// 3 mm board-to-board connector gap -> XIAO (17.76 x 21.25). Depths below are from the front
// wall's inner face, with the module housing seated against it.
pcb_w        = 17.76;       // XIAO width
pcb_l        = 21.25;       // XIAO length, USB-C on one short edge (down in the head)
pcb_t        = 1.14;        // XIAO thickness (13.44 - 12.30)
usb_protrude = 1.5;         // USB-C shell past the XIAO's bottom edge
usb_shell_h  = 3.2;         // USB-C receptacle height above the XIAO top face
cam_pcb_w    = 18.0;        // camera board width (across)
cam_pcb_l    = 15.0;        // camera board length, flush with the XIAO's far end
cam_pcb_t    = 1.0;
b2b_gap      = 3.11;        // PCB-to-PCB gap: MEASURED XIAO back -> camera board lens face 5.25, minus the
                            // two board thicknesses. Camera board ends: the FAR end (away from the XIAO's
                            // USB-C) carries the lens-module flex socket edge to edge, standing
                            // cam_flex_sock_h proud of the lens face, and sits directly over the board-to-
                            // board connector, so a stop bearing on the socket top loads that connector in
                            // pure compression. The end nearest the USB-C hangs free: any push there levers
                            // the connector open, so nothing touches it.
cam_flex_sock_h = 2.0;      // MEASURED: XIAO back -> socket top 7.25, minus 5.25
cam_housing  = 8.0;         // module housing (lens base), square
cam_housing_d= 2.0;         // MEASURED: lens base thickness
cam_barrel   = 7.0;         // lens barrel diameter
lens_front   = 5.37;        // MEASURED: back of lens base -> front of lens
lens_protrude= lens_front - cam_housing_d;         // 3.37 barrel past the base face
cam_lens_z   = 10.8;        // lens center above the XIAO's USB edge
lens_to_top  = 12.30;       // lens front -> XIAO top face
stack_h      = 13.44;       // lens front -> XIAO back face
cam_dz       = cam_lens_z - pcb_l / 2;             // lens center vs XIAO center (+0.18)
cam_win_d    = cam_barrel + 0.4;                   // 7.4 window: the housing stops on the wall
cam_sock     = cam_housing + 0.6;                  // 8.6 square socket for the housing
cam_sock_d   = cam_housing_d + 0.5;                // 2.5 socket depth: base + 0.5; the mic can on the camera board's pivot-side edge sits 2.8 back
cam_stop_clr = 0.2;                                // camera-board standoffs stop this short of the board
d_xiao_top   = lens_to_top - lens_protrude;        // 8.93  XIAO top face
d_xiao_back  = d_xiao_top + pcb_t;                 // 10.07 XIAO back face (lid posts stop 0.2 short)
d_cam_front  = d_xiao_top - b2b_gap - cam_pcb_t;   // 4.93  camera board front face
// WiFi antenna: the XIAO ESP32S3 has no on-board antenna; the kit's adhesive FPC patch
// (20 x 40 mm, 75 mm coax) sticks to the outer face of the head lid and its fin. The coax
// leaves the patch center on the EXPOSED face (adhesive is on the other side), so it runs over
// the patch to the fin's side edge above the head, around the edge, and drops into the head
// through a 3 mm notch at the top center of the lid (coax_notch_w). About 47 mm of the 75 are
// used; the rest is slack behind the XIAO.
ant_w        = 20.0;        // patch size
ant_l        = 40.0;
ant_plate_t  = 2.0;
ant_plate_dz = 9.5;         // plate center above the tilt axis: the plate (42 tall on a 30 mm head) rises
                            // 15 mm above the head behind the laser saddle. Its low edge at -11.5 stays above
                            // the USB notch in the lid, so a right-angle USB-C plug still runs out backward.
                            // (Below the head it would seal that notch.) Laser leads drop inside the head.
coax_notch_w = 3.0;         // lid notch over the groove's end: groove depth + this much into the lip corner
coax_groove  = 3.0;         // wall groove depth for the coax between the board stack and the back; deep enough
                            // for the bend out of the U.FL (leaves 2.5 of the 5.5 pivot-side wall)
coax_side    = -1;          // -1: pivot-side (-Y) wall. CONFIRMED on the printed head: with the lens toward
                            // you and USB down the U.FL is at the top right, which is the side opposite the
                            // horn channel. +1 mirrors it to the horn wall (groove stays above the axis).
usb_slot     = true;        // opening in the head floor for a (right-angle) USB-C plug
usb_w        = 13.5;        // USB-C overmold width
usb_t        = 7.5;         // USB-C overmold thickness

// --------------------------------------------------------------------- head
wall      = 2.0;
head_iy   = cam_pcb_w + 0.8;                // 18.8 interior width (camera board is the widest part)
head_iz   = pcb_l + 5.0;                    // 26.25 interior height (USB shell protrudes 1.5 below the PCB)
head_ix   = 20.0;                           // interior depth: XIAO back at 11.14, coax coil + lid posts behind;
                                            // the horn channel on the side needs the 24 mm head length
lid_t     = 2.0;
lid_lip   = 3.0;                            // lip depth into the shell
lip_t     = 1.4;
side_a_t  = wall + 4.5;                     // +Y wall (horn side): 6.5, takes the 5.8 hub counterbore
side_b_t  = wall + 3.5;                     // -Y wall (pivot side): 5.5, M3 pilot depth 5
head_y0   = -(head_iy/2 + side_b_t);        // -14.65
head_y1   =  (head_iy/2 + side_a_t);        //  13.65
head_z    = head_iz + 2*wall;               // 29
head_xlen = wall + head_ix + lid_t;         // 24 total incl. lid
head_x0   = -head_xlen/2;                   // front face
head_x1   = head_x0 + wall + head_ix;       // shell back face (lid inner face)
pivot_ring_d = 10;
pivot_ring_h = 1.5;                         // spacer between head and arm B
laser_mount  = true;                        // saddle for a 6 mm laser diode module on top
laser_d      = 7.3;         // bore for the Quarton VLM-650-03 LPT (7.0 mm barrel, 21 long; BOM 9c) as bought.
                            // 6.3 for the 6 mm HiLetgo modules (BOM 9).
laser_wall   = 1.5;         // saddle wall around the bore
laser_zc     = head_z/2 - 0.3 + laser_d/2;         // bore axis: bore bottom 0.3 into the head top wall
saddle_top   = laser_zc + laser_d/2 + laser_wall;  // saddle height follows the bore
saddle_w     = laser_d + 2*laser_wall + 1.0;       // 11.3 for 7.3

// --------------------------------------------------------------------- yoke
disc_d   = 56;
disc_t   = 5.0;                             // takes the 3.6 double-arm counterbore from below
arm_t    = 3.0;
arm_w    = 26;
axis_h   = 34;                              // disc top -> tilt axis
gap_a    = (sv_top - sv_flange_t - arm_t) + sv_boss_h + sv_horn_h_s + sv_seat_extra_s - horn_pocket + gap_margin;  // 8.4
gap_b    = pivot_ring_h;
head_dy  = -sv_seat_extra_s;                // head frame offset along the tilt axis from the pan axis: keeps
                                            // arm A at the disc edge, moves arm B outward instead (user's call)
arm_a_in = head_dy + head_y1 + gap_a;       // arm A inner face (Y)  22.3, unchanged
arm_a_out= arm_a_in + arm_t;
arm_b_in = head_dy + head_y0 - gap_b;       // arm B inner face (Y) -18.4, was -16.4
arm_b_out= arm_b_in - arm_t;
gusset_h = 10;

// --------------------------------------------------------------------- base
base_d      = 78;
base_h      = 34;
base_wall   = 2.4;
base_top_t  = 3.0;
base_lid_t  = 2.5;
base_boss_d = 6.5;
inlet       = true;                         // panel-mount USB-C breakout (BOM item 6)
inlet_ang   = 180;                          // wall angle: 180 = +X, the BACK of the turret. The pan servo body
                                            // ends 6.6 mm from center on +X but 17.6 on -X (shaft offset), so
                                            // +X and +-Y give ~30 mm behind the board, -X only ~16. Vents go
                                            // on the opposite wall.
inlet_pcb   = [20.1, 6.75];                 // MEASURED board: 20 x 6.75, mounted OUTSIDE against a flat facet
inlet_hole_sp = 16.0;                       // MEASURED: two mounting holes 16 mm apart, on the board's centerline
inlet_slot_w = 13.0;                        // wall slot for the 12 mm connector body, open to the bottom rim
inlet_face_x = 37.5;                        // flat outer facet at this radius (1.5 into the r 39 wall at center;
                                            // the inside pad below keeps 3.5 mm of wall behind the facet)
inlet_pad_x = 34.0;                         // inside pad face radius
inlet_z0    = base_lid_t + 1.0;             // board bottom edge above the lid
// (An inside mount was tried 2026-09-16 and failed: the receptacle face sat 3.5 mm behind the wall
//  and a plug could not reach it. The board face must be at the outer surface.)
cable_hole_d= 12;                           // under-disc cable hole, only useful with the flange on top
pan_flange_below = true;                    // pan servo fitted from below, flange clamped up against the
                                            // boss bottoms (as built). false = flange on the plate top DOES NOT
                                            // WORK: the servo lead leaves the body end face right under the
                                            // ear and runs into the screw boss beneath the plate. Kept only
                                            // for the geometry history.
sv_boss_len = 6;                            // flange screw bosses under the top plate
harness_w   = 6;                            // riser harness slot, radial width (disc edge 28, inner wall 36.6)
harness_l   = 12;                           // slot length along the arc: a servo plug is 8 x 3, passes end-on
harness_r   = 32.5;                         // arc radius; the slot follows the rim so its width stays 6
foot_d      = 10.5;

// ------------------------------------------------------------ assembly Z's
base_top   = base_h;
pan_flange_z = pan_flange_below ? base_top - base_top_t - sv_boss_len - sv_flange_t : base_top;  // flange bottom
disc_z0    = pan_flange_z + sv_horn_face - horn_pocket;    // disc bottom (0.95 above the plate as built)
disc_z1    = disc_z0 + disc_t;
axis_z     = disc_z1 + axis_h;

// =============================================================================
//  helpers
// =============================================================================
module rrect(w, h, r) { offset(r) offset(-r) square([w, h], center = true); }
module cyl_x(d, l) { rotate([0, 90, 0]) cylinder(d = d, h = l, center = true); }
module cyl_y(d, l) { rotate([90, 0, 0]) cylinder(d = d, h = l, center = true); }

// -------------------------------------------------------------- servo model
module servo(mock = false, single = false) {   // single: mock draws the single-arm horn pointing -X
  c = mock ? 0 : clr;
  color("dimgray") {
    // body
    translate([sv_cx, 0, (sv_top - sv_flange_z)/2])
      cube([sv_l + 2*c, sv_w + 2*c, sv_h + 2*c], center = true);
    // flange
    translate([sv_cx, 0, sv_flange_t/2])
      cube([sv_flange_l + 2*c, sv_w + 2*c, sv_flange_t + 2*c], center = true);
    // boss + spline
    translate([0, 0, sv_top]) cylinder(d = sv_boss_d + 2*c, h = sv_boss_h);
    translate([0, 0, sv_boss_top]) cylinder(d = sv_spline_d + 2*c, h = sv_spline_h);
  }
  if (mock) color("white") {
    if (single) {
      translate([0, 0, sv_boss_top + sv_seat_extra_s]) cylinder(d = sv_hub_d, h = sv_hub_top_s);   // hub, as seated
      translate([-sv_single_l / 2, 0, sv_boss_top + sv_seat_extra_s + sv_horn_h_s - sv_horn_t / 2])
        cube([sv_single_l, sv_arm_w, sv_horn_t], center = true);                           // single arm, -X
    } else {
      translate([0, 0, sv_boss_top]) cylinder(d = sv_hub_d, h = sv_hub_top_d);             // hub
      translate([0, 0, sv_horn_face - sv_horn_t / 2]) cube([sv_double_l, sv_arm_w, sv_horn_t], center = true);  // double arm
    }
  }
}

// Through-cut for a servo whose body passes through a plate lying at local Z in
// [z0, z1], plus pilot holes for the two flange screws (M2 self-tapping).
// MG90S lead exit: from the END FACE of the body (the -X end, away from the shaft) just below
// the ear. Anything within ~2 mm of that end face at ear level blocks the lead. In the base the
// screw bosses under the plate sit exactly there, which is why the pan servo cannot mount with
// its flange on the plate (see pan_flange_below). On arm A the body is outside in free air.
module servo_cut(z0 = -30, z1 = 30, pilot_z0 = -12, pilot_z1 = 30) {
  translate([sv_cx, 0, z0]) linear_extrude(z1 - z0)
    square([sv_cut_l + 2*clr, sv_cut_w + 2*clr], center = true);
  // slotted pilot holes: +-0.6 along the ear axis absorbs 27.3..28.5 hole spacing (27.8 / 28.0 measured)
  for (s = [-1, 1]) hull() {
    translate([sv_cx + s*(sv_hole_sp/2 - 0.6), 0, pilot_z0]) cylinder(d = m2_pilot, h = pilot_z1 - pilot_z0);
    translate([sv_cx + s*(sv_hole_sp/2 + 0.6), 0, pilot_z0]) cylinder(d = m2_pilot, h = pilot_z1 - pilot_z0);
  }
}

// Horn recess cut into a face lying in the XY plane at local Z=0, recess going -Z.
// A rounded channel takes the arm plate, a counterbore takes the hub that stands proud of it,
// a center hole passes the horn screw, and one continuous slot per arm takes M2 screws through
// the wall into any of the arm's holes. dirs: list of unit directions (in the face plane) the
// arm(s) point; len: hub center -> tip for each direction.
// roof: optional; a local 2D direction that points "up" on the printer when this face prints
// vertically. The recess edge on that side then slopes 45 deg to the surface and the hub counterbore
// gets a teardrop apex. NOT used: it loosens the horn's coupling to the channel. Default [0, 0].
module horn_channel(dirs, len, relief, center_d, through = 8, roof = [0, 0]) {
  w = sv_arm_w + 1.0;
  hub = sv_hub_d + 0.6;
  // arm channel(s)
  for (d = dirs) hull() {
    translate([0, 0, -horn_pocket]) cylinder(d = w, h = horn_pocket + 0.01);
    translate([d[0] * (len + 1.0), d[1] * (len + 1.0), -horn_pocket]) cylinder(d = w, h = horn_pocket + 0.01);
    if (roof != [0, 0]) {
      translate([roof[0] * horn_pocket, roof[1] * horn_pocket, -0.01]) cylinder(d = w, h = 0.02);
      translate([d[0] * (len + 1.0) + roof[0] * horn_pocket, d[1] * (len + 1.0) + roof[1] * horn_pocket, -0.01])
        cylinder(d = w, h = 0.02);
    }
  }
  // hub counterbore (teardrop when roofed) + center screw
  hull() {
    translate([0, 0, -relief]) cylinder(d = hub, h = relief + 0.01);
    if (roof != [0, 0])
      translate([roof[0] * hub / 2 * sqrt(2), roof[1] * hub / 2 * sqrt(2), -relief]) cylinder(d = 0.01, h = relief + 0.01);
  }
  translate([0, 0, -through]) cylinder(d = center_d, h = 2 * through);
  // screw slot per arm: from just outside the hub to near the tip
  for (d = dirs) hull() {
    translate([d[0] * 5.0, d[1] * 5.0, -through]) cylinder(d = 1.9, h = 2 * through);
    translate([d[0] * (len - 2.0), d[1] * (len - 2.0), -through]) cylinder(d = 1.9, h = 2 * through);
  }
}

// =============================================================================
//  BASE
// =============================================================================
module base() {
  difference() {
    union() {
      difference() {
        cylinder(d = base_d, h = base_h);
        translate([0, 0, -0.01]) cylinder(d = base_d - 2*base_wall, h = base_h - base_top_t + 0.01);
      }
      // lid screw bosses
      for (a = [45, 135, 225, 315]) rotate([0, 0, a])
        translate([base_d/2 - base_wall - base_boss_d/2 + 0.5, 0, base_lid_t])
          cylinder(d = base_boss_d, h = base_h - base_top_t - base_lid_t + 0.01);
      // servo flange screw bosses under the top plate
      for (s = [-1, 1])
        translate([sv_cx + s*sv_hole_sp/2, 0, base_h - base_top_t - sv_boss_len])
          cylinder(d = 6, h = sv_boss_len + 0.01);
      // inlet backing pad inside the wall behind the facet: wall stays 3.5 thick where the facet
      // cut would leave 0.8, and the screw pilots have material (authored on -X, turned to inlet_ang)
      if (inlet) rotate([0, 0, inlet_ang]) intersection() {
        cylinder(d = base_d - 0.02, h = base_h);
        translate([-base_d/2, -(inlet_pcb[0]/2 + 2), base_lid_t])
          cube([base_d/2 - inlet_pad_x, inlet_pcb[0] + 4, inlet_pcb[1] + 3]);
      }
    }
    // pan servo through the top plate, flange resting on top
    translate([0, 0, base_top]) servo_cut(z0 = -30, z1 = 5, pilot_z0 = -9.5, pilot_z1 = 1);
    // under-disc cable hole (only with the flange on top; as built the disc rides 1 mm off the plate)
    if (!pan_flange_below)
      translate([18, 0, base_h - base_top_t - 1]) cylinder(d = cable_hole_d, h = base_top_t + 2);
    // riser harness hole outside the disc, on the arm A (+Y) side at pan center
    // arc slot: swept between two round ends, centered on +Y (arm A side)
    hull() for (a = [-1, 1]) rotate([0, 0, 90 + a * (harness_l - harness_w) / 2 / harness_r * 180 / PI])
      translate([harness_r, 0, base_h - base_top_t - 1]) cylinder(d = harness_w, h = base_top_t + 2);
    // lid screw pilots
    for (a = [45, 135, 225, 315]) rotate([0, 0, a])
      translate([base_d/2 - base_wall - base_boss_d/2 + 0.5, 0, -1])
        cylinder(d = m2_pilot, h = 12);
    // power inlet on the -X side: the board screws flat to the internal pad (added in the union
    // below), its receptacle passes through a slot that is open to the bottom rim so nothing has to
    // bridge when the base prints top-down; the lid's edge closes the slot from below.
    if (inlet) rotate([0, 0, inlet_ang]) {
      // flat facet on the outside: everything outside the plane x = -inlet_face_x is removed over
      // the board's footprint plus 1.5 mm, from the rim to 1.5 above the board's top edge
      translate([-base_d/2 - 1, -(inlet_pcb[0]/2 + 1.5), -1])
        cube([base_d/2 + 1 - inlet_face_x, inlet_pcb[0] + 3, 1 + inlet_z0 + inlet_pcb[1] + 1.5]);
      // connector slot through the wall, open to the bottom rim (no bridge to print; the board
      // covers it from outside, the lid edge from below)
      translate([-base_d/2 - 1, -inlet_slot_w/2, -1])
        cube([base_d/2 - inlet_pad_x + 2, inlet_slot_w, 1 + inlet_z0 + inlet_pcb[1]/2 + 2.1]);
      // M2 pilots from the facet inward, 3.2 deep (M2x4 self-tapping through the 1 mm board)
      for (sy = [-1, 1])
        translate([-inlet_face_x - 0.01, sy * inlet_hole_sp/2, inlet_z0 + inlet_pcb[1]/2])
          rotate([0, 90, 0]) cylinder(d = m2_pilot, h = 3.2);
    }
    // vent slots on the wall opposite the inlet
    rotate([0, 0, inlet_ang]) for (i = [-1, 0, 1]) translate([base_d/2, i*6, 14]) cube([base_wall*3, 2.2, 14], center = true);
  }
}

module base_lid() {
  r = (base_d - 2*base_wall)/2 - 0.2;
  difference() {
    cylinder(r = r, h = base_lid_t);
    for (a = [45, 135, 225, 315]) rotate([0, 0, a])
      translate([base_d/2 - base_wall - base_boss_d/2 + 0.5, 0, -1]) cylinder(d = m2_free, h = 10);
    // rubber feet
    for (a = [0, 90, 180, 270]) rotate([0, 0, a])
      translate([r - 10, 0, -0.01]) cylinder(d = foot_d, h = 0.8);
    // vent grid
    for (x = [-3, -1, 1, 3]) translate([x*5, 0, base_lid_t/2]) cube([2.2, 30, base_lid_t + 2], center = true);   // through
  }
}

// =============================================================================
//  YOKE (pan platform + arms)
// =============================================================================
module arm_profile() {
  // 2D in the XZ plane (X = across, "Y" of the 2D shape = Z up from disc top)
  hull() {
    translate([-arm_w/2, 0]) square([arm_w, 1]);
    translate([0, axis_h]) circle(d = arm_w);
  }
}

module arm(y_in, y_out) {
  // plate between y_in and y_out (either order), standing on the disc top
  y0 = min(y_in, y_out); y1 = max(y_in, y_out);
  translate([0, y1, disc_z1]) rotate([90, 0, 0]) linear_extrude(y1 - y0) arm_profile();
}

module gusset(y_in, y_out) {
  // triangular fillet from the arm inner face down onto the disc
  dir = (y_in > 0) ? -1 : 1;                 // direction from arm toward disc center
  translate([0, y_in, disc_z1])
    rotate([90, 0, 90])
      linear_extrude(arm_w, center = true)
        polygon([[0, 0], [dir*gusset_h*0.8, 0], [0, gusset_h]]);
}

module yoke() {
  difference() {
    union() {
      translate([0, 0, disc_z0]) cylinder(d = disc_d, h = disc_t);
      arm(arm_a_in, arm_a_out);
      arm(arm_b_in, arm_b_out);
      gusset(arm_a_in, arm_a_out);
      gusset(arm_b_in, arm_b_out);
    }
    // pan horn (double arm, along X) on the underside
    // 3.2 clearance for the horn screw; its head sits on the disc top (no countersink: the 3.6 mm
    // hub counterbore from below leaves only 1.4 mm of floor)
    translate([0, 0, disc_z0 + horn_pocket]) horn_channel([[1, 0], [-1, 0]], sv_double_l / 2, hub_relief_d, 3.2, through = 8);
    // tilt servo through arm A: flange on the OUTER face, shaft toward the head (-Y)
    translate([0, arm_a_out + sv_flange_t, axis_z])
      rotate([90, 0, 0]) rotate([0, 0, 90])
        servo_cut(z0 = sv_flange_t - 1, z1 = sv_flange_t + arm_t + 5, pilot_z0 = 0, pilot_z1 = 20);
    // zip-tie slots through arm A, one near each edge (x +-9.5), above the gusset and below the tilt
    // servo flange: the tie goes through the slot and around the arm edge with the harness
    for (x = [-9.5, 9.5]) translate([x - 0.8, arm_a_in - 1, disc_z1 + 10]) cube([1.6, arm_t + 2, 4]);
    // pivot screw through arm B
    translate([0, arm_b_in + 1, axis_z]) rotate([90, 0, 0]) cylinder(d = m3_free, h = arm_t + 2);
    // pivot screw head countersink (outside)
    translate([0, arm_b_out - 0.01, axis_z]) rotate([-90, 0, 0]) cylinder(d = 6.5, h = 1.6);
  }
}

// =============================================================================
//  HEAD (camera housing)
// =============================================================================
module head_outer_2d() {
  // YZ footprint of the shell, centered on the tilt axis
  translate([(head_y0 + head_y1)/2, 0]) rrect(head_y1 - head_y0, head_z, 2.5);
}

module head() {
  front_in = head_x0 + wall;                 // front inner face X (module housing seats here)
  union() {
    difference() {
      union() {
        // shell
        translate([head_x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(wall + head_ix) head_outer_2d();
        // pivot spacer ring on the -Y face
        translate([0, head_y0 + 0.01, 0]) rotate([90, 0, 0]) cylinder(d = pivot_ring_d, h = pivot_ring_h);
        // laser saddle: block behind, 45 deg slope down to the head's front edge in front, so the face
        // that hangs over the bed when the head prints front-down is a printable overhang, not a ceiling
        if (laser_mount) hull() {
          translate([5.5 - (saddle_top - (head_z/2 - 0.25)), -saddle_w/2, head_z/2 - 0.25])
            cube([saddle_top - (head_z/2 - 0.25), saddle_w, saddle_top - (head_z/2 - 0.25)]);   // block, 45 deg ramp in front
          translate([head_x0, -saddle_w/2, head_z/2 - 0.25]) cube([5.5 - head_x0, saddle_w, 0.5]);  // base slab from the front face
        }
      }
      // interior cavity, open at the back
      translate([front_in, -head_iy/2, -head_iz/2]) cube([head_ix + 1, head_iy, head_iz]);
      // camera window: barrel passes, housing stops on the wall
      translate([head_x0 - 1, 0, cam_dz]) rotate([0, 90, 0]) cylinder(d = cam_win_d, h = wall + 2);
      // tilt horn (single arm, pointing down) on the +Y face; recess faces outward, screws from inside.
      // rotate([-90,0,0]) maps local +Z -> world +Y and local +Y -> world -Z, so dir [0,1] points down.
      translate([0, head_y1, 0]) rotate([-90, 0, 0])
        horn_channel([[0, 1]], max(sv_single_l, head_z / 2 + 2), hub_relief_s, 4.6, through = side_a_t + 1);
        // plain vertical channel walls by choice: full-depth horn coupling. The channel's upper edge is a
        // 2.6 mm ceiling when the head prints front-down and sags a little; file the blemish off.
      // pivot pilot on the -Y face
      translate([0, head_y0 - pivot_ring_h - 0.01, 0]) rotate([-90, 0, 0]) cylinder(d = m3_pilot, h = pivot_ring_h + side_b_t + 1);  // through: M3x8 ends 0.35 short of the cavity
      // USB-C slot through the floor, open to the back: the receptacle sits on the XIAO top face
      if (usb_slot)
        translate([front_in + d_xiao_top - usb_shell_h - 2.5, -usb_w/2, -head_z/2 - 1])
          cube([head_ix, usb_w, wall + 2]);
      // lid screw pilots through the top wall
      for (y = [-7, 7]) translate([head_x1 - 1.5, y, head_z/2 - wall - 1]) cylinder(d = m2_pilot, h = wall + 8);
      // laser bore + set screw
      if (laser_mount) {
        translate([-1.5, 0, laser_zc]) cyl_x(laser_d, 26);                       // x -14.5 .. 11.5, through the ramp
        translate([-1.5, 0, laser_zc]) cylinder(d = m2_pilot, h = laser_d/2 + laser_wall + 1);   // set screw from the top
        // lead drop: the laser leads fall through the top wall into the cavity behind the module
        translate([0, -2, head_z/2 - wall - 1]) cube([9, 4, wall + 4]);
      }
      // coax groove in one side wall (coax_side), from the camera board's back face to the back opening.
      // The U.FL sits between the boards at the far-end corner and its cable can only leave over the
      // far edge or sideways at that corner, so the groove runs from 4 mm below the XIAO's far edge up
      // into the wall/ceiling corner (0.5 mm into the top wall) and the coax can enter it either way.
      translate([front_in + d_cam_front + cam_pcb_t - 0.5,
                 coax_side * (head_iy / 2) - (coax_side > 0 ? 0.01 : coax_groove - 0.01), pcb_l/2 - 4])
        cube([head_ix, coax_groove, head_iz/2 + 0.5 - (pcb_l/2 - 4)]);
      // vent / mic slots on the -Y wall, low
      for (x = [5.5, 7.5]) translate([x, head_y0 - 1, -head_iz/2 + 4]) cube([1.6, side_b_t + 2, 6]);   // behind the pivot ring
    }
    // camera module socket: collar behind the front wall with a square pocket for the housing.
    // The flex pushes the module into it; nothing presses on the camera board or the connector.
    difference() {
      translate([front_in - 0.01, -cam_sock/2 - 2, cam_dz - cam_sock/2 - 2]) cube([cam_sock_d, cam_sock + 4, cam_sock + 4]);
      translate([front_in - 1, -cam_sock/2, cam_dz - cam_sock/2]) cube([cam_sock_d + 2, cam_sock, cam_sock]);
      // the flex leaves the back face of the base toward the FAR end (up, to the socket at the camera
      // board's far edge): no collar wall there behind the base. The USB-side wall stays full depth.
      translate([front_in + cam_housing_d, -cam_sock/2 - 3, cam_dz + cam_sock/2]) cube([cam_sock_d, cam_sock + 6, 3]);
    }
    // front stops: two standoffs to the TOP of the flex socket at the camera board's far-end corners,
    // which sits over the board-to-board connector (compression only). They stop cam_flex_sock_h
    // short of the board face; a full-depth stop rests on the socket and tilts the board. The end
    // nearest the USB-C is unsupported and gets no stop. Nothing touches the XIAO's top face either:
    // its exposed USB-end corners carry the reset/boot buttons. With the USB-C shell pad below and
    // the four lid posts behind, the stack is fully constrained (0.2 mm float, no clamp load).
    for (sy = [-1, 1])
      translate([front_in - 0.01, sy * (cam_pcb_w/2 - 1.5) - 1.5, pcb_l/2 - 3.5])
        cube([d_cam_front - cam_flex_sock_h - cam_stop_clr + 0.01, 3, 3]);
    // USB-end front stop: a pad to the front face of the USB-C shell (metal, 9 wide, between the two
    // buttons), 0.3 short. Without it the stack could pivot about the far-end stops.
    translate([front_in - 0.01, -3, -pcb_l/2 + 1.5]) cube([d_xiao_top - usb_shell_h - 0.3 + 0.01, 6, 3]);
  }
}

module head_lid() {
  front_in = head_x0 + wall;
  pcb_back = front_in + d_xiao_back;         // XIAO back face
  post_len = head_x1 - pcb_back - 0.2;       // posts locate the XIAO corners, no squeeze
  difference() {
    union() {
      // plate
      translate([head_x1, 0, 0]) rotate([90, 0, 90]) linear_extrude(lid_t) head_outer_2d();
      // friction lip
      translate([head_x1 - lid_lip, 0, 0]) rotate([90, 0, 90]) linear_extrude(lid_lip + 0.01)
        difference() {
          square([head_iy - 2*lip_clr, head_iz - 2*lip_clr], center = true);
          square([head_iy - 2*lip_clr - 2*lip_t, head_iz - 2*lip_clr - 2*lip_t], center = true);
        }
      // antenna plate on the outer face: the lid outline plus the 22 x 42 patch area (offset by
      // ant_plate_dz), so the whole outer face is one flat surface that prints on the bed with no
      // overhang. The lid is lid_t + ant_plate_t thick; only the fin above the head is ant_plate_t.
      translate([head_x1 + lid_t, 0, 0]) rotate([90, 0, 90]) linear_extrude(ant_plate_t) union() {
        head_outer_2d();
        translate([(head_y0 + head_y1) / 2, ant_plate_dz]) square([ant_w + 2, ant_l + 2], center = true);
      }
      // screw bosses inside the lip, top wall
      for (y = [-7, 7])
        translate([head_x1 - lid_lip, y > 0 ? y - 3 : -(head_iy/2 - lip_clr), head_iz/2 - lip_clr - 4])
          cube([lid_lip + 0.01, head_iy/2 - lip_clr - 4, 4]);   // 4 .. 9.15, flush with the lip
      // posts to the XIAO back face: far-end corners (unused D6/D7 pads) and, at the USB end,
      // inboard at Y +-3.5 flanking the flat BAT pads, clear of the soldered D0/D1/5V/GND pads (VERIFIED bare)
      for (sy = [-1, 1], sz = [-1, 1])
        translate([pcb_back + 0.2, sy*(sz > 0 ? pcb_w/2 - 1.5 : 3.5) - 1.5, sz*(pcb_l/2 - 1.5) - 1.5])
          cube([post_len + 0.01, 3, 3]);
    }
    // screw pilots
    for (y = [-7, 7]) translate([head_x1 - 1.5, y, head_iz/2 - 6]) cylinder(d = m2_pilot, h = 10);
    // coax exit: a notch through the lid's inner layer and the lip corner directly over the end of
    // the wall groove (coax_side), from 4.5 mm below the groove top out through the lid's top edge.
    // The groove is uncapped and continues up between the head's top wall and the fin, so the coax
    // follows it straight out of the head at the top corner, then round the fin's side edge.
    translate([head_x1 - lid_lip - 0.01,
               coax_side > 0 ? head_iy/2 - coax_notch_w : -(head_iy/2 + coax_groove), 9])
      cube([lid_lip + lid_t + 0.01, coax_groove + coax_notch_w, head_z/2 - 9 + 0.2]);
    // notch completing the USB slot
    if (usb_slot)
      translate([head_x1 - lid_lip - 1, -usb_w/2, -head_z/2 - 1]) cube([lid_lip + lid_t + ant_plate_t + 2, usb_w, wall + lip_t + 1.5]);
  }
}

// =============================================================================
//  MOCKS for the assembly view
// =============================================================================
module xiao_mock() {
  front_in = head_x0 + wall;
  color("green") {
    translate([front_in + d_cam_front, -cam_pcb_w/2, pcb_l/2 - cam_pcb_l]) cube([cam_pcb_t, cam_pcb_w, cam_pcb_l]);  // camera board
    translate([front_in + d_cam_front - cam_flex_sock_h, -cam_pcb_w/2, pcb_l/2 - 3]) cube([cam_flex_sock_h, cam_pcb_w, 3]);  // flex socket, far end
    translate([front_in + d_xiao_top, -pcb_w/2, -pcb_l/2]) cube([pcb_t, pcb_w, pcb_l]);                          // XIAO
  }
  color("black") {
    translate([front_in, -cam_housing/2, cam_dz - cam_housing/2]) cube([cam_housing_d, cam_housing, cam_housing]); // lens base
    translate([front_in - lens_protrude, 0, cam_dz]) rotate([0, 90, 0]) cylinder(d = cam_barrel, h = lens_protrude + 0.1);
  }
  color("silver") translate([front_in + d_xiao_top - usb_shell_h, -4.5, -pcb_l/2 - usb_protrude]) cube([usb_shell_h, 9, 7]);  // USB-C
}

module assembly() {
  color("slategray") base();
  color("slategray") translate([0, 0, base_lid_t]) mirror([0, 0, 1]) base_lid();
  translate([0, 0, pan_flange_z]) servo(mock = true);
  color("steelblue") yoke();
  translate([0, arm_a_out + sv_flange_t, axis_z]) rotate([90, 0, 0]) rotate([0, 0, 90]) servo(mock = true, single = true);  // local -X = down
  translate([0, head_dy, axis_z]) {
    color("orange") head();
    color("darkorange") head_lid();
    xiao_mock();
  }
}

// =============================================================================
//  PRINT ORIENTATIONS
// =============================================================================
module print_base()     { translate([0, 0, base_h]) mirror([0, 0, 1]) base(); }          // top plate on the bed
module print_base_lid() { base_lid(); }
module print_yoke()     { translate([0, 0, -disc_z0]) yoke(); }
module print_head()     { translate([0, 0, -head_x0]) rotate([0, -90, 0]) head(); }          // front face on the bed
module print_head_lid() { translate([0, 0, head_x1 + lid_t + ant_plate_t]) rotate([0, 90, 0]) head_lid(); } // antenna plate on the bed

if (part == "base")          print_base();
else if (part == "base_lid") print_base_lid();
else if (part == "yoke")     print_yoke();
else if (part == "head")     print_head();
else if (part == "head_lid") print_head_lid();
else if (part == "plate") {
  print_base();
  translate([90, 0, 0]) print_base_lid();
  translate([0, 80, 0]) print_yoke();
  translate([95, 60, 0]) print_head();
  translate([95, 100, 0]) print_head_lid();
}
else assembly();
