unit pbOutput;

interface

uses
  Classes,
  SysUtils,
  StrBuffer,
  pbPublic;

type

  TProtoBufOutput = class;

  IpbMessage = interface
    function getSerializedSize: integer;
    procedure writeTo(buffer: TProtoBufOutput);
  end;

  TProtoBufOutput = class(TInterfacedObject, IpbMessage)
  private
    FBuffer: TSegmentBuffer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SaveToStream(Stream: TStream);
    procedure SaveToFile(const FileName: string);
    procedure Clear;

    (* Encode and write varint. *)
    procedure writeRawVarint32(value: integer);
    (* Encode and write varint. *)
    procedure writeRawVarint64(value: int64);
    (* Encode and write tag. *)
    procedure writeTag(fieldNumber: integer; wireType: integer);
    (* Encode and write single byte. *)
    procedure writeRawByte(value: shortint);
    (* Write the data with specified size. *)
    procedure writeRawData(const p: Pointer; size: integer);

    (* Get the result as a string *)
    function GetText: AnsiString;
    (* Write a double field, including tag. *)
    procedure writeDouble(fieldNumber: integer; value: double);
    (* Write a single field, including tag. *)
    procedure writeFloat(fieldNumber: integer; value: single);
    (* Write a int64 field, including tag. *)
    procedure writeInt64(fieldNumber: integer; value: int64);
    (* Write a int64 field, including tag. *)
    procedure writeInt32(fieldNumber: integer; value: integer);
    (* Write a fixed64 field, including tag. *)
    procedure writeFixed64(fieldNumber: integer; value: int64);
    (* Write a fixed32 field, including tag. *)
    procedure writeFixed32(fieldNumber: integer; value: integer);
    (* Write a boolean field, including tag. *)
    procedure writeBoolean(fieldNumber: integer; value: boolean);
    (* Write a string field, including tag. *)
    procedure writeString(fieldNumber: integer; const value: string);
    (* Write a message field, including tag. *)
    procedure writeMessage(fieldNumber: integer; const value: IpbMessage);
    (* Write a unsigned int32 field, including tag. *)
    procedure writeUInt32(fieldNumber: integer; value: cardinal);

    procedure writeSInt32(fieldNumber: integer; value: integer);
    procedure writeSInt64(fieldNumber: integer; value: int64);
    (* Get serialized size *)
    function getSerializedSize: integer;
    (* Write to buffer *)
    procedure writeTo(buffer: TProtoBufOutput);
  end;

function EncodeZigZag32(const A: LongInt): LongWord;
function EncodeZigZag64(const A: int64): UInt64;

implementation

{$R-}

// returns SInt32 encoded to LongWord using 'ZigZag' encoding
function EncodeZigZag32(const A: LongInt): LongWord;
var
  I: int64;
begin
  if A < 0 then
    begin
      // use Int64 value to negate A without overflow
      I := A;
      I := -I;
      // encode ZigZag
      Result := (LongWord(I) - 1) * 2 + 1
    end
  else
    Result := LongWord(A) * 2;
end;

// returns SInt64 encoded to UInt64 using 'ZigZag' encoding
function EncodeZigZag64(const A: int64): UInt64;
var
  I: UInt64;
begin
  if A < 0 then
    begin
      // use two's complement to negate A without overflow
      I := not A;
      Inc(I);
      // encode ZigZag
      Dec(I);
      I := I * 2;
      Inc(I);
      Result := I;
    end
  else
    Result := UInt64(A) * 2;
end;

{ TProtoBuf }

constructor TProtoBufOutput.Create;
begin
  FBuffer := TSegmentBuffer.Create;
  inherited Create;
end;

destructor TProtoBufOutput.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TProtoBufOutput.Clear;
begin
  FBuffer.Clear;
end;

procedure TProtoBufOutput.writeRawByte(value: shortint);
begin
  FBuffer.Add(AnsiChar(value));
end;

procedure TProtoBufOutput.writeRawData(const p: Pointer; size: integer);
begin
  FBuffer.Add(p, size);
end;

procedure TProtoBufOutput.writeTag(fieldNumber, wireType: integer);
begin
  writeRawVarint32(makeTag(fieldNumber, wireType));
end;

procedure TProtoBufOutput.writeRawVarint32(value: integer);
var
  b: shortint;
begin
  repeat
    b := value and $7F;
    value := value shr 7;
    if value <> 0 then
      b := b + $80;
    writeRawByte(b);
  until value = 0;
end;

procedure TProtoBufOutput.writeRawVarint64(value: int64);
var
  b: shortint;
begin
  repeat
    b := value and $7F;
    value := value shr 7;
    if value <> 0 then
      b := b + $80;
    writeRawByte(b);
  until value = 0;
end;

procedure TProtoBufOutput.writeBoolean(fieldNumber: integer; value: boolean);
begin
  writeTag(fieldNumber, WIRETYPE_VARINT);
  writeRawByte(ord(value));
end;

procedure TProtoBufOutput.writeDouble(fieldNumber: integer; value: double);
begin
  writeTag(fieldNumber, WIRETYPE_FIXED64);
  writeRawData(@value, SizeOf(value));
end;

procedure TProtoBufOutput.writeFloat(fieldNumber: integer; value: single);
begin
  writeTag(fieldNumber, WIRETYPE_FIXED32);
  writeRawData(@value, SizeOf(value));
end;

procedure TProtoBufOutput.writeFixed32(fieldNumber, value: integer);
begin
  writeTag(fieldNumber, WIRETYPE_FIXED32);
  writeRawData(@value, SizeOf(value));
end;

procedure TProtoBufOutput.writeFixed64(fieldNumber: integer; value: int64);
begin
  writeTag(fieldNumber, WIRETYPE_FIXED64);
  writeRawData(@value, SizeOf(value));
end;

procedure TProtoBufOutput.writeInt32(fieldNumber, value: integer);
begin
  writeTag(fieldNumber, WIRETYPE_VARINT);
  writeRawVarint32(value);
end;

procedure TProtoBufOutput.writeInt64(fieldNumber: integer; value: int64);
begin
  writeTag(fieldNumber, WIRETYPE_VARINT);
  writeRawVarint64(value);
end;

procedure TProtoBufOutput.writeSInt32(fieldNumber, value: integer);
begin
  writeTag(fieldNumber, WIRETYPE_VARINT);
  writeRawVarint32(EncodeZigZag32(value));
end;

procedure TProtoBufOutput.writeSInt64(fieldNumber: integer; value: int64);
begin
  writeTag(fieldNumber, WIRETYPE_VARINT);
  writeRawVarint64(EncodeZigZag64(value));
end;

procedure TProtoBufOutput.writeString(fieldNumber: integer; const value: string);
var
  Buf: TBytes;
begin
  writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
  Buf := TEncoding.UTF8.GetBytes(value);
  writeRawVarint32(length(Buf));
  if length(Buf) > 0 then
    FBuffer.Add(@Buf[0], length(Buf));
end;

procedure TProtoBufOutput.writeUInt32(fieldNumber: integer; value: cardinal);
begin
  writeTag(fieldNumber, WIRETYPE_VARINT);
  writeRawVarint32(value);
end;

procedure TProtoBufOutput.writeMessage(fieldNumber: integer; const value: IpbMessage);
begin
  writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
  writeRawVarint32(value.getSerializedSize());
  value.writeTo(self);
end;

function TProtoBufOutput.GetText: AnsiString;
begin
  Result := FBuffer.GetText;
end;

procedure TProtoBufOutput.SaveToFile(const FileName: string);
begin
  FBuffer.SaveToFile(FileName);
end;

procedure TProtoBufOutput.SaveToStream(Stream: TStream);
begin
  FBuffer.SaveToStream(Stream);
end;

function TProtoBufOutput.getSerializedSize: integer;
begin
  Result := FBuffer.GetCount;
end;

procedure TProtoBufOutput.writeTo(buffer: TProtoBufOutput);
begin
  buffer.FBuffer.Add(GetText);
end;

end.
