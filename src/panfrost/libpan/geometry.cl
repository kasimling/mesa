/*
 * Copyright 2025 Collabora Ltd.
 * SPDX-License-Identifier: MIT
 */

#include "poly/cl/restart.h"
#include "poly/geometry.h"

#if PAN_ARCH >= 10
static bool
panlib_get_draws(global uint32_t **out_draw,
                 uint32_t out_draw_stride_dw,
                 constant uint **in_draw,
                 uint32_t in_draw_stride_dw,
                 constant uint *in_draw_count,
                 enum mesa_prim mode)
{
   uint per_prim = mesa_vertices_per_prim(mode);

   *in_draw += cl_group_id.x * in_draw_stride_dw;
   *out_draw += cl_group_id.x * out_draw_stride_dw;

   bool skip_draw = in_draw_count && cl_group_id.x >= *in_draw_count;

   /* If we don't have enough vertices/indices for a complete prim, skip */
   if ((*in_draw)[0] < per_prim)
      skip_draw = true;

   if (skip_draw) {
      if (cl_local_id.x == 0) {
         for (uint i = 0; i < out_draw_stride_dw; i++)
            out_draw[i] = 0;
      }
      return false;
   } else {
      return true;
   }
}

KERNEL(16)
panlib_unroll_restart(global uint32_t *out_draw,
                      global struct poly_heap *heap,
                      constant uint *in_draw,
                      uint32_t in_draw_stride_dw,
                      constant uint *in_draw_count,
                      uint64_t index_buffer,
                      uint32_t index_buffer_range_el,
                      uint32_t index_size_log2,
                      uint32_t restart_index,
                      uint32_t flatshade_first,
                      uint mode__11)
{
   const uint32_t index_size_B = 1 << index_size_log2;
   const enum mesa_prim mode = poly_uncompact_prim(mode__11);

   if (!panlib_get_draws(&out_draw, 5, &in_draw, in_draw_stride_dw,
                         in_draw_count, mode))
      return;

   poly_unroll_restart(out_draw, heap, in_draw, index_buffer,
                       index_buffer_range_el, index_size_B, restart_index,
                       flatshade_first, mode, NULL);
}

KERNEL(1)
panlib_gs_setup_indirect(global struct poly_vertex_params *vp /* output */,
                         global struct poly_geometry_params *gp /* output */,
                         global struct poly_geometry_draw_params *gdp /* output */,
                         global struct poly_heap *heap,
                         uint64_t index_buffer,
                         uint32_t index_size_B /* 0 if no index bffer */,
                         uint32_t index_buffer_range_el,
                         constant uint *draw,
                         uint64_t vs_outputs /* Vertex (TES) output mask */,
                         uint prim /* Input primitive type, mesa_prim */,
                         uint is_prefix_summing,
                         uint max_indices,
                         uint shape /* poly_gs_shape */)
{
   poly_gs_setup_indirect(index_buffer, draw, 0, 0, vp, gp, gdp, heap,
                          vs_outputs, index_size_B, index_buffer_range_el, prim,
                          is_prefix_summing, max_indices, false, shape);
}

KERNEL(1)
panlib_gs_setup_indirect_byte_count(global struct poly_vertex_params *vp /* output */,
                                    global struct poly_geometry_params *gp /* output */,
                                    global struct poly_geometry_draw_params *gdp /* output */,
                                    global struct poly_heap *heap,
                                    constant uint *byte_count,
                                    uint instance_count,
                                    uint counter_offset,
                                    uint vertex_stride,
                                    uint64_t vs_outputs /* Vertex (TES) output mask */,
                                    uint prim /* Input primitive type, mesa_prim */,
                                    uint is_prefix_summing,
                                    uint max_indices,
                                    uint shape /* poly_gs_shape */)
{
   poly_gs_setup_indirect_byte_count(byte_count, instance_count, counter_offset,
                                     vertex_stride, vp, gp, gdp, heap,
                                     vs_outputs, prim, is_prefix_summing,
                                     max_indices, shape);
}

KERNEL(256)
panlib_prefix_sum_geom(global struct poly_geometry_params *gp)
{
   POLY_DECL_PREFIX_SUM_SCRATCH(scratch, 16, 256);
   poly_prefix_sum(scratch, gp->count_buffer, gp->total_input_primitives,
                   gp->count_buffer_stride / 4, cl_group_id.x, 256);
}

#endif
