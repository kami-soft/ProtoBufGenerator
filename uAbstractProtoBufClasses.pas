unit uAbstractProtoBufClasses;

interface

uses
  SysUtils,
  Classes,
  {$IFDEF FPC}
  fgl,
  {$ELSE}
  System.Generics.Collections,
  {$ENDIF}
  pbInput,
  pbOutput;

type
  TFieldState = set of (fsRequired, fsHasValue);

  TAbstractProtoBuf = class(TObject)
  strict private
  type
    {$IFDEF FPC}
    TFieldStates = TFPGMap<Integer, TFieldState>;
    {$ELSE}
    TFieldStates = TDictionary<integer, TFieldState>;
    {$ENDIF}
  strict private
    FFieldStates: TFieldStates;
    function GetFieldState(Tag: Integer): TFieldState;
    procedure AddFieldState(Tag: Integer; AFieldState: TFieldState);
    procedure ClearFieldState(Tag: Integer; AFieldState: TFieldState);
    function GetFieldHasValue(Tag: Integer): Boolean;
    procedure SetFieldHasValue(Tag: Integer; const Value: Boolean);
  strict protected
    procedure AddLoadedField(Tag: integer);
    procedure RegisterRequiredField(Tag: integer);

    procedure BeforeLoad; virtual;
    procedure AfterLoad; virtual;

    function LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: integer; WireType: integer): Boolean; virtual;
    procedure SaveFieldsToBuf(ProtoBuf: TProtoBufOutput); virtual;
    procedure SaveMessageFieldToBuf(AField: TAbstractProtoBuf; AFieldNumber: Integer; AFieldProtoBufOutput, AMainProtoBufOutput: TProtoBufOutput);
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Assign(ProtoBuf: TAbstractProtoBuf);

    procedure LoadFromMem(const Mem: Pointer; const Size: Integer; const OwnsMem: Boolean = False);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput);
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput);

    function AllRequiredFieldsValid: Boolean;

    property FieldHasValue[Tag: Integer]: Boolean read GetFieldHasValue write SetFieldHasValue;
  end;

  {$IFDEF FPC}
  TProtoBufList<T: TAbstractProtoBuf> = class(TFPGObjectList<T>)
  {$ELSE}
  TProtoBufList<T: TAbstractProtoBuf, constructor> = class(TObjectList<T>)
  {$ENDIF}
  public
    function AddFromBuf(ProtoBuf: TProtoBufInput; FieldNum: integer): Boolean; virtual;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput; FieldNumForItems: integer); virtual;
  end;

implementation

uses
  pbPublic;

{ TAbstractProtoBuf }

function TAbstractProtoBuf.GetFieldState(Tag: Integer): TFieldState;
{$IFDEF FPC}
var
  idx: Integer;
begin
  if FFieldStates.Find(Tag, idx) then
    Result:= FFieldStates.Data[idx] else
    Result:= [];
{$ELSE}
begin
  Result:= [];
  FFieldStates.TryGetValue(Tag, Result);
{$ENDIF}
end;

procedure TAbstractProtoBuf.AddFieldState(Tag: integer;
  AFieldState: TFieldState);
begin
{$IFDEF FPC}
  FFieldStates[Tag]:= GetFieldState(Tag) + AFieldState;
{$ELSE}
  FFieldStates.AddOrSetValue(Tag, GetFieldState(Tag) + AFieldState);
{$ENDIF}
end;

procedure TAbstractProtoBuf.AddLoadedField(Tag: integer);
begin
  AddFieldState(Tag, [fsHasValue]);
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
{$IFDEF FPC}
var
  i: Integer;
begin
  for i:= 0 to FFieldStates.Count - 1 do
    FFieldStates.Data[i]:= FFieldStates.Data[i] - [fsHasValue];
{$ELSE}
var
  pair: TPair<integer, TFieldState>;
begin
  //clear HasValue flags
  for pair in FFieldStates do
    FFieldStates.Items[pair.Key]:= pair.Value - [fsHasValue];
{$ENDIF}
end;

procedure TAbstractProtoBuf.ClearFieldState(Tag: Integer;
  AFieldState: TFieldState);
begin
{$IFDEF FPC}
  FFieldStates[Tag]:= GetFieldState(Tag);
{$ELSE}
  FFieldStates.AddOrSetValue(Tag, GetFieldState(Tag) - AFieldState);
{$ENDIF}
end;

constructor TAbstractProtoBuf.Create;
begin
  inherited Create;
  FFieldStates:= TFieldStates.Create;
  {$IFDEF FPC}
  FFieldStates.Sorted:= True;
  {$ENDIF}
end;

destructor TAbstractProtoBuf.Destroy;
begin
  FreeAndNil(FFieldStates);
  inherited;
end;

function TAbstractProtoBuf.GetFieldHasValue(Tag: Integer): Boolean;
begin
  Result:= fsHasValue in GetFieldState(Tag);
end;

function TAbstractProtoBuf.AllRequiredFieldsValid: Boolean;
{$IFDEF FPC}
var
  i: Integer;
begin
  Result := True;
  for i:= 0 to FFieldStates.Count - 1 do
    if FFieldStates.Data[i] * [fsRequired, fsHasValue] = [fsRequired] then
      Exit(False);
{$ELSE}
var
  state: TFieldState;
begin
  Result := True;
  for state in FFieldStates.Values do
    if state * [fsRequired, fsHasValue] = [fsRequired] then
    begin
      Result:= False;
      Break;
    end;
{$ENDIF}
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
  if not AllRequiredFieldsValid then
    raise EStreamError.CreateFmt('Loading %s: not all required fields have been loaded', [ClassName]);

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
  AddFieldState(Tag, [fsRequired]);
end;

procedure TAbstractProtoBuf.SaveFieldsToBuf(ProtoBuf: TProtoBufOutput);
begin
  if not AllRequiredFieldsValid then
    raise EStreamError.CreateFmt('Saving %s: not all required fields have been set', [ClassName]);
end;

procedure TAbstractProtoBuf.SaveMessageFieldToBuf(
  AField: TAbstractProtoBuf; AFieldNumber: Integer;
  AFieldProtoBufOutput, AMainProtoBufOutput: TProtoBufOutput);
begin
  AFieldProtoBufOutput.Clear;
  AField.SaveToBuf(AFieldProtoBufOutput);
  AMainProtoBufOutput.writeMessage(AFieldNumber, AFieldProtoBufOutput);
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

procedure TAbstractProtoBuf.SetFieldHasValue(Tag: Integer;
  const Value: Boolean);
begin
  if Value then
    AddFieldState(Tag, [fsHasValue]) else
    ClearFieldState(Tag, [fsHasValue]);
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
