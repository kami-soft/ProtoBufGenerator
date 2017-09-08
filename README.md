# ProtoBufGenerator
Delphi ProtoBuf files generator

### Update 08.09.2017(jinnblue) rebase from kami-soft/master
+ Add Drap files to generator.exe feature
+ Add extensions check

### Update 14.01.2017
+ Add console generator version

### Update 08.01.2017
+ Add example

Work with binary ProtoBuf messages based on https://sourceforge.net/projects/protobuf-delphi/files/ by marat1961 (sources have some modifications)

Main features:
- generate classes, not records (like most other parsers)
- cross-platform(???) realization

Limitations:

- no comments in the middle of declaration:
  ```protobuf
  // this is correct
  message Sample { // this is correct
    // and this too
    repeated // this is NOT supported (comment in the middle of field declaration)
      sint32 Foo = 1;
    optional string FooString = 2; // this is correct
     ```

- field types `Any` and `OneOf` not supported
- reserved word `extensions` not supported
- `groups` (deprecated feature) not supported

## How to use
1. add root folder of this project to library path (Tools - Options - Delphi options - Library)
2. open ProtoBufGeneratorGroup.groupproj from root folder of this project
3. compile and run ProtoBufGenerator.exe
4. open .proto file(s) by press "Open" button
5. select directory for new generated .pas file(s) and press "Generate" button
6. add generated file to your project.

Do not use `LoadFromBuf`/`SaveToBuf` methods in generated classes! Use `LoadFromStream` and `SaveToStream` methods, which inherited from base class. See `Example2`, how to use generated classes.

## ToDo:
- add tests with "original" ProtoBuf generated binary messages.
