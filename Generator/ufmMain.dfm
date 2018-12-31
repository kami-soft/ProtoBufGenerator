object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'ProtoBufGenerator'
  ClientHeight = 192
  ClientWidth = 458
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
    458
    192)
  PixelsPerInch = 96
  TextHeight = 13
  object edProtoFileName: TEdit
    Left = 8
    Top = 16
    Width = 409
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    TextHint = 'Choose proto file'
  end
  object btnOpenProtoFile: TButton
    Left = 423
    Top = 14
    Width = 27
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 1
    OnClick = btnOpenProtoFileClick
  end
  object btnGenerate: TButton
    Left = 8
    Top = 112
    Width = 442
    Height = 72
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Generate'
    TabOrder = 2
    OnClick = btnGenerateClick
  end
  object edOutputFolder: TEdit
    Left = 8
    Top = 53
    Width = 409
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    TextHint = 'Choose output folder'
  end
  object btnChooseOutputFolder: TButton
    Left = 423
    Top = 51
    Width = 27
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 4
    OnClick = btnChooseOutputFolderClick
  end
  object edBaseClassName: TEdit
    Left = 8
    Top = 85
    Width = 442
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
    TextHint = 'Choose base class name'
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
