# Introduction

\begin{chapquote}{Monty Python}
Nobody expects Spanish inquisition.
\end{chapquote}

\noindent
Since the early beginnings of computer science, software engineers struggle to
achieve correctness of a software.  Nowadays a common approach used by industry
is a testing. Testing enables developers to cover basic use cases, but with a
growth of a software its hardly scales up to a satisfactory coverage.

\question{ Should I describe it more? } Besides that testing is in trouble, when
it encounters some nondeterminism in a program. We may distinguish two types of
nondeterminism. A data nondeterminism that is introduced by user inputs and
control-flow nondeterminism that is caused by unpredictable interleaving of
parallel programs.

To beat the problems of testing there have been invented many techniques of
formal verification.

\mytodo{ another approaches (model checking, abstract interpretation, symbolic
        execution) }

\mytodo{ how to hadle nondeterminism from }

\mytodo{ Setting in divine world } To verify real world programs, DIVINE builds
model from llvm. Hence the model corresponds precisely to program execution.

\begin{marginfigure} \includegraphics[width=\marginparwidth]{example-image-a}%
\caption{A small rectangle put in the margin.\label{rectangle}}%
\end{marginfigure}

## Aims

Abstraction of program have no cost for explicit program verification, since
model checker is not modified. Only interpretation of abstracted values adds
cost to model checking, but since the abstracted values narrows the domain of
values, the size of the state space will be decreased.

\mytodo{ Aims of work } \mytodo{ Chapters descriptions linked with aims }

Shouldn't [@King76]

\sidenote{goes to side}
