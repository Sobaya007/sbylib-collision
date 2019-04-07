module sbylib.collision.shape.shape;

import sbylib.collision.bounds.aabb;

interface CollisionShape{
    AABB getAABB();
}
