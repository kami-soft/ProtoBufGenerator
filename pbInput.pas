// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// author this port to delphi - Marat Shaymardanov, Tomsk 2007, 2013
//
// You can freely use this code in any project
// if sending any postcards with postage stamp to my address:
// Frunze 131/1, 56, Russia, Tomsk, 634021

unit pbInput;

interface

uses
  Classes,
  SysUtils,
  pbPublic;

type

  TProtoBufInput = class;

  IExtensionRegistry = interface
    ['{B08BC625-245E-4C25-98DD-98859B951CC7}']

  end;

  IBuilder = interface
    ['{98E70F9E-9236-48B2-A6BB-6468150B3A58}']
    procedure mergeFrom(input: TProtoBufInput; extReg: IExtensionRegistry);
  end;

  // Reads and decodes protocol message fields.
  TProtoBufInput = class
  private
    FBuffer: PAnsiChar;
    FPos: integer;
    FLen: integer;
    FSizeLimit: integer;
    FRecursionDepth: integer;
    FLastTag: integer;
    FOwnObject: boolean;
  public
    constructor Create; overload;
    constructor Create(buf: PAnsiChar; len: integer; aOwnsObjects: boolean = false); overload;
    destructor Destroy; override;
    // I/O routines to file and stream
    procedure SaveToStream(Stream: TStream);
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    // Set buffer posititon
    procedure setPos(aPos: integer);
    // Get buffer posititon
    function getPos: integer;
    // Attempt to read a field tag, returning zero if we have reached EOF.
    function readTag: integer;
    // Check whether the latter match the value read tag.
    // Used to test for nested groups.
    procedure checkLastTagWas(value: integer);
    // Reads and discards a single field, given its tag value.
    function skipField(tag: integer): boolean;
    // Reads and discards an entire message.
    procedure skipMessage;
    // Read a double field value
    function readDouble: double;
    // Read a float field value
    function readFloat: single;
    // Read an int64 field value
    function readInt64: int64;
    // Read an int32 field value
    function readInt32: integer;
    // Read a fixed64 field value
    function readFixed64: int64;
    // Read a fixed32 field value
    function readFixed32: integer;

    function readRawBoolean: boolean;
    // Read a boolean field value
    function readBoolean: boolean;
    // Read a AnsiString field value
    function readString: string;
    // read bytes field value
    function readBytes: TBytes;
    // Read nested message
    procedure readMessage(builder: IBuilder; extensionRegistry: IExtensionRegistry);
    // Read a uint32 field value
    function readUInt32: integer;
    // Read a enum field value
    function readEnum: integer;
    // Read an sfixed32 field value
    function readSFixed32: integer;
    // Read an sfixed64 field value
    function readSFixed64: int64;
    // Read an sint32 field value
    function readSInt32: integer;
    // Read an sint64 field value
    function readSInt64: int64;
    // Read a raw Varint from the stream. If larger than 32 bits, discard the upper bits
    function readRawVarint32: integer;
    // Read a raw Varint
    function readRawVarint64: int64;
    // Read a 32-bit little-endian integer
    function readRawLittleEndian32: integer;
    // Read a 64-bit little-endian integer
    function readRawLittleEndian64: int64;
    // Read one byte
    function readRawByte: shortint;
    // Read "size" bytes
    procedure readRawBytes(var data; size: integer);
    // Skip "size" bytes
    procedure skipRawBytes(size: integer);

    function ReadSubProtoBufInput: TProtoBufInput;

    property BufSize: integer read FLen;
    property LastTag: integer read FLastTag;
  end;

function decodeZigZag32(n: integer): integer;
function decodeZigZag64(n: int64): int64;

implementation

const
  ProtoBufException = 'Protocol buffer exception: ';
  DEFAULT_RECURSION_LIMIT = 64;
  DEFAULT_SIZE_LIMIT = 64 shl 20; // 64MB

function decodeZigZag32(n: integer): integer;
begin
  result := (n shr 1) xor -(n and 1);
end;

function decodeZigZag64(n: int64): int64;
begin
  result := (n shr 1) xor -(n and 1);
end;

{ TProtoBufInput }

constructor TProtoBufInput.Create;
begin
  inherited Create;
  FPos := 0;
  FLen := 256;
  GetMem(FBuffer, FLen);
  FSizeLimit := DEFAULT_SIZE_LIMIT;
  FRecursionDepth := DEFAULT_RECURSION_LIMIT;
  FOwnObject := true;
end;

constructor TProtoBufInput.Create(buf: PAnsiChar; len: integer; aOwnsObjects: boolean);
begin
  inherited Create;
  if not aOwnsObjects then
    FBuffer := buf
  else
    begin
      // allocate a buffer and copy the data
      FBuffer := AllocMem(len + 1);
      Move(buf^, FBuffer^, len);
    end;
  FPos := 0;
  FLen := len;
  FSizeLimit := DEFAULT_SIZE_LIMIT;
  FRecursionDepth := DEFAULT_RECURSION_LIMIT;
  FOwnObject := aOwnsObjects;
end;

destructor TProtoBufInput.Destroy;
begin
  if FOwnObject then
    FreeMem(FBuffer, FLen);
  inherited Destroy;
end;

function TProtoBufInput.readTag: integer;
begin
  if FPos < FLen then
    FLastTag := readRawVarint32
  else
    FLastTag := 0;
  result := FLastTag;
end;

procedure TProtoBufInput.checkLastTagWas(value: integer);
begin
  Assert(FLastTag = value, ProtoBufException + 'invalid end tag');
end;

function TProtoBufInput.skipField(tag: integer): boolean;
begin
  result := true;
  case getTagWireType(tag) of
    WIRETYPE_VARINT:
      readInt32;
    WIRETYPE_FIXED64:
      readRawLittleEndian64;
    WIRETYPE_LENGTH_DELIMITED:
      skipRawBytes(readRawVarint32());
    WIRETYPE_FIXED32:
      readRawLittleEndian32();
  else
    raise Exception.Create('InvalidProtocolBufferException.invalidWireType');
  end;
end;

procedure TProtoBufInput.skipMessage;
var
  tag: integer;
begin
  repeat
    tag := readTag();
  until (tag = 0) or (not skipField(tag));
end;

function TProtoBufInput.readDouble: double;
begin
  readRawBytes(result, SizeOf(double));
end;

function TProtoBufInput.readFloat: single;
begin
  readRawBytes(result, SizeOf(single));
end;

function TProtoBufInput.readInt64: int64;
begin
  result := readRawVarint64;
end;

function TProtoBufInput.readInt32: integer;
begin
  result := readRawVarint32;
end;

function TProtoBufInput.readFixed64: int64;
begin
  result := readRawLittleEndian64;
end;

function TProtoBufInput.readFixed32: integer;
begin
  result := readRawLittleEndian32;
end;

function TProtoBufInput.readBoolean: boolean;
begin
  result := readRawBoolean;
end;

function TProtoBufInput.readBytes: TBytes;
var
  size: integer;
begin
  size := readRawVarint32;
  Assert(size >= 0, ProtoBufException + 'readBytes (size < 0)');
  SetLength(result, size);
  if size > 0 then
    Move(Pointer(FBuffer + FPos)^, result[0], size);
  Inc(FPos, size);
end;

function TProtoBufInput.readString: string;
var
  size: integer;
  buf: TBytes;
begin
  size := readRawVarint32;
  Assert(size >= 0, ProtoBufException + 'readString (size < 0)');
  if size > 0 then
    begin
      SetLength(buf, size);
      Move(Pointer(FBuffer + FPos)^, buf[0], size);
      result := TEncoding.UTF8.GetString(buf);
    end
  else
    result := '';
  Inc(FPos, size);
end;

function TProtoBufInput.ReadSubProtoBufInput: TProtoBufInput;
var
  BufSize: integer;
  buf: Pointer;
begin
  BufSize := readInt32;
  buf := AllocMem(BufSize);
  try
    readRawBytes(buf^, BufSize);
    result := TProtoBufInput.Create(buf, BufSize, true);
  finally
    FreeMem(buf);
  end;
end;

procedure TProtoBufInput.readMessage(builder: IBuilder; extensionRegistry: IExtensionRegistry);
begin
  readRawVarint32;
  Assert(FRecursionDepth < RecursionLimit, ProtoBufException + 'recursion Limit Exceeded');
  Inc(FRecursionDepth);
  builder.mergeFrom(Self, extensionRegistry);
  checkLastTagWas(0);
  dec(FRecursionDepth);
end;

function TProtoBufInput.readUInt32: integer;
begin
  result := readRawVarint32;
end;

function TProtoBufInput.readEnum: integer;
begin
  result := readRawVarint32;
end;

function TProtoBufInput.readSFixed32: integer;
begin
  result := readRawLittleEndian32;
end;

function TProtoBufInput.readSFixed64: int64;
begin
  result := readRawLittleEndian64;
end;

function TProtoBufInput.readSInt32: integer;
begin
  result := decodeZigZag32(readRawVarint32);
end;

function TProtoBufInput.readSInt64: int64;
begin
  result := decodeZigZag64(readRawVarint64());
end;

function TProtoBufInput.readRawVarint32: integer;
var
  tmp: shortint;
  shift: integer;
begin
  shift := -7;
  result := 0;
  repeat
    Inc(shift, 7);
    // for negative numbers number value may be to 10 byte
    Assert(shift < 64, ProtoBufException + 'malformed Varint');
    tmp := readRawByte;
    result := result or ((tmp and $7F) shl shift);
  until tmp >= 0;
end;

function TProtoBufInput.readRawVarint64: int64;
var
  tmp: shortint;
  shift: integer;
  i64: int64;
begin
  shift := -7;
  result := 0;
  repeat
    Inc(shift, 7);
    Assert(shift < 64, ProtoBufException + 'malformed Varint');
    tmp := readRawByte;
    i64 := tmp and $7F;
    i64 := i64 shl shift;
    result := result or i64;
  until tmp >= 0;
end;

function TProtoBufInput.readRawLittleEndian32: integer;
begin
  readRawBytes(result, SizeOf(result));
end;

function TProtoBufInput.readRawLittleEndian64: int64;
begin
  readRawBytes(result, SizeOf(result));
end;

function TProtoBufInput.readRawBoolean: boolean;
begin
  result := readRawVarint32 <> 0;
end;

function TProtoBufInput.readRawByte: shortint;
begin
  Assert(FPos <= FLen, ProtoBufException + 'eof encounterd');
  result := shortint(FBuffer[FPos]);
  Inc(FPos);
end;

procedure TProtoBufInput.readRawBytes(var data; size: integer);
begin
  Assert(FPos + size <= FLen, ProtoBufException + 'eof encounterd');
  Move(FBuffer[FPos], data, size);
  Inc(FPos, size);
end;

procedure TProtoBufInput.skipRawBytes(size: integer);
begin
  Assert(size >= 0, ProtoBufException + 'negative Size');
  Assert((FPos + size) < FLen, ProtoBufException + 'truncated Message');
  Inc(FPos, size);
end;

procedure TProtoBufInput.SaveToFile(const FileName: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TProtoBufInput.SaveToStream(Stream: TStream);
begin
  Stream.WriteBuffer(Pointer(FBuffer)^, FLen);
end;

procedure TProtoBufInput.LoadFromFile(const FileName: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TProtoBufInput.LoadFromStream(Stream: TStream);
begin
  if FOwnObject then
    begin
      FreeMem(FBuffer, FLen);
      FBuffer := nil;
    end;
  FOwnObject := true;
  FLen := Stream.size;
  FBuffer := AllocMem(FLen + 1);
  Stream.Position := 0;
  Stream.Read(Pointer(FBuffer)^, FLen);
end;

procedure TProtoBufInput.setPos(aPos: integer);
begin
  FPos := aPos;
end;

function TProtoBufInput.getPos: integer;
begin
  result := FPos;
end;

end.
