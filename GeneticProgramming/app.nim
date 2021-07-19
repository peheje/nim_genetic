import strutils
import math
import random
import sugar
import strformat

# Fast math gives some weird behavior, try: nim c -r -d=danger -l=-flto app.nim

const subresults = false

type
    Node = ref object
        left, right: Node
        op: Operation
        value: float

    Operation = ref object
        sign: string
        unary: bool
        call: proc(a, b: Node): float

proc eval(node: Node): float =
    if node == nil:
        return
    elif node.op.sign == "val":
        return node.value
    elif node.op.unary:
        return node.op.call(node.left, nil)
    return node.op.call(node.left, node.right)

proc print(node: Node, indent: int = 0) =
    if node == nil:
        return
    print(node.right, indent + 6)
    echo ""
    for i in 0..<indent:
        stdout.write(" ")
    if node.op.sign == "val":
        echo node.value.formatFloat(ffDecimal, 3)
    else:
        when subresults:
            let value = node.eval()
            echo fmt"{node.op.sign} ({value})"
        else:
            echo node.op.sign
    print(node.left, indent + 6)

proc randomNode(ops: seq[Operation], depth, max: int): Node =
    let leaf = depth == max

    if leaf:
        result = Node(op: ops[0], value: round(rand(-10.0..10.0)))
    else:
        result = Node(op: ops[rand(1..<ops.len)])

proc randomTree(ops: seq[Operation], node: var Node, max, counter: int = 0) =
    node = randomNode(ops, counter, max)
    if counter >= max:
        return
    randomTree(ops, node.left, max, counter + 1)
    if not node.op.unary:
        randomTree(ops, node.right, max, counter + 1)

proc parenthesis(x: float): string =
    if x < 0.0:
        return fmt"({x})"
    else:
        return $x

proc toEquation(node: Node, eq: var string, depth: int = 0) =
    let sign = node.op.sign
    let right = node.right
    let left = node.left

    if right != nil and right.op.sign == "val":
        eq &= fmt"({parenthesis(left.value)} {sign} {parenthesis(right.value)})"
    elif not node.op.unary:
        if depth != 0:
            eq &= "("
        left.toEquation(eq, depth + 1)
        eq &= fmt" {sign} "
        right.toEquation(eq, depth + 1)
        if depth != 0:
            eq &= ")"
    else:
        eq &= fmt"{sign}("
        if left.op.sign == "val":
            eq &= fmt"{left.value}"
        else:
            left.toEquation(eq, depth + 1)
        eq &= ")"

proc main() =
    randomize()
    var ops = newSeq[Operation]()

    ops.add(Operation(sign: "val", call: (a, b) => a.value))
    ops.add(Operation(sign: "+", call: (a, b) => a.eval() + b.eval()))
    ops.add(Operation(sign: "-", call: (a, b) => a.eval() - b.eval()))
    ops.add(Operation(sign: "*", call: (a, b) => a.eval() * b.eval()))
    ops.add(Operation(sign: "^", call: (a, b) => pow(a.eval(), b.eval())))
    #ops.add(Operation(sign: "/", call: (a, b) => a.eval() / b.eval()))
    #ops.add(Operation(sign: "abs", call: (a, b) => abs(a.eval()), unary: true))
    #ops.add(Operation(sign: "cos", call: (a, b) => cos(a.eval()), unary: true))
    #ops.add(Operation(sign: "sin", call: (a, b) => sin(a.eval()), unary: true))
    #ops.add(Operation(sign:"sqrt", call: (a, b) => sqrt(a.eval()), unary: true))

    for i in 0..<10_000_000:
        var tree: Node = nil
        randomTree(ops, tree, 5)

        let value = tree.eval()

        if value == 120.0:
            echo "_____"
            var equation = ""
            tree.toEquation(equation)
            tree.print()
            echo equation
            echo value
            echo "_____"

main()
