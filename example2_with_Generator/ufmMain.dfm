object Form15: TForm15
  Left = 0
  Top = 0
  Caption = 'Example2'
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
    Height = 143
    Caption = 
      '1. Compile and run ProtoBufGenerator.exe'#13#10#13#10'2. Choose/Drag TestI' +
      'mport1.proto & Test1.proto file to ProtoBufGenerator.exe'#13#10'    Se' +
      't output folder - "example2_with_Generator"'#13#10#13#10'3. Press Generate' +
      ' button.'#13#10#13#10'Now you get 2 new files in this project directory - ' +
      'TestImport1.pas and Test1.pas.'#13#10'Or - you can use for test pre-lo' +
      'aded files.'#13#10#13#10'See in OnClick event handlers how to use generate' +
      'd files'
  end
  object btnSaveToPtotoBuf: TButton
    Left = 72
    Top = 169
    Width = 121
    Height = 25
    Caption = 'SaveToPtotoBuf'
    TabOrder = 0
    OnClick = btnSaveToPtotoBufClick
  end
  object btnLoadFromProtoBuf: TButton
    Left = 224
    Top = 169
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
