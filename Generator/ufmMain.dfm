object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'ProtoBufGenerator'
  ClientHeight = 131
  ClientWidth = 491
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    491
    131)
  TextHeight = 13
  object lblInput: TLabel
    Left = 8
    Top = 5
    Width = 96
    Height = 13
    Caption = 'Proto File(s)/Folder:'
  end
  object lblOutput: TLabel
    Left = 8
    Top = 50
    Width = 69
    Height = 13
    Caption = 'Output folder:'
  end
  object edProtoFileName: TEdit
    Left = 8
    Top = 23
    Width = 377
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    TextHint = 'Choose proto file(s) or a folder'
  end
  object btnOpenProtoFile: TButton
    Left = 391
    Top = 21
    Width = 35
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'File'
    TabOrder = 1
    OnClick = btnOpenProtoFileClick
  end
  object btnGenerate: TButton
    Left = 8
    Top = 97
    Width = 475
    Height = 34
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Generate'
    TabOrder = 2
    OnClick = btnGenerateClick
    ExplicitWidth = 442
  end
  object edOutputFolder: TEdit
    Left = 8
    Top = 69
    Width = 442
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    TextHint = 'Choose output folder'
    ExplicitWidth = 409
  end
  object btnChooseOutputFolder: TButton
    Left = 456
    Top = 66
    Width = 27
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 4
    OnClick = btnChooseOutputFolderClick
    ExplicitLeft = 423
  end
  object btnChooseProtoInputFolder: TButton
    Left = 432
    Top = 21
    Width = 51
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Folder'
    TabOrder = 5
    OnClick = btnChooseProtoInputFolderClick
  end
  object odProtoFile: TFileOpenDialog
    DefaultExtension = '.proto'
    FavoriteLinks = <>
    FileName = 'C:\Temp\ProtocolBuffers\ProtoBufCodeGenApp\messages.proto'
    FileTypes = <
      item
        DisplayName = 'ProtoBuf files'
        FileMask = '*.proto'
      end>
    Options = [fdoStrictFileTypes, fdoAllowMultiSelect, fdoPathMustExist, fdoFileMustExist]
    Title = 'Open ProtoBuf file(s)'
    Left = 296
    Top = 16
  end
end
