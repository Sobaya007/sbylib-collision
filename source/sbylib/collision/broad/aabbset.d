module sbylib.collision.broad.aabbset;

import sbylib.collision.bounds.aabb;
import sbylib.collision.shape.shape;
import sbylib.collision.narrow.detect : CollisionResult;
import std.typecons : Nullable;
import std.variant : Algebraic, visit;

class AABBSet {

    auto collisionDetected(MyType : CollisionShape, YourType : CollisionShape)(YourType shape) {
        return CollisionDetectNotification!(MyType, YourType)(this, shape);
    }

    private alias Tree = Algebraic!(Node, Leaf);
    private AABB visitAABB(Tree tree) {
        return tree.visit!(
                (Node node) => node.getAABB(),
                (Leaf leaf) => leaf.getAABB());
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
            return Tree(new Leaf(shapeList[0]));

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
        return Tree(new Node([buildTree(shapeList[0..$/2]), buildTree(shapeList[$/2..$])]));
    }

    void detect
        (MyType : CollisionShape, YourType : CollisionShape)
        (YourType shape, CollisionDetectCallback!(MyType, YourType) callback) 
    {
        root.visit!(
            (Node node) => node.detect!(MyType, YourType)(shape, callback),
            (Leaf leaf) => leaf.detect!(MyType, YourType)(shape, callback));
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

    private class Node {
        Tree[2] children;
        Nullable!AABB aabb;
        this(Tree[2] children) { this.children = children; }
        AABB getAABB() { 
            if(aabb.isNull)
                aabb = AABB.unite(visitAABB(children[0]), visitAABB(children[1])); 
            return aabb;
        }
        
        void detect(MyType : CollisionShape, YourType : CollisionShape)
            (YourType shape, CollisionDetectCallback!(MyType, YourType) callback) {
            if (intersect(this.getAABB(), shape.getAABB()) is false) return;
            static foreach (i; 0..2) {
                children[i].visit!(
                    (Node node) => node.detect!(MyType, YourType)(shape, callback),
                    (Leaf leaf) => leaf.detect!(MyType, YourType)(shape, callback));
            }
        }
    }

    private class Leaf {
        ShapePair shape;
        this(ShapePair shape) { this.shape = shape; }
        AABB getAABB() { return shape.getAABB(); }

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
