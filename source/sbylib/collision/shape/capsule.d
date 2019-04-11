module sbylib.collision.shape.capsule;

import sbylib.graphics;
import sbylib.collision.shape.shape;
import sbylib.collision.bounds.aabb;

interface CollisionCapsule : CollisionShape {
    vec3[2] ends();
    float radius();

    mixin template ImplAABB() {
        override AABB getAABB() {
            return AABB(min(ends[0], ends[1]) - vec3(radius), max(ends[0], ends[1]) + vec3(radius));
        }
    }
}
