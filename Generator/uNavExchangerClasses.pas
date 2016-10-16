unit uNavExchangerClasses;
{$I main.inc}

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Generics.Collections,
  pbPublic,
  pbInput,
  pbOutput,
  uPacketStream,
  uAbstractProtoBufClasses;

const
  FullName = 'NavExchangerX 1.0';
  DisplayName = 'Navigator exchanger';

type
  // ==========классы для обмена с навсервером ==================
  TInPacketStreamBigEndian = class(TInPacketStream)
  protected
    procedure DoHeaderReceived; override;
  end;

  TOutPacketStreamBigEndian = class(TOutPacketStream)
  protected
    procedure DoHeaderPrepared; override;
  end;

  // ===================== общие классы =========================
  TErrorMessage = class(TAbstractProtoBufClass)
  private
    FCode: integer;
    FDescription: string;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property Code: integer read FCode write FCode;
    property Description: string read FDescription write FDescription;
  end;

  // ================== авторизация на навсервере ======================
  TAuthRequest = class(TAbstractProtoBufClass)
  private
    FVersion: integer;
    FPassword: string;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property Version: integer read FVersion write FVersion;
    property Password: string read FPassword write FPassword;
  end;

  TAuthAnswer = class(TAbstractProtoBufClass)
  private
    FReason: string;
    FIsAccepted: boolean;
    FDebugMsg: string;
    FErrorCode: integer;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property IsAccepted: boolean read FIsAccepted write FIsAccepted;
    property Reason: string read FReason write FReason;
    property ErrorCode: integer read FErrorCode write FErrorCode;
    property DebugMsg: string read FDebugMsg write FDebugMsg;
  end;

  // =============== авторизация мобильных клиентов ===================
  // ===============    (водительских терминалов)   ===================
  // =============== авторизация мобильных клиентов ===================

  TMobileAuthRequest = class(TAbstractProtoBufClass)
  private
    FCallsign: string;
    FAuthKey: string;
    FLoginID: Int64;
    FSessionID: string;
    FPassword: string;
    FprotocolVersionMinor: integer;
    FprotocolVersionMajor: integer;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property LoginID: Int64 read FLoginID write FLoginID;
    // property AuthKey: string read FAuthKey write FAuthKey;
    property SessionID: string read FSessionID write FSessionID;
    property Callsign: string read FCallsign write FCallsign;
    property Password: string read FPassword write FPassword;

    property protocolVersionMajor: integer read FprotocolVersionMajor write FprotocolVersionMajor;
    property protocolVersionMinor: integer read FprotocolVersionMinor write FprotocolVersionMinor;
  end;

  TMobileContext = class;

  TMobileAuthAnswer = class(TAbstractProtoBufClass)
  private
    FCallsign: string;
    FSessionID: string;
    FIsAccepted: boolean;
    FReason: string;
    FMobileContext: TMobileContext;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property IsAccepted: boolean read FIsAccepted write FIsAccepted;
    property Callsign: string read FCallsign write FCallsign;
    property SessionID: string read FSessionID write FSessionID;
    property Reason: string read FReason write FReason;

    property MobileContext: TMobileContext read FMobileContext;
  end;

  // ===========================================================================
  // ==================== основной обмен с водительскими терминалами ===========
  // ===========================================================================

  TCommunicationHeader = class(TAbstractProtoBufClass)
  private
    FCallsign: string;
    FSessionID: string;
    FLifetime: integer;
    FMessageID: Int64;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property SessionIDX: string read FSessionID write FSessionID;
    property Callsign: string read FCallsign write FCallsign;
    property MessageID: Int64 read FMessageID write FMessageID;
    property Lifetime: integer read FLifetime write FLifetime;
  end;

  // ===========================================================================

  TTrackRecord = class(TAbstractProtoBufClass) // message TrackRecord
  private
    FLon: Double;
    FLat: Double;
    Fdt: TDateTime;
    FAccuracy: Double;
    FSpeed: Double;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property dt: TDateTime read Fdt write Fdt;
    property Lat: Double read FLat write FLat;
    property Lon: Double read FLon write FLon;
    property Speed: Double read FSpeed write FSpeed;
    property Accuracy: Double read FAccuracy write FAccuracy;
  end;

  (* enum TripStatus {
    UNDEFINED = 0;
    PROPOSED = 1;
    ASSIGNED = 2;
    MOVING_TO_START_ADDRESS = 3;
    ON_PLACE = 4;
    ON_ROUTE = 5;
    COMPLETE = 6;
    CANCEL = 7;
    WAITING = 9;
    } *)
  TTripStatus = (mtsUndefined, mtsAssigned, mtsAccepted, mtsMoveToStartAddress, mtsOnPlace, mtsOnRoute, mtsComplete, mtsCancelled, mtsNotUsed,
    mtsWaitingOnRoute);

  // message MobileTripStatus {
  TMobileTripStatus = class(TAbstractProtoBufClass)
  private
    FTripStatus: TTripStatus;
    FOrderID: Int64;
    FReason: string;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property OrderID: Int64 read FOrderID write FOrderID;
    property TripStatus: TTripStatus read FTripStatus write FTripStatus;
    property Reason: string read FReason write FReason;
  end;

  (* enum WorkshiftStatus {PLANNED = 0;OPEN = 1;REST = 2;CLOSED = 3;ACCIDENT = 4;} *)
  TMobileWSStatus = (mwsPlanned, mwsOpen, mwsRest, mwsClosed, mwsAccident);

  // message MobileDriverStatus  and message MobileTripStatus
  TMobileDriverStatus = class(TAbstractProtoBufClass)
  private
    FWorkshiftStatus: TMobileWSStatus;
    FMobileTripStatus: TMobileTripStatus;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property WorkshiftStatus: TMobileWSStatus read FWorkshiftStatus write FWorkshiftStatus;
    property MobileTripStatus: TMobileTripStatus read FMobileTripStatus;
  end;

  // message Client {
  TMobileClient = class(TAbstractProtoBufClass)
  private
    FPhone: string;
    FClientName: string;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property ClientName: string read FClientName write FClientName;
    property Phone: string read FPhone write FPhone;
  end;

  // message WayPoint {
  TMobileWayPoint = class(TAbstractProtoBufClass)
  private
    FLatitude: Double;
    FText: string;
    FLongitude: Double;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property Latitude: Double read FLatitude write FLatitude;
    property Longitude: Double read FLongitude write FLongitude;
    property Text: string read FText write FText;
  end;

  TMobileWayPoints = class(TObjectList<TMobileWayPoint>)
  public
    function AddNew: TMobileWayPoint;
  end;

  TMobileOrder = class(TAbstractProtoBufClass) // message Order {
  private
    FCost: Double;
    FNote: string;
    FStartDateTime: TDateTime;
    FWayPoints: TMobileWayPoints;
    FProposal: boolean;
    FOrderID: Int64;
    FClient: TMobileClient;
    FTripStatus: TTripStatus;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property OrderID: Int64 read FOrderID write FOrderID;
    property Cost: Double read FCost write FCost;

    property Client: TMobileClient read FClient write FClient;
    property WayPoints: TMobileWayPoints read FWayPoints write FWayPoints;

    property Proposal: boolean read FProposal write FProposal;
    property StartDateTime: TDateTime read FStartDateTime write FStartDateTime;
    property Note: string read FNote write FNote;

    property TripStatus: TTripStatus read FTripStatus write FTripStatus;
  end;

  TMobileOrders = class(TAbstractProtoBufClass) // message Orders { and message OrderUpdate {
  private
    FMobileOrders: TObjectList<TMobileOrder>;
    function GetOrder(ItemIndex: integer): TMobileOrder;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    function AddNew: TMobileOrder;

    property Orders[ItemIndex: integer]: TMobileOrder read GetOrder; default;
  end;

  // enum LinkType {
  TLinkType = (ltDispatcherToDriver, ltDriverToClient, ltDispatcherToClient);

  // message CallRequest {
  TCallRequest = class(TAbstractProtoBufClass)
  private
    FLinkType: TLinkType;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property LinkType: TLinkType read FLinkType write FLinkType;
  end;

  // message MobileContext {
  TMobileContext = class(TAbstractProtoBufClass)
  private
    FOrder: TMobileOrder;
    FMobileStatus: TMobileDriverStatus;

  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property MobileStatus: TMobileDriverStatus read FMobileStatus;
    property Order: TMobileOrder read FOrder;
  end;

  // enum TextMessageKind {
  TMobileTextMessageKind = (mtmkNormal, mtmkPopup);

  // message TextMessage {
  TMobileTextMessage = class(TAbstractProtoBufClass)
  private
    FMessageText: string;
    FRecepientName: string;
    FSentAt: TDateTime;
    FMessageKind: TMobileTextMessageKind;
    FSenderName: string;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property MessageKind: TMobileTextMessageKind read FMessageKind write FMessageKind;
    property SentAt: TDateTime read FSentAt write FSentAt;
    property SenderName: string read FSenderName write FSenderName;
    property RecepientName: string read FRecepientName write FRecepientName;
    property MessageText: string read FMessageText write FMessageText;
  end;

  // message FailureReasonMsg {
  TFailureReasonMsg = class(TAbstractProtoBufClass)
  private
    FID: integer;
    FText: string;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property ID: integer read FID write FID;
    property Text: string read FText write FText;
  end;

  TFailureReasonType = (frtPassenger, frtDriver);

  // message FailureReasons {
  TFailureReasons = class(TAbstractProtoBufClass)
  private
    FItemsPassenger: TObjectList<TFailureReasonMsg>;
    FItemsDriver: TObjectList<TFailureReasonMsg>;

    function GetItemsOfPassenger(Index: integer): TFailureReasonMsg;
    function GetItemsOfDriver(Index: integer): TFailureReasonMsg;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    procedure Clear;

    function Add(frt: TFailureReasonType; frm: TFailureReasonMsg): integer;
    function AddNew(frt: TFailureReasonType): TFailureReasonMsg;
    procedure Remove(frt: TFailureReasonType; frm: TFailureReasonMsg);
    procedure Delete(frt: TFailureReasonType; Index: integer);
    property ReasonsOfPassenger[Index: integer]: TFailureReasonMsg read GetItemsOfPassenger; default;
    property ReasonsOfDriver[Index: integer]: TFailureReasonMsg read GetItemsOfDriver;
  end;

  // message DistrictInfo {
  TActualWSInfo = class(TAbstractProtoBufClass)
  private
    FDistrictName: string;
    FNumberInQueue: integer;
    FOrdersCount: integer;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property NumberInQueue: integer read FNumberInQueue write FNumberInQueue;
    property DistrictName: string read FDistrictName write FDistrictName;
    property OrdersCount: integer read FOrdersCount write FOrdersCount;
  end;

  (* message NameValue {
    required string name = 1;
    required string value = 2;
    } *)

  TNameValue = class(TAbstractProtoBufClass)
  private
    FName: string;
    FValue: string;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property Name: string read FName write FName;
    property Value: string read FValue write FValue;
  end;

  TNameValues = class(TObjectList<TNameValue>)
  private
    function GetItemByName(const Name: string): TNameValue;
    function GetValue(const Name: string): string;
    procedure SetValue(const Name, Value: string);
  public
    function AddNew: TNameValue; overload;
    function AddNew(const Name, Value: string): TNameValue; overload;

    property Values[const Name: string]: string read GetValue write SetValue;
    property ItemByName[const Name: string]: TNameValue read GetItemByName;
  end;

  (* message TariffInfo {
    required string name = 1;
    repeated NameValue details = 2;
    } *)
  TTariffInfo = class(TAbstractProtoBufClass)
  private
    FDetails: TNameValues;
    FName: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property Name: string read FName write FName;
    property Details: TNameValues read FDetails;
  end;

  TInvoice = class(TAbstractProtoBufClass)
  private
    FFinalCost: Double;
    FWaitingMin: integer;
    FStartDateTime: TDateTime;
    FWayTimeByTrack: integer;
    FCostWaiting: Double;
    FAddresses: TStrings;
    FDetails: TNameValues;
    FTariffInfo: TTariffInfo;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property FinalCost: Double read FFinalCost write FFinalCost;
    property StartDateTime: TDateTime read FStartDateTime write FStartDateTime;
    property WaitingMin: integer read FWaitingMin write FWaitingMin;
    property CostWaiting: Double read FCostWaiting write FCostWaiting;
    property WayTimeByTrack: integer read FWayTimeByTrack write FWayTimeByTrack;
    property Addresses: TStrings read FAddresses write FAddresses;

    property TariffInfo: TTariffInfo read FTariffInfo;
    property Details: TNameValues read FDetails;
  end;

  (*
    message WorkshiftStatistics {
    required float threshold = 1;
    required float balance = 2;
    }
    *)
  TDriverBalanceInfo = class(TAbstractProtoBufClass)
  private
    FTreshold: Double;
    FBalance: Double;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property Treshold: Double read FTreshold write FTreshold;
    property Balance: Double read FBalance write FBalance;
  end;

  (* message ActualOrder {
    message WayPoint {
    required double latitude = 1;
    required double longitude = 2;
    required string text = 3;
    }
    required int64 id = 1;
    required int64 startDateTime = 2;
    repeated WayPoint wayPoints = 3;
    } *)

  TActualOrder = class(TAbstractProtoBufClass)
  private
    FStartDateTime: TDateTime;
    FWayPoints: TMobileWayPoints;
    FID: Int64;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property ID: Int64 read FID write FID;
    property StartDateTime: TDateTime read FStartDateTime write FStartDateTime;
    property WayPoints: TMobileWayPoints read FWayPoints;
  end;

  (* message ActualOrders {
    repeated ActualOrder orders = 1;
    } *)
  TActualOrders = class(TAbstractProtoBufClass)
  private
    FActualOrders: TObjectList<TActualOrder>;
    function GetOrder(ItemIndex: integer): TActualOrder;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    function AddNew: TActualOrder;

    property ActualOrders[ItemIndex: integer]: TActualOrder read GetOrder; default;
  end;

  (* message MobileOrderRequest{
    required int64 orderID = 1;
    } *)
  TMobileOrderRequest = class(TAbstractProtoBufClass)
  private
    FOrderID: Int64;
  public
    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property OrderID: Int64 read FOrderID write FOrderID;
  end;

  (* message Section {
    required string title = 1;
    repeated NameValue rows = 2;
    } *)
  TSection = class(TAbstractProtoBufClass)
  private
    FRows: TNameValues;
    FTitle: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property Title: string read FTitle write FTitle;
    property rows: TNameValues read FRows;
  end;

  (* message DriverInfo {
    repeated Section sections = 1;
    } *)

  TDriverInfo = class(TAbstractProtoBufClass)
  private
    FSections: TObjectList<TSection>;
    function GetSection(Index: integer): TSection;
  public
    constructor Create;
    destructor Destroy; override;

    function AddNew: TSection;
    procedure Delete(I: integer);

    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;
    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;

    property Sections[Index: integer]: TSection read GetSection;
  end;

function SwapEndian(Value: integer): integer;

implementation

uses
  DateUtils,
  uCommonFunctions;

function SwapEndian(Value: integer): integer;
var
  bx: LongRec;
begin
  bx := LongRec(Value);

  LongRec(Result).Bytes[0] := bx.Bytes[3];
  LongRec(Result).Bytes[1] := bx.Bytes[2];
  LongRec(Result).Bytes[2] := bx.Bytes[1];
  LongRec(Result).Bytes[3] := bx.Bytes[0];
end;

{ TOutPacketStreamBigEndian }

procedure TOutPacketStreamBigEndian.DoHeaderPrepared;
begin
  inherited;
  FPacketHeader.DataSize := SwapEndian(FPacketHeader.DataSize);
end;

{ TInPacketStreamBigEndian }

procedure TInPacketStreamBigEndian.DoHeaderReceived;
begin
  inherited;
  FPacketHeader.DataSize := SwapEndian(FPacketHeader.DataSize);
end;

{ TErrorMessage }

procedure TErrorMessage.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FCode := ProtoBuf.readInt32;
          end;
        2:
          begin
            FDescription := Utf8ToAnsi(ProtoBuf.readString);
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TErrorMessage.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt32(1, FCode);
  ProtoBuf.writeString(2, AnsiToUtf8(FDescription));
end;

{ TAuthRequest }

procedure TAuthRequest.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FVersion := ProtoBuf.readInt32;
          end;
        2:
          begin
            FPassword := Utf8ToAnsi(ProtoBuf.readString);
          end
        else
          ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TAuthRequest.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt32(1, FVersion);
  // ProtoBuf.writeInt32(2, 12);
  ProtoBuf.writeString(2, AnsiToUtf8(FPassword));
end;

{ TAuthAnswer }

procedure TAuthAnswer.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FIsAccepted := ProtoBuf.readBoolean;
          end;
        2:
          begin
            FReason := Utf8ToAnsi(ProtoBuf.readString);
          end;
        3:
          begin
            FErrorCode := ProtoBuf.readInt32;
          end;
        4:
          begin
            FDebugMsg := Utf8ToAnsi(ProtoBuf.readString);
          end
        else
          ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TAuthAnswer.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeBoolean(1, FIsAccepted);
  ProtoBuf.writeString(2, AnsiToUtf8(FReason));
  ProtoBuf.writeInt32(3, FErrorCode);
  ProtoBuf.writeString(4, AnsiToUtf8(FDebugMsg));
end;

{ TMobileAuthRequest }

procedure TMobileAuthRequest.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FLoginID := ProtoBuf.readInt64;
          end;
        2:
          begin
            FAuthKey := Utf8ToAnsi(ProtoBuf.readString);
          end;
        3:
          begin
            FSessionID := Utf8ToAnsi(ProtoBuf.readString);
          end;
        4:
          begin
            FCallsign := Utf8ToAnsi(ProtoBuf.readString);
          end;
        5:
          begin
            FPassword := Utf8ToAnsi(ProtoBuf.readString);
          end;
        6:
          begin
            FprotocolVersionMajor := ProtoBuf.readInt32;
          end;
        7:
          begin
            FprotocolVersionMinor := ProtoBuf.readInt32;
          end
        else
          ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileAuthRequest.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt64(1, FLoginID);
  ProtoBuf.writeString(2, AnsiToUtf8(FAuthKey));
  ProtoBuf.writeString(3, AnsiToUtf8(FSessionID));
  ProtoBuf.writeString(4, AnsiToUtf8(FCallsign));
  ProtoBuf.writeString(5, AnsiToUtf8(FPassword));
  ProtoBuf.writeInt32(6, FprotocolVersionMajor);
  ProtoBuf.writeInt32(7, FprotocolVersionMinor);
end;

{ TMobileAuthAnswer }

constructor TMobileAuthAnswer.Create;
begin
  inherited Create;
  FMobileContext := TMobileContext.Create;
end;

destructor TMobileAuthAnswer.Destroy;
begin
  FreeAndNil(FMobileContext);
  inherited;
end;

procedure TMobileAuthAnswer.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FIsAccepted := ProtoBuf.readBoolean;
          end;
        2:
          begin
            FCallsign := Utf8ToAnsi(ProtoBuf.readString);
          end;
        3:
          begin
            FSessionID := Utf8ToAnsi(ProtoBuf.readString);
          end;
        4:
          FReason := Utf8ToAnsi(ProtoBuf.readString);
        5:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FMobileContext.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileAuthAnswer.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
begin
  inherited;
  ProtoBuf.writeBoolean(1, FIsAccepted);
  ProtoBuf.writeString(2, AnsiToUtf8(FCallsign));
  ProtoBuf.writeString(3, AnsiToUtf8(FSessionID));
  ProtoBuf.writeString(4, AnsiToUtf8(FReason));

  if IsAccepted then
    begin
      tmpBuf := TProtoBufOutput.Create;
      try
        FMobileContext.SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(5, tmpBuf);
      finally
        tmpBuf.Free;
      end;
    end;
end;

{ TCommunicationHeader }
{ required string sessionID = 1;
  required string callsign = 2;
  required int64 messageID = 3;
  optional int32 lifetime = 4; //lifetime }
procedure TCommunicationHeader.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FSessionID := Utf8ToAnsi(ProtoBuf.readString);
          end;
        2:
          begin
            FCallsign := Utf8ToAnsi(ProtoBuf.readString);
          end;
        3:
          begin
            FMessageID := ProtoBuf.readInt64;
          end;
        4:
          begin
            FLifetime := ProtoBuf.readInt32;
          end
        else
          ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TCommunicationHeader.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  inherited;
  ProtoBuf.writeString(1, AnsiToUtf8(FSessionID));
  ProtoBuf.writeString(2, AnsiToUtf8(FCallsign));
  ProtoBuf.writeInt64(3, FMessageID);
  ProtoBuf.writeInt32(4, FLifetime);
end;

{ TTrackRecord }

procedure TTrackRecord.LoadFromBuf(ProtoBuf: TProtoBufInput);
{ required int64 timestamp = 1;
  required double latitude = 2;
  required double longitude = 3;
  required float speed = 4;
  required float accuracy = 5; }
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            Fdt := UTCToLocalTime(UnixToDateTime(ProtoBuf.readInt64));
          end;
        2:
          begin
            FLat := ProtoBuf.readDouble;
          end;
        3:
          begin
            FLon := ProtoBuf.readDouble;
          end;
        4:
          begin
            FSpeed := ProtoBuf.readFloat;
          end;
        5:
          begin
            FAccuracy := ProtoBuf.readFloat;
          end
        else
          ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TTrackRecord.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  { required int64 timestamp = 1;
    required double latitude = 2;
    required double longitude = 3;
    required float speed = 4;
    required float accuracy = 5; }
  inherited;
  ProtoBuf.writeInt64(1, DateTimeToUnix(LocalTimeToUTC(Fdt)));
  ProtoBuf.writeDouble(2, FLat);
  ProtoBuf.writeDouble(3, FLon);
  ProtoBuf.writeFloat(4, FSpeed);
  ProtoBuf.writeFloat(5, FAccuracy);
end;

{ TMobileDriverStatus }

constructor TMobileDriverStatus.Create;
begin
  inherited Create;
  FMobileTripStatus := TMobileTripStatus.Create;
end;

destructor TMobileDriverStatus.Destroy;
begin
  FreeAndNil(FMobileTripStatus);
  inherited;
end;

procedure TMobileDriverStatus.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FMobileTripStatus.FTripStatus := TTripStatus(0);
  FMobileTripStatus.FOrderID := 0;

  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FWorkshiftStatus := TMobileWSStatus(ProtoBuf.readEnum);
          end;
        2:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FMobileTripStatus.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileDriverStatus.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
begin
  ProtoBuf.writeInt32(1, integer(FWorkshiftStatus));

  if Assigned(FMobileTripStatus) then
    if (FMobileTripStatus.TripStatus <> mtsUndefined) and (FMobileTripStatus.OrderID <> 0) then
      begin
        tmpBuf := TProtoBufOutput.Create;
        try
          FMobileTripStatus.SaveToBuf(tmpBuf);
          ProtoBuf.writeMessage(2, tmpBuf);
        finally
          tmpBuf.Free;
        end;
      end;
end;

{ TMobileTripStatus }

procedure TMobileTripStatus.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FOrderID := ProtoBuf.readInt64;
          end;
        2:
          begin
            FTripStatus := TTripStatus(ProtoBuf.readEnum);
          end;
        3:
          begin
            FReason := Utf8ToAnsi(ProtoBuf.readString);
          end
        else
          ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileTripStatus.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt64(1, FOrderID);
  ProtoBuf.writeInt32(2, integer(FTripStatus));
  ProtoBuf.writeString(3, AnsiToUtf8(FReason));
end;

{ TCallRequest }

procedure TCallRequest.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FLinkType := TLinkType(ProtoBuf.readEnum);
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TCallRequest.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt32(1, integer(FLinkType));
end;

{ TMobileClient }

procedure TMobileClient.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FClientName := Utf8ToAnsi(ProtoBuf.readString);
          end;
        2:
          begin
            FPhone := Utf8ToAnsi(ProtoBuf.readString);
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileClient.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeString(1, AnsiToUtf8(FClientName));
  ProtoBuf.writeString(2, AnsiToUtf8(FPhone));
end;

{ TMobileWayPoint }

procedure TMobileWayPoint.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FLatitude := ProtoBuf.readDouble;
          end;
        2:
          begin
            FLongitude := ProtoBuf.readDouble;
          end;
        3:
          begin
            FText := Utf8ToAnsi(ProtoBuf.readString);
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileWayPoint.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeDouble(1, FLatitude);
  ProtoBuf.writeDouble(2, FLongitude);
  ProtoBuf.writeString(3, AnsiToUtf8(FText));
end;

{ TMobileOrder }

constructor TMobileOrder.Create;
begin
  inherited Create;
  FClient := TMobileClient.Create;
  FWayPoints := TMobileWayPoints.Create(True);
end;

destructor TMobileOrder.Destroy;
begin
  FreeAndNil(FWayPoints);
  FreeAndNil(FClient);
  inherited;
end;

procedure TMobileOrder.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber { , wireType } : integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FWayPoints.Clear;

  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FOrderID := ProtoBuf.readInt64;
          end;
        2:
          begin
            FCost := ProtoBuf.readFloat;
          end;
        3:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FClient.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
        4:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FWayPoints.AddNew.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
        5:
          FProposal := ProtoBuf.readBoolean;
        6:
          begin
            FStartDateTime := UTCToLocalTime(UnixToDateTime(ProtoBuf.readInt64));
          end;
        7:
          FNote := Utf8ToAnsi(ProtoBuf.readString);
        8:
          FTripStatus := TTripStatus(ProtoBuf.readEnum);
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileOrder.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
  I: integer;
begin
  ProtoBuf.writeInt64(1, FOrderID);
  ProtoBuf.writeFloat(2, FCost);

  tmpBuf := TProtoBufOutput.Create;
  try
    FClient.SaveToBuf(tmpBuf);
    ProtoBuf.writeMessage(3, tmpBuf);

    for I := 0 to FWayPoints.Count - 1 do
      begin
        tmpBuf.Clear;
        FWayPoints[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(4, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;

  ProtoBuf.writeBoolean(5, FProposal);
  ProtoBuf.writeInt64(6, DateTimeToUnix(LocalTimeToUTC(FStartDateTime)));
  ProtoBuf.writeString(7, AnsiToUtf8(FNote));
  ProtoBuf.writeInt32(8, integer(FTripStatus));
end;

{ TMobileWayPoints }

function TMobileWayPoints.AddNew: TMobileWayPoint;
begin
  Result := TMobileWayPoint.Create;
  Add(Result);
end;

{ TMobileContext }

constructor TMobileContext.Create;
begin
  inherited Create;
  FMobileStatus := TMobileDriverStatus.Create;
  FOrder := TMobileOrder.Create;
end;

destructor TMobileContext.Destroy;
begin
  FreeAndNil(FOrder);
  FreeAndNil(FMobileStatus);
  inherited;
end;

procedure TMobileContext.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber { , wireType } : integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FMobileStatus.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
        2:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FOrder.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileContext.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
begin
  tmpBuf := TProtoBufOutput.Create;
  try
    FMobileStatus.SaveToBuf(tmpBuf);
    ProtoBuf.writeMessage(1, tmpBuf);

    if Assigned(FOrder) then
      if FOrder.OrderID <> 0 then
        begin
          FOrder.SaveToBuf(tmpBuf);
          ProtoBuf.writeMessage(2, tmpBuf);
        end;
  finally
    tmpBuf.Free;
  end;
end;

{ TMobileTextMessage }

procedure TMobileTextMessage.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FMessageKind := TMobileTextMessageKind(ProtoBuf.readEnum);
          end;
        2:
          begin
            FSentAt := UTCToLocalTime(UnixToDateTime(ProtoBuf.readInt64));
          end;
        3:
          begin
            FSenderName := Utf8ToAnsi(ProtoBuf.readString);
          end;
        4:
          begin
            FRecepientName := Utf8ToAnsi(ProtoBuf.readString);
          end;
        5:
          begin
            FMessageText := Utf8ToAnsi(ProtoBuf.readString);
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileTextMessage.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt32(1, integer(FMessageKind));
  ProtoBuf.writeInt64(2, DateTimeToUnix(LocalTimeToUTC(FSentAt)));
  ProtoBuf.writeString(3, AnsiToUtf8(FSenderName));
  ProtoBuf.writeString(4, AnsiToUtf8(FRecepientName));
  ProtoBuf.writeString(5, AnsiToUtf8(FMessageText));
end;

{ TMobileOrders }

function TMobileOrders.AddNew: TMobileOrder;
begin
  Result := TMobileOrder.Create;
  FMobileOrders.Add(Result);
end;

constructor TMobileOrders.Create;
begin
  inherited Create;
  FMobileOrders := TObjectList<TMobileOrder>.Create;
end;

destructor TMobileOrders.Destroy;
begin
  FreeAndNil(FMobileOrders);
  inherited;
end;

function TMobileOrders.GetOrder(ItemIndex: integer): TMobileOrder;
begin
  Result := FMobileOrders[ItemIndex];
end;

procedure TMobileOrders.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber { , wireType } : integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FMobileOrders.Clear;

  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              AddNew.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileOrders.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
  I: integer;
begin
  tmpBuf := TProtoBufOutput.Create;
  try
    for I := 0 to FMobileOrders.Count - 1 do
      begin
        tmpBuf.Clear;
        FMobileOrders[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(1, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

{ TFailureReasonMsg }

procedure TFailureReasonMsg.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FID := ProtoBuf.readInt32;
          end;
        2:
          begin
            FText := Utf8ToAnsi(ProtoBuf.readString);
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TFailureReasonMsg.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt32(1, FID);
  ProtoBuf.writeString(2, AnsiToUtf8(FText));
end;

{ TFailureReasons }

function TFailureReasons.Add(frt: TFailureReasonType; frm: TFailureReasonMsg): integer;
begin
  if frt = frtPassenger then
    Result := FItemsPassenger.Add(frm)
  else
    if frt = frtDriver then
      Result := FItemsDriver.Add(frm)
    else
      raise EArgumentOutOfRangeException.Create('Failure reason type out of range');
end;

function TFailureReasons.AddNew(frt: TFailureReasonType): TFailureReasonMsg;
begin
  Result := TFailureReasonMsg.Create;
  try
    Add(frt, Result);
  except
    on e: Exception do
      begin
        FreeAndNil(Result);
        raise ;
      end;
  end;
end;

procedure TFailureReasons.Clear;
begin
  FItemsPassenger.Clear;
  FItemsDriver.Clear;
end;

constructor TFailureReasons.Create;
begin
  inherited Create;
  FItemsPassenger := TObjectList<TFailureReasonMsg>.Create(True);
  FItemsDriver := TObjectList<TFailureReasonMsg>.Create(True);
end;

procedure TFailureReasons.Delete(frt: TFailureReasonType; Index: integer);
begin
  if frt = frtPassenger then
    FItemsPassenger.Delete(Index)
  else
    if frt = frtDriver then
      FItemsDriver.Delete(Index)
    else
      raise EArgumentOutOfRangeException.Create('FailureReasonType out of range');
end;

destructor TFailureReasons.Destroy;
begin
  FreeAndNil(FItemsDriver);
  FreeAndNil(FItemsPassenger);
  inherited;
end;

function TFailureReasons.GetItemsOfDriver(Index: integer): TFailureReasonMsg;
begin
  Result := FItemsDriver[Index];
end;

function TFailureReasons.GetItemsOfPassenger(Index: integer): TFailureReasonMsg;
begin
  Result := FItemsPassenger[Index];
end;

procedure TFailureReasons.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber { , wireType } : integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  Clear;

  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              AddNew(frtPassenger).LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
        2:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              AddNew(frtDriver).LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TFailureReasons.Remove(frt: TFailureReasonType; frm: TFailureReasonMsg);
begin
  if frt = frtPassenger then
    FItemsPassenger.Remove(frm)
  else
    if frt = frtDriver then
      FItemsDriver.Remove(frm);
end;

procedure TFailureReasons.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
  I: integer;
begin
  tmpBuf := TProtoBufOutput.Create;
  try
    for I := 0 to FItemsPassenger.Count - 1 do
      begin
        tmpBuf.Clear;
        FItemsPassenger[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(1, tmpBuf);
      end;

    for I := 0 to FItemsDriver.Count - 1 do
      begin
        tmpBuf.Clear;
        FItemsDriver[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(2, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

{ TActualWSInfo }

procedure TActualWSInfo.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FNumberInQueue := ProtoBuf.readInt32;
          end;
        2:
          begin
            FDistrictName := Utf8ToAnsi(ProtoBuf.readString);
          end;
        3:
          begin
            FOrdersCount := ProtoBuf.readInt32;
          end
        else
          ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TActualWSInfo.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt32(1, FNumberInQueue);
  ProtoBuf.writeString(2, AnsiToUtf8(FDistrictName));
  ProtoBuf.writeInt32(3, FOrdersCount);
end;

{ TInvoice }

constructor TInvoice.Create;
begin
  inherited Create;
  FAddresses := TStringList.Create;
  FTariffInfo := TTariffInfo.Create;
  FDetails := TNameValues.Create;
end;

destructor TInvoice.Destroy;
begin
  FreeAndNil(FDetails);
  FreeAndNil(FTariffInfo);
  FreeAndNil(FAddresses);
  inherited;
end;

procedure TInvoice.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FAddresses.Clear;
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FFinalCost := ProtoBuf.readFloat;
          end;
        2:
          begin
            FStartDateTime := UTCToLocalTime(UnixToDateTime(ProtoBuf.readInt64));
          end;
        3:
          begin
            FWaitingMin := ProtoBuf.readInt32;
          end;
        4:
          begin
            FCostWaiting := ProtoBuf.readFloat;
          end;
        5:
          begin
            FWayTimeByTrack := ProtoBuf.readInt32;
          end;
        6:
          begin
            FAddresses.Add(Utf8ToAnsi(ProtoBuf.readString));
          end;
        7:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FTariffInfo.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
        8:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FDetails.AddNew.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end
        else
          ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TInvoice.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  I: integer;
  tmpBuf: TProtoBufOutput;
begin
  ProtoBuf.writeFloat(1, FFinalCost);
  ProtoBuf.writeInt64(2, DateTimeToUnix(LocalTimeToUTC(FStartDateTime)));
  ProtoBuf.writeInt32(3, FWaitingMin);
  ProtoBuf.writeFloat(4, FCostWaiting);
  ProtoBuf.writeInt32(5, FWayTimeByTrack);

  for I := 0 to FAddresses.Count - 1 do
    ProtoBuf.writeString(6, AnsiToUtf8(FAddresses[I]));

  tmpBuf := TProtoBufOutput.Create;
  try
    tmpBuf.Clear;
    FTariffInfo.SaveToBuf(tmpBuf);
    ProtoBuf.writeMessage(7, tmpBuf);

    for I := 0 to FDetails.Count - 1 do
      begin
        tmpBuf.Clear;
        FDetails[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(8, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

{ TNameValue }

procedure TNameValue.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FName := Utf8ToAnsi(ProtoBuf.readString);
          end;
        2:
          begin
            FValue := Utf8ToAnsi(ProtoBuf.readString);
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TNameValue.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeString(1, AnsiToUtf8(FName));
  ProtoBuf.writeString(2, AnsiToUtf8(FValue));
end;

{ TNameValues }

function TNameValues.AddNew(const Name, Value: string): TNameValue;
begin
  Result := AddNew;
  Result.Name := Name;
  Result.Value := Value;
end;

function TNameValues.AddNew: TNameValue;
begin
  Result := TNameValue.Create;
  Add(Result);
end;

function TNameValues.GetItemByName(const Name: string): TNameValue;
var
  I: integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if Items[I].Name = NAme then
      begin
        Result := Items[I];
        Break;
      end;
end;

function TNameValues.GetValue(const Name: string): string;
var
  tmp: TNameValue;
begin
  tmp := ItemByName[Name];
  if Assigned(tmp) then
    Result := tmp.Value
  else
    Result := '';
end;

procedure TNameValues.SetValue(const Name, Value: string);
var
  tmp: TNameValue;
begin
  tmp := ItemByName[Name];
  if Assigned(tmp) then
    tmp.Value := Value
  else
    AddNew(Name, Value);
end;

{ TTariffInfo }

constructor TTariffInfo.Create;
begin
  inherited Create;
  FDetails := TNameValues.Create;
end;

destructor TTariffInfo.Destroy;
begin
  FreeAndNil(FDetails);
  inherited;
end;

procedure TTariffInfo.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FDetails.Clear;
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FName := Utf8ToAnsi(ProtoBuf.readString)
          end;
        2:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FDetails.AddNew.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TTariffInfo.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  I: integer;
  tmpBuf: TProtoBufOutput;
begin
  ProtoBuf.writeString(1, AnsiToUtf8(FName));

  tmpBuf := TProtoBufOutput.Create;
  try
    for I := 0 to FDetails.Count - 1 do
      begin
        tmpBuf.Clear;
        FDetails[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(2, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

{ TDriverBalanceInfo }

procedure TDriverBalanceInfo.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FTreshold := ProtoBuf.readFloat;
          end;
        2:
          begin
            FBalance := ProtoBuf.readFloat;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TDriverBalanceInfo.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeFloat(1, FTreshold);
  ProtoBuf.writeFloat(2, FBalance);
end;

{ TActualOrder }

constructor TActualOrder.Create;
begin
  inherited Create;
  FWayPoints := TMobileWayPoints.Create;
end;

destructor TActualOrder.Destroy;
begin
  FreeAndNil(FWayPoints);
  inherited;
end;

procedure TActualOrder.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FWayPoints.Clear;
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FID := ProtoBuf.readInt64;
          end;
        2:
          begin
            FStartDateTime := UTCToLocalTime(UnixToDateTime(ProtoBuf.readInt64));
          end;
        3:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FWayPoints.AddNew.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TActualOrder.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  I: integer;
  tmpBuf: TProtoBufOutput;
begin
  ProtoBuf.writeInt64(1, FID);
  ProtoBuf.writeInt64(2, DateTimeToUnix(LocalTimeToUTC(FStartDateTime)));

  tmpBuf := TProtoBufOutput.Create;
  try
    for I := 0 to FWayPoints.Count - 1 do
      begin
        tmpBuf.Clear;
        FWayPoints[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(3, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

{ TActualOrders }

function TActualOrders.AddNew: TActualOrder;
begin
  Result := TActualOrder.Create;
  FActualOrders.Add(Result);
end;

constructor TActualOrders.Create;
begin
  inherited Create;
  FActualOrders := TObjectList<TActualOrder>.Create;
end;

destructor TActualOrders.Destroy;
begin
  FreeAndNil(FActualOrders);
  inherited;
end;

function TActualOrders.GetOrder(ItemIndex: integer): TActualOrder;
begin
  Result := FActualOrders[ItemIndex];
end;

procedure TActualOrders.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber { , wireType } : integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FActualOrders.Clear;

  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              AddNew.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TActualOrders.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
  I: integer;
begin
  tmpBuf := TProtoBufOutput.Create;
  try
    for I := 0 to FActualOrders.Count - 1 do
      begin
        tmpBuf.Clear;
        FActualOrders[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(1, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

{ TMobileOrderRequest }

procedure TMobileOrderRequest.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
begin
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FOrderID := ProtoBuf.readInt64;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TMobileOrderRequest.SaveToBuf(ProtoBuf: TProtoBufOutput);
begin
  ProtoBuf.writeInt64(1, FOrderID);
end;

{ TSection }

constructor TSection.Create;
begin
  inherited Create;
  FRows := TNameValues.Create;
end;

destructor TSection.Destroy;
begin
  FreeAndNil(FRows);
  inherited;
end;

procedure TSection.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber: integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FRows.Clear;
  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            FTitle := Utf8ToAnsi(ProtoBuf.readString);
          end;
        2:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              FRows.AddNew.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TSection.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
  I: integer;
begin
  ProtoBuf.writeString(1, AnsiToUtf8(FTitle));

  tmpBuf := TProtoBufOutput.Create;
  try
    for I := 0 to FRows.Count - 1 do
      begin
        tmpBuf.Clear;
        FRows[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(2, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

{ TDriverInfo }

function TDriverInfo.AddNew: TSection;
begin
  Result := TSection.Create;
  FSections.Add(Result);
end;

constructor TDriverInfo.Create;
begin
  inherited Create;
  FSections := TObjectList<TSection>.Create;
end;

procedure TDriverInfo.Delete(I: integer);
begin
  FSections.Delete(I);
end;

destructor TDriverInfo.Destroy;
begin
  FreeAndNil(FSections);
  inherited;
end;

function TDriverInfo.GetSection(Index: integer): TSection;
begin
  Result := FSections[Index];
end;

procedure TDriverInfo.LoadFromBuf(ProtoBuf: TProtoBufInput);
var
  fieldNumber { , wireType } : integer;
  Tag: integer;
  tmpBuf: TProtoBufInput;
begin
  FSections.Clear;

  Tag := ProtoBuf.readTag;
  while Tag <> 0 do
    begin
      // wireType := getTagWireType(Tag);
      fieldNumber := getTagFieldNumber(Tag);
      case fieldNumber of
        1:
          begin
            tmpBuf := ProtoBuf.ReadSubProtoBufInput;
            try
              AddNew.LoadFromBuf(tmpBuf);
            finally
              tmpBuf.Free;
            end;
          end;
      else
        ProtoBuf.skipField(Tag);
      end;
      Tag := ProtoBuf.readTag;
    end;
end;

procedure TDriverInfo.SaveToBuf(ProtoBuf: TProtoBufOutput);
var
  tmpBuf: TProtoBufOutput;
  I: integer;
begin
  tmpBuf := TProtoBufOutput.Create;
  try
    for I := 0 to FSections.Count - 1 do
      begin
        tmpBuf.Clear;
        FSections[I].SaveToBuf(tmpBuf);
        ProtoBuf.writeMessage(1, tmpBuf);
      end;
  finally
    tmpBuf.Free;
  end;
end;

end.
