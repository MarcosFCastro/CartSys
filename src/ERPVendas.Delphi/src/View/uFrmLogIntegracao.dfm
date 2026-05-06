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
    ExplicitTop = 516
    ExplicitWidth = 1000
    object btnAtualizar: TcxButton
      Left = 8
      Top = 8
      Width = 100
      Height = 28
      Caption = '&Atualizar'
      TabOrder = 0
      OnClick = btnAtualizarClick
    end
    object btnReenviar: TcxButton
      Left = 116
      Top = 8
      Width = 120
      Height = 28
      Caption = '&Reenviar Selecionado'
      TabOrder = 1
      OnClick = btnReenviarClick
    end
    object btnFechar: TcxButton
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
  object cxGrid: TcxGrid
    Left = 0
    Top = 0
    Width = 1000
    Height = 516
    Align = alClient
    TabOrder = 1
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 1000
    ExplicitHeight = 516
    object cxGridLevel: TcxGridLevel
      GridView = cxGridDBTableView
    end
    object cxGridDBTableView: TcxGridDBTableView
      DataController.DataSource = DataSource
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsCustomize.ColumnFiltering = False
      OptionsData.Editing = False
      OptionsView.GroupByBox = False
      Columns = <
        item
          DataBinding.FieldName = 'DT_EVENTO'
          Caption = 'Data/Hora'
          Width = 130
        end
        item
          DataBinding.FieldName = 'TIPO'
          Caption = 'Tipo'
          Width = 90
        end
        item
          DataBinding.FieldName = 'DIRECAO'
          Caption = 'Dire'#231#227'o'
          Width = 80
        end
        item
          DataBinding.FieldName = 'ENDPOINT'
          Caption = 'Endpoint'
          Width = 200
        end
        item
          DataBinding.FieldName = 'METODO_HTTP'
          Caption = 'M'#233'todo'
          Width = 70
        end
        item
          DataBinding.FieldName = 'STATUS_HTTP'
          Caption = 'Status HTTP'
          Width = 90
        end
        item
          DataBinding.FieldName = 'SUCESSO'
          Caption = 'Sucesso'
          Width = 65
        end
        item
          DataBinding.FieldName = 'ID_VENDA'
          Caption = 'Id Venda'
          Width = 70
        end
        item
          DataBinding.FieldName = 'MENSAGEM_ERRO'
          Caption = 'Mensagem Erro'
          Width = 200
        end>
    end
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
