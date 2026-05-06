object FrmCadCliente: TFrmCadCliente
  Left = 0
  Top = 0
  Caption = 'Clientes'
  ClientHeight = 520
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlFiltro: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblFiltro: TLabel
      Left = 8
      Top = 14
      Width = 39
      Height = 15
      Caption = 'Filtrar:'
    end
    object edtFiltro: TcxTextEdit
      Left = 56
      Top = 11
      Width = 260
      Height = 22
      TabOrder = 0
      object edtFiltro.Properties: TcxTextEditProperties
        OnChange = edtFiltroPropertiesChange
      end
    end
  end
  object cxGrid: TcxGrid
    Left = 0
    Top = 44
    Width = 900
    Height = 432
    Align = alClient
    TabOrder = 1
    ExplicitLeft = 0
    ExplicitTop = 44
    ExplicitWidth = 900
    ExplicitHeight = 432
    object cxGridLevel: TcxGridLevel
      GridView = cxGridTableView
    end
    object cxGridTableView: TcxGridTableView
      NavigatorButtons.ConfirmDelete = False
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsCustomize.ColumnFiltering = False
      OptionsView.GroupByBox = False
      Columns = <
        item
          Caption = 'C'#243'digo'
          MinWidth = 50
          Width = 70
        end
        item
          Caption = 'Nome'
          Width = 220
        end
        item
          Caption = 'CPF/CNPJ'
          Width = 130
        end
        item
          Caption = 'E-mail'
          Width = 180
        end
        item
          Caption = 'Telefone'
          Width = 110
        end
        item
          Caption = 'Ativo'
          MinWidth = 40
          Width = 50
        end>
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 476
    Width = 900
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 476
    ExplicitWidth = 900
    object btnNovo: TcxButton
      Left = 8
      Top = 8
      Width = 88
      Height = 28
      Caption = '&Novo'
      TabOrder = 0
      OnClick = btnNovoClick
    end
    object btnEditar: TcxButton
      Left = 104
      Top = 8
      Width = 88
      Height = 28
      Caption = '&Editar'
      TabOrder = 1
      OnClick = btnEditarClick
    end
    object btnExcluir: TcxButton
      Left = 200
      Top = 8
      Width = 88
      Height = 28
      Caption = 'E&xcluir'
      TabOrder = 2
      OnClick = btnExcluirClick
    end
    object btnFechar: TcxButton
      Left = 804
      Top = 8
      Width = 88
      Height = 28
      Anchors = [akTop, akRight]
      Caption = '&Fechar'
      TabOrder = 3
      OnClick = btnFecharClick
    end
  end
end
