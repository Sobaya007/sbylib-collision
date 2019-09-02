module sbylib.collision.shape.sphere;

import sbylib.math;
import sbylib.collision.shape.shape;
import sbylib.collision.bounds.aabb;

interface CollisionSphere : CollisionShape{
    vec3 center();
    float radius();

    mixin template ImplAABB() {
        override AABB getAABB() {
            return AABB(center - vec3(radius), center + vec3(radius));
        }
    }
}
