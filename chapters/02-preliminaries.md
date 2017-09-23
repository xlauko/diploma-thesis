# Preliminaries

In this chapter we will introduce foundations for proposed abstraction model
checking approach. We will cover \LLVM bitcode as input language for
verification. Focus will be on [instruction set for values
manipulation](#intro-to-llvm-ir) and its [semantics](#semantics), [\LLVM type
system](#type-system) and [control flow](#control-flow) of programs.
subsequently a notion of [model checking](#model-checking) will be explored in
context of \LLVM programs. The exposition of model checking is mainly based on
Petr's Ročkai dissertation [@Rockai15] further uncovered in [chapter
3](#chap03).

## Intro to \LLVMIR

\marginpar{ the \LLVM project is a collection of modular and
reusable compiler and toolchain technologies. Despite its name -- low level
virtual machine, \LLVM has little to do with traditional virtual
machines. the name "LLVM" itself is not an acronym; it is the full name
of the project. \href{http://llvm.org/}{[LLVM website]}}

Besides defining the semantics of bitcode in form of \LLVMIR (intermediate
representation), \LLVM{} [@LLVM:web] is primary toolkit for building
compilers. It was firstly introduced in [@Lattner04] as an optimization
framework. Nowadays \LLVM represents a set of libraries for building and
manipulation of an intermediate representation of a program and
platform-specific code generators.

According to [@LLVM:langref] \LLVM is a static single assignment (ssa) based
representation that provides type safety, low-level operations, flexibility, and
the capability of representing ‘all’ high-level languages cleanly. It is the
common code representation used throughout all phases of the \LLVM compilation
strategy.

Since the \LLVMIR simplifies semantics of verified language it is much more
suitable for model checking. Model checking can abstract from complicated
grammar of verified language and process \LLVM bicode produced by compiler
front-end.

\mytodo{ distinguish between LLVM, LLVMIR and LLVM bitcode }

### Instructions, Functions and other \LLVM building blocks

An \LLVMIR is kind of similar to traditional assembly language. When we look
into \LLVMIR file (or __module__),
\marginpar{\LLVM programs are composed of module‘s, each of which is a
    translation unit of the input programs.}
We can find there a description of global data and function definitions. Each
function definition has a list of basic blocks, forming a control flow graph for
the function.

\begin{definition}\label{sec:basicblock}
A basic block is a sequence of instructions, and ends with a terminator
instruction (such as a branch or function return). The computation of a program
within a basic block is entirely sequential, performing instructions in their
order of appearance in the block.
\mytodo{ add citation of mornfall }
\end{definition}

\LLVM instructions from basic blocks manipulates values in virtual registers or
they move values between registers and memory. Each instruction has at most one
return value, which is assigned to register for the time of execution of a
function. Considering values in registers, a whole \LLVM bitcode is always in
\SSA form.

\begin{definition}\label{sec:ssa}
A static single assignment (\SSA) is a property of an intermediate representation
(IR), which requires that each variable is assigned exactly once, and every
variable is defined before it is used.
\mytodo{ add citation }
\end{definition}

In addition to register values \LLVMIR allows address-taken variables (i.e. it's
allowed to take address of the variable and mutate it as normal variable).
Hence the address-taken variables are not part of the ssa form. In unoptimized
\LLVM bitcode each higher-level code (c/c++) variable becomes an address-taken
variable, created by `alloca` instruction. Consequently register values are only
created by compiler as intermediate results of instructions. However, the \LLVM
optimiser can lift many address-taken variables into registers if the addresses
of those variables are not actually taken.

For our purpose we will meet only subset of \LLVM instructions. Concretely
instructions for manipulation of transformed values, memory operations and
control flow (terminator) instructions. Precise documentation of all can be
found at \LLVM language reference manual [@LLVM:langref]. For better
undertanding of \LLVM bitcode look at following example.

---

\begin{example}
Let's have a look at piece of a c++ code and corresponding \LLVM bitcode.
\end{example}

```cpp
int factorial(int n) {
    if ( n == 0 )
        return 1;
    return n * factorial(n - 1);
}
```
\noindent
In \LLVM, a `factorial` function is defined as a global object (prefixed by `@`)
\marginpar{ To distinguish between register values and mutable
address-taken variables \LLVM use two types of prefixes, \% for register values
and @ for mutable and global values.}
`@factorial` with return type `i32` (a 32 bit integer) and argument called `%n`
also of type `i32`. In the function implementation we can see almost direct
correspondence to `c++` code.  The function is logically divided into few basic
blocks annotated with `<label>` and name of basic block (see definition
\ref{sec:basicblock}).  First basic block, also called _entry_ block,
contains equality comparison (`icmp` instruction) of input argument `%n`
and `0`. Followed by conditional branching instruction `br`.

```llvm
define i32 @factorial(i32 %n) {
  %1 = icmp eq i32 %n, 0
  br i1 %1, label %then, label %else
```
\noindent
Branching instruction connects basic blocks and determine control flow depending
on `%1` register value. Branching jumps to basic block labeled with `%then` if
the condition `%1` was true, otherwise it jumps to `%else` basic block.  Besides
branching \LLVM uses `br` instructions to model loops, by jumping to
same label.

```llvm
<label>:then
  ret i32 1
<label>:else
  %2 = sub nsw i32 %n, 1
  %3 = call i32 @factorial(i32 %2)
  %4 = mul nsw i32 %n, %3
  ret i32 %4
}
```
\noindent
In basic block `%then` one is returned with `ret` instruction. In `%else` branch,
besides arithmetic operations (`sub` executing subtraction and `mul` multiplication),
a recursive call is made with `call` instruction.

---

### Type system

An observant reader may noticed that \LLVMIR is strongly typed language.
Besides `void` type \LLVM distinguishes basic single value types, such as
`iN` where `N` determines bit width of integral type. We have already met `i32`
as 32-bit integer and `i1` usually used for booleans.
\LLVM additionally supports floating point types as `float` and `double` and also C like pointer types written as `<type> *`.

In order to support aggregate types, \LLVM recognizes array types. Similarly as
in C, array type represents a consecutive block of memory of same types,
e.g.&nbsp;to denote array of 10 integers \LLVM writes `[10 × i32]`. To
represent a collection of data members together in memory \LLVM defines a
structure type. The \LLVM identifies struct types with given identifiers
in global namespace as follows for structure of consisting of `i32` and pointer
to pair of `i32` values:

```llvm
%Struct = type { i32, { i32, i32 }* }
```

Structures in memory are accessed using `load` and `store` by
getting a pointer to a field with the `getelementptr` instruction. Structures
in registers are accessed using the `extractvalue` and `insertvalue`
instructions [@LLVM:langref].

In order to cast between types \LLVM provides a variety of casting instructions.
To be specific a `bitcast` instruction for explicit type casting, `ptrtoint` and
`inttoptr` for conversions between pointers and integers and `trunc`,`zext`,
`sext` for transformation  to larger or smaller types.

### Control flow

As mentioned before \LLVM supports control flow instructions like `br` for
conditional and unconditional jumps between basic blocks. To direct control flow
between functions \LLVM provides `ret` for returning from function, `call` and `invoke` for calling a function. Except `call` and `invoke`, control
flow instructions are always at end of a basic block, hence they are called
_terminator_ instructions.

As consequence of branching control flow graph and \SSA form, \LLVM needs to
support acquisition of same value from different basic block. For this
purpose a special instruction is designed -- a `phi` node.

```llvm
%v = phi i32 [ %a, %then ], [ %b, %else ]
```
As result of `phi` node instruction `%v` contains either value `%a` or `%b`
depending on the direction from which basic block the program execution came.

### Semantics

In order to build abstraction over \LLVM bitcode we need to setup a good
semantics model of instructions set. For this purpose a small-step operational
semantics [@Plotkin04] is a good candidate.

\begin{definition}
Operational semantics expresses the evaluation of commands as a relation between
a command, initial state and a final state.
\end{definition}

\noindent
Since \LLVMIR semantics prevents unnamed values creation, we don't need to
bother by expression semantics. Only state mutators are instructions, which are
semantically atomic and operates only on existing named values. Moreover
instructions may mutate at most single value from program state. Hence the
semantic function with derivation rules can be easily derived from \LLVM
language reference [@LLVM:langref]. Program state $\sigma$ will basically
consists of two parts -- stack frames and memory. Where stack frames represents
register values, similarly in memory part are stored allocated variables, whose
size is predetermined by the size of pointer type.

## \LLVM compilation process

\LLVM compilation tightly depends on on a given _frontend_ compiler that produces
\LLVMIR, e.g.&nbsp;clang frontend for C/C++, see figure \ref{compilation}.
\LLVM bitcode generated by frontend is then processed and optimized by \LLVM. Optimization is divided into \LLVM _passes_, where each of the passes
performs some optimization task or code analysis. Passes can be run directly
from compiler or they can be run by external tool, e.g.&nbsp; \LLVM
optimization tool _opt_ [@LLVM:opt]. After optimization \LLVMIR is passed to
appropriate code generator, which generates assembly bitcode for specific
platform, e.g.&nbsp;`x86` or ARM.

![\LLVM compilation process\label{compilation}](img/llvm.eps)

## Model checking

### Abstraction model checking

