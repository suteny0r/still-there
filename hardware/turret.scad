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
b2b_gap      = 3.0;         // PCB-to-PCB gap set by the connector
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
cam_sock_d   = cam_housing_d + 1.0;                // 3.0 socket depth: base + 1 mm of flex fold
cam_stop_clr = 0.1;                                // camera-board standoffs stop this short of the board
d_xiao_top   = lens_to_top - lens_protrude;        // 8.93  XIAO top face
d_xiao_back  = d_xiao_top + pcb_t;                 // 10.07 XIAO back face (lid posts stop 0.2 short)
d_cam_front  = d_xiao_top - b2b_gap - cam_pcb_t;   // 4.93  camera board front face
// WiFi antenna: the XIAO ESP32S3 has no on-board antenna; the kit's adhesive FPC patch
// (20 x 40 mm, 75 mm coax from its center to the U.FL between the two PCBs) sticks to a
// plate on the back of the head lid, cable through a slot at the patch center.
ant_w        = 20.0;        // patch size
ant_l        = 40.0;
ant_plate_t  = 2.0;
ant_plate_dz = 9.5;         // plate center above the tilt axis: the plate (42 tall on a 30 mm head) rises
                            // 15 mm above the head behind the laser saddle. Its low edge at -11.5 stays above
                            // the USB notch in the lid, so a right-angle USB-C plug still runs out backward.
                            // (Below the head it would seal that notch.) Laser leads drop inside the head.
ant_slot     = [4.0, 8.0];  // coax pass-through at the patch center (y, z)
coax_groove  = 1.6;         // wall groove for the 1.1 mm coax between the board stack and the back
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
laser_d      = 6.3;

// --------------------------------------------------------------------- yoke
disc_d   = 56;
disc_t   = 5.0;                             // takes the 3.6 double-arm counterbore from below
arm_t    = 3.0;
arm_w    = 26;
axis_h   = 34;                              // disc top -> tilt axis
gap_a    = (sv_top - sv_flange_t - arm_t) + sv_boss_h + sv_horn_h_s - horn_pocket + gap_margin;  // single arm on the head
gap_b    = pivot_ring_h;
arm_a_in = head_y1 + gap_a;                 // arm A inner face (Y)
arm_a_out= arm_a_in + arm_t;
arm_b_in = head_y0 - gap_b;                 // arm B inner face (Y), negative
arm_b_out= arm_b_in - arm_t;
gusset_h = 10;

// --------------------------------------------------------------------- base
base_d      = 78;
base_h      = 34;
base_wall   = 2.4;
base_top_t  = 3.0;
base_lid_t  = 2.5;
base_boss_d = 6.5;
inlet       = true;                         // rim notch for a panel-mount USB-C / DC jack breakout
inlet_w     = 13;
inlet_h     = 7;
cable_hole_d= 12;                           // under-disc cable hole, only useful with the flange on top
pan_flange_below = true;                    // pan servo fitted from below, flange clamped up against the
                                            // boss bottoms (as built). false: flange resting on the plate top.
sv_boss_len = 6;                            // flange screw bosses under the top plate
harness_hole_d = 6;                         // riser harness hole through the top plate, outside the disc
harness_r   = 32.5;                         // its radius: disc edge 28, inner wall 36.6
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
      translate([0, 0, sv_boss_top]) cylinder(d = sv_hub_d, h = sv_hub_top_s);             // hub
      translate([-sv_single_l / 2, 0, sv_boss_top + sv_horn_h_s - sv_horn_t / 2])
        cube([sv_single_l, sv_arm_w, sv_horn_t], center = true);                           // single arm, -X
    } else {
      translate([0, 0, sv_boss_top]) cylinder(d = sv_hub_d, h = sv_hub_top_d);             // hub
      translate([0, 0, sv_horn_face - sv_horn_t / 2]) cube([sv_double_l, sv_arm_w, sv_horn_t], center = true);  // double arm
    }
  }
}

// Through-cut for a servo whose body passes through a plate lying at local Z in
// [z0, z1], plus pilot holes for the two flange screws (M2 self-tapping). The servo
// lead exits on the body side that ends up in free air in both mounts, so no relief.
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
// roof: local 2D direction that points "up" on the printer when this face prints vertically
// (the head's channel). The recess edge on that side slopes 45 deg to the surface and the hub
// counterbore gets a teardrop apex, so nothing overhangs flat and no support is needed inside.
// [0, 0] (the disc, printed face-down) keeps plain vertical walls.
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
    }
    // pan servo through the top plate, flange resting on top
    translate([0, 0, base_top]) servo_cut(z0 = -30, z1 = 5, pilot_z0 = -9.5, pilot_z1 = 1);
    // under-disc cable hole (only with the flange on top; as built the disc rides 1 mm off the plate)
    if (!pan_flange_below)
      translate([18, 0, base_h - base_top_t - 1]) cylinder(d = cable_hole_d, h = base_top_t + 2);
    // riser harness hole outside the disc, on the arm A (+Y) side at pan center
    translate([0, harness_r, base_h - base_top_t - 1]) cylinder(d = harness_hole_d, h = base_top_t + 2);
    // lid screw pilots
    for (a = [45, 135, 225, 315]) rotate([0, 0, a])
      translate([base_d/2 - base_wall - base_boss_d/2 + 0.5, 0, -1])
        cylinder(d = m2_pilot, h = 12);
    // power inlet on the -X side: a notch open to the bottom rim (no bridge to print;
    // slide a panel-mount USB-C / DC breakout in from below, the lid closes it)
    if (inlet)
      translate([-base_d/2, 0, (base_lid_t + 2 + inlet_h - 1)/2])
        cube([base_wall*3, inlet_w, base_lid_t + 2 + inlet_h + 1], center = true);
    // vent slots on the +X side
    for (i = [-1, 0, 1]) translate([base_d/2, i*6, 14]) cube([base_wall*3, 2.2, 14], center = true);
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
        // laser saddle
        if (laser_mount)
          translate([-1.5, 0, head_z/2 + 3]) cube([14, 11, 6.5], center = true);
      }
      // interior cavity, open at the back
      translate([front_in, -head_iy/2, -head_iz/2]) cube([head_ix + 1, head_iy, head_iz]);
      // camera window: barrel passes, housing stops on the wall
      translate([head_x0 - 1, 0, cam_dz]) rotate([0, 90, 0]) cylinder(d = cam_win_d, h = wall + 2);
      // tilt horn (single arm, pointing down) on the +Y face; recess faces outward, screws from inside.
      // rotate([-90,0,0]) maps local +Z -> world +Y and local +Y -> world -Z, so dir [0,1] points down.
      translate([0, head_y1, 0]) rotate([-90, 0, 0])
        horn_channel([[0, 1]], max(sv_single_l, head_z / 2 + 2), hub_relief_s, 4.6, through = side_a_t + 1,
                     roof = [1, 0]);   // head prints front-face down: world +X (local +X) is up
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
        translate([-1.5, 0, head_z/2 + 3.2]) cyl_x(laser_d, 20);
        translate([-1.5, 0, head_z/2 + 3]) cylinder(d = m2_pilot, h = 6);
        // lead drop: the laser leads fall through the top wall into the cavity behind the module
        translate([0, -2, head_z/2 - wall - 1]) cube([9, 4, wall + 4]);
      }
      // coax groove in one side wall (coax_side), from behind the camera board to the back opening,
      // at the far (antenna) end where the U.FL sits between the two boards
      translate([front_in + d_cam_front + cam_pcb_t + 0.5,
                 coax_side * (head_iy / 2) - (coax_side > 0 ? 0.01 : coax_groove - 0.01), pcb_l/2 - 6])
        cube([head_ix, coax_groove, 4]);
      // vent / mic slots on the -Y wall, low
      for (x = [5.5, 7.5]) translate([x, head_y0 - 1, -head_iz/2 + 4]) cube([1.6, side_b_t + 2, 6]);   // behind the pivot ring
    }
    // camera module socket: collar behind the front wall with a square pocket for the housing.
    // The flex pushes the module into it; nothing presses on the camera board or the connector.
    difference() {
      translate([front_in - 0.01, -cam_sock/2 - 2, cam_dz - cam_sock/2 - 2]) cube([cam_sock_d, cam_sock + 4, cam_sock + 4]);
      translate([front_in - 1, -cam_sock/2, cam_dz - cam_sock/2]) cube([cam_sock_d + 2, cam_sock, cam_sock]);
      // the flex leaves the back face of the base toward the USB end: no collar wall there behind the base
      translate([front_in + cam_housing_d, -cam_sock/2 - 3, cam_dz - cam_sock/2 - 3]) cube([cam_sock_d, cam_sock + 6, 3]);
    }
    // front stops: two standoffs to the camera board's far-end corners (VERIFIED bare). Nothing touches the XIAO's
    // top face: its exposed USB-end corners carry the reset/boot buttons and the LEDs. The stack is
    // held between these standoffs and the lid posts on the XIAO back (0.1 + 0.2 mm float, no clamp
    // load through the board-to-board connector).
    for (sy = [-1, 1])
      translate([front_in - 0.01, sy * (cam_pcb_w/2 - 1.5) - 1.5, pcb_l/2 - 3.5]) cube([d_cam_front - cam_stop_clr + 0.01, 3, 3]);
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
      // antenna plate on the outer face: 22 x 42, centered on the lid, offset by ant_plate_dz
      translate([head_x1 + lid_t, (head_y0 + head_y1) / 2 - (ant_w + 2) / 2, ant_plate_dz - (ant_l + 2) / 2])
        cube([ant_plate_t, ant_w + 2, ant_l + 2]);
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
    // coax slot at the patch center, through plate and lid
    translate([head_x1 - 1, (head_y0 + head_y1) / 2 - ant_slot[0] / 2, ant_plate_dz - ant_slot[1] / 2])
      cube([lid_t + ant_plate_t + 2, ant_slot[0], ant_slot[1]]);
    // notch completing the USB slot
    if (usb_slot)
      translate([head_x1 - lid_lip - 1, -usb_w/2, -head_z/2 - 1]) cube([lid_lip + lid_t + 2, usb_w, wall + lip_t + 1.5]);
  }
}

// =============================================================================
//  MOCKS for the assembly view
// =============================================================================
module xiao_mock() {
  front_in = head_x0 + wall;
  color("green") {
    translate([front_in + d_cam_front, -cam_pcb_w/2, pcb_l/2 - cam_pcb_l]) cube([cam_pcb_t, cam_pcb_w, cam_pcb_l]);  // camera board
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
  translate([0, 0, axis_z]) {
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
