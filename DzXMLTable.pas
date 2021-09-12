{------------------------------------------------------------------------------
TDzXMLTable component
Developed by Rodrigo Depine Dalpiaz (digao dalpiaz)
Flexible dynamic table stored as XML file

https://github.com/digao-dalpiaz/DzXMLTable

Please, read the documentation at GitHub link.
------------------------------------------------------------------------------}

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
    FAbout: string;

    Data: TObjectList<TDzRecord>;

    FRequiredFile: Boolean;
    FFileName: string;

    FRequiredField: Boolean;

    procedure ReadRecord(N: IXMLNode);

    function GetRecCount: Integer;
    function GetRecord(Index: Integer): TDzRecord;

    function GetRecordOrNilByIndex(Index: Integer): TDzRecord;
  public
    property Rec[Index: Integer]: TDzRecord read GetRecord; default;
    property RecCount: Integer read GetRecCount;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;

    procedure Load;
    procedure Save;

    function New(Index: Integer = -1): TDzRecord;
    procedure Delete(Index: Integer);

    function FindIdxByField(const Name: string; const Value: Variant): Integer;
    function FindRecByField(const Name: string; const Value: Variant): TDzRecord;

    function FindIdxBySameText(const Name: string; const Value: string): Integer;
    function FindRecBySameText(const Name: string; const Value: string): TDzRecord;

    function GetEnumerator: TEnumerator<TDzRecord>;

    procedure Move(CurIndex, NewIndex: Integer);
  published
    property RequiredFile: Boolean read FRequiredFile write FRequiredFile default False;
    property FileName: string read FFileName write FFileName;

    property RequiredField: Boolean read FRequiredField write FRequiredField default False;
  end;

procedure Register;

implementation

uses Xml.XMLDoc, System.SysUtils, System.Variants;

const STR_VERSION = '1.2';

procedure Register;
begin
  RegisterComponents('Digao', [TDzXMLTable]);
end;

//

constructor TDzXMLTable.Create(AOwner: TComponent);
begin
  inherited;
  FAbout := 'Digao Dalpiaz / Version '+STR_VERSION;

  Data := TObjectList<TDzRecord>.Create;
end;

destructor TDzXMLTable.Destroy;
begin
  Data.Free;

  inherited;
end;

procedure TDzXMLTable.Clear;
begin
  Data.Clear;
end;

procedure TDzXMLTable.Load;
var
  X: TXMLDocument;
  Root: IXMLNode;
  I: Integer;
begin
  Data.Clear;

  if (not FRequiredFile) and (not FileExists(FFileName)) then Exit;

  X := TXMLDocument.Create(Self);
  try
    X.LoadFromFile(FFileName);

    Root := X.DocumentElement;
    if Root.NodeName<>STR_XML_DATA_IDENT then
      raise Exception.CreateFmt('Invalid root element name (expected "%s", found "%s")',
        [STR_XML_DATA_IDENT, Root.NodeName]);

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
    raise Exception.CreateFmt('Invalid record element name (expected "%s", found "%s")',
      [STR_XML_RECORD_IDENT, N.NodeName]);

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

function TDzXMLTable.GetRecordOrNilByIndex(Index: Integer): TDzRecord;
begin
  if Index<>-1 then
    Result := Data[Index]
  else
    Result := nil;
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

procedure TDzXMLTable.Move(CurIndex, NewIndex: Integer);
begin
  Data.Move(CurIndex, NewIndex);
end;

function TDzXMLTable.FindIdxByField(const Name: string;
  const Value: Variant): Integer;
var
  I: Integer;
  F: TDzField;
begin
  for I := 0 to Data.Count-1 do
  begin
    F := Data[I].FindField(Name);
    if F<>nil then
      if F.FValue = Value then Exit(I);
  end;

  Exit(-1);
end;

function TDzXMLTable.FindIdxBySameText(const Name, Value: string): Integer;
var
  I: Integer;
  F: TDzField;
begin
  for I := 0 to Data.Count-1 do
  begin
    F := Data[I].FindField(Name);
    if F<>nil then
      if SameText(F.FValue, Value) then Exit(I);
  end;

  Exit(-1);
end;

function TDzXMLTable.FindRecByField(const Name: string;
  const Value: Variant): TDzRecord;
begin
  Result := GetRecordOrNilByIndex(FindIdxByField(Name, Value));
end;

function TDzXMLTable.FindRecBySameText(const Name, Value: string): TDzRecord;
begin
  Result := GetRecordOrNilByIndex(FindIdxBySameText(Name, Value));
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
    if Table.FRequiredField then
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
