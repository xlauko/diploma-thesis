# preliminaries

in this chapter we will introduce foundations for proposed abstraction model
checking approach. we will cover \llvm bitcode as input language for
verification. focus will be on [instruction set for values
manipulation](#intro-to-llvm-ir) and its [semantics](#semantics), [\llvm type
system](#type-system) and [control flow](#control-flow) of programs.
subsequently a notion of [model checking](#model-checking) will be explored in
context of \llvm programs. the exposition of model checking is mainly based on
petr's ročkai dissertation [@rockai15] further uncovered in [chapter
3](#chap03).

## intro to llvm ir

\marginpar{ the llvm project is a collection of modular and
reusable compiler and toolchain technologies. despite its name -- low level
virtual machine, llvm has little to do with traditional virtual
machines. the name "llvm" itself is not an acronym; it is the full name
of the project. \href{http://llvm.org/}{[llvm website]}}

besides defining the semantics of bitcode in form of \llvmir (intermediate
representation), \llvm{} [@llvm:web] is primary toolkit for building
compilers. it was firstly introduced in [@lattner04] as an optimization
framework. nowadays llvm represents a set of libraries for building and
manipulation of an intermediate representation of a program and
platform-specific code generators.

according to [@llvm:langref] \llvm is a static single assignment (ssa) based
representation that provides type safety, low-level operations, flexibility, and
the capability of representing ‘all’ high-level languages cleanly. it is the
common code representation used throughout all phases of the \llvm compilation
strategy.

\mytodo{ llvm compiler image }

since the \llvmir simplifies semantics of verified language it is much more
suitable for model checking. model checking can abstract from complicated
grammar of verified language and process \llvm bicode produced by compiler
front-end.

\mytodo{ distinguish between llvm, llvmir and llvm bitcode }

### instructions, functions and other \llvm building blocks

an \llvmir is kind of similar to traditional assembly language. when we look
into \llvmir file (or __module__),
\marginpar{llvm programs are composed of module‘s, each of which is a
    translation unit of the input programs.}
we can find there a description of global data and function definitions. each
function definition has a list of basic blocks, forming a control flow graph for
the function.

\begin{def}\label{sec:basicblock}
a basic block is a sequence of instructions, and ends with a terminator
instruction (such as a branch or function return). the computation of a program
within a basic block is entirely sequential, performing instructions in their
order of appearance in the block.
\mytodo{ add citation of mornfall }
\end{def}

\llvm instructions from basic blocks manipulates values in virtual registers or
they move values between registers and memory. each instruction has at most one
return value, which is assigned to register for the time of execution of a
function. considering values in registers, a whole \llvm bitcode is always in
ssa form.

\begin{def}\label{sec:ssa}
a static single assignment (ssa) is a property of an intermediate representation
(ir), which requires that each variable is assigned exactly once, and every
variable is defined before it is used.
\mytodo{ add citation }
\end{def}

in addition to register values \llvmir allows address-taken variables (i.e. it's
allowed to take address of the variable and mutate it as normal variables).
hence the address-taken variables are not part of the ssa form. in unoptimized
\llvm bitcode each higher-level code (c/c++) variable becomes an address-taken
variable, created by `alloca` instruction. consequently register values are only
created by compiler as intermediate results of instructions. however, the \llvm
optimiser can lift many address-taken variables into registers if the addresses
of those variables are not actually taken.

\mytodo{ types of llvm instructions }

---

\begin{ex}
let's have a look at piece of a c++ code and corresponding \llvm bitcode.
\end{ex}

```cpp
int factorial(int n) {
    if ( n == 0 )
        return 1;
    return n * factorial(n - 1);
}
```
\noindent
in \llvm, `factorial` function is defined as a global object (prefixed by `@`)
`@factorial` with return type `i32` (a 32 bit integer) and argument called `%n`
also of type `i32`. function is logically divided into few basic blocks
annotated with `<label>` and name of basic block (see definition \ref{sec:basicblock}).

\marginpar{ To distinguish between register values and mutable
address-taken variables \LLVM use two types of prefixes, \% for register values
and @ for mutabe values.}


```llvm
define i32 @factorial(i32 %n) {
  %1 = icmp eq i32 %n, 0
  br i1 %1, label %then, label %else
```

```llvm
<label>:then
  ret i32 1
```

```llvm
<label>:else
  %2 = sub nsw i32 %n, 1
  %3 = call i32 @factorial(i32 %2)
  %4 = mul nsw i32 %n, %3
  ret i32 %4
}
```

---

### Semantics

### Type system

### Control flow

\mytodo{ definition of phinode }

## Clang compilation process

\mytodo{ describe passes + instrumentation }

## Model checking

### Abstraction model checking

