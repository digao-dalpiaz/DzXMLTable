unit UFrmContact;

interface

uses FMX.Forms, FMX.StdCtrls, FMX.Edit, System.Classes, FMX.Types, FMX.Controls,
  FMX.Controls.Presentation,
  //
  DzXMLTable;

type
  TFrmContact = class(TForm)
    Label1: TLabel;
    EdName: TEdit;
    Label2: TLabel;
    EdAddress: TEdit;
    Label3: TLabel;
    EdPhone: TEdit;
    CkEnabled: TCheckBox;
    BtnOK: TButton;
    BtnCancel: TButton;
    procedure FormShow(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
  private
    Edit: Boolean;
    Rec: TDzRecord;
    function NameAlreadyExists: Boolean;
  end;

var
  FrmContact: TFrmContact;

function DoEditContact(Edit: Boolean; var Rec: TDzRecord): Boolean;

implementation

{$R *.fmx}

uses UFrmMain, System.SysUtils, System.UITypes, FMX.DialogService;

function DoEditContact(Edit: Boolean; var Rec: TDzRecord): Boolean;
begin
  FrmContact := TFrmContact.Create(Application);
  FrmContact.Edit := Edit;
  FrmContact.Rec := Rec;
  Result := FrmContact.ShowModal = mrOk;
  Rec := FrmContact.Rec;
  FrmContact.Free;
end;

//

procedure TFrmContact.FormShow(Sender: TObject);
begin
  if Edit then
  begin
    Caption := 'Edit Contact';

    EdName.Text := Rec['Name'];
    EdAddress.Text := Rec['Address'];
    EdPhone.Text := Rec['Phone'];
    CkEnabled.IsChecked := Rec['Enabled'];
  end;
end;

procedure TFrmContact.BtnOKClick(Sender: TObject);
begin
  EdName.Text := Trim(EdName.Text);
  if EdName.Text.IsEmpty then
  begin
    TDialogService.ShowMessage('Name is blank');
    EdName.SetFocus;
    Exit;
  end;

  if NameAlreadyExists then
  begin
    TDialogService.ShowMessage('This name is already in use by another contact');
    EdName.SetFocus;
    Exit;
  end;


  if not Edit then
    Rec := FrmMain.XT.New;

  Rec['Name'] := EdName.Text;
  Rec['Address'] := EdAddress.Text;
  Rec['Phone'] := EdPhone.Text;
  Rec['Enabled'] := CkEnabled.IsChecked;

  ModalResult := mrOk;
end;

function TFrmContact.NameAlreadyExists: Boolean;
var
  Index: Integer;
begin
  Index := FrmMain.XT.FindSameText('Name', EdName.Text);
  Result := (Index<>-1) and not (Edit and (Index=FrmMain.L.Selected.Index));
end;

end.
