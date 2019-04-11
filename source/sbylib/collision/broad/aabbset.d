module sbylib.collision.broad.aabbset;

import sbylib.collision.bounds.aabb;
import sbylib.collision.shape.shape;
import sbylib.collision.narrow.detect : CollisionResult;

class AABBSet {

    auto collisionDetected(MyType : CollisionShape, YourType : CollisionShape)(YourType shape) {
        return CollisionDetectNotification!(MyType, YourType)(this, shape);
    }

    private Tree root; 
    private this(ShapePair[] shapeList) {
        this.root = buildTree(shapeList);
    }

    private Tree buildTree(ShapePair[] shapeList) 
        in (shapeList.length > 0)
    {
        import std.algorithm : map, reduce, sort, minElement, maxElement;
        import std.array : array;
        import std.typecons : tuple;
        import std.range : enumerate;
        import sbylib.math : mostDispersionBasis, dot, vec3;

        if (shapeList.length is 1)
            return new Leaf(shapeList[0]);

        auto shapeAABBList = shapeList.map!(s => tuple(s, s.getAABB())).array;
        auto centerList = shapeAABBList.map!(s => s[1].center).array;
        auto basisList = mostDispersionBasis(centerList);
        auto lengthList = basisList.array.map!(basis =>
                centerList.map!(c => dot(c, basis)).maxElement
              - centerList.map!(c => dot(c, basis)).minElement).array;
        vec3 basis = basisList[lengthList.enumerate.reduce!((a,b) => a.value > b.value ? a : b).index];
        shapeList = shapeAABBList
            .sort!((a,b) => dot(a[1].center, basis) < dot(b[1].center, basis))
            .map!(s => s[0])
            .array;
        return new Node([buildTree(shapeList[0..$/2]), buildTree(shapeList[$/2..$])]);
    }

    private void detect
        (MyType : CollisionShape, YourType : CollisionShape)
        (YourType shape, CollisionDetectCallback!(MyType, YourType) callback) 
    {
        if (auto node = cast(Node)root) node.detect!(MyType, YourType)(shape, callback);
        else if (auto leaf = cast(Leaf)root) leaf.detect!(MyType, YourType)(shape, callback);
        else assert(false);
    }

    private alias CollisionDetectCallback(MyType, YourType)
        = void delegate(MyType, YourType, CollisionResult!(MyType, YourType));

    private struct ShapePair {
        import std.variant : Variant;

        CollisionShape shape;
        Variant variant;
        alias shape this;

        this(Shape : CollisionShape)(Shape shape) {
            this.shape = shape;
            this.variant = shape;
        }
    }

    struct Builder {
        ShapePair[] shapeList;

        void add(Shape : CollisionShape)(Shape shape) {
            this.shapeList ~= ShapePair(shape); 
        }

        auto build() {
            return new AABBSet(shapeList);
        }
    }

    private interface Tree {
        AABB getAABB();
    }

    private class Node : Tree {
        Tree[2] children;
        this(Tree[2] children) { this.children = children; }
        override AABB getAABB() { return AABB.unite(children[0].getAABB(), children[1].getAABB()); }
        
        void detect(MyType : CollisionShape, YourType : CollisionShape)(YourType shape, CollisionDetectCallback!(MyType, YourType) callback) {
            if (intersect(this.getAABB(), shape.getAABB()) is false) return;
            static foreach (i; 0..2) {
                if (auto node = cast(Node)children[i]) node.detect!(MyType, YourType)(shape, callback);
                else if (auto leaf = cast(Leaf)children[i]) leaf.detect!(MyType, YourType)(shape, callback);
                else assert(false);
            }
        }
    }

    private class Leaf : Tree {
        ShapePair shape;
        this(ShapePair shape) { this.shape = shape; }
        override AABB getAABB() { return shape.getAABB(); }

        void detect(MyType : CollisionShape, YourType : CollisionShape)
            (YourType shape, CollisionDetectCallback!(MyType, YourType) callback) {
            import sbylib.collision.narrow : detect;

            if (this.shape is shape) return;
            if (intersect(this.getAABB(), shape.getAABB()) is false) return;

            if (auto s1 = this.shape.variant.peek!MyType) {
                auto info = detect(*s1, shape);
                if (info.isNull) return;
                callback(*s1, shape, info.get());
            }
        }
    }
}

private struct CollisionDetectNotification(MyType : CollisionShape, YourType : CollisionShape) {
    AABBSet set;
    YourType shape;
}

auto when(MyType : CollisionShape, YourType : CollisionShape)(CollisionDetectNotification!(MyType, YourType) notification) {
    import sbylib.graphics : Event, when, Frame, then, until;
    import std.meta : AliasSeq;

    alias Args = AliasSeq!(MyType, YourType, CollisionResult!(MyType, YourType));

    auto result = new Event!(Args);

    when(Frame).then({
        notification.set.detect!(MyType, YourType)(notification.shape, (Args args) => result.fire(args));
    });
    return result;
}
