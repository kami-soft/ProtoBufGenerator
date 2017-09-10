// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// author this port to delphi - Marat Shaymardanov, Tomsk (2007, 2013)
//
// You can freely use this code in any project
// if sending any postcards with postage stamp to my address:
// Frunze 131/1, 56, Russia, Tomsk, 634021

unit Example1;

interface

uses
  Classes, SysUtils, Contnrs, pbPublic, pbInput, pbOutput;

(*

  message Person {
    required string name = 1;
    required int32 id = 2;
    optional string email = 3;

    enum PhoneType {
      MOBILE = 0;
      HOME = 1;
      WORK = 2;
    }

    message PhoneNumber {
      required string number = 1;
      optional PhoneType type = 2 [default = HOME];
    }

    repeated PhoneNumber phone = 4;

  }

*)

type

  TPhoneType = (ptMOBILE, ptHOME, ptWORK);

  TPhoneNumber = class
  private
    FTyp   : TPhoneType;
    FNumber: AnsiString;

  const
    ft_Number = 1;
    ft_Typ    = 2;
  public
    constructor Create;
    property Number: AnsiString read FNumber write FNumber;
    property Typ: TPhoneType read FTyp write FTyp;
  end;

  TPerson = class
  private
    FName  : AnsiString;
    FEmail : AnsiString;
    FId    : integer;
    FPhones: TObjectList;
    function GetPhones(Index: integer): TPhoneNumber;
    function GetPhonesCount: integer;

  const
    ft_Name  = 1;
    ft_Id    = 2;
    ft_Email = 3;
    ft_Phone = 4;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddPhone(const Number: AnsiString; Typ: TPhoneType = ptHOME);
    procedure DeletePhone(Index: integer);
    property name: AnsiString read FName write FName;
    property Id: integer read FId write FId;
    property Email: AnsiString read FEmail write FEmail;
    property PhonesCount: integer read GetPhonesCount;
    property Phones[index: integer]: TPhoneNumber read GetPhones;
  end;

  TPersonBuilder = class
  private
    FBuffer: TProtoBufOutput;
  public
    constructor Create;
    destructor Destroy; override;
    function GetBuf: TProtoBufOutput;
    procedure Write(Person: TPerson);
  end;

  TPersonReader = class
  private
    FBuffer: TProtoBufInput;
    procedure LoadPhone(Phone: TPhoneNumber);
  public
    constructor Create;
    destructor Destroy; override;
    function GetBuf: TProtoBufInput;
    procedure Load(Person: TPerson);
  end;

implementation

{ TPhoneNumber }

constructor TPhoneNumber.Create;
begin
  inherited Create;
  FTyp := ptHOME;
end;

{ TPerson }

constructor TPerson.Create;
begin
  inherited Create;
  FPhones := TObjectList.Create(True);
end;

destructor TPerson.Destroy;
begin
  FPhones.Free;
  inherited;
end;

function TPerson.GetPhonesCount: integer;
begin
  Result := FPhones.Count;
end;

function TPerson.GetPhones(Index: integer): TPhoneNumber;
begin
  Result := FPhones.Items[index] as TPhoneNumber;
end;

procedure TPerson.AddPhone(const Number: AnsiString; Typ: TPhoneType = ptHOME);
var
  Phone: TPhoneNumber;
begin
  Phone := TPhoneNumber.Create;
  Phone.Number := Number;
  Phone.Typ := Typ;
  FPhones.Add(Phone);
end;

procedure TPerson.DeletePhone(Index: integer);
begin
  FPhones.Delete(index);
end;

{ TPersonBuilder }

constructor TPersonBuilder.Create;
begin
  inherited Create;
  FBuffer := TProtoBufOutput.Create;
end;

destructor TPersonBuilder.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

function TPersonBuilder.GetBuf: TProtoBufOutput;
begin
  Result := FBuffer;
end;

procedure TPersonBuilder.Write(Person: TPerson);
var
  Phone       : TPhoneNumber;
  PhonesBuffer: TProtoBufOutput;
  i           : integer;
begin
  FBuffer.writeString(TPerson.ft_Name, Person.Name);
  FBuffer.writeInt32(TPerson.ft_Id, Person.FId);
  // Not save empty e-mail
  if Person.Email <> '' then
    FBuffer.writeString(TPerson.ft_Email, Person.Email);
  // Save Phones as Message
  if Person.GetPhonesCount > 0 then
  begin
    PhonesBuffer := TProtoBufOutput.Create;
    try
      // Write person's phones
      for i := 0 to Person.GetPhonesCount - 1 do
      begin
        PhonesBuffer.Clear;
        Phone := Person.Phones[i];
        PhonesBuffer.writeString(TPhoneNumber.ft_Number, Phone.Number);
        // Not save phone type with Default value = ptHOME
        if Phone.FTyp <> ptHOME then
          PhonesBuffer.writeInt32(TPhoneNumber.ft_Typ, Ord(Phone.FTyp));
        // Write phones as message
        FBuffer.writeMessage(TPerson.ft_Phone, PhonesBuffer);
      end;
    finally
      PhonesBuffer.Free;
    end;
  end;
end;

{ TPersonReader }

constructor TPersonReader.Create;
begin
  inherited;
  FBuffer := TProtoBufInput.Create;
end;

destructor TPersonReader.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

function TPersonReader.GetBuf: TProtoBufInput;
begin
  Result := FBuffer;
end;

procedure TPersonReader.Load(Person: TPerson);
var
  tag, fieldNumber, wireType: integer;
  Phone                     : TPhoneNumber;
begin
  tag := FBuffer.readTag;
  while tag <> 0 do
  begin
    wireType := getTagWireType(tag);
    fieldNumber := getTagFieldNumber(tag);
    case fieldNumber of
      TPerson.ft_Name:
        begin
          Assert(wireType = WIRETYPE_LENGTH_DELIMITED);
          Person.Name := FBuffer.readString;
        end;
      TPerson.ft_Id:
        begin
          Assert(wireType = WIRETYPE_VARINT);
          Person.Id := FBuffer.readInt32;
        end;
      TPerson.ft_Email:
        begin
          Assert(wireType = WIRETYPE_LENGTH_DELIMITED);
          Person.Email := FBuffer.readString;
        end;
      TPerson.ft_Phone:
        begin
          Assert(wireType = WIRETYPE_LENGTH_DELIMITED);
          Phone := TPhoneNumber.Create;
          Person.FPhones.Add(Phone);
          LoadPhone(Phone);
        end;
    else
      FBuffer.skipField(tag);
    end;
    tag := FBuffer.readTag;
  end;
end;

procedure TPersonReader.LoadPhone(Phone: TPhoneNumber);
var
  tag, fieldNumber, wireType: integer;
  size                      : integer;
  endPosition               : integer;
begin
  size := FBuffer.readInt32;
  endPosition := FBuffer.getPos + size;
  repeat
    tag := FBuffer.readTag;
    if tag = 0 then
      exit;
    wireType := getTagWireType(tag);
    fieldNumber := getTagFieldNumber(tag);
    case fieldNumber of
      TPhoneNumber.ft_Number:
        begin
          Assert(wireType = WIRETYPE_LENGTH_DELIMITED);
          Phone.Number := FBuffer.readString;
        end;
      TPhoneNumber.ft_Typ:
        begin
          Assert(wireType = WIRETYPE_VARINT);
          Phone.Typ := TPhoneType(FBuffer.readInt32);
        end;
    else
      FBuffer.skipField(tag);
    end;
  until FBuffer.getPos >= endPosition;
end;

end.
