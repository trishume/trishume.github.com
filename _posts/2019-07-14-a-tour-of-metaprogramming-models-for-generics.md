---
layout: post
title: "A Tour of Metaprogramming Models for Generics"
description: ""
category:
tags: [compilers]
---
{% include JB/setup %}

In some domains of programming it's common to want to write a data structure or algorithm that can work with elements of many different types, such as a generic list or a sorting algorithm that only needs a comparison function. Different programming languages have come up with all sorts of solutions to this problem, from just pointing people to existing general features that can be useful for the purpose (e.g C, Go) to generics systems so powerful they become Turing-complete (e.g. [Rust](https://sdleffler.github.io/RustTypeSystemTuringComplete/), [C++](http://matt.might.net/articles/c++-template-meta-programming-with-lambda-calculus/)). In this post I'm going to take you on a tour of the generics systems in many different languages and how they are implemented. We'll start from how languages without a special generics system like C solve the problem and then show how gradually adding extensions in different directions leads to the systems found in other languages.

One reason I think generics are an interesting case is that I think they're a simple case of the general problem of metaprogramming: writing programs that can generate classes of other programs. As evidence I'll fit three different fully general metaprogramming methods in as extensions from different directions in the space of generics systems: dynamic languages like Python, procedural macro systems like [Template Haskell](https://wiki.haskell.org/A_practical_Template_Haskell_Tutorial), and staged compilation like [Zig](https://ziglang.org/#Generic-data-structures-and-functions) and [Terra](http://terralang.org/).

## The basic ideas

Let's say we're programming in a language without a generics system and we want to make a generic stack data structure with `push` and `pop` methods which works for any data type. The problem is that each function and type definition we write only works for data that's the same size, is copied the same way, and generally acts the same way.

Two ideas for how to get around this are to find a way to make all data types act the same way in our data structure, or to make multiple copies of our data structure with slight tweaks to deal with each data type the correct way. These two ideas form the basis of the two major classes of solutions to generics: boxing and monomorphization.

Boxing is where we put everything in uniform "boxes" so that they all act the same way. This is usually done by allocating things on the heap and just putting pointers in the data structure. We can make pointers to all different types act the same way so that the same code can deal with all data types! However this can come at the cost of extra memory allocation, dynamic lookups and cache misses. In C this corresponds to making your data structure store `void*` pointers and just casting your data to and from `void*` (allocating on the heap if the data isn't already on the heap).

Monomorphization is where we copy the code multiple times for the different types of data we want to store. This way each instance of the code can directly use the size and methods of the data it is working with, without any dynamic lookups. This produces the fastest possible code, but comes at the cost of bloat in code size and compile times as the same code with minor tweaks is pasted many times. In C this corresponds to [defining your entire data structure in a macro](https://www.cs.grinnell.edu/~rebelsky/musings/cnix-macros-generics) and calling it for each type you want to use it with.

Each of these schools of generics has many directions it can be extended in to add additional power or safety, and different languages have taken them in very interesting directions. Some languages like Rust and C# even provide both options!

## Boxing

Let's start with an example of the basic boxing approach in Go:

```go
type Stack struct {
  values []interface{}
}

func (this *Stack) Push(value interface{}) {
  this.values = append(this.values, value)
}

func (this *Stack) Pop() interface{} {
  x := this.values[len(this.values)-1]
  this.values = this.values[:len(this.values)-1]
  return x
}
```

Example languages that use basic boxing: C (`void*`), Go (`interface{}`), pre-generics Java (`Object`), pre-generics Objective-C (`id`)

## Type-erased boxed generics

Here's some problems with the basic boxing approach:

- Depending on the language we often need to cast values to and from the correct type every time we read or write to the data structure.
- Nothing stops us from putting elements of different types into the structure, which could allow bugs leading to runtime crashes.

A solution to both of these problems is to add generics functionality to the type system, while still using the basic boxing method exactly as before at runtime. This approach is often called type erasure, because the types in the generics system are "erased" and all become the same type (like `Object`) under the hood.

Java and Objective-C both started out with basic boxing, and later added language features for generics with type erasure, even using the exact same collection types as before for compatibility but with optional generic type parameters. See the following example from the [Wikipedia article on Java Generics](https://en.wikipedia.org/wiki/Generics_in_Java):

```java
List v = new ArrayList();
v.add("test"); // A String that cannot be cast to an Integer
Integer i = (Integer)v.get(0); // Run time error

List<String> v = new ArrayList<String>();
v.add("test");
Integer i = v.get(0); // (type error) compilation-time error
```

### Inferred boxed generics with a uniform representation

OCaml takes this idea even further with a uniform representation where there are no primitive types that require an additional boxing allocation (like `int` needing to be turned into an `Integer` to go in an `ArrayList` in Java), because everything is either already boxed or represented by a pointer-sized integer, so everything is one machine word. However when the garbage collector looks at data stored in generic structures it needs to tell pointers from integers so integers are tagged using a 1 bit in a place where valid aligned pointers never have a 1 bit, leaving only 31 or 63 bits of range!

OCaml also has a type inference system so you can write a function and the compiler will infer the most generic type possible if you don't annotate it, which can lead to functions that look like a dynamically typed language:

```ocaml
let first (head :: tail) = head
(* inferred type: 'a list -> 'a *)
```

The inferred type is read as "a function from a list of elements of type `'a` to something of type `'a`". Which encodes the relation that the return type is the same as the list type but can be any type.

## Interfaces

A different limitation in the basic boxing approach is that the boxed types are *completely* opaque. This is fine for data structures like a stack, but things like a generic sorting function need some extra functionality, like a type-specific comparison functionality. There's a number of different ways of both implementing this at runtime and exposing this in the language, which are technically different questions and you can [implement the same language using multiple of these approaches](http://okmij.org/ftp/Computation/typeclass.html). However it seems like different language features mostly lend themselves towards being implemented a certain way and then language extensions take advantage of the strengths of the chosen implementation. This means there's mostly two families of languages based around the different runtime approaches:

### Interface vtables

If we want to expose type-specific functions while sticking with the boxing strategy of a uniform way of working with everything, we can just make sure that there's a uniform way to find the type-specific function we want. This approach is called "vtables" (shortened from "virtual method tables" but nobody uses the full name) and how it is implemented is that at offset zero in every object in the generic structure is a pointer to some tables of function pointers with a consistent layout. These tables allow the generic code to look up a pointer to the type-specific functions in the same way for every type by indexing certain pointers at fixed offsets.

This is how `interface` types are implemented in Go and `dyn` `trait` objects are implemented in Rust. When you cast a type to an interface type for something it implements, it gets wrapped in an interface type that contains a pointer to a vtable of the type-specific functions for that interface and a pointer to the original object. However this requires an extra layer of pointer indirection and a different layout, which is why sorting in Go uses [an interface for the container](https://golang.org/pkg/sort/#Interface) instead of taking a slice of a `Comparable` interface, because it would require allocating an entire new slice of the interface types and then it would only sort that and not the original slice!

### Object-oriented programming

A language feature that makes use of the power of vtables is object-oriented programming. Instead of having separate interface objects that contain the vtables, languages like Java just have a vtable pointer at the start of every object. Java and similar languages have a system of inheritance and interfaces that can be implemented with vtables.

As well as providing additional features like inheritance, this also solves the earlier problem of needing to construct new interface types with indirection. Unlike `Go`, in Java [the sorting function](https://docs.oracle.com/javase/7/docs/api/java/util/Arrays.html#sort(java.lang.Object[])) can just use the `Comparable` interface on types that implement it.

### Reflection


