# Abstractions

Finally we are coming to main chapter of the thesis, where we will try to tackle
handling of inputs in model checking. We would like to minimize nondeterministic
choices during model checking process, hence minimize the state space of a
verified program and speed up a verification (enable model checker to verify
larger set of programs).

One of the approaches as mentioned before [ chapter 3 ] is symbolic abstraction.
More generally we may use power of general abstraction to shrink a domain of
nondeterministic variables.

\mytodo{ intro to abstractions with some definitions }

## Abstract domains

\mytodo { An abstract domain is an abstract algebra, implemented as a library module,
providing a description of abstract program properties and abstract property
transformers describing the operational effect of program instructions and
commands in the abstract. Abstract domains are often complete lattices, an
abstraction of powersets [@Cousot79] }


## Symbolic domain


\mytodo{ There are two main approaches to do abstractions of programs: \newline
    1. interprets \newline
    2. compilers
}

\mytodo{ Add pros and cons of both approaches }

## LART

- information lossless transformation

- Transformation objectives:
\mytodo{ add citation to objectives }

## Data flow analysis
    - annotation propagations

## Data type determination
    - intrinsics creation

## Approximate invariant assertions
    - bcp + assumes

## Domain manipulations insertion
    - substitution

## Other domains
