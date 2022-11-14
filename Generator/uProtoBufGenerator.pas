unit uProtoBufGenerator;

interface

uses
  System.SysUtils,
  System.Classes,
  uAbstractProtoBufClasses,
  uProtoBufParserAbstractClasses,
  uProtoBufParserClasses;

type
  TProtoBufGenerator = class(TObject)
  strict private
    procedure GenerateInterfaceSection(Proto: TProtoFile; SL: TStrings);
    procedure GenerateImplementationSection(Proto: TProtoFile; SL: TStrings);
  public
    procedure Generate(Proto: TProtoFile; Output: TStrings); overload;
    procedure Generate(Proto: TProtoFile; OutputStream: TStream; Encoding: TEncoding = nil); overload;
    procedure Generate(Proto: TProtoFile; const OutputDir: string; Encoding: TEncoding = nil); overload;
    procedure Generate(const InputFile: string; const OutputDir: string; Encoding: TEncoding = nil); overload;
  end;

implementation

uses
  System.StrUtils;

function ProtoPropTypeToDelphiType(const PropTypeName: string): string;
var
  StandartType: TScalarPropertyType;
  i: Integer;
begin
  StandartType := StrToPropertyType(PropTypeName);
  case StandartType of
    sptDouble:
      Result := 'Double';
    sptFloat:
      Result := 'Single';
    sptInt32:
      Result := 'Integer';
    sptInt64:
      Result := 'Int64';
    sptuInt32:
      Result := 'Cardinal';
    sptUint64:
      Result := 'UInt64';
    sptSInt32:
      Result := 'Integer';
    sptSInt64:
      Result := 'Int64';
    sptFixed32:
      Result := 'Integer';
    sptFixed64:
      Result := 'Int64';
    sptSFixed32:
      Result := 'Integer';
    sptSFixed64:
      Result := 'Int64';
    sptBool:
      Result := 'Boolean';
    sptString:
      Result := 'string';
    sptBytes:
      Result := 'TBytes';
  else
    i := LastDelimiter('.', PropTypeName);
    Result := 'T' + Copy(PropTypeName, i + 1, Length(PropTypeName));
  end;
end;

function PropertyIsPrimitiveNumericPacked(Prop: TProtoBufProperty): Boolean;
begin
  Result := (Prop.PropOptions.Value['packed'] = 'true') and (StrToPropertyType(Prop.PropType) in [sptDouble, sptFloat, sptInt32, sptInt64, sptuInt32, sptUint64, sptSInt32,
    sptSInt64, sptBool, sptFixed32, sptSFixed32, sptFixed64, sptSFixed64])
end;

function GetProtoBufMethodForScalarType(const Prop: TProtoBufProperty): string;
var
  StandartType: TScalarPropertyType;
  bPacked: Boolean;
begin
  StandartType := StrToPropertyType(Prop.PropType);
  bPacked := (Prop.PropKind = ptRepeated) and PropertyIsPrimitiveNumericPacked(Prop);

  case StandartType of
    sptComplex:
      ;
    sptDouble:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'Double';
    sptFloat:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'Float';
    sptInt32:
      if bPacked then
        Result := 'RawVarint32'
      else
        Result := 'Int32';
    sptInt64:
      if bPacked then
        Result := 'RawVarint64'
      else
        Result := 'Int64';
    sptuInt32:
      if bPacked then
        Result := 'RawVarint32'
      else
        Result := 'UInt32';
    sptUint64:
      if bPacked then
        Result := 'RawVarint64'
      else
        Result := 'Int64';
    sptSInt32:
      if bPacked then
        Result := 'RawSInt32'
      else
        Result := 'SInt32';
    sptSInt64:
      if bPacked then
        Result := 'RawSInt64'
      else
        Result := 'SInt64';
    sptFixed32:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'Fixed32';
    sptFixed64:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'Fixed64';
    sptSFixed32:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'SFixed32';
    sptSFixed64:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'SFixed64';
    sptBool:
      if bPacked then
        Result := 'RawBoolean'
      else
        Result := 'Boolean';
    sptString:
      Result := 'String';
    sptBytes:
      Result := 'Bytes';
  end;
end;

function ReQuoteStr(const Str: string): string;
begin
  Result := Str;
  if not StartsStr('"', Str) then
    Exit;

  Result := StringReplace(Str, '''', '''''', [rfReplaceAll]);
  Result := StringReplace(Result, '""', '"', [rfReplaceAll]);
  Result[1] := '''';
  Result[Length(Result)] := '''';
end;

type
  TDelphiProperty = record
    IsList: Boolean;
    isComplex: Boolean;
    isObject: Boolean;
    PropertyName: string;
    PropertyType: string;
    function tagName: string;
    function readOnlyDelphiProperty: Boolean;
  end;

procedure ParsePropType(Prop: TProtoBufProperty; Proto: TProtoFile; out DelphiProp: TDelphiProperty);
var
  LPropertyNameFirstCharUpperCase: string;
begin
  DelphiProp.IsList := Prop.PropKind = ptRepeated;
  DelphiProp.isComplex := StrToPropertyType(Prop.PropType) = sptComplex;
  if DelphiProp.isComplex then
    DelphiProp.isObject := Assigned(Proto.ProtoBufMessages.FindByName(Prop.PropType))
  else
    DelphiProp.isObject := False;
  LPropertyNameFirstCharUpperCase := AnsiUpperCase(Prop.Name[1]) + AnsiRightStr(Prop.Name, Length(Prop.Name) -1);
  if not DelphiProp.IsList then
    begin
      DelphiProp.PropertyName := LPropertyNameFirstCharUpperCase;
      DelphiProp.PropertyType := ProtoPropTypeToDelphiType(Prop.PropType);
    end
  else
    begin
      DelphiProp.PropertyName := Format('%sList', [LPropertyNameFirstCharUpperCase]);
      if DelphiProp.isObject then
        DelphiProp.PropertyType := Format('TProtoBufClassList<%s>', [ProtoPropTypeToDelphiType(Prop.PropType)])
      else
        DelphiProp.PropertyType := Format('TList<%s>', [ProtoPropTypeToDelphiType(Prop.PropType)]);
    end;

end;

function MsgNeedConstructor(ProtoMsg: TProtoBufMessage; Proto: TProtoFile): Boolean;
var
  i: Integer;
  DelphiProp: TDelphiProperty;
  Prop: TProtoBufProperty;
begin
  Result := False;
  for i := 0 to ProtoMsg.Count - 1 do
    begin
      Prop := ProtoMsg[i];
      ParsePropType(Prop, Proto, DelphiProp);
      Result := (Prop.PropKind = ptRequired) or DelphiProp.IsList or DelphiProp.isObject or Prop.PropOptions.HasValue['default'];
      if Result then
        Break;
    end;
end;

function MsgContainsRepeatedFields(ProtoMsg: TProtoBufMessage): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to ProtoMsg.Count - 1 do
    if ProtoMsg[i].PropKind = TPropKind.ptRepeated then
      begin
        Result := True;
        Break;
      end;
end;

{ TProtoBufGenerator }

procedure TProtoBufGenerator.Generate(Proto: TProtoFile; Output: TStrings);
var
  SLInterface, SLImplementation: TStrings;
begin
  // write name and interface uses
  SLInterface := TStringList.Create;
  try
    SLImplementation := TStringList.Create;
    try
      GenerateInterfaceSection(Proto, SLInterface);
      GenerateImplementationSection(Proto, SLImplementation);

      Output.Clear;
      Output.AddStrings(SLInterface);
      Output.AddStrings(SLImplementation);
    finally
      SLImplementation.Free;
    end;
  finally
    SLInterface.Free;
  end;
end;

procedure TProtoBufGenerator.Generate(Proto: TProtoFile; OutputStream: TStream; Encoding: TEncoding);
var
  SL: TStrings;
begin
  SL := TStringList.Create;
  try
    SL.WriteBOM := True;
    Generate(Proto, SL);
    SL.SaveToStream(OutputStream, Encoding);
  finally
    SL.Free;
  end;
end;

procedure TProtoBufGenerator.Generate(Proto: TProtoFile; const OutputDir: string; Encoding: TEncoding);
var
  FS: TFileStream;
  LOutputFileName: string;
begin
  LOutputFileName := Format('%s%s.pas', [IncludeTrailingPathDelimiter(OutputDir), Proto.Name]);
  FS := TFileStream.Create(LOutputFileName, fmCreate);
  try
    Generate(Proto, FS, Encoding);
  finally
    FS.Free;
  end;
end;

procedure TProtoBufGenerator.GenerateImplementationSection(Proto: TProtoFile; SL: TStrings);
  procedure WriteConstructor(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    Prop: TProtoBufProperty;
    DelphiProp: TDelphiProperty;
    i: Integer;
  begin
    SL.Add(Format('constructor T%s.Create;', [ProtoMsg.Name]));
    SL.Add('begin');
    SL.Add('  inherited;');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        if DelphiProp.IsList or DelphiProp.isObject then
          SL.Add(Format('  F%s := %s.Create;', [DelphiProp.PropertyName, DelphiProp.PropertyType]));
        if Prop.PropOptions.HasValue['default'] then
          SL.Add(Format('  %s%s := %s;', [IfThen(DelphiProp.readOnlyDelphiProperty, 'F', ''), DelphiProp.PropertyName, ReQuoteStr(Prop.PropOptions.Value['default'])]));
        if Prop.PropKind = ptRequired then
          SL.Add(Format('  RegisterRequiredField(%s);', [DelphiProp.tagName]));
      end;
    SL.Add('end;');

    SL.Add('');
    SL.Add(Format('destructor T%s.Destroy;', [ProtoMsg.Name]));
    SL.Add('begin');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        if DelphiProp.IsList or DelphiProp.isObject then
          SL.Add(Format('  F%s.Free;', [DelphiProp.PropertyName]));
      end;
    SL.Add('  inherited;');
    SL.Add('end;');
    SL.Add('');
  end;

  procedure WriteLoadProc(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    i, iInsertVarBlock, iInserttmpBufCreation, iBeginBlock: Integer;
    Prop: TProtoBufProperty;
    DelphiProp, OneOfDelphiProp: TDelphiProperty;
    bNeedtmpBuf: Boolean;
    sIndent: string;
  begin
    bNeedtmpBuf:= False;
    SL.Add(Format('function T%s.LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: Integer; WireType: Integer): Boolean;', [ProtoMsg.Name]));
    iInsertVarBlock:= SL.Count;
    SL.Add('begin');
    SL.Add('  Result := inherited;');
    if ProtoMsg.Count = 0 then
      begin
        SL.Add('end;');
        Exit;
      end;
    SL.Add('  if Result then');
    SL.Add('    Exit;');
    SL.Add('  Result := True;');
    iInserttmpBufCreation:= SL.Count;
    SL.Add('  case FieldNumber of');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        if Prop.PropKind = ptOneOf then
          Continue;
        SL.Add(Format('    %s:', [DelphiProp.tagName]));
        iBeginBlock:= SL.Count;
        SL.Add('      begin');
        sIndent:=  StringOfChar(' ', 8); {4 for case + 4 for tag and begin/end}
        if not DelphiProp.IsList then
          begin
            if not DelphiProp.isComplex then
              SL.Add(Format('%s%s := ProtoBuf.read%s;', [sIndent, DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop)]))
            else
              if not DelphiProp.isObject then
                SL.Add(Format('%s%s := %s(ProtoBuf.readEnum);', [sIndent, DelphiProp.PropertyName, DelphiProp.PropertyType]))
              else
                begin
                  bNeedtmpBuf:= True;
                  SL.Add(Format('%stmpBuf := ProtoBuf.ReadSubProtoBufInput;', [sIndent]));
                  SL.Add(Format('%sF%s.LoadFromBuf(tmpBuf);', [sIndent, DelphiProp.PropertyName]));
                end;
          end
        else
          begin
            if not DelphiProp.isComplex then
              begin
                if PropertyIsPrimitiveNumericPacked(Prop) then
                  begin
                    bNeedtmpBuf:= True;
                    SL.Add(Format('%sif WireType = WIRETYPE_LENGTH_DELIMITED then', [sIndent]));
                    SL.Add(Format('%sbegin', [sIndent]));
                    SL.Add(Format('%s  tmpBuf:=ProtoBuf.ReadSubProtoBufInput;', [sIndent]));
                    SL.Add(Format('%s  while tmpBuf.getPos < tmpBuf.BufSize do', [sIndent]));
                    SL.Add(Format('%s    F%s.Add(tmpBuf.read%s);', [sIndent, DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop)]));
                    SL.Add(Format('%send else', [sIndent]));
                    SL.Add(Format('%s  F%s.Add(ProtoBuf.read%s);', [sIndent, DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop)]));
                  end
                else
                  SL.Add(Format('%sF%s.Add(ProtoBuf.read%s);', [sIndent, DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop)]));
              end
            else
              if not DelphiProp.isObject then
                begin
                  if (Prop.PropOptions.Value['packed'] = 'true') then
                    begin
                      bNeedtmpBuf:= True;
                      SL.Add(Format('%sif WireType = WIRETYPE_LENGTH_DELIMITED then', [sIndent]));
                      SL.Add(Format('%sbegin', [sIndent]));
                      SL.Add(Format('%s  tmpBuf:=ProtoBuf.ReadSubProtoBufInput;', [sIndent]));
                      SL.Add(Format('%s  while tmpBuf.getPos<tmpBuf.BufSize do', [sIndent]));
                      SL.Add(Format('%s    F%s.Add(T%s(tmpBuf.readEnum));', [sIndent, DelphiProp.PropertyName, Prop.PropType]));
                      SL.Add(Format('%send else', [sIndent]));
                      SL.Add(Format('%s  F%s.Add(T%s(ProtoBuf.readEnum));', [sIndent, DelphiProp.PropertyName, Prop.PropType]));
                    end
                  else
                    SL.Add(Format('%sF%s.Add(T%s(ProtoBuf.readEnum));', [sIndent, DelphiProp.PropertyName, Prop.PropType]));
                end
              else
                SL.Add(Format('%sF%s.AddFromBuf(ProtoBuf, fieldNumber);', [sIndent, DelphiProp.PropertyName]));
          end;
        if Prop.OneOfPropertyParent <> nil then
        begin
          ParsePropType(Prop.OneOfPropertyParent, Proto, OneOfDelphiProp);
          SL.Add(Format('%s%s:= %s_%s_%s;', [sIndent, OneOfDelphiProp.PropertyName, ProtoMsg.Name, OneOfDelphiProp.PropertyName, DelphiProp.PropertyName]));
        end;
        if SL.Count = iBeginBlock + 2 then
        begin
          //we added only begin and one extra line, so remove begin block and
          //remove 2 intending spaces from the one inserted line
          SL.Delete(iBeginBlock);
          SL[iBeginBlock]:= Copy(SL[iBeginBlock], 3, MaxInt);
        end else
          SL.Add('      end;');
      end;
    SL.Add('  else');
    SL.Add('    Result := False;');
    SL.Add('  end;');
    if bNeedtmpBuf then
      begin
        SL.Insert(iInsertVarBlock, '  tmpBuf: TProtoBufInput;');
        SL.Insert(iInsertVarBlock, 'var');

        Inc(iInserttmpBufCreation, 2); //we just added two lines for the declaration
        SL.Insert(iInserttmpBufCreation, '  try');
        SL.Insert(iInserttmpBufCreation, '  tmpBuf:= nil;');
        for i:= iInserttmpBufCreation + 2 to SL.Count - 1 do
          SL[i]:= '  ' + SL[i];
        SL.Add('  finally');
        SL.Add('    tmpBuf.Free');
        SL.Add('  end;');
      end;
    SL.Add('end;');
    SL.Add('');
  end;

  procedure WriteSaveProc(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    i, iInsertVarBlock, iInserttmpBufCreation: Integer;
    Prop: TProtoBufProperty;
    DelphiProp: TDelphiProperty;
    bNeedtmpBuf, bNeedCounterVar: Boolean;
  begin
    bNeedtmpBuf:= False;
    bNeedCounterVar:= False;
    SL.Add(Format('procedure T%s.SaveFieldsToBuf(ProtoBuf: TProtoBufOutput);', [ProtoMsg.Name]));
    iInsertVarBlock:= sl.Count;
    SL.Add('begin');
    SL.Add('  inherited;');
    iInserttmpBufCreation:= SL.Count;
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);

        if Prop.PropKind = ptOneOf then
          Continue;

        SL.Add(Format('  if FieldHasValue[%s] then', [DelphiProp.tagName]));
        if not DelphiProp.IsList then
          begin
            if not DelphiProp.isComplex then
              SL.Add(Format('    ProtoBuf.write%s(%s, F%s);', [GetProtoBufMethodForScalarType(Prop), DelphiProp.tagName, DelphiProp.PropertyName]))
            else
              if not DelphiProp.isObject then
                SL.Add(Format('    ProtoBuf.writeInt32(%s, Integer(F%s));', [DelphiProp.tagName, DelphiProp.PropertyName]))
              else
                begin
                  bNeedtmpBuf:= True;
                  SL.Add(Format('    SaveMessageFieldToBuf(F%s, %s, tmpBuf, ProtoBuf);', [DelphiProp.PropertyName, DelphiProp.tagName]));
                end;
          end
        else
          begin
            if not DelphiProp.isComplex then
              begin
                if PropertyIsPrimitiveNumericPacked(Prop) then
                  begin
                    bNeedtmpBuf:= True;
                    bNeedCounterVar:= True;
                    SL.Add(       '  begin');
                    SL.Add(       '    tmpBuf.Clear;');
                    SL.Add(Format('    for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                    SL.Add(Format('      tmpBuf.write%s(F%s[i]);', [GetProtoBufMethodForScalarType(Prop), DelphiProp.PropertyName]));
                    SL.Add(Format('    ProtoBuf.writeMessage(%s, tmpBuf);', [DelphiProp.tagName]));
                    SL.Add(       '  end;');
                  end
                else
                  begin
                    bNeedCounterVar:= True;
                    SL.Add(Format('    for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                    SL.Add(Format('      ProtoBuf.write%s(%s, F%s[i]);', [GetProtoBufMethodForScalarType(Prop), DelphiProp.tagName, DelphiProp.PropertyName]));
                  end;
              end
            else
              if not DelphiProp.isObject then
                begin
                  if Prop.PropOptions.Value['packed'] = 'true' then
                    begin
                      bNeedtmpBuf:= True;
                      bNeedCounterVar:= True;
                      SL.Add(       '  begin');
                      SL.Add(       '    tmpBuf.Clear;');
                      SL.Add(Format('    for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                      SL.Add(Format('      tmpBuf.writeRawVarint32(Integer(F%s[i]));', [DelphiProp.PropertyName]));
                      SL.Add(Format('    ProtoBuf.writeMessage(%s, tmpBuf);', [DelphiProp.tagName]));
                      SL.Add(       '  end;');
                    end
                  else
                    begin
                      bNeedCounterVar:= True;
                      SL.Add(Format('    for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                      SL.Add(Format('      ProtoBuf.writeInt32(%s, Integer(F%s[i]));', [DelphiProp.tagName, DelphiProp.PropertyName]));
                    end;
                end
              else
                SL.Add(Format('    F%s.SaveToBuf(ProtoBuf, %s);', [DelphiProp.PropertyName, DelphiProp.tagName]));
          end;
      end;

    if bNeedtmpBuf or bNeedCounterVar then
      begin
        if bNeedCounterVar then
        begin
          SL.Insert(iInsertVarBlock, '  i: Integer;');
          Inc(iInserttmpBufCreation);
        end;
        if bNeedtmpBuf then
        begin
          SL.Insert(iInsertVarBlock, '  tmpBuf: TProtoBufOutput;');
          Inc(iInserttmpBufCreation);
        end;
        SL.Insert(iInsertVarBlock, 'var');
        Inc(iInserttmpBufCreation);
        if bNeedtmpBuf then
          begin
            SL.Insert(iInserttmpBufCreation, '  try');
            SL.Insert(iInserttmpBufCreation, '  tmpBuf:= TProtoBufOutput.Create;');
            for i:= iInserttmpBufCreation + 2 to SL.Count - 1 do
              SL[i]:= '  ' + SL[i];
            SL.Add('  finally');
            SL.Add('    tmpBuf.Free');
            SL.Add('  end;');
          end;
      end;

    SL.Add('end;');
    SL.Add('');
  end;

  procedure WriteSetterProcs(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    i, j: Integer;
    Prop, OneOfChildProp: TProtoBufProperty;
    DelphiProp, OneOfDelphiProp: TDelphiProperty;
  begin
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        if DelphiProp.readOnlyDelphiProperty then
          Continue;
        if  Prop.PropKind = ptOneOf then
          SL.Add(Format('procedure T%s.Set%s(const Value: %s);',
            [ProtoMsg.Name, DelphiProp.PropertyName, DelphiProp.PropertyType]))
        else
          SL.Add(Format('procedure T%s.Set%s(Tag: Integer; const Value: %s);',
            [ProtoMsg.Name, DelphiProp.PropertyName, DelphiProp.PropertyType]));
        SL.Add('begin');
        SL.Add(Format('  F%s:= Value;', [DelphiProp.PropertyName]));
        if Prop.PropKind = ptOneOf then
        begin
          //clear FieldHasValue for all others of this OneOf
          for j:= i + 1 to ProtoMsg.Count - 1 do
          begin
            OneOfChildProp:= ProtoMsg[j];
            ParsePropType(OneOfChildProp, Proto, OneOfDelphiProp);
            if OneOfChildProp.OneOfPropertyParent <> Prop then
              Break;
            SL.Add(Format('  FieldHasValue[%s]:= Value = %s_%s_%s;',
              [OneOfDelphiProp.tagName, ProtoMsg.Name, DelphiProp.PropertyName,
              OneOfDelphiProp.PropertyName]));
          end;
        end else
        begin
          if Prop.OneOfPropertyParent <> nil then
          begin
            ParsePropType(Prop.OneOfPropertyParent, Proto, OneOfDelphiProp);
            SL.Add(Format('  %s:= %s_%s_%s;', [OneOfDelphiProp.PropertyName, ProtoMsg.Name, OneOfDelphiProp.PropertyName, DelphiProp.PropertyName]));
          end else
            SL.Add('  FieldHasValue[Tag]:= True;');
        end;
        SL.Add('end;');
        SL.Add('');
      end;

  end;

  procedure WriteMessageToSL(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    bNeedConstructor: Boolean;
  begin
    if ProtoMsg.IsImported then
      Exit;
    bNeedConstructor := MsgNeedConstructor(ProtoMsg, Proto);

    SL.Add(Format('{ T%s }', [ProtoMsg.Name]));
    SL.Add('');
    if bNeedConstructor then
      WriteConstructor(ProtoMsg, SL);
    WriteLoadProc(ProtoMsg, SL);
    WriteSaveProc(ProtoMsg, SL);
    WriteSetterProcs(ProtoMsg, SL);
  end;

var
  i: Integer;
begin
  SL.Add('implementation');
  SL.Add('');

  for i := 0 to Proto.ProtoBufMessages.Count - 1 do
    if not Proto.ProtoBufMessages[i].IsImported then
        WriteMessageToSL(Proto.ProtoBufMessages[i], SL);
  SL.Add('end.');
end;

procedure TProtoBufGenerator.GenerateInterfaceSection(Proto: TProtoFile; SL: TStrings);
var
  bNeedsGenericsCollection: Boolean;

  procedure WriteBeforeComments(AComments, SL: TStrings; const Indent: string = '  ');
  var
    i: Integer;
  begin
    for i:= 0 to AComments.Count - 1 do
      SL.Add(Format('%s//%s', [Indent, AComments[i]]));
  end;

  procedure WriteEnumToSL(ProtoEnum: TProtoBufEnum; SL: TStrings);
  var
    i: Integer;
    s: string;
  begin
    if ProtoEnum.IsImported then
      Exit;

    WriteBeforeComments(ProtoEnum.Comments, SL);
    SL.Add(Format('  T%s=(', [ProtoEnum.Name]));
    for i := 0 to ProtoEnum.Count - 1 do
      begin
        if ProtoEnum[i].Comments.Count > 1 then
          WriteBeforeComments(ProtoEnum[i].Comments, SL, '    ');
        s:= Format('    %s = %s%s', [ProtoEnum[i].Name, ProtoEnum.GetEnumValueString(i),
          IfThen(i < (ProtoEnum.Count - 1), ',', '')]);
        if ProtoEnum[i].Comments.Count = 1 then
          s:= Format('%s  //%s', [s, ProtoEnum[i].Comments[0]]);
        SL.Add(s);
      end;
    SL.Add('  );');
  end;

  procedure WriteMessageToSL(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    i, j: Integer;
    Prop, OneOfProp: TProtoBufProperty;
    DelphiProp, OneOfDelphiProp: TDelphiProperty;
    s, sdefValue: string;
  begin
    if ProtoMsg.IsImported then
      Exit;

    WriteBeforeComments(ProtoMsg.Comments, SL);
    if ProtoMsg.ExtendOf = '' then
      s := 'AbstractProtoBufClass'
    else
      s := ProtoMsg.ExtendOf;
    SL.Add(Format('  T%s = class(T%s)', [ProtoMsg.Name, s]));
    //write tag constants and OneOfEnums, need to be first since
    //OneOfEnum is used for strict private field
    SL.Add('  public');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        if Prop.PropKind = ptOneOf then
          Continue;
        s := Format('    const %s = %d;', [DelphiProp.tagName, Prop.PropFieldNum]);
        SL.Add(s);
      end;
    //write oneOfEnums, using the tag constants we just wrote
    for i:= 0 to ProtoMsg.Count - 1 do
    begin
      OneOfProp := ProtoMsg[i];
      if OneOfProp.PropKind <> ptOneOf then
        Continue;
      ParsePropType(OneOfProp, Proto, OneOfDelphiProp);
      SL.Add(Format('    type %s = (', [OneOfDelphiProp.PropertyType]));
      SL.Add(Format('      %s_%s_Nothing = 0,', [ProtoMsg.Name, OneOfDelphiProp.PropertyName]));
      for j:= i + 1 to ProtoMsg.Count - 1 do
      begin
        Prop:= ProtoMsg[j];
        if Prop.OneOfPropertyParent <> OneOfProp then
          Break;
        ParsePropType(Prop, Proto, DelphiProp);
        SL.Add(Format('      %s_%s_%s = %s,', [ProtoMsg.Name, OneOfDelphiProp.PropertyName, DelphiProp.PropertyName, DelphiProp.tagName]));
      end;
      //remove comma of last enum value
      s:= SL[SL.Count - 1];
      SL[SL.Count - 1]:= Copy(s, 1, Length(s) - 1);
      SL.Add('    );');
    end;
    SL.Add('  strict private');
    //field definitions
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        SL.Add(Format('    F%s: %s;', [DelphiProp.PropertyName, DelphiProp.PropertyType]));
      end;
    SL.Add('');
    //property setters
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        if DelphiProp.readOnlyDelphiProperty then
          Continue;
        if Prop.PropKind = ptOneOf then
          s := Format('    procedure Set%s(const Value: %s);', [DelphiProp.PropertyName, DelphiProp.PropertyType])
        else
          s := Format('    procedure Set%s(Tag: Integer; const Value: %s);', [DelphiProp.PropertyName, DelphiProp.PropertyType]);
        SL.Add(s);
      end;

    SL.Add('  strict protected');
    SL.Add('    function LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: Integer; WireType: Integer): Boolean; override;');
    SL.Add('    procedure SaveFieldsToBuf(ProtoBuf: TProtoBufOutput); override;');

    SL.Add('  public');
    if MsgNeedConstructor(ProtoMsg, Proto) then
      begin
        SL.Add('    constructor Create; override;');
        SL.Add('    destructor Destroy; override;');
        SL.Add('');
      end;
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        //we need Generics.Collection if TList<> is used, but not for
        //TProtoBufClassList, which is defined in uAbstractProtoBufClasses
        if DelphiProp.IsList and (not DelphiProp.IsObject) then
          bNeedsGenericsCollection:= True;
        for j:= 0 to Prop.Comments.Count - 1 do
          SL.Add('    //' + Prop.Comments[j]);
        if DelphiProp.readOnlyDelphiProperty then
          begin
            s := Format('    property %s: %s read F%s',
              [DelphiProp.PropertyName, DelphiProp.PropertyType,
              DelphiProp.PropertyName]);
          end else
          begin
            if Prop.PropKind = ptOneOf then
            begin
              s := Format('    property %s: %s read F%s write Set%s',
                [DelphiProp.PropertyName, DelphiProp.PropertyType,
                DelphiProp.PropertyName, DelphiProp.PropertyName]);
            end else
            begin
              s := Format('    property %s: %s index %s read F%s write Set%s',
                [DelphiProp.PropertyName, DelphiProp.PropertyType,
                DelphiProp.tagName, DelphiProp.PropertyName,
                DelphiProp.PropertyName]);
              if Prop.PropOptions.HasValue['default'] then
                begin
                  sdefValue := Prop.PropOptions.Value['default'];
                  if StartsStr('"', sdefValue) or ContainsStr(sdefValue, '.') or ContainsStr(sdefValue, 'e') then
                    s := s + '; //';
                  s := s + Format(' default %s', [ReQuoteStr(sdefValue)]);
                end;
            end;
          end;
        s := s + ';';
        SL.Add(s);
      end;
    SL.Add('  end;');
  end;

var
  i, iGenericsCollectionUses: Integer;
begin
  SL.Add(Format('unit %s;', [Proto.Name]));
  SL.Add('');
  SL.Add('interface');
  SL.Add('');
  SL.Add('// *********************************** ');
  SL.Add('//   classes for:');
  SL.Add(Format('//   %s.proto', [Proto.Name]));
  SL.Add('//   generated by ProtoBufGenerator ');
  SL.Add('//        kami-soft 2016-2017');
  SL.Add('// ***********************************');
  SL.Add('');
  SL.Add('uses');
  SL.Add('  SysUtils,');
  SL.Add('  Classes,');
  iGenericsCollectionUses:= SL.Count;
  bNeedsGenericsCollection:= False;
  SL.Add('  pbInput,');
  SL.Add('  pbOutput,');
  SL.Add('  pbPublic,');
  if Proto.Imports.Count = 0 then
    SL.Add('  uAbstractProtoBufClasses;')
  else
    begin
      SL.Add('  uAbstractProtoBufClasses,');
      for i := 0 to Proto.Imports.Count - 2 do
        SL.Add('  ' + Proto.Imports[i] + ',');
      SL.Add('  ' + Proto.Imports[Proto.Imports.Count - 1] + ';');
    end;
  SL.Add('');
  SL.Add('type');
  // add all enums
  for i := 0 to Proto.ProtoBufEnums.Count - 1 do
    if not Proto.ProtoBufEnums[i].IsImported then
      begin
        WriteEnumToSL(Proto.ProtoBufEnums[i], SL);
        SL.Add('');
      end;

  // add all classes definitions
  for i := 0 to Proto.ProtoBufMessages.Count - 1 do
    if not Proto.ProtoBufMessages[i].IsImported then
      begin
        WriteMessageToSL(Proto.ProtoBufMessages[i], SL);
        SL.Add('');
      end;

  if bNeedsGenericsCollection then
    SL.Insert(iGenericsCollectionUses, '  Generics.Collections,');
end;

procedure TProtoBufGenerator.Generate(const InputFile, OutputDir: string; Encoding: TEncoding);
var
  Proto: TProtoFile;
  SL: TStringList;
  iPos: Integer;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(InputFile);
    Proto := TProtoFile.Create(nil);
    try
      Proto.FileName := InputFile;
      iPos := 1;
      Proto.ParseFromProto(SL.Text, iPos);
      Generate(Proto, OutputDir, Encoding);
    finally
      Proto.Free;
    end;
  finally
    SL.Free;
  end;
end;

{ TDelphiProperty }

function TDelphiProperty.readOnlyDelphiProperty: Boolean;
begin
  Result := IsList or isObject;
end;

function TDelphiProperty.tagName: string;
begin
  Result := 'tag_' + PropertyName;
end;

end.
