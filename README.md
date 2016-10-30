# ProtoBufGenerator
## Work in progress!
Delphi ProtoBuf files generator

Work with binary ProtoBuf messages based on https://sourceforge.net/projects/protobuf-delphi/files/ by marat1961 (sources have little modifications)

Main features:
- generate classes, not records (like most other parsers)
- cross-platform(???) realization

Limitations:

- no comments in the middle of declaration:
  ```protobuf
  // this is correct
  message Sample { // this is correct
    // and this too
    repeated // this is NOT supported (middle of field declaration)
      sint32 Foo = 1;
    optional string FooString = 2; // this is correct
     ```

- ```import``` not supported (skip declaration)
- field types `Any` and `OneOf` not supported
- `extend` and `extensions` not supported

## How to use
+ add root folder of this project to library path (Tools - Options - Delphi options - Library)
+ open ProtoBufGeneratorGroup.groupproj from root folder of this project
+ compile and run ProtoBufGenerator.exe
+ open .proto file by press "Open" button or drag&drop .proto file to main form
+ select directory for new generated .pas file
+ add generated file to your project

Do not use LoadFromBuf/SaveToBuf methods in generated classes!

Use LoadFromStream and SaveToStream methods, which inherited from base class.