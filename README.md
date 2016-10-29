# ProtoBufGenerator
## Work in progress!
Delphi ProtoBuf files generator

Work with binary ProtoBuf messages is planned to base on https://sourceforge.net/projects/protobuf-delphi/files/ by marat1961 (sources have little modifications)

Planned main features:
- generate classes, not records (like most other parsers)
- cross-platform(???) realization

Limitations:
~~- nested routines are not supported. You can`t use something like
  ```protobuf
    message SampleLevel1 {
      required int32 Foo = 1;
      message SampleLevel2 {
      ...
   ```
~~
now nested routines are supported

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