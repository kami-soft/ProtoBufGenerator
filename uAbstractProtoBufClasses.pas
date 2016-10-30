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
  TAbstractProtoBufClass = class(TObject)
  strict private
  type
    TRequiredFields = TDictionary<integer, Boolean>;
  strict private
    FRequiredFields: TRequiredFields;
  strict protected
    procedure AddLoadedField(Tag: integer);
    procedure RegisterRequiredField(Tag: integer);
    function IsAllRequiredLoaded: Boolean;

    function LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: integer): Boolean; virtual;
    procedure SaveFieldsToBuf(ProtoBuf: TProtoBufOutput); virtual; abstract;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Assign(ProtoBuf: TAbstractProtoBufClass);

    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput);
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput);
  end;

  TProtoBufClassList<T: TAbstractProtoBufClass, constructor> = class(TObjectList<T>)
  public
    procedure AddFromBuf(ProtoBuf: TProtoBufInput; TagValue: integer);
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput; TagValue: integer);
  end;

implementation

uses
  pbPublic;

{ TAbstractProtoBufClass }

procedure TAbstractProtoBufClass.AddLoadedField(Tag: integer);
begin
  if FRequiredFields.ContainsKey(Tag) then
    FRequiredFields[Tag] := True;
end;

procedure TAbstractProtoBufClass.Assign(ProtoBuf: TAbstractProtoBufClass);
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

constructor TAbstractProtoBufClass.Create;
begin
  inherited Create;
  FRequiredFields := TRequiredFields.Create;
end;

destructor TAbstractProtoBufClass.Destroy;
begin
  FreeAndNil(FRequiredFields);
  inherited;
end;

function TAbstractProtoBufClass.IsAllRequiredLoaded: Boolean;
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

procedure TAbstractProtoBufClass.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  FieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      FieldNumber := getTagFieldNumber(Tag);
      if not LoadSingleFieldFromBuf(ProtoBuf, FieldNumber) then
        ProtoBuf.skipField(Tag)
      else
        AddLoadedField(FieldNumber);
      Tag := ProtoBuf.readTag;
    end;
  if not IsAllRequiredLoaded then
    raise EStreamError.Create('not enought fields');
end;

procedure TAbstractProtoBufClass.LoadFromStream(Stream: TStream);
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

function TAbstractProtoBufClass.LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: integer): Boolean;
begin
  Result := False;
end;

procedure TAbstractProtoBufClass.RegisterRequiredField(Tag: integer);
begin
  FRequiredFields.Add(Tag, False);
end;

procedure TAbstractProtoBufClass.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  SaveFieldsToBuf(ProtoBuf);
end;

procedure TAbstractProtoBufClass.SaveToStream(Stream: TStream);
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

procedure TProtoBufClassList<T>.AddFromBuf(ProtoBuf: TProtoBufInput; TagValue: integer);
var
  tmpBuf: TProtoBufInput;
  Item: T;
begin
  ProtoBuf.checkLastTagWas(TagValue);
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
end;

procedure TProtoBufClassList<T>.SaveToBuf(ProtoBuf: TProtoBufOutput; TagValue: integer);
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
        ProtoBuf.writeMessage(TagValue, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

end.
