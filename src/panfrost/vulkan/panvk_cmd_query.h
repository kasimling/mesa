/*
 * Copyright © 2024 Collabora Ltd.
 * SPDX-License-Identifier: MIT
 */

#ifndef PANVK_CMD_QUERY_H
#define PANVK_CMD_QUERY_H

#ifndef PAN_ARCH
#error "PAN_ARCH must be defined"
#endif

#include "genxml/gen_macros.h"

struct panvk_occlusion_query_state {
#if PAN_ARCH >= 10
   uint64_t syncobj;
#endif
   uint64_t ptr;
   enum mali_occlusion_mode mode;
};

#if PAN_ARCH >= 10
struct panvk_prims_generated_query_state {
   uint64_t syncobj;
   uint64_t ptr;
};

struct panvk_xfb_query_state {
   uint64_t syncobj;
   uint64_t ptr;
};

static inline uint64_t
panvk_xfb_query_prims_written(struct panvk_xfb_query_state *state)
{
   return state->ptr;
}

static inline uint64_t
panvk_xfb_query_prims_generated(struct panvk_xfb_query_state *state)
{
   return state->ptr + sizeof(uint64_t);
}
#endif

#endif
