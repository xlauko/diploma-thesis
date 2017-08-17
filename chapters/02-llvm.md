# LLVM

In this chapter we will cover basics of \LLVM bitcode.
\footnote{ Quoting LLVM website, The LLVM Project is a collection of modular and reusable
compiler and toolchain technologies.Despite its name, LLVM has little to do with
traditional virtual machines. The name "LLVM" itself is not an acronym; it is
the full name of the project.}
Focus will be on instruction set for values manipulation, \LLVM type system and control flow of
programs. We will use gained knowledge in following chapters, to be able to do
abstraction over \LLVM values.

## Intro to LLVM IR
Besides defining the semantics of bitcode, \LLVM is primary toolkit for building
compilers an \LLVM bitcode manipulation.

\todo[inline]{ LLVM compiler image }

Since the \LLVMIR simplifies semantics of verified language it is much more
suitable for model checking. Model checking can abstract from complicated
grammar of verified language and process \LLVM bicode produces by compiler
front-end.

The \LLVMIR is kind of similar to a assembly language, with few major
differences.

### Modules, Functions and smaller building blocks

The \LLVMIR is build upon instructions, whose manipulates values in virtual
registers or they move values between registers and memory. Each instruction
has at most one return value, which is assigned to register.

\todo[inline]{ SSA as definition }

\todo[inline]{ A basic block is a sequence of \LLVM instructions without
a branching, with potential branch instruction at the end. }
\todo[inline]{ definition of function }

\todo[inline]{ definition of value }

\todo[inline]{ describe intrinsics }

### Type system

### Control flow

## Clang compilation process

\todo[inline]{ describe passes + instrumentation }
