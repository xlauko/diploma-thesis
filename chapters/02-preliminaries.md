# Preliminaries

In this chapter, we will introduce foundations for proposed the
abstraction-based model checking approach. We will cover \LLVM bitcode as the
input language for verification. Focus will be on the
[instruction set for value manipulation](#intro-to-llvm-ir) and its [semantics](#semantics), the [\LLVM
type system](#type-system) and the [control flow](#control-flow) of programs.
Subsequently the notion of [model checking](#model-checking) will be explored in
the context of \LLVM programs. The exposition of model checking is mainly based on
Petr Ročkai's dissertation [@Rockai15] further covered in [chapter 3](#chap03).

## Intro to \LLVMIR

\marginpar{The \LLVM project is a collection of modular and
reusable compiler and toolchain technologies. Despite its name -- low level
virtual machine, \LLVM has little to do with traditional virtual
machines. The name \LLVM itself is not an acronym; it is the full name
of the project. \href{http://llvm.org/}{[\LLVM website]}}

Besides defining the semantics of bitcode in the form of \LLVMIR (intermediate
representation), \LLVM{} [@LLVM:web] is primarily a toolkit for building
compilers. It was firstly introduced by Ch. Lattner and V. Adve [@Lattner04] as
an optimization framework. Nowadays \LLVM represents a set of libraries for
building and manipulation of an intermediate representation of a program and
platform-specific code generators.

According to \LLVM language reference manual [@LLVM:langref],
\LLVM is a static single assignment (\SSA) based representation that
provides type safety, low-level operations, flexibility, and
the capability of representing ‘all’ high-level languages cleanly. It is the
common code representation used throughout all phases of the \LLVM compilation
strategy.

Since the \LLVMIR simplifies semantics of verified language it is much more
suitable for model checking. Model checking can abstract from complicated
grammar of verified language and process \LLVM bicode produced by compiler
front-end.

### Instructions, Functions and other LLVM building blocks

An \LLVMIR aims to be slightly richer assembly-like language. When we look
into \LLVMIR file (or _module_),
\marginpar{\LLVM programs are composed of modules, each of which is a
translation unit of the input programs.}
we can find there a description of global data and function definitions. Each
function definition has a list of basic blocks, forming a control flow graph for
the function.

\begin{definition}\label{sec:basicblock}
A basic block is a sequence of instructions that ends with a terminator
instruction (such as a branch or function return). The computation of a program
within a basic block is entirely sequential, performing instructions in their
order of appearance in the block [\hyperlink{ref-Rockai15}{2}].
\end{definition}

Instructions from basic blocks manipulate values in virtual registers or
they move values between registers and memory. Each instruction has at most one
return value, which is assigned to register for the time of execution of a
function. Considering values in registers, a whole \LLVM bitcode is always in
partial \SSA form.

\begin{definition}\label{sec:ssa}
A static single assignment (\SSA{}) is a property of an intermediate representation
(\textsc{ir}), which requires that each variable is assigned exactly once, and every
variable is defined before it is used [\hyperlink{ref-Cytron91}{?}].
\mytodo{ fix citation }
\end{definition}

In addition to register values \LLVMIR allows address-taken variables (i.e. it's
allowed to take address of the variable and mutate it as normal variable).
Hence the address-taken variables are not part of the \SSA form. In unoptimized
\LLVM bitcode, each higher-level (C/\Cpp{}) variable becomes an address-taken
variable, created by an `alloca` instruction. Consequently, register values are only
created by the compiler as intermediate results of instructions. However, the \LLVM
optimiser can lift many address-taken variables into registers if the addresses
of those variables are not actually taken.

For our purpose we will meet only a subset of \LLVM instructions. Concretely
instructions for manipulation of transformed values, memory operations and
control flow (terminator) instructions. Precise documentation of all can be
found at \LLVM language reference manual [@LLVM:langref]. For better
undertanding of \LLVM bitcode, look at the following example.

---

\begin{example}
Let's have a look at piece of \Cpp{} code and corresponding \LLVM bitcode.
\end{example}

```cpp
int factorial(int n) {
    if (n == 0 )
        return 1;
    return n * factorial(n - 1);
}
```

```llvm
define i32 @factorial(i32 %n) {
  %1 = icmp eq i32 %n, 0
  br i1 %1, label %then, label %else
```
\mytodo{ klikihakova ciara }
\noindent
In \LLVM bitcode, the `factorial` function is defined as a global object (prefixed by `@`)
\marginpar{To distinguish between register values and mutable
address-taken variables \LLVM use two types of prefixes, \texttt{\%} for register values
and \texttt{@} for mutable and global values.}
`@factorial` with return type `i32` (a 32 bit integer) and an argument called `%n`,
also of type `i32`. In the function implementation we can see almost direct
correspondence to \Cpp{} code. The function is logically divided into a few basic
blocks annotated with `<label>` and the name of the basic block (see definition
\ref{sec:basicblock}). First basic block, also called _entry_ block,
contains equality comparison (`icmp` instruction) of the input argument `%n`
and `0`, followed by conditional branching instruction `br`.

The branching instruction connects basic blocks and determines control flow depending
on the value of register `%1`. Branching jumps to basic block labeled with `%then` if
the condition `%1` was true, otherwise it jumps to `%else` basic block. Besides
branching \LLVM uses `br` instructions to represent loops, by jumping
backwards in the control flow graph.


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
In basic block `%then` one is returned with `ret` instruction. In the `%else` branch,
besides arithmetic operations (`sub` executing subtraction and `mul` multiplication),
a recursive call is made using a `call` instruction.

---

### Type system

An observant reader may have noticed that \LLVMIR is a strongly typed language.
Besides the `void` type, \LLVM distinguishes basic single value types, such as
`iN` where `N` determines bit width of integral type. We have already met `i32`
as 32-bit integer and `i1` usually used for booleans.
\LLVM additionally supports floating point types as `float` and `double` and also C like pointer types written as `<type> *`.

In order to support aggregate types, \LLVM recognizes array types, struct types
and vector types [@LLVM:langref]. Similarly as in C, array type represents a consecutive block
of memory of same types, e.g.&nbsp;to denote array of 10 integers \LLVM writes
`[10 × i32]`. To represent a collection of data members together in memory \LLVM
defines a structure type. \LLVM identifies struct types with given
identifiers in the global namespace as follows for a structure called `aggregate`
consisting of `i32` and a pointer to pair of `i32` values:

```llvm
%aggregate = type { i32, { i32, i32 }* }
```

Structures in memory are accessed using `load` and `store` instructions. To
compute an offset into an aggregate type a `getelementptr` instruction is used.
Structures in registers are accessed using the `extractvalue` and `insertvalue`
instructions [@LLVM:langref].

In order to cast between types \LLVM provides a variety of casting instructions.
To be specific, a `bitcast` instruction for explicit type casting, `ptrtoint` and
`inttoptr` for conversions between pointers and integers and `trunc`, `zext`,
`sext` for transformation to larger or smaller integer types.

### Control flow

As mentioned earlier, \LLVM supports control flow instructions like `br` for
conditional and unconditional jumps between basic blocks. To direct control flow
between functions, \LLVM provides `ret` for returning from functions, `call` and
`invoke` for calling a function. Except `call`, all control flow instructions
are always at the end of a basic block, hence they are called _terminator_
instructions.

As consequence of branching control flow graph and \SSA form, \LLVM needs to
support acquisition of value from different basic blocks. For this
purpose a special instruction is designed -- a `phi` node [@Cytron91].

```llvm
%v = phi i32 [ %a, %then ], [ %b, %else ]
```
As result of `phi` node instruction, `%v` contains either value `%a` or `%b`
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
bother by expression semantics. The only state mutators are instructions, which are
semantically atomic and operates only on existing named values. Moreover
instructions may mutate at most single value from program state. Hence the
semantic function with derivation rules can be easily derived from \LLVM
language reference [@LLVM:langref]. Program state $\sigma$ will basically
consists of two parts -- stack frames and memory. Where stack frames represents
register values, similarly in memory part are stored allocated variables, whose
size is predetermined by the size of pointer type.

## \LLVM compilation process

\LLVM compilation tightly depends on on a given _frontend_ compiler that produces
\LLVMIR, e.g.&nbsp;clang frontend for C/\Cpp{}, see figure \ref{fig:compilation}.
\LLVM bitcode generated by frontend is then processed and optimized by \LLVM. Optimization is divided into \LLVM _passes_, where each of the passes
performs some optimization task or code analysis. Passes can be run directly
from compiler or they can be run by external tool, e.g.&nbsp; \LLVM
optimization tool _opt_ [@LLVM:opt]. After optimization \LLVMIR is passed to
appropriate code generator, which generates assembly bitcode for specific
platform, e.g.&nbsp;`x86` or ARM.

\begin{figure}[!ht]
\centering
\resizebox{\textwidth}{!}{
\begin{tikzpicture}[>=stealth',shorten >=1pt,auto,node distance=4em, <->]

    \tikzstyle{component}=[draw, text centered, rounded corners=1pt, minimum height=2.8 em, minimum width=2 cm, text width=1.8 cm]
    \tikzset{>=latex}
    \tikzset{font={\fontsize{9pt}{12}\selectfont}}

    \node [component] (clang) { Clang C++ frontend};
    \node [component, below = 0.5 cm of clang] (gcc) { llvm-gcc frontend};
    \node [component, below = 0.5 cm of gcc] (ghc) { GHC frontend};
    \node [left = 0.4 cm of clang](c++) {C++};
    \node [left = 0.4 cm of gcc](fortran) {Fortran};
    \node [left = 0.4 cm of ghc](haskell) {Haskell};

    \node [component, right = of gcc] (opt) {\LLVM optimizer};

    \node [component, right = of opt] (power) {\LLVM PowerPC backend};
    \node [component, above = 0.5 cm of power] (x86) {\LLVM \texttt{x86} backend};
    \node [component, below = 0.5 cm of power] (arm) {\LLVM ARM backend};

    \node [right = 0.4 cm of x86] (rx86) {\texttt{x86}};
    \node [right = 0.4 cm of power] (rpower) {PowerPC};
    \node [right = 0.4 cm of arm] (rarm) {ARM};

    \draw [->] (c++) -- (clang);
    \draw [->] (fortran) -- (gcc);
    \draw [->] (haskell) -- (ghc);

    \draw [->] (clang.east) -| ([xshift= 0.3 cm]gcc.east) -- (opt.west);
    \draw [->] (gcc) -- (opt) node [pos=0.6,above] {\tiny \LLVMIR};
    \draw [->] (ghc) -| ([xshift= 0.3 cm]gcc.east) -- (opt);

    \draw [->] (opt) -- ([xshift= -0.3 cm]power.west) |- (x86);
    \draw [->] (opt) -- (power) node [pos=0.4,above] {\tiny \LLVMIR};
    \draw [->] (opt) -- ([xshift= -0.3 cm]power.west) |- (arm);

    \draw [->] (x86) -- (rx86);
    \draw [->] (power) -- (rpower);
    \draw [->] (arm) -- (rarm);
\end{tikzpicture}
}
\caption{\LLVM compilation process consists of 3 steps -- parsing of input
language and producing \LLVMIR in frontend part, optimization of produced
\LLVMIR and generation of platform specific assembly by compiler backend.}
\label{fig:compilation}
\end{figure}

## Model checking
Model checking is an automated technique that, given a finite-state model of a
system and a formal property, systematically checks whether this property holds
for (a given state in) that model [@Baier08]. To define a model checking problem
we need setup a transition system that describes model of a system to be
verified.
\begin{definition}\label{def:ts}
A transition system $TS$ is a tuple $(S, s_0, Act, \longrightarrow, AP, L)$, where
\begin{itemize}
    \setlength\itemsep{0.7em}
    \item $S$ is a set of states,
    \item $s_0$ is a initial state,
    \item $Act$ is a set of actions,
    \item $\longrightarrow \subseteq S \times \mathrm{Act} \times S$ is a
    transition relation,
    \item $AP$ is a set of atomic propositions, and
    \item $L: S \rightarrow 2^{AP}$ is a labeling function.
\end{itemize}
\end{definition}
\noindent
For readability, we will write $s \xrightarrow[]{a} s'$ insted of $(s, a,s') \in
\longrightarrow$. To describe transition system in context of \LLVM program we
will consider a program state as a configuration of memory and stack variables.
Change of program state is achieved only by instructions, that modify or
introduce new program variables. Hence transition label $l \in Act$ is sequence
of \LLVM instruction ending with a visible action.

To check whether state $s$ satisfies property $\varphi$ we want show that a set of
atomic propositions induced by $L(s)$ satisfies property $\varphi$, i.e.:
$$ s \models \varphi \iff L(s) \models \varphi.$$
Now we have everything to setup a model checking problem.
\begin{definition}\label{def:mc} Let $M$ be a transition system and $\varphi$ a
formula of temporal logic (i.e., the specification). Find all states $s \in M$
such that $s \models \varphi$ .  \end{definition}

Since our proposed abstractions of program model should not interfere
with proposition checking, we will consider model checking only as technique for
checking error state reachability (safety). From \LLVM point of view error states are
those, that does not satisfy some program assert (i.e., the transition to
those states were made through unsatisfied assert call).

### Abstraction model checking

When the number of states is large, its difficult to determine whether a program
is correct. To reduce state space size, there was proposed technique of
abstract model checking in [@Clarke94].

Abstract model checking abstracts a given model, taking some concrete state,
which is $n$-tuple of variables, and producing a $n$-tuple of abstract
variables. Abstraction of state $s = (s_1,\dots,s_n)$ is then formed by surjections
$\alpha = (\alpha_1,\dots,\alpha_n)$ that map each $s_1$ to abstract variable $\widehat{s}_1$.
Applying this transformation to transitions system of a program
results into a _minimal abstraction_ $\widehat{M}$ of the original program.

Formally having concrete domain $C$ we define for a state $s \in C_1 \times \dots \times C_n$
surjections $\alpha_1,\dots,\alpha_n$, that maps each variable of state to abstract domain
$A$, i.e. $\alpha_i : C_i \rightarrow A_i$. These mapping induce
a surjection $\alpha: C \rightarrow A$ defined as:
$$\alpha(s_1,\dots, s_n) = \alpha_1(s_1), \dots , \alpha_n(s_n).$$

\noindent
Alternatively we may define a relation between abstracted and concrete values by
a set of equivalence relations. Concretely each $\alpha_i$ corresponds to the
equivalence ${\sim}_i \subseteq C_i \times C_i$ defined by
$$s_i  \sim s'_i \iff \alpha_i(s_i) = \alpha_i(s'_i).$$

The mapping $\alpha$ induces an equivalence relation $\sim \in C \times C$ similarly.
We can now define what it means for transition system to be transformed to
abstract version. Lets $M$ be a transition system over some concrete domain $C$ and
$\alpha$ be a surjection from $C$ to abstract domain $A$. Intuitively we want an
abstract state $\widehat{s}$ to represent all states from $M$ for which $\alpha(s) =
\widehat{s}$.

\begin{definition}\label{def:am}
    Let $\widehat{M}$ be a transition system over $A$. We say that $\widehat{M}$
    approximates $M$ when
    \begin{enumerate}
        \item $h(s_0) = \widehat{s}_0$ is initial state in $\widehat{M}$, and
        \item $\exists s \exists p \exists a . \alpha(s) = \widehat{s} \wedge \alpha(p) = \widehat{p} \wedge s
               \xrightarrow[]{a} p$ implies $\widehat{s}
               \xrightarrow[]{a} \widehat{p}$ in $\widehat{M}$.
    \end{enumerate}
\end{definition}

\noindent
The transition system that has only those transitions required by definition \ref{def:am} is called
_minimal_.

Once we have abstract transition system $\widehat{M}$, the model checking is
straight forward. Traversing the abstract state space is done in same manner as
in original model checking approach. But satisfaction of property has to be done
over abstract state. Since abstract states represent a set of concrete states,
it may happen that abstraction does not separate error states from the rest.
Hence it may alarm an error even though the error state is not reachable.
But since abstraction includes original model $M$ we know that if $\widehat{M} \models \varphi$
then $M \models \varphi$, for some property $\varphi$. If the abstraction satisfies
also this property $\widehat{M} \not\models \varphi \implies M \not\models \varphi$,
we are saying that abstraction is _precise_.
