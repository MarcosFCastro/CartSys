object FrmCadVenda: TFrmCadVenda
  Left = 0
  Top = 0
  Caption = 'Venda'
  ClientHeight = 640
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
  object pnlCabecalho: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 112
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 0
    object lblCliente: TLabel
      Left = 8
      Top = 14
      Width = 40
      Height = 15
      Caption = 'Cliente:'
    end
    object lblDataVenda: TLabel
      Left = 420
      Top = 14
      Width = 27
      Height = 15
      Caption = 'Data:'
    end
    object lblDesconto: TLabel
      Left = 8
      Top = 50
      Width = 54
      Height = 15
      Caption = 'Desconto:'
    end
    object lblObservacoes: TLabel
      Left = 8
      Top = 82
      Width = 72
      Height = 15
      Caption = 'Observa'#231#245'es:'
    end
    object edtCliente: TcxLookupComboBox
      Left = 60
      Top = 10
      Width = 340
      Height = 22
      TabOrder = 0
      object edtCliente.Properties: TcxLookupComboBoxProperties
        ListColumns = <>
        ListSource = nil
      end
    end
    object edtDataVenda: TcxDateEdit
      Left = 456
      Top = 10
      Width = 120
      Height = 22
      TabOrder = 1
      object edtDataVenda.Properties: TcxDateEditProperties
        Kind = ckDate
      end
    end
    object edtDesconto: TcxCurrencyEdit
      Left = 72
      Top = 46
      Width = 120
      Height = 22
      TabOrder = 2
      object edtDesconto.Properties: TcxCurrencyEditProperties
        Alignment.Horz = taRightJustify
        OnChange = edtDescontoPropertiesChange
      end
    end
    object edtObservacoes: TcxTextEdit
      Left = 88
      Top = 78
      Width = 500
      Height = 22
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 596
    Width = 900
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 596
    ExplicitWidth = 900
    object btnSalvar: TcxButton
      Left = 700
      Top = 8
      Width = 88
      Height = 28
      Anchors = [akTop, akRight]
      Caption = '&Salvar'
      Default = True
      TabOrder = 0
      OnClick = btnSalvarClick
    end
    object btnCancelar: TcxButton
      Left = 796
      Top = 8
      Width = 96
      Height = 28
      Anchors = [akTop, akRight]
      Caption = '&Cancelar'
      Cancel = True
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object pnlTotais: TPanel
    Left = 0
    Top = 564
    Width = 900
    Height = 32
    Align = alBottom
    BevelOuter = bvNone
    Color = $00F0F0F0
    TabOrder = 2
    ExplicitTop = 564
    ExplicitWidth = 900
    object lblTotal: TLabel
      Left = 8
      Top = 8
      Width = 33
      Height = 15
      Caption = 'Total:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblValorTotal: TLabel
      Left = 48
      Top = 8
      Width = 200
      Height = 15
      Caption = 'R$ 0,00   |   L'#237'quido: R$ 0,00'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlItens: TPanel
    Left = 0
    Top = 112
    Width = 900
    Height = 452
    Align = alClient
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 3
    ExplicitHeight = 452
    object btnAddItem: TcxButton
      Left = 8
      Top = 8
      Width = 120
      Height = 28
      Caption = '+ &Adicionar Item'
      TabOrder = 0
      OnClick = btnAddItemClick
    end
    object btnDelItem: TcxButton
      Left = 136
      Top = 8
      Width = 120
      Height = 28
      Caption = '- &Remover Item'
      TabOrder = 1
      OnClick = btnDelItemClick
    end
    object cxGridItens: TcxGrid
      Left = 0
      Top = 44
      Width = 900
      Height = 408
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 2
      ExplicitWidth = 900
      ExplicitHeight = 408
      object cxGridItensLevel: TcxGridLevel
        GridView = cxGridItensTableView
      end
      object cxGridItensTableView: TcxGridTableView
        NavigatorButtons.ConfirmDelete = False
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsCustomize.ColumnFiltering = False
        OptionsData.Editing = False
        OptionsView.GroupByBox = False
        Columns = <
          item
            Caption = '#'
            MinWidth = 40
            Width = 50
          end
          item
            Caption = 'Produto'
            Width = 280
          end
          item
            Caption = 'Qtd'
            Width = 80
          end
          item
            Caption = 'Pre'#231'o Unit.'
            Width = 120
          end
          item
            Caption = 'Total'
            Width = 120
          end>
      end
    end
  end
end
