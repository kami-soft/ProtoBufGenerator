﻿unit TestProtoBuf;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit
  being tested.

}

interface

uses
  TestFramework,
  Classes,
  SysUtils;

type
  // Test methods for proto buf implementation
  // moved from pbTest.dpr and UnitTest.pas

  TestProtoBufMethods = class(TTestCase)
  strict private
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestVarint;
    procedure TestReadLittleEndian32;
    procedure TestReadLittleEndian64;
    procedure TestDecodeZigZag;
    procedure TestEncodeDecodeZigZag;
    procedure TestReadString;
    procedure TestMemoryLeak;
    procedure TestReadTag;
  end;

implementation

uses
  pbPublic,
  pbInput,
  pbOutput;

procedure TestProtoBufMethods.SetUp;
begin
end;

procedure TestProtoBufMethods.TearDown;
begin
end;

procedure TestProtoBufMethods.TestDecodeZigZag;
begin
  (* 32 *)
  CheckEquals(0, decodeZigZag32(0));
  CheckEquals(-1, decodeZigZag32(1));
  CheckEquals(1, decodeZigZag32(2));
  CheckEquals(-2, decodeZigZag32(3));
  CheckEquals(integer($3FFFFFFF), decodeZigZag32($7FFFFFFE));
  CheckEquals(integer($C0000000), decodeZigZag32($7FFFFFFF));
  CheckEquals(integer($7FFFFFFF), decodeZigZag32(integer($FFFFFFFE)));
  CheckEquals(integer($80000000), decodeZigZag32(integer($FFFFFFFF)));
  (* 64 *)
  CheckEquals(0, decodeZigZag64(0));
  CheckEquals(-1, decodeZigZag64(1));
  CheckEquals(1, decodeZigZag64(2));
  CheckEquals(-2, decodeZigZag64(3));
  CheckEquals(Int64($000000003FFFFFFF), decodeZigZag64($000000007FFFFFFE));
  CheckEquals(Int64($FFFFFFFFC0000000), decodeZigZag64($000000007FFFFFFF));
  CheckEquals(Int64($000000007FFFFFFF), decodeZigZag64($00000000FFFFFFFE));
  CheckEquals(Int64($FFFFFFFF80000000), decodeZigZag64($00000000FFFFFFFF));
  CheckEquals(Int64($7FFFFFFFFFFFFFFF), decodeZigZag64(Int64($FFFFFFFFFFFFFFFE)));
  CheckEquals(Int64($8000000000000000), decodeZigZag64(Int64($FFFFFFFFFFFFFFFF)));
end;

procedure TestProtoBufMethods.TestEncodeDecodeZigZag;
var
  i: integer;
  j: integer;

  i64: Int64;
  j64: Int64;
begin
  for i := -50000 to 50000 do
    begin
      j := EncodeZigZag32(i);
      CheckEquals(i, decodeZigZag32(j), 'ZigZag32 symmetry error');
    end;

  i := -MaxInt;
  j := EncodeZigZag32(i);
  CheckEquals(i, decodeZigZag32(j), 'ZigZag32 symmetry error');

  i := MaxInt;
  j := EncodeZigZag32(i);
  CheckEquals(i, decodeZigZag32(j), 'ZigZag32 symmetry error');

  for i64 := -50000 to 50000 do
    begin
      j64 := EncodeZigZag64(i64);
      CheckEquals(i64, decodeZigZag64(j64), 'ZigZag64 symmetry error');
    end;

  i64 := $7FFFFFFFFFFFFFFF;
  j64 := EncodeZigZag64(i64);
  CheckEquals(i64, decodeZigZag64(j64), 'ZigZag64 symmetry error');
end;

procedure TestProtoBufMethods.TestMemoryLeak;
const
  Mb = 1024 * 1024;
var
  in_pb: TProtoBufInput;
  buf_size: integer;
  s: AnsiString;
  i: integer;
begin
  buf_size := 64 * Mb;
  SetLength(s, buf_size);
  for i := 0 to 200 do
    begin
      in_pb := TProtoBufInput.Create(PAnsiChar(s), Length(s), false);
      in_pb.Free;
    end;
end;

procedure TestProtoBufMethods.TestReadLittleEndian32;
type
  TLittleEndianCase = record
    bytes: array [1 .. 4] of byte; // Encoded bytes.
    value: integer; // Parsed value.
  end;
const
  LittleEndianCases: array [0 .. 5] of TLittleEndianCase = ((bytes: ($78, $56, $34, $12); value: $12345678),
    (bytes: ($F0, $DE, $BC, $9A); value: integer($9ABCDEF0)), (bytes: ($FF, $00, $00, $00); value: 255),
    (bytes: ($FF, $FF, $00, $00); value: 65535), (bytes: ($4E, $61, $BC, $00); value: 12345678),
    (bytes: ($B2, $9E, $43, $FF); value: - 12345678));
var
  i, j: integer;
  t: TLittleEndianCase;
  pb: TProtoBufInput;
  buf: AnsiString;
  int: integer;
begin
  for i := 0 to 5 do
    begin
      t := LittleEndianCases[i];
      SetLength(buf, 4);
      for j := 1 to 4 do
        buf[j] := AnsiChar(t.bytes[j]);
      pb := TProtoBufInput.Create(@buf[1], 4);
      try
        int := pb.readRawLittleEndian32;
        CheckEquals(t.value, int, 'Test readRawLittleEndian32 fails');
      finally
        pb.Free;
      end;
    end;
end;

procedure TestProtoBufMethods.TestReadLittleEndian64;
type
  TLittleEndianCase = record
    bytes: array [1 .. 8] of byte; // Encoded bytes.
    value: Int64; // Parsed value.
  end;
const
  LittleEndianCases: array [0 .. 3] of TLittleEndianCase = ((bytes: ($67, $45, $23, $01, $78, $56, $34, $12);
    value: $1234567801234567), (bytes: ($F0, $DE, $BC, $9A, $78, $56, $34, $12); value: $123456789ABCDEF0),
    (bytes: ($79, $DF, $0D, $86, $48, $70, $00, $00); value: 123456789012345),
    (bytes: ($87, $20, $F2, $79, $B7, $8F, $FF, $FF); value: - 123456789012345));
var
  i, j: integer;
  t: TLittleEndianCase;
  pb: TProtoBufInput;
  buf: AnsiString;
  int: Int64;
begin
  for i := 0 to 3 do
    begin
      t := LittleEndianCases[i];
      SetLength(buf, 8);
      for j := 1 to 8 do
        buf[j] := AnsiChar(t.bytes[j]);
      pb := TProtoBufInput.Create(@buf[1], 8);
      try
        int := pb.readRawLittleEndian64;
        CheckEquals(t.value, int, 'Test readRawLittleEndian64 fails');
      finally
        pb.Free;
      end;
    end;
end;

procedure TestProtoBufMethods.TestReadString;
const
  TEST_string:string = 'Òåñòîâàÿ ñòðîêà';
  TEST_integer = 12345678;
  TEST_single = 12345.123;
  TEST_double = 1234567890.123;
var
  out_pb: TProtoBufOutput;
  in_pb: TProtoBufInput;
  tag, t: integer;
  text: string;
  int: integer;
  dbl: double;
  flt: single;
  delta: extended;
begin
  out_pb := TProtoBufOutput.Create;
  out_pb.writeString(1, TEST_string);
  out_pb.writeFixed32(2, TEST_integer);
  out_pb.writeFloat(3, TEST_single);
  out_pb.writeDouble(4, TEST_double);
  out_pb.SaveToFile('test.dmp');

  in_pb := TProtoBufInput.Create();
  in_pb.LoadFromFile('test.dmp');
  // TEST_string
  tag := makeTag(1, WIRETYPE_LENGTH_DELIMITED);
  t := in_pb.readTag;
  CheckEquals(tag, t);
  text := in_pb.readString;
  CheckEquals(TEST_string, text);
  // TEST_integer
  tag := makeTag(2, WIRETYPE_FIXED32);
  t := in_pb.readTag;
  CheckEquals(tag, t);
  int := in_pb.readFixed32;
  CheckEquals(TEST_integer, int);
  // TEST_single
  tag := makeTag(3, WIRETYPE_FIXED32);
  t := in_pb.readTag;
  CheckEquals(tag, t);
  flt := in_pb.readFloat;
  delta := TEST_single - flt;
  CheckTrue(abs(delta) < 0.001);
  // TEST_double
  tag := makeTag(4, WIRETYPE_FIXED64);
  t := in_pb.readTag;
  CheckEquals(tag, t);
  dbl := in_pb.readDouble;
  {$OVERFLOWCHECKS ON}
  delta := dbl - TEST_double;
  CheckTrue(abs(delta) < 0.000001);
end;

procedure TestProtoBufMethods.TestReadTag;
var
  out_pb: TProtoBufOutput;
  in_pb: TProtoBufInput;
  tag, t: integer;
  tmp: TMemoryStream;
  data_size: integer;
  garbage: Cardinal;
begin
  tmp := TMemoryStream.Create;
  try
    out_pb := TProtoBufOutput.Create;
    try
      out_pb.writeSInt32(1, 150);
      out_pb.SaveToStream(tmp);
    finally
      out_pb.Free;
    end;

    data_size := tmp.Size;
    garbage := $BADBAD;
    tmp.WriteBuffer(garbage, SizeOf(garbage));

    in_pb := TProtoBufInput.Create(tmp.Memory, data_size);
    try
      tag := makeTag(1, WIRETYPE_VARINT);
      t := in_pb.readTag;
      CheckEquals(tag, t);
      CheckEquals(150, in_pb.readSInt32);
      CheckEquals(0, in_pb.readTag);
    finally
      in_pb.Free;
    end;
  finally
    tmp.Free;
  end;
end;

procedure TestProtoBufMethods.TestVarint;
type
  TVarintCase = record
    bytes: array [1 .. 10] of byte; // Encoded bytes.
    Size: integer; // Encoded size, in bytes.
    value: Int64; // Parsed value.
  end;
const
  VarintCases: array [0 .. 7] of TVarintCase = (
    // 32-bit values
    (bytes: ($00, $00, $00, $00, $00, $00, $00, $00, $00, $00); Size: 1; value: 0),
    (bytes: ($01, $00, $00, $00, $00, $00, $00, $00, $00, $00); Size: 1; value: 1),
    (bytes: ($7F, $00, $00, $00, $00, $00, $00, $00, $00, $00); Size: 1; value: 127),
    (bytes: ($A2, $74, $00, $00, $00, $00, $00, $00, $00, $00); Size: 2; value: 14882),
    (bytes: ($FF, $FF, $FF, $FF, $0F, $00, $00, $00, $00, $00); Size: 5; value: - 1),
    // 64-bit
    (bytes: ($BE, $F7, $92, $84, $0B, $00, $00, $00, $00, $00); Size: 5; value: 2961488830),
    (bytes: ($BE, $F7, $92, $84, $1B, $00, $00, $00, $00, $00); Size: 5; value: 7256456126),
    (bytes: ($80, $E6, $EB, $9C, $C3, $C9, $A4, $49, $00, $00); Size: 8; value: 41256202580718336));
var
  i, j: integer;
  t: TVarintCase;
  pb: TProtoBufInput;
  buf: AnsiString;
  i64: Int64;
  int: integer;
begin
  for i := 0 to 7 do
    begin
      t := VarintCases[i];
      // 耦玟囹?蝈耱钼 狍翦?
      SetLength(buf, t.Size);
      for j := 1 to t.Size do
        buf[j] := AnsiChar(t.bytes[j]);
      pb := TProtoBufInput.Create(@buf[1], t.Size);
      try
        if i < 5 then
          begin
            int := pb.readRawVarint32;
            CheckEquals(t.value, int, 'Test Varint fails');
          end
        else
          begin
            i64 := pb.readRawVarint64;
            CheckEquals(t.value, i64, 'Test Varint fails');
          end;
      finally
        pb.Free;
      end;
    end;
end;

initialization

// Register any test cases with the test runner
RegisterTest(TestProtoBufMethods.Suite);

end.
