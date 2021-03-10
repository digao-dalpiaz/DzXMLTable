unit DzXMLTable;

interface

uses System.Classes, System.Generics.Collections, Xml.XMLIntf;

const
  STR_XML_DATA_IDENT = 'data';
  STR_XML_RECORD_IDENT = 'record';

type
  TDzXMLTable = class;

  TDzField = class
  private
    FName: string;
    FValue: Variant;
  public
    property Name: string read FName;
    property Value: Variant read FValue write FValue;
  end;

  TDzRecord = class
  private
    Table: TDzXMLTable;

    Fields: TObjectList<TDzField>;

    function GetField(const Name: string): Variant;
    procedure SetField(const Name: string; const Value: Variant);

    function GetFieldIdx(Index: Integer): TDzField;
    function GetFieldCount: Integer;
  public
    constructor Create(Table: TDzXMLTable);
    destructor Destroy; override;

    property Field[const Name: string]: Variant read GetField write SetField; default;
    property FieldIdx[Index: Integer]: TDzField read GetFieldIdx;

    property FieldCount: Integer read GetFieldCount;

    function GetEnumerator: TEnumerator<TDzField>;

    function ReadDef(const Name: string; const DefValue: Variant): Variant;

    function FindField(const Name: string): TDzField;
    function FieldExists(const Name: string): Boolean;

    procedure ClearFields;
  end;

  TDzXMLTable = class(TComponent)
  private
    Data: TObjectList<TDzRecord>;

    FFileMustExist: Boolean;
    FFileName: string;

    FFieldMustExist: Boolean;

    procedure ReadRecord(N: IXMLNode);

    function GetRecCount: Integer;
    function GetRecord(Index: Integer): TDzRecord;
  public
    property Rec[Index: Integer]: TDzRecord read GetRecord; default;
    property RecCount: Integer read GetRecCount;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property FileMustExist: Boolean read FFileMustExist write FFileMustExist default False;
    property FileName: string read FFileName write FFileName;

    property FieldMustExist: Boolean read FFieldMustExist write FFieldMustExist default False;

    procedure Load;
    procedure Save;

    function New(Index: Integer = -1): TDzRecord;
    procedure Delete(Index: Integer);

    function FindRecByField(const Name: string; Value: Variant): TDzRecord;

    function GetEnumerator: TEnumerator<TDzRecord>;

    procedure MoveRec(CurIndex, NewIndex: Integer);
  end;

implementation

uses Xml.XMLDoc, System.SysUtils, System.Variants;

constructor TDzXMLTable.Create(AOwner: TComponent);
begin
  inherited;
  Data := TObjectList<TDzRecord>.Create;
end;

destructor TDzXMLTable.Destroy;
begin
  Data.Free;
  inherited;
end;

procedure TDzXMLTable.Load;
var
  X: TXMLDocument;
  Root: IXMLNode;
  I: Integer;
begin
  Data.Clear;

  X := TXMLDocument.Create(Self);
  try
    if not ((not FFileMustExist) and (not FileExists(FFileName))) then
      X.LoadFromFile(FFileName);

    Root := X.DocumentElement;
    if Root.NodeName<>STR_XML_DATA_IDENT then
      raise Exception.Create('Invalid root element name');

    for I := 0 to Root.ChildNodes.Count-1 do
      ReadRecord(Root.ChildNodes[I]);

  finally
    X.Free;
  end;
end;

procedure TDzXMLTable.ReadRecord(N: IXMLNode);
var
  I: Integer;
  R: TDzRecord;
  F: TDzField;
  XMLFld: IXMLNode;
begin
  if N.NodeName<>STR_XML_RECORD_IDENT then
    raise Exception.Create('Invalid record element name');

  R := TDzRecord.Create(Self);
  Data.Add(R);

  for I := 0 to N.ChildNodes.Count-1 do
  begin
    F := TDzField.Create;
    R.Fields.Add(F);

    XMLFld := N.ChildNodes[I];

    F.FName := XMLFld.NodeName;
    F.FValue := XMLFld.NodeValue;

    if VarIsNull(F.FValue) then F.FValue := Unassigned;
  end;
end;

procedure TDzXMLTable.Save;
var
  X: TXMLDocument;
  Root, XMLRec: IXMLNode;

  R: TDzRecord;
  F: TDzField;
begin
  X := TXMLDocument.Create(Self);
  try
    X.Active := True;

    Root := X.AddChild(STR_XML_DATA_IDENT);

    for R in Data do
    begin
      XMLRec := Root.AddChild(STR_XML_RECORD_IDENT);

      for F in R.Fields do
        XMLRec.AddChild(F.FName).NodeValue := F.FValue;
    end;

    X.SaveToFile(FFileName);
  finally
    X.Free;
  end;
end;

function TDzXMLTable.GetRecord(Index: Integer): TDzRecord;
begin
  Result := Data[Index];
end;

function TDzXMLTable.GetRecCount: Integer;
begin
  Result := Data.Count;
end;

function TDzXMLTable.GetEnumerator: TEnumerator<TDzRecord>;
begin
  Result := Data.GetEnumerator;
end;

function TDzXMLTable.New(Index: Integer): TDzRecord;
begin
  Result := TDzRecord.Create(Self);
  if Index = -1 then
    Data.Add(Result)
  else
    Data.Insert(Index, Result);
end;

procedure TDzXMLTable.Delete(Index: Integer);
begin
  Data.Delete(Index);
end;

procedure TDzXMLTable.MoveRec(CurIndex, NewIndex: Integer);
begin
  Data.Move(CurIndex, NewIndex);
end;

function TDzXMLTable.FindRecByField(const Name: string;
  Value: Variant): TDzRecord;
var
  R: TDzRecord;
  F: TDzField;
begin
  for R in Data do
  begin
    F := R.FindField(Name);
    if F<>nil then
      if F.FValue = Value then Exit(R);
  end;

  Exit(nil);
end;

{ TDzRecord }

constructor TDzRecord.Create(Table: TDzXMLTable);
begin
  Self.Table := Table;

  Fields := TObjectList<TDzField>.Create;
end;

destructor TDzRecord.Destroy;
begin
  Fields.Free;
end;

procedure TDzRecord.ClearFields;
begin
  Fields.Clear;
end;

function TDzRecord.GetEnumerator: TEnumerator<TDzField>;
begin
  Result := Fields.GetEnumerator;
end;

function TDzRecord.FindField(const Name: string): TDzField;
var
  F: TDzField;
begin
  for F in Fields do
    if SameText(F.FName, Name) then Exit(F);

  Exit(nil);
end;

function TDzRecord.FieldExists(const Name: string): Boolean;
begin
  Result := FindField(Name) <> nil;
end;

function TDzRecord.GetField(const Name: string): Variant;
var
  F: TDzField;
begin
  F := FindField(Name);
  if F=nil then
  begin
    if Table.FFieldMustExist then
      raise Exception.CreateFmt('Field "%s" not found', [Name]);

    Result := Unassigned;
  end else
    Result := F.FValue;
end;

function TDzRecord.GetFieldCount: Integer;
begin
  Result := Fields.Count;
end;

function TDzRecord.ReadDef(const Name: string; const DefValue: Variant): Variant;
var
  F: TDzField;
begin
  F := FindField(Name);
  if F=nil then
    Result := DefValue
  else
    Result := F.FValue;
end;

procedure TDzRecord.SetField(const Name: string; const Value: Variant);
var
  F: TDzField;
begin
  F := FindField(Name);
  if F=nil then
  begin
    F := TDzField.Create;
    Fields.Add(F);

    F.FName := Name;
  end;
  F.FValue := Value
end;

function TDzRecord.GetFieldIdx(Index: Integer): TDzField;
begin
  Result := Fields[Index];
end;

end.
