# DIVINE and friends {#chap03}

In this chapter we will look under the hood of DIVINE [@Divine17] the model checker.
And on top of that we will try to tackle problem of handling inputs by
symbolic model checking as introduced in [@Barnat14]. We will try to emphasize the
differences between classical model checking algorithm and symbolic algorithm,
in order to decompose symbolic part in following chapter.

For purpose of this thesis only minor knowledge of \DIVINE architecture is
needed. Our interest is mostly in \LLVM interpreter, since its only part that
interacts with a transformed program. Deeper description of \DIVINE can be found
in [@Divine17] or on project website
[divine.fi.muni.cz](https://divine.fi.muni.cz/).

## Model checking with \DIVINE

\marginpar{Described architecture is of latest release \DIVINE 4.0.}

\DIVINE is a modular platform for verification of real world programs.
Overall architecture can be divided into 2 parts: a verification environment
that provides tools for \LLVM interpretation and state space exploration, and a
runtime environment, whose purpose is to give support of language features like
memory allocation, threads and standard libraries.

The verification and runtime environment are split into several components with
precisely defined interfaces between them, see figure \ref{fig:architecture}.

The runtime part consists of user's program accompanied with necessary
libraries. For user's program is provided a \Cpp{} standard library and threading
library suited for \DIVINE interpreter. As environment for program is provided
a \DIVINE operating system (DiOS) that provides support for thread management
and scheduling. For communication between program and operating system a set
of `syscalls` is provided by DiOS.
The verification part consists of 2 main components: a \DIVINE virtual machine
that interprets \LLVM bitcode and provides a state space generator, and a
verification core that provides algorithms for verification.

\begin{figure}[!ht]

\resizebox{\textwidth}{!}{
\begin{tikzpicture}[>=stealth',shorten >=1pt,auto,node distance=4em, <->]
    \tikzstyle{runtime}=[fill=vivid!20]
    \tikzstyle{verification}=[fill=apple!20]


    \node [bcomponent] (input) {User's program $+$ libraries};
    \node [above = 0cm of input] (renv) {Runtime environment};
    \node [bcomponent, below = 0cm of input] (runtime) {\Cpp{} standard libraries,
        \texttt{pthreads}};
    \node [right = 1.7cm of runtime] (syslabel) {\texttt{syscalls}};
    \node [left = 2cm of runtime] (divine) {\large\DIVINE};
    \node [bcomponent, below = 0cm of runtime] (dios) {DiOS};

    \node [below = 0.4cm of dios] (venv) {Verification environment};
    \node [left = 2.5cm of venv] (hyplabel) {\texttt{hypercalls}};
    \node [bcomponent, below = 0cm of venv] (divm) {DiVM};
    \node [bcomponent, below = 0cm of divm] (vc) {Verification core};

    \begin{pgfonlayer}{background}
        \node[runtime, outer, fit = (renv) (input) (runtime) (dios)] (runtimebox) {};
    \end{pgfonlayer}

    \begin{pgfonlayer}{background}
        \node[verification, outer, fit = (venv) (divm) (vc)] (verificationbox) {};
    \end{pgfonlayer}

    \draw [-,dashed, thick] ([xshift=4cm]input.south east) -- ([xshift=-4cm]input.south west);
    \draw [rectangle connector=1.5cm] (input.east) to (dios.east);
    \draw [rectangle connector=0.75cm] (runtime.east) to (dios.east);

    \draw [rectangle connector=-1.5cm] (runtime.west) to (divm.west);
    \draw [rectangle connector=-0.75cm] (dios.west) to (divm.west);
\end{tikzpicture}
}
\caption{\DIVINE architecture is divided into two parsts. A runtime environment
represents a \LLVM bitcode that is interpreted by DiVM. And verification
component that provides model checking tooling. A communication between
layers is done by \texttt{syscalls} to DiOS and by \texttt{hypercalls}
to DiVM. We may notice that user's program can not call \texttt{hypercalls}
and communicates only with OS layer.}\label{fig:architecture}
\end{figure}


### \DIVINE virtual machine (DiVM)

A \DIVINE virtual machine aims to provide a bare minimum for \LLVM-based
model checking. This involves an execution of instructions, memory management,
nondeterministic choice and tracking of atomic sections. A deeper description of
DiVM can be found in [@RockaiCB17].
\marginpar{Nondeterministic choice serves for simulation of threads interleaving
and potential input generation.}

Side by side of \LLVM bitcode evaluation, DiVM stores a representation of a
program state. A snapshot of a state can be passed to verification algorithm
for safety analysis. And vice versa a verification algorithm may ask DiVM for
successors of a given state.

A program state is represented by memory configuration described by graph.
Nodes of graph represents objects (e.g. results of allocation, global
variables) and edges represents pointers between this objects.
DiVM stores these states compressed and hashed, and compares the graphs
directly for state equality.

DiVM in \DIVINE is accompanied by runtime environment, which is executed on top
of DiVM. This environment is expected to provide a _scheduler_, that is invoked
by DiVM during generation of state successors. An interface between DiVM and
runtime environment is provided by _hypercalls_, that enable runtime to modify
memory and create a state space branching by nondeterministic choice.

---

\begin{example}
A nondeterministic choice provided by DiVM as \texttt{\_\_vm\_choose} function
gives an ability to branch a state space. For example following nondeterministic
choice generates each state for \texttt{n} from a given \texttt{range}.
\end{example}

```cpp
int n  = __vm_choose( range );
```

---

### Verification workflow

A verification in \DIVINE is split into two phases, see figure
\ref{fig:verification}. A preprocessing phase, where an input program is
transformed into suitable input for DiVM. In second phase a transformed program
is processed by DiVM and some verification algorithm.

Since most of this thesis extends the preprocessing part, let's have a closer
look into program transformations. The transformations are similar to \LLVM
optimization passes (they work in \LLVM -to-\LLVM manner). They modify an input
program in order to extend a model checker capabilities. For example a
verification of programs with weak memory models is done via a transformation
[@Still16], verification of programs with exceptions [@Still17] and minor
optimizations like interrupts insertion for faster scheduling.

Transformations are made by external tool named \LART introduced in [@Rockai15]
as \LLVM Abstraction \& Refinement tool. The main motivation behind \LART is to
provide a preprocessing for \LLVM -based verification tools, simplifying their
job by reducing the problem size without compromising soundness of the
verification.

As abstraction tool \LART was never fully implemented and till this thesis it
was meant only as a proof-of-concept. The main aim of this thesis is to provide
a core analysis for \LART to be able inject an arbitrary abstraction into a
program.

\begin{figure}[!ht]
\centering
\resizebox{\textwidth}{!}{
\begin{tikzpicture}[>=stealth',shorten >=1pt,auto,node distance=4em, <->]

\tikzset{>=latex}

\tikzstyle{divm}=[fill=apple!20]
\tikzstyle{prepbox}=[fill=vivid!20]
    \node [] (input) {\Cpp{} code};
    \node [right = 1 cm of input] (prop) {property and options};

    \node [component, below = 1 cm of input] (cc) {compiler};
    \node [component, below = 2 cm of cc.west, anchor = west, text width= 4 cm] (lart) {Instrumentation};
    \node [left = 0.5 cm of cc] (runtime) {runtime};
    \node [above = 0.1 cm of cc, xshift=-2cm] (preproc) {Preprocessing};

    \node [component, below = 3 cm of lart.west, anchor = west, text width =
    4cm] (divm) {DiVM};
    \node [below = 5.2 cm of preproc.west, anchor = west] (divine) {Verification};

    \node [below = 5.5 cm of cc, text=apple] (valid) {Valid};
    \node [right = 0.5 cm of valid, text=orioles] (ce) {Error};

    \begin{pgfonlayer}{background}
        \node[prepbox, outer, fit = (cc) (runtime) (preproc) (lart)] (prepbox) {};
    \end{pgfonlayer}


    \begin{pgfonlayer}{background}
        \node[divm, outer, fit = (divine) (divm)] (prepbox) {};
    \end{pgfonlayer}

    \draw [->, input] (input) -- (cc);
    \draw [->] (cc) -> node {LLVM IR} (cc |- lart.north);
    \draw [->] (runtime) -- (cc);
    \draw [->, input] (prop) |- (lart);
    \draw [->, input] (prop) |- (divm);
    \draw [->] ( perpendicular cs: vertical line through={(cc.south)},
                                   horizontal line through={(lart.south)} )
               -> node {DiVM IR}
               ( perpendicular cs: vertical line through={(cc.south)},
                                   horizontal line through={(divm.north)} )
      ;
    \draw [->, dashed] (divm.south) -- (valid.north);
    \draw [->, dashed] (divm.south) -- (ce.north);
\end{tikzpicture}
}
\caption{ \mytodo{ finish figure } Verification workflow}\label{fig:verification}
\end{figure}

## Symbolic model checking with \SymDIVINE

Since \DIVINE is an explicit state model checker, its big pitfall are inputs. The
only way to handle inputs in \DIVINE is to enumerate all possibilities, what
leads to enormous state space explosion. Hence current \DIVINE is usable only on
closed programs (programs without input). As an attempt to solve input problem a
\SymDIVINE was designed as an extension of \DIVINE. \SymDIVINE is
a proof-of-concept tool that is based on idea of _control-explicit data-symbolic_
model checking [@Barnat14], described below.

### Control-explicit data-symbolic model checking

In compare to exhaustive enumeration of states by purely explicit approach, a
control-explicit data-symbolic approach tries to group states into sets, when
they differ only in data values but not in control location. In this way \SymDIVINE is able to
simulate inputs as sets of possible values. These sets, also called _multi
states_ , are described by explicit control location and symbolic representation of
data, in our case by _smt_ formula (for better description see section
\ref{sec:multistates}). During model checking a state space exploration
algorithm works directly with multi states, hence the computation is more
time-consuming, since some \SMT solver has to be called in order to
distinguish reachable states. On the other hand symbolic approach may bring
exponential memory savings and avoid state space explosion caused by inputs.

### Representation of multi states \label{sec:multistates}

A challenging part of symbolic model checking is how to define a suitable
representation of states. Representation of control location (explicit part of
multistate) is straightforward. A model checker just needs to store
a program location for each thread. On the other hand coming up with a good
representation of symbolic data may be quite challenging. Since \DIVINE aims
for bit-precise verification a suitable choice is representation of data
by _smt_ formulae [@Bauch14].

\marginpar{ \color{red} TODO introduce smt }

Since \SymDIVINE does not support dynamic memory allocation, the representation
of symbolic data becomes much more simpler. In current state representation of
data is done by quantified bit-vector smt formulae. For identification of
symbolic variables \SymDIVINE uses a names given by function segment on stack
and offset of given variable in the corresponding segment.

Besides remembering current values of variables, \SymDIVINE has to keep for
some variables previous evaluations (also called generations). This happens when
value of symbolic variable depends on another symbolic variable, see example
\ref{ex:gen}.

---

\begin{example}\label{ex:gen}
Having following C code \SymDIVINE has to store multiple generations of variable
\texttt{a}, because after evaluation of all statements \SymDIVINE needs to know
that, \texttt{b} is equal to \texttt{a} from first line (first generation of
\texttt{a}) and \texttt{a} (in second generation) is equal to 0.
\end{example}

```cpp
int a = 10;
int b = a;
a = 0;
```

---

A symbolic representation of data is further structured into two parts -- a
program _path condition_ and data _definitions_. The path condition is a
conjunction of formulae that represents a restriction of the data that have been
collected during the branching along the path leading to the current location.
_Definitions_, on the other hand, are made of a set of formulae in the form
_variable = expression_ that describe internal relations among variables.
Definitions are produced as a result of an assignment or arithmetic
instructions. The structure of symbolic data representation allows for a
precise description of what is needed for the model checking, but it lacks the
canonical representation. As a matter of fact, the equality of multi-states
cannot be performed as a syntax equality, instead, \SymDIVINE employs smt
solver and quantified formulae to check the satisfiability of a path condition
and to decide the equality of two multi-states [@Mrazek16].

### State space exploration

\mytodo{example porovnania behu divinu a symdivinu}

\resizebox{\textwidth}{!}{
\begin{tikzpicture}[>=stealth',shorten >=1pt,auto,node distance=4em, <->]
\tikzset{>=latex}

\tikzstyle{symdivine}=[fill=apple!20]
\tikzstyle{prepbox}=[fill=vivid!20]
\tikzstyle{smt}=[fill=orioles!20]
    \node [component](clang) {clang -emit-llvm};
    \node [above = 0.3 cm of clang] (preprocessing) {Preprocessing};
    \node [component, below = 0.5 cm of clang](lart) {LART};

    \node [component, right = 0.6 cm of lart, ](interpreter) {\LLVM interpreter};
    \node [component, right = 0.5 cm of interpreter, minimum width=1 cm](generator) {State space generator};

    \node [component, smt, right = 0.5 cm of generator, minimum width=1 cm, text width=1 cm](smt){SMT solver};
    \node [component, above = 0.5 cm of generator, minimum width=1 cm](exploration) {Exploration algorithm};
    \node [above = 0.3 cm of exploration] (symdivine) {SymDIVINE};

    \begin{pgfonlayer}{background}
        \node[prepbox, outer, fit = (clang) (lart) (preprocessing)] (prepbox) {};
    \end{pgfonlayer}

    \begin{pgfonlayer}{background}
        \node[symdivine, outer, fit = (interpreter) (generator) (exploration) (symdivine) ] (preprocessing) {};
    \end{pgfonlayer}

    \node [left = 1.5 cm of clang] (start) {input.c};
    \node [right = 2 cm of exploration] (end) {};
    \node [below = 2.3 cm of start] (property) {property};

    \draw [->] (clang) -- (lart);

    \draw [->] (lart) -- (interpreter);

    \draw [<->] (interpreter) -- (generator);

    \draw [<->] (smt) -- (generator);

    \draw [->] (generator) -- (exploration);

    \draw [->, dashed] (start) -- (clang);
    \draw [->, dashed] (property) -| (generator);
    \draw [->, output] (exploration) -- (end) node [midway, above = 3pt] {result};
\end{tikzpicture}
}
\mytodo{zjednotit s vrchnym obrazkom}

\mytodo{nedostatky symdivinu}
