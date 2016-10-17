unit uProtoBufParserAbstractClasses;

interface

uses
  System.Classes,
  System.Generics.Collections;

type
  TAbstractProtoBufParserItem = class(TObject)
  protected
    FName: string;
  public
    constructor Create; virtual;
    procedure ParseFromProto(const Proto: string; var iPos: Integer); virtual; abstract;
    property Name: string read FName;
  end;

  TAbstractProtoBufParserContainer<T: TAbstractProtoBufParserItem> = class(TObjectList<T>)
  protected
    FName: string;
  public
    procedure ParseFromProto(const Proto: string; var iPos: Integer); virtual;
    property Name: string read FName;
  end;

implementation

{ TAbstractProtoBufParserItem }

constructor TAbstractProtoBufParserItem.Create;
begin
  inherited Create;
end;

{ TAbstractProtoBufParserContainer<T> }

procedure TAbstractProtoBufParserContainer<T>.ParseFromProto(const Proto: string; var iPos: Integer);
begin
  Clear;
end;

end.
