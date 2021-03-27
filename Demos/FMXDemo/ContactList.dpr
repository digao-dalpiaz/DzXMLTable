program ContactList;

uses
  System.StartUpCopy,
  FMX.Forms,
  UFrmMain in 'UFrmMain.pas' {FrmMain},
  UFrmContact in 'UFrmContact.pas' {FrmContact};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
