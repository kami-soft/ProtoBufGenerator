unit uProtoBufParserAbstractClasses;

interface

uses
  System.Classes,
  System.Generics.Collections;

type
  TAbstractProtoBufParserItem = class(TObject)
  protected
    FName: string;
    FRoot: TAbstractProtoBufParserItem;
  public
    constructor Create(ARoot: TAbstractProtoBufParserItem); virtual;
    procedure ParseFromProto(const Proto: string; var iPos: Integer); virtual; abstract;
    property Name: string read FName;
  end;

  TAbstractProtoBufParserContainer<T: TAbstractProtoBufParserItem> = class(TObjectList<T>)
  protected
    FName: string;
    FRoot: TAbstractProtoBufParserItem;
  public
    constructor Create(ARoot: TAbstractProtoBufParserItem); virtual;
    procedure ParseFromProto(const Proto: string; var iPos: Integer); virtual;
    property Name: string read FName;
  end;

implementation

{ TAbstractProtoBufParserItem }

constructor TAbstractProtoBufParserItem.Create(ARoot: TAbstractProtoBufParserItem);
begin
  inherited Create;
  FRoot := ARoot;
end;

{ TAbstractProtoBufParserContainer<T> }

constructor TAbstractProtoBufParserContainer<T>.Create(ARoot: TAbstractProtoBufParserItem);
begin
  inherited Create(True);
  FRoot := ARoot;
end;

procedure TAbstractProtoBufParserContainer<T>.ParseFromProto(const Proto: string; var iPos: Integer);
begin
  Clear;
end;

end.
