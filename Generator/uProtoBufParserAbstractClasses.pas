unit uProtoBufParserAbstractClasses;

interface

uses
  System.Classes,
  System.Generics.Collections;

type
  TAbstractProtoBufParserItem = class(TObject)
  protected
    FPackage: string;
    FName: string;
    FRoot: TAbstractProtoBufParserItem;
    FRootPath: string;
    FComments: TStringList;
  public
    constructor Create(ARoot: TAbstractProtoBufParserItem); virtual;
    destructor Destroy; override;

    procedure ParseFromProto(const Proto: string; var iPos: Integer); virtual; abstract;
    procedure AddCommentsToBeginning(AComments: TStringList);

    property RootPath: string read FRootPath write FRootPath;
    property Name: string read FName write FName;
    property Package: string read FPackage write FPackage;
    property Comments: TStringList read FComments;
  end;

  TAbstractProtoBufParserContainer<T: TAbstractProtoBufParserItem> = class(TObjectList<T>)
  private
    FExtendOf: string;
    FIsImported: Boolean;
  protected
    FName: string;
    FRoot: TAbstractProtoBufParserItem;
    FComments: TStringList;
  public
    constructor Create(ARoot: TAbstractProtoBufParserItem); virtual;
    destructor Destroy; override;

    procedure ParseFromProto(const Proto: string; var iPos: Integer); virtual;
    procedure AddCommentsToBeginning(AComments: TStringList);

    property Name: string read FName write FName;
    property Comments: TStringList read FComments;

    property IsImported: Boolean read FIsImported write FIsImported;
    property ExtendOf: string read FExtendOf write FExtendOf;
  end;

implementation

{ TAbstractProtoBufParserItem }

procedure TAbstractProtoBufParserItem.AddCommentsToBeginning(
  AComments: TStringList);
begin
  if (AComments <> nil) and (AComments.Count > 0) then
    if FComments.Count > 0 then
      FComments.Text:= AComments.Text + FComments.LineBreak + FComments.Text else
      FComments.Text:= AComments.Text;
end;

constructor TAbstractProtoBufParserItem.Create(ARoot: TAbstractProtoBufParserItem);
begin
  inherited Create;
  FRoot := ARoot;
  FComments:= TStringList.Create;
  FComments.TrailingLineBreak:= False;
end;

destructor TAbstractProtoBufParserItem.Destroy;
begin
  FComments.Free;
  inherited;
end;

{ TAbstractProtoBufParserContainer<T> }

procedure TAbstractProtoBufParserContainer<T>.AddCommentsToBeginning(AComments: TStringList);
begin
  if (AComments <> nil) and (AComments.Count > 0) then
    if FComments.Count > 0 then
      FComments.Text:= AComments.Text + FComments.LineBreak + FComments.Text else
      FComments.Text:= AComments.Text;
end;

constructor TAbstractProtoBufParserContainer<T>.Create(ARoot: TAbstractProtoBufParserItem);
begin
  inherited Create(True);
  FRoot := ARoot;
  FComments := TStringList.Create;
  FComments.TrailingLineBreak:= False;
end;

destructor TAbstractProtoBufParserContainer<T>.Destroy;
begin
  FComments.Free;
  inherited;
end;

procedure TAbstractProtoBufParserContainer<T>.ParseFromProto(const Proto: string; var iPos: Integer);
begin
  FComments.Clear;
  Clear;
end;

end.
