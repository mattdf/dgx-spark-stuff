/*
  Printable stackable 4x rack for NVIDIA DGX Spark

  DGX Spark reference body dimensions used:
    150 mm L x 150 mm W x 50.5 mm H

  This version is designed for FDM printing without support:
    - tray exports bottom-flat; no downward feet
    - no suspended top perimeter frame or long bridges
    - separate flat side joiners instead of tall upright straps
    - lateral brass-insert pockets use printable teardrop geometry
    - tray-to-tray alignment uses separate dowel pins and socket pockets

  Print/export modes:
    part = "stack4";        // preview full 4x assembly, including roof if enabled
    part = "tray";          // print 4x
    part = "top_slice";     // print 1x roof cap; same footprint as tray floor, no columns
    part = "side_joiner";   // print 12x for a fixed 4-stack; 4 per seam
    part = "align_pin";     // print 16x with roof, 12x without, or replace with 8 mm OD dowel pins
    part = "device";        // DGX Spark reference placeholder only

  Hardware:
    - M3 heat-set inserts, default pocket: 4.6 mm OD x 5.8 mm deep
    - M3 x 10 mm button/socket-head screws for side joiners
    - populate 32 inserts if every tray should remain independently stackable
      in either direction; only 24 are used in a fixed 4-stack.

  Coordinate convention:
    - X = width
    - Y = depth, rear I/O/cable side at +Y
    - Z = height
*/

module dgx_spark_ref() {
    // credit: SchwickSchwimmer @ https://www.printables.com/model/1512927-nvidia-dgx-spark
    import("./dgx_spark_ref.stl");
}

$fn = 48;

front_label = "DGX SPARK";

part = "stack4";
show_device_preview = false;
show_joiners = true;
show_alignment_pins = true;
show_top_slice = true;
show_front_label = true;

enable_base_vent = false;

// ---- DGX Spark reference dimensions ----
dgx_w = 150;
dgx_d = 150;
dgx_h = 50.5;
rack_u = 44.45;

// ---- Tray fit and stack geometry ----
fit_clearance_xy = 2.0;
top_clearance = 5.5;
floor_t = 4.0;
tray_h = 60.0;             // floor_t + dgx_h + top_clearance
stack_count = 4;

cavity_w = dgx_w + 2 * fit_clearance_xy;
cavity_d = dgx_d + 2 * fit_clearance_xy;

outer_w = 192;
outer_d = 192;

// The roof cap is deliberately only the tray-floor slice: no columns, no lips.
top_slice_t = floor_t;
top_slice_pad = floor_t/2;

post_size = 18;
post_cx = outer_w / 2 - post_size / 2;
post_cy = outer_d / 2 - post_size / 2;

rail_t = 6;
rail_h = 8;
rear_keeper_w = 24;
rear_keeper_h = 6; 

// ---- Alignment sockets and removable pins ----
align_pin_d = 8.8;
align_pin_h = 8.0;
align_pin_chamfer_h = 0.8;
socket_d = 8.8;
socket_clear_depth = align_pin_h / 2 + 0.5;
socket_roof_h = socket_d / 2;   // conic roof removes bottom-socket bridging

// ---- Heat-set inserts and screws ----
insert_od = 4.6;
insert_depth = 5.8;
insert_relief_d = 3.4;
insert_relief_depth = 4.0;
insert_teardrop_rise = 0.0;//1.1;
side_insert_z_bottom = 14;
side_insert_z_top = tray_h - 14;

m3_clearance_d = 3.4;
m3_head_d = 6.6;
m3_head_depth = 2.2;

// ---- Seam joiners ----
joiner_t = 4.0;
joiner_w = 16.0;
joiner_h = 118.0*2; // 44*x
joiner_gap = 0.35;
joiner_hole_offset = 14.0;  // aligns with top/bottom tray insert positions

eps = 0.05;

assert(tray_h >= floor_t + dgx_h + top_clearance,
       "tray_h is smaller than floor_t + dgx_h + top_clearance");
assert(outer_w >= cavity_w + 2 * post_size,
       "outer_w too small for DGX cavity plus posts");
assert(outer_d >= cavity_d + 2 * post_size,
       "outer_d too small for DGX cavity plus posts");

// ---------- helpers ----------

module rounded_square_2d(size, r = 2, center = true) {
  rr = max(0.01, min(r, min(size[0], size[1]) / 2 - 0.01));
  offset(r = rr)
    square([size[0] - 2 * rr, size[1] - 2 * rr], center = center);
}

module rbox(size, r = 2, center = true) {
  if (center) {
    translate([0, 0, -size[2] / 2])
      linear_extrude(height = size[2])
        rounded_square_2d([size[0], size[1]], r, true);
  } else {
    linear_extrude(height = size[2])
      rounded_square_2d([size[0], size[1]], r, false);
  }
}

module rboxc(size, pos = [0, 0, 0], r = 2) {
  translate(pos) rbox(size, r, true);
}

module rboxuc(size, pos = [0, 0, 0], r = 2) {
  translate(pos) rbox(size, r, false);
}


module teardrop_2d_xup(d, rise = 1.0) {
  r = d / 2;
  union() {
    circle(r = r);
    if (rise > 0.0)
    polygon(points = [[0, -r], [r + rise, 0], [0, r]]);
  }
}

module teardrop_hole_x(d, depth, rise = 1.0) {
  // Local +X of the 2D profile maps to global +Z, so the point is upward.
  rotate([0, -90, 0])
    linear_extrude(height = depth, center = true)
      teardrop_2d_xup(d, rise);
}

module corner_positions() {
  for (sx = [-1, 1])
    for (sy = [-1, 1])
      translate([sx * post_cx, sy * post_cy, 0]) children();
}

// ---------- tray cutouts/features ----------

module base_vent_slots() {
  slot_w = 4;
  slot_len = dgx_d - 16;
  for (x = [-52, -26, 0, 26, 52])
    rboxc([slot_w, slot_len, floor_t + 10 + 2 * eps], [x, 0, floor_t / 2], r = 4);
}

module top_alignment_socket_voids() {
  corner_positions()
    translate([0, 0, tray_h - socket_clear_depth])
      cylinder(d = socket_d, h = socket_clear_depth + eps);
}

module top_alignment_socket_pins() {
  corner_positions()
    translate([0, 0, tray_h ])
      cylinder(d = socket_d-0.2, h = socket_clear_depth + eps);
}

module bottom_alignment_socket_voids() {
  corner_positions()
    translate([0, 0, -eps]) {
      cylinder(d = socket_d, h = socket_clear_depth + eps);
      translate([0, 0, socket_clear_depth])
        cylinder(d1 = socket_d, d2 = 0.4, h = socket_roof_h);
    }
}

module side_insert_pocket_at(sx, sy, zpos) {
  // Main heat-set pocket, open from left/right outside face.
  translate([sx * (outer_w / 2 - insert_depth / 2 + eps),
             sy * post_cy,
             zpos])
    teardrop_hole_x(insert_od, insert_depth + 2 * eps, insert_teardrop_rise);

  // Smaller screw-tip relief just behind the insert.
  translate([sx * (outer_w / 2 - insert_depth - insert_relief_depth / 2 + eps),
             sy * post_cy,
             zpos])
    teardrop_hole_x(insert_relief_d, insert_relief_depth + 2 * eps, insert_teardrop_rise);
}

module side_insert_pockets() {
  for (sx = [-1, 1])
    for (sy = [-1, 1])
      for (zpos = [side_insert_z_bottom, side_insert_z_top])
        side_insert_pocket_at(sx, sy, zpos);
}

module front_label_marking() {
  if (show_front_label) {
    translate([0, -(cavity_d / 2 + rail_t / 2), floor_t + rail_h + 0.05])
      linear_extrude(height = 0.55)
        text(front_label, size = 4.5, halign = "center", valign = "center");
  }
}

// ---------- main printable tray ----------

module spark_tray() {
  difference() {
    union() {
      // Flat print bed contact: entire underside starts at Z=0.
      rboxc([outer_w, outer_d, floor_t], [0, 0, floor_t / 2], r = 3.5);

      // Four vertical load posts. No top frame; the next tray bears on these posts.
      corner_positions()
        rboxc([post_size, post_size, tray_h], [0, 0, tray_h / 2], r = 2.5);

      // Low DGX retention lips. Rear center remains open for I/O and cables.
      rboxc([rail_t, cavity_d, rail_h],
            [-(cavity_w / 2 + rail_t / 2), 0, floor_t + rail_h / 2], r = 1.4);
      rboxc([rail_t, cavity_d, rail_h],
            [ (cavity_w / 2 + rail_t / 2), 0, floor_t + rail_h / 2], r = 1.4);
      rboxc([cavity_w + 2 * rail_t, rail_t, rail_h],
            [0, -(cavity_d / 2 + rail_t / 2), floor_t + rail_h / 2], r = 1.4);

      for (sx = [-1, 1])
        rboxc([rear_keeper_w, rail_t, rear_keeper_h],
              [sx * (cavity_w / 2 - rear_keeper_w / 2),
               cavity_d / 2 + rail_t / 2,
               floor_t + rear_keeper_h / 2], r = 1.3);

      front_label_marking();
      
      top_alignment_socket_pins();
    }
    
    if (enable_base_vent)
        base_vent_slots();
    bottom_alignment_socket_voids();
    side_insert_pockets();
    for (sx = [0 : 20 : 140]) {
          rboxuc([15, rail_t+4, 3],
            [-(cavity_w/2) + sx - 0.5, -(cavity_d / 2 + rail_t +2), floor_t +0.5], r = 0);
    }
  }
}

// ---------- separate printable roof cap ----------

module top_slice_pin_holes() {
  // Through-holes avoid blind-hole bridging and still capture the top alignment pins.
  corner_positions()
    translate([0, 0, -eps])
      cylinder(d = socket_d, h = top_slice_t + 2 + 2 * eps);
}

module top_slice() {
  difference() {
    rboxc([outer_w, outer_d, top_slice_t + top_slice_pad],
          [0, 0, top_slice_t ], r = 3.5);
      
    if (enable_base_vent)
        base_vent_slots();
    top_slice_pin_holes();
  }
}

// ---------- separate printable alignment pin ----------

module align_pin() {
  union() {
    cylinder(d1 = align_pin_d - 0.8, d2 = align_pin_d,
             h = align_pin_chamfer_h);
    translate([0, 0, align_pin_chamfer_h])
      cylinder(d = align_pin_d,
               h = align_pin_h - 2 * align_pin_chamfer_h);
    translate([0, 0, align_pin_h - align_pin_chamfer_h])
      cylinder(d1 = align_pin_d, d2 = align_pin_d - 0.8,
               h = align_pin_chamfer_h);
  }
}

module installed_alignment_pins(include_top = false) {
  if (show_alignment_pins) {
    max_seam = include_top ? stack_count : stack_count - 1;
    for (seam = [1 : max_seam])
      corner_positions()
        translate([0, 0, seam * tray_h - align_pin_h / 2])
          align_pin();
  }
}

// ---------- separate printable seam joiner ----------

module side_joiner_print(seam = 2) {
  difference() {
    // Same geometry as installed, but kept in print orientation:
    // installed Z -> print X
    rboxc([joiner_h, joiner_w, joiner_t], [0, 0, joiner_t / 2], r = 2);

    z_center = seam * tray_h;

    for (z0_i = [0 : tray_h : tray_h * 4]) {
      for (zpos = [z0_i - joiner_hole_offset
                 : joiner_hole_offset * 2
                 : z0_i + joiner_hole_offset * 2]) {

        xpos = zpos - z_center;

        translate([xpos, 0, joiner_t / 2])
          cylinder(d = m3_clearance_d,
                   h = joiner_t + 2 * eps,
                   center = true);

        translate([xpos, 0, joiner_t - m3_head_depth / 2 + eps])
          cylinder(d = m3_head_d,
                   h = m3_head_depth + 2 * eps,
                   center = true);
      }
    }
  }
}

module side_joiner_installed(sx = 1, sy = 1, seam = 1) {
  x0 = sx * (outer_w / 2 + joiner_gap + joiner_t / 2);
  y0 = sy * post_cy;
  z0 = seam * tray_h;

  difference() {
    rboxc([joiner_t, joiner_w, joiner_h], [x0, y0, z0], r = 2);
      
    for (z0_i = [0 : tray_h :tray_h*4]){

        for (zpos = [z0_i - joiner_hole_offset : joiner_hole_offset * 2 : z0_i + joiner_hole_offset* 2]) {
          translate([x0, y0, zpos])
            rotate([0, 90, 0])
              cylinder(d = m3_clearance_d, h = joiner_t + 2 * eps, center = true);

          translate([sx * (outer_w / 2 + joiner_gap + joiner_t - m3_head_depth / 2 + eps),
                     y0,
                     zpos])
            rotate([0, 90, 0])
              cylinder(d = m3_head_d, h = m3_head_depth + 2 * eps, center = true);
        }
    }
  }
}

module side_joiner_set() {
  if (!show_joiners) {
    for (seam = [1 : stack_count - 1])
      for (sx = [-1, 1])
        for (sy = [-1, 1])
          side_joiner_installed(sx, sy, seam);
  }
  for (sx = [-1, 1])
        for (sy = [-1, 1])
            side_joiner_installed(sx, sy, 2);
}

// ---------- preview placeholder ----------

module dgx_spark_placeholder(alpha = 0.65){
    color([0.95, 0, 0, alpha])
        translate([0, 0, dgx_h/2 + 8]) 
            dgx_spark_ref();
}

module dgx_spark_placeholder_(alpha = 0.35) {
  color([0.04, 0.04, 0.04, alpha])
    rboxc([dgx_w, dgx_d, dgx_h], [0, 0, floor_t + dgx_h / 2], r = 5);

  // Rear I/O zone marker at +Y; rack leaves this region open.
  color([0.0, 0.35, 0.0, alpha])
    rboxc([100, 1.6, 18], [0, dgx_d / 2 + 0.9, floor_t + 20], r = 0.6);
}

module stack4_assembly() {
  for (i = [0 : stack_count - 1]) {
    translate([0, 0, i * tray_h]) {
      spark_tray();
      if (show_device_preview) dgx_spark_placeholder();
    }
  }
  if (show_top_slice)
    translate([0, 0, stack_count * tray_h - top_slice_pad+1])
      top_slice();

  //installed_alignment_pins(show_top_slice);
  side_joiner_set();
}

// ---------- part selection ----------

if (part == "tray") {
  spark_tray();
} else if (part == "top_slice") {
  top_slice();
} else if (part == "side_joiner") {
  side_joiner_print();
} else if (part == "align_pin") {
  align_pin();
} else if (part == "device") {
  dgx_spark_placeholder(alpha = 0.75);
} else {
  stack4_assembly();
}
