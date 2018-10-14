object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'ProtoBufGenerator'
  ClientHeight = 213
  ClientWidth = 452
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    452
    213)
  PixelsPerInch = 96
  TextHeight = 13
  object lblBaseClassName: TLabel
    Left = 8
    Top = 8
    Width = 75
    Height = 13
    Caption = 'BaseClassName'
  end
  object edProtoFileName: TEdit
    Left = 8
    Top = 56
    Width = 403
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    TextHint = 'Choose proto file'
  end
  object btnOpenProtoFile: TButton
    Left = 417
    Top = 54
    Width = 27
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 1
    OnClick = btnOpenProtoFileClick
  end
  object btnGenerate: TButton
    Left = 8
    Top = 128
    Width = 436
    Height = 77
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Generate'
    TabOrder = 2
    OnClick = btnGenerateClick
    ExplicitWidth = 442
  end
  object edOutputFolder: TEdit
    Left = 8
    Top = 93
    Width = 403
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    TextHint = 'Choose output folder'
  end
  object btnChooseOutputFolder: TButton
    Left = 417
    Top = 91
    Width = 27
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 4
    OnClick = btnChooseOutputFolderClick
  end
  object cbbBaseClassName: TComboBox
    Left = 8
    Top = 21
    Width = 403
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
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
