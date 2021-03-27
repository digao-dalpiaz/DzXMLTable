unit UFrmMain;

interface

uses FMX.Forms, DzXMLTable, FMX.StdCtrls, FMX.Controls.Presentation,
  System.Classes, FMX.Types, FMX.Controls, FMX.Layouts, FMX.ListBox;

type
  TFrmMain = class(TForm)
    L: TListBox;
    Label1: TLabel;
    BtnAdd: TButton;
    BtnMod: TButton;
    BtnDel: TButton;
    XT: TDzXMLTable;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnModClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure LItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure LDblClick(Sender: TObject);
  private
    procedure LoadList;
    procedure UpdButtons;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.fmx}

uses UFrmContact, System.SysUtils,
  FMX.Dialogs, FMX.DialogService, System.UITypes;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  XT.FileName := ExtractFilePath(ParamStr(0))+'..\..\Contacts.xml';
  XT.Load;

  LoadList;
  UpdButtons;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  XT.Save;
end;

procedure TFrmMain.LItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  UpdButtons;
end;

procedure TFrmMain.LDblClick(Sender: TObject);
begin
  if BtnMod.Enabled then
    BtnModClick(nil);
end;

procedure TFrmMain.LoadList;
var
  R: TDzRecord;
begin
  for R in XT do
    L.Items.Add(R['Name']);
end;

procedure TFrmMain.UpdButtons;
begin
  BtnMod.Enabled := L.Selected <> nil;
  BtnDel.Enabled := L.Selected <> nil;
end;

procedure TFrmMain.BtnAddClick(Sender: TObject);
var
  R: TDzRecord;
begin
  if DoEditContact(False, R) then
    L.Items.Add(R['Name']);
end;

procedure TFrmMain.BtnModClick(Sender: TObject);
var
  R: TDzRecord;
begin
  R := XT[L.Selected.Index];
  if DoEditContact(True, R) then
    L.Selected.Text := R['Name'];
end;

procedure TFrmMain.BtnDelClick(Sender: TObject);
var
  R: TDzRecord;
begin
  R := XT[L.Selected.Index];

  TDialogService.MessageDialog(
    Format('Do you want to delete contact "%s"?', [R['Name']]),
    TMsgDlgType.mtConfirmation, mbYesNo, TMsgDlgBtn.mbNo, 0,
    procedure (const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        XT.Delete(L.Selected.Index);
        L.Items.Delete(L.Selected.Index);

        UpdButtons;
      end;
    end);
end;

end.
