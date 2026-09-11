// =============================================================================
//  Tracking turret enclosure for Seeed Studio XIAO ESP32S3 Sense + 2x MG90S
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
//  Coordinate convention (assembly): Z up, camera looks along +X.
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
sv_flange_l = 32.5;
sv_hole_d   = 2.0;
sv_hole_sp  = 27.8;         // flange screw hole spacing (slotted +-0.5 in the cuts)
sv_shaft_off= 5.9;          // shaft axis from the near body end (along X)
sv_boss_d   = 12.0;         // round gear-head boss; must be < sv_cut_w + 2*clr to pass the arm
sv_boss_h   = 2.5;          // boss_h + spline_h = C 28.4 - sv_h 22.7 = 5.7
sv_spline_d = 4.8;          // 20T spline
sv_spline_h = 3.2;
sv_horn_d   = 21.0;         // 4-arm cross horn envelope (single/double arm horns are longer)
sv_horn_t   = 1.5;          // horn plate thickness
sv_horn_h   = 4.8;          // boss top to horn plate OUTER face (hub height) -- MEASURE YOURS
gap_margin  = 0.8;          // extra head-to-arm clearance; a short hub seat beats a rubbing head
sv_cx       = sv_shaft_off - sv_l/2;            // body center X in the local frame (-5.5)
sv_top      = sv_h - sv_flange_z;               // body top above flange bottom (6.7)
sv_boss_top = sv_top + sv_boss_h;               // 9.2
sv_horn_face= sv_boss_top + sv_horn_h;          // 14.0  (horn outer face)
horn_pocket = 2.0;                              // recess depth for the horn plate

// -------------------------------------------- XIAO ESP32S3 Sense board stack
pcb_w        = 17.5;        // board width  (across the two pin rows)
pcb_l        = 21.0;        // board length (USB-C on one short edge)
stack_h      = 11.0;        // camera lens top  ->  XIAO back face
cam_module_h = 5.0;         // camera lens top  ->  expansion PCB top face
cam_dz       = 2.0;         // lens center offset from board center toward the antenna end
cam_win_d    = 10.0;        // front window diameter
usb_slot     = true;        // opening in the head floor for a (right-angle) USB-C plug
usb_w        = 13.5;        // USB-C overmold width
usb_t        = 7.5;         // USB-C overmold thickness

// --------------------------------------------------------------------- head
wall      = 2.0;
head_iy   = pcb_w + 0.8;                    // 18.3 interior width (tilt axis direction)
head_iz   = pcb_l + 4.0;                    // 25.0 interior height
head_ix   = stack_h + 9.0;                  // 20.0 interior depth (front inner face -> lid inner face);
                                            // the 21 mm horn pocket on the side must fit inside the 24 mm head length
lid_t     = 2.0;
lid_lip   = 3.0;                            // lip depth into the shell
lip_t     = 1.4;
side_a_t  = wall + 2.5;                     // +Y wall (horn side): 4.5, pocket leaves 2.3
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
disc_t   = 3.5;
arm_t    = 3.0;
arm_w    = 26;
axis_h   = 34;                              // disc top -> tilt axis
gap_a    = (sv_top - sv_flange_t - arm_t) + sv_boss_h + sv_horn_h - horn_pocket + gap_margin;
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
cable_hole_d= 12;
foot_d      = 10.5;

// ------------------------------------------------------------ assembly Z's
base_top   = base_h;
disc_z0    = base_top + sv_horn_face - horn_pocket;    // disc bottom
disc_z1    = disc_z0 + disc_t;
axis_z     = disc_z1 + axis_h;

// =============================================================================
//  helpers
// =============================================================================
module rrect(w, h, r) { offset(r) offset(-r) square([w, h], center = true); }
module cyl_x(d, l) { rotate([0, 90, 0]) cylinder(d = d, h = l, center = true); }
module cyl_y(d, l) { rotate([90, 0, 0]) cylinder(d = d, h = l, center = true); }

// -------------------------------------------------------------- servo model
module servo(mock = false) {
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
    translate([0, 0, sv_boss_top]) cylinder(d = 7, h = sv_horn_h);
    translate([0, 0, sv_horn_face - sv_horn_t]) cylinder(d = sv_horn_d, h = sv_horn_t);
  }
}

// Through-cut for a servo whose body passes through a plate lying at local Z in
// [z0, z1], plus pilot holes for the two flange screws (M2 self-tapping). The servo
// lead exits on the body side that ends up in free air in both mounts, so no relief.
module servo_cut(z0 = -30, z1 = 30, pilot_z0 = -12, pilot_z1 = 30) {
  translate([sv_cx, 0, z0]) linear_extrude(z1 - z0)
    square([sv_cut_l + 2*clr, sv_cut_w + 2*clr], center = true);
  // slotted pilot holes: +-0.5 along the ear axis absorbs 27.3..28.3 hole spacing
  for (s = [-1, 1]) hull() {
    translate([sv_cx + s*(sv_hole_sp/2 - 0.5), 0, pilot_z0]) cylinder(d = m2_pilot, h = pilot_z1 - pilot_z0);
    translate([sv_cx + s*(sv_hole_sp/2 + 0.5), 0, pilot_z0]) cylinder(d = m2_pilot, h = pilot_z1 - pilot_z0);
  }
}

// Recess for a round/cross horn plus radial slots for M2 screws into the horn,
// cut into a face lying in the XY plane at local Z=0, recess going -Z.
module horn_pocket(through = 8) {
  translate([0, 0, -horn_pocket]) cylinder(d = sv_horn_d + 2*clr, h = horn_pocket + 0.01);
  translate([0, 0, -through]) cylinder(d = 4.6, h = 2*through);              // center screw
  for (a = [0, 90, 180, 270]) rotate([0, 0, a])
    hull() {
      translate([5.0, 0, -through]) cylinder(d = 1.9, h = 2*through);
      translate([9.5, 0, -through]) cylinder(d = 1.9, h = 2*through);
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
        translate([sv_cx + s*sv_hole_sp/2, 0, base_h - base_top_t - 6])
          cylinder(d = 6, h = 6.01);
    }
    // pan servo through the top plate, flange resting on top
    translate([0, 0, base_top]) servo_cut(z0 = -30, z1 = 5, pilot_z0 = -9.5, pilot_z1 = 1);
    // cable hole through the top plate
    translate([18, 0, base_h - base_top_t - 1]) cylinder(d = cable_hole_d, h = base_top_t + 2);
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
    for (x = [-3, -1, 1, 3]) translate([x*5, 0, -1]) cube([2.2, 30, 6], center = true);
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
    // pan horn pocket on the underside
    translate([0, 0, disc_z0 + horn_pocket]) horn_pocket(through = 8);
    // countersink for the center screw head from the top
    translate([0, 0, disc_z1 - 1.5]) cylinder(d1 = 4.6, d2 = 7, h = 1.51);
    // tilt servo through arm A: flange on the OUTER face, shaft toward the head (-Y)
    translate([0, arm_a_out + sv_flange_t, axis_z])
      rotate([90, 0, 0]) rotate([0, 0, 90])
        servo_cut(z0 = sv_flange_t - 1, z1 = sv_flange_t + arm_t + 5, pilot_z0 = 0, pilot_z1 = 20);
    // pivot screw through arm B
    translate([0, arm_b_in + 1, axis_z]) rotate([90, 0, 0]) cylinder(d = m3_free, h = arm_t + 2);
    // pivot screw head countersink (outside)
    translate([0, arm_b_out - 0.01, axis_z]) rotate([-90, 0, 0]) cylinder(d = 6.5, h = 1.6);
    // cable tie slots in the disc
    for (a = [60, 120, 240, 300]) rotate([0, 0, a])
      translate([disc_d/2 - 6, 0, disc_z0 - 1]) cube([4, 1.6, disc_t + 2], center = true);
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
  front_in = head_x0 + wall;                 // front inner face X
  pcb_face = front_in + cam_module_h;        // expansion PCB rests here
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
    // camera window
    translate([head_x0 - 1, 0, cam_dz]) rotate([0, 90, 0]) cylinder(d = cam_win_d, h = wall + 2);
    // shallow relief so the lens housing can sit proud of the pads if needed
    translate([front_in - 0.6, 0, cam_dz]) rotate([0, 90, 0]) cylinder(d = cam_win_d + 4, h = 1);
    // horn pocket on the +Y face (recess faces outward, screws from inside)
    translate([0, head_y1, 0]) rotate([-90, 0, 0]) horn_pocket(through = side_a_t + 1);
    // pivot pilot on the -Y face
    translate([0, head_y0 - pivot_ring_h - 0.01, 0]) rotate([-90, 0, 0]) cylinder(d = m3_pilot, h = pivot_ring_h + 5);
    // USB-C slot through the floor, open to the back
    if (usb_slot)
      translate([pcb_face + stack_h - cam_module_h - 1.0 - usb_t + 1.5, -usb_w/2, -head_z/2 - 1])
        cube([usb_t + 10, usb_w, wall + 2]);
    // lid screw pilots through the top wall
    for (y = [-7, 7]) translate([head_x1 - 1.5, y, head_z/2 - wall - 1]) cylinder(d = m2_pilot, h = wall + 8);
    // laser bore + set screw
    if (laser_mount) {
      translate([-1.5, 0, head_z/2 + 3.2]) cyl_x(laser_d, 20);
      translate([-1.5, 0, head_z/2 + 3]) cylinder(d = m2_pilot, h = 6);
    }
    // vent / mic slots on the -Y wall, low
    for (x = [-3, 0, 3]) translate([x, head_y0 - 1, -head_iz/2 + 4]) cube([1.6, side_b_t + 2, 6]);
  }
  // board seat: 4 corner pads the expansion PCB rests on (front side)
  for (sy = [-1, 1], sz = [-1, 1])
    translate([front_in, sy*(head_iy/2 - 1.0), sz*(head_iz/2 - 1.0)])
      translate([0, -1, -1]) cube([cam_module_h, 2, 2]);
}

module head_lid() {
  front_in = head_x0 + wall;
  pcb_back = front_in + stack_h;             // XIAO back face
  post_len = head_x1 - pcb_back - 0.3;       // posts press the XIAO corners
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
      // screw bosses inside the lip, top wall
      for (y = [-7, 7])
        translate([head_x1 - lid_lip, y - 3, head_iz/2 - lip_clr - 4]) cube([lid_lip + 0.01, 6, 4]);
      // corner posts
      for (sy = [-1, 1], sz = [-1, 1])
        translate([pcb_back + 0.3, sy*(pcb_w/2 - 1.5) - 1.5, sz*(pcb_l/2 - 1.5) - 1.5]) cube([post_len + 0.01, 3, 3]);
    }
    // screw pilots
    for (y = [-7, 7]) translate([head_x1 - 1.5, y, head_iz/2 - 6]) cylinder(d = m2_pilot, h = 10);
    // wire grommet hole for soldered power leads
    translate([head_x1 - 1, 0, -6]) rotate([0, 90, 0]) cylinder(d = 5, h = lid_t + 2);
    // notch completing the USB slot
    if (usb_slot)
      translate([head_x1 - lid_lip - 1, -usb_w/2, -head_z/2 - 1]) cube([lid_lip + lid_t + 2, usb_w, wall + lip_t + 1]);
  }
}

// =============================================================================
//  MOCKS for the assembly view
// =============================================================================
module xiao_mock() {
  front_in = head_x0 + wall;
  color("green") {
    translate([front_in + cam_module_h, -pcb_w/2, -pcb_l/2]) cube([1.0, pcb_w, pcb_l]);          // expansion pcb
    translate([front_in + stack_h - 1.0, -pcb_w/2, -pcb_l/2]) cube([1.0, pcb_w, pcb_l]);         // XIAO pcb
  }
  color("black") translate([front_in + 0.5, 0, cam_dz]) rotate([0, 90, 0]) cylinder(d = 8, h = cam_module_h - 0.5);
  color("silver") translate([front_in + stack_h - 1.0 - 3.2, -4.5, -pcb_l/2 - 1]) cube([3.2, 9, 7]);  // USB-C receptacle
}

module assembly() {
  color("slategray") base();
  color("slategray") translate([0, 0, base_lid_t]) mirror([0, 0, 1]) base_lid();
  translate([0, 0, base_top]) servo(mock = true);
  color("steelblue") yoke();
  translate([0, arm_a_out + sv_flange_t, axis_z]) rotate([90, 0, 0]) rotate([0, 0, 90]) servo(mock = true);
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
module print_head_lid() { translate([0, 0, head_x1 + lid_t]) rotate([0, 90, 0]) head_lid(); } // outer face on the bed

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
