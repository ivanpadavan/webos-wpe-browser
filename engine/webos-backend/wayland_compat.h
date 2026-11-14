// SPDX-License-Identifier: GPL-3.0-or-later
// wl_registry_bind without a link-time need for wl_proxy_marshal_constructor_versioned, which libwayland-client
// gained in 1.10: webOS 3.x ships an older one. Where the TV has it (webOS 4 and later) it is used exactly as
// wl_registry_bind would; otherwise the bind goes through wl_proxy_marshal_constructor, which is what
// wl_registry_bind did before 1.10 (proxies had no version then).
#pragma once

#include <dlfcn.h>
#include <stdint.h>
#include <wayland-client.h>

typedef struct wl_proxy *(*wpeb_marshal_versioned_fn)(struct wl_proxy *, uint32_t, const struct wl_interface *,
                                                     uint32_t, ...);

static inline void *wpeb_registry_bind(struct wl_registry *registry, uint32_t name,
                                       const struct wl_interface *interface, uint32_t version)
{
    static wpeb_marshal_versioned_fn versioned;
    static int looked_up;
    if (!looked_up) {
        versioned = (wpeb_marshal_versioned_fn)dlsym(RTLD_DEFAULT, "wl_proxy_marshal_constructor_versioned");
        looked_up = 1;
    }
    if (versioned)
        return versioned((struct wl_proxy *)registry, WL_REGISTRY_BIND, interface, version, name, interface->name,
                         version, NULL);
    return wl_proxy_marshal_constructor((struct wl_proxy *)registry, WL_REGISTRY_BIND, interface, name,
                                        interface->name, version, NULL);
}
