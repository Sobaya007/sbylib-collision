module sbylib.collision.shape.capsule;

import sbylib.math;
import sbylib.collision.shape.shape;
import sbylib.collision.bounds.aabb;

interface CollisionCapsule : CollisionShape {
    vec3[2] ends();
    float radius();

    mixin template ImplAABB() {
        import sbylib.math : vmin = min, vmax = max;

        override AABB getAABB() {
            return AABB(vmin(ends[0], ends[1]) - vec3(radius), vmax(ends[0], ends[1]) + vec3(radius));
        }
    }
}
