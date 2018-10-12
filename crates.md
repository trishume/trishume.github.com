---
layout: page
title: Tristan's Top 100 Crates
---

# Tristan's Top 100 Rust Crates

Based on a [talk](/talks) I gave at the Bay Area Rust Meetup in October 2018.

## Command Line: Better existing commands

- [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep): Fast nice grep/ag replacement
- [sharkdp/bat](https://github.com/sharkdp/bat): cat replacement with syntax highlighting and git
- [sharkdp/fd](https://github.com/sharkdp/fd): faster and easier alternative to `find`
- [ogham/exa](https://github.com/ogham/exa): nicer alternative to `ls`
- [Aaronepower/tokei](https://github.com/Aaronepower/tokei): count lines of code


## Command Line: New(ish) powers

- [sharkdp/hyperfine](https://github.com/sharkdp/hyperfine): benchmark command line programs
- [benfred/py-spy](https://github.com/benfred/py-spy): profile Python programs
- [rbspy/rbspy](https://github.com/rbspy/rbspy): profile Ruby programs
- [nathan/pax](https://github.com/nathan/pax): JS bundler
- [m4b/bingrep](https://github.com/m4b/bingrep): search through executables with structure


## Web: Static

- [Keats/gutenberg](https://github.com/Keats/gutenberg): Lots of fancy features
- [cobalt-org/cobalt.rs](https://github.com/cobalt-org/cobalt.rs): Inspired by Jekyll


## Web: Backend

- <https://actix.rs/>: Actor-based
- <https://rocket.rs/>: Fancy compiler magic, very clean
- <https://gotham.rs/>: Futures-based
- <http://diesel.rs/>: Type safe ORM


## Web: Frontend

- [DenisKolodin/yew](https://github.com/DenisKolodin/yew): React/elm style front end
- [rustwasm/wasm-bindgen](https://github.com/rustwasm/wasm-bindgen): Generate WASM bindings
- [rustwasm/wasm-pack](https://github.com/rustwasm/wasm-pack): Package Rust to NPM packages


## Web: Templating

- [djc/askama](https://github.com/djc/askama): Jinja-like, compiles templates at compile time
- [Keats/tera](https://github.com/Keats/tera): Jinja-like, compiles templates at runtime


## Async I/O

- <https://tokio.rs/>: Asynchronous cross-platform I/O
- [rust-lang-nursery/futures-rs](https://github.com/rust-lang-nursery/futures-rs): The Futures API Tokio builds on
- [carllerche/mio](https://github.com/carllerche/mio): The underlying platform abstraction Tokio uses
- [hyperium/hyper](https://github.com/hyperium/hyper): HTTP based on Tokio, fast and high-quality


## Graphics & Games

- <http://ggez.rs/>: Simple fully-featured 2D game library
- [gfx-rs/gfx](https://github.com/gfx-rs/gfx): Cross-platform 3D graphics abstraction
- [tomaka/glutin](https://github.com/tomaka/glutin): Cross-platform OpenGL window creation
- [glium/glium](https://github.com/glium/glium): Safe OpenGL wrapper
- [slide-rs/specs](https://github.com/slide-rs/specs): Fast and flexible Enity Component System
- [sebcrozet/kiss3d](https://github.com/sebcrozet/kiss3d): Easy high level 3D graphics
- [phaazon/warmy](https://github.com/phaazon/warmy): hot reloading resources


## 2D Graphics

- [servo/webrender](https://github.com/servo/webrender): Really fast 2D web-like graphics renderer
- [pcwalton/pathfinder](https://github.com/pcwalton/pathfinder): Fancy new GPU vector graphics technique
- [nical/lyon](https://github.com/nical/lyon): Vector graphics tessellation library
- [alexheretic/glyph-brush](https://github.com/alexheretic/glyph-brush): Easy library for text rendering


## GUI

- [PistonDevelopers/conrod](https://github.com/PistonDevelopers/conrod): Immediate mode OpenGL GUI
- <http://gtk-rs.org/>: High quality GTK+ bindings
- [antoyo/relm](https://github.com/antoyo/relm): Elm-inspired GTK+ UI library
- [maps4print/azul](https://github.com/maps4print/azul): Fancy new WIP GUI framework


## Extending other languages

- [neon-bindings/neon](https://github.com/neon-bindings/neon): Node
- [tildeio/helix](https://github.com/tildeio/helix): Ruby
- [getsentry/milksnake](https://github.com/getsentry/milksnake): Python FFI
- [PyO3/pyo3](https://github.com/PyO3/pyo3): Python bindings
- [hansihe/rustler](https://github.com/hansihe/rustler): Erlang
- [dtolnay/syn](https://github.com/dtolnay/syn): Rust procedural macros


## Example: helix

```rust
ruby! {
    class Console {
        def log(string: String) {
            println!("LOG: {}", string);
        }
    }
}
```


## OS Interface

- [rust-lang-nursery/rand](https://github.com/rust-lang-nursery/rand): Random number generation
- [BurntSushi/walkdir](https://github.com/BurntSushi/walkdir): Recursive directory walking
- [passcod/notify](https://github.com/passcod/notify): file system notification
- [Stebalien/tempfile](https://github.com/Stebalien/tempfile): Cross-platform temporary files


## Command line output

- [BurntSushi/termcolor](https://github.com/BurntSushi/termcolor): Cross-platform terminal colors
- [rust-lang/log](https://github.com/rust-lang/log): Common logging abstraction API
- [slog-rs/slog](https://github.com/slog-rs/slog): Fancy structured logging
- [mitsuhiko/indicatif](https://github.com/mitsuhiko/indicatif): Fancy progress bars


## Command line arguments

- [clap-rs/clap](https://github.com/clap-rs/clap): Command line argument parsing
- [TeXitoi/structopt](https://github.com/TeXitoi/structopt): Custom derive to get arguments in a structure


## Example: structopt

```rust
/// A basic example
#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
struct Opt {
    /// Activate debug mode
    #[structopt(short = "d", long = "debug")]
    debug: bool,
    /// Set speed
    #[structopt(short = "s", long = "speed", default_value = "42")]
    speed: f64,
    /// Number of cars
    #[structopt(short = "c", long = "nb-cars")]
    nb_cars: Option<i32>,
}

fn main() {
    let opt = Opt::from_args();
    println!("{:?}", opt);
}
```

## Utility libraries

- [rust-lang-nursery/failure](https://github.com/rust-lang-nursery/failure): Clean error management
- [rust-lang-nursery/lazy-static.rs](https://github.com/rust-lang-nursery/lazy-static.rs): Lazily constructed global variables
- [bitflags/bitflags](https://github.com/bitflags/bitflags): Efficiently collections of on/off flags
- [BurntSushi/byteorder](https://github.com/BurntSushi/byteorder): Getting numbers to/from bytes of different endiannesses.


## Example: failure

```rust
#[derive(Debug, Fail)]
enum ToolchainError {
    #[fail(display = "invalid toolchain name: {}", name)]
    InvalidToolchainName { name: String },
    #[fail(display = "unknown toolchain version: {}", version)]
    UnknownToolchainVersion { version: String }
}

pub fn read_toolchains(path: PathBuf) -> Result<Toolchains, Error> {
  // ... can use ? on ToolchainError, io Error and other errors
}
```


## Example: lazy_static

```rust
lazy_static! {
    static ref HASHMAP: HashMap<u32, &'static str> = {
        let mut m = HashMap::new();
        m.insert(0, "foo");
        m
    };
}

fn main() {
    println!("`0` is \"{}\".", HASHMAP.get(&0).unwrap());
}
```


## Example: bitflags

```rust
bitflags! {
    struct Flags: u32 {
        const A = 0b00000001;
        const B = 0b00000010;
        const C = 0b00000100;
        const ABC = Self::A.bits | Self::B.bits | Self::C.bits;
    }
}

fn main() {
    let e1 = Flags::A | Flags::C;
    let e2 = Flags::B | Flags::C;
    assert_eq!((e1 | e2), Flags::ABC);   // union
    assert_eq!((e1 & e2), Flags::C);     // intersection
    assert_eq!((e1 - e2), Flags::A);     // set difference
    assert_eq!(!e2, Flags::A);           // set complement
}
```


## Text processing

- [rust-lang/regex](https://github.com/rust-lang/regex): Fast linear time regular expressions
- [raphlinus/pulldown-cmark](https://github.com/raphlinus/pulldown-cmark): Markdown parser
- [mgeisler/textwrap](https://github.com/mgeisler/textwrap): Monospace text wrapping
- [dguo/strsim-rs](https://github.com/dguo/strsim-rs): String similarity metrics like Levenshtein


## Algorithms & Data structure utilities

- [bluss/rust-itertools](https://github.com/bluss/rust-itertools): extra iterator functions!
- [cbreeden/fxhash](https://github.com/cbreeden/fxhash): Faster hash maps
- [indiv0/lazycell](https://github.com/indiv0/lazycell): Lazily filled cell
- [bluss/petgraph](https://github.com/bluss/petgraph): Graph data structure
- [gnzlbg/slice_deque](https://github.com/gnzlbg/slice_deque): deque using page tricks to yield slices
- [tantivy-search/tantivy](https://github.com/tantivy-search/tantivy): full text search


## Cargo addons

- [killercup/cargo-edit](https://github.com/killercup/cargo-edit): Easily add crate dependencies
- [passcod/cargo-watch](https://github.com/passcod/cargo-watch): Rebuild on file modification
- [RazrFalcon/cargo-bloat](https://github.com/RazrFalcon/cargo-bloat): Find what's making your binaries large


## Testing

- [colin-kiegel/rust-pretty-assertions](https://github.com/colin-kiegel/rust-pretty-assertions): Make assert_eq show diffs
- [rust-fuzz/honggfuzz-rs](https://github.com/rust-fuzz/honggfuzz-rs): Simple fuzz testing


## Property Testing

- [AltSysrq/proptest](https://github.com/AltSysrq/proptest): Powerful property testing library
- [BurntSushi/quickcheck](https://github.com/BurntSushi/quickcheck): Simple property testing library


## Example: Property testing

```rust
#[macro_use] extern crate quickcheck;
quickcheck! {
  fn prop(xs: Vec<u32>) -> bool {
      xs == reverse(&reverse(&xs))
  }
}

#[macro_use] extern crate proptest;
proptest! {
    #[test]
    fn parses_all_valid_dates(ref s in "[0-9]{4}-[0-9]{2}-[0-9]{2}") {
        parse_date(s).unwrap();
    }
}
```


## Optimizing

- [japaric/criterion.rs](https://github.com/japaric/criterion.rs): Fancy statistical benchmarking
- [pcwalton/signpost](https://github.com/pcwalton/signpost): Show points of interest in Instruments


## Vector math

- [brendanzab/cgmath](https://github.com/brendanzab/cgmath): `Vector`, `Matrix`, `Point`, a few others
- <http://nalgebra.org/>: Nice docs, more helpers, more types (e.g `Translation`)
- [servo/euclid](https://github.com/servo/euclid): Maximum type safety (on the other hand, maximum hassle)


## Parallelizing

- [rayon-rs/rayon](https://github.com/rayon-rs/rayon): has easy-to use threadpools and parallel iterators
- [crossbeam-rs](https://github.com/crossbeam-rs): includes fast lock-free channels, queues, stacks and more
    - Includes scoped threads that can access stack data
    - Also includes a library for GC in lock-free data structures
- [AdamNiederer/faster](https://github.com/AdamNiederer/faster): Simple SIMD iterators


## Example: rayon

```rust
use rayon::prelude::*;
fn sum_of_squares(input: &[i32]) -> i32 {
    input.par_iter() // <-- just change that!
         .map(|&i| i * i)
         .sum()
}
```


## Example: faster

```rust
use faster::*;
let lots_of_3s = (&[-123.456f32; 128][..]).simd_iter()
    .simd_map(f32s(0.0), |v| {
        f32s(9.0) * v.abs().sqrt().rsqrt().ceil().sqrt() - f32s(4.0) - f32s(2.0)
    })
    .scalar_collect();
```


## Serialization

- <https://serde.rs/>: The ultimate (de)serialization system
  - JSON, CBOR, YAML, MessagePack, TOML, Pickle, BSON, Avro, XML
- [TyOverby/bincode](https://github.com/TyOverby/bincode): Binary serde format
- [ron-rs/ron](https://github.com/ron-rs/ron): Rust-like serde format
- [danburkert/prost](https://github.com/danburkert/prost): Protobuf


## Example: serde

```rust
#[macro_use]
extern crate serde_derive;
extern crate serde;
extern crate serde_json;

#[derive(Serialize, Deserialize, Debug)]
struct Point { x: i32, y: i32 }

fn main() {
    let point = Point { x: 1, y: 2 };
    let serialized = serde_json::to_string(&point).unwrap();
    let deserialized: Point = serde_json::from_str(&serialized).unwrap();
    println!("ser = {}, de = {:?}", serialized, deserialized);
}
```


## Parsing and compiling

- [Geal/nom](https://github.com/Geal/nom): Fast macro-based parser generator
- [pest-parser/pest](https://github.com/pest-parser/pest): Parser generator using special grammar files
- [CraneStation/cranelift](https://github.com/CraneStation/cranelift): Fast compiler backend
- [TheDan64/inkwell](https://github.com/TheDan64/inkwell): Safe LLVM wrapper


## Other

- [google/tarpc](https://github.com/google/tarpc): RPC framework
- [RustCrypto/hashes](https://github.com/RustCrypto/hashes): Crypto hashes
- [spacejam/sled](https://github.com/spacejam/sled): in-process database
- <https://panopticon.re>: disassembler library
- [m-labs/smoltcp](https://github.com/m-labs/smoltcp): TCP implementation
- [edef1c/libfringe](https://github.com/edef1c/libfringe): Coroutines / green threads
- [trishume/syntect](https://github.com/trishume/syntect): Syntax highlighting
