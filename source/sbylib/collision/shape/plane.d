module sbylib.collision.shape.plane;

import sbylib.graphics;
import sbylib.collision.shape.shape;
import sbylib.collision.bounds.aabb;

interface CollisionPlane : CollisionShape {
    vec3[4] vertices();
    
    mixin template ImplAABB() {
        override AABB getAABB() {
            return AABB.fromVertex(this.vertices);
        }
    }

}
