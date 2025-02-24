// RUN: onnx-mlir-opt --shape-inference --convert-onnx-to-krnl --canonicalize %s -split-input-file | FileCheck %s

// Adding canonicalize is important here as this is the only way to check the values of the map,
// which are otherwise before the function, and thus are hard to test.

func.func private @test_conv_unknown_dimensions(%arg0 : tensor<?x?x?x?xf32>, %arg1 : tensor<5x2x6x7xf32>, %arg2 : tensor<5xf32>) -> tensor<*xf32> {
  %0 = "onnx.Conv"(%arg0, %arg1, %arg2) {auto_pad = "NOTSET", group = 1 : si64} : (tensor<?x?x?x?xf32>, tensor<5x2x6x7xf32>, tensor<5xf32>) -> tensor<*xf32>
  "func.return"(%0) : (tensor<*xf32>) -> ()

// mlir2FileCheck.py -a'["image", "filter", "bias"]'
// CHECK-DAG:   [[MAP_0_:#.+]] = affine_map<()[s0] -> (s0 - 5)>
// CHECK-DAG:   [[MAP_1_:#.+]] = affine_map<()[s0] -> (s0 - 6)>
// CHECK-DAG:   [[MAP_2_:#.+]] = affine_map<(d0, d1, d2) -> (d2)>
// CHECK-DAG:   [[MAP_3_:#.+]] = affine_map<(d0, d1) -> (d0 * 5 + d1)>
// CHECK-DAG:   [[MAP_4_:#.+]] = affine_map<(d0, d1)[s0] -> (s0)>
// CHECK-DAG:   [[MAP_5_:#.+]] = affine_map<(d0, d1)[s0, s1] -> (s1)>
// CHECK-DAG:   [[MAP_6_:#.+]] = affine_map<(d0) -> (-d0, 0)>
// CHECK-DAG:   [[MAP_7_:#.+]] = affine_map<(d0)[s0] -> (-d0 + s0, 6)>
// CHECK-DAG:   [[MAP_8_:#.+]] = affine_map<(d0, d1)[s0] -> (-d1, 0)>
// CHECK-DAG:   [[MAP_9_:#.+]] = affine_map<(d0, d1)[s0, s1] -> (-d1 + s1, 7)>
// CHECK-DAG:   [[MAP_10_:#.+]] = affine_map<(d0, d1) -> (d0 + d1 * 2)>
// CHECK-DAG:   [[MAP_11_:#.+]] = affine_map<(d0, d1) -> (d0 + d1)>
// CHECK-LABEL:  func private @test_conv_unknown_dimensions
// CHECK-SAME:   ([[IMAGE_:%.+]]: memref<?x?x?x?xf32>, [[FILTER_:%.+]]: memref<5x2x6x7xf32>, [[BIAS_:%.+]]: memref<5xf32>) -> memref<?x5x?x?xf32> {
// CHECK-DAG:       [[CST_0_dot_000000_:%.+]] = arith.constant 0.000000e+00 : f32
// CHECK-DAG:       [[CST_3_:%.+]] = arith.constant 3 : index
// CHECK-DAG:       [[CST_2_:%.+]] = arith.constant 2 : index
// CHECK-DAG:       [[CST_0_:%.+]] = arith.constant 0 : index
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:       [[VAR_0_:%.+]] = memref.dim [[IMAGE_]], [[CST_0_]] : memref<?x?x?x?xf32>
// CHECK-DAG:       [[VAR_1_:%.+]] = memref.dim [[IMAGE_]], [[CST_2_]] : memref<?x?x?x?xf32>
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:       [[VAR_2_:%.+]] = affine.apply [[MAP_0_]](){{.}}[[VAR_1_]]{{.}}
// CHECK-DAG:       [[VAR_3_:%.+]] = memref.dim [[IMAGE_]], [[CST_3_]] : memref<?x?x?x?xf32>
// CHECK:           [[VAR_4_:%.+]] = affine.apply [[MAP_1_]](){{.}}[[VAR_3_]]{{.}}
// CHECK-DAG:       [[VAR_5_:%.+]] = memref.alloc([[VAR_0_]], [[VAR_2_]], [[VAR_4_]]) {{.*}}: memref<?x5x?x?xf32>
// CHECK-DAG:       [[VAR_11_:%.+]] = memref.alloca() : memref<f32>
// CHECK-DAG:       [[LOOP_0_:%.+]]:3 = krnl.define_loops 3
// CHECK:           krnl.iterate([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) with ([[LOOP_0_]]#0 -> [[I_0_:%.+]] = 0 to [[MAP_2_]]([[VAR_1_]], [[VAR_3_]], [[VAR_0_]]), [[LOOP_0_]]#1 -> [[I_1_:%.+]] = 0 to 1, [[LOOP_0_]]#2 -> [[I_2_:%.+]] = 0 to 5){
// CHECK:             [[VAR_7_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:         [[VAR_8_:%.+]] = affine.apply [[MAP_3_]]([[VAR_7_]]#1, [[VAR_7_]]#2)
// CHECK-DAG:         [[LOOP_1_:%.+]]:2 = krnl.define_loops 2
// CHECK:             krnl.iterate([[LOOP_1_]]#0, [[LOOP_1_]]#1) with ([[LOOP_1_]]#0 -> [[I_3_:%.+]] = 0 to [[MAP_4_]]([[VAR_7_]]#1, [[VAR_7_]]#2){{.}}[[VAR_2_]]{{.}}, [[LOOP_1_]]#1 -> [[I_4_:%.+]] = 0 to [[MAP_5_]]([[VAR_7_]]#1, [[VAR_7_]]#2){{.}}[[VAR_2_]], [[VAR_4_]]{{.}}){
// CHECK-DAG:           [[VAR_10_:%.+]]:2 = krnl.get_induction_var_value([[LOOP_1_]]#0, [[LOOP_1_]]#1) : (!krnl.loop, !krnl.loop) -> (index, index)
// CHECK:               krnl.store [[CST_0_dot_000000_]], [[VAR_11_]][] : memref<f32>
// CHECK-DAG:           [[LOOP_2_:%.+]]:3 = krnl.define_loops 3
// CHECK-DAG:           [[VAR_13_:%.+]] = memref.dim [[IMAGE_]], [[CST_2_]] : memref<?x?x?x?xf32>
// CHECK-DAG:           [[VAR_14_:%.+]] = memref.dim [[IMAGE_]], [[CST_3_]] : memref<?x?x?x?xf32>
// CHECK:               krnl.iterate([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) with ([[LOOP_2_]]#0 -> [[I_5_:%.+]] = 0 to 2, [[LOOP_2_]]#1 -> [[I_6_:%.+]] = max [[MAP_6_]]([[VAR_10_]]#0) to min [[MAP_7_]]([[VAR_10_]]#0){{.}}[[VAR_13_]]{{.}}, [[LOOP_2_]]#2 -> [[I_7_:%.+]] = max [[MAP_8_]]([[VAR_10_]]#0, [[VAR_10_]]#1){{.}}[[VAR_13_]]{{.}} to min [[MAP_9_]]([[VAR_10_]]#0, [[VAR_10_]]#1){{.}}[[VAR_13_]], [[VAR_14_]]{{.}}){
// CHECK:                 [[VAR_18_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:             [[VAR_19_:%.+]] = affine.apply [[MAP_10_]]([[VAR_18_]]#0, [[VAR_7_]]#1)
// CHECK-DAG:             [[VAR_20_:%.+]] = affine.apply [[MAP_11_]]([[VAR_18_]]#1, [[VAR_10_]]#0)
// CHECK-DAG:             [[VAR_21_:%.+]] = affine.apply [[MAP_11_]]([[VAR_18_]]#2, [[VAR_10_]]#1)
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:             [[LOAD_IMAGE_MEM_:%.+]] = krnl.load [[IMAGE_]]{{.}}[[VAR_7_]]#0, [[VAR_19_]], [[VAR_20_]], [[VAR_21_]]{{.}} : memref<?x?x?x?xf32>
// CHECK-DAG:             [[LOAD_FILTER_MEM_:%.+]] = krnl.load [[FILTER_]]{{.}}[[VAR_8_]], [[VAR_18_]]#0, [[VAR_18_]]#1, [[VAR_18_]]#2] : memref<5x2x6x7xf32>
// CHECK-DAG:             [[LOAD_VAR_11_MEM_:%.+]] = krnl.load [[VAR_11_]][] : memref<f32>
// CHECK:                 [[VAR_25_:%.+]] = arith.mulf [[LOAD_IMAGE_MEM_]], [[LOAD_FILTER_MEM_]] : f32
// CHECK:                 [[VAR_26_:%.+]] = arith.addf [[LOAD_VAR_11_MEM_]], [[VAR_25_]] : f32
// CHECK:                 krnl.store [[VAR_26_]], [[VAR_11_]][] : memref<f32>
// CHECK:               }
// CHECK-DAG:           [[LOAD_VAR_11_MEM_1_:%.+]] = krnl.load [[VAR_11_]][] : memref<f32>
// CHECK-DAG:           [[LOAD_BIAS_MEM_:%.+]] = krnl.load [[BIAS_]]{{.}}[[VAR_8_]]{{.}} : memref<5xf32>
// CHECK:               [[VAR_17_:%.+]] = arith.addf [[LOAD_VAR_11_MEM_1_]], [[LOAD_BIAS_MEM_]] : f32
// CHECK:               krnl.store [[VAR_17_]], [[VAR_5_]]{{.}}[[VAR_7_]]#0, [[VAR_8_]], [[VAR_10_]]#0, [[VAR_10_]]#1] : memref<?x5x?x?xf32>
// CHECK:             }
// CHECK:           }
// CHECK:           return [[VAR_5_]] : memref<?x5x?x?xf32>
// CHECK:         }
}

// -----

func.func private @test_conv_no_bias_no_pad(%arg0 : tensor<1x2x32x64xf32>, %arg1 : tensor<5x2x6x7xf32>) -> tensor<*xf32> {
  %cst = "onnx.NoValue"() {value} : () -> none
  %0 = "onnx.Conv"(%arg0, %arg1, %cst) {auto_pad = "NOTSET", group = 1 : si64} : (tensor<1x2x32x64xf32>, tensor<5x2x6x7xf32>, none) -> tensor<*xf32>
  "func.return"(%0) : (tensor<*xf32>) -> ()

// mlir2FileCheck.py -a'["image", "filter", "bias"]'
// CHECK-DAG:   [[MAP_0_:#.+]] = affine_map<(d0, d1) -> (d0 * 5 + d1)>
// CHECK-DAG:   [[MAP_1_:#.+]] = affine_map<(d0) -> (-d0, 0)>
// CHECK-DAG:   [[MAP_2_:#.+]] = affine_map<(d0) -> (-d0 + 32, 6)>
// CHECK-DAG:   [[MAP_3_:#.+]] = affine_map<(d0, d1) -> (-d1, 0)>
// CHECK-DAG:   [[MAP_4_:#.+]] = affine_map<(d0, d1) -> (-d1 + 64, 7)>
// CHECK-DAG:   [[MAP_5_:#.+]] = affine_map<(d0, d1) -> (d0 + d1 * 2)>
// CHECK-DAG:   [[MAP_6_:#.+]] = affine_map<(d0, d1) -> (d0 + d1)>
// CHECK-LABEL:  func private @test_conv_no_bias_no_pad
// CHECK-SAME:   ([[IMAGE_:%.+]]: memref<1x2x32x64xf32>, [[FILTER_:%.+]]: memref<5x2x6x7xf32>) -> memref<1x5x27x58xf32> {
// CHECK-DAG:       [[CST_0_dot_000000_:%.+]] = arith.constant 0.000000e+00 : f32
// CHECK-DAG:       [[VAR_0_:%.+]] = memref.alloc() {{.*}}: memref<1x5x27x58xf32>
// CHECK-DAG:       [[VAR_6_:%.+]] = memref.alloca() : memref<f32>
// CHECK-DAG:       [[LOOP_0_:%.+]]:3 = krnl.define_loops 3
// CHECK:           krnl.iterate([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) with ([[LOOP_0_]]#0 -> [[BIAS_:%.+]] = 0 to 1, [[LOOP_0_]]#1 -> [[I_0_:%.+]] = 0 to 1, [[LOOP_0_]]#2 -> [[I_1_:%.+]] = 0 to 5){
// CHECK:             [[VAR_2_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:         [[VAR_3_:%.+]] = affine.apply [[MAP_0_]]([[VAR_2_]]#1, [[VAR_2_]]#2)
// CHECK-DAG:         [[LOOP_1_:%.+]]:2 = krnl.define_loops 2
// CHECK:             krnl.iterate([[LOOP_1_]]#0, [[LOOP_1_]]#1) with ([[LOOP_1_]]#0 -> [[I_2_:%.+]] = 0 to 27, [[LOOP_1_]]#1 -> [[I_3_:%.+]] = 0 to 58){
// CHECK-DAG:           [[VAR_5_:%.+]]:2 = krnl.get_induction_var_value([[LOOP_1_]]#0, [[LOOP_1_]]#1) : (!krnl.loop, !krnl.loop) -> (index, index)
// CHECK:               krnl.store [[CST_0_dot_000000_]], [[VAR_6_]][] : memref<f32>
// CHECK:               [[LOOP_2_:%.+]]:3 = krnl.define_loops 3
// CHECK:               krnl.iterate([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) with ([[LOOP_2_]]#0 -> [[I_4_:%.+]] = 0 to 2, [[LOOP_2_]]#1 -> [[I_5_:%.+]] = max [[MAP_1_]]([[VAR_5_]]#0) to min [[MAP_2_]]([[VAR_5_]]#0), [[LOOP_2_]]#2 -> [[I_6_:%.+]] = max [[MAP_3_]]([[VAR_5_]]#0, [[VAR_5_]]#1) to min [[MAP_4_]]([[VAR_5_]]#0, [[VAR_5_]]#1)){
// CHECK:                 [[VAR_9_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:             [[VAR_10_:%.+]] = affine.apply [[MAP_5_]]([[VAR_9_]]#0, [[VAR_2_]]#1)
// CHECK-DAG:             [[VAR_11_:%.+]] = affine.apply [[MAP_6_]]([[VAR_9_]]#1, [[VAR_5_]]#0)
// CHECK-DAG:             [[VAR_12_:%.+]] = affine.apply [[MAP_6_]]([[VAR_9_]]#2, [[VAR_5_]]#1)
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:             [[LOAD_IMAGE_MEM_:%.+]] = krnl.load [[IMAGE_]]{{.}}[[VAR_2_]]#0, [[VAR_10_]], [[VAR_11_]], [[VAR_12_]]{{.}} : memref<1x2x32x64xf32>
// CHECK-DAG:             [[LOAD_FILTER_MEM_:%.+]] = krnl.load [[FILTER_]]{{.}}[[VAR_3_]], [[VAR_9_]]#0, [[VAR_9_]]#1, [[VAR_9_]]#2] : memref<5x2x6x7xf32>
// CHECK-DAG:             [[LOAD_VAR_6_MEM_:%.+]] = krnl.load [[VAR_6_]][] : memref<f32>
// CHECK:                 [[VAR_16_:%.+]] = arith.mulf [[LOAD_IMAGE_MEM_]], [[LOAD_FILTER_MEM_]] : f32
// CHECK:                 [[VAR_17_:%.+]] = arith.addf [[LOAD_VAR_6_MEM_]], [[VAR_16_]] : f32
// CHECK:                 krnl.store [[VAR_17_]], [[VAR_6_]][] : memref<f32>
// CHECK:               }
// CHECK:               [[LOAD_VAR_6_MEM_1_:%.+]] = krnl.load [[VAR_6_]][] : memref<f32>
// CHECK:               krnl.store [[LOAD_VAR_6_MEM_1_]], [[VAR_0_]]{{.}}[[VAR_2_]]#0, [[VAR_3_]], [[VAR_5_]]#0, [[VAR_5_]]#1] : memref<1x5x27x58xf32>
// CHECK:             }
// CHECK:           }
// CHECK:           return [[VAR_0_]] : memref<1x5x27x58xf32>
// CHECK:         }
}

// -----

func.func private @test_conv_bias_no_pad(%arg0 : tensor<1x2x32x64xf32>, %arg1 : tensor<5x2x6x7xf32>, %arg2 : tensor<5xf32>) -> tensor<*xf32> {
  %0 = "onnx.Conv"(%arg0, %arg1, %arg2) {auto_pad = "NOTSET", group = 1 : si64} : (tensor<1x2x32x64xf32>, tensor<5x2x6x7xf32>, tensor<5xf32>) -> tensor<*xf32>
  "func.return"(%0) : (tensor<*xf32>) -> ()

// mlir2FileCheck.py -a'["image", "filter", "bias"]'
// CHECK-DAG:   [[MAP_0_:#.+]] = affine_map<(d0, d1) -> (d0 * 5 + d1)>
// CHECK-DAG:   [[MAP_1_:#.+]] = affine_map<(d0) -> (-d0, 0)>
// CHECK-DAG:   [[MAP_2_:#.+]] = affine_map<(d0) -> (-d0 + 32, 6)>
// CHECK-DAG:   [[MAP_3_:#.+]] = affine_map<(d0, d1) -> (-d1, 0)>
// CHECK-DAG:   [[MAP_4_:#.+]] = affine_map<(d0, d1) -> (-d1 + 64, 7)>
// CHECK-DAG:   [[MAP_5_:#.+]] = affine_map<(d0, d1) -> (d0 + d1 * 2)>
// CHECK-DAG:   [[MAP_6_:#.+]] = affine_map<(d0, d1) -> (d0 + d1)>
// CHECK-LABEL:  func private @test_conv_bias_no_pad
// CHECK-SAME:   ([[IMAGE_:%.+]]: memref<1x2x32x64xf32>, [[FILTER_:%.+]]: memref<5x2x6x7xf32>, [[BIAS_:%.+]]: memref<5xf32>) -> memref<1x5x27x58xf32> {
// CHECK-DAG:       [[CST_0_dot_000000_:%.+]] = arith.constant 0.000000e+00 : f32
// CHECK-DAG:       [[VAR_0_:%.+]] = memref.alloc() {{.*}}: memref<1x5x27x58xf32>
// CHECK-DAG:       [[VAR_6_:%.+]] = memref.alloca() : memref<f32>
// CHECK-DAG:       [[LOOP_0_:%.+]]:3 = krnl.define_loops 3
// CHECK:           krnl.iterate([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) with ([[LOOP_0_]]#0 -> [[I_0_:%.+]] = 0 to 1, [[LOOP_0_]]#1 -> [[I_1_:%.+]] = 0 to 1, [[LOOP_0_]]#2 -> [[I_2_:%.+]] = 0 to 5){
// CHECK:             [[VAR_2_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:         [[VAR_3_:%.+]] = affine.apply [[MAP_0_]]([[VAR_2_]]#1, [[VAR_2_]]#2)
// CHECK-DAG:         [[LOOP_1_:%.+]]:2 = krnl.define_loops 2
// CHECK:             krnl.iterate([[LOOP_1_]]#0, [[LOOP_1_]]#1) with ([[LOOP_1_]]#0 -> [[I_3_:%.+]] = 0 to 27, [[LOOP_1_]]#1 -> [[I_4_:%.+]] = 0 to 58){
// CHECK-DAG:           [[VAR_5_:%.+]]:2 = krnl.get_induction_var_value([[LOOP_1_]]#0, [[LOOP_1_]]#1) : (!krnl.loop, !krnl.loop) -> (index, index)
// CHECK:               krnl.store [[CST_0_dot_000000_]], [[VAR_6_]][] : memref<f32>
// CHECK:               [[LOOP_2_:%.+]]:3 = krnl.define_loops 3
// CHECK:               krnl.iterate([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) with ([[LOOP_2_]]#0 -> [[I_5_:%.+]] = 0 to 2, [[LOOP_2_]]#1 -> [[I_6_:%.+]] = max [[MAP_1_]]([[VAR_5_]]#0) to min [[MAP_2_]]([[VAR_5_]]#0), [[LOOP_2_]]#2 -> [[I_7_:%.+]] = max [[MAP_3_]]([[VAR_5_]]#0, [[VAR_5_]]#1) to min [[MAP_4_]]([[VAR_5_]]#0, [[VAR_5_]]#1)){
// CHECK:                 [[VAR_11_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:             [[VAR_12_:%.+]] = affine.apply [[MAP_5_]]([[VAR_11_]]#0, [[VAR_2_]]#1)
// CHECK-DAG:             [[VAR_13_:%.+]] = affine.apply [[MAP_6_]]([[VAR_11_]]#1, [[VAR_5_]]#0)
// CHECK-DAG:             [[VAR_14_:%.+]] = affine.apply [[MAP_6_]]([[VAR_11_]]#2, [[VAR_5_]]#1)
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:             [[LOAD_IMAGE_MEM_:%.+]] = krnl.load [[IMAGE_]]{{.}}[[VAR_2_]]#0, [[VAR_12_]], [[VAR_13_]], [[VAR_14_]]{{.}} : memref<1x2x32x64xf32>
// CHECK-DAG:             [[LOAD_FILTER_MEM_:%.+]] = krnl.load [[FILTER_]]{{.}}[[VAR_3_]], [[VAR_11_]]#0, [[VAR_11_]]#1, [[VAR_11_]]#2] : memref<5x2x6x7xf32>
// CHECK-DAG:             [[LOAD_VAR_6_MEM_:%.+]] = krnl.load [[VAR_6_]][] : memref<f32>
// CHECK:                 [[VAR_18_:%.+]] = arith.mulf [[LOAD_IMAGE_MEM_]], [[LOAD_FILTER_MEM_]] : f32
// CHECK:                 [[VAR_19_:%.+]] = arith.addf [[LOAD_VAR_6_MEM_]], [[VAR_18_]] : f32
// CHECK:                 krnl.store [[VAR_19_]], [[VAR_6_]][] : memref<f32>
// CHECK:               }
// CHECK-DAG:           [[LOAD_VAR_6_MEM_1_:%.+]] = krnl.load [[VAR_6_]][] : memref<f32>
// CHECK-DAG:           [[LOAD_BIAS_MEM_:%.+]] = krnl.load [[BIAS_]]{{.}}[[VAR_3_]]{{.}} : memref<5xf32>
// CHECK:               [[VAR_10_:%.+]] = arith.addf [[LOAD_VAR_6_MEM_1_]], [[LOAD_BIAS_MEM_]] : f32
// CHECK:               krnl.store [[VAR_10_]], [[VAR_0_]]{{.}}[[VAR_2_]]#0, [[VAR_3_]], [[VAR_5_]]#0, [[VAR_5_]]#1] : memref<1x5x27x58xf32>
// CHECK:             }
// CHECK:           }
// CHECK:           return [[VAR_0_]] : memref<1x5x27x58xf32>
// CHECK:         }
}

// -----

func.func private @test_conv_no_bias_no_pad_w_group(%arg0 : tensor<1x9x32x64xf32>, %arg1 : tensor<6x3x6x7xf32>) -> tensor<*xf32> {
  %cst = "onnx.NoValue"() {value} : () -> none
  %0 = "onnx.Conv"(%arg0, %arg1, %cst) {auto_pad = "NOTSET", group = 3 : si64} : (tensor<1x9x32x64xf32>, tensor<6x3x6x7xf32>, none) -> tensor<*xf32>
  "func.return"(%0) : (tensor<*xf32>) -> ()

// mlir2FileCheck.py -a'["image", "filter", "bias"]'
// CHECK-DAG:   [[MAP_0_:#.+]] = affine_map<(d0, d1) -> (d0 * 2 + d1)>
// CHECK-DAG:   [[MAP_1_:#.+]] = affine_map<(d0) -> (-d0, 0)>
// CHECK-DAG:   [[MAP_2_:#.+]] = affine_map<(d0) -> (-d0 + 32, 6)>
// CHECK-DAG:   [[MAP_3_:#.+]] = affine_map<(d0, d1) -> (-d1, 0)>
// CHECK-DAG:   [[MAP_4_:#.+]] = affine_map<(d0, d1) -> (-d1 + 64, 7)>
// CHECK-DAG:   [[MAP_5_:#.+]] = affine_map<(d0, d1) -> (d0 + d1 * 3)>
// CHECK-DAG:   [[MAP_6_:#.+]] = affine_map<(d0, d1) -> (d0 + d1)>
// CHECK-LABEL:  func private @test_conv_no_bias_no_pad_w_group
// CHECK-SAME:   ([[IMAGE_:%.+]]: memref<1x9x32x64xf32>, [[FILTER_:%.+]]: memref<6x3x6x7xf32>) -> memref<1x6x27x58xf32> {
// CHECK-DAG:       [[CST_0_dot_000000_:%.+]] = arith.constant 0.000000e+00 : f32
// CHECK-DAG:       [[VAR_0_:%.+]] = memref.alloc() {{.*}}: memref<1x6x27x58xf32>
// CHECK-DAG:         [[VAR_6_:%.+]] = memref.alloca() : memref<f32>
// CHECK-DAG:       [[LOOP_0_:%.+]]:3 = krnl.define_loops 3
// CHECK:           krnl.iterate([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) with ([[LOOP_0_]]#0 -> [[BIAS_:%.+]] = 0 to 1, [[LOOP_0_]]#1 -> [[I_0_:%.+]] = 0 to 3, [[LOOP_0_]]#2 -> [[I_1_:%.+]] = 0 to 2){
// CHECK:             [[VAR_2_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:         [[VAR_3_:%.+]] = affine.apply [[MAP_0_]]([[VAR_2_]]#1, [[VAR_2_]]#2)
// CHECK-DAG:         [[LOOP_1_:%.+]]:2 = krnl.define_loops 2
// CHECK:             krnl.iterate([[LOOP_1_]]#0, [[LOOP_1_]]#1) with ([[LOOP_1_]]#0 -> [[I_2_:%.+]] = 0 to 27, [[LOOP_1_]]#1 -> [[I_3_:%.+]] = 0 to 58){
// CHECK-DAG:           [[VAR_5_:%.+]]:2 = krnl.get_induction_var_value([[LOOP_1_]]#0, [[LOOP_1_]]#1) : (!krnl.loop, !krnl.loop) -> (index, index)
// CHECK:               krnl.store [[CST_0_dot_000000_]], [[VAR_6_]][] : memref<f32>
// CHECK:               [[LOOP_2_:%.+]]:3 = krnl.define_loops 3
// CHECK:               krnl.iterate([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) with ([[LOOP_2_]]#0 -> [[I_4_:%.+]] = 0 to 3, [[LOOP_2_]]#1 -> [[I_5_:%.+]] = max [[MAP_1_]]([[VAR_5_]]#0) to min [[MAP_2_]]([[VAR_5_]]#0), [[LOOP_2_]]#2 -> [[I_6_:%.+]] = max [[MAP_3_]]([[VAR_5_]]#0, [[VAR_5_]]#1) to min [[MAP_4_]]([[VAR_5_]]#0, [[VAR_5_]]#1)){
// CHECK:                 [[VAR_9_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:             [[VAR_10_:%.+]] = affine.apply [[MAP_5_]]([[VAR_9_]]#0, [[VAR_2_]]#1)
// CHECK-DAG:             [[VAR_11_:%.+]] = affine.apply [[MAP_6_]]([[VAR_9_]]#1, [[VAR_5_]]#0)
// CHECK-DAG:             [[VAR_12_:%.+]] = affine.apply [[MAP_6_]]([[VAR_9_]]#2, [[VAR_5_]]#1)
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:             [[LOAD_IMAGE_MEM_:%.+]] = krnl.load [[IMAGE_]]{{.}}[[VAR_2_]]#0, [[VAR_10_]], [[VAR_11_]], [[VAR_12_]]{{.}} : memref<1x9x32x64xf32>
// CHECK-DAG:             [[LOAD_FILTER_MEM_:%.+]] = krnl.load [[FILTER_]]{{.}}[[VAR_3_]], [[VAR_9_]]#0, [[VAR_9_]]#1, [[VAR_9_]]#2] : memref<6x3x6x7xf32>
// CHECK-DAG:             [[LOAD_VAR_6_MEM_:%.+]] = krnl.load [[VAR_6_]][] : memref<f32>
// CHECK:                 [[VAR_16_:%.+]] = arith.mulf [[LOAD_IMAGE_MEM_]], [[LOAD_FILTER_MEM_]] : f32
// CHECK:                 [[VAR_17_:%.+]] = arith.addf [[LOAD_VAR_6_MEM_]], [[VAR_16_]] : f32
// CHECK:                 krnl.store [[VAR_17_]], [[VAR_6_]][] : memref<f32>
// CHECK:               }
// CHECK:               [[LOAD_VAR_6_MEM_1_:%.+]] = krnl.load [[VAR_6_]][] : memref<f32>
// CHECK:               krnl.store [[LOAD_VAR_6_MEM_1_]], [[VAR_0_]]{{.}}[[VAR_2_]]#0, [[VAR_3_]], [[VAR_5_]]#0, [[VAR_5_]]#1] : memref<1x6x27x58xf32>
// CHECK:             }
// CHECK:           }
// CHECK:           return [[VAR_0_]] : memref<1x6x27x58xf32>
// CHECK:         }
}

// -----

func.func private @test_conv_no_bias_no_pad_w_strides(%arg0 : tensor<1x9x32x64xf32>, %arg1 : tensor<5x9x6x7xf32>) -> tensor<*xf32> {
  %cst = "onnx.NoValue"() {value} : () -> none
  %0 = "onnx.Conv"(%arg0, %arg1, %cst) {auto_pad = "NOTSET", group = 1 : si64, strides = [2, 2]} : (tensor<1x9x32x64xf32>, tensor<5x9x6x7xf32>, none) -> tensor<*xf32>
  "func.return"(%0) : (tensor<*xf32>) -> ()

// mlir2FileCheck.py -a'["image", "filter", "bias"]'
// CHECK-DAG:   [[MAP_0_:#.+]] = affine_map<(d0, d1) -> (d0 * 5 + d1)>
// CHECK-DAG:   [[MAP_1_:#.+]] = affine_map<(d0) -> (d0 * -2, 0)>
// CHECK-DAG:   [[MAP_2_:#.+]] = affine_map<(d0) -> (d0 * -2 + 32, 6)>
// CHECK-DAG:   [[MAP_3_:#.+]] = affine_map<(d0, d1) -> (d1 * -2, 0)>
// CHECK-DAG:   [[MAP_4_:#.+]] = affine_map<(d0, d1) -> (d1 * -2 + 64, 7)>
// CHECK-DAG:   [[MAP_5_:#.+]] = affine_map<(d0, d1) -> (d0 + d1 * 9)>
// CHECK-DAG:   [[MAP_6_:#.+]] = affine_map<(d0, d1) -> (d0 + d1 * 2)>
// CHECK-LABEL:  func private @test_conv_no_bias_no_pad_w_strides
// CHECK-SAME:   ([[IMAGE_:%.+]]: memref<1x9x32x64xf32>, [[FILTER_:%.+]]: memref<5x9x6x7xf32>) -> memref<1x5x14x29xf32> {
// CHECK-DAG:       [[CST_0_dot_000000_:%.+]] = arith.constant 0.000000e+00 : f32
// CHECK-DAG:       [[VAR_0_:%.+]] = memref.alloc() {{.*}}: memref<1x5x14x29xf32>
// CHECK-DAG:       [[VAR_6_:%.+]] = memref.alloca() : memref<f32>
// CHECK-DAG:       [[LOOP_0_:%.+]]:3 = krnl.define_loops 3
// CHECK:           krnl.iterate([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) with ([[LOOP_0_]]#0 -> [[BIAS_:%.+]] = 0 to 1, [[LOOP_0_]]#1 -> [[I_0_:%.+]] = 0 to 1, [[LOOP_0_]]#2 -> [[I_1_:%.+]] = 0 to 5){
// CHECK:             [[VAR_2_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_0_]]#0, [[LOOP_0_]]#1, [[LOOP_0_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:         [[VAR_3_:%.+]] = affine.apply [[MAP_0_]]([[VAR_2_]]#1, [[VAR_2_]]#2)
// CHECK-DAG:         [[LOOP_1_:%.+]]:2 = krnl.define_loops 2
// CHECK:             krnl.iterate([[LOOP_1_]]#0, [[LOOP_1_]]#1) with ([[LOOP_1_]]#0 -> [[I_2_:%.+]] = 0 to 14, [[LOOP_1_]]#1 -> [[I_3_:%.+]] = 0 to 29){
// CHECK-DAG:           [[VAR_5_:%.+]]:2 = krnl.get_induction_var_value([[LOOP_1_]]#0, [[LOOP_1_]]#1) : (!krnl.loop, !krnl.loop) -> (index, index)
// CHECK:               krnl.store [[CST_0_dot_000000_]], [[VAR_6_]][] : memref<f32>
// CHECK:               [[LOOP_2_:%.+]]:3 = krnl.define_loops 3
// CHECK:               krnl.iterate([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) with ([[LOOP_2_]]#0 -> [[I_4_:%.+]] = 0 to 9, [[LOOP_2_]]#1 -> [[I_5_:%.+]] = max [[MAP_1_]]([[VAR_5_]]#0) to min [[MAP_2_]]([[VAR_5_]]#0), [[LOOP_2_]]#2 -> [[I_6_:%.+]] = max [[MAP_3_]]([[VAR_5_]]#0, [[VAR_5_]]#1) to min [[MAP_4_]]([[VAR_5_]]#0, [[VAR_5_]]#1)){
// CHECK:                 [[VAR_9_:%.+]]:3 = krnl.get_induction_var_value([[LOOP_2_]]#0, [[LOOP_2_]]#1, [[LOOP_2_]]#2) : (!krnl.loop, !krnl.loop, !krnl.loop) -> (index, index, index)
// CHECK-DAG:             [[VAR_10_:%.+]] = affine.apply [[MAP_5_]]([[VAR_9_]]#0, [[VAR_2_]]#1)
// CHECK-DAG:             [[VAR_11_:%.+]] = affine.apply [[MAP_6_]]([[VAR_9_]]#1, [[VAR_5_]]#0)
// CHECK-DAG:             [[VAR_12_:%.+]] = affine.apply [[MAP_6_]]([[VAR_9_]]#2, [[VAR_5_]]#1)
// CHECK-NOT: separator of consecutive DAGs
// CHECK-DAG:             [[LOAD_IMAGE_MEM_:%.+]] = krnl.load [[IMAGE_]]{{.}}[[VAR_2_]]#0, [[VAR_10_]], [[VAR_11_]], [[VAR_12_]]{{.}} : memref<1x9x32x64xf32>
// CHECK-DAG:             [[LOAD_FILTER_MEM_:%.+]] = krnl.load [[FILTER_]]{{.}}[[VAR_3_]], [[VAR_9_]]#0, [[VAR_9_]]#1, [[VAR_9_]]#2] : memref<5x9x6x7xf32>
// CHECK-DAG:             [[LOAD_VAR_6_MEM_:%.+]] = krnl.load [[VAR_6_]][] : memref<f32>
// CHECK:                 [[VAR_16_:%.+]] = arith.mulf [[LOAD_IMAGE_MEM_]], [[LOAD_FILTER_MEM_]] : f32
// CHECK:                 [[VAR_17_:%.+]] = arith.addf [[LOAD_VAR_6_MEM_]], [[VAR_16_]] : f32
// CHECK:                 krnl.store [[VAR_17_]], [[VAR_6_]][] : memref<f32>
// CHECK:               }
// CHECK:               [[LOAD_VAR_6_MEM_1_:%.+]] = krnl.load [[VAR_6_]][] : memref<f32>
// CHECK:               krnl.store [[LOAD_VAR_6_MEM_1_]], [[VAR_0_]]{{.}}[[VAR_2_]]#0, [[VAR_3_]], [[VAR_5_]]#0, [[VAR_5_]]#1] : memref<1x5x14x29xf32>
// CHECK:             }
// CHECK:           }
// CHECK:           return [[VAR_0_]] : memref<1x5x14x29xf32>
// CHECK:         }
}
