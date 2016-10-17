unit uProtoBufParserClasses;

interface

uses
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections,
  uProtoBufParserAbstractClasses;

type
  TPropKind = ( //
    ptDefaultRequired, //
    ptRequired, //
    ptOptional, //
    ptRepeated, //
    ptReserved);

  TScalarPropertyType = ( //
    sptComplex, //
    sptDouble, //
    sptFloat, //
    sptInt32, //
    sptInt64, //
    sptuInt32, //
    sptUint64, //
    sptSInt32, //
    sptSInt64, //
    sptFixed32, //
    sptFixed64, //
    sptSFixed32, //
    sptSFixed64, //
    sptBool, //
    sptString, //
    sptBytes);

  TProtoBufPropOption = class(TAbstractProtoBufParserItem)
  private
    FOptionValue: string;
  public
    procedure ParseFromProto(const Proto: string; var iPos: integer); override;
    property OptionValue: string read FOptionValue;
  end;

  TProtoBufPropOptions = class(TAbstractProtoBufParserContainer<TProtoBufPropOption>)
  private
    function GetHasValue(const OptionName: string): Boolean;
    function GetValue(const OptionName: string): string;
  public
    procedure ParseFromProto(const Proto: string; var iPos: integer); override;
    property HasValue[const OptionName: string]: Boolean read GetHasValue;
    property Value[const OptionName: string]: string read GetValue;
  end;

  TProtoBufProperty = class(TAbstractProtoBufParserItem)
  strict private
    FPropTag: integer;
    FPropType: string;
    FPropKind: TPropKind;
    FPropComment: string;
    FPropOptions: TProtoBufPropOptions;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure ParseFromProto(const Proto: string; var iPos: integer); override;

    property PropKind: TPropKind read FPropKind;
    property PropType: string read FPropType;
    property PropTag: integer read FPropTag;
    property PropComment: string read FPropComment;
    property PropOptions: TProtoBufPropOptions read FPropOptions;
  end;

  TProtoBufEnumValue = class(TAbstractProtoBufParserItem)
  strict private
    FValue: integer;
  public
    procedure ParseFromProto(const Proto: string; var iPos: integer); override;

    property Value: integer read FValue;
  end;

  TProtoBufEnum = class(TAbstractProtoBufParserContainer<TProtoBufEnumValue>)
  public
    procedure ParseFromProto(const Proto: string; var iPos: integer); override;
  end;

  TProtoBufMessage = class(TAbstractProtoBufParserContainer<TProtoBufProperty>)
  public
    procedure ParseFromProto(const Proto: string; var iPos: integer); override;
  end;

  TProtoBufEnumList = class(TObjectList<TProtoBufEnum>)
  public
    function FindByName(const EnumName: string): TProtoBufEnum;
  end;

  TProtoBufMessageList = class(TObjectList<TProtoBufMessage>)
  public
    function FindByName(const MessageName: string): TProtoBufMessage;
  end;

  TProtoFile = class(TAbstractProtoBufParserItem)
  private
    FProtoBufMessages: TProtoBufMessageList;
    FProtoBufEnums: TProtoBufEnumList;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure ParseFromProto(const Proto: string; var iPos: integer); override;

    property ProtoBufEnums: TProtoBufEnumList read FProtoBufEnums;
    property ProtoBufMessages: TProtoBufMessageList read FProtoBufMessages;
  end;

function StrToPropertyType(const AStr: string): TScalarPropertyType;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Character;

function PropKindToStr(APropKind: TPropKind): string;
begin
  case APropKind of
    ptDefaultRequired:
      Result := '';
    ptRequired:
      Result := 'required';
    ptOptional:
      Result := 'optional';
    ptRepeated:
      Result := 'repeated';
    ptReserved:
      Result := 'reserved';
  end;
end;

function StrToPropKind(const AStr: string): TPropKind;
var
  i: TPropKind;
begin
  Result := Low(TPropKind);
  for i := Low(TPropKind) to High(TPropKind) do
    if SameStr(PropKindToStr(i), AStr) then
      begin
        Result := i;
        Break;
      end;
end;

function PropertyTypeToStr(PropType: TScalarPropertyType): string;
begin
  Result := '';
  case PropType of
    sptComplex:
      ;
    sptDouble:
      Result := 'double';
    sptFloat:
      Result := 'float';
    sptInt32:
      Result := 'int32';
    sptInt64:
      Result := 'int64';
    sptuInt32:
      Result := 'uint32';
    sptUint64:
      Result := 'uint64';
    sptSInt32:
      Result := 'sint32';
    sptSInt64:
      Result := 'sint64';
    sptFixed32:
      Result := 'fixed32';
    sptFixed64:
      Result := 'fixed64';
    sptSFixed32:
      Result := 'sfixed32';
    sptSFixed64:
      Result := 'sfixed64';
    sptBool:
      Result := 'bool';
    sptString:
      Result := 'string';
    sptBytes:
      Result := 'bytes';
  end;
end;

function StrToPropertyType(const AStr: string): TScalarPropertyType;
var
  i: TScalarPropertyType;
begin
  Result := Low(TScalarPropertyType);
  for i := Low(TScalarPropertyType) to High(TScalarPropertyType) do
    if SameStr(PropertyTypeToStr(i), AStr) then
      begin
        Result := i;
        Break;
      end;
end;

{ TProtoBufProperty }

constructor TProtoBufProperty.Create;
begin
  inherited;
  FPropOptions := TProtoBufPropOptions.Create;
end;

destructor TProtoBufProperty.Destroy;
begin
  FreeAndNil(FPropOptions);
  inherited;
end;

procedure SkipWhitespaces(const Proto: string; var iPos: integer);
begin
  while Proto[iPos].IsWhiteSpace and (iPos <= Length(Proto)) do
    Inc(iPos);
end;

function ReadAllTillChar(const Proto: string; var iPos: integer; BreakSymbol: array of Char): string;
begin
  Result := '';
  while not Proto[iPos].IsInArray(BreakSymbol) and (iPos <= Length(Proto)) do
    begin
      Result := Result + Proto[iPos];
      Inc(iPos);
    end;
end;

function ReadAllToEOL(const Proto: string; var iPos: integer): string;
begin
  Result := ReadAllTillChar(Proto, iPos, [#13, #10]);
end;

function ReadCommentIfExists(const Proto: string; var iPos: integer): string;
begin
  SkipWhitespaces(Proto, iPos);
  if (Proto[iPos] = '/') and (Proto[iPos + 1] = '/') then
    begin
      Inc(iPos, 2);
      Result := ReadAllToEOL(Proto, iPos);
    end
  else
    Result := '';
end;

procedure SkipAllComments(const Proto: string; var iPos: integer);
begin
  while ReadCommentIfExists(Proto, iPos) <> '' do;
  SkipWhitespaces(Proto, iPos);
end;

procedure SkipRequiredChar(const Proto: string; var iPos: integer; const RequiredChar: Char);
begin
  SkipWhitespaces(Proto, iPos);
  if Proto[iPos] <> RequiredChar then
    raise EParserError.Create(RequiredChar + ' not found in ProtoBuf');
  Inc(iPos);
end;

function ReadWordFromBuf(const Proto: string; var iPos: integer; BreakSymbols: array of Char): string;
begin
  SkipWhitespaces(Proto, iPos);

  Result := '';
  while not Proto[iPos].IsWhiteSpace and not Proto[iPos].IsInArray(BreakSymbols) and (iPos <= Length(Proto)) do
    begin
      Result := Result + Proto[iPos];
      Inc(iPos);
    end;
end;

procedure TProtoBufProperty.ParseFromProto(const Proto: string; var iPos: integer);
var
  Buf: string;
begin
  inherited;
  FPropOptions.Clear;
  {
    [optional] int32   DefField1  = 1  [default = 2]; // def field 1, default value 2
    int64 DefField2 = 2;
  }
  Buf := ReadWordFromBuf(Proto, iPos, []);
  // in Buf - first word of property. Choose type
  FPropKind := StrToPropKind(Buf);
  if FPropKind = ptReserved then
    begin
      ReadAllTillChar(Proto, iPos, [';']);
      SkipRequiredChar(Proto, iPos, ';');
      exit; // reserved is not supported now by this parser
    end;
  if FPropKind <> ptDefaultRequired then // if required/optional/repeated is not skipped,
    Buf := ReadWordFromBuf(Proto, iPos, []); // read type of property

  FPropType := Buf;

  FName := ReadWordFromBuf(Proto, iPos, ['=']);

  // skip '=' character
  SkipRequiredChar(Proto, iPos, '=');

  // read property tag
  Buf := ReadWordFromBuf(Proto, iPos, [';', '[']);
  FPropTag := StrToInt(Buf);

  SkipWhitespaces(Proto, iPos);
  if Proto[iPos] = '[' then
    FPropOptions.ParseFromProto(Proto, iPos);

  // read separator
  SkipRequiredChar(Proto, iPos, ';');

  FPropComment := ReadCommentIfExists(Proto, iPos);
end;

{ TProtoBufPropOption }

procedure TProtoBufPropOption.ParseFromProto(const Proto: string; var iPos: integer);
begin
  inherited;
  { [default = Val2, packed = true]; }
  SkipWhitespaces(Proto, iPos);
  FName := ReadWordFromBuf(Proto, iPos, ['=']);

  // skip '=' character
  SkipRequiredChar(Proto, iPos, '=');

  SkipWhitespaces(Proto, iPos);
  if Proto[iPos] <> '"' then
    FOptionValue := ReadWordFromBuf(Proto, iPos, [',', ']'])
  else
    begin
      Inc(iPos);
      { TODO : Solve problem with double "" in the middle of string... }
      FOptionValue := '"' + ReadAllTillChar(Proto, iPos, ['"']) + '"';
      SkipRequiredChar(Proto, iPos, '"');
    end;

  SkipWhitespaces(Proto, iPos);
  if Proto[iPos] = ',' then
    Inc(iPos);
end;

{ TProtoBufPropOptions }

function TProtoBufPropOptions.GetHasValue(const OptionName: string): Boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to Count - 1 do
    if Items[i].Name = OptionName then
      begin
        Result := True;
        Break;
      end;
end;

function TProtoBufPropOptions.GetValue(const OptionName: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to Count - 1 do
    if Items[i].Name = OptionName then
      begin
        Result := Items[i].OptionValue;
        Break;
      end;
end;

procedure TProtoBufPropOptions.ParseFromProto(const Proto: string; var iPos: integer);
var
  Option: TProtoBufPropOption;
begin
  inherited;
  SkipRequiredChar(Proto, iPos, '[');
  SkipWhitespaces(Proto, iPos); // check for empty options
  while Proto[iPos] <> ']' do
    begin
      Option := TProtoBufPropOption.Create;
      try
        Option.ParseFromProto(Proto, iPos);
        Add(Option);
        Option := nil;
        SkipWhitespaces(Proto, iPos);
      finally
        Option.Free;
      end;
    end;
  SkipRequiredChar(Proto, iPos, ']');
end;

{ TProtoBufEnumValue }

procedure TProtoBufEnumValue.ParseFromProto(const Proto: string; var iPos: integer);
begin
  inherited;
  { Val1 = 1; }
  FName := ReadWordFromBuf(Proto, iPos, ['=']);
  SkipRequiredChar(Proto, iPos, '=');
  FValue := StrToInt(ReadWordFromBuf(Proto, iPos, [';']));
  SkipRequiredChar(Proto, iPos, ';');
end;

{ TProtoBufEnum }

procedure TProtoBufEnum.ParseFromProto(const Proto: string; var iPos: integer);
var
  Item: TProtoBufEnumValue;
begin
  inherited;
  (* Enum1 {
    Val1 = 1;
    Val2 = 2;
    } *)

  FName := ReadWordFromBuf(Proto, iPos, ['{']);
  SkipRequiredChar(Proto, iPos, '{');
  SkipAllComments(Proto, iPos);
  while Proto[iPos] <> '}' do
    begin
      Item := TProtoBufEnumValue.Create;
      try
        Item.ParseFromProto(Proto, iPos);
        Add(Item);
        Item := nil;
        SkipAllComments(Proto, iPos);
      finally
        Item.Free;
      end;
    end;
  SkipRequiredChar(Proto, iPos, '}');

  Sort(TComparer<TProtoBufEnumValue>.Construct(
    function(const Left, Right: TProtoBufEnumValue): integer
    begin
      Result := Left.Value - Right.Value;
    end));
end;

{ TProtoBufMessage }

procedure TProtoBufMessage.ParseFromProto(const Proto: string; var iPos: integer);
var
  Item: TProtoBufProperty;
begin
  inherited;
  (*
    TestMsg0 {
    required int32 Field1 = 1;
    required int64 Field2 = 2;
    }
  *)

  FName := ReadWordFromBuf(Proto, iPos, ['{']);
  SkipRequiredChar(Proto, iPos, '{');
  SkipAllComments(Proto, iPos);
  while Proto[iPos] <> '}' do
    begin
      Item := TProtoBufProperty.Create;
      try
        Item.ParseFromProto(Proto, iPos);
        Add(Item);
        Item := nil;
        SkipAllComments(Proto, iPos);
      finally
        Item.Free;
      end;
    end;
  SkipRequiredChar(Proto, iPos, '}');

  Sort(TComparer<TProtoBufProperty>.Construct(
    function(const Left, Right: TProtoBufProperty): integer
    begin
      Result := Left.PropTag - Right.PropTag;
    end));
end;

{ TProtoFile }

constructor TProtoFile.Create;
begin
  inherited;
  FProtoBufMessages := TProtoBufMessageList.Create;
  FProtoBufEnums := TProtoBufEnumList.Create;
end;

destructor TProtoFile.Destroy;
begin
  FreeAndNil(FProtoBufEnums);
  FreeAndNil(FProtoBufMessages);
  inherited;
end;

procedure TProtoFile.ParseFromProto(const Proto: string; var iPos: integer);
var
  Buf: string;
  Enum: TProtoBufEnum;
  Msg: TProtoBufMessage;
begin
  // need skip comments,
  // parse .proto package name
  SkipAllComments(Proto, iPos);

  while ReadWordFromBuf(Proto, iPos, []) <> 'package' do;

  FName := ReadWordFromBuf(Proto, iPos, [';']);
  SkipRequiredChar(Proto, iPos, ';');

  while iPos < Length(Proto) do
    begin
      SkipAllComments(Proto, iPos);
      Buf := ReadWordFromBuf(Proto, iPos, []);
      if Buf = 'import' then
        begin
          ReadAllTillChar(Proto, iPos, [';']);
          SkipRequiredChar(Proto, iPos, ';');
        end;
      if Buf = 'enum' then
        begin
          Enum := TProtoBufEnum.Create;
          try
            Enum.ParseFromProto(Proto, iPos);
            FProtoBufEnums.Add(Enum);
            Enum := nil;
          finally
            Enum.Free;
          end;
        end;

      if Buf = 'message' then
        begin
          Msg := TProtoBufMessage.Create;
          try
            Msg.ParseFromProto(Proto, iPos);
            FProtoBufMessages.Add(Msg);
            Msg := nil;
          finally
            Msg.Free;
          end;
        end;
    end;
end;

{ TProtoBufMessageList }

function TProtoBufMessageList.FindByName(const MessageName: string): TProtoBufMessage;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
    if Items[i].Name = MessageName then
      begin
        Result := Items[i];
        Break;
      end;
end;

{ TProtoBufEnumList }

function TProtoBufEnumList.FindByName(const EnumName: string): TProtoBufEnum;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
    if Items[i].Name = EnumName then
      begin
        Result := Items[i];
        Break;
      end;
end;

end.
