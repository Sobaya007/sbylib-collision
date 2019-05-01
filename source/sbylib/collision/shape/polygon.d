module sbylib.collision.shape.polygon;

import sbylib.graphics;
import sbylib.collision.shape.shape;
import sbylib.collision.bounds.aabb;

interface CollisionPolygon : CollisionShape {
    vec3[] vertices();
    
    mixin template ImplAABB() {
        import std.typecons : Nullable;

        private Nullable!AABB aabb;

        override AABB getAABB() {
            if (aabb.isNull)
                aabb = AABB.fromVertex(this.vertices);
            return aabb;
        }
    }

}
