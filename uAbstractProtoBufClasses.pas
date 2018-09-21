unit uAbstractProtoBufClasses;

interface

uses
  Windows,
  SysUtils,
  Classes,
  System.Generics.Collections,
  pbInput,
  pbOutput;

type
  TAbstractProtoBuf = class(TObject)
  strict private
  type
    TRequiredFields = TDictionary<integer, Boolean>;
  strict private
    FRequiredFields: TRequiredFields;
  strict protected
    procedure AddLoadedField(Tag: integer);
    procedure RegisterRequiredField(Tag: integer);
    function IsAllRequiredLoaded: Boolean;

    procedure BeforeLoad; virtual;
    procedure AfterLoad; virtual;

    function LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: integer; WireType: integer): Boolean; virtual;
    procedure SaveFieldsToBuf(ProtoBuf: TProtoBufOutput); virtual; abstract;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Assign(ProtoBuf: TAbstractProtoBuf);

    procedure LoadFromMem(const Mem: Pointer; const Size: Integer; const OwnsMem: Boolean = False);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput);
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput);
  end;

  TProtoBufList<T: TAbstractProtoBuf, constructor> = class(TObjectList<T>)
  public
    function AddFromBuf(ProtoBuf: TProtoBufInput; FieldNum: integer): Boolean; virtual;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput; FieldNumForItems: integer); virtual;
  end;

implementation

uses
  pbPublic;

{ TAbstractProtoBufClass }

procedure TAbstractProtoBuf.AddLoadedField(Tag: integer);
begin
  if FRequiredFields.ContainsKey(Tag) then
    FRequiredFields[Tag] := True;
end;

procedure TAbstractProtoBuf.AfterLoad;
begin

end;

procedure TAbstractProtoBuf.Assign(ProtoBuf: TAbstractProtoBuf);
var
  Stream: TStream;
begin
  Stream := TMemoryStream.Create;
  try
    ProtoBuf.SaveToStream(Stream);
    Stream.Seek(0, soBeginning);
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TAbstractProtoBuf.BeforeLoad;
begin

end;

constructor TAbstractProtoBuf.Create;
begin
  inherited Create;
  FRequiredFields := TRequiredFields.Create;
end;

destructor TAbstractProtoBuf.Destroy;
begin
  FreeAndNil(FRequiredFields);
  inherited;
end;

function TAbstractProtoBuf.IsAllRequiredLoaded: Boolean;
var
  b: Boolean;
begin
  Result := True;
  for b in FRequiredFields.Values do
    if not b then
      begin
        Result := False;
        Break;
      end;
end;

procedure TAbstractProtoBuf.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  FieldNumber: integer;
  Tag: integer;
begin
  BeforeLoad;

  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      FieldNumber := getTagFieldNumber(Tag);
      if not LoadSingleFieldFromBuf(ProtoBuf, FieldNumber, getTagWireType(Tag)) then
        ProtoBuf.skipField(Tag)
      else
        AddLoadedField(FieldNumber);
      Tag := ProtoBuf.readTag;
    end;
  if not IsAllRequiredLoaded then
    raise EStreamError.Create('not enought fields');

  AfterLoad;
end;

procedure TAbstractProtoBuf.LoadFromMem(const Mem: Pointer; const Size: Integer; const OwnsMem: Boolean);
var
  pb: TProtoBufInput;
begin
  pb := TProtoBufInput.Create(Mem, Size, OwnsMem);
  try
    LoadFromBuf(pb);
  finally
    pb.Free;
  end;
end;

procedure TAbstractProtoBuf.LoadFromStream(Stream: TStream);
var
  pb: TProtoBufInput;
  tmpStream: TStream;
begin
  pb := TProtoBufInput.Create;
  try
    tmpStream := TMemoryStream.Create;
    try
      tmpStream.CopyFrom(Stream, Stream.Size - Stream.Position);
      tmpStream.Seek(0, soBeginning);
      pb.LoadFromStream(tmpStream);
    finally
      tmpStream.Free;
    end;
    LoadFromBuf(pb);
  finally
    pb.Free;
  end;
end;

function TAbstractProtoBuf.LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: integer; WireType: integer): Boolean;
begin
  Result := False;
end;

procedure TAbstractProtoBuf.RegisterRequiredField(Tag: integer);
begin
  FRequiredFields.Add(Tag, False);
end;

procedure TAbstractProtoBuf.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  SaveFieldsToBuf(ProtoBuf);
end;

procedure TAbstractProtoBuf.SaveToStream(Stream: TStream);
var
  pb: TProtoBufOutput;
begin
  pb := TProtoBufOutput.Create;
  try
    SaveToBuf(pb);
    pb.SaveToStream(Stream);
  finally
    pb.Free;
  end;
end;

{ TProtoBufList<T> }

function TProtoBufList<T>.AddFromBuf(ProtoBuf: TProtoBufInput; FieldNum: integer): Boolean;
var
  tmpBuf: TProtoBufInput;
  Item: T;
begin
  if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
    begin
      Result := False;
      exit;
    end;

  tmpBuf := ProtoBuf.ReadSubProtoBufInput;
  try
    Item := T.Create;
    try
      Item.LoadFromBuf(tmpBuf);
      Add(Item);
      Item := nil;
    finally
      Item.Free;
    end;
  finally
    tmpBuf.Free;
  end;
  Result := True;
end;

procedure TProtoBufList<T>.SaveToBuf(ProtoBuf: TProtoBufOutput; FieldNumForItems: integer);
var
  i: integer;
  tmpBuf: TProtoBufOutput;
begin
  tmpBuf := TProtoBufOutput.Create;
  try
    for i := 0 to Count - 1 do
      begin
        tmpBuf.Clear;
        Items[i].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

end.
