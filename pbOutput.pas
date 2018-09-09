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
    (* Write the data with specified size. *)
    procedure writeRawData(const p: Pointer; size: integer); overload;
    procedure writeRawData(const buf; size: integer); overload;

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
    procedure writeRawBoolean(value: Boolean);
    procedure writeBoolean(fieldNumber: integer; value: Boolean);
    (* Write a string field, including tag. *)
    procedure writeString(fieldNumber: integer; const value: string);
    { * Write a bytes field, including tag. * }
    procedure writeBytes(fieldNumber: integer; const value: TBytes);
    (* Write a message field, including tag. *)
    procedure writeMessage(fieldNumber: integer; const value: IpbMessage);
    (* Write a unsigned int32 field, including tag. *)
    procedure writeUInt32(fieldNumber: integer; value: cardinal);

    procedure writeRawSInt32(value: integer);
    procedure writeRawSInt64(value: int64);
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

procedure TProtoBufOutput.writeRawBoolean(value: Boolean);
var
  b: ShortInt;
begin
  b := ord(value);
  writeRawData(b, SizeOf(Byte));
end;

procedure TProtoBufOutput.writeRawData(const buf; size: integer);
begin
  writeRawData(@buf, size);
end;

procedure TProtoBufOutput.writeRawSInt32(value: integer);
begin
  writeRawVarint32(EncodeZigZag32(value));
end;

procedure TProtoBufOutput.writeRawSInt64(value: int64);
begin
  writeRawVarint64(EncodeZigZag64(value));
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
  b: ShortInt;
begin
  repeat
    b := value and $7F;
    value := value shr 7;
    if value <> 0 then
      b := b + $80;
    writeRawData(b, SizeOf(ShortInt));
  until value = 0;
end;

procedure TProtoBufOutput.writeRawVarint64(value: int64);
var
  b: ShortInt;
begin
  repeat
    b := value and $7F;
    value := value shr 7;
    if value <> 0 then
      b := b + $80;
    writeRawData(b, SizeOf(ShortInt));
  until value = 0;
end;

procedure TProtoBufOutput.writeBoolean(fieldNumber: integer; value: Boolean);
begin
  writeTag(fieldNumber, WIRETYPE_VARINT);
  writeRawBoolean(value);
end;

procedure TProtoBufOutput.writeBytes(fieldNumber: integer; const value: TBytes);
begin
  writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
  writeRawVarint32(length(value));
  if length(value) > 0 then
    writeRawData(value[0], length(value));
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
  writeRawSInt32(value);
end;

procedure TProtoBufOutput.writeSInt64(fieldNumber: integer; value: int64);
begin
  writeTag(fieldNumber, WIRETYPE_VARINT);
  writeRawSInt64(value);
end;

procedure TProtoBufOutput.writeString(fieldNumber: integer; const value: string);
var
  buf: TBytes;
begin
  writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
  buf := TEncoding.UTF8.GetBytes(value);
  writeRawVarint32(length(buf));
  if length(buf) > 0 then
    writeRawData(buf[0], length(buf));
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
