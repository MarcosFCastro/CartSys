object FrmCadCliente: TFrmCadCliente
  Left = 0
  Top = 0
  Caption = 'Clientes'
  ClientHeight = 480
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
    object edtFiltro: TEdit
      Left = 56
      Top = 11
      Width = 260
      Height = 23
      TabOrder = 0
      OnChange = edtFiltroChange
    end
  end
  object lvClientes: TListView
    Left = 0
    Top = 44
    Width = 900
    Height = 392
    Align = alClient
    Columns = <
      item
        Caption = 'Id'
        Width = 50
      end
      item
        Caption = 'Nome'
        Width = 250
      end
      item
        Caption = 'CPF/CNPJ'
        Width = 130
      end
      item
        Caption = 'E-mail'
        Width = 200
      end
      item
        Caption = 'Telefone'
        Width = 110
      end
      item
        Caption = 'Ativo'
        Width = 50
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 436
    Width = 900
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 436
    ExplicitWidth = 900
    object btnNovo: TButton
      Left = 8
      Top = 8
      Width = 88
      Height = 28
      Caption = '&Novo'
      TabOrder = 0
      OnClick = btnNovoClick
    end
    object btnEditar: TButton
      Left = 104
      Top = 8
      Width = 88
      Height = 28
      Caption = '&Editar'
      TabOrder = 1
      OnClick = btnEditarClick
    end
    object btnExcluir: TButton
      Left = 200
      Top = 8
      Width = 88
      Height = 28
      Caption = 'E&xcluir'
      TabOrder = 2
      OnClick = btnExcluirClick
    end
    object btnFechar: TButton
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
