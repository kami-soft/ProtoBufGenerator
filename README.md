# ProtoBufGenerator

Delphi ProtoBuf files generator

### Update 13.11.2018
by @modersohn  (https://github.com/modersohn)
- support for optional fields
- strong check for fill all required fields
- minimize and beautify the generated code


### Update 14.01.2017
Add console generator version

### Update 08.01.2017
Add example

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
+ add root folder of this project to library path (Tools - Options - Delphi options - Library)
+ open ProtoBufGeneratorGroup.groupproj from root folder of this project
+ compile and run ProtoBufGenerator.exe
+ open .proto file(s) by press "Open" button
+ select directory for new generated .pas file(s) and press "Generate" button
+ add generated file to your project.

Do not use `LoadFromBuf`/`SaveToBuf` methods in generated classes! Use `LoadFromStream` and `SaveToStream` methods, which inherited from base class. See `Example2`, how to use generated classes.

## ToDo:
- add `extensions` (simple ignore directive, or - wrap to comment)
- add tests with "original" ProtoBuf generated binary messages.
