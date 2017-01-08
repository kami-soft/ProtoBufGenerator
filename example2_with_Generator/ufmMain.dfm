object Form15: TForm15
  Left = 0
  Top = 0
  Caption = 'Form15'
  ClientHeight = 250
  ClientWidth = 430
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  PixelsPerInch = 96
  TextHeight = 13
  object lblDescription: TLabel
    Left = 16
    Top = 8
    Width = 395
    Height = 130
    Caption = 
      'First, compile and run ProtoBufGenerator.exe'#13#10'Choose TestImport1' +
      '.proto file and output folder - "example2_with_Generator"'#13#10'Press' +
      ' Generate button.'#13#10'Choose Test1.proto file'#13#10'Press Generate butto' +
      'n'#13#10'Now you get 2 new files in this project directory - TestImpor' +
      't1.pas and Test1.pas.'#13#10#13#10'Or - you can use for test pre-loaded fi' +
      'les.'#13#10#13#10'See in OnClick event handlers how to use generated files'
  end
  object btnSaveToPtotoBuf: TButton
    Left = 72
    Top = 160
    Width = 121
    Height = 25
    Caption = 'SaveToPtotoBuf'
    TabOrder = 0
    OnClick = btnSaveToPtotoBufClick
  end
  object btnLoadFromProtoBuf: TButton
    Left = 216
    Top = 160
    Width = 121
    Height = 25
    Caption = 'LoadFromProtoBuf'
    TabOrder = 1
    OnClick = btnLoadFromProtoBufClick
  end
  object btnSpeedTest: TButton
    Left = 168
    Top = 208
    Width = 75
    Height = 25
    Hint = 'Save and load arrays of 10 000 strings and 10 000 integers'
    Caption = 'Speed Test'
    TabOrder = 2
    OnClick = btnSpeedTestClick
  end
end
