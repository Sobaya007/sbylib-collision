module sbylib.collision.bounds.aabb;

import sbylib.math : vec3;

struct AABB {
    vec3 min, max;

    static fromVertex(vec3[] vertices) {
        import sbylib.math : vmin = min, vmax = max;

        vec3 a = vertices[0];
        vec3 b = vertices[0];
        foreach (v; vertices) {
            a = vmin(a, v);
            b = vmax(b, v);
        }
        return AABB(a,b);
    }

    static unite(AABB bounds1, AABB bounds2) {
        import sbylib.math : vmin = min, vmax = max;

        return AABB(vmin(bounds1.min, bounds2.min), vmax(bounds1.max, bounds2.max));
    }

    vec3 center() const {
        return (min + max) / 2;
    }
}

bool intersect(AABB bounds1, AABB bounds2) {
    static foreach (i; 0..3) {
        if (bounds1.max[i] < bounds2.min[i]) return false;
        if (bounds2.max[i] < bounds1.min[i]) return false;
    }
    return true;
}
