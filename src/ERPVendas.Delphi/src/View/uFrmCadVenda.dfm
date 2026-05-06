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
    object cmbCliente: TComboBox
      Left = 60
      Top = 10
      Width = 340
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object edtDataVenda: TDateTimePicker
      Left = 456
      Top = 10
      Width = 120
      Height = 23
      Date = 40000.000000000000000000
      Time = 40000.000000000000000000
      TabOrder = 1
    end
    object edtDesconto: TEdit
      Left = 72
      Top = 46
      Width = 120
      Height = 23
      TabOrder = 2
      Text = '0.00'
      OnChange = edtDescontoChange
    end
    object edtObservacoes: TEdit
      Left = 88
      Top = 78
      Width = 500
      Height = 23
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
    object btnSalvar: TButton
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
    object btnCancelar: TButton
      Left = 796
      Top = 8
      Width = 96
      Height = 28
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = '&Cancelar'
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
    ParentBackground = False
    TabOrder = 2
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
    object btnAddItem: TButton
      Left = 8
      Top = 8
      Width = 130
      Height = 28
      Caption = '+ &Adicionar Item'
      TabOrder = 0
      OnClick = btnAddItemClick
    end
    object btnDelItem: TButton
      Left = 146
      Top = 8
      Width = 120
      Height = 28
      Caption = '- &Remover Item'
      TabOrder = 1
      OnClick = btnDelItemClick
    end
    object lvItens: TListView
      Left = 0
      Top = 44
      Width = 900
      Height = 408
      Anchors = [akLeft, akTop, akRight, akBottom]
      Columns = <
        item
          Caption = '#'
          Width = 40
        end
        item
          Caption = 'Produto'
          Width = 300
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
      ReadOnly = True
      RowSelect = True
      TabOrder = 2
      ViewStyle = vsReport
    end
  end
end
