# Node System #

## Node System Reasoning ##
The goal of the Node System is to handle any process of the game under a single roof.

I also wanted a way to handle screen transition safely, and have them be part of the
NodeTree - unlike Godot, which has a tree for each individual scene.

This change effectively let us talk between current and past screens safely. 

The node system allows to set nodes as unique, which treats them internally like a singleton,
without making them static classes.

## How to use ##

The Node system uses three core components;
- `NodeTree.hx`
- `Node.hx`
- `VisualNode.hx`

```haxe

/**
    In hxd.App, setup the node tree as follow;
**/

var root:RootNode;
var tree:NodeTree;
var frame:plib.engine.Frame;

override function init(){
    super.init(root);

    root = new RootNode();
    tree = new NodeTree(root, s2d);

    // frame wasnt designed for this system, so we
    // need to handle it accordingly for the time being.
    // note: this may change in the future to be more streamlined.
    frame = @:privateAccess new plib.engine.Frame();

    // then to add new nodes to the tree:
    // root.addChild(otherNode).
}

override function update(dt:Float){
    super.update(dt);

    // update the frame and the tree each frame.
    @:privateAccess frame.update();
    tree.process(frame);

}
```

## Screens ##

Usually, you will want some sort of screen system. This is handled via the tree as well. All you have to do:

```haxe

override function init(){
    // [...]

    var screenManager = new ScreenManager();
    root.addChild(screenManager);

    screenManager.change(new FooScreen());
}

```

and create the screen node:

```haxe
class FooScreen extends ScreenNode{

    public function new(){
        super();
    }

    // will trigger when the screen is added first.
    // use this to initialize your visuals and gameplay.
    override function onEnter(){}

    // called when the screen is removed from the tree.
    // use this for cleanup.
    override function onExit(){}

    // called when another screen is added on top of
    // this one.
    override function onCovered(){}

    // called when the overlapping screen is removed.
    override function onRevealed(){}
}

```

Additionally, each screen comes with its own animator, which schedules animations and callbacks for you.

To access the manager from within screens, do as follows:
```haxe
var manager = tree.getUnique(ScreenManager);
```

## NodeTree.hx ##

The NodeTree is responsible for updating the node tree and all its children.
When creating a new node, add it to its parent, and it will automatically be added
to the tree. It comes with a set of utility methods;



```haxe
/**
    Add a callback right before the cleanup phase, after all processes.
**/
/
tree.addCleanupCb(fn);


/**
    Remove a cleanup callback. This should be done in nodes when they are removed.
**/
tree.removeCleanupCb(fn);


/**
    Should be called once per frame, in the `update(dt:Float)` method of your application,
    or wherever you do your application updates. This will call processing methods on
    all valid nodes within the tree structure (preupdate, update, postupdate, cleanup)

    The frame parameter should be a plib.engine.Frame, which contains the frame data such as
    dt, tmod, elapsed and frames.
**/
tree.process(frame);

/**
    Safely disposes of nodes. Automatically called by `tree.process(frame)`.
**/
tree.cleanup();

/**
    Validation that throws an error if there are multiple unique node of the same type
    within the node tree structure. Should usually not be called manually.
**/
tree.validateSubtree(node);

/**
    Attach a node and all its children to this tree.
**/
tree.attachSubtree(node);

/**
    Remove the given node and all its children from the tree structure.
**/
tree.detachSubtree(node);

/**
    Returns a unique node by its class. 
**/
tree.getUnique(MyUniqueNodeClass);

/** 
    Walk through each node of a subtree, in depth order.

    --Root
    ---- ScreenManager
    -------- Screen1
    ------------ Object1
    ---------------- SubObject1
    ------------ Object2
    -------- Screen2
    ------------ Object3
    ------------ Object4

    tree.walksubtree(screenManager, fn) would trigger in order;
    Screen1
    Screen2
    Object1
    Object2
    Object3
    Object4
    SubObject1
**/
tree.walkSubtree(node, fn);

/**
    Alternatively, you can use visitSubtree(node, fn), which
    would do the same thing, but trigger each subtree in order.

    Screen1
    Object1
    SubObject1
    Object2
    Screen2
    Object3
    Object4
**/
tree.visitSubtree(node, fn);

/**
    Using walkSubtreePostOrder works like visitSubtree, but will
    trigger the last element of the subtree first.

    SubObject1
    Object1
    Object2
    Screen1
    Object4
    Object3
    Screen2
**/
tree.walkSubtreePostOrder(node, fn);
```

## Node.hx ##

Node is the root of all other nodes. It contains generic methods and properties.

```haxe
/**
    nodes can block their individual processing methods, and those of children nodes,
    by setting the following properties. They are false by default.
**/
node.block_preupdate = true;
node.block_update = true;
node.block_postupdate = true;

/**
    pausing the node behaves the same way as setting the block properties to true.
    However, the block properties will not change how pause behaves.
**/
node.pause();
node.resume();

/**
    showing and hiding nodes behave the same way as pause and resume, but they will also
    call onShow and onHide, which can be overidden to add additional behavior.

    In the case of VisualNodes, they will make their display invisible.
**/
node.hide();
node.show();

/**
    Returns whether the node should be paused or if a parent is paused.
**/
node.isPausedInTree();

/**
    Add/Remove a child to this node.
    If the child was already on the tree, use reparent instead.
**/
node.addChild(child);
node.removeChild(child);
child.reparent(node);

// shortcut that calls parent.removeChild(node).
node.remove();

/**
    Return true if the nodes have the proper relationship.
**/
node.isAncestorOf(other);
node.isDescendantOf(other);

/**
    Query nodes with their class.
**/
node.getFirstOf(nodeClass);
node.getAllOf(nodeClass);
node.getFirst(node, query);
node.getAll(node, query);

/**
    Get the root node.
**/
node.getRoot();

/**
    Safely disposes of the node and its children at the end of the tree processing cycle.
**/
node.destroy();

/**
    Update Cycle. These are called once per frame, in order.

    preupdate should register inputs.
    update handle data manipulations.
    postupdate handle visual changes.
**/
node.preupdate();
node.update(frame);
node.postupdate();

// lifecycle hooks

node.onAddedToTree();
node.onRemovedFromTree();

// When calling node.destroy(), a onDestroyRequested call is fired. However,
// if the node is not added to the tree, onDestroyed() will never fire.
// If the node is not added to the tree, removeChild() should be used instead.
node.onDestroyRequested();
node.onDestroyed();

```

## VisualNode.hx ##

Visual nodes are the backbone of the node system. They extend the base node, but have a display.

The display order is from the closest visual node parent within the tree structure.