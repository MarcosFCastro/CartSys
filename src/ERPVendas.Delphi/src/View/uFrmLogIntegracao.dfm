object FrmLogIntegracao: TFrmLogIntegracao
  Left = 0
  Top = 0
  Caption = 'Log de Integra'#231#227'o'
  ClientHeight = 560
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object pnlBotoes: TPanel
    Left = 0
    Top = 516
    Width = 1000
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnAtualizar: TButton
      Left = 8
      Top = 8
      Width = 100
      Height = 28
      Caption = '&Atualizar'
      TabOrder = 0
      OnClick = btnAtualizarClick
    end
    object btnReenviar: TButton
      Left = 116
      Top = 8
      Width = 150
      Height = 28
      Caption = '&Reenviar Selecionado'
      TabOrder = 1
      OnClick = btnReenviarClick
    end
    object btnFechar: TButton
      Left = 896
      Top = 8
      Width = 96
      Height = 28
      Anchors = [akTop, akRight]
      Caption = '&Fechar'
      TabOrder = 2
      OnClick = btnFecharClick
    end
  end
  object dbgLog: TDBGrid
    Left = 0
    Top = 0
    Width = 1000
    Height = 516
    Align = alClient
    DataSource = DataSource
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection]
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object FDQuery: TFDQuery
    Left = 904
    Top = 528
  end
  object DataSource: TDataSource
    DataSet = FDQuery
    Left = 952
    Top = 528
  end
end
